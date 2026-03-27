# CASSANDRA-18330: CEP-21 Transactional Cluster Metadata (CMS)

## Status

| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary

CEP-21 replaces Cassandra's gossip-based cluster metadata propagation with a linearized, distributed log managed by a Cluster Metadata Service (CMS). All modifications to cluster membership, token ownership, and schema are now serialized through the CMS using Paxos-backed consensus. This is the single largest architectural change in Cassandra 6.0, affecting how every cluster operates, how upgrades are performed, and how operators manage topology and schema changes. It introduces mandatory post-upgrade operator steps (`nodetool cms initialize` and `nodetool cms reconfigure`), a new `nodetool cms` command family with 9 subcommands, new configuration properties, a new system keyspace (`system_cluster_metadata`), deprecation of `IEndpointSnitch` in favor of new location/proximity interfaces, and fundamental changes to how nodes discover, register, join, and leave clusters.

## Discovery Source

- JIRA: [CASSANDRA-18330](https://issues.apache.org/jira/browse/CASSANDRA-18330)
- CEP: [CEP-21: Transactional Cluster Metadata](https://cwiki.apache.org/confluence/display/CASSANDRA/CEP-21%3A+Transactional+Cluster+Metadata)
- NEWS.txt: Lines 92-95 (feature), Lines 144-199 (upgrade instructions), Lines 216-232 (snitch deprecation)

## Why It Matters

Before CEP-21, Cassandra relied on gossip to propagate metadata changes (schema, topology, membership). Gossip is eventually consistent and non-linearizable, leading to race conditions during concurrent topology operations (e.g., simultaneous bootstrap and decommission affecting overlapping ranges), split-brain schema disagreements, and difficulty reasoning about the order of metadata changes. CEP-21 eliminates these problems by introducing a single, linearized log of all metadata changes, enforced by a quorum of CMS nodes. This makes cluster operations safer, more predictable, and auditable, but introduces a mandatory migration step for existing clusters and new operational concepts that operators must understand.

## Source Evidence

### Implementation (repo-validated)

| Evidence | Location |
|----------|----------|
| TCM core package | `src/java/org/apache/cassandra/tcm/` (~40+ files) |
| Design doc (in-tree) | `src/java/org/apache/cassandra/tcm/TransactionalClusterMetadata.md` |
| Implementation doc (in-tree) | `src/java/org/apache/cassandra/tcm/TCM_implementation.md` |
| `ClusterMetadata` immutable state | `src/java/org/apache/cassandra/tcm/ClusterMetadata.java` |
| `ClusterMetadataService` | `src/java/org/apache/cassandra/tcm/ClusterMetadataService.java` |
| CMS operations MBean | `src/java/org/apache/cassandra/tcm/CMSOperationsMBean.java` |
| CMS operations impl | `src/java/org/apache/cassandra/tcm/CMSOperations.java` |
| Nodetool CMS commands | `src/java/org/apache/cassandra/tools/nodetool/CMSAdmin.java` |
| Transformations | `src/java/org/apache/cassandra/tcm/transformations/` (25+ types) |
| CMS-specific transformations | `src/java/org/apache/cassandra/tcm/transformations/cms/` (8 classes) |
| Sequences (multi-step ops) | `src/java/org/apache/cassandra/tcm/sequences/` (18 classes) |
| Migration from gossip | `src/java/org/apache/cassandra/tcm/migration/` (5 classes) |
| System keyspace name | `system_cluster_metadata` (in `SchemaConstants.java`) |
| Config properties | `src/java/org/apache/cassandra/config/Config.java` |

### Configuration Properties (repo-validated)

| Property | Default | Description |
|----------|---------|-------------|
| `cms_await_timeout` | `120000ms` | Timeout for CMS operations |
| `cms_default_max_retries` | `10` | Max retries for CMS commits |
| `cms_default_retry_backoff` | `null` | Deprecated since 6.0 |
| `cms_default_max_retry_backoff` | `null` | Deprecated since 6.0 |
| `cms_retry_delay` | `50ms*attempts <= 500ms ... 100ms*attempts <= 1s,retries=10` | Retry delay expression |
| `metadata_snapshot_frequency` | `100` | How often (in epochs) to snapshot cluster metadata |
| `progress_barrier_backoff` | `1000ms` | Backoff for progress barriers during multi-step operations |
| `discovery_timeout` | `30s` | Timeout for CMS discovery during startup |
| `unsafe_tcm_mode` | `false` | Unsafe mode flag for testing |

**Note**: These properties are defined in `Config.java` but are NOT currently present in `cassandra.yaml`. This is a documentation gap -- operators have no visibility into these tuning knobs from the config file alone.

### Nodetool CMS Subcommands (repo-validated from CMSAdmin.java)

| Command | Description |
|---------|-------------|
| `nodetool cms describe` | Describe the current CMS (members, epoch, state, replication factor) |
| `nodetool cms initialize` | Upgrade from gossip and initialize CMS (mandatory for upgrades) |
| `nodetool cms reconfigure` | Reconfigure CMS replication factor (per-DC or simple) |
| `nodetool cms snapshot` | Request a checkpointing snapshot of cluster metadata |
| `nodetool cms unregister` | Unregister nodes in LEFT state |
| `nodetool cms abortinitialization` | Abort an incomplete CMS initialization |
| `nodetool cms dumpdirectory` | Dump the directory from current ClusterMetadata (optional `--tokens`) |
| `nodetool cms dumplog` | Dump the metadata log (optional `--start`/`--end` epoch range) |
| `nodetool cms resumedropaccordtable` | Resume a stalled drop accord table operation |

### CMSOperationsMBean JMX Interface (repo-validated)

Additional JMX-only operations not exposed through nodetool subcommands:
- `unsafeRevertClusterMetadata(long epoch)` -- revert to a prior epoch
- `dumpClusterMetadata(long epoch, long transformToEpoch, String version)` -- dump metadata at epoch
- `unsafeLoadClusterMetadata(String file)` -- load metadata from file
- `setCommitsPaused(boolean paused)` / `getCommitsPaused()` -- pause/resume CMS commits
- `cancelInProgressSequences(String sequenceOwner, String expectedSequenceKind)` -- cancel in-progress operations

### Existing Documentation (repo-validated)

| Doc file | CMS content |
|----------|-------------|
| `doc/modules/cassandra/pages/new/index.adoc` | Single bullet linking to CEP-21 wiki |
| `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` | Mentions `tcm_group` thread pool |
| `doc/modules/cassandra/pages/managing/operating/onboarding-to-accord.adoc` | Brief mention of TCM table migration |
| No dedicated CMS/TCM page exists | **Gap** |
| No `nodetool cms` documentation page exists | **Gap** |
| No CMS upgrade guide exists as a doc page | **Gap** |
| No CMS architecture/concept page exists | **Gap** |
| Nav (`doc/modules/cassandra/nav.adoc`) has no CMS entries | **Gap** |

### Snitch Deprecation (repo-validated from NEWS.txt lines 216-232)

CEP-21 caused `IEndpointSnitch` to be deprecated because `ClusterMetadata` is now the source of truth for topology. Responsibilities split into:
- `o.a.c.locator.Locator` -- datacenter/rack info (not configurable, always from ClusterMetadata)
- `o.a.c.locator.InitialLocationProvider` -- DC/rack for new nodes joining (configurable via `initial_location_provider` yaml)
- `o.a.c.locator.NodeProximity` -- replica sorting (configurable via `node_proximity` yaml)
- `o.a.c.locator.NodeAddressConfig` -- broadcast address config (configurable via `address_config` yaml)

`endpoint_snitch` remains supported but is superseded by the new settings.

## What Changed

### Architecture
- **Gossip no longer manages cluster metadata.** All membership, token ownership, and schema changes are linearized through the CMS distributed log.
- **CMS** is a subset of cluster nodes responsible for maintaining the metadata log using Paxos LWTs.
- **Epoch-based versioning**: Each metadata change produces a new monotonically increasing epoch. All nodes can be identified by their current epoch.
- **Immutable ClusterMetadata**: The cluster state is represented as an immutable object, atomically published on each node. No partial updates are ever visible.
- **New system keyspace**: `system_cluster_metadata` with `distributed_metadata_log` table stores the linearized log.

### Operations
- **Multi-step operations** (bootstrap, decommission, move, replace) are now executed as coordinated, pre-planned sequences with progress barriers to maintain quorum consistency.
- **Concurrent operations** on disjoint token ranges are permitted; overlapping ranges are rejected via locked ranges.
- **Read/write consistency**: Coordinators and replicas exchange epoch information. A `CoordinatorBehindException` is thrown when a replica detects the coordinator has stale metadata.

### Upgrade Path (mandatory operator action)
1. Rolling upgrade all nodes to 6.0 (metadata-changing operations prohibited during this phase)
2. Run `nodetool cms initialize` on one node to create initial single-member CMS
3. Run `nodetool cms reconfigure <rf>` to expand CMS membership (recommended: 3-7 nodes per DC)

### Configuration
- 9 new config properties in `Config.java` (see table above)
- New yaml settings for location/proximity replacing snitches
- `IEndpointSnitch` deprecated

### Fresh Cluster Behavior
- On fresh clusters, CMS election happens automatically during startup. One node self-nominates as the first CMS member. Operators should still run `cms reconfigure` to add redundancy.

## Docs Impact

### Critical (must-have for 6.0 GA)

1. **Upgrade Guide for CMS Migration**: Step-by-step procedure including prohibited operations, `cms initialize`, `cms reconfigure`, handling failures (`--ignore` flag), and `abortinitialization`. This is the most operationally impactful change in 6.0.

2. **Nodetool CMS Command Reference**: All 9 subcommands need full documentation with usage, options, and examples. No nodetool docs page currently exists for `cms`.

3. **CMS Architecture Concept Page**: Explain the distributed metadata log, epochs, CMS membership, how metadata propagates, and what `ClusterMetadata` contains (schema, directory, data placements, in-progress sequences).

4. **Configuration Reference for CMS Properties**: The 9 config properties need to be added to cassandra.yaml with comments and documented. Currently they exist only in `Config.java`.

### Important (should-have)

5. **Snitch Deprecation Guide**: Document the transition from `endpoint_snitch` to `initial_location_provider`, `node_proximity`, and `address_config`. Include mapping from old snitch classes to new interfaces.

6. **Troubleshooting CMS**: Common failure scenarios -- CMS initialization failures (metadata mismatch), stuck in-progress sequences, coordinator behind exceptions, node lagging behind on epochs.

7. **Fresh Cluster CMS Setup**: Document automatic election behavior and when/why to reconfigure CMS membership after initial deployment.

8. **Virtual Tables / System Tables**: Document `system_cluster_metadata` keyspace and its tables. Update virtual tables doc for `tcm_group`.

### Nice-to-have

9. **JMX Operations Reference**: Document the MBean operations for advanced/emergency use (unsafe revert, pause commits, dump metadata).

10. **Developer/Client Impact**: Explain `CoordinatorBehindException` and epoch-aware request handling for driver developers.

## Proposed Disposition
- Inventory classification: new-page
- Affected docs: virtualtables.adoc; onboarding-to-accord.adoc; snitch.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

1. **Why are CMS config properties absent from `cassandra.yaml`?** The 9 CMS-related properties in `Config.java` have no corresponding entries in the default yaml. Is this intentional (hidden tuning) or an oversight? This affects whether we document them as "advanced" or "standard" configuration.

2. **What is the recommended CMS size?** NEWS.txt suggests 3-7 per DC. Is there more specific guidance based on cluster size or workload?

3. **What happens if CMS quorum is lost?** Is there a recovery procedure? The `unsafeRevertClusterMetadata` and `unsafeLoadClusterMetadata` JMX methods suggest emergency recovery paths but these are undocumented.

4. **Is `unsafe_tcm_mode` intended for operator use?** If so, under what circumstances?

5. **What is the interaction between CMS and Accord (CEP-15)?** The `resumedropaccordtable` subcommand and `onboarding-to-accord.adoc` reference suggest coupling, but the relationship is not clearly documented.

6. **Is rolling back from CMS to gossip supported?** The in-tree design doc says "reverting to the previous method of metadata management is not supported." This needs to be made very clear in upgrade docs.

7. **Version references**: NEWS.txt refers to "5.1" in upgrade instructions but the feature ships in 6.0. Are these references stale, or was there a version renumbering?

## Next Research Steps

1. **Check JIRA comments** for any upgrade runbook or operator guide drafted by committers.
2. **Review test cases** in `test/` for CMS initialization, reconfiguration, and failure scenarios to identify edge cases that should be documented.
3. **Cross-reference with CEP-15 (Accord)** to clarify the CMS-Accord interaction for the `resumedropaccordtable` command.
4. **Review `cassandra.yaml` on `cassandra-6.0` branch** to check if CMS config properties are present there (they may have been added after trunk diverged).
5. **Check for any CQL-level changes** related to CMS (e.g., new DESCRIBE output, virtual tables exposing CMS state).
6. **Validate the snitch deprecation path** by checking `initial_location_provider` and `node_proximity` implementations for completeness.

## Notes

- The in-tree design documents (`TransactionalClusterMetadata.md` and `TCM_implementation.md`) in the `tcm` package are excellent technical references but are developer-oriented, not operator-oriented. They could serve as source material for the architecture concept page.
- The NEWS.txt upgrade instructions still reference "5.1" in several places, suggesting they were written before the version was renamed to 6.0 and need updating.
- The absence of CMS config from `cassandra.yaml` is notable. Operators tuning CMS behavior would need to know about these properties through documentation alone.
- CMS membership uses Paxos at SERIAL/QUORUM consistency, so minimum viable CMS is 3 nodes. Single-member CMS (post-initialize, pre-reconfigure) is a availability risk that operators must address promptly.
- The `nodetool cms` command defaults to `describe` when run without a subcommand, which is a helpful UX choice worth noting in docs.
