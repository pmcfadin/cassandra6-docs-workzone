# CASSANDRA-19604 + CASSANDRA-19688 BETWEEN operator in WHERE clauses with SAI support

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | major-update |

## Summary
CASSANDRA-19604 introduces the `BETWEEN` operator for use in CQL `WHERE` clauses, allowing range queries to be expressed as `column BETWEEN val1 AND val2` instead of requiring two separate comparisons (`column >= val1 AND column <= val2`). The operator works on single columns, multi-column tuple notation, and the `TOKEN` function. CASSANDRA-19688 extends this by adding native SAI (Storage Attached Index) support for BETWEEN, enabling BETWEEN queries to be pushed down into SAI index scans rather than relying solely on row filtering.

## Discovery Source
- `CHANGES.txt` reference: "Add support for the BETWEEN operator in WHERE clauses (CASSANDRA-19604)"
- `CHANGES.txt` reference: "SAI support for BETWEEN operator (CASSANDRA-19688)"
- `NEWS.txt` reference: "Add support for the BETWEEN operator in WHERE clauses (CASSANDRA-19604)" and "SAI support for BETWEEN operator (CASSANDRA-19688)"
- `doc/modules/cassandra/pages/developing/cql/changes.adoc`: Section 3.4.8 entry "Add support for the BETWEEN operator in WHERE clauses (`19604`)"
- Related JIRA: none listed
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Developers can use `col BETWEEN x AND y` as a more readable equivalent to `col >= x AND col <= y`. Supports single-column, multi-column tuple, and TOKEN BETWEEN. Works with clustering columns directly (no ALLOW FILTERING needed for clustering restrictions) and with non-primary-key columns via ALLOW FILTERING or SAI index.
- Operational effect: SAI indexes on numeric/comparable columns can serve BETWEEN queries natively (CASSANDRA-19688), reducing read amplification compared to post-scan filtering. BETWEEN on non-indexed, non-primary-key columns still requires ALLOW FILTERING.
- Upgrade or compatibility effect: New syntax only; no schema changes. Queries using BETWEEN will fail on older Cassandra nodes (pre-6.0) that do not recognize the keyword.
- Configuration or tooling effect: cqlsh tab-completion updated to recognize `BETWEEN` keyword (added to `pylib/cqlshlib/cql3handling.py`). `K_BETWEEN` added to `src/antlr/Lexer.g` as a lexer token; marked as basic_unreserved_keyword so `between` can still be used as a column name.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/changes.adoc` -- BETWEEN listed as CQL 3.4.8 change
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- WHERE clause section exists but has **no mention of BETWEEN** (gap)
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- no BETWEEN documentation (gap)
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- operator list does not include BETWEEN (gap)
- Relevant code paths:
  - `src/antlr/Lexer.g` -- `K_BETWEEN: B E T W E E N;` token definition
  - `src/antlr/Parser.g` -- `singleColumnBetweenValues`, `betweenLiterals` grammar rules; BETWEEN added to `relation` rule for single-column, TOKEN, and multi-column tuple cases; `K_BETWEEN` added to `basic_unreserved_keyword` (commit `53fabf1f02`)
  - `src/java/org/apache/cassandra/cql3/Operator.java` -- `BETWEEN(19)` enum value added with full implementation (commit `53fabf1f02`)
  - `src/java/org/apache/cassandra/cql3/Relation.java` -- `singleColumn` and `token` factory calls with `Operator.BETWEEN`
  - `src/java/org/apache/cassandra/cql3/restrictions/ClusteringElements.java` -- BETWEEN range restriction support
  - `src/java/org/apache/cassandra/cql3/restrictions/SimpleRestriction.java` -- BETWEEN evaluation
  - `src/java/org/apache/cassandra/cql3/terms/Terms.java` -- `Terms.Raw.of(list)` used to bundle lower/upper bounds
  - `src/java/org/apache/cassandra/db/filter/RowFilter.java` -- BETWEEN added to row filter evaluation (both commits)
  - `src/java/org/apache/cassandra/index/sai/plan/Expression.java` -- SAI `IndexOperator` extended to handle BETWEEN via RANGE evaluation (commit `bddaa4409f`)
  - `src/java/org/apache/cassandra/index/sai/plan/StorageAttachedIndexQueryPlan.java` -- BETWEEN passed to SAI query planner (commit `53fabf1f02`, refined in `bddaa4409f`)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/cql3/restrictions/ClusteringElementsTest.java` -- BETWEEN restriction tests (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectMultiColumnRelationTest.java` -- 250-line addition (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectSingleColumnRelationTest.java` -- BETWEEN query tests (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectOrderedPartitionerTest.java` -- TOKEN BETWEEN tests (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/DeleteTest.java` -- BETWEEN in DELETE (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/UpdateTest.java` -- BETWEEN in UPDATE (commit `53fabf1f02`)
  - `test/unit/org/apache/cassandra/index/sai/cql/DescClusteringRangeQueryTest.java` -- SAI BETWEEN tests (commit `bddaa4409f`)
  - `test/unit/org/apache/cassandra/index/sai/cql/IndexQuerySupport.java` -- SAI BETWEEN in query support (commit `bddaa4409f`)
  - `test/distributed/org/apache/cassandra/distributed/test/BetweenInversionTest.java` -- distributed BETWEEN tests

## What Changed

### New CQL syntax

```cql
-- Single-column BETWEEN on clustering or non-primary-key column
SELECT * FROM t WHERE col BETWEEN val1 AND val2;

-- Multi-column tuple BETWEEN on clustering columns
SELECT * FROM t WHERE (col1, col2) BETWEEN (low1, low2) AND (high1, high2);

-- TOKEN BETWEEN for partition key range scans
SELECT * FROM t WHERE TOKEN(pk) BETWEEN TOKEN(low) AND TOKEN(high);

-- BETWEEN also valid in UPDATE and DELETE WHERE clauses
DELETE FROM t WHERE pk = x AND ck BETWEEN val1 AND val2;
```

### Semantics
- `col BETWEEN x AND y` is inclusive on both ends: equivalent to `col >= x AND col <= y`
- Lower bound must be less than or equal to upper bound (invalid request if violated)
- Works on clustering columns (no ALLOW FILTERING needed), regular columns (needs ALLOW FILTERING or SAI index), and TOKEN

### SAI index support (CASSANDRA-19688)
- SAI indexes serve BETWEEN as a range query natively using the `RANGE` index operator path
- BETWEEN queries on SAI-indexed columns are pushed down to the index; unindexed non-PK columns still need ALLOW FILTERING
- Adds `LIKE_PREFIX`, `LIKE_SUFFIX`, `LIKE_MATCHES`, `LIKE_CONTAINS` to `Expression.IndexOperator` (combined in that commit for SAI expression infrastructure)

### Grammar changes
- `K_BETWEEN` added to Lexer as unreserved keyword
- `singleColumnBetweenValues` and `betweenLiterals` parser rules added
- `relation` rule extended with three BETWEEN forms: single-column, TOKEN, and multi-column tuple

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- **PRIMARY GAP**: WHERE clause section documents `IN`, `CONTAINS`, `CONTAINS KEY`, and tuple notation but has zero mention of BETWEEN. Needs a new paragraph or subsection documenting the BETWEEN operator syntax, semantics, and when ALLOW FILTERING is required.
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- `operator` line does not include BETWEEN; needs update.
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- BNF operator definition in the SELECT section is similarly missing BETWEEN.
  - `doc/modules/cassandra/pages/developing/cql/changes.adoc` -- already updated (no gap).
- New pages likely needed: none (subsection in dml.adoc is sufficient)
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: Simon Chess (implementer), Arun Ganesh / Caleb Rackliffe (SAI implementers), Benjamin Lerer (reviewer)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `major-update`
- Recommended owner role: docs-lead or docs-contributor
- Publish blocker: yes — dml.adoc WHERE section is the primary reference for query syntax; omission of BETWEEN is a meaningful gap

## Open Questions
1. Should BETWEEN appear in the `select_statement.bnf` operator line, or does it need a separate grammar alternative alongside the `relation` rule?
2. Is BETWEEN supported in the WHERE clause of `UPDATE` and `DELETE` (tests suggest yes for clustering columns) — does dml.adoc's UPDATE and DELETE sections also need updating?
3. Does the SAI index documentation (`doc/modules/cassandra/pages/developing/cql/indexes.adoc` or SAI-specific pages) need a note that SAI supports BETWEEN natively?

## Next Research Steps
- Draft BETWEEN subsection for `dml.adoc` WHERE clause section
- Update `select_statement.bnf` to include BETWEEN in the operator alternatives
- Confirm behavior when lower bound > upper bound (verify error message text)
- Verify cqlsh tab-completion works for BETWEEN syntax (pylib change is present)

## Notes
- Commit `53fabf1f02` (CASSANDRA-19604, May 2024): core BETWEEN operator, grammar, parser, operator evaluation
- Commit `bddaa4409f` (CASSANDRA-19688, September 2024): SAI index support for BETWEEN
- `K_BETWEEN` is listed as `basic_unreserved_keyword`, meaning `between` can be used as a column or table name without quoting
- BETWEEN is not a new concept in SQL; the Cassandra version is inclusive-inclusive, matching standard SQL BETWEEN semantics
- The `Operator.BETWEEN` enum value is `19` in the current Operator.java on trunk
