# CASSANDRA-17092: Accord / General Purpose Transactions (CEP-15)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Mixed |
| Docs impact | new-page |

## Summary
Accord is the new leaderless consensus protocol for general-purpose transactions in Cassandra 6, replacing Paxos as the primary transaction mechanism. It enables multi-partition, multi-table atomic transactions via a new `BEGIN TRANSACTION ... COMMIT TRANSACTION` CQL syntax, and transparently replaces Paxos for LWT (CAS) operations on migrated tables. Four documentation pages already exist on trunk covering architecture internals, CQL-on-Accord developer details, and an operational onboarding guide. The primary documentation gap is a **user-facing CQL reference page** for the new transaction statement syntax (`BEGIN TRANSACTION`, `LET`, `IF ... THEN`, `SELECT`, `COMMIT TRANSACTION`). Additionally, the `cassandra.yaml` configuration reference and nodetool command references need updates for the new Accord settings and commands.

## Discovery Source
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-17092
- CEP: CEP-15 (General Purpose Transactions)
- Branch: trunk (Apache Cassandra GitHub)

## Why It Matters
Accord is arguably the single largest feature in Cassandra 6. It fundamentally changes the transaction model, enables multi-partition atomic operations for the first time, and requires operators to understand new configuration, migration workflows, and operational tooling. Incomplete documentation would block adoption.

## Source Evidence

### Existing Documentation Pages (all present on trunk)

1. **`doc/modules/cassandra/pages/architecture/accord.adoc`** -- Landing/index page (8 lines). Links to the two sub-pages below. Minimal content.

2. **`doc/modules/cassandra/pages/architecture/accord-architecture.adoc`** -- Deep developer-oriented architecture doc (~360 lines). Covers:
   - Coordinator and replica-side internals (CommandStore, SafeCommandStore, SafeCommand)
   - AccordExecutor, AccordTask, AsyncChain concurrency model
   - ProgressLog recovery mechanism
   - Command state machine (SaveStatus, Participants, Timestamps, PartialTxn, Dependencies, Writes, Result)
   - CommandsForKey (CFK) managed vs unmanaged transactions
   - RedundantBefore, DurabilityService, ExclusiveSyncPoint
   - ConfigurationService and TopologyManager (epochs)
   - DataStore integration
   - Journal garbage collection (ERASE, EXPUNGE, INVALIDATE, VESTIGIAL, TRUNCATE)
   - Contributing/testing guidance (BurnTest)
   - Cheat sheet (Medium Path, SaveStatus vs Status, Routable/Seekable/Unseekable)

3. **`doc/modules/cassandra/pages/architecture/cql-on-accord.adoc`** -- Developer guide for CQL integration (~627 lines). Covers:
   - Anatomy of a transaction (Txn, Keys/Ranges, Data, Result, Read, Query, Update, Write)
   - Seekable/Unseekable/Routable type hierarchy
   - TxnRead, TxnNamedRead, TxnQuery, TxnUpdate, TxnWrite implementation
   - Live migration core challenges and bridging mechanisms
   - Key barriers (Paxos and Accord)
   - No non-SERIAL key migration explanation
   - Two-phase migration to Accord
   - Supported consistency levels (ONE, QUORUM, SERIAL, ALL for reads; ANY, ONE, QUORUM, SERIAL, ALL for writes; no LOCAL/TWO/THREE)
   - Interoperability support (AccordInteropAdapter, AccordInteropExecution, AccordInteropPersist)
   - Routing requests during migration, splitting writes, partition range reads
   - Transactional modes (FULL, MIXED_READS, OFF)
   - Timestamp handling during migration (Accord timestamp, server timestamp, USING TIMESTAMP, BATCH behavior)
   - `accord.mixed_time_source_handling` config (reject/log/ignore)

4. **`doc/modules/cassandra/pages/managing/operating/onboarding-to-accord.adoc`** -- Operational user guide (~372 lines). Covers:
   - YAML configuration (`accord.enabled`, `accord.default_transactional_mode`, `accord.range_migration`)
   - Table parameters (`transactional_mode`, `transactional_migration_from`)
   - Transactional modes explained (full, mixed_reads, off)
   - Accord repair
   - Migration to Accord (two phases with repair requirements)
   - Migration from Accord (single phase)
   - Migration commands: `nodetool consensus_admin list`, `begin-migration`, `finish-migration`
   - JMX methods for external management tools
   - Supported consistency levels
   - non-SERIAL consistency semantics
   - BATCH timestamp handling
   - Batchlog and hints behavior
   - Operations spanning Accord/non-Accord data
   - Partition range read with LIMIT performance implications
   - Metrics (AccordRead, AccordWrite scopes, RetryDifferentSystem meter, HintsRetryDifferentSystem)

### Navigation
All four pages are included in `doc/modules/cassandra/nav.adoc`:
- Lines 26-28: Architecture section (accord.adoc, accord-architecture.adoc, cql-on-accord.adoc)
- Line 114: Operating section (onboarding-to-accord.adoc)

### cassandra.yaml Configuration
The `accord:` config block (lines 2737-2754 in `conf/cassandra.yaml`) includes:
- `enabled` (default: false)
- `journal_directory`
- `queue_shard_count` (default: -1, i.e., number of cores)
- `command_store_shard_count` (default: -1)
- `recover_delay` (default: 1s)
- `fast_path_update_delay` (default: 5s)

The full `AccordSpec.java` reveals many additional settings NOT in the YAML comments:
- `enable_journal_compaction` (default: true)
- `enable_virtual_debug_only_keyspace` (default: false)
- `queue_shard_model` (THREAD_PER_SHARD, THREAD_PER_SHARD_SYNC_QUEUE, THREAD_POOL_PER_SHARD)
- `queue_submission_model` (SYNC, SEMI_SYNC, ASYNC, EXEC_ST)
- `max_queued_loads`, `max_queued_range_loads`
- `progress_log_concurrency`, `progress_log_query_fallback_timeout` (1m)
- `cache_size`, `working_set_size`, `shrink_cache_entries_before_eviction`
- `range_syncpoint_timeout` (3m), `repair_timeout` (10m)
- Various retry strategies (recover_txn, recover_syncpoint, fetch_txn, etc.)
- `shard_durability_target_splits`, `shard_durability_max_splits`, `shard_durability_cycle`, `global_durability_cycle`
- `range_migration` (auto/explicit)
- `default_transactional_mode` (default: off)
- `ephemeralReadEnabled` (default: true)
- `mixedTimeSourceHandling` (reject/log/ignore)
- `catchup_on_start*` settings
- `journal.*` sub-settings (segmentSize, compactMaxSegments, failurePolicy, replayMode, flushMode, flushPeriod, etc.)

### Nodetool Commands

1. **`nodetool accord`** -- Manage Accord operations
   - `describe` -- Show current Accord epoch and stale replicas
   - `mark_stale` -- Mark replica(s) as stale (unable to participate in durability coordination)
   - `mark_rejoining` -- Mark stale replica(s) as rejoining

2. **`nodetool consensus_admin`** -- Manage consensus protocol migration
   - `list [<keyspace> <tables>...]` -- List migrating tables/ranges (formats: json, yaml, minified variants)
   - `begin-migration [<keyspace> <tables>...] [-st/-et token range]` -- Mark ranges as migrating
   - `finish-migration [<keyspace> <tables>...] [-st/-et token range]` -- Run repairs to complete migration

### CQL Transaction Syntax (from Parser.g lines 760-797)
```
BEGIN TRANSACTION
  LET <name> = (SELECT ... FROM <table> WHERE ...);
  ...
  SELECT <name>.<col>, ...;            -- or full SELECT
  IF <condition> AND ... THEN
    UPDATE/INSERT/DELETE ...;
    ...
  END IF
COMMIT TRANSACTION
```
Supports: read-only transactions (just SELECT), write-only (just INSERT/UPDATE/DELETE), conditional (IF...THEN...END IF), and read-write with LET assignments and references.

### System Keyspaces
- `system_accord` -- Core Accord state (journal table)
- `system_accord_debug` -- Virtual debug-only keyspace (includes `migration_state` table)
- `system_accord_debug_remote` -- Remote debug keyspace

### Metrics
- `AccordRead` and `AccordWrite` scopes in ClientRequestMetrics
- `AccordCoordinatorMetrics` (read-only, read-write, sync-point scopes)
- `RetryDifferentSystem` meter
- `HintsRetryDifferentSystem` meter
- `ReadRepairMetrics.RepairedBlockingViaAccord` and `RepairedBlockingFromAccord`

## What Changed
Accord introduces:
1. New consensus protocol replacing Paxos for multi-partition transactions
2. `BEGIN TRANSACTION ... COMMIT TRANSACTION` CQL syntax with LET, IF...THEN, SELECT
3. `transactional_mode` table property (full, mixed_reads, off)
4. `transactional_migration_from` table property for migration tracking
5. `accord.*` YAML configuration block
6. `nodetool accord` and `nodetool consensus_admin` commands
7. Two-phase live migration from Paxos to Accord (and single-phase back)
8. New system keyspaces (system_accord, system_accord_debug)
9. New metrics scopes (AccordRead, AccordWrite, AccordCoordinatorMetrics)
10. Accord Journal (new storage subsystem separate from commitlog)
11. Consistency level restrictions (no LOCAL, TWO, THREE)
12. Behavioral changes: paging runs separate transactions per page; range reads split across command stores

## Docs Impact

### Already Well Covered
- Architecture internals (accord-architecture.adoc) -- thorough developer reference
- CQL-on-Accord integration details (cql-on-accord.adoc) -- thorough developer reference
- Operational onboarding (onboarding-to-accord.adoc) -- good operator guide covering migration, nodetool commands, consistency levels, metrics

### Gaps Identified

1. **HIGH PRIORITY: No CQL reference page for transaction syntax.** The `BEGIN TRANSACTION ... COMMIT TRANSACTION` syntax is not documented in any user-facing CQL reference. The onboarding guide explicitly states "This guide does not cover the new transaction syntax." The grammar (Parser.g) defines the full syntax but there is no corresponding `.adoc` page. This is the most significant gap.

2. **MEDIUM PRIORITY: Incomplete cassandra.yaml reference.** The YAML file only documents 5 of 30+ Accord config settings. Many operational settings (cache_size, journal sub-settings, retry strategies, durability cycles, catchup_on_start) are only discoverable via source code.

3. **MEDIUM PRIORITY: `nodetool accord` commands not documented.** The `nodetool accord describe`, `mark_stale`, and `mark_rejoining` subcommands are not mentioned in the onboarding guide or any other doc page. Only `nodetool consensus_admin` commands are documented.

4. **LOW PRIORITY: System tables not documented.** The `system_accord` keyspace and `system_accord_debug.migration_state` table are mentioned in passing but not formally documented.

5. **LOW PRIORITY: Architecture docs are developer-focused, not user-focused.** The accord-architecture.adoc and cql-on-accord.adoc are implementation guides for contributors, not user/operator documentation. A conceptual "What is Accord" page for users/architects is absent (the current accord.adoc index is only 8 lines).

6. **LOW PRIORITY: Metrics not comprehensively listed.** The onboarding guide mentions AccordRead/AccordWrite scopes and RetryDifferentSystem but does not enumerate all AccordCoordinatorMetrics (preaccept latency, accept latency, commit latency, etc.).

## Proposed Disposition
- Inventory classification: draft-new-page
- Affected docs: accord.adoc; accord-architecture.adoc; cql-on-accord.adoc; onboarding-to-accord.adoc
- Owner role: technical-owner
- Publish blocker: yes

## Open Questions

1. Is a user-facing CQL transaction syntax reference planned separately (possibly under a different JIRA)?
2. Should the architecture docs (accord-architecture.adoc, cql-on-accord.adoc) be reorganized to separate user/operator content from developer/contributor content?
3. Are there plans to document all AccordSpec settings in cassandra.yaml, or are some considered internal/unstable?
4. The onboarding guide mentions `system_accord_debug.migration_state` -- should system_accord tables get a formal reference page?
5. What is the expected behavior of `nodetool accord mark_stale` / `mark_rejoining` in practice? When would an operator use these?

## Next Research Steps

1. Search for any separate JIRAs tracking transaction syntax documentation
2. Review the binary protocol changes for Accord (new error codes, result types)
3. Check for any Accord-related changes to `cqlsh` (transaction syntax support)
4. Investigate AccordCoordinatorMetrics in detail for a comprehensive metrics listing
5. Verify whether `ephemeralReadEnabled` is exposed to users or is internal-only
6. Check for Accord-related virtual table content in system_accord_debug

## Notes

- The existing documentation is remarkably thorough for an in-development feature, particularly the operational onboarding guide which covers migration workflows, consistency level implications, and edge cases comprehensively.
- The two developer-focused docs (accord-architecture.adoc, cql-on-accord.adoc) contain inline GitHub links to specific commits that will need updating before release.
- The `accord.adoc` landing page is the thinnest page and would benefit most from expansion for general audiences.
- The CQL transaction syntax is the clearest gap: it is fully implemented in the parser (Parser.g lines 760-797) and TransactionStatement.java, but has zero user documentation.
- The onboarding guide references `CASSANDRA-20588` as a known issue for batch atomicity during migration -- this should be tracked for resolution before release.
