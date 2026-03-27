# CASSANDRA-19289 Thread pool stats in nodetool tpstats --verbose

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-19289 exposes three thread pool configuration parameters -- `core_pool_size`, `max_pool_size`, and `max_tasks_queued` -- through both `nodetool tpstats --verbose` and the `system_views.thread_pools` virtual table. Previously these values were only accessible via JMX. The nodetool change uses a `--verbose` / `-v` flag to preserve backward compatibility, while the virtual table always includes the new columns.

## Discovery Source
- `NEWS.txt` reference: "nodetool tpstats can display core pool size, max pool size and max tasks queued if --verbose / -v flag is specified. system_views.thread_pools adds core_pool_size, max_pool_size and max_tasks_queued columns."
- `CHANGES.txt` reference: "Extend nodetool tpstats and system_views.thread_pools with detailed pool parameters (CASSANDRA-19289)"
- Related JIRA: CASSANDRA-19289
- Related JIRA: CASSANDRA-19328 (bug fix for incorrect `getMaxTasksQueued` return value in `ThreadPoolExecutorPlus`)

## Why It Matters
- User-visible effect: Operators can inspect thread pool sizing directly from `nodetool tpstats --verbose` or CQL queries against `system_views.thread_pools` without needing JMX access. This simplifies debugging thread pool saturation and capacity planning.
- Operational effect: Reduces the need for JMX-only tooling to understand thread pool configuration. Useful for environments where JMX access is restricted.
- Upgrade or compatibility effect: No breaking changes. The `--verbose` flag is additive for nodetool. New columns in `system_views.thread_pools` are additive.
- Configuration or tooling effect: No new configuration. The `--verbose` / `-v` flag is the only new user-facing control.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` -- Thread Pools Virtual Table section (lines 434-476). Already has a note about CASSANDRA-19289 at line 441, but the example query output does not include the three new columns.
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` -- Threadpool State section (lines 132-181). Documents `nodetool tpstats` but does not mention `--verbose` flag or the new columns.
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/stats/TpStatsPrinter.java` -- `print(data, out, verbose)` method: when `verbose` is true, adds "Core Pool Size", "Max Pool Size", "Max Tasks Queued" columns to the table header and fetches `CorePoolSize`, `MaxPoolSize`, `MaxTasksQueued` metrics for each pool.
  - `src/java/org/apache/cassandra/tools/nodetool/stats/TpStatsHolder.java` -- passes verbose flag through.
  - `src/java/org/apache/cassandra/db/virtual/walker/ThreadPoolRowWalker.java` -- defines `core_pool_size`, `max_pool_size`, `max_tasks_queued` as REGULAR columns in `system_views.thread_pools`.
  - `src/java/org/apache/cassandra/metrics/ThreadPoolMetrics.java` -- exposes `CorePoolSize`, `MaxPoolSize`, `MaxTasksQueued` JMX metrics.
  - `src/java/org/apache/cassandra/concurrent/ThreadPoolExecutorBase.java` -- `getMaxTasksQueued()` implementation (bug fix moved here from `ThreadPoolExecutorPlus` to cover `UDFExecutorService` as well).
  - `src/java/org/apache/cassandra/concurrent/ResizableThreadPool.java` / `ResizableThreadPoolMXBean.java` -- interface definitions for pool size accessors.
- Relevant test paths: (not investigated)

## What Changed
1. **nodetool tpstats --verbose** adds three columns to the thread pool table:
   - "Core Pool Size" -- the core (minimum) number of threads in the pool
   - "Max Pool Size" -- the maximum number of threads the pool can scale to
   - "Max Tasks Queued" -- the maximum number of tasks that can be queued before blocking
2. **system_views.thread_pools** gains three new columns (always visible, no flag needed):
   - `core_pool_size` (int)
   - `max_pool_size` (int)
   - `max_tasks_queued` (int)
3. **Bug fix**: `getMaxTasksQueued()` was moved from `ThreadPoolExecutorPlus` to `ThreadPoolExecutorBase` to correctly report the value for all executor types including `UDFExecutorService` (related CASSANDRA-19328).

## Docs Impact
- Existing pages likely affected:
  - `virtualtables.adoc` -- Thread Pools section (line 434). Already has a brief mention of CASSANDRA-19289 at line 441, but the example CQL output (lines 446-476) does not show the `core_pool_size`, `max_pool_size`, or `max_tasks_queued` columns. The example needs to be updated to include these columns.
  - `use_nodetool.adoc` -- Threadpool State section (line 132). The `nodetool tpstats` example does not mention the `--verbose` flag. Should add a note about `--verbose` / `-v` and show example output with the additional columns.
- New pages likely needed: None
- Audience home: Operators
- Authored or generated: Authored content in both pages. No generated-doc surfaces affected.
- Technical review needed from: Concurrency / thread pool domain expert

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: virtualtables.adoc; use_nodetool.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- The `virtualtables.adoc` example output for `thread_pools` currently omits the three new columns even though the text mentions them. Should the example be fully regenerated or manually updated?
- Should the `use_nodetool.adoc` tpstats section show two examples (default and verbose) or just note the flag?
- The `--verbose` flag is handled in `TpStatsPrinter` -- where is the picocli `--verbose` option defined? Need to confirm whether it is on the TpStats command class or inherited.

## Next Research Steps
- Update the `system_views.thread_pools` example in `virtualtables.adoc` to include the three new columns
- Add `--verbose` documentation to the `nodetool tpstats` section in `use_nodetool.adoc`
- Locate the picocli `--verbose` option definition for the tpstats command to confirm flag name/aliases

## Notes
- Reporter/assignee: Stefan Miklosovic. Fix version: 6.0-alpha1, 6.0.
- GitHub PR: apache/cassandra#3066. Commit: 37acd27f2d0e79fac969e34304bff2d6641728f5.
- The values exposed via `--verbose` match what was already available through JMX (`ResizableThreadPoolMXBean`), just now surfaced through more accessible interfaces.
- The `max_tasks_queued` value for unbounded pools (like `Repair-Task` with `max_pool_size` of `Integer.MAX_VALUE`) may show as 0 or a sentinel value -- worth verifying in the example output.
