# CASSANDRA-20161 system_views.partition_key_statistics virtual table

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-20161 introduces `system_views.partition_key_statistics`, a virtual table that allows operators to query partition keys and related SSTable-level metadata for a specific keyspace/table combination without expensive full-table scans. The table exposes each partition key's token value, string representation, an estimated size (in bytes) from SSTable index data, and the number of SSTables containing the key. The table requires both `keyspace_name` and `table_name` in the partition key (range queries across tables are explicitly rejected). A basic documentation section already exists in `virtualtables.adoc` on trunk.

## Discovery Source
- `NEWS.txt` reference: not verified
- `CHANGES.txt` reference: "Add system_views.partition_key_statistics for querying SSTable metadata (CASSANDRA-20161)"
- Related JIRA: CASSANDRA-20161

## Why It Matters
- User-visible effect: Operators can identify which partitions exist in SSTables for a given table, inspect token placement, and estimate partition size without triggering full compaction or repair operations.
- Operational effect: Useful for diagnosing large partition problems, identifying data distribution skew, and verifying that specific keys are present in SSTables. The `key` column supports equality filtering with the `WHERE key = '...'` clause.
- Upgrade or compatibility effect: Additive. New table; not present in Cassandra 5.0. No existing APIs changed.
- Configuration or tooling effect: No configuration required. Only partitioners that support splitting (`supportsSplitting()`) are supported; others produce an `InvalidRequestException`. Reversed queries and range queries without both partition key components are also rejected.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — a section "Virtual table for primary id's" already exists (lines 525–564 on trunk) covering this table with example output and composite key usage; the section title uses an informal name ("primary id's") rather than the actual table name
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/virtual/PartitionKeyStatsTable.java` — full implementation; table name constant `NAME = "partition_key_statistics"`
  - Schema (from Javadoc and code in `PartitionKeyStatsTable.java`):
    - Partition key: `keyspace_name text`, `table_name text` (composite)
    - Clustering: `token_value varint`, `key text`
    - Regular: `size_estimate counter`, `sstables counter`
  - `src/java/org/apache/cassandra/db/virtual/SystemViewsKeyspace.java` — registered as `.add(new PartitionKeyStatsTable(VIRTUAL_VIEWS))`
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/virtual/PartitionKeyStatsTableTest.java`

## What Changed
1. New virtual table `system_views.partition_key_statistics` registered in `SystemViewsKeyspace`.
2. Schema:
   - Composite partition key: `(keyspace_name text, table_name text)`
   - Clustering: `token_value varint` (BigInteger-typed token), `key text` (human-readable partition key string)
   - Regular: `size_estimate counter` (estimated byte size from SSTable position delta), `sstables counter` (number of SSTables containing this key)
3. Query constraints enforced at the virtual table layer:
   - Both `keyspace_name` and `table_name` must be specified (range query without both raises `UNSUPPORTED_RANGE_QUERY_ERROR`)
   - `key` can only be used with `=` (equality); range operators on `key` raise `KEY_ONLY_EQUALS_ERROR`
   - Reversed queries are rejected (`REVERSED_QUERY_ERROR`)
   - Only partitioners that return `true` from `supportsSplitting()` are supported
4. `size_estimate` is calculated as the byte delta between consecutive key positions in the SSTable index; the last key in a file uses `uncompressedLength()` as the upper bound.
5. Composite partition keys are formatted using `:` as separator in the `key` column.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — the existing section (lines 525–564) is present but has the following gaps:
    1. Section title "Virtual table for primary id's" does not use the actual table name `partition_key_statistics`
    2. The section does not describe query constraints (requirement for keyspace+table, equality-only on `key`, no reversed queries, partitioner limitations)
    3. The `size_estimate` semantics (bytes, SSTable position delta) are not explained
    4. The `sstables` column meaning (count of SSTables containing the key) is briefly noted but not fully explained in the context of compaction/merging
    5. Composite key separator syntax (`:`) is mentioned but not explained
- New pages likely needed: None
- Audience home: Operators
- Authored or generated: Authored
- Technical review needed from: Storage / SSTable domain expert

## Proposed Disposition
- `inventory/docs-map.csv` classification: minor-update
- Affected docs: `virtualtables.adoc`
- Recommended owner role: docs-contributor
- Publish blocker: no

## Open Questions
- What exactly does `size_estimate` represent for a key spanning multiple SSTables — is it the sum across all SSTables or the size in a single SSTable? The current code accumulates one `buildRow` per SSTable and merges; the merged result would show the sum via counter semantics.
- Should the doc explain that `size_estimate` may vary significantly before/after compaction since it is based on raw SSTable index position deltas?
- Is `ByteOrderedPartitioner` or `LocalPartitioner` excluded (both have `supportsSplitting() = false`)? Worth noting explicitly in docs.

## Next Research Steps
- Confirm whether `size_estimate` across multiple SSTables sums via the counter merge
- Confirm which common partitioners are excluded by `!supportsSplitting()`
- Update `virtualtables.adoc` to: rename the section header to use the actual table name, add query constraints, explain `size_estimate` semantics, add a note on compaction impact

## Notes
- Commit: `69dc5d05ef` on trunk — "Add system_views.partition_key_statistics for querying SSTable metadata"
- The token stored in `token_value` is a `varint` (mapped from `BigInteger`) representing the raw Murmur3 or other partitioner token.
- `key` for composite partition keys uses `:` as a separator (e.g., `'val1:val2'`), matching nodetool conventions.
- The Javadoc in `PartitionKeyStatsTable.java` shows `size_estimate COUNTER` and `sstables COUNTER` — both use Cassandra's counter type, not integer, which is somewhat non-standard for a virtual table.
- Not present in cassandra-5.0.
