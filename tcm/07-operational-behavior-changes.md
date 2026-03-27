# Chapter 7: Operational Behavior Changes (What to Expect)

Your cluster is on TCM. CMS is initialized, reconfigured, and validated. Now what?

This chapter covers what day-to-day operations look like in a TCM-enabled cluster. The short answer: everything you do still works, but the mechanics underneath have changed in ways that make your life measurably better. Bootstrap is faster to converge. Decommission is easier to track. Concurrent topology changes that were once dangerous are now safe — or explicitly rejected before they can cause harm. And the class of data loss bugs caused by nodes seeing ring changes at different speeds is eliminated entirely.

If you have operated Cassandra through a major rebalancing event — adding a rack, expanding into a new datacenter, replacing a string of failed nodes — you will appreciate what TCM changes about the experience. If you have not, this chapter will help you understand what the system is doing during these operations and what to watch for.

## Learning Objectives

- Explain how TCM changes bootstrap, decommission, replace, and move workflows.
- Use progress barriers and range locking concepts to reason about safe concurrency.
- Translate TCM behavior changes into simpler, faster operator runbooks.

## The New Shape of Topology Operations

Under gossip, topology changes were asynchronous and eventually consistent. A node would announce its intentions through gossip, other nodes would learn about it over a period of seconds to minutes, and the operation would proceed with varying degrees of coordination. Operators developed rituals: wait for the ring to settle, check `nodetool status` three times, pause between operations "just in case."

Under TCM, every topology operation follows the same pattern: a coordinated, multi-step sequence committed through the distributed metadata log. Each step produces an epoch. Each epoch must be acknowledged by affected nodes before the next step proceeds. The operation is visible in the log, trackable through its steps, and resumable if interrupted.

The universal structure looks like this:

```
PREPARE   ──►  START   ──►  MID   ──►  FINISH
(validate)    (announce)   (stream)   (complete)
```

Prepare validates that the operation is legal: the node is in the right state, no conflicting operations are in progress, the ranges involved are not locked. Start commits the first metadata change — the cluster learns what is about to happen. Mid executes the data movement (streaming). Finish commits the final metadata change — the operation is done and the cluster state reflects it.

This structure applies to bootstrap, decommission, move, replace, and CMS reconfiguration. The specific transformations differ, but the pattern is identical. Once you understand it for one operation, you understand it for all of them.

## Bootstrap Under TCM

Bootstrap — adding a new node to the cluster — is the topology operation operators perform most often. Under TCM, the mechanics change in three important ways: the cluster knows about the new node immediately (not eventually), streaming starts only after affected nodes have acknowledged the topology change, and the operation can be resumed if it fails mid-stream.

### The Three Steps

**START_JOIN.** The joining node commits a `StartJoin` transformation to the metadata log. This produces a new epoch. The transformation modifies the cluster's placement information: the joining node is added to the write replica set for its token ranges. At this point, the node exists in the cluster's metadata — every node that applies this epoch knows the bootstrap is happening. But the joining node does not yet hold data, and it is not yet a read replica.

A progress barrier fires after START_JOIN. The system sends `TCM_CURRENT_EPOCH_REQ` messages to all nodes that own ranges affected by the bootstrap and waits for a quorum in each datacenter to acknowledge the new epoch. Only after this acknowledgment does the operation proceed.

**MID_JOIN.** This is where data movement happens. The joining node computes a `MovementMap` — a precise specification of which ranges to stream from which source nodes. The map is derived from the placement deltas between the old and new topology, not from gossip state. The node knows exactly what it needs and exactly where to get it.

Streaming proceeds using the standard Cassandra streaming protocol. The joining node pulls data from source replicas, builds SSTables locally, and indexes them. If Accord is enabled, the node also waits for Accord metadata to become readable before completing this step.

After streaming completes, the joining node commits the `MidJoin` transformation. This advances the epoch again and transitions the node from write-only to read-write in the placement information.

**FINISH_JOIN.** The final transformation removes the original owners' read replicas for the ranges the joining node now owns. The joining node is now a full cluster member. Its bootstrap state is marked `COMPLETED` in `SystemKeyspace`, and CMS placement is updated if the new node is eligible for CMS membership.

### What Operators Notice

The most visible change is **speed of convergence**. Under gossip, a bootstrap could take 30 seconds or more before all nodes in the cluster knew it was happening. Under TCM, the START_JOIN epoch propagates to all nodes within milliseconds. There is no "ring settle" period — the progress barrier ensures acknowledgment before streaming begins.

The second change is **visibility**. Each step produces log entries that map directly to the three-step model:

```
INFO  - Starting to bootstrap...
INFO  - fetching new ranges and streaming old ranges
INFO  - Accord metadata is ready, continuing with bootstrap
INFO  - Bootstrap completed for tokens [...]
```

If the bootstrap fails — a source node goes down during streaming, a disk fills up, a network partition occurs — the operation stops at whatever step it reached. It does not leave the cluster in an ambiguous state. The in-progress sequence is recorded in the metadata, and you can resume it:

```bash
$ nodetool bootstrap resume
```

Or abort it:

```bash
$ nodetool bootstrap abort
```

Under gossip, a failed bootstrap often required manual cleanup — removing gossip state, clearing tokens, restarting the node. Under TCM, the state machine tracks where the operation stopped, and recovery is a single command.

## Decommission Under TCM

Decommission — removing a node from the cluster — follows the same three-step pattern, but in reverse.

### The Three Steps

**START_LEAVE.** The leaving node commits a `StartLeave` transformation. This marks the node's state as `LEAVING` in the cluster metadata. Optionally, a severity penalty is applied to the endpoint snitch, which causes coordinators to prefer other replicas for reads. The node stops accepting new writes.

**MID_LEAVE.** The leaving node streams its data to the nodes that will take over its ranges. The streaming targets are computed from placement deltas — the difference between the current topology (with this node) and the target topology (without it). The `LeaveStreams` class coordinates which ranges go to which recipients.

After streaming completes, the `MidLeave` transformation is committed.

**FINISH_LEAVE.** The final transformation removes the node from all placements. It transitions to the `LEFT` state in the cluster directory. The node can now safely shut down.

### Decommission vs. Remove

TCM distinguishes between two kinds of node departure:

**Decommission (LEAVE).** The node is alive and participates in streaming its own data out. This is the normal, graceful path.

**Remove (REMOVE).** The node is dead and cannot stream. Other nodes must reconstruct the missing data from remaining replicas. The progress barrier adjusts its expectations to exclude the removed node from acknowledgment requirements.

The operator interface is the same as before:

```bash
$ nodetool decommission          # Graceful departure
$ nodetool removenode <host-id>  # Dead node removal
```

What changes is the internal coordination. Under gossip, a decommission that failed mid-stream left the cluster in a gray area: the node was partially decommissioned, some data had been streamed, but the operation was not complete. Under TCM, the in-progress sequence tracks exactly which step failed, and `abortDecommission` reverts cleanly.

### What Operators Notice

Decommission under TCM is **more predictable** and **easier to monitor**. The three-step progression is visible in logs and in `nodetool cms describe` (the `Is Migrating` field and `multi_step_operation` in the directory). You can see exactly where the operation is at any moment.

The time to decommission is dominated by streaming — how much data the node holds and how fast it can transfer to recipients. TCM does not change the streaming speed. What it eliminates is the gossip propagation overhead at each step and the ambiguity about whether the operation completed successfully.

## No More Ring-Settle Waits

This is perhaps the most impactful operational change, and the one that saves the most cumulative time for operators managing large clusters.

### The Old Ritual

Under gossip, every topology change required a waiting period before the next operation could safely begin. The typical operator workflow looked like this:

```
1. Start bootstrap of node A
2. Wait for bootstrap to complete
3. Wait 30-60 seconds for "ring to settle"
4. Verify with nodetool status
5. Start bootstrap of node B
6. Wait for bootstrap to complete
7. Wait 30-60 seconds for ring to settle
8. Repeat for each node
```

The ring-settle wait existed because gossip propagation was not instantaneous. After a topology change completed, it could take 10-30 seconds for all nodes to learn about the new ring state. If you started a second operation before the first had fully propagated, the second operation might make decisions based on stale ring information — potentially leading to incorrect range assignments or, worse, data placement errors.

Operators added buffer time to be safe. The 30-60 second wait was not based on any specific measurement; it was a convention born from caution. Some operators waited even longer. In a cluster expansion that added 20 nodes, these waits accumulated into 10-20 minutes of pure idle time — doing nothing except hoping gossip had finished.

### Why TCM Eliminates It

TCM replaces eventual consistency with epoch-based ordering and progress barriers. When a topology operation completes (FINISH_JOIN, FINISH_LEAVE, FINISH_MOVE), the final epoch is committed to the log and a progress barrier ensures that affected nodes have acknowledged it. The barrier starts at `EACH_QUORUM` consistency — quorum acknowledgment in every datacenter — before the system considers the operation fully propagated.

This means:

**The next operation can start immediately.** As soon as FINISH_JOIN for node A completes, you can start the bootstrap for node B. There is no propagation delay to wait for, because the progress barrier already confirmed propagation.

**Conflicting operations are rejected, not silently broken.** If node B's bootstrap would affect ranges that are still locked by node A's in-progress operation, the system rejects it with a clear error. You do not need to guess whether it is safe to proceed — the system tells you.

**Non-overlapping operations can run in parallel.** If node A's bootstrap affects token ranges (0, 1000) and node B's bootstrap affects ranges (5000, 6000), both can proceed simultaneously. Range locking detects that there is no overlap and allows both operations to hold their locks concurrently.

### The Time Savings

For a cluster expansion adding 10 nodes sequentially:

| Phase | Gossip Model | TCM Model |
|-------|-------------|-----------|
| Per-node settle wait | 30-60 seconds | 0 seconds |
| Total settle overhead (10 nodes) | 5-10 minutes | 0 minutes |
| Total expansion time | Streaming + 5-10 min overhead | Streaming only |

For parallel expansion where ranges do not overlap, the savings are even greater — multiple bootstraps can proceed simultaneously, reducing total expansion time from sequential to concurrent.

## Range Locking Behavior

Range locking is the mechanism that makes concurrent topology operations safe. It is also the mechanism that tells you, clearly and immediately, when two operations conflict.

### How It Works

Every topology operation — bootstrap, decommission, move, replace — locks the token ranges it affects. The lock is identified by an epoch-based key and covers a set of ranges per replication configuration.

When a new operation is prepared, the system checks whether its ranges intersect with any existing locks:

```
lockedRanges.intersects(newOperationRanges)
  → NOT_LOCKED: proceed
  → Key(epoch): conflict with existing operation at that epoch
```

The intersection check is thorough. It examines ranges per replication parameters (so a lock on ranges for `SimpleStrategy` RF=3 does not block an operation on ranges that only affect `NetworkTopologyStrategy` RF=2 in a different keyspace). It handles token ring wraparound correctly — ranges that span the minimum token value are treated as intersecting with any other range that also spans the minimum.

### What Operators See

If you attempt a topology operation that conflicts with an in-progress one, the operation is rejected before it begins. You do not need to diagnose the conflict yourself — the error tells you which operation holds the conflicting lock.

In practice, range locking means:

**You cannot accidentally run overlapping operations.** Two bootstraps on adjacent token ranges, a bootstrap and a decommission on the same range, a move and a bootstrap that would reassign the same tokens — all are caught and rejected.

**You can safely run non-overlapping operations.** Adding a node in rack 1 while decommissioning a node in rack 3, provided their token ranges do not overlap, is safe and allowed.

**Locks are released automatically.** When a FINISH transformation completes (FINISH_JOIN, FINISH_LEAVE, FINISH_MOVE), the lock is released as part of the metadata commit. There is no manual unlock step.

**Stuck locks indicate stuck operations.** If a lock persists, it means the associated operation is still in progress (or failed and needs to be resumed or aborted). Clearing the lock requires completing or aborting the operation — not manually removing the lock.

## Elimination of Split-Brain Data Loss

This is the change that matters most for data integrity, and it addresses a bug that existed in gossip-based Cassandra for its entire history.

### The Problem

In a gossip-based cluster, different coordinators can observe ring changes at different speeds. Consider this scenario:

```
Time 0:  Node X begins decommission. Gossip starts propagating.
Time 1:  Coordinator A sees the ring change. It knows X is leaving.
         Coordinator A routes a write to replicas {Y, Z} (excluding X).
Time 1:  Coordinator B has NOT yet seen the ring change.
         Coordinator B routes the same write to replicas {X, Z} (including X).

Result:  The write at CL=QUORUM "succeeded" on both coordinators,
         but the replica sets differ. If X finishes decommission
         and its data is gone, Coordinator B's write to X is lost.
```

This is not a theoretical concern. It is a real bug that produces transient data loss during topology changes. The window is small — seconds to tens of seconds — but in a high-throughput cluster, thousands of writes can pass through that window. The data loss is silent: no errors are raised, no warnings are logged. The writes simply go to a node that is about to leave the cluster.

### How TCM Fixes It

TCM eliminates this bug through two mechanisms working together: **epoch-based ordering** and **progress barriers**.

When a decommission begins, the START_LEAVE transformation is committed to the metadata log at a specific epoch. The progress barrier then waits for affected nodes to acknowledge this epoch before the operation proceeds to the streaming phase. This means:

1. **All coordinators see the ring change before streaming begins.** The barrier ensures quorum acknowledgment in every datacenter. A coordinator cannot route writes to the old replica set because it has already applied the epoch that changes the replica set.

2. **Epoch application is atomic.** A node either has applied epoch N (and sees the new replica set) or it has not (and sees the old replica set). There is no intermediate state where the node has "partially" applied the change.

3. **The consistency level cascade provides a safety net.** If some nodes are slow to acknowledge, the barrier degrades gracefully from `EACH_QUORUM` to `QUORUM` to `LOCAL_QUORUM` to `ONE`. At each level, it guarantees that at least the specified number of nodes have seen the change. The degradation produces a log message, alerting operators that some nodes were slow — but the operation proceeds safely.

The result is that coordinators always agree on the current replica set. The quorum inconsistency window is closed.

### What This Means in Practice

For most operators, this change is invisible — you do not notice the absence of a bug. But it has real consequences for clusters that perform topology changes under load:

**No more "drain before decommission" rituals.** Some operators would drain a node (stop accepting writes) and wait before starting decommission, specifically to reduce the risk of lost writes during the gossip propagation window. With TCM, the progress barrier handles this automatically.

**No more reduced-quorum workarounds.** Some operators would temporarily increase the replication factor or write consistency level during topology changes to compensate for the gossip propagation window. This is no longer necessary.

**Topology changes under full production load are safe.** You do not need to reduce traffic, pause writes, or shift load away from affected nodes before starting a bootstrap or decommission. The epoch ordering guarantees that all coordinators will see the change before it takes effect.

## Node Replacement Under TCM

Replacing a failed node follows the same three-step model as bootstrap, with a few differences specific to the replacement scenario.

### The Three Steps

**START_REPLACE.** The replacement node registers itself and marks the node it is replacing. The cluster metadata is updated to reflect that the old node is being replaced. Gossip state for the replaced node is set to "hibernating" — this prevents clients from attempting to write to the dead node during the replacement.

**MID_REPLACE.** The replacement node streams data, but its movement map is different from a standard bootstrap. Instead of deriving sources from the general placement, it specifically identifies the being-replaced node's ranges and streams them from the remaining replicas. Strict movement validation is relaxed — the replacement can rebuild from partial data if necessary, since the replaced node is presumably dead.

**FINISH_REPLACE.** The replacement node assumes the replaced node's tokens. The replaced node is removed from the directory. The replacement node becomes the authoritative replica.

### What Operators Notice

The primary operational difference from gossip-based replacement is **reliability**. Under gossip, host replacement during certain cluster states (mixed-version upgrades, in-progress topology changes) could produce inconsistent metadata. Under TCM, the replacement is a committed metadata operation — it either succeeds atomically or it does not proceed.

The restriction from Chapter 4 bears repeating: do not perform host replacement during the upgrade itself. Replace dead nodes before starting the rolling upgrade, or after completing all three phases.

## Token Moves Under TCM

Token moves — changing which tokens a node owns — are the least common topology operation, but they benefit from the same TCM improvements.

### The Three Steps

**START_MOVE.** The system commits the intent to move, splitting ranges at the new token boundaries. The cluster metadata reflects the new token assignment immediately.

**MID_MOVE.** Streaming occurs. The node streams ranges it needs for its new token position from source nodes, using the same movement map logic as bootstrap. After streaming completes, Paxos state is repaired for the moved ranges.

**FINISH_MOVE.** The old tokens are released, new tokens are finalized, and the node's local token metadata is updated. CMS placement is re-evaluated.

### What Operators Notice

Under gossip, a token move was one of the most operationally painful procedures. After the move completed, operators had to wait for gossip to propagate the new token assignment to all nodes, then verify that the ring was consistent. Under TCM, the epoch ordering guarantees immediate consistency, and the progress barrier confirms it. You can move a token and immediately proceed with the next operation.

## Operator Self-Check

1. Why does TCM remove manual ring-settle waiting after topology operations?
2. What is the operator-visible difference between a rejected conflicting operation and a stalled one?
3. Which mechanisms jointly eliminate split-brain replica-set disagreement?

## Summary

The operational behavior changes under TCM can be summarized in one sentence: **topology operations are now coordinated, predictable, and safe to perform under load.**

The three-step model (START → MID → FINISH) gives every operation a clear structure that is visible in logs, trackable through the metadata, and resumable if interrupted. Progress barriers eliminate the ring-settle wait by confirming that affected nodes have seen each step before the next one begins. Range locking prevents conflicting operations from proceeding, replacing silent failures with explicit rejections. And epoch-based ordering eliminates the split-brain quorum inconsistency that could cause data loss during gossip-based topology changes.

For operators, the day-to-day impact is:

| Operation | Before TCM | After TCM |
|-----------|------------|-----------|
| Bootstrap convergence | 5-30 seconds via gossip | Sub-second via epoch commit |
| Ring-settle wait | 30-60 seconds (manual) | Eliminated (barrier-based) |
| Concurrent operations | Unsafe on overlapping ranges | Safe with range locking |
| Failed operation recovery | Manual cleanup | Resume or abort command |
| Split-brain risk during topology changes | Present (silent data loss) | Eliminated (epoch ordering) |
| Operation progress visibility | Unclear | 3-step model in logs and metadata |

The next chapter covers what happens when things go wrong — the failure playbooks for CMS node loss, interrupted operations, and epoch divergence.
