# CASSANDRA-20448 sstableexpiredblockers human-readable output with SSTable sizes

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
The `sstableexpiredblockers` tool now supports a `-H` (`--human-readable`) flag that converts raw numeric timestamps to ISO 8601 instants and displays SSTable on-disk sizes in human-readable format (e.g., "1.5 MB" instead of raw bytes). Without the flag, backward-compatible raw numeric output is preserved, but disk size is now always included in the output (previously absent). The tool also gained proper CLI argument parsing via Apache Commons CLI (`GnuParser`), replacing the previous positional-only argument handling.

## Discovery Source
- `NEWS.txt` reference: not found in local trunk NEWS.txt (may not yet be listed)
- `CHANGES.txt` reference: "Make sstableexpiredblockers support human-readable output with SSTable sizes" (6.0-alpha1)
- Related JIRA: [CASSANDRA-20448](https://issues.apache.org/jira/browse/CASSANDRA-20448)
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Operators can now see disk sizes alongside blocking information, making it far easier to prioritize which expired-but-blocked SSTables warrant attention. Human-readable timestamps replace opaque epoch values.
- Operational effect: Improves triage speed when investigating disk space issues caused by expired tombstones that cannot be compacted away.
- Upgrade or compatibility effect: No breaking changes. Default output (without `-H`) now includes `diskSize` in raw bytes, which is additive. Scripts parsing old output should still work but may see the new `diskSize` field.
- Configuration or tooling effect: New CLI flag `-H` / `--human-readable`.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/tools/sstable/sstableexpiredblockers.adoc` (existing page, needs update)
  - `doc/modules/cassandra/pages/managing/tools/sstable/index.adoc` (lists the tool, no change needed)
- Relevant config paths: none
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/SSTableExpiredBlockers.java` (main implementation)
  - `tools/bin/sstableexpiredblockers` (shell wrapper, unchanged)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/tools/SSTableExpiredBlockersTest.java`
- Relevant generated-doc paths: none (this is an authored page)

## What Changed

1. **New `-H` / `--human-readable` flag**: When present, timestamps (minTS, maxTS, maxLDT) are rendered as ISO 8601 instants (e.g., `2025-03-19T13:37:46.057Z`) instead of raw epoch milliseconds/seconds. Disk sizes use `FileUtils.stringifyFileSize()` (e.g., "36 bytes", "1.5 MB").

2. **Disk size always displayed**: Both human-readable and default output now include `diskSize` for every SSTable listed. This is a new field not present in Cassandra 5.0 output.

3. **Proper CLI parsing**: Replaced simple positional argument parsing with Apache Commons CLI `GnuParser`. The tool now has a structured `Options` inner class that handles flag registration, help text, and argument validation.

4. **Updated usage string**: Usage now shows `sstableexpiredblockers [-H] <keyspace> <table>` with help output describing the `-H` flag.

5. **Timestamp boundary handling**: In human-readable mode, sentinel values (`Long.MIN_VALUE`, `Long.MAX_VALUE`) are preserved as raw numbers rather than converted to nonsensical dates.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/tools/sstable/sstableexpiredblockers.adoc` -- needs update to document `-H` flag, updated usage syntax, new `diskSize` field in output, and updated example output
- New pages likely needed: none
- Audience home: Operators > Managing > Tools > SSTable Tools
- Authored or generated: authored
- Technical review needed from: tool author (Stefan Miklosovic) or committer familiar with sstable tooling

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: sstableexpiredblockers.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- The local trunk does not yet contain this patch (the current `SSTableExpiredBlockers.java` on local trunk still has the old positional-arg-only code). The change is confirmed merged on remote trunk per GitHub. Need to pull latest trunk before drafting the doc update.
- Confirm exact output format with a local run of the patched tool to produce accurate example output for documentation.
- The existing test `testMaybeChangeDocs` checks the old usage string -- confirm it has been updated in the merged version.

## Next Research Steps
- Pull latest trunk to get the merged CASSANDRA-20448 code
- Run `sstableexpiredblockers -H` locally against test data to capture exact example output
- Draft updated `sstableexpiredblockers.adoc` with new usage, flag description, and example output
- Identify review owner

## Notes
- Reporter: Brad Schoening. Assignee: Stefan Miklosovic.
- Fix version: 6.0-alpha1, 6.0.
- Type: Improvement (not a new tool, enhancement to existing tool).
- The `formatForExpiryTracing` method signature changed to accept a `boolean humanReadable` parameter and now builds output through a `logEntry()` helper method.
- The `checkForExpiredSSTableBlockers` algorithm itself is unchanged -- only the presentation layer was modified.
- Reference to original tool creation: CASSANDRA-10015.
