# CASSANDRA-18111 SnapshotManager MBean consolidation

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-18111 centralizes all snapshot operations into a dedicated `SnapshotManager` with its own MBean (`org.apache.cassandra.service.snapshot:type=SnapshotManager`). Snapshot-related methods on `StorageServiceMBean` are deprecated (since 5.1) and replaced by equivalent methods on `SnapshotManagerMBean`. The `SnapshotManager` also caches snapshot metadata in memory on startup, eliminating expensive directory scans on every `nodetool listsnapshots` or JMX `SnapshotsSize` call. A `WatchService` detects manually-deleted snapshots to keep the cache consistent.

## Discovery Source
- `NEWS.txt` reference: "There is new MBean of name org.apache.cassandra.service.snapshot:type=SnapshotManager which exposes user-facing snapshot operations. Snapshot-related methods on StorageServiceMBean are still present and functional but marked as deprecated."
- `CHANGES.txt` reference: "Consolidate all snapshot management to SnapshotManager and introduce SnapshotManagerMBean (CASSANDRA-18111)"
- Related JIRA: CASSANDRA-18111
- Related JIRAs: CASSANDRA-13338 (expensive JMX metrics), CASSANDRA-18102 (virtual table for snapshots), CASSANDRA-21173 (snapshot loading from disk)

## Why It Matters
- User-visible effect: No change to nodetool commands (`snapshot`, `listsnapshots`, `clearsnapshot`). These now delegate through `SnapshotManagerMBean` instead of `StorageServiceMBean`, but the user experience is identical.
- Operational effect: Significantly faster `nodetool listsnapshots` and JMX snapshot size queries because snapshots are cached in memory rather than requiring full directory traversal each time. On large clusters this was previously taking hundreds of milliseconds per call.
- Upgrade or compatibility effect: `StorageServiceMBean` snapshot methods are deprecated since 5.1 but still functional. JMX monitoring scripts or tooling that calls snapshot methods on `StorageServiceMBean` will continue to work but should be migrated to the new MBean. Custom JMX integrations need to be updated for the new MBean path.
- Configuration or tooling effect: New MBean path: `org.apache.cassandra.service.snapshot:type=SnapshotManager`. The `SnapshotManager` has a `restart()` method to force a reload from disk if needed.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/backups.adoc` -- primary snapshot operations documentation (uses nodetool commands, no MBean references currently)
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` -- documents `system_views.snapshots` virtual table
  - `doc/modules/cassandra/pages/managing/operating/metrics.adoc` -- no snapshot-specific MBean metrics section currently
- Relevant code paths:
  - `src/java/org/apache/cassandra/service/snapshot/SnapshotManager.java` -- central implementation
  - `src/java/org/apache/cassandra/service/snapshot/SnapshotManagerMBean.java` -- MBean interface with `takeSnapshot`, `clearSnapshot`, `listSnapshots`, `getTrueSnapshotSize`, `getTrueSnapshotsSize`, `setSnapshotLinksPerSecond`, `getSnapshotLinksPerSecond`, `restart`
  - `src/java/org/apache/cassandra/service/StorageServiceMBean.java` -- deprecated methods at lines 298-350 (`@Deprecated(since = "5.1")` referencing CASSANDRA-18111): `takeSnapshot`, `clearSnapshot`, `getSnapshotDetails`, `trueSnapshotsSize`
  - `src/java/org/apache/cassandra/tools/NodeProbe.java` -- now connects `snapshotProxy` to `SnapshotManagerMBean` (line 287) and routes all snapshot operations through it (lines 933-1038)
  - `src/java/org/apache/cassandra/db/virtual/SnapshotsTable.java` -- `system_views.snapshots` virtual table reads from `SnapshotManager`
- Relevant test paths: (not investigated)

## What Changed
1. **New MBean**: `org.apache.cassandra.service.snapshot:type=SnapshotManager` exposes:
   - `takeSnapshot(tag, options, entities)` / `takeSnapshot(tag, entities)`
   - `clearSnapshot(tag, options, keyspaceNames)`
   - `listSnapshots(options)` -- supports filtering by `no_ttl`, `include_ephemeral`, `keyspace`, `table`, `snapshot`
   - `getTrueSnapshotSize()` / `getTrueSnapshotsSize(keyspace)` / `getTrueSnapshotsSize(keyspace, table)` / `getTrueSnapshotsSize(keyspace, table, snapshotName)`
   - `setSnapshotLinksPerSecond(throttle)` / `getSnapshotLinksPerSecond()`
   - `restart()` -- reloads snapshots from disk
2. **Deprecated on StorageServiceMBean** (since 5.1):
   - `takeSnapshot(String tag, Map<String, String> options, String... entities)`
   - `clearSnapshot(Map<String, Object> options, String tag, String... keyspaceNames)`
   - `getSnapshotDetails(Map<String, String> options)`
   - `trueSnapshotsSize()`
3. **In-memory snapshot cache**: Snapshots are loaded from disk at startup and maintained in memory. WatchService detects manual filesystem deletions.
4. **NodeProbe routing**: All nodetool snapshot commands now use `snapshotProxy` (SnapshotManagerMBean) rather than `ssProxy` (StorageServiceMBean).

## Docs Impact
- Existing pages likely affected:
  - `backups.adoc` -- No MBean references currently, but if/when JMX-based backup automation is documented, it should reference the new MBean. Low urgency.
  - `metrics.adoc` -- Could benefit from a note about the new SnapshotManager MBean for operators using JMX directly for snapshot management.
  - `virtualtables.adoc` -- The `system_views.snapshots` section is already documented and unaffected by this change.
- New pages likely needed: None
- Audience home: Operators (especially those with JMX-based automation)
- Authored or generated: All authored content
- Technical review needed from: Snapshot / storage domain expert

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: backups.adoc; metrics.adoc; virtualtables.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should the docs explicitly call out the deprecated StorageServiceMBean snapshot methods and point users to SnapshotManagerMBean? This would be relevant for operators with custom JMX tooling.
- Is there a need to document the `restart()` method on SnapshotManagerMBean? This seems like a recovery/admin operation.
- The `listSnapshots` options map supports `no_ttl`, `include_ephemeral`, `keyspace`, `table`, `snapshot` filtering -- should these be documented as part of the MBean reference?

## Next Research Steps
- Determine if any existing JMX reference pages document StorageServiceMBean snapshot methods that need a deprecation note
- Decide whether to add a dedicated SnapshotManager MBean reference section or just a brief note in backups/metrics docs
- Check if the in-memory cache behavior warrants operational guidance (e.g., when `restart()` is needed)

## Notes
- Reporter: Paulo Motta. Assignee: Stefan Miklosovic. Fix version: 6.0-alpha1, 6.0.
- Multiple PRs contributed: #3374, #3648, #3719.
- Memory overhead of the cache is minimal: ~2 KiB per snapshot object per JIRA discussion, negligible even for tens of thousands of snapshots.
- The WatchService approach handles manual snapshot deletions from the filesystem, keeping the cache accurate without polling.
- Some older StorageServiceMBean snapshot methods were already deprecated in earlier versions (since 3.4 for `takeSnapshot(tag, keyspaceNames)`, since 4.1 for `getSnapshotDetails()`, since 5.0 for `clearSnapshot(tag, keyspaceNames)`). CASSANDRA-18111 deprecates the remaining current methods.
