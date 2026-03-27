# CASSANDRA-20081: Nodetool compactionhistory enhancements

## JIRA Summary

| Field | Value |
|-------|-------|
| JIRA | [CASSANDRA-20081](https://issues.apache.org/jira/browse/CASSANDRA-20081) |
| Title | Enhance nodetool compactionhistory to report compaction type and strategy |
| Status | Resolved |
| Fix Version | 6.0-alpha1, 6.0 |
| Reporter | Brad Schoening |
| Assignee | Arvind Kandpal |
| Commit | `6d60102422d8409cdf8fabfb1c906afdf6a85859` |
| PR | [apache/cassandra#4540](https://github.com/apache/cassandra/pull/4540) |

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Change Description

This JIRA enhances the existing `nodetool compactionhistory` command with:

1. **Human-readable byte formatting**: A new `-H` / `--human-readable` flag displays `bytes_in` and `bytes_out` in human-readable form (KiB, MiB, GiB, TiB) instead of raw byte counts. Default behavior is raw bytes (flag is `false` by default).

2. **Compaction properties column**: The `compaction_properties` column in `system.compaction_history` now includes compaction type and strategy information, stored within the existing map (no schema change). The `COMPACTION_TYPE_PROPERTY` constant is exposed via `CompactionHistoryTabularData`.

### Changes vs Cassandra 5.0

In Cassandra 5.0, `CompactionHistory.java`:
- Uses `io.airlift.airline` annotations (old CLI framework)
- Has only `-F` / `--format` option (json, yaml)
- Creates `CompactionHistoryHolder(probe)` with no humanReadable parameter

In Cassandra 6 (trunk), `CompactionHistory.java`:
- Uses `picocli.CommandLine` annotations (new CLI framework per CASSANDRA-17445)
- Adds `-H` / `--human-readable` option (boolean, default false)
- Creates `CompactionHistoryHolder(probe, humanReadable)`
- `CompactionHistoryHolder.getAllAsMap()` calls `FileUtils.stringifyFileSize(bytesIn, humanReadable)` to conditionally format bytes

### Source Evidence

- `src/java/org/apache/cassandra/tools/nodetool/CompactionHistory.java` -- new `-H` flag
- `src/java/org/apache/cassandra/tools/nodetool/stats/CompactionHistoryHolder.java` -- humanReadable parameter, `FileUtils.stringifyFileSize()` for bytes_in/bytes_out
- `src/java/org/apache/cassandra/tools/nodetool/stats/CompactionHistoryPrinter.java` -- unchanged output logic
- `src/java/org/apache/cassandra/db/compaction/CompactionHistoryTabularData.java` -- `COMPACTION_TYPE_PROPERTY` constant, `compaction_properties` column
- `src/java/org/apache/cassandra/db/compaction/CompactionTask.java` -- persists compaction strategy/type in compaction_properties map

### CHANGES.txt Entry

> Enhance nodetool compactionhistory to report more compaction properties (CASSANDRA-20081)

### NEWS.txt Entry

> Added compaction_properties column to system.compaction_history table and nodetool compactionhistory command

## User-Facing Impact

- **Operators** can now use `-H` to see human-readable byte sizes in compaction history output
- **Operators** can now see which compaction strategy and compaction type produced each compaction in the `compaction_properties` column
- **Backward compatible**: default behavior (raw bytes, no strategy info in older rows) is unchanged

## Docs Impact Assessment

### Generated Docs (nodetool reference)

**Status: Automatically covered by regeneration.**

The generated nodetool docs (`doc/scripts/gen-nodetool-docs.py`) will pick up the new `-H` / `--human-readable` option from `nodetool help compactionhistory` output. No manual intervention needed for the generated reference page -- just regenerate.

### Authored Docs

**Status: Minor update may be warranted.**

1. **`doc/modules/cassandra/pages/managing/operating/compaction/overview.adoc`** (line 208-209): Currently says `compactionhistory:: List details about the last compactions.` This brief description could be enhanced to mention the human-readable flag and the compaction properties info, but is not strictly required since the generated reference page covers the syntax.

2. **Troubleshooting/use_nodetool.adoc**: References `nodetool compactionstats` but not `compactionhistory` directly, so no change needed.

## Open Questions

- The JIRA originally requested documentation for `rows_merged` and `compaction_properties` columns. The `compaction_properties` is now populated with strategy/type info. It is unclear whether the authored docs describe these columns in detail anywhere; the compaction overview page does not.
- The `-H` flag default is `false` (raw bytes), which differs from the JIRA's original request for human-readable by default with a `-n` / `--no-human-readable` flag for raw. The final implementation inverted this -- the flag enables human-readable rather than disabling it.

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: overview.adoc (compaction)
- Owner role: generated-doc-owner
- Publish blocker: no

## Status Recommendation

- **Generated docs**: Regenerate. No manual edits to generated surfaces.
- **Authored docs**: Low priority. Consider adding a sentence about the `-H` flag and compaction properties in the compaction overview page. Not blocking.
- **Overall**: No doc blocker. Standard regeneration covers the primary reference surface.
