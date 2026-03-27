# CASSANDRA-13001 system_views.slow_queries virtual table

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary
CASSANDRA-13001 adds `system_views.slow_queries`, a virtual table that accumulates slow-query monitoring events from `MonitoringTask` into an in-memory ring buffer and exposes them via CQL. Each row identifies the keyspace, table, query text, and timestamp of the slow operation, along with aggregated timing (min/max/avg in milliseconds), a hit count (`times_reported`), and a flag indicating whether the query was cross-node. The buffer holds up to 10,000 rows by default (configurable up to 100,000 via the JVM property `cassandra.virtual.slow_queries.max.rows`). Rows survive only in memory and reset on node restart.

## Discovery Source
- `NEWS.txt` reference: not verified
- `CHANGES.txt` reference: "Implement appender of slow queries to system_views.slow_queries table (CASSANDRA-13001)"
- Related JIRA: CASSANDRA-13001
- Related JIRA: CASSANDRA-19003 (log_messages virtual table — same AbstractLoggerVirtualTable base class)

## Why It Matters
- User-visible effect: Operators can now query `SELECT * FROM system_views.slow_queries` in CQL to inspect slow operations without scraping logs. The table is filterable with `ALLOW FILTERING`.
- Operational effect: Enables cluster-wide slow-query visibility via standard CQL tooling. Log-based slow query detection no longer requires log parsing.
- Upgrade or compatibility effect: Additive. No existing APIs change. The table did not exist in Cassandra 5.0.
- Configuration or tooling effect: The in-memory buffer size is controlled by `-Dcassandra.virtual.slow_queries.max.rows` (default 10,000; max 100,000). Partitions (by keyspace) can be deleted with a `DELETE FROM system_views.slow_queries WHERE keyspace_name = '...'` statement.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — `slow_queries` is not mentioned anywhere in the current doc (confirmed by text search on trunk)
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/virtual/SlowQueriesTable.java` — table definition; partition key `keyspace_name` (text), clustering `table_name` (text), `timestamp` (timestamp), `query` (text); regular columns `min_ms` (bigint), `max_ms` (bigint), `avg_ms` (bigint), `times_reported` (int), `cross_node` (boolean)
  - `src/java/org/apache/cassandra/db/virtual/SystemViewsKeyspace.java` — registered as `.add(new SlowQueriesTable(VIRTUAL_VIEWS))`
  - `src/java/org/apache/cassandra/db/virtual/AbstractLoggerVirtualTable.java` — shared base class (used by `log_messages` too) providing the ring-buffer mechanism
  - `src/java/org/apache/cassandra/config/CassandraRelevantProperties.java` — `LOGS_SLOW_QUERIES_VIRTUAL_TABLE_MAX_ROWS` property (`cassandra.virtual.slow_queries.max.rows`, default 10,000, max 100,000)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/virtual/SlowQueriesTableTest.java`
  - `test/distributed/org/apache/cassandra/distributed/test/SlowQueriesAppenderTest.java`

## What Changed
1. New virtual table `system_views.slow_queries` registered in `SystemViewsKeyspace`.
2. Schema (from `SlowQueriesTable.java`):
   - Partition key: `keyspace_name text`
   - Clustering: `table_name text`, `timestamp timestamp`, `query text`
   - Regular: `min_ms bigint`, `max_ms bigint`, `avg_ms bigint`, `times_reported int`, `cross_node boolean`
3. The table uses a ring buffer capped at `LOGS_VIRTUAL_TABLE_DEFAULT_ROWS` (10,000) entries by default. The cap is configurable via `-Dcassandra.virtual.slow_queries.max.rows` up to `LOGS_VIRTUAL_TABLE_MAX_ROWS` (100,000).
4. Partition-level `DELETE` is supported (removes all slow queries for a keyspace); row-level deletes are not.
5. `ALLOW FILTERING` is permitted implicitly on this table.
6. Timestamps are in milliseconds; timing values (`min_ms`, `max_ms`, `avg_ms`) are in milliseconds (converted from nanoseconds internally).

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — needs a new section describing `slow_queries` schema, buffer size config, sample queries, and the ring-buffer eviction behavior
- New pages likely needed: None; the section belongs in `virtualtables.adoc` alongside `log_messages`
- Audience home: Operators
- Authored or generated: Authored (the virtual tables page is hand-written)
- Technical review needed from: Performance / monitoring domain

## Proposed Disposition
- `inventory/docs-map.csv` classification: major-update
- Affected docs: `virtualtables.adoc`
- Recommended owner role: docs-contributor or docs-lead
- Publish blocker: no

## Open Questions
- Is the slow-query threshold configured via the existing `slow_query_log_timeout_in_ms` setting in `cassandra.yaml`? Confirm relationship between that setting and what populates this table.
- Does `cross_node` indicate coordinator-only vs. cross-node reads, or something else? Source in `MonitoringTask.Operation` should be confirmed.
- Does deleting a partition remove only the in-memory buffer for that keyspace on the local node, or does it propagate?

## Next Research Steps
- Confirm the relationship between `slow_query_log_timeout_in_ms` and the slow-query virtual table by reading `MonitoringTask.java`
- Verify what `cross_node` means by reading `MonitoringTask.Operation`
- Draft a `virtualtables.adoc` section analogous to the `log_messages` section, including schema, CQL sample queries, and configuration note

## Notes
- Commit: `8fcf309dad` on trunk — "Implement appender of slow queries to system_views.slow_queries table"
- This table uses the same `AbstractLoggerVirtualTable<T>` base as `system_views.log_messages`, which is already documented in `virtualtables.adoc`. The documentation pattern for `log_messages` is a reasonable template.
- The table did not exist in cassandra-5.0 (confirmed: `SlowQueriesTable.java` is not present on the `cassandra-5.0` branch).
