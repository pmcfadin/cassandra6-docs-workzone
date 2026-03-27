# CASSANDRA-18802 UCS compaction parallelization via parallelize_output_shards

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
The Unified Compaction Strategy (UCS) now parallelizes individual compactions by splitting operations into separate tasks per output shard. This is controlled by the `parallelize_output_shards` compaction option (default: `true`). The parallelization also applies to major compactions triggered via `nodetool compact`, where a new `--jobs` / `-j` option controls the maximum thread count to prevent starving background compactions.

## Discovery Source
- `NEWS.txt` reference: Lines 118-127 -- describes parallelize_output_shards option, major compaction parallelism, and --jobs/-j option for nodetool compact
- `CHANGES.txt` reference: (not found by JIRA number; NEWS.txt is primary)
- Related JIRA: https://issues.apache.org/jira/browse/CASSANDRA-18802
- Related CEP or design doc: None identified

## Why It Matters
- User-visible effect: Individual compaction operations complete faster because they are split into parallel subtasks per output shard. Major compactions can see dramatic duration reductions.
- Operational effect: Operators gain a new `--jobs`/`-j` option on `nodetool compact` to control thread parallelism for major compactions. Default limits major compaction to half the available compaction threads.
- Upgrade or compatibility effect: The feature is enabled by default (`true`). However, parallelized compactions cannot take advantage of preemptive SSTable opening, so tables configured with very large SSTables may be less efficient. Operators who rely on preemptive SSTable opening behavior may want to disable this.
- Configuration or tooling effect: New compaction sub-option `parallelize_output_shards` (boolean). System property `-Dunified_compaction.parallelize_output_shards` sets the default. New `--jobs`/`-j` flag on `nodetool compact`.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/compaction/ucs.adoc` (UCS options table at line 601-699 -- missing `parallelize_output_shards`)
  - `doc/modules/cassandra/pages/reference/cql-commands/compact-subproperties.adoc` (UCS section at line 88-135 -- missing `parallelize_output_shards`)
- Relevant config paths:
  - `conf/cassandra.yaml` -- `parallelize_output_shards` is NOT present in cassandra.yaml; it is a compaction sub-option and JVM system property only
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/compaction/unified/Controller.java` (lines 154-160: option definition, default from system property; line 371-374: accessor; lines 466-468: parsing from compaction options; line 604: validation)
  - `src/java/org/apache/cassandra/config/CassandraRelevantProperties.java` (line 684: `UCS_PARALLELIZE_OUTPUT_SHARDS("unified_compaction.parallelize_output_shards", "true")`)
  - `src/java/org/apache/cassandra/tools/nodetool/Compact.java` (lines 59-64: `--jobs`/`-j` option definition with description)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/compaction/unified/BackgroundCompactionTrackingTest.java` (uses `parallelize_output_shards` in CQL CREATE TABLE)
- Relevant generated-doc paths: None (nodetool docs may be auto-generated from annotations but no generated compact page was found)

## What Changed
1. **New UCS compaction option `parallelize_output_shards`** (boolean, default `true`): When enabled, UCS splits individual compaction operations into separate subtasks per output shard and runs them in parallel. This shortens compaction durations significantly but disables preemptive SSTable opening for those compactions.
2. **System property `-Dunified_compaction.parallelize_output_shards`**: Sets the default value for the option across all tables. Defined in `CassandraRelevantProperties` with default `"true"`.
3. **`nodetool compact --jobs/-j <N>` option**: Controls the maximum number of threads used for parallel major compaction. If not set, up to half the compaction threads are used. If set to 0, the major compaction uses all threads and blocks other compactions until complete.
4. **Not in cassandra.yaml**: The `parallelize_output_shards` setting is not exposed as a cassandra.yaml configuration key. It is set either as a per-table compaction sub-option in CQL or via JVM system property.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/compaction/ucs.adoc` -- The UCS Options table (line 601+) needs a new row for `parallelize_output_shards` describing the boolean option, its default, and trade-off with preemptive SSTable opening.
  - `doc/modules/cassandra/pages/reference/cql-commands/compact-subproperties.adoc` -- The UCS section (line 88+) needs `parallelize_output_shards` added to the option syntax block and definition list.
  - Nodetool compact documentation (if auto-generated or manually authored) -- needs the `--jobs`/`-j` option documented. The annotation-based description in `Compact.java` lines 59-63 may feed auto-generated docs.
- New pages likely needed: None
- Audience home: Operators (compaction tuning, nodetool usage)
- Authored or generated: Authored for UCS options; potentially generated for nodetool compact help
- Technical review needed from: Compaction team / UCS maintainers

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: ucs.adoc; compact-subproperties.adoc
- Owner role: technical-owner
- Publish blocker: no

## Open Questions
- Should the UCS docs mention the trade-off between parallelized compaction and preemptive SSTable opening more explicitly, or is the NEWS.txt note sufficient guidance?
- Is there a generated nodetool reference page that will automatically pick up the `--jobs`/`-j` option from the Picocli annotations in `Compact.java`, or does it need manual authoring?
- Should the system property `-Dunified_compaction.parallelize_output_shards` be listed in a JVM/system properties reference page?

## Next Research Steps
- Check if `doc/scripts/gen-nodetool-docs.py` generates a page for `nodetool compact` that would auto-include the `--jobs` flag
- Verify whether a JVM system properties reference page exists that should list the new property
- Confirm the exact behavior when `--jobs 0` is used (blocks all other compactions) for accurate documentation

## Notes
- The `parallelize_output_shards` option is validated as a boolean in `Controller.validateOptions()` (line 604).
- The option can be set per-table via CQL ALTER TABLE: `ALTER TABLE ks.t WITH compaction = {'class': 'UnifiedCompactionStrategy', 'parallelize_output_shards': 'true'};`
- The `--jobs`/`-j` option in `Compact.java` defaults to `null` (not set), which triggers the "up to half compaction threads" behavior on the server side.
- The existing UCS documentation extensively covers sharding concepts but does not yet mention the ability to parallelize the actual compaction execution across shards.
