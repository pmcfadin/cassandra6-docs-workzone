# Chapter 8: Failure Playbooks

This chapter is a collection of runbooks. Each playbook covers a specific failure scenario: what you will see, why it happened, and exactly what to do about it. Keep this chapter bookmarked. You will not need it often, but when you do, you will want it immediately.

The playbooks are ordered by severity, from routine situations that resolve themselves to emergency recovery procedures that should never be necessary if CMS is sized correctly.

## Learning Objectives

- Map common failure modes to deterministic response playbooks.
- Recover from quorum and reconfiguration failures with minimal operational risk.
- Apply unsafe recovery tools only under clearly defined break-glass conditions.

## Playbook: Single CMS Node Lost

**Severity: Low. No operator action required.**

### What You See

A CMS member goes down — hardware failure, process crash, network isolation. The remaining CMS members continue operating. You may notice log messages from the remaining CMS nodes indicating a peer is unreachable, and the `unreachableCMSMembers` metric ticks up by one.

### Why It Is Not a Problem

The CMS is a Paxos group. As long as a majority of CMS members are alive, the group can reach consensus and commit transformations. A 3-member CMS tolerates 1 failure. A 5-member CMS tolerates 2. A 7-member CMS tolerates 3.

The quorum calculation in `PaxosBackedProcessor` is straightforward:

```
blockFor = (replicas.size() / 2) + 1
```

For a 3-member CMS, `blockFor = 2`. Two of three nodes can still commit. For a 5-member CMS, `blockFor = 3`. Three of five can still commit. All metadata operations — topology changes, schema changes, CMS reconfiguration — continue without interruption.

### What to Do

1. **Diagnose the failed node.** Check hardware, process logs, network connectivity. This is standard Cassandra troubleshooting — nothing specific to TCM.

2. **Restore the node.** Restart the process if it crashed. Replace the hardware if it failed. When the node comes back, it will automatically catch up on any metadata log entries it missed. The `PeerLogFetcher` handles this — the node fetches log entries from its CMS peers and applies them in order until it reaches the current epoch.

3. **If the node cannot be restored,** replace it as you would any other Cassandra node (`nodetool removenode` followed by bootstrapping a replacement). The CMS will automatically reconfigure itself if the dead node was a CMS member and the replacement node is eligible.

### When to Escalate

If you lose a second CMS node before the first is restored, and you are running a 3-member CMS, you have lost quorum. See the next playbook.

## Playbook: CMS Quorum Lost

**Severity: High. Metadata changes are blocked until quorum is restored.**

### What You See

More than half of the CMS members are down. With a 3-member CMS, this means 2 nodes are down. With a 5-member CMS, 3 nodes are down.

The cluster continues serving reads and writes for existing data. Existing topology is intact. But any operation that requires a metadata commit is blocked:

- New bootstraps cannot start
- Decommissions cannot proceed
- Schema changes (CREATE TABLE, ALTER TABLE) are rejected
- CMS reconfiguration cannot complete

You will see `ReadTimeoutException` errors with `ConsistencyLevel.QUORUM` in the logs of nodes attempting metadata operations. Non-CMS nodes attempting commits through `RemoteProcessor` will receive failure responses and retry with exponential backoff.

### Why It Happens

The CMS uses Paxos for consensus. Paxos requires a majority to agree on each commit. Without a majority, no new log entries can be committed. This is by design — it prevents split-brain scenarios where two partitions of the CMS could commit conflicting metadata.

### What to Do

**Step 1: Restore CMS nodes.** This is always the first priority. Every CMS node you bring back online moves you closer to quorum. Once a majority is up, the system recovers automatically. Nodes catch up on missed log entries and resume committing.

**Step 2: If nodes cannot be restored quickly,** assess the situation:

- Can you restart the CMS processes? (Process crash, OOM, etc.)
- Can you restore network connectivity? (Network partition, firewall rule, etc.)
- Is the hardware permanently lost? (Disk failure, host termination, etc.)

**Step 3: If quorum cannot be restored through normal means,** you have two options:

**Option A: Wait.** If the outage is temporary (network partition, datacenter power issue), waiting for connectivity to restore is the safest choice. The cluster continues serving existing data. No metadata changes can occur, but no data is at risk.

**Option B: Emergency recovery.** If the CMS nodes are permanently lost, proceed to the "Total CMS Loss" playbook below. This requires unsafe mode operations and should be a last resort.

### Prevention

Size your CMS appropriately. A 3-member CMS has a thin margin — one failure away from quorum loss if a second node goes down. For production clusters, 5-member CMS provides a more comfortable buffer. See Chapter 5 for sizing guidance.

## Playbook: Total CMS Loss

**Severity: Critical. Emergency recovery required.**

### What You See

All CMS members are down. No metadata commits are possible. The cluster is frozen in its current topology state — it can still serve reads and writes, but no topology or schema changes can occur.

This scenario should be extraordinarily rare. For all CMS members to be lost simultaneously requires a catastrophic event: total datacenter loss, a cluster-wide bug triggered by a specific operation, or a cascade failure that takes down every CMS member. If your CMS members are distributed across racks and datacenters (as recommended in Chapter 5), simultaneous loss of all of them implies a much larger incident.

### The Escape Hatch

TCM provides emergency recovery mechanisms that bypass Paxos consensus. These are "break glass" operations — they require explicitly enabling unsafe mode and should only be used when the CMS is completely unavailable.

**Prerequisites for all escape hatch operations:**

1. Set `cassandra.unsafe_tcm_mode=true` in `cassandra.yaml`
2. Restart at least one node with this flag enabled
3. Execute the recovery operation via JMX

#### Recovery Method 1: Revert to a Previous Epoch

If you know the last good epoch before the failure, you can revert the cluster's metadata to that point:

```bash
# Via JMX (using jconsole, jmxterm, or similar)
# MBean: org.apache.cassandra.tcm:type=CMSOperations
# Method: unsafeRevertClusterMetadata(long epoch)
```

What this does internally:

1. Retrieves the metadata snapshot at the specified epoch from `system_cluster_metadata`
2. Creates a new snapshot at epoch N+1 (one past the current epoch) with that historical state
3. Commits a `ForceSnapshot` transformation that bypasses Paxos consensus
4. The node's metadata is now at the specified historical state

**When to use:** You know which epoch was the last consistent state, and you want to roll back to it. Any metadata changes committed after that epoch are lost.

#### Recovery Method 2: Load Metadata from a Dump File

If you have previously exported a metadata dump (or can obtain one from a surviving node's local state), you can load it directly:

```bash
# First, obtain a dump (if you have a running node with local metadata):
# JMX Method: dumpClusterMetadata(long epoch, long transformToEpoch, String version)
# This writes a file to disk

# Then load the dump on the recovery node:
# JMX Method: unsafeLoadClusterMetadata(String filePath)
```

What this does internally:

1. Deserializes the `ClusterMetadata` object from the dump file
2. Forces the epoch to current+1
3. Commits a `ForceSnapshot` transformation with the loaded state

**When to use:** You have a metadata backup or can extract one from any surviving node's local system tables. This is the most common recovery path for total CMS loss.

#### Recovery Method 3: Boot with a Metadata File

If no CMS nodes can start normally, you can bootstrap a node using a metadata file from disk:

```bash
# Add JVM property before starting the node:
-Dcassandra.unsafe_boot_with_clustermetadata=/path/to/metadata/dump
```

This causes the node to boot in `RESET` state — it ignores the CMS entirely and uses the provided metadata file as its view of the cluster. The property is consumed on startup and does not persist.

**When to use:** No CMS nodes can start at all, and you need to bring at least one node up with a known metadata state.

### Recovery Procedure: Step by Step

1. **Stop all remaining CMS nodes** (if any are in a bad state).
2. **Choose one node** to be the recovery node. Ideally, pick a node that was recently a CMS member.
3. **Enable unsafe mode** on that node: set `cassandra.unsafe_tcm_mode=true` in `cassandra.yaml`.
4. **Start the recovery node.**
5. **Execute the appropriate recovery method** (revert, load, or boot-with-file).
6. **Verify the metadata state** with `nodetool cms describe`. Confirm the epoch, CMS members, and directory look correct.
7. **Disable unsafe mode** on the recovery node: set `cassandra.unsafe_tcm_mode=false`.
8. **Restart the recovery node** in normal mode.
9. **Start the remaining CMS nodes.** They will fetch the recovery node's metadata and sync.
10. **Verify cluster-wide convergence**: check that all nodes report the same epoch.

### The Dump-Early, Dump-Often Principle

The escape hatch works best when you have a recent metadata dump. Consider making periodic metadata dumps part of your backup routine:

```bash
# Dump current metadata state (via JMX)
# MBean: org.apache.cassandra.tcm:type=CMSOperations
# Method: dumpClusterMetadata(currentEpoch, currentEpoch, "V8")
```

Store the dump alongside your regular Cassandra backups. In a total CMS loss scenario, the dump is your fastest path back to a functioning cluster.

## Playbook: Node Restarted Mid-Bootstrap

**Severity: Low. Resumable.**

### What You See

A node that was in the middle of bootstrapping — streaming data from source replicas — crashes or is restarted. When it comes back up, it is in a partially bootstrapped state. The `InProgressSequences` in the cluster metadata still has the node's bootstrap entry, and the node's state in the directory is either `BOOTSTRAPPING` or `REGISTERED`.

### What to Do

**Resume the bootstrap:**

```bash
$ nodetool bootstrap resume
```

This is the simplest recovery path. The node picks up where it left off. The `BootstrapAndJoin` sequence knows which step it was on (START_JOIN, MID_JOIN, or FINISH_JOIN) and resumes from there. If the node had completed START_JOIN and was mid-stream (MID_JOIN), it restarts streaming for the ranges it had not yet received.

The `InProgressSequences.finishInProgressSequences()` method handles this on startup. It checks whether the node has an in-progress sequence, determines if the sequence is safe to resume during startup, and if so, executes the remaining steps.

**If resume fails or you want to start fresh:**

```bash
$ nodetool bootstrap abort <node-id> <endpoint>
```

This cancels the in-progress bootstrap sequence, releases the range locks, and cleans up the metadata. The node returns to `REGISTERED` state. You can then start a fresh bootstrap.

### What Not to Do

Do not manually clear tokens, delete system tables, or restart the node with a different configuration hoping it will "forget" the partial bootstrap. The metadata log has a record of the in-progress sequence. The proper path is always resume or abort.

## Playbook: Stuck Topology Operation

**Severity: Medium. Requires operator decision.**

### What You See

A topology operation (bootstrap, decommission, move, replace) started but did not complete. The operation is visible in `nodetool cms describe` as an in-progress sequence, and no further progress is being made. The range locks held by this operation are preventing other topology changes.

Common causes:

- The node performing the operation crashed and has not been restarted
- Streaming failed due to a source node going down
- A network partition isolated the node performing the operation
- A disk filled up on the streaming target

### Diagnosing the Stuck Operation

Check the in-progress sequences:

```bash
$ nodetool cms describe
```

Look for entries in the directory with states like `BOOTSTRAPPING`, `LEAVING`, or `MOVING`. Cross-reference with the `multi_step_operation` field to see which step the operation is on.

Check the node's logs for error messages:

```
ERROR - Error while decommissioning node: ...
ERROR - Streaming error during bootstrap: ...
```

### Resolution Options

**Option 1: Resume the operation.** If the underlying issue is resolved (node restarted, network restored, disk space freed), resume:

```bash
$ nodetool bootstrap resume          # For stuck bootstrap
$ nodetool decommission              # For stuck decommission (re-invocation resumes)
$ nodetool move <token>              # For stuck move (re-invocation resumes)
```

**Option 2: Abort the operation.** If the operation cannot complete or should not proceed:

```bash
$ nodetool bootstrap abort <node-id> <endpoint>
$ nodetool cancel_decommission <node-id>
$ nodetool stop_moving
```

**Option 3: Generic cancellation.** For any operation type:

```bash
$ nodetool cms cancel_in_progress_sequences <node-id> <operation-type>
# operation-type: JOIN, REPLACE, LEAVE, REMOVE, MOVE, RECONFIGURE_CMS
```

The `CancelInProgressSequence` transformation handles cleanup for each operation type: releasing locked ranges, reverting token assignments (for moves), and removing the sequence from the in-progress map.

### What Cancellation Does

When you cancel an in-progress sequence, the system:

1. Calls `sequence.cancel(metadata)` on the specific operation type, which performs type-specific cleanup
2. Removes the node from the `InProgressSequences` map
3. Releases associated range locks
4. Commits the cancellation as a new epoch

The node's state in the directory reverts to its pre-operation state. For a cancelled bootstrap, the node goes back to `REGISTERED`. For a cancelled decommission, the node returns to `JOINED`. For a cancelled move, the node keeps its original tokens.

## Playbook: Epoch Divergence

**Severity: Low. Usually self-resolving.**

### What You See

Different nodes in the cluster report different epochs. You check `nodetool cms describe` on multiple nodes and see mismatched epoch numbers. Or you see log messages like:

```
WARN - Could not perform consistent fetch, downgrading to fetching from CMS peers.
```

### Why This Is Usually Not a Problem

Epoch divergence is a transient state, not a failure. It happens naturally when:

- A metadata change was just committed and some nodes have not yet received the update
- A node was down briefly and is catching up
- A network blip delayed log replication to some nodes

Non-CMS nodes learn about new epochs through two mechanisms: the `PeerLogFetcher` background process that periodically pulls log entries from CMS peers, and direct epoch requests when the node needs to perform an operation that requires a minimum epoch.

CMS nodes learn about new epochs through Paxos — they are directly involved in committing each epoch. They should always be at or very near the latest epoch.

### When to Investigate

Epoch divergence becomes a concern only if:

**A node is persistently behind.** If a node stays at the same epoch for minutes while other nodes advance, it may be unable to reach CMS peers. Check network connectivity.

**The gap is large and growing.** A node at epoch 100 while the cluster is at epoch 150 suggests either prolonged network isolation or a processing failure. The node's logs should indicate what is happening — look for `fetchCMSLogConsistencyDowngrade` metrics or repeated `ReadTimeoutException` entries.

**Metadata operations fail on the lagging node.** If a node cannot catch up to the epoch required by a topology operation's progress barrier, the barrier will degrade through consistency levels (`EACH_QUORUM` → `QUORUM` → `LOCAL_QUORUM` → `ONE`) and eventually may fail. The log will show the degradation:

```
INFO - Could not collect epoch acknowledgements within Xms for EACH_QUORUM. Falling back to QUORUM.
```

### What to Do

**Usually: nothing.** The catch-up mechanisms are automatic. Give the node time to fetch and apply log entries.

**If the node is network-isolated:** restore connectivity. Once the node can reach CMS peers, it will catch up.

**If the node appears stuck:** check that the `PeerLogFetcher` is running and that CMS peers are responding. The `fetchCMSLogLatency` metric indicates how long log fetches are taking. If fetches are timing out, there may be a deeper connectivity issue.

**If the node cannot catch up through log replay** (for example, if the log has been compacted and the entries the node needs are gone), it can recover through a metadata snapshot. Snapshots are stored in the `system_cluster_metadata` keyspace and contain a complete `ClusterMetadata` image at a specific epoch. The node fetches the nearest snapshot and applies only the log entries after that point.

## Playbook: CMS Reconfiguration Failure

**Severity: Medium. Requires explicit resume or cancel.**

### What You See

A CMS reconfiguration (changing the number of CMS members) started but did not complete. The `nodetool cms describe` output shows the reconfiguration in progress, and `nodetool cms reconfigure --status` shows which step it stopped at.

### Why It Happens

CMS reconfiguration is a multi-step process. When adding a member, the system must stream the distributed metadata log tables to the new node before it can participate in quorum. When removing a member, the system must repair Paxos state on the remaining members. Either of these can fail if nodes go down during the process.

### What to Do

**Check the status:**

```bash
$ nodetool cms reconfigure --status
```

The output will show active transitions, pending additions, pending removals, and any incomplete steps.

**Resume the reconfiguration:**

```bash
$ nodetool cms reconfigure --resume
```

This picks up from the last completed step. If the failure was transient (node temporarily unreachable, streaming interrupted), resuming will often succeed.

**Cancel the reconfiguration:**

```bash
$ nodetool cms reconfigure --cancel
```

This aborts the reconfiguration, releases any locks on the metadata keyspace ranges, and reverts any partially completed membership changes. You can start a new reconfiguration later.

## Playbook: Network Partition During Metadata Change

**Severity: Variable. Depends on which nodes are partitioned.**

### What You See

A network partition splits the cluster into two or more groups. The behavior depends on which side of the partition the CMS majority falls.

### Scenario 1: CMS Majority on One Side

The side with the CMS majority continues operating normally — metadata commits succeed, topology operations proceed. The side without CMS access cannot commit metadata changes. Non-CMS nodes on the isolated side fall back to a candidate selection strategy: they try known CMS members first, then seed nodes, then the discovery protocol.

**What to do:** Resolve the network partition. When connectivity is restored, isolated nodes catch up automatically.

### Scenario 2: CMS Split Across the Partition

If the partition splits the CMS such that no side has a majority, all metadata commits are blocked cluster-wide. This is equivalent to the "CMS Quorum Lost" playbook above.

**What to do:** Resolve the partition. If the partition is long-lived and you need to make metadata changes, you may need to pause commits on one side and use unsafe operations — but this is an extreme measure.

### Automatic Recovery

When a network partition heals:

1. The failure detector marks previously unreachable nodes as alive
2. CMS nodes exchange Paxos ballots and reach consensus on the latest state
3. Non-CMS nodes fetch and apply missed log entries from CMS peers
4. Progress barriers that were waiting for unreachable nodes can now complete

No operator action is required for automatic recovery. The system converges on its own.

## Playbook: Emergency Commit Pause

**Severity: Operator-initiated. Use when you need to freeze metadata changes.**

### When to Use

You suspect metadata corruption, an unexpected transformation was committed, or you need to investigate the metadata log before allowing further changes.

### How to Pause

```bash
# Pause all metadata commits
$ nodetool cms set_commits_paused true

# Verify the pause is active
$ nodetool cms describe
# Look for: Commits Paused: true
```

While commits are paused:

- No topology changes can proceed
- No schema changes can be applied
- In-progress sequences are frozen at their current step
- The cluster continues serving reads and writes for existing data

### How to Resume

```bash
# Resume commits after investigation
$ nodetool cms set_commits_paused false
```

Paused commits do not queue — operations that attempted to commit while paused received failures. Operators or applications will need to retry those operations after resuming.

## The Break-Glass Reference

All unsafe and force operations in one table, for quick reference during incidents:

| Operation | Command | Precondition | Risk Level |
|-----------|---------|-------------|------------|
| Cancel stuck sequence | `nodetool cms cancel_in_progress_sequences` | Sequence exists | Low — graceful cleanup |
| Pause commits | `nodetool cms set_commits_paused true` | None | Low — freezes metadata temporarily |
| Resume reconfiguration | `nodetool cms reconfigure --resume` | Reconfig was interrupted | Low — continues normal flow |
| Revert to epoch | JMX: `unsafeRevertClusterMetadata(epoch)` | `unsafe_tcm_mode=true`, CMS down | High — loses recent changes |
| Load metadata from file | JMX: `unsafeLoadClusterMetadata(path)` | `unsafe_tcm_mode=true`, CMS down | High — requires trusted dump |
| Boot with metadata file | JVM: `-Dcassandra.unsafe_boot_with_clustermetadata=path` | All CMS down | High — bypasses CMS entirely |
| Unsafe join (skip streaming) | Automatic when `auto_bootstrap=false` | Node not yet a member | High — skips data streaming |

The pattern is clear: safe operations use `nodetool` commands. Dangerous operations require `unsafe_tcm_mode=true` and direct JMX access. The system makes you work harder to do dangerous things, which is exactly how it should be.

## Operator Self-Check

1. Which failures are generally self-healing, and which require immediate operator intervention?
2. What is the safest default response when CMS quorum is lost but outage is likely temporary?
3. Which explicit prerequisites must be met before using unsafe metadata recovery methods?

## Summary

Most TCM failures are self-resolving. Single CMS node loss is a non-event. Epoch divergence corrects itself. Stuck topology operations can be resumed or aborted with a single command.

The scenarios that require real operator intervention are rare: total CMS loss, persistent quorum loss, or metadata corruption. For these, TCM provides escape hatches — but they require unsafe mode, which is an explicit acknowledgment that you are bypassing the system's safety guarantees.

The best failure playbook is prevention:

- Size your CMS to tolerate the failure modes you care about (5 members for production, 7 if you want extra margin)
- Distribute CMS members across racks and datacenters
- Make periodic metadata dumps as part of your backup routine
- Monitor `unreachableCMSMembers` and alert when it is non-zero

The next chapter covers performance and latency expectations — what TCM adds to the critical path and what it does not.
