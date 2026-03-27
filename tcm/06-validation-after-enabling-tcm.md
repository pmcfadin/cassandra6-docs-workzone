# Chapter 6: Validation After Enabling TCM

You have completed the upgrade. CMS is initialized. Reconfiguration is done. Now prove it works.

This chapter is about building confidence — not by trusting that the process succeeded, but by verifying it through observable evidence. You will query epochs, inspect the metadata log, test schema propagation end-to-end, and learn which log patterns indicate health and which indicate trouble. By the end, you will know exactly how to confirm that your cluster's metadata subsystem is functioning correctly, and how to detect problems before they become incidents.

## Learning Objectives

- Validate post-enablement health using epoch consistency, log inspection, and schema smoke tests.
- Interpret key TCM log signatures and metrics to separate normal behavior from incidents.
- Build a production-ready alerting baseline for ongoing TCM operations.

## Understanding Epochs

Every discussion of TCM validation begins with epochs, so let us make sure the concept is concrete.

An epoch is a monotonically increasing integer that identifies a specific version of the cluster's metadata. Every metadata change — a schema mutation, a node joining, a decommission step, a CMS reconfiguration — produces a new epoch. Epoch 1 is assigned during CMS initialization. Each subsequent commit increments it by one.

The `Epoch` class defines several special values:

| Constant | Value | Meaning |
|----------|-------|---------|
| `EMPTY` | 0 | No TCM metadata exists; pre-initialization state |
| `FIRST` | 1 | First valid epoch; assigned at CMS initialization |
| `UPGRADE_STARTUP` | Long.MIN_VALUE | Transitional value during gossip-to-TCM upgrade at startup |
| `UPGRADE_GOSSIP` | Long.MIN_VALUE + 1 | Transitional value during gossip-to-TCM upgrade in gossip processing |

After initialization, epochs advance linearly: 1, 2, 3, 4, and so on. The `isDirectlyBefore()` method validates that transitions are consecutive — epoch 5 is directly before epoch 6, but not before epoch 8. This strict ordering is the foundation of TCM's consistency guarantees: every node applies the same transformations in the same sequence.

### What an Epoch Represents

An epoch is not a timestamp. It is a version number for the entire cluster metadata state. When a node reports "I am at epoch 47," it means: "I have applied the first 47 metadata transformations, in order, and my view of the cluster's token ownership, schema, and membership reflects all of those changes."

This makes epoch comparison the single most powerful validation tool available to you. If every node reports the same epoch, every node has the same metadata. If a node is behind, it will catch up by fetching and applying the missing entries in order. If it cannot catch up, something is wrong.

## Your First Validation: `nodetool cms describe`

Immediately after initialization and reconfiguration, run this on every node:

```bash
$ nodetool cms describe
```

The output includes several key fields:

```
Epoch: 3
Members: [node1-id, node2-id, node3-id]
Is Member: true
Service State: LOCAL
Is Migrating: false
Local Pending Count: 0
CMS Identifier: a1b2c3d4-...
Commits Paused: false
```

**What to verify:**

**Epoch is greater than zero.** After initialization, the epoch should be at least 1 (FIRST). After reconfiguration, it will be higher — each reconfiguration step produces additional epochs.

**Service State is LOCAL or REMOTE.** CMS members report `LOCAL`. Non-CMS nodes report `REMOTE`. No node should report `GOSSIP` — that would mean the node has not transitioned to TCM mode.

**Is Migrating is false.** If this is `true`, a CMS reconfiguration is still in progress. Wait for it to complete before proceeding with further validation.

**Local Pending Count is 0 (or very small).** The pending count indicates entries received out of order that are waiting for their predecessors. In a healthy cluster, this should be 0. A sustained non-zero value indicates the node is having trouble applying log entries.

**Commits Paused is false.** If commits are paused, metadata operations are blocked. This should never be `true` during normal operation.

### Verifying Epoch Consistency Across the Cluster

Run `nodetool cms describe` on every node and compare the `Epoch` values. In a healthy, quiescent cluster (no metadata changes in flight), every node should report the same epoch.

If nodes differ, the lagging nodes are behind on log application. In most cases, they will catch up within seconds. If the gap persists, investigate network connectivity between the lagging nodes and the CMS members.

## Querying the Metadata Log via CQL

TCM exposes two virtual tables in the `system_views` keyspace that you can query directly from `cqlsh`. These are read-only views into the TCM subsystem — you cannot modify them, and they impose no load on the cluster.

### `system_views.cluster_metadata_log`

This table contains every committed transformation in the metadata log:

```sql
SELECT epoch, kind, entry_id, entry_time
FROM system_views.cluster_metadata_log
ORDER BY epoch DESC
LIMIT 20;
```

Each row represents one epoch — one metadata change. The `kind` column tells you what type of transformation it was: `SCHEMA_CHANGE`, `REGISTER`, `PREPARE_JOIN`, `FINISH_JOIN`, `INITIALIZE_CMS`, and so on.

After a fresh initialization and reconfiguration to RF=3, you might see something like:

```
 epoch | kind                              | entry_time
-------+-----------------------------------+----------------------------
     5 | FINISH_ADD_TO_CMS                 | 2025-03-15 14:23:45.123
     4 | START_ADD_TO_CMS                  | 2025-03-15 14:23:44.987
     3 | PREPARE_SIMPLE_CMS_RECONFIGURATION| 2025-03-15 14:23:44.654
     2 | INITIALIZE_CMS                    | 2025-03-15 14:22:30.321
     1 | PRE_INITIALIZE_CMS                | 2025-03-15 14:22:29.876
```

This is your cluster's birth certificate under TCM. Epochs 1 and 2 are initialization. Epochs 3–5 are the CMS reconfiguration from RF=1 to RF=3.

### `system_views.cluster_metadata_directory`

This table shows every node known to TCM, along with its current state:

```sql
SELECT node_id, host_id, state, cassandra_version, dc, rack,
       broadcast_address, multi_step_operation
FROM system_views.cluster_metadata_directory;
```

**What to verify:**

- Every node you expect to be in the cluster appears in the directory.
- All active nodes show `state = 'JOINED'`.
- No nodes are stuck in `BOOTSTRAPPING`, `MOVING`, or `LEAVING` (unless an operation is genuinely in progress).
- The `multi_step_operation` column is empty for all JOINED nodes (a non-empty value indicates an in-progress topology operation).
- The `cassandra_version` is consistent across all nodes.

## The Smoke Test: End-to-End Schema Propagation

The most convincing validation is a live test. Create a keyspace, verify it propagates to every node, then drop it.

**Step 1. Record the current epoch.**

```bash
$ nodetool cms describe | grep "Epoch:"
Epoch: 5
```

**Step 2. Create a test keyspace.**

```sql
cqlsh> CREATE KEYSPACE test_tcm_validation
       WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 3};
```

**Step 3. Verify the epoch advanced.**

```bash
$ nodetool cms describe | grep "Epoch:"
Epoch: 6
```

The epoch should be higher than before. If it is, the schema change was committed through the TCM log — not through gossip.

**Step 4. Verify propagation to other nodes.**

On a different node:

```sql
cqlsh> DESCRIBE KEYSPACE test_tcm_validation;
```

The keyspace should exist. Repeat on multiple nodes if your cluster is large.

**Step 5. Verify in the metadata log.**

```sql
SELECT epoch, kind
FROM system_views.cluster_metadata_log
WHERE epoch = 6;
```

You should see a `SCHEMA_CHANGE` entry at the epoch that corresponds to your CREATE KEYSPACE.

**Step 6. Clean up.**

```sql
cqlsh> DROP KEYSPACE test_tcm_validation;
```

This produces another epoch. Verify that as well if you want to be thorough.

If all steps pass, TCM is working end-to-end: schema changes enter the CMS, are committed via Paxos, replicate to all nodes through the log, and are applied locally. This is the same path that token ownership changes and node lifecycle transitions take. If schema works, everything works.

## Understanding Catch-Up and Partial States

A common question after enabling TCM: "Can a node be partially caught up?"

The answer is **no**, with one exception.

Epochs are applied in strict order. A node at epoch 10 has applied all transformations from 1 through 10. It cannot skip epoch 7 and apply epoch 8. If it is missing epoch 7, it stops and waits until epoch 7 is fetched. This means there are only two states for any given node:

1. **Fully caught up.** The node's epoch matches the cluster's current epoch.
2. **Behind by one or more epochs.** The node has a gap that it is actively filling.

There is no "partially applied epoch 7" — each transformation is atomic. The node either has it or it does not.

**The exception:** A newly booting node can start from a metadata snapshot rather than replaying the entire log from epoch 1. When this happens, the node loads the snapshot (which represents the complete metadata state at some epoch, say epoch 40), and then replays only the entries after epoch 40. From the node's perspective, it "jumps" to epoch 40 without having processed epochs 1 through 39 individually. This is a performance optimization, not a consistency compromise — the snapshot contains the same final state that replaying all 40 entries would produce.

## Monitoring via JMX

For integration with monitoring systems (Prometheus, Grafana, Datadog, etc.), TCM exposes metrics through JMX.

### Key JMX Attributes

The `org.apache.cassandra.tcm:type=CMSOperations` MBean provides:

| Attribute | Type | Meaning |
|-----------|------|---------|
| `EPOCH` | long | Current epoch on this node |
| `LOCAL_PENDING` | int | Entries in pending buffer (waiting for predecessors) |
| `IS_MEMBER` | boolean | Whether this node is a CMS member |
| `SERVICE_STATE` | String | LOCAL, REMOTE, or GOSSIP |
| `COMMITS_PAUSED` | boolean | Whether metadata commits are paused |

### TCM Metrics

The `org.apache.cassandra.tcm:type=TCMMetrics` MBean provides operational gauges and timers:

| Metric | Type | What It Tells You |
|--------|------|-------------------|
| `currentEpochGauge` | Gauge (long) | Current cluster epoch — the primary health signal |
| `currentCMSSize` | Gauge (int) | Number of active CMS members |
| `unreachableCMSMembers` | Gauge (int) | CMS members not responding — alert if > 0 |
| `isCMSMember` | Gauge (0/1) | Whether this node participates in Paxos consensus |
| `needsCMSReconfiguration` | Gauge (0/1) | Whether CMS membership needs rebalancing |
| `commitSuccessLatency` | Timer | Histogram of successful commit latencies |
| `fetchCMSLogLatency` | Timer | Histogram of log fetch latencies from peers |

### Recommended Alerts

| Condition | Severity | Meaning |
|-----------|----------|---------|
| `unreachableCMSMembers > 0` | Warning | A CMS member is down; quorum may be at risk |
| `unreachableCMSMembers >= (CMS_RF + 1) / 2` | Critical | Quorum lost; metadata operations blocked |
| `LOCAL_PENDING > 10` for more than 60 seconds | Warning | Node is falling behind on log application |
| `needsCMSReconfiguration = 1` for more than 5 minutes | Warning | CMS membership needs rebalancing after topology change |
| `COMMITS_PAUSED = true` | Critical | Metadata commits are blocked |
| Epoch difference between nodes > 10 | Warning | Significant epoch divergence; investigate connectivity |

## Log Patterns to Watch

### Healthy Operation

These messages are normal and expected:

```
INFO  - Fetching log from <peer>, at least <epoch>
DEBUG - Fetched log from CMS - caught up from epoch X to epoch Y
INFO  - First CMS node
INFO  - Endpoint <ip> running <version> is ignored
```

### Warning Signs

These messages warrant investigation:

```
WARN  - Learned about epoch X from <peer>, but could not fetch log
WARN  - Could not fetch log entries from peer, remote = <peer>, await = <epoch>
WARN  - Could not reconfigure CMS, operator should run...
INFO  - Could not collect epoch acknowledgements within Xms for Y. Falling back to Z.
```

The progress barrier fallback message is particularly common and usually benign — it means a few nodes were slow to acknowledge an epoch, so the system relaxed its consistency requirement. If you see it occasionally, it is normal. If you see it on every metadata operation, investigate the slow nodes.

### Error Conditions

These messages require action:

```
ERROR - Caught an exception while processing entry X. This can mean that this node
        is configured differently from CMS.
ERROR - Error while processing entry X. Transformation returned result of REJECTED.
        This can mean that this node is configured differently from CMS.
WARN  - Stopping log processing on the node. All subsequent epochs will be ignored.
WARN  - Unable to serialize metadata snapshot triggered by TriggerSnapshot transformation
```

The "configured differently" messages are the most critical. They indicate that a transformation that was accepted by the CMS cannot be applied on this node — usually because of a version mismatch or a configuration difference. The "stopping log processing" message means the node has given up and will not apply any further metadata changes until restarted.

**Grep commands for operators:**

```bash
# Quick health check — find TCM errors and warnings
grep -E "ERROR|WARN" /var/log/cassandra/system.log | grep -i "epoch\|CMS\|metadata\|transform"

# Monitor log fetch activity
grep "fetch.*log\|caught up" /var/log/cassandra/system.log

# Detect progress barrier fallbacks
grep "Falling back to" /var/log/cassandra/system.log

# Find snapshot activity
grep -i "snapshot" /var/log/cassandra/system.log
```

## Metadata Snapshots

Metadata snapshots are TCM's mechanism for efficient node catch-up. After enabling TCM, verify that snapshots are being created.

### Triggering a Manual Snapshot

```bash
$ nodetool cms snapshot
```

This forces a snapshot at the current epoch. Use it after major topology changes or as part of a validation routine.

### Verifying Snapshot Health

Snapshots are stored in the `system_distributed_metadata` keyspace. There is no direct `nodetool` command to list snapshots, but you can verify their presence indirectly:

1. **Check for snapshot errors in the log:** A successful snapshot produces no log output. A failed snapshot produces:
   ```
   WARN - Unable to serialize metadata snapshot triggered by TriggerSnapshot transformation
   ```

2. **After triggering a snapshot, verify epoch consistency.** If a snapshot completes successfully, a newly restarting node should be able to catch up quickly — loading the snapshot and replaying only the entries after it.

### When Snapshots Matter

Snapshots are most important when:

- **A node has been down for a long time** and needs to catch up on hundreds or thousands of epochs.
- **A new node bootstraps** and needs the full cluster metadata state without replaying the entire log.
- **After a major topology change** that produced many log entries in quick succession.

In steady state with infrequent metadata changes, snapshots are less critical — the log is small and replay is fast.

## The Complete Post-Enablement Validation Checklist

Work through this list on every node after completing all three upgrade phases:

### Immediate Checks

- [ ] `nodetool cms describe` shows `Epoch >= 1` on every node
- [ ] `Service State` is `LOCAL` on CMS members and `REMOTE` on others — no node shows `GOSSIP`
- [ ] `Is Migrating` is `false` on every node
- [ ] `Local Pending Count` is `0` on every node
- [ ] `Commits Paused` is `false` on every node
- [ ] All nodes report the same epoch (within a few seconds of each other)

### Metadata Log Checks

- [ ] `system_views.cluster_metadata_log` shows `PRE_INITIALIZE_CMS` and `INITIALIZE_CMS` entries
- [ ] CMS reconfiguration entries are present if you reconfigured
- [ ] `system_views.cluster_metadata_directory` shows all expected nodes in `JOINED` state

### End-to-End Test

- [ ] Create a test keyspace — epoch advances
- [ ] Test keyspace visible on all nodes
- [ ] Drop the test keyspace — epoch advances again
- [ ] Schema version is consistent (`nodetool describecluster` shows single UUID)

### Monitoring Integration

- [ ] JMX metrics are accessible for `currentEpochGauge` and `unreachableCMSMembers`
- [ ] Alerting configured for quorum loss and epoch divergence
- [ ] Log monitoring configured for TCM error patterns

## Operator Self-Check

1. Which immediate post-upgrade checks prove all nodes actually transitioned out of `GOSSIP` mode?
2. What does sustained non-zero pending log count indicate, and where do you investigate first?
3. Which single end-to-end test provides the strongest confidence in metadata propagation?

## Summary

Validation after enabling TCM comes down to three things: **epoch consistency**, **end-to-end propagation**, and **absence of errors**.

Epoch consistency means every node is at the same epoch — proof that the metadata log is replicating correctly. End-to-end propagation means a schema change issued on one node appears on every other node within seconds — proof that the full commit pipeline (CQL → transformation → Paxos → log → application) is working. Absence of errors means the system logs show no transformation failures, no log processing halts, and no persistent progress barrier fallbacks — proof that the system is healthy.

If all three hold, your cluster is running correctly on TCM. The next chapter covers what day-to-day operations look like in this new world.
