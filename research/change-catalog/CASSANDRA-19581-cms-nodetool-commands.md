# CASSANDRA-19581 CMS nodetool commands (consolidated: 19581, 20525, 20482, 19216, 19393)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary
Five JIRAs collectively define and refine the `nodetool cms` command group introduced with Transactional Cluster Metadata (TCM) in Cassandra 6. CASSANDRA-19393 unified previously scattered CMS commands (`describecms`, `initializecms`, `reconfigurecms`) into a single `nodetool cms` command group backed by a picocli `@Command` subcommand hierarchy. Subsequent JIRAs added `cms unregister` (CASSANDRA-19581), `cms abortinitialization` (CASSANDRA-20482), and `cms dumplog` / `cms dumpdirectory` (CASSANDRA-20525), while CASSANDRA-19216 changed `cms reconfigure` to run synchronously by default and added `--cancel` to abort in-progress reconfigurations. The net result is a unified `nodetool cms` command with nine subcommands that operators use to inspect, initialize, and manage the CMS.

## Discovery Source
- `CHANGES.txt` references (trunk):
  - "Group nodetool cms commands into single command group (CASSANDRA-19393)"
  - "Make nodetool reconfigurecms sync by default and add --cancel to be able to cancel ongoing reconfigurations (CASSANDRA-19216)"
  - "Add nodetool command to unregister LEFT nodes (CASSANDRA-19581)"
  - "Add nodetool command to abort failed nodetool cms initialize (CASSANDRA-20482)"
  - "Add nodetool command to dump the contents of the system_views.{cluster_metadata_log, cluster_metadata_directory} tables (CASSANDRA-20525)"
- Related JIRA: CASSANDRA-18330 (TCM / CMS foundation)
- Related JIRA: CASSANDRA-19972 (correct return code for reconfigure cms when streaming fails)

## Why It Matters
- User-visible effect: Operators gain a dedicated `nodetool cms` subcommand tree for all CMS lifecycle operations instead of top-level scattered commands. New subcommands expose previously unavailable actions: unregistering LEFT nodes, aborting stuck initialization, and dumping the metadata log and directory.
- Operational effect: The `cms reconfigure` subcommand now blocks until reconfiguration completes (CASSANDRA-19216), reducing ambiguity about reconfiguration state. The `--cancel` flag allows operators to abort an in-progress reconfiguration. `cms unregister` removes LEFT nodes from cluster metadata that previously required manual intervention. `cms abortinitialization` provides recovery from stalled migrations. `cms dumplog` and `cms dumpdirectory` enable diagnostic inspection of the metadata log and cluster directory.
- Upgrade or compatibility effect: CASSANDRA-19393 replaced the top-level commands `nodetool describecms`, `nodetool initializecms`, and `nodetool reconfigurecms` with `nodetool cms describe`, `nodetool cms initialize`, and `nodetool cms reconfigure`. The old top-level command names were removed. This is a breaking change for any scripts using the old command names.
- Configuration or tooling effect: No new cassandra.yaml configuration. Changes are exclusively at the `nodetool` CLI interface.

## Source Evidence
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/CMSAdmin.java` — top-level `@Command(name = "cms")` class with all subcommands as inner static classes. Commit 98ca5f8f1a (CASSANDRA-19393) created this file.
  - Full subcommand list as of trunk (from `CMSAdmin.java` line 49 `@Command` annotation `subcommands` field):
    - `describe` (`DescribeCMS`) — describes current CMS state
    - `initialize` (`InitializeCMS`) — upgrades from gossip and initializes CMS; `@Option(names = { "-i", "--ignore" })` for ignored endpoints
    - `reconfigure` (`ReconfigureCMS`) — reconfigures CMS replication factor; `--status`, `-r`/`--resume`, `-c`/`--cancel` flags added by CASSANDRA-19216
    - `snapshot` (`Snapshot`) — requests a checkpointing snapshot
    - `unregister` (`Unregister`) — added by CASSANDRA-19581; `@Parameters(paramLabel = "nodeId", arity = "1..*")` accepts one or more node IDs in LEFT state
    - `abortinitialization` (`AbortInitialization`) — added by CASSANDRA-20482; `@Option(required = true, names = { "--initiator" })` requires the address of the node where `cms initialize` was run
    - `dumpdirectory` (`DumpDirectory`) — added by CASSANDRA-20525; `@Option(names = { "--tokens" })` to include tokens in output
    - `dumplog` (`DumpLog`) — added by CASSANDRA-20525; `@Option(names = { "--start" })` start epoch, `@Option(names = { "--end" })` end epoch
    - `resumedropaccordtable` (`ResumeDropAccordTable`) — resumes stalled drop accord table; `@Parameters` for table ID
  - `src/java/org/apache/cassandra/tcm/CMSOperations.java` — MBean operations backing the nodetool commands
  - `src/java/org/apache/cassandra/tcm/CMSOperationsMBean.java` — MBean interface; `unregisterLeftNodes(List)`, `abortInitialization(String)`, `dumpLog(long, long)`, `dumpDirectory(boolean)` added per their respective JIRAs
  - `src/java/org/apache/cassandra/db/virtual/ClusterMetadataDirectoryTable.java` — backing virtual table for `dumpdirectory`; updated by CASSANDRA-19581 (added) and CASSANDRA-20525 (extended)
  - `src/java/org/apache/cassandra/db/virtual/ClusterMetadataLogTable.java` — backing virtual table for `dumplog`; updated by CASSANDRA-20525
  - `src/java/org/apache/cassandra/tcm/transformations/Unregister.java` — unregister transformation; updated by CASSANDRA-19581
  - `src/java/org/apache/cassandra/tcm/migration/Election.java` — abort initialization logic; updated by CASSANDRA-20482
  - Deleted files (CASSANDRA-19393): `src/java/org/apache/cassandra/tools/nodetool/DescribeCMS.java`, `InitializeCMS.java`, `ReconfigureCMS.java`
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/upgrade/ClusterMetadataUpgradeAbortMigrationTest.java` — added by CASSANDRA-20482
  - `test/distributed/org/apache/cassandra/distributed/test/log/ReconfigureCMSTest.java` — updated by CASSANDRA-19393 and CASSANDRA-19216

## Commit References
| JIRA | Commit | Description |
|---|---|---|
| CASSANDRA-19393 | 98ca5f8f1a | Group nodetool cms commands into single command group |
| CASSANDRA-19216 | 3acec3c28e | Make reconfigurecms sync by default, add --cancel |
| CASSANDRA-19581 | 7694d90152 | Add nodetool command to unregister LEFT nodes |
| CASSANDRA-20482 | 4fb81ea483 | Add nodetool command to abort failed cms initialize |
| CASSANDRA-20525 | 2c05f82755 | Add nodetool command to dump metadata log/directory |

## What Changed

### CASSANDRA-19393 (commit 98ca5f8f1a)
- Introduced `CMSAdmin.java` as a picocli `@Command(name = "cms")` top-level command grouping `describe`, `initialize`, `reconfigure`, and `snapshot` as subcommands.
- Deleted the three previously separate nodetool command files: `DescribeCMS.java`, `InitializeCMS.java`, `ReconfigureCMS.java`.
- The old top-level nodetool names (`describecms`, `initializecms`, `reconfigurecms`) are gone; operators must use `nodetool cms describe`, `nodetool cms initialize`, `nodetool cms reconfigure`.

### CASSANDRA-19216 (commit 3acec3c28e)
- `cms reconfigure` now runs synchronously by default (previously returned after initiating the reconfiguration asynchronously).
- Added `-c`/`--cancel` option to `ReconfigureCMS` to cancel an in-progress CMS reconfiguration.
- Added `--status` option to poll the reconfiguration status.
- Added `--resume` / `-r` option to resume a previously interrupted reconfiguration sequence.

### CASSANDRA-19581 (commit 7694d90152)
- Added `cms unregister <nodeId>...` subcommand (`Unregister` inner class in `CMSAdmin.java`).
- Accepts one or more node IDs (`@Parameters(arity = "1..*")`); all must be in LEFT state.
- Backed by `CMSOperationsMBean.unregisterLeftNodes(List<String>)`.
- Also introduced `system_views.cluster_metadata_directory` virtual table (`ClusterMetadataDirectoryTable.java`).

### CASSANDRA-20482 (commit 4fb81ea483)
- Added `cms abortinitialization --initiator <address>` subcommand (`AbortInitialization` inner class).
- `--initiator` is required; must be the address of the node where `cms initialize` was originally run.
- Backed by `CMSOperationsMBean.abortInitialization(String)`.
- Recovery mechanism for clusters where `nodetool cms initialize` started but never completed.

### CASSANDRA-20525 (commit 2c05f82755)
- Added `cms dumpdirectory [--tokens]` subcommand (`DumpDirectory` inner class).
  - `--tokens` flag includes token ranges in the output (default false).
  - Backed by `CMSOperationsMBean.dumpDirectory(boolean)` which queries `ClusterMetadataDirectoryTable`.
- Added `cms dumplog [--start <epoch>] [--end <epoch>]` subcommand (`DumpLog` inner class).
  - `--start` defaults to `Epoch.FIRST`; `--end` defaults to `Long.MAX_VALUE` (all epochs).
  - Backed by `CMSOperationsMBean.dumpLog(long, long)` which queries `ClusterMetadataLogTable`.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` — any references to old top-level `describecms`, `initializecms`, `reconfigurecms` commands must be updated to the new `nodetool cms <subcommand>` form.
  - `tcm/` workzone materials referencing nodetool CMS operations may need updating.
- New pages likely needed:
  - A generated reference page (or authored overview page) for `nodetool cms` and its subcommands. The existing gen-nodetool-docs.py infrastructure would generate per-subcommand help, but there is currently no dedicated authored page for the `cms` command group.
  - An operator guide section explaining the CMS lifecycle commands and when to use `unregister`, `abortinitialization`, `dumplog`, `dumpdirectory`.
- Audience home: Operators
- Authored or generated: Both. Generated docs would cover option syntax; an authored page or section is needed for the "when and why" operational guidance.
- Technical review needed from: TCM/CMS domain experts (Marcus Eriksson, Sam Tunnicliffe)

## Proposed Disposition
- Inventory classification: new-page (generated reference) + minor-update (existing use_nodetool.adoc)
- Affected docs: `troubleshooting/use_nodetool.adoc`; new `cms` command reference page
- Owner role: docs-lead with CMS expert reviewer
- Publish blocker: yes — `use_nodetool.adoc` may contain stale references to old command names

## Open Questions
- Does `use_nodetool.adoc` or any other authored page currently reference `nodetool describecms`, `nodetool initializecms`, or `nodetool reconfigurecms` by their old names? If so those are broken in Cassandra 6.
- Does the gen-nodetool-docs.py script correctly traverse subcommand groups to produce per-subcommand reference pages for the `cms` group?
- What is the expected operator workflow for `cms dumplog` and `cms dumpdirectory` — diagnostic-only, or also used for support ticket collection? This affects the authored doc scope.
- For `cms unregister`, what is the relationship to `nodetool decommission` and `assassinate`? Should the authored page cross-reference those?

## Next Research Steps
- Audit `use_nodetool.adoc` for references to the old top-level CMS command names and flag as publish blockers if found.
- Verify whether gen-nodetool-docs.py handles picocli subcommand groups (the `cms` parent command).
- Review TCM workzone materials in `tcm/` for any stale nodetool references.
- Identify whether a new authored CMS operations page is planned for the TCM documentation initiative (see CASSANDRA-18330 research file).

## Notes
- Authors: Marcus Eriksson (marcuse), N. V. Harikrishna, Sam Tunnicliffe. CASSANDRA-19393 fix version: 6.0-alpha1.
- The `cms` command itself (with no subcommand) invokes `DescribeCMS` by default (see `CMSAdmin.execute()` at line 62 of `CMSAdmin.java`).
- The `resumedropaccordtable` subcommand is present in `CMSAdmin.java` but was not part of this JIRA set; it is part of Accord table drop handling.
- CASSANDRA-19393 commit message references `tcm/TransactionalClusterMetadata.md` (updated 4 lines), suggesting there is an in-tree design doc that also describes the command group.
