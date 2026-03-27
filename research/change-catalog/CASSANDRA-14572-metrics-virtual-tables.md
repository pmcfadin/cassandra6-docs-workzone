# CASSANDRA-14572 All Dropwizard metrics exposed in system_metrics virtual keyspace

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
CASSANDRA-14572 introduces a new `system_metrics` virtual keyspace that exposes every registered Dropwizard metric in Cassandra as a queryable CQL virtual table. The keyspace contains one table per metric group (e.g., `compaction_group`, `table_group`, `hints_service_group`) plus four cross-cutting type tables (`type_counter`, `type_gauge`, `type_histogram`, `type_timer`) and an `all_groups` index table. This replaces and supersedes the older JMX-only path as the canonical way to inspect any metric via CQL. Basic documentation already exists in `virtualtables.adoc` on trunk, but it predates the full set of groups and omits important operational details.

## Discovery Source
- `NEWS.txt` reference: not verified
- `CHANGES.txt` reference: "Expose all dropwizard metrics in virtual tables (CASSANDRA-14572)"
- Related JIRA: CASSANDRA-14572
- Related JIRA: CASSANDRA-20466 (adds histogram columns to timer metrics vtable — see consolidated metrics file)

## Why It Matters
- User-visible effect: Operators can query any Cassandra metric (counter, gauge, histogram, meter, timer) via CQL against `system_metrics.*`. Previously, many metrics required JMX access or custom tooling.
- Operational effect: Enables metrics-based alerting and dashboards using standard CQL drivers without JMX exposure. The `all_groups` table provides discovery of available metric groups at runtime.
- Upgrade or compatibility effect: The `system_metrics` keyspace is new in Cassandra 6.0 (not present in 5.0). The older per-table metric virtual tables in `system_views` (e.g., `local_read_latency`, `disk_usage`) remain available for backward compatibility.
- Configuration or tooling effect: No new configuration. Uses the same Dropwizard registry (`CassandraMetricsRegistry`) already driving JMX. The `system_metrics` keyspace name is defined in `SchemaConstants.VIRTUAL_METRICS`.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — section "Virtual Tables system_metrics Keyspace" (lines 63–168 on trunk) documents the `all_groups` table with example output listing all 37 groups; does not document per-group table schemas, type-tables, or query patterns beyond `all_groups`
  - `doc/modules/cassandra/pages/managing/operating/metrics.adoc` — mentions the `system_metrics` keyspace briefly in the context of specific metric types
- Relevant code paths:
  - `src/java/org/apache/cassandra/metrics/CassandraMetricsRegistry.java` — `createMetricsKeyspaceTables()` method builds the full list of virtual tables; per-group tables use `createSinglePartitionedKeyFiltered`; type tables (`type_counter`, `type_gauge`, `type_histogram`, `type_meter`, `type_timer`) use `createSinglePartitionedValueFiltered`
  - `src/java/org/apache/cassandra/db/virtual/CollectionVirtualTableAdapter.java` — the core adapter class introduced by this JIRA (582-line addition); wraps a `ConcurrentMap` of metrics with row walkers
  - `src/java/org/apache/cassandra/db/virtual/model/TimerMetricRow.java` — timer row model with `count`, rate columns (`fifteenMinuteRate`, `fiveMinuteRate`, `meanRate`, `oneMinuteRate`) and percentiles (`p75th`, `p95th`, `p98th`, `p99th`, `p999th`, `max`, `mean`, `min`)
  - `src/java/org/apache/cassandra/db/virtual/model/CounterMetricRow.java` — counter row model
  - `src/java/org/apache/cassandra/db/virtual/model/GaugeMetricRow.java` — gauge row model
  - `src/java/org/apache/cassandra/db/virtual/model/HistogramMetricRow.java` — histogram row model
  - `src/java/org/apache/cassandra/db/virtual/model/MeterMetricRow.java` — meter row model
  - `src/java/org/apache/cassandra/db/virtual/SystemViewsKeyspace.java` — updated to use `CollectionVirtualTableAdapter` for `thread_pools` (replacing the deleted `ThreadPoolsTable.java`)
  - `src/java/org/apache/cassandra/schema/SchemaConstants.java` — `VIRTUAL_METRICS = "system_metrics"` constant added
  - `src/java/org/apache/cassandra/service/CassandraDaemon.java` — registers `system_metrics` virtual keyspace at startup
- Relevant test paths:
  - `test/unit/org/apache/cassandra/metrics/JmxVirtualTableMetricsTest.java` — 336-line new test file
  - `test/unit/org/apache/cassandra/metrics/CassandraMetricsRegistryTest.java` — expanded significantly (117-line additions)
  - `test/unit/org/apache/cassandra/db/virtual/CollectionVirtualTableAdapterTest.java` — new 243-line test

## What Changed
1. New virtual keyspace `system_metrics` containing:
   - **Per-group tables**: one table per metric group name (37 groups visible in trunk example, e.g., `compaction_group`, `hints_service_group`, `table_group`). Each table has partition key `name` (the full metric name), plus all metric columns for that group's dominant type.
   - **`all_groups`** table: maps `group_name` to `virtual_table`; used for discovery.
   - **Type tables**: `type_counter`, `type_gauge`, `type_histogram`, `type_meter`, `type_timer` — each shows all registered metrics of that Dropwizard type across all groups.
2. `CollectionVirtualTableAdapter` is the generic mechanism for exposing any `ConcurrentMap<String, Metric>` as a virtual table using annotated row-model POJOs and walker classes.
3. The `ThreadPoolsTable` class was deleted and replaced by a `CollectionVirtualTableAdapter`-backed implementation under the same `system_views.thread_pools` name for backward compatibility.
4. `TimerMetricRow` exposes full percentile distribution: `p75th`, `p95th`, `p98th`, `p99th`, `p999th`, `max`, `mean`, `min` (enhanced further by CASSANDRA-20466 — see consolidated metrics file).
5. CQL completion in `cqlsh` was updated to recognize `system_metrics` as a virtual keyspace.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — the existing section shows `all_groups` output but does not:
    1. Describe per-group table schemas or show sample queries against a group table
    2. Document the four type tables (`type_counter`, `type_gauge`, etc.) or their schemas
    3. Explain the naming convention (metric group → virtual table name pattern)
    4. Document `CollectionVirtualTableAdapter` behavior (partitioned by metric group prefix in name)
    5. Show how to discover all metrics for a specific component (e.g., all compaction metrics)
  - `doc/modules/cassandra/pages/managing/operating/metrics.adoc` — cross-reference to `system_metrics` could be strengthened; many metric descriptions could note the corresponding virtual table query
- New pages likely needed: Possibly a dedicated `system-metrics-keyspace.adoc` reference page listing all groups and their schemas; alternatively, a substantial expansion of the `system_metrics` section in `virtualtables.adoc`
- Audience home: Operators
- Authored or generated: This is authored content; the virtual table implementations are auto-generated from annotated Java model classes at registration time, but the documentation is hand-written
- Technical review needed from: Metrics domain expert

## Proposed Disposition
- `inventory/docs-map.csv` classification: major-update
- Affected docs: `virtualtables.adoc`; `metrics.adoc` (cross-references)
- Recommended owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should `system_metrics` get its own dedicated reference page, or is an expanded section in `virtualtables.adoc` sufficient?
- The `all_groups` table lists 37 metric groups on trunk. Is this list stable for 6.0, or might groups be added/removed before GA?
- How does querying a per-group table differ in performance vs. querying `type_timer` with `ALLOW FILTERING`? Any guidance for operators on which to use?
- The type tables (`type_counter` etc.) cross all groups — is there an upper bound on how many rows they contain in production clusters?

## Next Research Steps
- Read `CollectionVirtualTableAdapter.java` in full to understand query semantics (single-partition vs. range behavior, filter pushdown)
- Sample the schemas for several group tables (e.g., `compaction_group`, `table_group`) to produce representative documentation examples
- Check whether `metrics.adoc` already cross-references `system_metrics` for each metric category, and identify gaps
- Determine whether a separate `system-metrics-keyspace.adoc` page is warranted or if `virtualtables.adoc` expansion is preferred

## Notes
- Commit: `2e7def7626` on trunk — "Expose all dropwizard metrics in virtual tables"; 87 files changed, 3,909 insertions, 315 deletions
- The `system_metrics` keyspace was added to `SchemaConstants.SYSTEM_KEYSPACE_NAMES` set, meaning it receives the same protections as other system keyspaces.
- `ThreadPoolsTable.java` was deleted (94 lines removed) and replaced by `CollectionVirtualTableAdapter.create(...)` registration in `SystemViewsKeyspace.java`; the table name `thread_pools` in `system_views` was preserved for backward compatibility.
- The `CassandraRelevantProperties` was not modified by this JIRA — no new JVM properties are needed.
- Not present in cassandra-5.0 (the entire `system_metrics` keyspace is new).
