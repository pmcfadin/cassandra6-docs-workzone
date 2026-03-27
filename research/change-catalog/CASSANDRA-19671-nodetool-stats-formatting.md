# CASSANDRA-19671 nodetool stats formatting (consolidated: 19671, 20820, 20940, 19104, 19015, 19022, 19771)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Summary
Seven JIRAs incrementally improve the output of `nodetool tablestats` and `nodetool gcstats` in Cassandra 6. For `tablestats`: CASSANDRA-19671 adds per-keyspace total disk space; CASSANDRA-20820 adds per-level statistics for tables using UnifiedCompactionStrategy (UCS); CASSANDRA-20940 adds compression dictionary memory usage; CASSANDRA-19104 standardizes byte-size formatting using human-readable units; CASSANDRA-19015 standardizes significant-digit formatting for time and latency values. For `gcstats`: CASSANDRA-19022 rewrites the output to be table-aligned, adds `-H`/`--human-readable` flag, `-F`/`--format` flag (json/yaml/table), and adds max and reserved direct memory fields; CASSANDRA-19771 adds JSON and YAML output modes to `gcstats` (overlapping intent with CASSANDRA-19022 — both were committed separately and consolidated into `GcStats.java`). The combined effect is that both commands produce richer, better-formatted output in Cassandra 6 versus Cassandra 5.

## Discovery Source
- `CHANGES.txt` references (trunk):
  - "Add total space used for a keyspace to nodetool tablestats (CASSANDRA-19671)"
  - "Include Level information for UnifiedCompactionStrategy in nodetool tablestats output (CASSANDRA-20820)"
  - "Extend nodetool tablestats for dictionary memory usage (CASSANDRA-20940)"
  - "Standardize nodetool tablestats formatting of data units (CASSANDRA-19104)"
  - "Make nodetool tablestats use number of significant digits for time and average values consistently (CASSANDRA-19015)"
  - "Fix nodetool gcstats output, support human-readable units and more output formats (CASSANDRA-19022)"
  - "Add JSON and YAML output option to nodetool gcstats (CASSANDRA-19771)"
- Related JIRAs: CASSANDRA-17021 (zstd dictionary — the dictionary whose memory CASSANDRA-20940 reports); CASSANDRA-18802 (UCS — the compaction strategy whose level info CASSANDRA-20820 exposes)

## Why It Matters
- User-visible effect: `nodetool tablestats` output gains multiple new fields. `nodetool gcstats` is reformatted and gains new flags. Operators relying on scripted parsing of either command's output should be aware of changes.
- Operational effect: Operators can now read per-keyspace disk usage directly from `tablestats`, inspect UCS compaction level details without JMX, check compression dictionary memory consumption, and view GC statistics in JSON/YAML for programmatic ingestion.
- Upgrade or compatibility effect: The output format of both commands changed. Scripts that parse `tablestats` or `gcstats` output by column position or specific string matching may break. The changes are additive for most fields, but CASSANDRA-19104 and CASSANDRA-19015 change how existing values are formatted (byte sizes and latency digits).
- Configuration or tooling effect: `nodetool gcstats` gains two new flags: `-F`/`--format` and `-H`/`--human-readable`.

## Source Evidence
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/stats/TableStatsPrinter.java` — primary printer for tablestats; contains all new fields
  - `src/java/org/apache/cassandra/tools/nodetool/stats/StatsKeyspace.java` — keyspace-level stats holder; `spaceUsedLive` and `spaceUsedTotal` fields (CASSANDRA-19671, line 37-38); these are printed at lines 71-72 of `TableStatsPrinter.java` as "Space used (live)" and "Space used (total)" under each keyspace heading
  - `src/java/org/apache/cassandra/tools/nodetool/stats/StatsTable.java` — table-level stats holder; `isUCSSstable` flag and associated per-level fields (CASSANDRA-20820); `compressionDictionariesMemoryUsed` field (CASSANDRA-20940)
  - `src/java/org/apache/cassandra/tools/nodetool/stats/TableStatsHolder.java` — populates StatsTable/StatsKeyspace from JMX; updated by all five tablestats JIRAs
  - `src/java/org/apache/cassandra/tools/nodetool/GcStats.java` — `@Command(name = "gcstats")` with `@Option(names = { "-F", "--format" })` and `@Option(names = { "-H", "--human-readable" })`
  - `src/java/org/apache/cassandra/tools/nodetool/stats/GcStatsHolder.java` — holds GC stats fields; added `MAX_DIRECT_MEMORY`, `RESERVED_DIRECT_MEMORY` constants alongside existing `ALLOCATED_DIRECT_MEMORY` (CASSANDRA-19022)
  - `src/java/org/apache/cassandra/tools/nodetool/stats/GcStatsPrinter.java` — added by CASSANDRA-19771; dispatches between table/json/yaml output formats
  - `src/java/org/apache/cassandra/db/ColumnFamilyStoreMBean.java` — added JMX methods for UCS level stats (CASSANDRA-20820)
  - `src/java/org/apache/cassandra/db/compaction/UnifiedCompactionStrategy.java` — exposes per-level density/size data (CASSANDRA-20820)
  - `src/java/org/apache/cassandra/metrics/TableMetrics.java` — added `compressionDictionariesMemoryUsed` metric (CASSANDRA-20940)
  - `src/java/org/apache/cassandra/utils/FBUtilities.java` — significant-digit formatting helpers used by CASSANDRA-19015
- Relevant test paths:
  - `test/unit/org/apache/cassandra/tools/nodetool/stats/TableStatsPrinterTest.java` — updated by CASSANDRA-19671, CASSANDRA-19104, CASSANDRA-19015
  - `test/unit/org/apache/cassandra/tools/nodetool/GcStatsTest.java` — added by CASSANDRA-19771
  - `test/unit/org/apache/cassandra/db/compaction/CompactionStrategyManagerTest.java` — added by CASSANDRA-20820
  - `test/unit/org/apache/cassandra/db/ColumnFamilyStoreMBeansTest.java` — added by CASSANDRA-20820
- Relevant docs paths:
  - No dedicated authored docs page for `nodetool tablestats` or `nodetool gcstats` was found in `doc/modules/cassandra/pages/`. Changes affect the generated nodetool reference (via `doc/scripts/gen-nodetool-docs.py`).
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` — may contain tablestats and gcstats examples that need updating.

## Commit References
| JIRA | Commit | Description |
|---|---|---|
| CASSANDRA-19671 | b9f900947a | Add total space used for a keyspace to nodetool tablestats |
| CASSANDRA-20820 | 8974fdb821 | Include Level information for UCS in nodetool tablestats |
| CASSANDRA-20940 | dc89b8c802 | Extend nodetool tablestats for dictionary memory usage |
| CASSANDRA-19104 | 9db908917a | Standardize nodetool tablestats formatting of data units |
| CASSANDRA-19015 | ac201d2f04 | Consistent significant digits in nodetool tablestats |
| CASSANDRA-19022 | 009146959a | Fix gcstats output, add human-readable + more formats |
| CASSANDRA-19771 | 664ab193d6 | Add JSON and YAML output option to nodetool gcstats |

## What Changed

### CASSANDRA-19671 — Keyspace total space in tablestats (commit b9f900947a)
- `TableStatsPrinter.java` lines 71-72: for each keyspace section, two new lines are printed:
  - `Space used (live): <value>` using `formatDataSize(keyspace.spaceUsedLive, data.humanReadable)`
  - `Space used (total): <value>` using `formatDataSize(keyspace.spaceUsedTotal, data.humanReadable)`
- `StatsKeyspace.java` gains `spaceUsedLive` and `spaceUsedTotal` fields populated from `ColumnFamilyMetric.LiveDiskSpaceUsed` and `TotalDiskSpaceUsed` aggregated across all tables in the keyspace.
- `TableStatsHolder.java` updated to aggregate disk space per keyspace.

### CASSANDRA-20820 — UCS Level information in tablestats (commit 8974fdb821)
- `StatsTable.java` gains `isUCSSstable` boolean flag and six per-level string-list fields: `sstableAvgTokenSpaceInEachLevel`, `sstableMaxDensityThresholdInEachLevel`, `sstableAvgSizeInEachLevel`, `sstableAvgDensityInEachLevel`, `sstableAvgDensityMaxDensityThresholdRatioInEachLevel`, `sstableMaxDensityMaxDensityThresholdRatioInEachLevel`.
- `TableStatsPrinter.java` lines 103-116: when `table.isUCSSstable` is true, prints six new level-info lines (e.g., "Average token space for SSTables in each level: [...]") analogous to the existing `isLeveledSstable` block (lines 95-100).
- New JMX methods added to `ColumnFamilyStoreMBean.java` and implemented via `CompactionStrategyManager.java` to expose UCS level data.

### CASSANDRA-20940 — Compression dictionary memory in tablestats (commit dc89b8c802)
- `StatsTable.java` gains `compressionDictionariesUsed` boolean and `compressionDictionariesMemoryUsed` long field.
- `TableStatsPrinter.java` line 157: conditionally prints `Compression dictionaries memory used: <value>` when `table.compressionDictionariesUsed` is true.
- `TableMetrics.java` adds a `compressionDictionariesMemoryUsed` gauge backed by `CompressionDictionaryCache`.
- `StatsTableComparator.java` updated to support sorting by `compressionDictionariesMemoryUsed`.

### CASSANDRA-19104 — Standardized byte-size formatting in tablestats (commit 9db908917a)
- `TableStatsPrinter.java` updated to use a consistent `formatDataSize()` helper for all byte-size fields instead of ad-hoc formatting.
- The `formatDataSize()` method applies human-readable unit suffixes (KiB, MiB, GiB) when the `-H`/`--human-readable` flag is set on `nodetool tablestats`, and raw byte counts otherwise.
- Pre-existing inconsistency: some fields showed human-readable sizes by default, others showed raw bytes. This change standardizes raw-bytes-by-default with optional `-H` formatting.

### CASSANDRA-19015 — Consistent significant digits in tablestats (commit ac201d2f04)
- `TableStatsPrinter.java` and `StatsTable.java` updated so time and average values use a consistent number of significant digits via `FBUtilities.prettyPrintLatency()` and related helpers.
- `FBUtilities.java` gains helper methods for significant-digit formatting.
- Previously some latency values used 2 decimal places, others used 3 or formatted inconsistently.

### CASSANDRA-19022 — Rewrite gcstats output, add -H and -F flags (commit 009146959a)
- `GcStats.java` gains two new picocli options:
  - `@Option(names = { "-F", "--format" }, description = "Output format (json, yaml, table)")` — defaults to `""` (table)
  - `@Option(names = { "-H", "--human-readable" }, description = "Display gcstats with human-readable units")`
- `GcStatsHolder.java` adds two new fields: `MAX_DIRECT_MEMORY` ("max_direct_memory_bytes") and `RESERVED_DIRECT_MEMORY` ("reserved_direct_memory_bytes") alongside the existing `ALLOCATED_DIRECT_MEMORY`.
- The column layout was previously misaligned (broken); CASSANDRA-19022 fixed this by switching to a proper table formatter.
- `GcStatsPrinter.java` was added (commit 664ab193d6, CASSANDRA-19771) to dispatch between output formats.

### CASSANDRA-19771 — JSON/YAML output for gcstats (commit 664ab193d6)
- `GcStatsPrinter.java` added: dispatches on output format string to produce table, JSON, or YAML output from `GcStatsHolder`.
- `GcStatsTest.java` added with test cases for all three output formats.
- Note: CASSANDRA-19022 and CASSANDRA-19771 were committed separately but both contribute to the current `GcStats.java`/`GcStatsHolder.java`/`GcStatsPrinter.java` trio on trunk. CASSANDRA-19022 introduced the `-F` and `-H` flags and the basic output-format dispatch; CASSANDRA-19771 completed the JSON/YAML printer implementation.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` — if it contains `nodetool tablestats` or `nodetool gcstats` example output, the examples are stale and must be updated.
  - Any generated nodetool reference pages for `tablestats` and `gcstats` (produced by `gen-nodetool-docs.py`) will reflect new option flags automatically but will not show new output fields without regeneration.
- New pages likely needed: None beyond regenerating existing nodetool reference pages.
- Audience home: Operators
- Authored or generated: Primarily generated-review. The tablestats output changes are extensive; if there are authored examples in `use_nodetool.adoc` or similar, those need manual review.
- Technical review needed from: Compaction (UCS, CASSANDRA-20820), Dictionary compression (CASSANDRA-20940), JVM/GC (CASSANDRA-19022)

## Proposed Disposition
- Inventory classification: generated-review for nodetool reference pages; minor-update for `use_nodetool.adoc` if it contains gcstats/tablestats examples
- Affected docs: generated nodetool reference for `tablestats` and `gcstats`; `troubleshooting/use_nodetool.adoc`
- Owner role: docs-lead
- Publish blocker: no (additive changes; formatting changes are cosmetic)

## Open Questions
- Does `use_nodetool.adoc` contain literal output examples for `tablestats` or `gcstats`? If so, those examples need regeneration.
- CASSANDRA-19022 and CASSANDRA-19771 both address gcstats output format — were they coordinated, or did CASSANDRA-19771 supersede the format work from CASSANDRA-19022? The current code in `GcStats.java` references `GcStatsPrinter.from(outputFormat)` which was introduced in CASSANDRA-19771's commit; need to confirm no duplication or dead code.
- For CASSANDRA-20820, the UCS level info is only shown when `table.isUCSSstable` is true — what does an operator need to know to trigger this (i.e., must UCS be explicitly configured)? Should the docs page note the pre-condition?
- For CASSANDRA-20940, is dictionary memory usage shown for all tables or only those with compression dictionaries loaded?

## Next Research Steps
- Audit `use_nodetool.adoc` for tablestats and gcstats literal output examples.
- Verify whether `gen-nodetool-docs.py` is run as part of the trunk docs build to confirm whether nodetool reference pages would be auto-updated.
- Cross-reference CASSANDRA-17021 (zstd dictionary) research file for context on CASSANDRA-20940's metric.
- Cross-reference CASSANDRA-18802 (UCS) for context on CASSANDRA-20820's level fields.

## Notes
- Authors: Arun Ganesh / Stefan Miklosovic (19671); Alan Wang (20820); Stefan Miklosovic (20940); Leo Toff / Stefan Miklosovic (19104, 19015); Ling Mao / Stefan Miklosovic (19022); Mohammad Suhel (19771).
- CASSANDRA-19022 patch notes: "This command was using a completely custom way of displaying the statistics which was fixed." This implies the prior gcstats output was significantly broken, not merely poorly formatted.
- The `-H`/`--human-readable` flag in `tablestats` pre-dates these JIRAs; CASSANDRA-19104 standardized how it is applied across fields.
- CASSANDRA-19015 and CASSANDRA-19104 are closely related formatting cleanups; both were authored by Leo Toff and reviewed by Stefan Miklosovic.
