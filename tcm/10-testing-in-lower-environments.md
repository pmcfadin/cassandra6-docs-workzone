# Chapter 10: Testing in Lower Environments

Do not enable TCM in production without testing it first. This is not a feature you can turn on, observe briefly, and roll back if something looks wrong. As Chapter 4 explained, CMS initialization has a point of no return. Once you commit, you are on TCM. The time to discover that your monitoring is missing a metric, your automation scripts assume gossip-based schema propagation, or your deployment pipeline does not account for the three-phase upgrade is before you start the production rollout.

This chapter covers how to build a testing plan that validates TCM behavior in your specific environment. It starts with the simplest local setup and progresses through increasingly realistic scenarios: single-node smoke tests, multi-node topology validation, network partition simulation, concurrent operation safety, and upgrade path verification.

## Learning Objectives

- Select the right test environment based on realism, speed, and team capability.
- Validate upgrade, failure, and concurrency behavior before production rollout.
- Convert scenario results into release-ready go/no-go criteria.

## Test Environment Options

You have three practical options for testing TCM, in order of increasing fidelity.

### Option 1: CCM (Cassandra Cluster Manager)

CCM is the quickest way to spin up a multi-node Cassandra cluster on a single machine. Each node runs as a separate process with its own data directory, log files, and network address (127.0.0.x).

```bash
# Create a 3-node cluster on Cassandra 6.0
ccm create tcm-test -v 6.0 -n 3

# Start the cluster
ccm start

# Verify all nodes are up
ccm status

# Run the full upgrade sequence
ccm node1 nodetool cms initialize
ccm node1 nodetool cms reconfigure 3
ccm node1 nodetool cms describe
```

CCM is ideal for:

- Validating the basic upgrade sequence (Chapter 4's three phases)
- Testing `nodetool cms` commands and understanding their output
- Verifying that your schema changes propagate correctly under TCM
- Practicing the failure playbooks from Chapter 8

CCM is not ideal for:

- Testing network partitions (all nodes share the same loopback interface)
- Realistic latency testing (no actual network hops)
- Multi-datacenter scenarios (possible but cumbersome)

### Option 2: Docker Compose

A Docker-based setup provides better isolation than CCM and can simulate multi-datacenter topologies with network controls.

```yaml
# docker-compose.yml (simplified)
services:
  cassandra-seed:
    image: cassandra:6.0
    environment:
      CASSANDRA_CLUSTER_NAME: tcm-test
      CASSANDRA_DC: dc1
    networks:
      - cassandra-net

  cassandra-2:
    image: cassandra:6.0
    environment:
      CASSANDRA_CLUSTER_NAME: tcm-test
      CASSANDRA_SEEDS: cassandra-seed
      CASSANDRA_DC: dc1
    networks:
      - cassandra-net
    depends_on:
      - cassandra-seed

  cassandra-3:
    image: cassandra:6.0
    environment:
      CASSANDRA_CLUSTER_NAME: tcm-test
      CASSANDRA_SEEDS: cassandra-seed
      CASSANDRA_DC: dc1
    networks:
      - cassandra-net
    depends_on:
      - cassandra-seed

networks:
  cassandra-net:
    driver: bridge
```

Docker provides network-level controls that CCM cannot. You can use `docker network disconnect` to simulate node isolation, `tc` (traffic control) to inject latency, and separate Docker networks to model datacenter boundaries.

### Option 3: Cassandra's In-JVM Distributed Test Framework

Cassandra's own test suite uses an in-JVM distributed testing framework that creates multi-node clusters within a single Java process. Each node runs in an isolated ClassLoader, giving it its own static state while sharing the same JVM. This is the framework Cassandra's developers use to test TCM itself.

The framework provides capabilities that no external tool can match: fine-grained message filtering to simulate network partitions at the Cassandra protocol level, ByteBuddy-based bytecode injection to trigger failures at exact code points, and deterministic control over commit ordering and epoch progression.

If your team has the engineering capacity to write Java tests, this framework is the most powerful option for validating TCM behavior. The rest of this chapter describes the test scenarios you should run, regardless of which tool you use, and provides specific patterns for the in-JVM framework where applicable.

## Scenario 1: The Smoke Test

**Goal:** Verify that the basic TCM lifecycle works end to end.

**What to test:**

1. Start a 3-node cluster on Cassandra 6.0
2. Initialize CMS: `nodetool cms initialize`
3. Verify CMS is active: `nodetool cms describe`
4. Reconfigure CMS to 3 members: `nodetool cms reconfigure 3`
5. Create a keyspace and table
6. Verify the schema propagated to all nodes (query `system_schema.tables` on each node)
7. Verify all nodes report the same epoch (query `system_views.cluster_metadata_log` on each node, or compare `nodetool cms describe` output)

**What you are validating:**

- CMS initialization completes without errors
- CMS reconfiguration selects appropriate members
- Schema changes commit through the Paxos path and propagate via the metadata log
- All nodes converge on the same epoch

**Expected time:** 5-10 minutes.

This is the minimum viable test. If this does not pass, nothing else will.

## Scenario 2: The Upgrade Path

**Goal:** Verify that the three-phase upgrade from a pre-TCM version works correctly.

**What to test:**

1. Start a 3-node cluster on Cassandra 5.0 (or 4.1)
2. Create keyspaces, tables, and insert data
3. Perform a rolling upgrade to 6.0 (Phase 1: restart each node with 6.0 binaries)
4. Verify the cluster is in GOSSIP mode: all nodes should be running 6.0 but CMS is not initialized
5. Initialize CMS (Phase 2): `nodetool cms initialize`
6. Verify CMS is active and all nodes have migrated
7. Reconfigure CMS (Phase 3): `nodetool cms reconfigure 3`
8. Verify data is still readable
9. Create a new table and verify schema propagation
10. Bootstrap a new node and verify it joins correctly

**What you are validating:**

- The rolling binary upgrade preserves data and schema
- CMS initialization migrates gossip-based metadata to the TCM log
- The three election checks (directory, token map, schema digest) pass
- Post-upgrade operations (schema changes, bootstrap) work correctly

**Using the in-JVM framework:**

Cassandra's `ClusterMetadataUpgradeTest` demonstrates this pattern. It creates a cluster on an older version, performs a rolling upgrade, and validates that CMS initialization succeeds:

```java
new TestCase()
    .nodes(3)
    .nodesToUpgrade(1, 2, 3)
    .withConfig(cfg -> cfg.with(Feature.NETWORK, Feature.GOSSIP)
        .set(Constants.KEY_DTEST_FULL_STARTUP, true))
    .upgradesToCurrentFrom(v50)
    .setup(cluster -> {
        // Create schema pre-upgrade
        cluster.schemaChange("CREATE TABLE ks.tbl (pk int PRIMARY KEY)");
    })
    .runAfterClusterUpgrade(cluster -> {
        // Initialize CMS
        cluster.get(1).nodetoolResult("cms", "initialize")
            .asserts().success();

        // Verify migration completed
        cluster.forEach(i ->
            assertFalse(ClusterUtils.isMigrating(i)));

        // Reconfigure and verify
        cluster.get(2).nodetoolResult("cms", "reconfigure", "3")
            .asserts().success();
    })
    .run();
```

The framework also tests error cases — what happens when a node has a directory mismatch during initialization, and how the `--ignore` flag resolves it.

## Scenario 3: Topology Operations

**Goal:** Verify that bootstrap, decommission, and node replacement work correctly under TCM.

### Bootstrap Test

1. Start a 3-node cluster with CMS initialized
2. Bootstrap a 4th node
3. Verify the 4th node appears in `nodetool status` as UN (Up/Normal)
4. Verify all nodes report the same epoch
5. Verify data is correctly distributed (run `nodetool cleanup` on existing nodes if needed)

### Decommission Test

1. From the 4-node cluster, decommission node 4
2. Verify node 4 disappears from the ring
3. Verify data was streamed to remaining nodes
4. Verify all nodes report the same epoch

### Node Replacement Test

1. Stop node 3 abruptly (simulate crash)
2. Bootstrap a replacement node with the same tokens
3. Verify the replacement joins the ring
4. Verify the replaced node is removed from the directory

**Using the in-JVM framework:**

The `ClusterUtils` class provides assertion helpers for each of these operations:

```java
// Bootstrap
IInvokableInstance newNode = cluster.bootstrap(config);
newNode.startup(cluster);
ClusterUtils.awaitRingJoin(cluster.get(1), newNode);

// Decommission
cluster.get(4).nodetoolResult("decommission").asserts().success();
ClusterUtils.awaitRingRemoval(cluster.get(1), cluster.get(4));

// Replace
IInstance replacement = ClusterUtils.replaceHostAndStart(
    cluster, deadNode);
ClusterUtils.awaitRingJoin(cluster.get(1), replacement);
```

**What you are validating:**

- The three-step model (START → MID → FINISH) completes for each operation type
- Range locking prevents conflicting operations
- Progress barriers ensure epoch propagation before streaming begins
- The cluster state is consistent after each operation

## Scenario 4: Network Partition Simulation

**Goal:** Verify that TCM handles network partitions gracefully — CMS continues operating with a majority, and isolated nodes recover when connectivity is restored.

### Partition: Isolate One Non-CMS Node

1. Start a 5-node cluster with 3 CMS members
2. Partition one non-CMS node from the rest of the cluster
3. Perform a schema change
4. Verify the schema change commits (CMS has quorum)
5. Restore connectivity
6. Verify the isolated node catches up to the current epoch

### Partition: Isolate One CMS Node

1. Partition one CMS member from the cluster
2. Perform a schema change
3. Verify it commits (2 of 3 CMS members still form a quorum)
4. Restore connectivity
5. Verify the isolated CMS member catches up

### Partition: CMS Quorum Loss

1. Partition 2 of 3 CMS members from the cluster
2. Attempt a schema change
3. Verify it fails (no quorum)
4. Verify the cluster continues serving reads and writes for existing data
5. Restore connectivity
6. Verify the schema change can now be committed

**Using the in-JVM framework:**

The `MessageFilters` API provides exact control over network partitions:

```java
// Create partition: nodes 1,2 cannot reach nodes 3,4,5
IMessageFilters.Filter partition1 = cluster.filters()
    .allVerbs().from(1, 2).to(3, 4, 5).drop();
IMessageFilters.Filter partition2 = cluster.filters()
    .allVerbs().from(3, 4, 5).to(1, 2).drop();

// Test operations during partition...

// Heal partition
partition1.off();
partition2.off();

// Verify recovery
ClusterUtils.waitForCMSToQuiesce(cluster, cluster.get(1));
```

The `SplitBrainTest` in the Cassandra test suite demonstrates a more sophisticated version of this pattern. It starts four nodes in a partitioned state (nodes 1,2 isolated from nodes 3,4), verifies that each side forms its own metadata view, then heals the partition and verifies that nodes correctly reject metadata from the other partition based on metadata identifier mismatches.

**What you are validating:**

- CMS continues operating with a majority during partitions
- Non-CMS nodes degrade gracefully when they cannot reach CMS (log fetches retry, not crash)
- Recovery is automatic when connectivity is restored
- No metadata corruption occurs during or after the partition

## Scenario 5: Concurrent Operation Safety

**Goal:** Verify that range locking prevents conflicting concurrent topology changes.

### Non-Overlapping Operations (Should Succeed)

1. Start a 6-node cluster with well-separated token ranges
2. Simultaneously bootstrap two new nodes with non-overlapping token ranges
3. Verify both bootstraps complete successfully
4. Verify no range locking conflicts

### Overlapping Operations (Should Be Rejected)

1. Start a 4-node cluster
2. Begin bootstrapping a new node
3. While the bootstrap is in progress (during the MID_JOIN step), attempt to decommission a node whose ranges overlap with the bootstrapping node
4. Verify the decommission is rejected with a range locking error
5. Wait for the bootstrap to complete
6. Retry the decommission — it should now succeed

**What you are validating:**

- Range locking correctly identifies overlapping and non-overlapping ranges
- Overlapping operations are rejected with clear error messages
- Non-overlapping operations proceed safely in parallel
- Range locks are released when operations complete

## Scenario 6: Failure Recovery

**Goal:** Validate the failure playbooks from Chapter 8 in a controlled environment.

### Stuck Bootstrap Recovery

1. Bootstrap a new node
2. Kill the node mid-streaming (after START_JOIN, during MID_JOIN)
3. Verify the bootstrap appears as in-progress in `nodetool cms describe`
4. Restart the node and run `nodetool bootstrap resume`
5. Verify the bootstrap completes
6. Alternatively: run `nodetool bootstrap abort` and verify the node returns to REGISTERED state

### CMS Member Loss and Recovery

1. Start a 5-node cluster with 5 CMS members
2. Stop 2 CMS members
3. Verify metadata commits still work (3 of 5 is quorum)
4. Stop a 3rd CMS member
5. Verify metadata commits fail (2 of 5 is not quorum)
6. Restart one CMS member (back to 3 of 5)
7. Verify metadata commits resume automatically

### Emergency Recovery Drill

This is the most important test and the one most operators skip. Practice the total CMS loss recovery procedure from Chapter 8:

1. Start a 3-node cluster with CMS initialized
2. Create some metadata (keyspaces, tables)
3. Take a metadata dump via JMX
4. Stop all nodes
5. Enable `unsafe_tcm_mode` on one node
6. Start the recovery node
7. Load the metadata dump via JMX
8. Verify the metadata state
9. Disable unsafe mode, restart, and bring up remaining nodes
10. Verify cluster-wide convergence

Do not skip this test. The emergency recovery procedure is the one you will need when everything else has failed, and you do not want to be reading the instructions for the first time during a production incident.

## Scenario 7: Monitoring and Alerting Validation

**Goal:** Verify that your monitoring infrastructure captures TCM metrics and your alerts fire at the correct thresholds.

### Metrics Collection

1. Start a cluster with your production monitoring stack (Prometheus exporter, Datadog agent, or equivalent)
2. Initialize CMS
3. Verify the following metrics are being collected:
   - `CommitSuccessLatency`
   - `CommitRetries`
   - `FetchPeerLogLatency` / `FetchCMSLogLatency`
   - `ProgressBarrierLatency`
   - `CoordinatorBehindSchema` / `CoordinatorBehindPlacements`
   - `UnreachableCMSMembers`
   - `currentEpochGauge`

### Alert Validation

Trigger the conditions that should fire alerts:

1. **Stop a CMS member.** Verify `UnreachableCMSMembers` goes to 1 and your alert fires.
2. **Create a network partition.** Verify `ProgressBarrierCLRelaxed` increments and your alert fires.
3. **Perform rapid schema changes.** Verify `CoordinatorBehindSchema` increments briefly during propagation.

### Dashboard Verification

If you have operational dashboards, verify they show:

- Current epoch across all nodes (should be identical in steady state)
- CMS membership (which nodes are CMS members)
- Commit latency distribution
- Log replication lag (if any node is behind)

## Building Your Test Plan

The scenarios above can be assembled into a test plan based on your risk tolerance and time budget.

### Minimum Viable Test Plan (1-2 hours)

Run Scenarios 1 and 2. This validates that TCM works and that the upgrade path from your current version succeeds. If you are on a tight timeline, this is the minimum.

### Standard Test Plan (4-8 hours)

Add Scenarios 3, 6, and 7. This validates topology operations, failure recovery, and monitoring. Most teams should run at least this much before a production rollout.

### Comprehensive Test Plan (1-2 days)

Add Scenarios 4 and 5. This validates network partition behavior and concurrent operation safety. Teams operating large clusters, multi-datacenter deployments, or clusters with frequent topology changes should run the full suite.

### The Emergency Recovery Drill

Regardless of which plan you choose, run the emergency recovery drill from Scenario 6. It takes 30 minutes and could save you hours during an actual incident.

## Test Assertions Checklist

Across all scenarios, these are the assertions that matter:

**Epoch consistency:** After every operation, all nodes should report the same epoch. Query `system_views.cluster_metadata_log` on each node and compare the maximum epoch values.

**Ring integrity:** After bootstrap or decommission, `nodetool status` should show the expected number of nodes, all in UN (Up/Normal) state. No nodes should be in a transitional state unless an operation is in progress.

**Schema agreement:** After schema changes, all nodes should report the same schema version. Under TCM, this is guaranteed by epoch ordering — if all nodes are at the same epoch, they have the same schema.

**Data availability:** After topology changes, reads and writes at your production consistency level should succeed without errors.

**Log continuity:** The metadata log should have no gaps. Query `system_cluster_metadata.distributed_metadata_log` and verify that epoch numbers are consecutive.

**CMS health:** `nodetool cms describe` should show all CMS members as reachable. `UnreachableCMSMembers` should be 0.

## Operator Self-Check

1. Which minimum scenarios must pass before considering production enablement?
2. What does a successful emergency recovery drill prove about operational readiness?
3. Which assertions should be evaluated after every scenario to catch subtle regressions?

## Summary

Testing TCM before production deployment is not optional — it is the single most effective way to reduce the risk of the upgrade. The scenarios in this chapter are ordered by importance: start with the smoke test and upgrade path, then add topology operations and failure recovery. The network partition and concurrent operation tests are valuable but require more infrastructure.

The key insight is that TCM testing is not about testing Cassandra itself (the project's own test suite does that extensively). It is about testing your specific environment: your monitoring catches the right metrics, your automation scripts handle the new CMS commands, your runbooks account for the three-phase upgrade, and your team has practiced the failure recovery procedures before they need them for real.

Test early. Test the upgrade path. Test the failure recovery. And keep the metadata dumps from your test environment — they may serve as a reference when you run the procedure in production.
