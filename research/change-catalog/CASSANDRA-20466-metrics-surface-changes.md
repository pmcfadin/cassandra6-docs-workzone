# Metrics Surface Changes (Consolidated): CASSANDRA-20466, 19486, 20499, 20132, 20502, 20864, 13890, 17062, 20870, 19447

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
This file consolidates ten related metrics surface changes that individually add or enrich metrics, nodetool commands, and JMX operations in Cassandra 6. Each change is a targeted addition to an existing metrics subsystem rather than a new major feature. Together they improve observability across hints delivery, compaction throughput, prepared statement caches, bootstrap progress, purgeable tombstones, SSTable interval tree latency, auth caches, and timer metrics in the `system_metrics` virtual tables.

---

## CASSANDRA-20466: Histogram columns added to timer metrics vtable

### Commit
`73cd2c56ca` — "Add histogram columns to timer metrics vtable"

### What Changed
`TimerMetricRow` in `src/java/org/apache/cassandra/db/virtual/model/TimerMetricRow.java` gained five new `@Column`-annotated methods: `max()`, `mean()`, `min()`, `p75th()`, and `p95th()`. Combined with the previously existing `p99th()` and `p999th()`, the `system_metrics.type_timer` virtual table (and all timer-type group tables) now exposes a full snapshot distribution including min, mean, max, and percentiles p75, p95, p98, p99, p999.

### Docs Impact
- `virtualtables.adoc` — the `system_metrics` timer table description (if any) needs updating to reflect the full column list
- `metrics.adoc` — any table describing timer metric columns should include `min`, `mean`, `max`, `p75th`, `p95th`
- Classification: minor-update to `virtualtables.adoc` and `metrics.adoc`

### Source Evidence
- `src/java/org/apache/cassandra/db/virtual/model/TimerMetricRow.java` — adds `p75th()`, `p95th()`, `p98th()`, `max()`, `mean()`, `min()` annotated columns
- `src/java/org/apache/cassandra/db/virtual/walker/TimerMetricRowWalker.java` — walker updated for new columns
- `test/unit/org/apache/cassandra/metrics/JmxVirtualTableMetricsTest.java` — test coverage added

---

## CASSANDRA-19486: system_views.pending_hints enriched with hint sizes

### Commit
`5b23692a90` — "Enrich system_views.pending_hints vtable with hints sizes"

### What Changed
`PendingHintsTable` gained two new columns: `total_size` (bigint, total bytes of all hint files for the target node) and `total_corrupted_files_size` (bigint, total bytes of corrupted hint files). These complement the existing `files` and `corrupted_files` count columns. The size information is backed by `PendingHintsInfo.totalSize` and `PendingHintsInfo.corruptedFilesSize`, populated via `HintsStore`.

### Docs Impact
- `virtualtables.adoc` — any existing `pending_hints` documentation needs the two new size columns added (currently the table is listed in the system_views description table but has no dedicated section)
- Classification: minor-update

### Source Evidence
- `src/java/org/apache/cassandra/db/virtual/PendingHintsTable.java` — `TOTAL_FILES_SIZE = "total_size"` (LongType) and `TOTAL_CORRUPTED_FILES_SIZE = "total_corrupted_files_size"` (LongType) columns added; both populated in `data()` method
- `src/java/org/apache/cassandra/hints/PendingHintsInfo.java` — `totalSize` and `corruptedFilesSize` fields added
- `src/java/org/apache/cassandra/hints/HintsStore.java` — size computation added
- `test/unit/org/apache/cassandra/hints/HintsPendingTableTest.java` — 163-line new test

---

## CASSANDRA-20499: Additional metrics around hints (HintsApplySucceeded, HintsApplyFailed, HintsThrottle, HintsFileSize)

### Commit
`1261ba159c` — "Add additional metrics around hints"

### What Changed
Four new metrics added to `HintsServiceMetrics`:
- `HintsApplySucceeded` (Meter) — fired on successful application of a hint at `HintVerbHandler`
- `HintsApplyFailed` (Meter) — fired on failed application of a hint
- `HintsThrottle` (Counter) — incremented by the bytes acquired from the rate limiter (`hinted_handoff_throttle_in_kb`)
- `HintsFileSize` (Gauge\<Long\>) — total on-disk size of all hint files for this node (backed by `HintsService.getTotalHintsSize()`)

All four metrics are available via JMX at `org.apache.cassandra.metrics:type=HintsService,name=<MetricName>` and via the `system_metrics.hints_service_group` virtual table.

The `metrics.adoc` was updated as part of this commit (44-line diff, net reduction due to reformatting plus 3 new entries documented).

### Docs Impact
- `metrics.adoc` — updated in the commit: `HintsApplySucceeded`, `HintsApplyFailed`, `HintsThrottle` documented (lines ~897–899 on trunk); `HintsFileSize` should be verified as documented
- Status: largely covered; verify `HintsFileSize` is present in the metrics table
- Classification: minor-update (verify completeness)

### Source Evidence
- `src/java/org/apache/cassandra/metrics/HintsServiceMetrics.java` — `hintsApplySucceeded`, `hintsApplyFailed`, `hintsThrottle`, `hintsFileSize` metric fields
- `src/java/org/apache/cassandra/hints/HintVerbHandler.java` — calls `HintsServiceMetrics.hintsApplySucceeded.mark()` / `hintsApplyFailed.mark()`
- `src/java/org/apache/cassandra/hints/HintsReader.java` — calls `hintsThrottle.inc(size)` via `applyThrottleRateLimit`
- `doc/modules/cassandra/pages/managing/operating/metrics.adoc` — updated in this commit

---

## CASSANDRA-20132: PurgeableTombstoneScannedHistogram table metric + tracing event

### Commit
`d7258ac8f3` — "Add table metric PurgeableTombstoneScannedHistogram and a tracing event for scanned purgeable tombstones"

### What Changed
1. New `TableMetrics` field `purgeableTombstoneScannedHistogram` (type: `TableHistogram`) — registered as `PurgeableTombstoneScannedHistogram` in JMX and exposed via `system_views.purgeable_tombstones_per_read` virtual table (added to `TableMetricTables.getAll()` in `TableMetricTables.java`).
2. New `cassandra.yaml` configuration property `tombstone_read_purgeable_metric_granularity` (default: `disabled`) with values:
   - `disabled` — metric not collected
   - `row` — tracks partition/range/row-level tombstones (~\<1% CPU overhead for CPU-bound workloads)
   - `cell` — tracks all tombstone types including cell-level (~5% CPU overhead for CPU-bound workloads)
3. A new tracing event is emitted when purgeable tombstones are scanned.
4. `metrics.adoc` updated: `PurgeableTombstoneScannedHistogram` is documented at line 184 with the note about the `tombstone_read_purgeable_metric_granularity` property.

### Docs Impact
- `metrics.adoc` — documented (line 184 on trunk); complete
- `virtualtables.adoc` — `purgeable_tombstones_per_read` virtual table in `system_views` is listed in the description table but has no dedicated section; the companion tombstones section does not mention the purgeable variant
- `cassandra.yaml` reference — `tombstone_read_purgeable_metric_granularity` is a new configuration property with performance implications that needs operator guidance
- Classification: minor-update to `virtualtables.adoc` and configuration reference

### Source Evidence
- `src/java/org/apache/cassandra/metrics/TableMetrics.java` line 166: `public final TableHistogram purgeableTombstoneScannedHistogram;`; line 813: initialization
- `src/java/org/apache/cassandra/db/virtual/TableMetricTables.java` — `new HistogramTableMetric(name, "purgeable_tombstones_per_read", t -> t.purgeableTombstoneScannedHistogram.cf)` in `getAll()`
- `conf/cassandra.yaml` lines 2014–2026: `tombstone_read_purgeable_metric_granularity` property documentation

---

## CASSANDRA-20502: SSTableIntervalTree latency metric

### Commit
`67df6a5bff` — "Add SSTableIntervalTree latency metric"

### What Changed
New `LatencyMetrics` field `viewSSTableIntervalTree` added to `TableMetrics` (line 315–316) tracking "time spent building SSTableIntervalTree when constructing a new View under the Tracker lock". The metric is registered as `ViewSSTableIntervalTree` and exposed via JMX (`type=ColumnFamily,scope=<table>,name=ViewSSTableIntervalTreeLatency` etc.) and also via `KeyspaceMetrics` (`viewSSTableIntervalTree`). This is a diagnostic metric for tracking lock contention during SSTable view construction.

### Docs Impact
- `metrics.adoc` — `ViewSSTableIntervalTree` does not appear in the current trunk doc (confirmed by search); this metric is missing from the Table Metrics or Keyspace Metrics section
- Classification: minor-update to `metrics.adoc`

### Source Evidence
- `src/java/org/apache/cassandra/metrics/TableMetrics.java` line 315: `public final LatencyMetrics viewSSTableIntervalTree;`; line 916: initialization `createLatencyMetrics("ViewSSTableIntervalTree", ...)`
- `src/java/org/apache/cassandra/metrics/KeyspaceMetrics.java` — `viewSSTableIntervalTree` field added
- `src/java/org/apache/cassandra/db/lifecycle/Tracker.java` — metric updated during view construction
- `src/java/org/apache/cassandra/db/lifecycle/View.java` — metric wired in

---

## CASSANDRA-20864: Prepared Statement Cache Size metric (bytes)

### Commit
`f41b625e48` — "Expose Metric for Prepared Statement Cache Size (in bytes)"

### What Changed
New `CQLMetrics` field `preparedStatementsCacheSize` (type: `Gauge<Long>`) registered as `PreparedStatementsCacheSize`, reporting the memory usage of the prepared statements cache in bytes via `QueryProcessor.preparedStatementsCacheMemoryUsedBytes()`. Available via JMX at `org.apache.cassandra.metrics:type=CQL,name=PreparedStatementsCacheSize`.

The `metrics.adoc` was updated in this commit and documents `PreparedStatementsCacheSize` at line 675 on trunk: `|PreparedStatementsCacheSize | Gauge<Long> | The size of the prepared statements cache in bytes.`

### Docs Impact
- `metrics.adoc` — documented; complete
- `virtualtables.adoc` — `cql_metrics` virtual table section (lines 336–352 on trunk) lists `PreparedStatementsCount`, `PreparedStatementsEvicted`, `PreparedStatementsExecuted`, `PreparedStatementsRatio` but does not list `PreparedStatementsCacheSize`; the example output shown in that section is stale
- Classification: minor-update to `virtualtables.adoc` CQL metrics example

### Source Evidence
- `src/java/org/apache/cassandra/metrics/CQLMetrics.java` line 41: `public final Gauge<Long> preparedStatementsCacheSize;`; line 69: registration as `PreparedStatementsCacheSize`
- `src/java/org/apache/cassandra/cql3/QueryProcessor.java` — `preparedStatementsCacheMemoryUsedBytes()` method used by the gauge
- `doc/modules/cassandra/pages/managing/operating/metrics.adoc` line 675: documented

---

## CASSANDRA-13890: Current compaction throughput in nodetool

### Commit
`26ff589f3d` — "Expose current compaction throughput in nodetool"

### What Changed
1. New `CompactionMetrics` field `bytesCompactedThroughput` (type: `Meter`) registered as `BytesCompactedThroughput`, measuring the recent/current rate of bytes compacted.
2. `nodetool getcompactionthroughput` now outputs three additional lines showing the rolling average throughput from the `BytesCompactedThroughput` meter:
   - `Current compaction throughput (1 minute): <value> MiB/s`
   - `Current compaction throughput (5 minute): <value> MiB/s`
   - `Current compaction throughput (15 minute): <value> MiB/s`
3. `StorageService` exposes `getCurrentCompactionThroughputMiBPerSec()` to provide the three rolling averages via JMX/nodetool probe.

### Docs Impact
- `metrics.adoc` — `BytesCompactedThroughput` is **not** present in the Compaction Metrics table on trunk (confirmed by search); needs to be added
- nodetool docs — `getcompactionthroughput` output is changed; existing docs (if any) need updating to show the new lines
- Classification: minor-update to `metrics.adoc`; check nodetool reference

### Source Evidence
- `src/java/org/apache/cassandra/metrics/CompactionMetrics.java` line 57–58: `public final Meter bytesCompactedThroughput;`; registered as `BytesCompactedThroughput` at line 152
- `src/java/org/apache/cassandra/tools/nodetool/GetCompactionThroughput.java` — added `getCurrentCompactionThroughputMiBPerSec()` call and three output lines
- `src/java/org/apache/cassandra/service/StorageService.java` — `getCurrentCompactionThroughputMiBPerSec()` returns 1-minute, 5-minute, 15-minute rates as a map

---

## CASSANDRA-17062: Auth cache metrics via JMX (UnweightedCacheMetrics)

### Commit
`64e2a4e9a3` — "Refactor structure of caching metrics and expose auth cache metrics via JMX"

### What Changed
Auth caches (`AuthCache` and subclasses) now expose `UnweightedCacheMetrics` via JMX. The `UnweightedCacheMetrics` class was introduced/refactored to expose per-cache metrics under `org.apache.cassandra.metrics:type=UnweightedCache,scope=<CacheName>,name=<MetricName>` with columns: `MaxEntries`, `Entries`, `FifteenMinuteCacheHitRate`, `FiveMinuteCacheHitRate`, `OneMinuteCacheHitRate`, `HitRate`, `Hits`, `Misses`, `MissLatency`, `Requests`. Seven caches are covered: `CredentialsCache`, `JmxPermissionsCache`, `CIDRPermissionsCache`, `IdentityCache`, `NetworkPermissionsCache`, `PermissionsCache`, `RolesCache`.

The `metrics.adoc` was updated as part of this commit with a 64-line addition documenting the new "Unweighted Cache Metrics" section (now lines ~599–643 on trunk). A note clarifies that auth cache MBeans are only available if the corresponding authorizer/authenticator is enabled.

### Docs Impact
- `metrics.adoc` — documented; the "Unweighted Cache Metrics" section appears complete
- `system_metrics.unweighted_cache_group` — the `system_metrics` virtual table `unweighted_cache_group` exposes these same metrics via CQL (the group appears in the `all_groups` table on trunk)
- Classification: likely complete; verify `unweighted_cache_group` virtual table columns match the documented metrics

### Source Evidence
- `src/java/org/apache/cassandra/metrics/UnweightedCacheMetrics.java` — `MaxEntries` (Gauge\<Integer\>), `Entries` (Gauge\<Integer\>) plus inherited hit/miss metrics
- `src/java/org/apache/cassandra/auth/AuthCache.java` — `metrics` field of type `UnweightedCacheMetrics`; initialized at line 188
- `doc/modules/cassandra/pages/managing/operating/metrics.adoc` — "Unweighted Cache Metrics" section added

---

## CASSANDRA-20870: StorageService.dropPreparedStatements via JMX

### Commit
`c5d6a36fa7` — "Expose StorageService.dropPreparedStatements via JMX"

### What Changed
`StorageServiceMBean` gained a new JMX operation `dropPreparedStatements(boolean memoryOnly)`. The implementation delegates to `QueryProcessor.instance.clearPreparedStatements(memoryOnly)`. The `memoryOnly` parameter controls whether the prepared statement cache is cleared only in memory (true) or also invalidated on disk (false). This allows operators to remotely clear the prepared statement cache via JMX without restarting the node.

### Docs Impact
- No change to `metrics.adoc` (this is an operation, not a metric)
- The JMX operations reference (if any) should document `dropPreparedStatements(boolean memoryOnly)` under `StorageService`
- Existing prepared statement cache documentation should cross-reference this operation
- Classification: minor-update (JMX operations reference or operational docs)

### Source Evidence
- `src/java/org/apache/cassandra/service/StorageService.java` line 2782: `public void dropPreparedStatements(boolean memoryOnly)` delegates to `QueryProcessor.instance.clearPreparedStatements(memoryOnly)`
- `src/java/org/apache/cassandra/service/StorageServiceMBean.java` line 1406: `public void dropPreparedStatements(boolean memoryOnly);` (JMX interface)

---

## CASSANDRA-19447: Bootstrap process Dropwizard metrics

### Commit
`81a2cb782e` — "Register the measurements of the bootstrap process as Dropwizard metrics"

### What Changed
Four new Dropwizard metrics registered in `BootStrapper` via `StorageMetrics.factory` under `type=Storage`:
- `BootstrapFilesTotal` (Gauge\<Long\>) — total number of files to receive during bootstrap
- `BootstrapFilesReceived` (Gauge\<Long\>) — number of files received so far
- `BootstrapLastSeenStatus` (Gauge\<String\>) — last status message (e.g., "Beginning bootstrap process")
- `BootstrapLastSeenError` (Gauge\<String\>) — last error message seen during bootstrap

Additionally, `BootstrapFilesThroughput` (Meter) was added to `StorageMetrics` proper, marked on each file received.

The `metrics.adoc` is updated and documents all five metrics in the Storage Metrics table (lines 826–830 on trunk), though `BootstrapFilesReceived` has a typo (`Gauage<Long>` instead of `Gauge<Long>`).

### Docs Impact
- `metrics.adoc` — documented; fix typo `Gauage<Long>` → `Gauge<Long>` for `BootstrapFilesReceived` (line 826)
- `system_metrics.storage_group` virtual table — these metrics are available via CQL via the `storage_group` virtual table
- Classification: minor-update (typo fix in `metrics.adoc`)

### Source Evidence
- `src/java/org/apache/cassandra/dht/BootStrapper.java` — static block registers `BootstrapFilesTotal`, `BootstrapFilesReceived`, `BootstrapLastSeenStatus`, `BootstrapLastSeenError` using `AtomicLong`/`AtomicReference` backing fields; progress listener updates these values
- `src/java/org/apache/cassandra/metrics/StorageMetrics.java` line 54: `public static final Meter bootstrapFilesThroughputMetric` registered as `BootstrapFilesThroughput`
- `doc/modules/cassandra/pages/managing/operating/metrics.adoc` lines 826–830: documented (with typo)

---

## Combined Docs Impact Summary

| JIRA | Docs change needed | Affected file | Urgency |
|---|---|---|---|
| CASSANDRA-20466 | Add `min`, `mean`, `max`, `p75th`, `p95th` to timer metrics column list | `metrics.adoc`, `virtualtables.adoc` | low |
| CASSANDRA-19486 | Add `total_size`, `total_corrupted_files_size` to pending_hints section | `virtualtables.adoc` | low |
| CASSANDRA-20499 | Verify `HintsFileSize` is documented | `metrics.adoc` | low |
| CASSANDRA-20132 | Add `purgeable_tombstones_per_read` vtable section; config property docs | `virtualtables.adoc`, config ref | medium |
| CASSANDRA-20502 | Add `ViewSSTableIntervalTree` to Table Metrics table | `metrics.adoc` | low |
| CASSANDRA-20864 | Add `PreparedStatementsCacheSize` to `cql_metrics` vtable example | `virtualtables.adoc` | low |
| CASSANDRA-13890 | Add `BytesCompactedThroughput` to Compaction Metrics table; update `getcompactionthroughput` docs | `metrics.adoc` | medium |
| CASSANDRA-17062 | Verify `unweighted_cache_group` vtable columns match docs | `metrics.adoc`, `virtualtables.adoc` | low |
| CASSANDRA-20870 | Document `dropPreparedStatements(boolean)` JMX operation | JMX ops reference | low |
| CASSANDRA-19447 | Fix `Gauage<Long>` typo for `BootstrapFilesReceived` | `metrics.adoc` | low |

## Proposed Disposition
- `inventory/docs-map.csv` classification: minor-update (each individually small; combined they touch `metrics.adoc` and `virtualtables.adoc`)
- Recommended owner role: docs-contributor
- Publish blocker: no

## Open Questions
- CASSANDRA-20132: Is `tombstone_read_purgeable_metric_granularity` documented in the configuration reference? A cross-reference from the metrics doc to the yaml config page would be valuable.
- CASSANDRA-20466: The `type_timer` virtual table in `system_metrics` — should docs show the full column list for a timer row to help operators know what to expect?
- CASSANDRA-20870: Is there an existing JMX operations reference page for `StorageService`? If not, `dropPreparedStatements` is a new operation without a home.
- CASSANDRA-13890: Does `nodetool compactionstats` output also show the new throughput, or only `getcompactionthroughput`? Check `CompactionStats.java` usage of `getCurrentCompactionThroughputMiBPerSec`.

## Next Research Steps
- Search `metrics.adoc` for `BytesCompactedThroughput` and `ViewSSTableIntervalTree` — confirm they are absent and flag for addition
- Search `virtualtables.adoc` for `pending_hints` — confirm the two new size columns are not yet listed in any example
- Check `CompactionStats.java` to determine if `getCurrentCompactionThroughputMiBPerSec` is also used there
- Verify the `HintsFileSize` metric presence in `metrics.adoc` HintedHandoff section
