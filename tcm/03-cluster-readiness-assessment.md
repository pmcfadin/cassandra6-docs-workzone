# Chapter 3: Cluster Readiness Assessment Checklist

Chapter 2 told you what the prerequisites are. This chapter tells you how to verify them — step by step, command by command, with the exact output you should expect and the exact errors you will see if something is wrong.

Think of this chapter as the pre-flight checklist a pilot runs before takeoff. You know the plane should have fuel and functioning engines. This chapter is the procedure that confirms it does.

## Learning Objectives

- Execute a repeatable readiness assessment using TCM initialization gates.
- Diagnose and resolve the most common initialization blockers from command output and logs.
- Decide when to use `--ignore` safely and when to stop and remediate.

## The Five-Gate Model

CMS initialization runs through five validation gates in sequence. If any gate fails, the process stops and reports the reason. Understanding these gates is the key to a smooth migration — and to rapid troubleshooting when something is not right.

```
Gate 1          Gate 2          Gate 3          Gate 4          Gate 5
Can I run    ─► Are ignored  ─► Am I fully  ─► Is everyone  ─► Is CMS
this from       endpoints       JOINED?        upgraded?       uninitialized?
here?           real?

  │                │               │               │               │
  ▼                ▼               ▼               ▼               ▼
Don't ignore    Endpoints      Initiator       All non-LEFT    fullCMSMembers
localhost       must exist     must be in      nodes must      must be empty
                in directory   JOINED state    pass isUpgraded()
```

After all five gates pass, the election phase begins — where the initiating node contacts every peer to verify that they agree on the directory, token map, and schema. Only then does CMS initialization proceed.

Let us walk through each gate and the manual verification that confirms it will pass.

## Gate 1: Verify the Initiating Node

You will run `nodetool cms initialize` from exactly one node. That node becomes the first CMS member. Choose it deliberately.

**Check that the node is JOINED:**

```bash
$ nodetool status
```

Look for your node's entry. It should show `UN` (Up/Normal). If it shows anything else — `UJ` (joining), `UL` (leaving), `UM` (moving) — the node is in the middle of a topology operation and cannot initiate CMS.

The error you will see if you proceed anyway:

```
Initial CMS node needs to be fully joined, not: BOOTSTRAPPING
```

**Choose a stable node.** Do not pick a node you recently restarted, a node you plan to decommission soon, or a node in an unstable availability zone. The initiating node becomes the first CMS member. While CMS membership can be reconfigured later, starting on stable footing avoids unnecessary churn.

## Gate 2: Check All Nodes Are Up and Upgraded

This is the most common source of initialization failures. Every non-LEFT node in the cluster must be running Cassandra 6.0 or later.

**Verify with `nodetool status` across all nodes:**

```bash
$ nodetool status
Datacenter: dc1
===============
Status=Up/Down
|/ State=Normal/Leaving/Joining/Moving
--  Address       Load       Tokens  Owns   Host ID                               Rack
UN  10.0.1.10     256.12 GiB 256     ?      a1b2c3d4-...                          rack1
UN  10.0.1.11     248.67 GiB 256     ?      e5f6a7b8-...                          rack2
UN  10.0.1.12     261.33 GiB 256     ?      c9d0e1f2-...                          rack3
```

Every node should show `UN`. If any node shows `DN` (Down/Normal), you must either bring it up on the new version or add it to the `--ignore` list.

**Verify version uniformity:**

```bash
$ nodetool version
```

Run this on every node, or if you have a cluster management tool, query the version across all nodes simultaneously. The Cassandra version must be 6.0+ on every participating node.

If a non-ignored, non-LEFT node is still on an older version, initialization will fail with:

```
All nodes are not yet upgraded - /10.0.1.11:7000 is running <old-version>
```

## Gate 3: Confirm No In-Progress Topology Operations

TCM tracks multi-step topology operations through the `InProgressSequences` data structure. Six operation types are tracked:

| Operation | What It Means |
|-----------|---------------|
| JOIN | A node is bootstrapping into the cluster |
| MOVE | A node is moving its token ranges |
| REPLACE | A node is replacing a dead peer |
| LEAVE/REMOVE | A node is decommissioning or being removed |
| RECONFIGURE_CMS | CMS membership is being changed |
| DROP_ACCORD_TABLE | An Accord table is being dropped |

If any of these operations is in flight, CMS initialization cannot proceed. The metadata log cannot begin from a snapshot that includes half-completed transitions.

**How to check:**

```bash
$ nodetool status
```

Look for any node not in the `UN` state. A node showing `UJ` (joining), `UL` (leaving), or `UM` (moving) indicates an in-progress operation.

Additionally, examine the system log for recent topology activity:

```bash
$ grep -E "PrepareJoin|PrepareLeave|PrepareMove|PrepareReplace" /var/log/cassandra/system.log
```

If you find an operation that is stuck — a bootstrap that hung, a decommission that was interrupted — you must resolve it before proceeding. Either let it complete, or cancel it explicitly. A restarted node will attempt to resume its in-progress operation automatically through the `finishInProgressSequences()` mechanism.

## Gate 4: Confirm No Locked Ranges

Locked ranges are TCM's mechanism for preventing concurrent topology changes on overlapping token ranges. During a bootstrap, for example, the ranges being streamed are locked so that a simultaneous decommission cannot reassign them.

If locked ranges exist — typically because a topology operation crashed or was interrupted — they must be cleared before initialization.

In practice, locked ranges and in-progress sequences are closely correlated. If Gate 3 passes (no in-progress operations), Gate 4 almost certainly passes as well. But verify explicitly if you have any doubt:

```bash
$ nodetool cms describe
```

If CMS is not yet initialized, this command may not return useful output. In that case, check the system log for warnings about locked ranges.

## Gate 5: Verify Schema Convergence

This is the gate that catches operators off guard most often, because schema disagreement can exist silently for weeks or months without visible impact.

**Check schema agreement:**

```bash
$ nodetool describecluster
```

Look for the `Schema versions` section in the output. In a healthy cluster, you will see a single schema UUID with all nodes listed under it:

```
Schema versions:
    a1b2c3d4-e5f6-7890-abcd-ef1234567890: [10.0.1.10, 10.0.1.11, 10.0.1.12]
```

If you see multiple UUIDs, your cluster has schema disagreement:

```
Schema versions:
    a1b2c3d4-e5f6-7890-abcd-ef1234567890: [10.0.1.10, 10.0.1.11]
    f9e8d7c6-b5a4-3210-fedc-ba9876543210: [10.0.1.12]
```

During the election phase, the initiating node computes an MD5 digest of all eight `system_schema` tables (keyspaces, tables, columns, indexes, views, types, functions, aggregates) and sends it to every peer. Each peer computes the same digest and compares. A mismatch produces:

```
Got mismatching cluster metadatas. Check logs on peers ([/10.0.1.12:7000])
```

And on the peer's log:

```
Initiator schema different from our: a1b2c3d4-... != f9e8d7c6-...
```

### Resolving Schema Disagreement

Schema disagreement can occur for several reasons, and each has a different fix:

**A DDL statement was run during the rolling upgrade.** This is the most common cause. If a CREATE TABLE or ALTER TABLE was issued while nodes were on different messaging versions, some nodes may not have received the mutation. Resolution: complete the upgrade to get all nodes on the same version, then run the DDL again.

**A node was down during a schema change and missed the gossip propagation.** Resolution: restart the node. On startup, it will pull the current schema from its peers.

**Persistent disagreement despite restarts.** This indicates a deeper issue, often caused by a corrupt local schema. Resolution: run `nodetool resetlocalschema` on the affected node. This drops the node's local schema and rebuilds it from its peers. Use this with caution — it triggers a full schema reload.

**Verify convergence after resolution:**

```bash
$ nodetool describecluster | grep -A 5 "Schema versions"
```

Do not proceed until you see a single UUID.

## Gate 6 (Implicit): Confirm Gossip Has Settled

Before CMS initialization, gossip must be in a stable state — meaning all nodes have discovered all their peers and the failure detector has established baseline heartbeat rates.

Cassandra checks this automatically during startup via `Gossiper.waitToSettle()`. The algorithm is straightforward: wait a minimum of 5 seconds, poll the known endpoint count every second, and require 3 consecutive polls with the same count.

If the endpoint count is still changing — because nodes are still discovering each other — gossip is not settled. You will see log messages like:

```
Gossip not settled after 5000ms, ...
```

Followed eventually by:

```
Gossip settled after X ms
```

In practice, gossip settles within seconds of all nodes being up. If it does not settle within a minute, investigate network connectivity between nodes.

> **Note:** There is a system property `cassandra.skip_wait_for_gossip_to_settle` that can bypass this check. Never set this before CMS initialization. The gossip state is the starting point from which TCM builds its initial snapshot — if gossip has not converged, the snapshot will be inconsistent.

## Verifying Repair State

Here is an important detail that the automated checks do not cover: **TCM does not check for in-progress repairs.** The `upgradeFromGossip` validation chain checks node versions, node states, and schema — but it does not query the repair service.

This means an active repair session will not block CMS initialization. However, running repairs during the initialization window introduces unnecessary risk. A repair session modifies SSTable state and anti-entropy metadata. While this is unlikely to interfere with CMS initialization directly, the concurrent load and messaging activity are best avoided.

**Check for active repairs:**

```bash
$ nodetool repair --list
```

If there are active sessions, either wait for them to complete or cancel them. Failed or timed-out repair sessions clean up automatically.

**The practical rule:** finish or cancel all repairs before starting the rolling upgrade, not just before CMS initialization. This gives the cluster a clean baseline.

## The Election Phase: What Happens When You Run Initialize

Once the five gates pass, `nodetool cms initialize` triggers the election phase. Understanding this phase helps you diagnose failures and understand what "agreement" means concretely.

1. **The initiating node collects its current metadata:** directory (all node IDs, states, endpoints), token map, and schema digest.

2. **It broadcasts a `CMSInitializationRequest` to every non-ignored peer.** This message contains the initiator's view of the cluster.

3. **Each peer runs three comparisons** against its own local state:
   - Directory: Are the node IDs, states, and endpoints identical?
   - Token map: Is the token-to-node mapping identical?
   - Schema digest: Does the MD5 of all eight `system_schema` tables match?

4. **Each peer responds with a boolean:** metadata matches or it does not. If it does not match, the peer logs the specific diff — which fields in the directory differ, which tokens are misassigned, which schema UUID is wrong.

5. **If any peer responds with a mismatch, initialization aborts.** The initiator logs which peers disagreed and directs you to check their logs.

6. **If all peers agree, the initiator becomes the first CMS node.** It writes the initial snapshot to the `system_cluster_metadata` keyspace and begins accepting commits.

If a peer does not respond at all (because it is down or unreachable), you will see:

```
Did not get response from /10.0.1.12:7000 - not continuing with migration.
Ignore down hosts with --ignore <host>
```

This is the point where the `--ignore` flag becomes relevant. If you are certain the node is permanently down or will not return to the cluster, you can re-run:

```bash
$ nodetool cms initialize --ignore 10.0.1.12
```

If another node has already initiated (perhaps a colleague ran the command on a different node), you will see:

```
Migration already initiated by /10.0.1.10:7000
```

To recover, abort the stale initialization from a different node:

```bash
$ nodetool cms abortinitialization --initiator 10.0.1.10
```

Then re-run `initialize` from your chosen node.

## The Complete Readiness Checklist

This is the consolidated checklist. Work through it top to bottom. Do not skip items.

### Cluster-Level Checks

- [ ] **All nodes are up.** `nodetool status` shows `UN` for every node on every node.
- [ ] **All nodes are on 6.0+.** `nodetool version` returns 6.0 or later on every node.
- [ ] **No nodes are in transitional states.** No `UJ`, `UL`, `UM` in `nodetool status`.
- [ ] **Schema is converged.** `nodetool describecluster` shows a single schema UUID.
- [ ] **Gossip is settled.** System log shows "Gossip settled" on every node.
- [ ] **No active repairs.** `nodetool repair --list` shows no in-progress sessions.
- [ ] **Automation is disabled.** Auto-scaling, scheduled DDL, repair cron jobs — all paused.

### Initiating-Node Checks

- [ ] **Node is in JOINED state.** `nodetool status` shows `UN` for this node.
- [ ] **Node is stable.** Recently restarted or recently-bootstrapped nodes should be avoided.
- [ ] **Node has network connectivity to all peers.** Port 7000 (inter-node) is reachable from this node to every other.

### Operational Checks

- [ ] **You have identified any nodes to ignore.** Dead nodes that will not return should be listed for the `--ignore` flag.
- [ ] **You have a rollback plan.** If initialization fails, you know how to abort and retry.
- [ ] **You have scheduled a maintenance window.** While TCM initialization is fast (typically 1–2 minutes on a healthy cluster), the surrounding upgrade process requires a period of no metadata changes.

## Error Reference

If initialization fails, this table maps every error message to its cause and resolution:

| Error Message | Cause | Resolution |
|---------------|-------|------------|
| `Can't ignore local host %s when doing CMS migration` | Your own IP is in the `--ignore` list | Remove your IP from `--ignore` |
| `Ignored host(s) %s don't exist in the cluster` | An `--ignore` address is not in the directory | Verify the IP address; check `nodetool status` |
| `Initial CMS node needs to be fully joined, not: %s` | Initiating node is not JOINED | Wait for the node to complete its current operation |
| `All nodes are not yet upgraded - %s is running %s` | A non-LEFT node is on a pre-6.0 version | Upgrade that node to 6.0+ |
| `Can't upgrade from gossip since CMS is already initialized` | CMS is already active | No action needed — you are already on TCM |
| `Migration already initiated by %s` | Another node started initialization | Run `nodetool cms abortinitialization --initiator <ip>` |
| `Did not get response from %s` | A peer is unreachable | Bring the peer up or add to `--ignore` |
| `Got mismatching cluster metadatas` | Peer disagrees on directory, tokens, or schema | Check peer logs for specific diff; resolve and retry |

## What TCM Checks For You (And What It Does Not)

It is worth being explicit about the boundary between automated and manual verification:

**TCM checks automatically:**
- Initiating node state (must be JOINED)
- Node version compatibility (must be 6.0+)
- CMS initialization state (must not already be initialized)
- Directory agreement (verified during election)
- Token map agreement (verified during election)
- Schema digest agreement (verified during election)
- Ignored endpoint validity (must exist in cluster)

**You must check manually:**
- Active repair sessions (no automated check)
- Gossip settlement (happens at startup, but verify via logs)
- Automation and cron jobs (TCM cannot see your external systems)
- Network connectivity between all nodes (TCM discovers failures only when it tries to communicate)
- Whether a node in the `--ignore` list is truly unrecoverable

## Operator Self-Check

1. Which checks are validated automatically by TCM, and which remain operator responsibilities?
2. How would you diagnose a `Got mismatching cluster metadatas` failure quickly?
3. What evidence confirms the initiating node is an acceptable CMS seed candidate?

## Summary

The readiness assessment reduces to a clear mental model: **confirm uniformity, confirm stability, confirm agreement.**

Uniformity means all nodes are on the same version. Stability means no topology operations are in flight, no repairs are running, and no automation will trigger changes. Agreement means every node sees the same directory, the same token map, and the same schema.

TCM enforces most of these checks automatically and will reject initialization if they are not met. The errors are specific, actionable, and logged on the relevant peers. Your job as the operator is to verify the conditions that TCM cannot see — active repairs, external automation, and network health — and to resolve any disagreements before giving the command.

Once the checklist is green, you are ready for the rolling upgrade. Turn to Chapter 4.
