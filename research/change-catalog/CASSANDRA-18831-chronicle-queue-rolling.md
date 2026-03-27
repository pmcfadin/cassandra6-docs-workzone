# CASSANDRA-18831 Chronicle Queue Log Rolling Deprecation (FAST_HOURLY Default)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
The JDK21 upgrade (CASSANDRA-18831) required updating the Chronicle Queue dependency, which changed the available enum names for log rolling cycles. The default `roll_cycle` for both full query logging (`full_query_logging_options`) and audit logging changed from `HOURLY` to `FAST_HOURLY`. The primary difference is index frequency: FAST_HOURLY builds 256 index entries vs. 16 in the old HOURLY. Legacy enum names (`HOURLY`, `MINUTELY`, `DAILY`) still resolve via Chronicle Queue's `RollCycles.valueOf()` but may emit deprecation warnings; future Chronicle Queue upgrades could remove them entirely.

## Discovery Source
- `NEWS.txt` reference: Section on JDK21 dependency updates; "The default log rolling param has been changed from HOURLY to FAST_HOURLY"
- `CHANGES.txt` reference: No explicit CHANGES.txt entry for the roll_cycle default change (bundled in CASSANDRA-18831 JDK21 support)
- Related JIRA: CASSANDRA-18831 (Add JDK21 support)
- Related CEP or design doc: None; this is a side-effect of dependency upgrades

## Why It Matters
- User-visible effect: Users who explicitly set `roll_cycle: HOURLY` will see deprecation warnings in logs. Users relying on the default get different segment rolling behavior.
- Operational effect: Log segment sizes and index granularity change. FAST_HOURLY creates 256 index entries per hour vs. 16 for HOURLY, affecting FQL/audit log file sizes and query replay tool behavior.
- Upgrade or compatibility effect: Legacy values (`HOURLY`, `MINUTELY`, `DAILY`) still work but may break in future Chronicle Queue upgrades. Operators upgrading to 6.0 should update their configurations proactively.
- Configuration or tooling effect: `cassandra.yaml` default changed; `nodetool enablefullquerylog --roll-cycle` and `nodetool enableauditlog --roll-cycle` help text already shows new values (`FAST_MINUTELY`, `FAST_HOURLY`, `FAST_DAILY`).

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/fqllogging.adoc` (OUTDATED: still shows `HOURLY` as default, lists `HOURLY, MINUTELY, DAILY` as supported values)
  - `doc/modules/cassandra/pages/managing/operating/audit_logging.adoc` (MIXED: audit log YAML section shows `FAST_HOURLY` correctly; auditlogviewer section still shows `MINUTELY, HOURLY, DAILY` and "Default HOURLY")
- Relevant config paths:
  - `conf/cassandra.yaml` lines 2150-2160: `roll_cycle: FAST_HOURLY` (correctly updated)
- Relevant code paths:
  - `src/java/org/apache/cassandra/utils/binlog/BinLogOptions.java`: `public String roll_cycle = "FAST_HOURLY"` (default)
  - `src/java/org/apache/cassandra/utils/binlog/BinLog.java`: Roll cycle resolution via `RollCycles.valueOf()`, special handling for deprecated `TEST_SECONDLY`
  - `src/java/org/apache/cassandra/tools/nodetool/EnableFullQueryLog.java`: `--roll-cycle` option description says `FAST_MINUTELY, FAST_HOURLY, FAST_DAILY`
  - `src/java/org/apache/cassandra/tools/nodetool/EnableAuditLog.java`: Same updated enum names
  - `src/java/org/apache/cassandra/fql/FullQueryLoggerOptions.java`: Extends `BinLogOptions`, inherits `FAST_HOURLY` default
- Relevant test paths:
  - `test/resources/nodetool/help/enablefullquerylog`: Help text shows `FAST_MINUTELY, FAST_HOURLY, FAST_DAILY`
- Relevant generated-doc paths: None identified

## What Changed
1. **Default value**: `roll_cycle` default changed from `HOURLY` to `FAST_HOURLY` in `BinLogOptions.java` (affects both FQL and audit logging).
2. **Enum naming**: Chronicle Queue's `RollCycles` enum uses `FAST_` prefixed names (`FAST_HOURLY`, `FAST_MINUTELY`, `FAST_DAILY`) as the canonical names. Old names may still resolve but are considered legacy.
3. **Index granularity**: `FAST_HOURLY` creates 256 index entries per cycle vs. 16 for the old `HOURLY`.
4. **cassandra.yaml**: The config file comment already shows `FAST_HOURLY`.
5. **nodetool help**: Both `enablefullquerylog` and `enableauditlog` nodetool commands already reference `FAST_*` names.
6. **Documentation gap**: The `fqllogging.adoc` page is NOT updated -- it still references `HOURLY` as the default and `HOURLY, MINUTELY, DAILY` as supported values.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/fqllogging.adoc` -- **needs update**: change default from `HOURLY` to `FAST_HOURLY`, update supported values list to `FAST_MINUTELY`, `FAST_HOURLY`, `FAST_DAILY` (with note about legacy names), update YAML example block
  - `doc/modules/cassandra/pages/managing/operating/audit_logging.adoc` -- **needs update**: the auditlogviewer section (line ~153) still says "Default HOURLY" and lists old enum names
- New pages likely needed: None
- Audience home: Operators
- Authored or generated: Authored
- Technical review needed from: Josh McKenzie (CASSANDRA-18831 author) or storage/logging domain expert

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: fqllogging.adoc; audit_logging.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Does Chronicle Queue's `RollCycles.valueOf("HOURLY")` currently emit a deprecation warning at runtime, or does it silently map to the new name? The BinLog code only has special handling for `TEST_SECONDLY`; other legacy names are passed through to `RollCycles.valueOf()` without explicit warning logic in Cassandra itself.
- What exact Chronicle Queue version is bundled with Cassandra 6.0, and which legacy names does it still support?
- Should the fqltool (replay/compare/dump) documentation also be updated for roll_cycle references?

## Next Research Steps
- Verify the exact Chronicle Queue version in Cassandra 6.0's dependency tree (check `build.xml` or gradle files)
- Test what happens when `HOURLY` is passed to `RollCycles.valueOf()` in the bundled Chronicle Queue version -- confirm whether it logs a warning
- Compare `fqllogging.adoc` content between cassandra-5.0 and trunk to confirm the page was not updated
- Update `fqllogging.adoc` and the auditlogviewer section of `audit_logging.adoc`

## Notes
- The code change itself is part of CASSANDRA-18831 (JDK21 support), authored by Josh McKenzie. The roll_cycle default change was a necessary side-effect, not a standalone feature.
- The `conf/cassandra.yaml` and nodetool Java source code are already correct. Only the .adoc documentation lags behind.
- The NEWS.txt explicitly warns: "Older legacy options will still work for the foreseeable future but you will see warnings in logs and future dependency upgrades may break your log rolling param."
- Available new enum options include: `FIVE_MINUTELY`, `FAST_MINUTELY`, `FAST_HOURLY`, `FAST_DAILY`, `LargeRollCycles.LARGE_DAILY`, `LargeRollCycles.XLARGE_DAILY`, `LargeRollCycles.HUGE_DAILY`.
