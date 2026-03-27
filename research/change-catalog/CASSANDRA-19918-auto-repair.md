# CASSANDRA-19918 CEP-37 Auto Repair

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CEP-37 Auto Repair introduces a fully automated repair scheduler built into Apache Cassandra, eliminating the need for external repair orchestration tools like `cassandra-reaper`. The scheduler supports Full, Incremental, and Preview repair types, stores repair history in `system_distributed.auto_repair_history`, coordinates multi-node parallel repairs, and provides rich configuration via `cassandra.yaml`, CQL table properties, nodetool commands, and JMX metrics.

## Discovery Source
- `NEWS.txt` reference: CEP-37 Auto Repair is a fully automated scheduler that provides repair orchestration within Apache Cassandra, eliminating the need for external repair tools.
- `CHANGES.txt` reference: CASSANDRA-19918
- Related JIRA: https://issues.apache.org/jira/browse/CASSANDRA-19918
- Related CEP or design doc: https://cwiki.apache.org/confluence/display/CASSANDRA/CEP-37+Apache+Cassandra+Unified+Repair+Solution

## Why It Matters
- User-visible effect: Operators no longer need to deploy and manage external repair tools; repair runs automatically similar to compaction.
- Operational effect: Major reduction in operational overhead. Repair scheduling, retries, parallelism, and token range splitting are all handled internally.
- Upgrade or compatibility effect: Disabled by default (`enabled: false`). Enabling incremental repair on existing clusters with large data sets requires careful migration planning (risk of excessive anticompaction). Mixed major version repair is disabled by default for safety.
- Configuration or tooling effect: New `auto_repair` section in `cassandra.yaml`, new CQL table property `auto_repair`, three new nodetool commands, new JMX metrics under `AutoRepair` type, new `system_distributed.auto_repair_history` and `auto_repair_priority` tables.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/auto_repair.adoc` (461 lines, comprehensive)
  - `doc/modules/cassandra/pages/managing/operating/metrics.adoc` (AutoRepair metrics section at ~line 1075)
  - `doc/modules/cassandra/nav.adoc` (linked under Operating section, line 105)
- Relevant config paths:
  - `conf/cassandra.yaml` lines 2770-2920 (full auto_repair config block, commented out by default)
  - `conf/cassandra.yaml` lines 2758-2768 (`reject_repair_compaction_threshold`, `repair_disk_headroom_reject_ratio`)
- Relevant code paths:
  - `src/java/org/apache/cassandra/repair/autorepair/` (core: AutoRepair.java, AutoRepairConfig.java, AutoRepairState.java, AutoRepairUtils.java, RepairTokenRangeSplitter.java, FixedSplitTokenRangeSplitter.java, IAutoRepairTokenRangeSplitter.java, plus assignment/plan classes)
  - `src/java/org/apache/cassandra/service/AutoRepairService.java` / `AutoRepairServiceMBean.java`
  - `src/java/org/apache/cassandra/metrics/AutoRepairMetrics.java` / `AutoRepairMetricsManager.java`
  - `src/java/org/apache/cassandra/tools/nodetool/GetAutoRepairConfig.java`
  - `src/java/org/apache/cassandra/tools/nodetool/SetAutoRepairConfig.java`
  - `src/java/org/apache/cassandra/tools/nodetool/AutoRepairStatus.java`
  - `src/java/org/apache/cassandra/schema/AutoRepairParams.java` (CQL table property)
  - `src/java/org/apache/cassandra/schema/SystemDistributedKeyspace.java` (auto_repair_history, auto_repair_priority tables)
  - `src/java/org/apache/cassandra/config/Config.java`
- Relevant test paths: not explored (out of scope for docs assessment)
- Relevant generated-doc paths: none

## What Changed
1. **New cassandra.yaml configuration**: `auto_repair` block with top-level settings (enabled, repair_check_interval, repair_max_retries, history_clear_delete_hosts_buffer_interval, mixed_major_version_repair_enabled) and per-repair-type overrides (full, incremental, preview_repaired) with 25+ configurable parameters.
2. **Token range splitters**: Two built-in implementations: `RepairTokenRangeSplitter` (data-size-aware, default) and `FixedSplitTokenRangeSplitter` (even splits). Pluggable via `IAutoRepairTokenRangeSplitter` interface.
3. **CQL table property**: `auto_repair` property with `priority`, `full_enabled`, `incremental_enabled`, `preview_repaired_enabled` options for per-table control.
4. **Three nodetool commands**:
   - `nodetool getautorepairconfig` - retrieves runtime configuration
   - `nodetool autorepairstatus` - shows active repairs (with `-t` flag for repair type)
   - `nodetool setautorepairconfig` - dynamic runtime config changes (not persisted across restarts)
5. **System tables**: `system_distributed.auto_repair_history` and `system_distributed.auto_repair_priority`.
6. **JMX metrics**: 19 metrics under `org.apache.cassandra.metrics.AutoRepair` including RepairsInProgress, NodeRepairTimeInSec, ClusterRepairTimeInSec, LongestUnrepairedSec, RepairStartLagSec, SucceededTokenRangesCount, FailedTokenRangesCount, SkippedTokenRangesCount, SkippedTablesCount, TotalBytesToRepair, BytesAlreadyRepaired, TotalKeyspaceRepairPlansToRepair, KeyspaceRepairPlansAlreadyRepaired, RepairTurnMyTurn, RepairTurnMyTurnDueToPriority, RepairTurnMyTurnForceRepair, RepairDelayedByReplica, RepairDelayedBySchedule, TotalMVTablesConsideredForRepair, TotalDisabledRepairTables.
7. **Related existing config**: `reject_repair_compaction_threshold` and `repair_disk_headroom_reject_ratio` serve as backpressure for auto repair.

## Docs Impact
- Existing pages likely affected:
  - `managing/operating/repair.adoc` - should cross-reference auto_repair
  - `managing/operating/metrics.adoc` - already updated with AutoRepair metrics section
- New pages likely needed: None - `auto_repair.adoc` already exists and is comprehensive (461 lines)
- Audience home: Operators
- Authored or generated: Authored (already complete)
- Technical review needed from: CEP-37 author/committer for accuracy validation

## Docs Completeness Assessment

The existing `auto_repair.adoc` documentation is **comprehensive and well-structured**. It covers:

| Area | Covered? | Notes |
|------|----------|-------|
| Feature overview & architecture | Yes | Scheduler, history table, algorithm description |
| Full repair guidance | Yes | Considerations for schedule and assignment size |
| Incremental repair guidance | Yes | Detailed migration guidance for existing clusters |
| Preview repair guidance | Yes | Cross-references to table metrics |
| cassandra.yaml configuration | Yes | All top-level and per-type settings documented with defaults |
| RepairTokenRangeSplitter config | Yes | Parameters with defaults for each repair type |
| FixedSplitTokenRangeSplitter config | Yes | number_of_subranges parameter |
| Related yaml considerations | Yes | reject_repair_compaction_threshold, repair_disk_headroom_reject_ratio |
| CQL table property | Yes | ALTER TABLE syntax, all 4 options documented |
| nodetool getautorepairconfig | Yes | With example output |
| nodetool autorepairstatus | Yes | With example output |
| nodetool setautorepairconfig | Yes | With multiple examples |
| JMX metrics | Partially | Documented in metrics.adoc, not cross-referenced from auto_repair.adoc |
| system_distributed tables | Partially | auto_repair_history mentioned; schema not documented |

### Minor Gaps Identified
1. **Metrics cross-reference**: The auto_repair.adoc mentions "Comprehensive observability features" in the Features list but does not link to the AutoRepair metrics section in metrics.adoc. Only preview-specific table metrics (BytesPreviewedDesynchronized, TokenRangesPreviewedDesynchronized) are cross-referenced.
2. **system_distributed table schemas**: The `auto_repair_history` and `auto_repair_priority` tables are mentioned but their schema/columns are not documented.
3. **Typo**: Line 125 has "particulary" (should be "particularly").

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: auto_repair.adoc; repair.adoc; metrics.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should the AutoRepair metrics section in metrics.adoc be cross-referenced from auto_repair.adoc for discoverability?
- Should the schema of `system_distributed.auto_repair_history` and `auto_repair_priority` be documented (e.g., column names, types, TTL)?
- Is there a dedicated nodetool help page that needs updating for the three new commands?

## Next Research Steps
- Verify nodetool command help output is documented in the nodetool reference pages (if they exist)
- Confirm `auto_repair_priority` table usage and whether it warrants documentation
- Minor editorial review (typo fix on line 125)

## Notes
- The feature is disabled by default (`enabled: false` at both top level and per-repair-type level), which is a safe default for upgrades.
- The cassandra.yaml block is entirely commented out (lines 2777-2920), consistent with the disabled-by-default approach.
- The incremental repair migration section (lines 62-103) is particularly thorough and addresses a real operational pain point, with specific guidance for different compaction strategies (STCS, LCS, UCS).
- CEP-37 wiki: https://cwiki.apache.org/confluence/display/CASSANDRA/CEP-37+Apache+Cassandra+Unified+Repair+Solution
