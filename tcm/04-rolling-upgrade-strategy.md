# Chapter 4: Rolling Upgrade Strategy

The previous chapters established what TCM is, what prerequisites must be met, and how to verify readiness. This chapter is the procedure itself — the step-by-step sequence from "cluster running pre-TCM Cassandra" to "cluster running with TCM fully initialized."

If you have performed a rolling upgrade of Cassandra before, the mechanics will be familiar. What is different is the final step: after all nodes are on the new version, you must explicitly initialize the Cluster Metadata Service. This is a new operation with no precedent in previous upgrades, and it deserves your full attention.

## Learning Objectives

- Run the three-phase upgrade flow without introducing metadata inconsistency.
- Enforce hard safety constraints during the mixed-version interval.
- Manage down-node cases and understand rollback boundaries before and after initialization.

## The Three Phases

A TCM upgrade is not a single operation. It is three distinct phases, each with its own rules and constraints:

```
Phase 1                    Phase 2                    Phase 3
Rolling Binary          ─► CMS                     ─► CMS
Upgrade                    Initialization              Reconfiguration

All nodes upgraded         First CMS member            CMS scaled to
one at a time              established (RF=1)          production RF

Duration: hours            Duration: 1-2 minutes       Duration: minutes
Risk: low (reversible)     Risk: medium (commit point)  Risk: low
```

**Phase 1** is a standard rolling upgrade — the same procedure you have used for every previous Cassandra version bump. The cluster remains in gossip mode throughout. This phase is fully reversible.

**Phase 2** is the commit point. Running `nodetool cms initialize` creates the distributed metadata log and transitions the cluster from gossip-managed to TCM-managed metadata. After this point, reverting to gossip requires significant manual effort.

**Phase 3** scales the CMS from its initial single-node configuration to a production-resilient Paxos group. This is a metadata operation that takes minutes and does not affect data availability.

## Phase 1: Rolling Binary Upgrade

### The Procedure

Upgrade nodes one at a time, rack by rack, datacenter by datacenter. This is standard Cassandra operational procedure. For each node:

**Step 1. Drain the node.**

```bash
$ nodetool drain
```

This flushes all memtables to SSTables and stops accepting new connections. The node's data is safely persisted on disk.

**Step 2. Stop the Cassandra process.**

```bash
$ sudo systemctl stop cassandra
```

Or whatever process management system your deployment uses.

**Step 3. Install the new Cassandra version.**

Replace the Cassandra binaries with the 6.0 (or later) release. Your package manager, configuration management tool, or container image handles this step. Preserve your `cassandra.yaml`, `cassandra-env.sh`, and any other customized configuration files.

**Step 4. Start the node on the new version.**

```bash
$ sudo systemctl start cassandra
```

**Step 5. Wait for the node to rejoin the cluster.**

```bash
$ nodetool status
```

Confirm the node shows `UN` (Up/Normal) and that gossip has settled. Check the system log for:

```
Gossip settled after X ms
```

**Step 6. Verify the node is healthy before moving to the next one.**

```bash
$ nodetool describecluster
```

Confirm that the schema version count has not increased (you should see at most two schema versions — one for upgraded nodes, one for not-yet-upgraded nodes, which is expected during the rolling upgrade).

### What the Cluster Looks Like During Phase 1

While the rolling upgrade is in progress, the cluster is in a **mixed-version state**. Some nodes are running the old version; others are running 6.0. During this window:

**Gossip continues to manage everything.** Even though the upgraded nodes contain the TCM code, they operate in `GOSSIP` mode — the `ClusterMetadataService` state that indicates TCM is present but not yet activated. From the cluster's perspective, nothing has changed yet.

**Metadata operations are blocked on upgraded nodes.** An upgraded node in `GOSSIP` mode will reject any attempt to commit a TCM transformation. If you accidentally issue a schema change from an upgraded node, you will see:

```
Can't commit transformations when running in gossip mode
```

This is a safety mechanism. The upgraded node knows it has TCM capabilities but also knows the cluster has not yet transitioned. It refuses to create metadata through the new path when the old path is still active.

**Non-upgraded nodes do not know about TCM.** They continue operating exactly as they did before the upgrade began. They send and receive gossip, they process schema changes (if you issue them from a non-upgraded node — which you should not), and they are completely unaware that their peers have new capabilities.

**The messaging version boundary is respected.** Cassandra 5.0 uses messaging version 13; Cassandra 6.0 uses version 14. During the mixed-version window, inter-node communication uses the lower of the two versions for any given pair. This is why schema propagation across the version boundary does not work — it has never worked across messaging version boundaries.

### The Pace of Upgrades

There is no mandatory waiting period between upgrading individual nodes, beyond confirming that each node has rejoined the cluster successfully. However, a few practical guidelines apply:

**Upgrade one rack at a time.** This ensures that if something goes wrong with a rack's worth of nodes, the cluster retains quorum in the remaining racks.

**Do not upgrade all nodes in a datacenter simultaneously.** Even if your deployment tooling supports parallel upgrades, resist the temptation. A rolling upgrade that takes an hour is far preferable to a parallel upgrade that takes ten minutes but risks a quorum outage if the new version has a startup issue.

**Complete the upgrade within a maintenance window.** The mixed-version state is not dangerous in itself, but it is a period during which no metadata operations can safely occur. The longer the window, the higher the chance that someone or something triggers a blocked operation.

## The "Do Not Do This" List

These are not guidelines. They are hard constraints.

**Do not perform host replacements during the upgrade.** If you have a dead node that needs replacing, do one of two things: replace it *before* you begin the rolling upgrade (while all nodes are still on the old version), or complete the entire upgrade (all three phases) and replace it afterward. Host replacement during a mixed-version state is dangerous because the replacement node must agree on metadata with all its peers, and during mixed-mode the metadata management path is ambiguous.

**Do not issue schema changes during the upgrade.** Not from upgraded nodes, not from non-upgraded nodes, not from any node. On upgraded nodes, schema changes will be explicitly rejected. On non-upgraded nodes, schema changes will appear to succeed but may not propagate to upgraded peers (because of the messaging version boundary). Either outcome is bad.

**Do not bootstrap new nodes during the upgrade.** A new node joining the cluster requires token assignment and streaming coordination — both are metadata operations that cannot safely occur during the mixed-version window.

**Do not decommission nodes during the upgrade.** Decommission is a multi-step metadata operation. It cannot begin in gossip mode and complete in TCM mode, or vice versa.

**Do not run `nodetool move` during the upgrade.** Token moves are metadata operations subject to the same constraints as bootstrap and decommission.

**Do not run `nodetool assassinate` during the upgrade.** Forcible node removal modifies the cluster directory. Save it for after Phase 3.

**Do not change `storage_compatibility_mode` during the upgrade.** This setting affects messaging version caps and metadata serialization. Leave it at its default until the upgrade is complete.

### What You Can Do Safely

Read operations, write operations, and queries continue to work throughout the upgrade. Clients are unaffected. Compaction runs normally. Streaming for repair is safe at the individual-node level (though you should have completed cluster-wide repairs before starting, as recommended in Chapter 3). Monitoring, backups, and snapshots all continue to function.

The cluster remains fully available for its primary purpose — serving data — throughout all three phases.

## Phase 2: CMS Initialization

Once every node is running 6.0 and you have confirmed readiness (Chapter 3's checklist), you are ready to initialize the Cluster Metadata Service.

### Step-by-Step

**Step 1. Choose the initiating node.**

Pick a stable, JOINED node with good network connectivity to all peers. This node will become the first CMS member.

**Step 2. Run the initialize command.**

```bash
$ nodetool cms initialize
```

Or, if you have nodes that are permanently down and will not return:

```bash
$ nodetool cms initialize --ignore 10.0.1.50,10.0.1.51
```

**Step 3. Watch the output.**

A successful initialization looks like this:

```
Initializing CMS...
Verifying cluster metadata agreement...
All peers agree on cluster metadata.
CMS initialized successfully. Current epoch: 1
```

If it fails, refer to the error reference in Chapter 3. The most common failures are:

- A node is unreachable (add to `--ignore` or bring it up)
- Schema disagreement (resolve with `nodetool describecluster` and `nodetool resetlocalschema` if needed)
- A node is still on the old version (complete the binary upgrade first)

**Step 4. Verify initialization.**

```bash
$ nodetool cms describe
```

This should show the CMS state, including the current epoch, the single CMS member (the initiating node), and the replication configuration.

### What Happens Under the Hood

When you run `nodetool cms initialize`, the following sequence executes:

1. **Validation.** The five gates from Chapter 3 are checked: no self-ignore, valid ignore endpoints, initiating node is JOINED, all nodes are upgraded, CMS is not already initialized.

2. **Election.** The initiating node broadcasts a `CMSInitializationRequest` to every non-ignored peer. Each peer compares its directory, token map, and schema digest against the initiator's. All must match.

3. **PreInitialize transformation.** The first entry in the distributed metadata log is committed. This marks the beginning of the TCM era. The `system_cluster_metadata` keyspace is created with its `distributed_metadata_log` table.

4. **Initialize transformation.** The second log entry captures the full cluster metadata snapshot — every node, every token, every schema definition — as the baseline state at Epoch 1.

5. **State transition.** The initiating node transitions from `GOSSIP` to `LOCAL` state (it is now a CMS member). All other nodes transition from `GOSSIP` to `REMOTE` state (they are now TCM participants that commit metadata through the CMS). The `LegacyStateListener` begins feeding TCM-managed state back into gossip for compatibility.

6. **Snapshot.** A metadata snapshot is triggered, persisting the initial state for fast recovery.

This entire process typically completes in 1–2 minutes on a healthy cluster. It does not involve data streaming or SSTable manipulation — it is purely a metadata operation.

### The Point of No Return

Phase 2 is the commit point. Once `nodetool cms initialize` succeeds:

- The `system_cluster_metadata` keyspace exists on disk.
- All nodes have transitioned out of `GOSSIP` mode.
- The distributed metadata log is the authoritative source for token ownership, schema, and cluster membership.
- Gossip continues to run but now receives its metadata state from TCM via the `LegacyStateListener`.

**Reverting from this point is not a supported operation.** While it is technically possible to migrate back from TCM to gossip, doing so requires manual intervention and is not a simple rollback. The design of the upgrade process is intentional: Phase 1 is fully reversible (just downgrade the binaries), giving you ample opportunity to validate. Phase 2 is the commitment. Make sure the checklist is green before you execute it.

## Phase 3: CMS Reconfiguration

After initialization, the CMS has a replication factor of 1 — only the initiating node is a CMS member. This is a single point of failure for metadata operations. You need to scale it up immediately.

### Step-by-Step

**Step 1. Determine your target replication factor.**

The sizing guidelines from the outline:

| Cluster Size | Recommended CMS RF |
|-------------|-------------------|
| Small (~12 nodes) | 3 |
| Medium-large | 5 |
| Very large or multi-DC | 7 |

The CMS RF must be an odd number (it is a Paxos group, so odd numbers provide clean majority quorums).

**Step 2. Run the reconfigure command.**

For a single-datacenter cluster:

```bash
$ nodetool cms reconfigure 3
```

For a multi-datacenter cluster, specify per-datacenter:

```bash
$ nodetool cms reconfigure dc1:3 dc2:3
```

**Step 3. Monitor the reconfiguration.**

```bash
$ nodetool cms reconfigure --status
```

This shows the progress of the reconfiguration: which nodes are being added, whether streaming is in progress, and whether the operation has completed.

**Step 4. Verify the final state.**

```bash
$ nodetool cms describe
```

Confirm that the CMS membership matches your target RF, and that nodes are distributed across racks and (if applicable) datacenters.

### How CMS Placement Works

You do not choose which nodes become CMS members. TCM elects them automatically using a placement strategy that maximizes rack diversity — the same principle behind `NetworkTopologyStrategy` for data replicas. The algorithm selects nodes across different racks (and datacenters, in multi-DC deployments) to ensure that no single rack failure can take out a quorum of CMS members.

This is a deliberate design choice. Operators should not need to maintain a mental model of which specific nodes are CMS members. The system handles placement, and you can verify it with `nodetool cms describe`.

### Handling Reconfiguration Failures

If reconfiguration is interrupted — by a node failure, a network partition, or an operator cancellation — you have two options:

**Resume the operation:**

```bash
$ nodetool cms reconfigure --resume
```

This picks up where the reconfiguration left off.

**Cancel the operation:**

```bash
$ nodetool cms reconfigure --cancel
```

This aborts the in-progress reconfiguration and reverts to the previous CMS configuration. You can then retry with different parameters.

## Handling Down Nodes

Down nodes are a fact of life in distributed systems. TCM handles them at every phase:

**During Phase 1 (rolling upgrade):** A down node does not prevent you from upgrading other nodes. Just skip it in your upgrade sequence and upgrade it when it comes back. If it will never come back, plan to ignore it during Phase 2.

**During Phase 2 (CMS initialization):** Use the `--ignore` flag to exclude permanently down nodes. The flag tells the election process to skip these nodes during the metadata agreement check. Ignored nodes do not need to be on the new version, do not need to respond to the initialization request, and will not block the process.

When an ignored node eventually restarts — either on the old version or after being upgraded — it will detect that CMS has been initialized and fetch the current metadata from the distributed log. It catches up automatically. There is no manual intervention needed.

**During Phase 3 (CMS reconfiguration):** CMS reconfiguration can work around down nodes. The placement algorithm will select from available nodes. If a down node is already a CMS member (unlikely in the initial configuration, but possible if the initiating node goes down between Phase 2 and Phase 3), the reconfiguration will account for it.

## The Complete Procedure

Here is the entire upgrade distilled into a single reference sequence:

```
PRE-UPGRADE
├── Complete all repairs
├── Disable automation (auto-scaling, scheduled DDL, repair cron)
├── Run Chapter 3 readiness checklist
└── Confirm rollback plan

PHASE 1: ROLLING BINARY UPGRADE
├── For each node (rack by rack, DC by DC):
│   ├── nodetool drain
│   ├── Stop Cassandra
│   ├── Install 6.0 binaries
│   ├── Start Cassandra
│   ├── Wait for UN status
│   └── Verify with nodetool describecluster
├── Confirm all nodes are on 6.0
└── Run Chapter 3 readiness checklist again

PHASE 2: CMS INITIALIZATION
├── Choose initiating node
├── nodetool cms initialize [--ignore <down-nodes>]
├── nodetool cms describe (verify success)
└── Confirm epoch is advancing

PHASE 3: CMS RECONFIGURATION
├── nodetool cms reconfigure <target-rf>
├── nodetool cms reconfigure --status (monitor)
├── nodetool cms describe (verify final state)
└── Re-enable automation

POST-UPGRADE
├── Verify nodetool status shows all UN
├── Verify nodetool describecluster shows single schema version
├── Verify client connectivity
└── Resume normal operations
```

## Rollback Considerations

**Before Phase 2 (CMS not initialized):** Full rollback is straightforward. Perform a reverse rolling upgrade — stop each node, install the previous version's binaries, restart. The cluster reverts to its previous state entirely. No data is lost, no metadata is changed. This is the primary safety net: you can complete Phase 1, validate thoroughly, and only commit when you are confident.

**After Phase 2 (CMS initialized):** Rollback is not a supported operation. The distributed metadata log now exists, the `system_cluster_metadata` keyspace is populated, and all nodes are operating in TCM mode. While it is technically possible to migrate back to gossip — the path has been tested — it requires manual intervention that goes beyond the scope of a standard operational procedure.

The practical recommendation: treat Phase 2 as a one-way door. Spend your time validating before you walk through it, not planning how to walk back.

## Operator Self-Check

1. Which phase is the one-way door, and what makes it operationally different?
2. What operations are explicitly out of bounds during Phase 1, and why?
3. How do you recover if CMS reconfiguration is interrupted in Phase 3?

## Summary

The rolling upgrade to TCM is a three-phase process: a standard binary upgrade, an explicit CMS initialization, and a CMS replication scale-up. The first phase is fully reversible and follows the same pattern as every previous Cassandra upgrade. The second phase is the commit point — quick to execute (minutes), but irreversible in practice. The third phase scales CMS to production resilience and completes in minutes.

The critical rules: no metadata operations during the mixed-version window, no host replacements during the upgrade, and no hesitation on Phase 3 — running with CMS RF=1 for any longer than necessary is an avoidable risk.

With all three phases complete, your cluster is running on TCM. The next chapter covers how to configure and monitor the CMS in steady state.
