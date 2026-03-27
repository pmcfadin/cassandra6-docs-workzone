# CASSANDRA-18112 Manual Secondary Index Selection (Index Hints)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
Cassandra 6 adds CQL-level "index hints" that let users manually control which secondary indexes a `SELECT` query uses. The syntax introduces `WITH included_indexes = {idx1}` and `WITH excluded_indexes = {idx2}` clauses appended to SELECT statements. This allows users to force specific indexes, exclude unwanted ones, or override the query planner's automatic index selection. Documentation already exists in trunk in the DML page and BNF grammar.

## Discovery Source
- `NEWS.txt` reference: Not present in NEWS.txt
- `CHANGES.txt` reference: Line 81 — "Support manual secondary index selection at the CQL level (CASSANDRA-18112)"
- Related JIRA: [CASSANDRA-18112](https://issues.apache.org/jira/browse/CASSANDRA-18112)
- Related CEP or design doc: None (design doc is inline in source at `src/java/org/apache/cassandra/db/filter/IndexHints.md`)

## Why It Matters
- User-visible effect: Users can now explicitly include or exclude secondary indexes in SELECT queries, giving fine-grained control over query execution plans.
- Operational effect: Enables workarounds when the automatic index planner picks a suboptimal index, or when an index "shades" unindexed ALLOW FILTERING behavior (e.g., case-insensitive SAI indexes overriding exact equality).
- Upgrade or compatibility effect: New CQL syntax; queries using the new clauses will not parse on older versions. The feature is additive and backward-compatible for existing queries.
- Configuration or tooling effect: None. No new configuration properties.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` (lines 253-273, "Index hints" section)
  - `doc/modules/cassandra/examples/CQL/query_with_index_hints.cql`
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` (lines 23-26, `select_options` / `select_option` grammar)
  - `doc/cql3/CQL.textile` (lines 1176-1179, BNF for select-options)
- Relevant config paths: None
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/filter/IndexHints.java` — core implementation with validation, serialization, include/exclude logic
  - `src/java/org/apache/cassandra/db/filter/IndexHints.md` — detailed developer design doc with examples and corner cases
  - `src/java/org/apache/cassandra/cql3/statements/SelectOptions.java` — CQL option parsing (`included_indexes`, `excluded_indexes`)
  - `src/antlr/Parser.g` (lines 320, 333, 2182-2183) — grammar rules for `included_indexes` / `excluded_indexes` keywords
  - `src/java/org/apache/cassandra/cql3/restrictions/IndexRestrictions.java`
  - `src/java/org/apache/cassandra/index/SecondaryIndexManager.java`
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/filter/IndexHintsTest.java`
  - `test/distributed/org/apache/cassandra/distributed/test/sai/IndexHintsDistributedTest.java`
- Relevant generated-doc paths: None (this is authored content)

## What Changed
1. **New CQL syntax** — SELECT statements accept an optional `WITH` clause after `ALLOW FILTERING`:
   ```
   SELECT ... FROM ... WHERE ...
   [ALLOW FILTERING]
   WITH included_indexes = {idx1, idx2} AND excluded_indexes = {idx3};
   ```
2. **Included indexes** — Forces the query to use the specified indexes. The query fails if any included index cannot be used (no matching restriction, incompatible restriction, or index implementation limitation).
3. **Excluded indexes** — Prevents the query from using specified indexes. Never causes query failure on its own (unless the index doesn't exist), but may require `ALLOW FILTERING`.
4. **Validation rules** — Referenced indexes must exist. An index cannot be both included and excluded. Non-existent index names cause the query to fail.
5. **Use cases documented in source** — (a) Unshading queries where an index overrides ALLOW FILTERING behavior (e.g., case-insensitive SAI), and (b) choosing between multiple index implementations on the same column (e.g., legacy vs SAI).

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` — **Already updated** with "Index hints" section (lines 253-273)
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` — **Already updated** with select_options grammar
  - `doc/modules/cassandra/examples/CQL/query_with_index_hints.cql` — **Already added** with working example
  - `doc/cql3/CQL.textile` — **Already updated** with BNF
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/sai-read-write-paths.adoc` — Could reference index hints in the "Index selection and Coordinator processing" section, but currently does not
- New pages likely needed: None
- Audience home: Developers (CQL users)
- Authored or generated: Authored
- Technical review needed from: Caleb Rackliffe (assignee), Andres de la Pena (design contributor)

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: dml.adoc; select_statement.bnf; sai-read-write-paths.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- The SAI read-write-paths page (`sai-read-write-paths.adoc`) discusses "Index selection and Coordinator processing" but does not mention index hints. Should it cross-reference the new feature?
- The dml.adoc "Index hints" section is functional but brief (lines 253-273). Consider whether the advanced use cases documented in `IndexHints.md` (unshading queries, choosing between implementations) merit inclusion in the user-facing docs.
- The feature is absent from `NEWS.txt`. Should it be added for the 6.0 release notes?

## Next Research Steps
- Review whether the SAI read-write-paths page should cross-reference index hints
- Evaluate if the dml.adoc section needs expansion to cover the unshading and multi-implementation use cases from `IndexHints.md`
- Confirm whether NEWS.txt omission is intentional or an oversight

## Notes
- The in-source design doc at `src/java/org/apache/cassandra/db/filter/IndexHints.md` is thorough and covers corner cases (unshading, multi-implementation selection) that the user-facing docs do not yet address.
- The CQL grammar uses `select_options` as an extensible mechanism — `included_indexes` and `excluded_indexes` are the first two options in this framework, suggesting future SELECT options could reuse the same `WITH` clause pattern.
- Fix versions: 6.0-alpha1, 6.0. Status: Resolved/Fixed.
