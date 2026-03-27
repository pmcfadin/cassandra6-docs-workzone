# CASSANDRA-21129 Offline dump tool for cluster metadata and the log

## Status
| Field | Value |
|---|---|
| Research state | blocked |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary
A new standalone offline tool called `offlineclustermetadatadump` is being added to enable operators to inspect Transactional Cluster Metadata (TCM) state directly from SSTables without requiring a running Cassandra node. This addresses a critical operational gap: when a node fails to start due to TCM corruption or issues, existing tools (`nodetool`, `cqlsh`) are unavailable because they require a live node. The tool reads from `system.local_metadata_log` and `system.metadata_snapshots` SSTables on disk and supports three subcommands: `metadata`, `log`, and `distributed-log`.

## Discovery Source
- `NEWS.txt` reference: not yet present (PR not merged)
- `CHANGES.txt` reference: "Add tool to offline dump cluster metadata and the log" (targeted for 6.0-alpha1)
- Related JIRA: [CASSANDRA-21129](https://issues.apache.org/jira/browse/CASSANDRA-21129)
- Related CEP or design doc: CEP-21 (Transactional Cluster Metadata) provides the foundational context
- Related JIRAs:
  - CASSANDRA-19393 / CASSANDRA-20525: online `nodetool cms dump*` commands (complementary, requires running node)
  - CASSANDRA-19151: related offline diagnostic work (different approach)

## Why It Matters
- User-visible effect: Operators gain the ability to diagnose cluster metadata problems on nodes that will not start, a previously impossible task.
- Operational effect: Critical for incident response when TCM corruption prevents node startup. Enables offline forensic inspection of metadata state, log entries, and epoch history.
- Upgrade or compatibility effect: New tool only, no breaking changes. Only applicable to Cassandra 6.0+ clusters using TCM (CEP-21).
- Configuration or tooling effect: New standalone tool `offlineclustermetadatadump` in `tools/bin/`. Uses picocli for CLI parsing.

## Source Evidence
- Relevant docs paths:
  - No existing doc page (new tool)
  - `doc/modules/cassandra/pages/managing/tools/index.adoc` (tool index, may need a new category)
  - `doc/modules/cassandra/pages/managing/tools/sstable/index.adoc` (for reference to existing offline tool patterns)
- Relevant config paths: none (tool reads from data directories)
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/OfflineClusterMetadataDump.java` (main class, in PR #4581)
  - `tools/bin/offlineclustermetadatadump` (shell wrapper, in PR #4581)
  - `src/java/org/apache/cassandra/tcm/log/LogReader.java` (minor doc update in PR)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/tools/OfflineClusterMetadataDumpTest.java` (in PR)
  - `test/unit/org/apache/cassandra/tools/OfflineClusterMetadataDumpIntegrationTest.java` (in PR)
- Relevant generated-doc paths: none
- Related online tool (already in trunk):
  - `src/java/org/apache/cassandra/tools/nodetool/CMSAdmin.java` -- `nodetool cms dumpdirectory` and `nodetool cms dumplog` provide online equivalents

## What Changed

1. **New standalone tool**: `offlineclustermetadatadump` -- a picocli-based command with three subcommands:
   - `metadata` -- reconstructs and dumps the full `ClusterMetadata` state to a target epoch by replaying the latest snapshot plus applied transformations
   - `log` -- dumps local metadata log entries from `system.local_metadata_log`
   - `distributed-log` -- dumps distributed log entries (only on CMS nodes)

2. **Common options**:
   - `--data-dir` / `-d`: path to the Cassandra data directory containing the system keyspace
   - `--sstable-directories` / `-s`: specific SSTable directory paths (repeatable)
   - `--partitioner` / `-p`: custom partitioner class
   - `--verbose` / `-v`: enable debug logging

3. **Metadata subcommand options**:
   - `--epoch`: target epoch to reconstruct to
   - `--serialization-version`: serialization version for output
   - `--output-file`: file to write binary output to
   - `--to-string`: output as human-readable text instead of binary

4. **Log subcommand options**:
   - `--from-epoch`: start epoch for filtering (inclusive)
   - `--to-epoch`: end epoch for filtering (inclusive)

5. **Implementation approach**: imports SSTables into a temporary environment, uses existing `LogReader` and `MetadataSnapshots` infrastructure to reconstruct state, validates epoch availability, and reports gaps in the log.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/tools/index.adoc` -- add new tool category or link
  - Troubleshooting pages may reference this tool for TCM-related issues
- New pages likely needed:
  - `doc/modules/cassandra/pages/managing/tools/offlineclustermetadatadump.adoc` -- full tool reference page
  - Possibly a section in a TCM troubleshooting guide
- Audience home: Operators > Managing > Tools
- Authored or generated: authored (new standalone tool, not generated)
- Technical review needed from: Abhijeet Dubey (author), Marcus Eriksson, Sam Tunnicliffe (reviewers)

## Proposed Disposition
- Inventory classification: awaiting-merge
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
- PR #4581 is still open as of 2026-03-24. Will it merge in time for 6.0 GA? If not, this research should be deferred.
- What is the exact tool name in the shell wrapper? PR description says `offlineclustermetadatadump` but JIRA title mentions "tcmdump" -- need to confirm final naming once merged.
- Should this tool be documented alongside SSTable tools (since it reads SSTables offline) or in a new "Cluster Metadata Tools" section?
- The online equivalent commands (`nodetool cms dumpdirectory`, `nodetool cms dumplog`) were added via CASSANDRA-20525. Should the offline and online dump tools cross-reference each other in docs?
- What does the output actually look like? Need sample output from a test run once the PR is merged.
- The `distributed-log` subcommand is only useful on CMS nodes -- should the docs explicitly warn about this?

## Next Research Steps
- Monitor PR #4581 for merge status
- Once merged, pull latest trunk and verify the tool builds and runs
- Run the tool against test data to capture sample output for each subcommand
- Determine doc placement (new tools category vs. SSTable tools vs. standalone page)
- Cross-reference with `nodetool cms` documentation to avoid duplication
- Draft the new tool reference page
- Identify review owner

## Notes
- Reporter and assignee: Abhijeet Dubey (GitHub: dracarys09).
- Reviewers: Marcus Eriksson, Sam Tunnicliffe.
- Fix version target: 6.0-alpha1, 6.0.
- Type: New Feature.
- Component: Transactional Cluster Metadata.
- Time spent on JIRA: 2h 20m (as of last JIRA update).
- The tool is complementary to the online `nodetool cms` commands (CASSANDRA-20525) which were added by Marcus Eriksson. The online commands require a running node and dump from virtual tables (`system_views.cluster_metadata_log`, `system_views.cluster_metadata_directory`). The offline tool reads directly from SSTables.
- The `LogReader` interface documentation was refined in the PR to clarify that entries are retrieved where `epoch > since` (exclusive lower bound).
- The `StandaloneJournalUtil.java` in the existing trunk is a different tool focused on Accord journal inspection, not TCM metadata -- these are distinct tools.
