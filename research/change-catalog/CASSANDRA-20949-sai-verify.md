# CASSANDRA-20949 SAI file validation via nodetool verify

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Summary
Extends `nodetool verify` with two new flags (`--sai-only` / `-s` and `--include-sai` / `-i`) that allow operators to validate checksums of Storage Attached Index (SAI) on-disk components. Previously, `nodetool verify` ignored secondary indexes entirely. This matters because during streaming, checksums are verified on the receiving end but not the sender side; a corrupted SAI component can now be detected, removed, and rebuilt without rebuilding the entire index.

## Discovery Source
- `NEWS.txt` reference: not checked (trunk)
- `CHANGES.txt` reference: "Extend nodetool verify to (optionally) validate SAI files (CASSANDRA-20949)"
- Related JIRA: [CASSANDRA-20949](https://issues.apache.org/jira/browse/CASSANDRA-20949)
- Related epic: CASSANDRA-19224 (Storage Attached Indexes Phase 3)

## Why It Matters
- User-visible effect: Operators gain the ability to validate SAI index file integrity on any node, independent of data file verification.
- Operational effect: Enables proactive detection of corrupted SAI components. A corrupted component can be removed and the index rebuilt, rather than discovering corruption during reads.
- Upgrade or compatibility effect: None. The flags are additive; existing `nodetool verify` behavior is unchanged when neither flag is specified.
- Configuration or tooling effect: Two new nodetool flags; no cassandra.yaml changes.

## Source Evidence
- Relevant docs paths:
  - Generated nodetool verify page (trunk live site confirms `--sai-only` and `--include-sai` flags are present)
  - SAI conceptual docs (no mention of verify/validation currently)
- Relevant config paths: None (no cassandra.yaml changes)
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/Verify.java` -- new `-s`/`--sai-only` and `-i`/`--include-sai` options
  - `src/java/org/apache/cassandra/db/compaction/CompactionManager.java` -- `performVerify()` and `verifyOne()` updated to call `cfs.indexManager.validateSSTableAttachedIndexes()`
  - `src/java/org/apache/cassandra/db/compaction/IVerifier.java` -- `Options` class gains `onlySai` and `includeSai` booleans
  - `src/java/org/apache/cassandra/service/StorageService.java` -- `verify()` method overloaded with SAI parameters
  - `src/java/org/apache/cassandra/service/StorageServiceMBean.java` -- new verify method signature
- Relevant test paths: `ActiveCompactionsTest` (new SAI verify test cases); `NodetoolHelpCommandsOutputTest` updated
- Relevant generated-doc paths: `doc/modules/cassandra/pages/managing/tools/nodetool/verify.adoc` (generated surface)
- Commit: [a84abe7ba13fead1d889ceb2347357f971719e98](https://github.com/apache/cassandra/commit/a84abe7ba13fead1d889ceb2347357f971719e98)

## What Changed

1. **Two new `nodetool verify` flags:**
   - `--sai-only` (`-s`): Verify only SAI index checksums, skipping data file verification. Tables without SAI indexes are skipped with a log message.
   - `--include-sai` (`-i`): Verify SAI index checksums in addition to the standard data file verification.
   - The two flags are mutually exclusive; specifying both raises `IllegalArgumentException`.

2. **New JMX method signature** on `StorageServiceMBean` with `onlySai` and `includeSai` boolean parameters, maintaining backward compatibility via overloading.

3. **SAI checksum validation** is performed by calling `cfs.indexManager.validateSSTableAttachedIndexes()` from within the compaction manager verify path.

## Docs Impact
- Existing pages likely affected:
  - **nodetool verify reference** (generated) -- already reflects new flags on trunk. Needs regeneration check for Cassandra 6 release branch.
  - **SAI operations/management docs** -- should cross-reference `nodetool verify --include-sai` as a maintenance tool for SAI indexes.
- New pages likely needed: None
- Audience home: Operators (managing/tools)
- Authored or generated: **Generated** (nodetool verify page). Authored SAI pages may benefit from a cross-reference addition.
- Technical review needed from: SAI maintainers (Caleb Rackliffe / Sunil Pawar)

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: (generated nodetool docs)
- Owner role: generated-doc-owner
- Publish blocker: no

## Open Questions
- Does the generated nodetool verify page on the release branch match trunk? Need to confirm regeneration was done for 6.0-alpha1.
- Should SAI operational guidance pages (e.g., SAI troubleshooting or management) reference `nodetool verify --include-sai` as a recommended maintenance check?
- Is there any interaction with `nodetool verify --extended-verify` when combined with `--include-sai`?

## Next Research Steps
- Regenerate nodetool docs for 6.0 release branch and diff against trunk
- Check SAI authored docs for a natural place to add verify cross-reference
- Confirm `NodetoolHelpCommandsOutputTest` passes with current generated output

## Notes
- Fix versions: 6.0-alpha1, 6.0
- Reporter: Caleb Rackliffe; Assignee: Sunil Ramchandra Pawar
- The feature is categorized under "Operability" in the JIRA
- The generated nodetool verify page on the live trunk site already includes both `--sai-only` and `--include-sai` flags, confirming the generator picked up the changes
