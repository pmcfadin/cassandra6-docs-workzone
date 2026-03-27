# CASSANDRA-19939 sstabledump tombstones-only option

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-19939 adds a `-o` flag to `sstabledump` that restricts output to tombstoned rows only, suppressing live rows from the dump. This is useful for diagnosing tombstone accumulation problems — previously operators had to dump the full SSTable and grep for tombstone markers, which was impractical for large SSTables. The flag filters at the row level: partition tombstones and range tombstones are always included when a partition contains them; row-level tombstones are included only when the row `hasDeletion(nowInSeconds)` returns true.

## Discovery Source
- `CHANGES.txt` reference (trunk): "Make sstabledump possible to show tombstones only (CASSANDRA-19939)"
- Related JIRA: None identified

## Why It Matters
- User-visible effect: `sstabledump -o <sstable>` outputs only tombstoned rows. Without this flag the full SSTable content is dumped, which can be many GB in JSON form.
- Operational effect: Enables efficient tombstone auditing in production environments without piping gigabytes of JSON through grep. Useful when investigating read performance degradation caused by tombstone accumulation.
- Upgrade or compatibility effect: Purely additive. The `-o` flag is new; existing invocations without it are unchanged.
- Configuration or tooling effect: No cassandra.yaml changes. Change is at the `sstabledump` CLI interface. Note: Cassandra must be stopped before running `sstabledump` (existing requirement unchanged).

## Source Evidence
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/SSTableExport.java` — main `sstabledump` implementation
    - Line 70: `private static final String ENUMERATE_TOMBSTONES_OPTION = "o";` — option letter constant
    - Line 94-95: `Option optTombstones = new Option(ENUMERATE_TOMBSTONES_OPTION, false, "Enumerate tombstones only"); options.addOption(optTombstones);` — Apache Commons CLI option registration
    - Lines 167-170: `else if (cmd.hasOption(ENUMERATE_TOMBSTONES_OPTION)) { ... }` — early scan branch when `-o` is used alone (no partition-key filter), sets up `process()` call
    - Lines 207-212: `boolean hasTombstoneOption = cmd.hasOption(ENUMERATE_TOMBSTONES_OPTION);` then `if (hasTombstoneOption && row.isRow()) shouldPrint = ((Row) row).hasDeletion(nowInSeconds);` — row-level filtering
    - Lines 243-244: `hasTombstoneOption` passed to `JsonTransformer.toJsonLines()` and `JsonTransformer.toJson()` for JSON/JSON-lines output paths
  - `src/java/org/apache/cassandra/tools/JsonTransformer.java` — updated to accept and propagate `hasTombstoneOption` in both `toJson()` and `toJsonLines()` methods (227 lines rewritten)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/tools/SSTableExportTest.java` — updated (3 lines) by this commit; inference is that test coverage was extended to exercise `-o`
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/tools/sstable/sstabledump.adoc` — **updated as part of this commit** (11 lines changed)
    - Line 21: `|-o |Enumerate tombstones only` — option added to the usage table
    - Lines 242-251: "Dump tombstones only" section added:
      ```
      == Dump tombstones only

      It is possible to display only tombstones since CASSANDRA-19939. You enable this feature by `-o` flag. This option
      is useful to use if you are interested only in tombstones and the output is very long. This way, you find tombstones
      faster.
      ```
    - The new section describes the flag but does not include an example invocation or sample output.

## Commit Reference
- CASSANDRA-19939: commit `b11909b611` — "Make sstabledump possible to show tombstones only"
  - Author: Stefan Miklosovic
  - Reviewed by: Brad Schoening
  - Date: 2024-09-24

## What Changed
1. `sstabledump` gains a new `-o` flag: "Enumerate tombstones only".
2. When `-o` is passed, the dump output contains only:
   - Row-level deletions (rows where `row.hasDeletion(nowInSeconds)` is true)
   - Partition-level tombstones and range tombstones (existing behavior — partition deletion info is preserved)
3. Live rows are suppressed from output when `-o` is active.
4. The flag is implemented in `SSTableExport.java` using Apache Commons CLI (not picocli — `sstabledump` uses a different CLI library than `nodetool`).
5. `JsonTransformer.java` was significantly refactored (227 lines rewritten) as part of this commit — likely to thread `hasTombstoneOption` cleanly through the JSON transformation pipeline.
6. `sstabledump.adoc` was updated in-tree with a "Dump tombstones only" section (see above), but the section lacks an example invocation.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/tools/sstable/sstabledump.adoc` — already updated by the commit. The "Dump tombstones only" section (lines 242-251) exists but is minimal: it mentions the flag and its purpose but provides no example invocation or sample output. A concrete example with `sstabledump -o <path>` and representative JSON output showing tombstone rows would make this section more useful.
- New pages likely needed: None.
- Audience home: Operators
- Authored or generated: Authored (the sstabledump page is hand-written, not generated).
- Technical review needed from: SSTable/storage expert

## Proposed Disposition
- Inventory classification: minor-update
- Affected docs: `doc/modules/cassandra/pages/managing/tools/sstable/sstabledump.adoc`
- Owner role: docs-lead
- Publish blocker: no (the flag is already documented in the options table; the section exists but is thin)

## Open Questions
- Should the "Dump tombstones only" section include a representative JSON output example showing what a tombstoned row looks like? The existing sstabledump examples all show live rows.
- Does `-o` interact with other flags? For example, does `-o -k <key>` filter tombstones within a specific partition? The code at line 167 has an `else if` branch for `-o` without a key filter, but the `hasTombstoneOption` variable is also used in the filtered-key path (lines 207-212), so combining them should work. Confirm and document.
- Does `-o` show partition tombstones (e.g., `DELETE FROM t WHERE pk = 1`) or only row-level and cell-level tombstones? The filter `row.hasDeletion(nowInSeconds)` operates on `Row` objects — partition-level deletions may be handled differently in `JsonTransformer`.
- What does the output look like for a range tombstone when `-o` is active? An example would help operators interpret the output.

## Next Research Steps
- Add a sample invocation and JSON output example to the `sstabledump.adoc` "Dump tombstones only" section.
- Verify the interaction of `-o` with `-k` (specific partition key) and `-l` (JSON lines output) by reviewing `SSTableExport.java` more carefully.
- Clarify whether partition tombstones appear in `-o` output by reviewing `JsonTransformer.toJson()` with `hasTombstoneOption=true`.

## Notes
- Author: Stefan Miklosovic. Fix version: 6.0.
- This is one of the few Cassandra 6 changes where the authored docs page (`sstabledump.adoc`) was updated in the same commit as the code change, which is unusual. The in-tree docs update is minimal — it adds the flag to the table and a brief prose section but no code examples.
- `sstabledump` uses Apache Commons CLI (not picocli) for option parsing; this is different from `nodetool` commands which use picocli. This means the flag is `-o` (single hyphen, single character) rather than a `--long-form` option.
- The `JsonTransformer.java` refactor in this commit was large (227 lines changed) relative to the feature size, suggesting pre-existing tech debt was addressed alongside the new feature.
