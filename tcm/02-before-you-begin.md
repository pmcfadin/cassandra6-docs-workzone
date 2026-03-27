# Chapter 2: Before You Begin (Pre-Upgrade Requirements)

Every upgrade guide begins with prerequisites, and most operators skim them. Do not skim this one. The transition to Transactional Cluster Metadata is not a routine patch — it is a fundamental change to how your cluster manages its own identity. The good news is that the requirements are straightforward. The bad news is that violating them will stop the migration cold, and in some cases the error messages will be more informative than you are accustomed to from Cassandra.

This chapter covers everything you need to verify before you type a single `nodetool` command.

## Learning Objectives

- Validate version, network, and cluster-state prerequisites before migration.
- Explain why schema and topology changes are prohibited during the mixed-version window.
- Build a pre-upgrade checklist that prevents avoidable initialization failures.

## Version Prerequisites

TCM was introduced in **Cassandra 6.0** as part of CEP-21. It is not available in 4.x or 5.x. The version you are running today determines your upgrade path.

### The Recommended Path

The best-tested upgrade path is:

```
4.0 / 4.1 / 5.0  ──►  6.0  ──►  Initialize CMS
```

If you are on Cassandra 3.x, you must first upgrade to the latest 4.0 release before proceeding to 6.0. Direct jumps from 3.x to 6.0 are not supported.

### Why 6.0 Is the Threshold

The TCM subsystem uses a metadata serialization version to distinguish pre-TCM nodes from TCM-capable ones. Inside the codebase, the `NodeVersion` class defines this boundary:

```java
private static final CassandraVersion SINCE_VERSION = CassandraVersion.CASSANDRA_6_0;
public static final Version CURRENT_METADATA_VERSION = Version.V8;

public boolean isUpgraded() {
    return serializationVersion >= Version.V0.asInt();
}
```

When a node reports a Cassandra version of 6.0 or later, it receives metadata version `V8` and `isUpgraded()` returns `true`. Pre-6.0 nodes are tagged as `Version.OLD`. During CMS initialization, every non-LEFT node in the cluster must pass the `isUpgraded()` check or the migration will be rejected with an explicit error:

```
All nodes are not yet upgraded - /10.0.1.42:7000 is running <version>
```

There is no override for this check. Either the node is on 6.0+, or it blocks the migration. The only exception is nodes you explicitly choose to ignore (covered below).

### The Messaging Service Version

Understanding why version matters requires understanding a related system: the messaging service. Cassandra assigns an integer version to its inter-node messaging protocol:

| Cassandra Version | Messaging Version |
|-------------------|-------------------|
| 3.0               | 10                |
| 4.0               | 12                |
| 5.0               | 13                |
| 6.0               | 14                |

This matters because schema mutations have historically only been sent to nodes running the same messaging version. This is not a TCM-specific constraint — it has been true since Cassandra 3.0 — but it is critical context for the schema discussion later in this chapter.

## Network Assumptions

The network requirement is simple: **all nodes in the cluster should be up and running the same version before you initialize CMS.**

This is not strictly a TCM-imposed constraint. Running a major version upgrade with down nodes has never been recommended, regardless of the Cassandra version. TCM does not change this guidance — but it does enforce it more visibly.

During CMS initialization, the initiating node contacts every known peer to verify that their metadata matches. If a node is down, it cannot respond, and the initialization will report a mismatch. You have two options:

1. **Bring the node up** on the new version before initializing.
2. **Explicitly ignore the node** using the `--ignore` flag (see Chapter 5).

The `--ignore` flag exists for nodes that are genuinely unreachable — hardware failures, decommissioned-but-not-yet-removed nodes, and similar situations. It is not a shortcut for skipping nodes you haven't upgraded yet.

### What "Agreement" Means

When the documentation says "all nodes must be in agreement," it means something specific and verifiable. During CMS initialization, the `Election.PrepareHandler` runs three checks against every peer:

**Directory match.** The initiating node's view of the cluster directory — every node ID, its state, and its endpoint address — must be identical to the peer's view. If they differ, the peer logs the diff and rejects the initialization.

**TokenMap match.** The token-to-node mapping must be identical. If coordinator A thinks node X owns tokens 100–200 but coordinator B disagrees, the initialization fails. This is exactly the kind of inconsistency that TCM is designed to eliminate, but it must not exist at the moment of migration.

**Schema digest match.** Both nodes compute a digest of their schema using `SchemaKeyspace.calculateSchemaDigest()`. If the digests differ — because a schema change was applied to some nodes but not others — the initialization fails.

If any check fails, you will see:

```
Got mismatching cluster metadatas. Check logs on peers ([/10.0.1.42:7000])
```

The peer's logs will contain the specific diff. This is a feature, not a bug — TCM refuses to start with an inconsistent foundation.

## Storage Format Assumptions

There are none. TCM works with every storage format Cassandra supports: legacy SSTables, BIG format, BTI format — it does not matter. Token ownership, schema, and cluster membership are metadata concerns, not storage concerns. Your on-disk data is unchanged by the migration.

## Client-Driver Implications

There are none. Client drivers connect to Cassandra via the native protocol, discover nodes through `system.peers` and `system.local`, and receive topology change events through the event channel. All of these mechanisms continue to work identically after TCM is enabled. The `ClientNotificationListener` in the TCM subsystem ensures that topology events are pushed to connected clients just as they were under gossip.

You do not need to upgrade your drivers, change your connection configuration, or modify your application code.

## The Truth About Schema Changes During Upgrades

This section addresses two widely held misconceptions. If you take nothing else from this chapter, take this.

### Misconception 1: "Schema Changes Work During Major Version Upgrades"

**They do not.** They have not worked reliably since Cassandra 3.0, and possibly longer.

Here is why: Cassandra's messaging service assigns a protocol version to each node. Schema mutations are only sent to nodes running the same messaging version. During a rolling upgrade — when half your nodes are on version N and the other half are on version N+1 — the two halves are running different messaging versions. A schema change issued on an upgraded node will not be disseminated to the non-upgraded nodes. The upgraded node does not log an error. The non-upgraded nodes do not know they missed anything. The schema simply diverges, silently.

If you have performed schema changes during a rolling upgrade in the past and nothing went wrong, you got lucky. Either both versions happened to share the same messaging version (some minor releases do), or the divergence was masked by a subsequent schema pull after all nodes reached the same version.

**TCM does not change this fundamental constraint** — schema changes during a mixed-version window are still prohibited. What TCM does change is the failure mode. Instead of silently not propagating the mutation, TCM will actively reject the commit. You will see an error message explaining that the operation is not permitted. This is a substantial improvement: an explicit rejection is infinitely preferable to silent divergence.

### Misconception 2: "I Can Create Tables with New Parameters During Upgrade"

In a pre-TCM cluster, if you create a table during a rolling upgrade using a parameter that only the new version understands — say, a new compression algorithm or a new compaction option — the schema mutation will be sent to nodes on the old version. Those nodes cannot parse the unfamiliar parameter. The result depends on timing and luck: the schema mutation might fail to apply on the old nodes, leaving them with a stale schema, or it might cause an outright error that destabilizes the node.

Under TCM, this scenario is handled cleanly. The `AlterSchema` transformation includes a compatibility check:

```java
public boolean eligibleToCommit(ClusterMetadata metadata) {
    return schemaTransformation.compatibleWith(metadata);
}
```

The `compatibleWith` method inspects the cluster's minimum version (tracked in the `Directory` as `clusterMinVersion`) and rejects the transformation if any node in the cluster cannot support it. The commit returns a `Rejected` result before the change is applied to any node. Your cluster remains consistent.

### The Practical Rule

**Do not make schema changes until all nodes are on the same version and CMS has been initialized.** This rule applied before TCM — it was just silently unenforced. Now it is explicit.

## What Operations Are Prohibited During the Upgrade Window

Between starting the rolling upgrade and completing CMS initialization, the following metadata-changing operations must not be performed:

- **Schema changes** (CREATE, ALTER, DROP for keyspaces, tables, types, functions, aggregates)
- **Node bootstrap** (adding new nodes)
- **Node decommission** (removing existing nodes)
- **Node move** (reassigning tokens)
- **Node replacement** (replacing a dead node with a new one)
- **Assassinate** (forcibly removing a node from the ring)

Once all nodes are on 6.0 and you have successfully run `nodetool cms initialize`, all of these operations become available again — now backed by TCM's transactional guarantees.

> **Tip:** If you have automation that can trigger any of these operations — auto-scaling policies, scheduled maintenance scripts, orchestration systems — **disable it** before starting the rolling upgrade. Re-enable it only after CMS initialization completes. An upgraded node will reject these operations, but a node still running the previous version may attempt them through the old gossip path with unpredictable results.

## The `system_cluster_metadata` Keyspace

When CMS is initialized, Cassandra creates a new system keyspace: `system_cluster_metadata`. This keyspace contains the distributed metadata log — the backbone of TCM.

The primary table is `distributed_metadata_log`:

```sql
CREATE TABLE system_cluster_metadata.distributed_metadata_log (
    epoch bigint PRIMARY KEY,
    entry_id bigint,
    transformation blob,
    kind int
)
```

Each row represents a single epoch — one atomic metadata change. The `transformation` column contains the serialized change (a node joining, a schema mutation, a decommission step), and `kind` identifies the transformation type. The table uses Time-Window Compaction Strategy with one-day windows, which is appropriate for an append-mostly log.

At initialization, this keyspace is created with `SimpleStrategy` and a replication factor of 1 on the initiating node. Once initialization completes, you reconfigure it for production resilience using `nodetool cms reconfigure` (covered in detail in Chapter 5).

You should never need to query this table directly, but knowing it exists helps demystify what TCM is doing under the hood: maintaining an ordered, replicated log of every metadata change, stored in a Cassandra table, replicated across CMS nodes using Paxos.

## Configuration

TCM introduces very little new configuration. The most significant property in `cassandra.yaml` is:

**`unsafe_tcm_mode`** (default: `false`) — Enables unsafe TCM operations for recovery and debugging. This unlocks operations like `unsafeRevertClusterMetadata` and `unsafeLoadClusterMetadata` through JMX. Leave this `false` in production unless you are following an emergency recovery procedure with full understanding of the consequences.

The following properties control TCM's progress barrier — the mechanism that ensures metadata changes have propagated before certain operations proceed:

| Property | Default | Purpose |
|----------|---------|---------|
| `progress_barrier_default_consistency_level` | `EACH_QUORUM` | Consistency level for verifying metadata propagation |
| `progress_barrier_timeout` | `3600000ms` (1 hour) | Maximum wait for propagation to complete |
| `progress_barrier_backoff` | `1000ms` | Retry interval when waiting for propagation |
| `discovery_timeout` | `30s` | Timeout for initial peer discovery |

For most clusters, the defaults are appropriate. Tuning these values is only necessary in environments with unusual network latency characteristics or very large cluster sizes.

Notably, the CMS replication factor is **not** configured in `cassandra.yaml`. It is managed dynamically via `nodetool cms reconfigure` and can be changed without a restart.

## Pre-Upgrade Checklist

Before beginning the rolling upgrade, verify every item:

- [ ] **Current version is 4.0, 4.1, 5.0, or 5.x.** If on 3.x, upgrade to latest 4.0 first.
- [ ] **All nodes are up and healthy.** Run `nodetool status` on every node and confirm `UN` (Up/Normal) for all.
- [ ] **All nodes are running the same version.** No mixed-version state before the rolling upgrade begins.
- [ ] **Schema is converged.** Run `nodetool describecluster` and confirm a single schema version across all nodes.
- [ ] **No topology operations are in flight.** No ongoing bootstraps, decommissions, or moves.
- [ ] **No repairs are in progress.** Complete or cancel any active repair sessions.
- [ ] **Automation is disabled.** Auto-scaling, scheduled topology changes, and automated schema migrations are paused.
- [ ] **You have a rollback plan.** Know how to revert nodes to the previous version if the upgrade encounters problems.
- [ ] **You have read Chapter 4 (Rolling Upgrade Strategy).** Understand the step-by-step process before starting.

## Operator Self-Check

1. What three preconditions must be true before running `nodetool cms initialize`?
2. Why are schema changes during a major rolling upgrade unsafe, even before TCM?
3. Which automation systems should be paused before entering the upgrade window?

## Summary

The requirements for enabling TCM are deliberately conservative. The Cassandra team chose to make the migration fail loudly when preconditions are not met, rather than allow it to proceed on a shaky foundation. This is a philosophical shift from the gossip era, where many operations would attempt to proceed regardless of cluster state and hope for eventual convergence.

The core requirements reduce to three points: every node must be on 6.0 or later, every node must agree on the current state of the cluster (directory, tokens, and schema), and no metadata-changing operations can run between the start of the upgrade and the completion of CMS initialization.

If those three conditions are met, you are ready to begin. Turn to Chapter 3 for the detailed readiness assessment, or skip directly to Chapter 4 for the rolling upgrade procedure.
