# Chapter 1: What Changes When You Turn On TCM?

If you have operated an Apache Cassandra cluster for any length of time, you have developed an intuition for how the cluster communicates. Nodes gossip with one another, state propagates probabilistically, and eventually the ring settles. You have learned to wait, to check `nodetool status` one more time, and to trust — but verify — that every node sees the same picture.

Transactional Cluster Metadata changes the machinery behind that picture. The remarkable thing is how little changes on the surface.

This chapter draws a sharp line between what is different after TCM is enabled and what remains exactly the same. If you read nothing else before your upgrade, read this.

## Learning Objectives

- Distinguish which metadata domains move from gossip to TCM and which remain unchanged.
- Explain the new epoch-based mental model for metadata propagation and convergence.
- Identify operational risks that disappear after TCM activation.

## How to Read This Chapter

This chapter is organized around a practical operator question: "What changes in my daily workflow on Day 1 after TCM is enabled?" Read it in this order:

1. What stays the same (so you can preserve existing runbooks)
2. What moves to the metadata log (so you can reason about correctness)
3. What operational uncertainty disappears (so you can simplify procedures)

## The One-Sentence Version

TCM replaces gossip as the authority for cluster membership, token ownership, and schema — but it preserves gossip for failure detection and heartbeats, and it deliberately maintains the same external interface so that your existing tooling, monitoring, and muscle memory continue to work.

## Sidebar: What Operators Usually Notice First

The first visible change after enablement is often not a new command or dashboard. It is the absence of familiar uncertainty. You stop waiting for the ring to "settle." You stop wondering whether two coordinators are routing with slightly different token maps. You stop planning defensive pauses between topology operations.

In practice, this feels less like learning a new system and more like removing hidden failure modes from the old one. That is exactly the point of the design: preserve the interface, strengthen the guarantees.

## What Stays the Same

The design goal behind CEP-21 (the Cassandra Enhancement Proposal that introduced TCM) was explicit: from the operator's perspective, the cluster should be indistinguishable from a gossip-driven cluster. The Cassandra team went to considerable effort to make this true.

**`nodetool` commands behave as expected.** You still run `nodetool status` and see the familiar ring output. You still run `nodetool describecluster` and get schema versions. The output comes from the same application states it always did — the difference is in how those states are populated.

**Gossip application states still exist.** Every `ApplicationState` you are accustomed to seeing — `STATUS_WITH_PORT`, `HOST_ID`, `TOKENS`, `SCHEMA`, `DC`, `RACK`, `RELEASE_VERSION`, `NATIVE_ADDRESS_AND_PORT` — remains in the gossip state table. A compatibility layer called `GossipHelper` bridges TCM's internal representation to these states so that any tool reading gossip (including older sidecar processes or monitoring agents) sees exactly what it expects.

**Client drivers are unaffected.** There are no client-driver implications whatsoever. Drivers negotiate protocol versions, discover nodes, and route queries the same way they always have. The `system.peers` and `system.local` tables continue to be populated. Topology change events are still pushed to connected clients through the `ClientNotificationListener`.

**Storage format is unchanged.** TCM does not impose any requirements on SSTable format, compression, or on-disk layout. It works with every storage configuration Cassandra supports.

**Repair, compaction, and streaming are unchanged.** These subsystems are consumers of metadata, not producers. They ask "who owns this range?" and get an answer. The fact that the answer now comes from an ordered log rather than a gossip state machine is invisible to them.

## What Gossip Stops Doing

Before TCM, gossip was the mechanism by which three critical categories of metadata propagated through the cluster:

1. **Token ownership** — which node owns which token ranges
2. **Node lifecycle state** — whether a node is joining, leaving, moving, or normal
3. **Schema** — the definition of keyspaces, tables, types, and functions

All three are now managed by the TCM log. Let's look at each.

### Token Ownership

In a gossip-driven cluster, each node announces its tokens through the `TOKENS` application state. Other nodes receive this announcement, update their local view of the token map, and begin routing queries accordingly. The problem is that different coordinators may receive these announcements at different times. During a bootstrap, for example, coordinator A may begin routing writes to the new node while coordinator B still routes to the old owner. This creates a window in which read and write quorums are computed against different token maps — a classic split-brain condition that can cause transient data loss.

Under TCM, token assignment is a transformation recorded in the distributed metadata log. The `TokenMap` class maintains an authoritative `SortedBiMultiValMap<Token, NodeId>` that is updated atomically as part of an epoch transition. Every node applies the same sequence of transformations in the same order, so every node converges to the same token map at the same epoch. There is no window for divergence.

### Node Lifecycle State

The old model used gossip `STATUS` updates to signal state transitions: `BOOTSTRAPPING`, `NORMAL`, `LEAVING`, `LEFT`, `MOVING`. These transitions were uncoordinated — a node declared its intent through gossip and other nodes reacted asynchronously.

TCM replaces this with a multi-step transformation sequence. A node join, for example, progresses through a strict series of stages:

| Step | Transformation | What Happens |
|------|---------------|--------------|
| 1 | `Register` | Node registers in the cluster directory |
| 2 | `PrepareJoin` | Token ranges are assigned and locked |
| 3 | `StartJoin` | Streaming begins |
| 4 | `MidJoin` | Data transfer progresses |
| 5 | `FinishJoin` | Node becomes a full member |

Each step is a committed entry in the metadata log. The cluster cannot advance to the next step until the current one is committed and applied. This eliminates an entire class of race conditions that have plagued operators since Cassandra's early days.

The same sequential model applies to decommission (`PrepareLeave` → `StartLeave` → `MidLeave` → `FinishLeave`), moves, and host replacements.

### Schema

Schema propagation via gossip has been one of Cassandra's most persistent operational headaches. Schema mutations were sent via the messaging service, but only to nodes running compatible messaging versions. During a rolling upgrade, this meant schema changes were silently dropped between nodes on different versions — a behavior that surprised operators for years.

Under TCM, schema mutations are `AlterSchema` transformations committed to the same distributed log. They arrive at every node in the same order, at the same epoch. The `DistributedSchema` class wraps the full keyspace definitions in an immutable snapshot tagged with its epoch and a UUID version. If a schema change would be incompatible with a node still running an older version — say, a new compression parameter — the commit is rejected before it is applied. The cluster tells you "no" instead of silently breaking.

## What Gossip Still Does

Gossip is not removed. It still runs on every node, and it still serves two vital functions.

**Failure detection.** Gossip heartbeats remain the mechanism by which nodes detect that a peer is unreachable. The `FailureDetector` consumes gossip `HeartBeatState` updates and calculates phi-accrual failure suspicion levels exactly as before. TCM does not duplicate this mechanism because it does not need to — failure detection is a distributed, peer-to-peer concern that gossip handles well.

**Transient, non-correctness-impacting state.** Gossip continues to disseminate operational metadata that does not affect correctness: RPC readiness, storage load, severity, and similar signals. These states change frequently and are consumed by monitoring and load-balancing logic, but they do not need the strong ordering guarantees that TCM provides.

### The Compatibility Bridge

Here is the key insight: gossip still has all the application state slots it always had. What changes is _who populates some of those slots_.

Before TCM, the node itself wrote its `TOKENS`, `STATUS_WITH_PORT`, and `SCHEMA` application states into gossip. After TCM is enabled, the `LegacyStateListener` — a change listener attached to the local metadata log — intercepts every epoch transition and writes the corresponding values into the local gossip state. From the perspective of any system reading gossip, the state looks the same. The source of truth has simply moved upstream.

**Figure 1-1. Metadata authority before and after TCM**

Image to generate separately: compare pre-TCM node-written gossip metadata vs post-TCM log-driven metadata with gossip as compatibility transport.

This design is deliberately conservative. By feeding TCM-managed state back into gossip, the Cassandra team ensured that older sidecar tools, monitoring scripts, and mixed-version nodes during a rolling upgrade all continue to function. Gossip becomes a read-mostly transport for metadata that is now authoritatively managed elsewhere.

## The New Mental Model

If you carry one diagram in your head, let it be this:

**Figure 1-2. Epoch commit and convergence model**

Image to generate separately: CMS quorum commits epoch N, nodes replicate/apply in order, cluster converges on one authoritative metadata version.

Every metadata change — a new node joining, a table being created, a node being decommissioned — becomes a `Transformation` that is committed to the distributed log at the next epoch. The CMS (a Paxos group of 3, 5, or 7 nodes) serializes all commits. Non-CMS nodes send their commit requests to a CMS member via the `TCM_COMMIT_REQ` verb and receive back the committed entry.

Each node maintains a local copy of the log and applies entries in strict epoch order. At any given moment, you can ask any node "what epoch are you on?" and compare it to the cluster's current epoch. If the numbers match, the node has the latest metadata. If they don't, the node is behind and will catch up — there is no ambiguity, no probabilistic convergence, no "wait and hope."

## What Disappears

Several operational realities that Cassandra administrators have accepted for years simply cease to exist:

**Split-brain metadata.** In a gossip-driven cluster, coordinators can disagree about token ownership during topology changes. This means read and write quorums can be calculated against different views of the ring, leading to transient data loss that is nearly impossible to detect after the fact. With TCM, every coordinator operates on the same epoch. The split-brain class of bugs is structurally eliminated.

**Ring-settle waits.** The manual or scripted waiting period after a topology change — "give gossip time to propagate" — is no longer necessary. Once a transformation is committed, it is committed. Nodes apply it as soon as they receive it.

**Silent schema divergence.** The situation where two nodes end up with different schema versions — because a gossip message was dropped, or because a migration ran during a mixed-version window — cannot happen when schema is applied through an ordered, replicated log.

**Non-deterministic topology operations.** Bootstrap, decommission, and move were historically sequences of gossip state changes that could interleave in unexpected ways if multiple operations ran concurrently. TCM's range-locking mechanism (`LockedRanges`) prevents conflicting topology changes from overlapping. The `InProgressSequences` tracker ensures that multi-step operations complete before new ones begin.

## A Note on What You Will Not Notice

This may be the most important section in this chapter: **the absence of problems is the primary observable change.**

You will not notice that bootstrap is "different" — it will just work more reliably. You will not notice that schema changes are "different" — they will just stop failing in mysterious ways during upgrades. You will not notice that decommission is "different" — it will just complete without the nagging doubt about whether every coordinator got the memo.

The TCM team invested significant effort to make the cluster externally indistinguishable from a gossip-managed cluster. The payoff is not a flashy new feature — it is the quiet disappearance of an entire category of operational risk.

## Operator Self-Check

1. Which gossip responsibilities remain after TCM is enabled, and why does that matter operationally?
2. Why does epoch ordering eliminate split-brain metadata windows during topology changes?
3. What should you expect to stay identical in day-to-day tooling after migration?

## Summary

| Aspect | Before TCM (Gossip) | After TCM |
|--------|---------------------|-----------|
| Token ownership | Gossip propagation | Distributed log (epoch-ordered) |
| Schema distribution | Gossip + messaging service | Distributed log (epoch-ordered) |
| Node lifecycle states | Gossip STATUS updates | Multi-step transformations |
| Failure detection | Gossip heartbeats | Gossip heartbeats (unchanged) |
| Transient state (load, etc.) | Gossip | Gossip (unchanged) |
| Client driver impact | — | None |
| Storage format impact | — | None |
| Consistency model | Eventual (probabilistic) | Linearizable (Paxos-backed) |
| Split-brain risk | Present | Eliminated |
| Ring-settle wait | Required | Not needed |
| nodetool compatibility | — | Fully preserved |

The single most important thing to internalize: **TCM changes how metadata is managed, not how the cluster appears to you.** Your runbooks, your monitoring, your client applications — they all continue to work. What changes is the guarantee behind them.

If you remember only three points from this chapter:

- Keep your existing operational tooling; the interface remains stable.
- Treat epochs as the source of truth for metadata convergence.
- Remove defensive "wait for gossip" rituals from topology runbooks once TCM is active.
