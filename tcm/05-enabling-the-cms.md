# Chapter 5: Enabling the Cluster Metadata Service (CMS)

Chapter 4 walked you through the three phases of the upgrade. This chapter zooms in on the CMS itself — the Paxos group at the heart of TCM. You will learn how CMS nodes are selected, how many you need, how commits flow through the system, how to monitor its health, and how to reconfigure it as your cluster evolves.

If the distributed metadata log is the ledger that records every metadata change, the CMS is the notary that certifies each entry. Understanding it is essential to operating a TCM-enabled cluster with confidence.

## Learning Objectives

- Describe CMS membership roles and the commit path for metadata transformations.
- Choose a CMS size that matches failure-domain and latency requirements.
- Operate `nodetool cms` workflows for reconfiguration, verification, and troubleshooting.

## What the CMS Actually Is

The Cluster Metadata Service is a subset of your cluster's nodes — typically 3, 5, or 7 — that form a Paxos consensus group. This group has one job: serialize metadata commits. When any node in the cluster wants to make a metadata change (a schema mutation, a node join, a decommission step), that change must be committed through the CMS.

The CMS is not a separate process. It is not a sidecar. It runs inside the Cassandra JVM on the selected nodes, using the same `system_cluster_metadata` keyspace and `distributed_metadata_log` table described in Chapter 2. The difference between a CMS node and a non-CMS node is which code path handles metadata commits.

### CMS Members vs. Non-CMS Nodes

When CMS is initialized, every node in the cluster transitions into one of two states:

**LOCAL state (CMS members).** These nodes participate in Paxos consensus. They use the `PaxosBackedProcessor` to handle metadata transformations. When a commit request arrives — from a local operation or from a remote peer — the CMS member proposes it to the Paxos group, waits for quorum acceptance, and appends the entry to the distributed log.

**REMOTE state (non-CMS nodes).** These nodes do not participate in Paxos voting. They use the `RemoteProcessor`, which forwards commit requests to a CMS member via the `TCM_COMMIT_REQ` messaging verb. They stay in sync by fetching log entries from CMS members or peers through the `PeerLogFetcher`.

The flow looks like this:

```
Non-CMS Node                         CMS Member
─────────────                        ──────────

Wants to create a table
    │
    ├── Build AlterSchema
    │   transformation
    │
    ├── Send TCM_COMMIT_REQ ────────► Receive commit request
    │                                     │
    │                                     ├── Paxos PREPARE
    │                                     │   (propose to CMS quorum)
    │                                     │
    │                                     ├── Paxos ACCEPT
    │                                     │   (quorum agrees)
    │                                     │
    │                                     ├── Paxos COMMIT
    │                                     │   (write to log)
    │                                     │
    ◄── Receive committed entry ─────── Replicate to peers
    │
    ├── Apply transformation
    │   locally
    │
    └── Epoch advances
```

This is the fundamental operational model. Every metadata change follows this path. The CMS serializes all commits, which is how TCM guarantees that every node applies the same changes in the same order.

## Choosing the Right CMS Size

The CMS replication factor determines how many nodes participate in the Paxos group. This is the single most important configuration decision after enabling TCM.

### Sizing Guidelines

| Cluster Size | Recommended CMS RF | Quorum Size | Tolerated Failures |
|-------------|-------------------|-------------|-------------------|
| Small (~12 nodes) | 3 | 2 | 1 |
| Medium (12–50 nodes) | 5 | 3 | 2 |
| Large (50+ nodes) or multi-DC | 7 | 4 | 3 |

The CMS RF must be an odd number. Paxos requires a strict majority for quorum, and odd numbers provide clean majority boundaries. With RF=3, quorum is 2 — you can lose 1 CMS node and continue operating. With RF=5, quorum is 3 — you can lose 2. With RF=7, quorum is 4 — you can lose 3.

### Why Not Higher?

You might think "more is safer." In theory, yes — but in practice, larger Paxos groups have higher commit latency because more nodes must acknowledge each proposal. For metadata operations (which are infrequent compared to data operations), this latency increase is negligible. But there is no operational benefit to RF=9 or RF=11. The metadata itself is tiny, and an RF of 7 already provides failure tolerance well beyond what any realistic failure scenario demands.

### Why Not Lower?

RF=1 is what you get immediately after `nodetool cms initialize`. It is a single point of failure. If that one node goes down, no metadata operations can proceed — no schema changes, no topology changes, no node joins or leaves. Data reads and writes continue (they do not require the CMS), but the cluster is operationally frozen for metadata changes. This is why Phase 3 of the upgrade (Chapter 4) should follow Phase 2 immediately.

## How CMS Placement Works

You do not choose which nodes become CMS members. TCM does it for you, and it does it well.

### The Placement Algorithm

The `CMSPlacementStrategy` selects CMS members using the same rack-diversity principles as `NetworkTopologyStrategy`. The algorithm:

1. **Identifies all eligible nodes** — those in JOINED state and reachable.
2. **Distributes across racks** — no two CMS members should share a rack if possible.
3. **Distributes across datacenters** — in multi-DC deployments, CMS members are spread across DCs.
4. **Maximizes failure domain separation** — the goal is that no single rack failure, and no single DC failure (in multi-DC configurations), can take out a quorum of CMS members.

This is a deliberate design decision. The Cassandra team decided that CMS placement should be automatic, not operator-configured, because manual placement is error-prone and creates operational debt. When you run `nodetool cms reconfigure 5`, the system selects the best 5 nodes based on the current topology. You verify the result with `nodetool cms describe`; you do not micromanage it.

### Placement Anti-Patterns

Even though placement is automatic, there are topology configurations that can undermine it:

**Unbalanced rack distribution.** If your cluster has 3 racks but one rack contains 80% of the nodes, CMS placement is constrained. The algorithm will try to place members across all 3 racks, but with RF=5, at least two members must share a rack. This is not dangerous, but it reduces the failure isolation that CMS placement is designed to provide.

**Single-rack clusters.** If all your nodes are in one rack (or if racks are not configured), CMS placement degenerates to arbitrary node selection. All CMS members are in the same failure domain. Consider configuring racks before enabling TCM if you have not already.

**Unstable availability zones.** If you know that a particular AZ or rack has a history of outages, you cannot directly exclude it from CMS placement. But you can influence placement indirectly by ensuring the cluster topology is well-balanced, which gives the algorithm more options.

## Running `nodetool cms reconfigure`

This is the command that scales CMS from its initial RF=1 to your target configuration.

### Single-Datacenter

```bash
$ nodetool cms reconfigure 3
```

This tells TCM to scale to 3 CMS members, selected automatically for rack diversity.

### Multi-Datacenter

```bash
$ nodetool cms reconfigure dc1:3 dc2:3
```

This distributes CMS members across both datacenters — 3 in each, for a total membership of 6 (technically, an even number works here because the Paxos group sees all 6 as a single quorum).

### What Happens During Reconfiguration

CMS reconfiguration is itself a multi-step metadata operation. Two variants exist:

**Simple reconfiguration.** Used when adding or removing individual CMS members with no concurrent topology changes. This is the common case when you run `nodetool cms reconfigure` in a stable cluster.

**Complex reconfiguration.** Used when CMS membership changes coincide with topology changes — a bootstrap, a replacement, or a move. This variant has higher coordination overhead to ensure consistency during concurrent state changes.

The system decides which variant to use automatically. You do not need to specify it.

During reconfiguration:

1. The system identifies the target CMS membership based on the new RF and the placement strategy.
2. New CMS members receive the distributed metadata log via streaming.
3. New members catch up to the current epoch.
4. Once all new members are synchronized, the membership change is committed.
5. Any removed members transition from LOCAL to REMOTE state.

### Monitoring Reconfiguration

```bash
$ nodetool cms reconfigure --status
```

This reports whether a reconfiguration is in progress, which nodes are being added or removed, and whether the operation has completed.

If reconfiguration is interrupted:

```bash
$ nodetool cms reconfigure --resume    # Pick up where it left off
$ nodetool cms reconfigure --cancel    # Abort and revert
```

### Automatic Reconfiguration After Topology Changes

An important detail: CMS reconfiguration can be triggered automatically after certain topology changes. When a CMS member is decommissioned, replaced, or otherwise leaves the cluster, the system needs to maintain the target CMS RF. TCM handles this by initiating an automatic reconfiguration to replace the departed member. This is controlled by the `cassandra.test.skip_cms_reconfig_after_topology_change` property (default: `false` — meaning automatic reconfiguration is enabled).

## Verifying CMS State

### `nodetool cms describe`

This is your primary tool for inspecting CMS health:

```bash
$ nodetool cms describe
```

The output includes:

| Field | Meaning |
|-------|---------|
| **Members** | List of node IDs that are CMS members |
| **Is Member** | Whether the local node is a CMS member |
| **Service State** | Current CMS state (LOCAL, REMOTE, GOSSIP) |
| **Is Migrating** | Whether a CMS reconfiguration is in progress |
| **Epoch** | Current metadata epoch |

Check this command after initialization, after reconfiguration, and whenever you suspect a CMS issue.

### `nodetool cms dumpdirectory`

For deeper inspection of the node directory (all registered nodes, their states, addresses, and versions):

```bash
$ nodetool cms dumpdirectory --tokens    # Include token assignments
```

### `nodetool cms dumplog`

To inspect the distributed metadata log itself:

```bash
$ nodetool cms dumplog --start 1 --end 100    # Dump epochs 1 through 100
```

This is primarily a debugging tool. You should not need it in normal operations, but it is invaluable when diagnosing unexpected metadata behavior.

## Monitoring CMS Health

### Key Metrics

**Log watermark.** This is the most important CMS metric. Each node tracks which epoch it has applied — its "watermark" in the metadata log. You can query any node's current epoch through JMX or through `nodetool cms describe`. If a node's watermark is significantly behind the cluster's current epoch, it is not receiving or applying metadata updates promptly.

**Epoch progression.** The current epoch should advance whenever a metadata change occurs — a schema change, a topology operation, a CMS reconfiguration step. If the epoch is stagnant during a period when metadata changes are expected, investigate CMS health.

**CMS member availability.** Monitor the UP/DOWN status of CMS members the same way you monitor any node. If enough CMS members go down to break quorum, metadata operations will stall. Data reads and writes continue unaffected, but no new schema changes, node joins, or decommissions can proceed until quorum is restored.

### The Reality of CMS Monitoring

Here is a reassuring data point from the TCM development team: **CMS nodes and followers have never been observed to lag in practice.** The metadata payload is tiny — a schema change or a topology operation produces a few kilobytes of log data. Even under heavy metadata change load, the CMS log propagates to all nodes within milliseconds.

This does not mean you should skip monitoring. It means that if you see a node lagging behind on epoch, the problem is almost certainly a network partition or a node health issue — not a CMS performance bottleneck. Treat epoch lag as a symptom, not a disease.

## How Nodes Stay in Sync

### The PeerLogFetcher

Non-CMS nodes do not participate in Paxos consensus, so they do not learn about new log entries through the commit process. Instead, they rely on the `PeerLogFetcher` — a background process that discovers and retrieves missing log entries.

The fetch process works in three phases:

1. **Discovery.** The node compares its local epoch (from `ClusterMetadata.current().epoch`) to the cluster's current epoch. If there is a gap, it knows entries are missing.

2. **Fetch.** The node requests missing entries from a CMS member or any peer that has them. CMS members are preferred (they are the authoritative source), but any peer with the entries will do. Entries are transferred using the `TCM_FETCH_CMS_LOG` and `TCM_REPLICATION` messaging verbs.

3. **Apply.** Entries are applied in strict epoch order. Each transformation updates the local `ClusterMetadata` state and advances the node's watermark. This guarantees that every node applies the same transformations in the same sequence.

### Metadata Snapshots

For nodes that are very far behind — newly bootstrapped nodes, or nodes returning after extended downtime — replaying the entire log from epoch 1 would be inefficient. TCM addresses this with metadata snapshots.

A snapshot is a serialized copy of the complete `ClusterMetadata` at a specific epoch. It includes the directory, token map, schema, locked ranges, and in-progress sequences — everything the log encodes, but as a single point-in-time image rather than a sequence of transformations.

Snapshots are triggered automatically at strategic points: after CMS initialization, after major topology changes, and periodically during steady-state operation. The `MetadataSnapshotListener` watches for appropriate moments and triggers snapshot creation.

When a lagging node needs to catch up, it can request a snapshot instead of replaying hundreds or thousands of log entries. It loads the snapshot as its base state, then replays only the entries after the snapshot's epoch. This dramatically reduces catch-up time and I/O load.

## CMS Failover

### What Happens When a CMS Member Goes Down

Paxos is designed for exactly this scenario. When a CMS member becomes unreachable:

1. **The remaining members continue operating.** As long as a quorum is available (more than half the CMS members), metadata commits proceed normally. A 5-member CMS can lose 2 members and continue. A 3-member CMS can lose 1.

2. **No explicit leader election is needed.** Paxos does not have a single leader. Any CMS member can propose a commit. When one member goes down, the others naturally take over its proposer role. There is no failover delay, no election process, no split-brain risk.

3. **Non-CMS nodes are unaffected.** They continue sending commit requests to any reachable CMS member. If their preferred CMS member is down, they route to another one.

### What Happens When Quorum Is Lost

If enough CMS members go down to break quorum (more than half), metadata operations stall. This is a serious operational event, but it is contained:

**Data operations continue.** Reads and writes are completely unaffected. The CMS only handles metadata — token ownership, schema, cluster membership. Once this metadata is established, data operations do not consult the CMS.

**Metadata operations block.** No new schema changes, no topology changes, no node joins or leaves until quorum is restored.

**Recovery is straightforward.** Bring CMS members back online. Once quorum is restored, pending commits (if any) complete automatically. No manual intervention is needed — Paxos handles the recovery.

### The Worst Case: All CMS Members Lost

If every CMS member is permanently lost (an extraordinary scenario requiring the simultaneous permanent loss of 3, 5, or 7 nodes depending on your RF), there is an emergency escape hatch: you can nominate one surviving node as a CMS member via a local metadata update and force its view of the world onto all remaining nodes. This is a manual intervention procedure documented in Chapter 8 (Failure Playbooks) and is not something any production cluster should ever need — provided the CMS RF is sized appropriately for the cluster's failure domain characteristics.

## Progress Barriers

After a metadata commit, TCM does not simply broadcast the change and hope for the best. It uses **progress barriers** to ensure that metadata changes have propagated to affected nodes before dependent operations proceed.

A progress barrier works like this: after committing a transformation, the system queries affected nodes using the `TCM_CURRENT_EPOCH_REQ` verb to verify that they have applied the entry. It expects a response confirming that the remote node's epoch is at least as high as the committed epoch.

The barrier uses a configurable consistency level with automatic fallback:

```
EACH_QUORUM  ──►  QUORUM  ──►  LOCAL_QUORUM  ──►  ONE  ──►  NODE_LOCAL
  (default)       (fallback)    (fallback)     (fallback)   (last resort)
```

At each level, the barrier retries every second (configurable via `progress_barrier_backoff`) for up to 30 seconds before falling back to the next lower level. At `NODE_LOCAL`, the barrier always succeeds — the local node has already applied the change by definition.

This fallback mechanism ensures that metadata operations are never permanently blocked by a few slow or unreachable nodes, while still providing strong propagation guarantees under normal conditions.

## CMS Configuration Reference

| Property | Default | Purpose |
|----------|---------|---------|
| `progress_barrier_default_consistency_level` | `EACH_QUORUM` | Consistency level for verifying metadata propagation |
| `progress_barrier_timeout` | `3600000ms` | Maximum total wait for propagation |
| `progress_barrier_backoff` | `1000ms` | Retry interval between propagation checks |
| `discovery_timeout` | `30s` | Timeout for initial peer discovery |
| `unsafe_tcm_mode` | `false` | Enables emergency recovery operations via JMX |

CMS replication factor is managed via `nodetool cms reconfigure`, not `cassandra.yaml`. It can be changed without a node restart.

## Nodetool CMS Command Reference

| Command | Purpose |
|---------|---------|
| `nodetool cms describe` | Show CMS state, members, epoch, migration status |
| `nodetool cms initialize [--ignore <ips>]` | Initialize CMS from gossip state |
| `nodetool cms abortinitialization --initiator <ip>` | Abort a failed initialization |
| `nodetool cms reconfigure <rf>` | Change CMS replication factor |
| `nodetool cms reconfigure --status` | Check reconfiguration progress |
| `nodetool cms reconfigure --resume` | Resume interrupted reconfiguration |
| `nodetool cms reconfigure --cancel` | Cancel in-progress reconfiguration |
| `nodetool cms snapshot` | Force a metadata snapshot |
| `nodetool cms unregister <nodeId>` | Unregister a node in LEFT state |
| `nodetool cms dumpdirectory [--tokens]` | Dump the node directory |
| `nodetool cms dumplog [--start N] [--end N]` | Dump metadata log entries |

## Operator Self-Check

1. How does a non-CMS node commit metadata changes after TCM is enabled?
2. What tradeoff changes when moving from CMS RF=3 to RF=5 or RF=7?
3. Which command sequence validates that reconfiguration completed cleanly?

## Summary

The CMS is a small, automatic, self-managing Paxos group embedded in your Cassandra cluster. You configure its size once (via `nodetool cms reconfigure`), the placement algorithm distributes members across failure domains, and the system handles failover, log replication, and node synchronization without operator intervention.

The operational model is simple: monitor CMS member availability the same way you monitor any Cassandra node, watch for epoch lag as a canary for network or node health issues, and trust that the CMS will handle its own internal consistency through Paxos.

The CMS exists so that you do not have to think about metadata consistency anymore. Once it is configured, the next chapter — validation — shows you how to confirm that it is working correctly.
