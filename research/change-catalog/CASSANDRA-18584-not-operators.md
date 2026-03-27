# CASSANDRA-18584 NOT operators in WHERE clauses (three-valued logic)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | major-update |

## Summary
CASSANDRA-18584 adds negation operators to CQL `WHERE` clauses: `NOT IN`, `NOT CONTAINS`, and `NOT CONTAINS KEY`. These allow filtering rows where a column value is absent from a list, or where a collection column does not contain a given element or key. The patch also fixes three-valued logic (3VL) handling for `NULL` values in comparisons, ensuring that expressions involving `NULL` operands follow SQL-standard three-valued logic (true, false, or unknown) rather than producing incorrect results.

## Discovery Source
- `CHANGES.txt` reference: "Add support for NOT operators in WHERE clauses. Fixed Three Valued Logic (CASSANDRA-18584)"
- `NEWS.txt` reference: "Add support for NOT operators in WHERE clauses. Fixed Three Valued Logic (CASSANDRA-18584)"
- `doc/modules/cassandra/pages/developing/cql/changes.adoc`: Section 3.4.8 entry "Add support for NOT operator in WHERE clauses ('18584')"
- Related JIRA: none listed
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Developers can use `col NOT IN (...)`, `col NOT IN ?`, `(col1, col2) NOT IN (...)`, `col NOT CONTAINS val`, and `col NOT CONTAINS KEY key` in SELECT, UPDATE, and DELETE WHERE clauses. This eliminates the need to fetch and filter in application code when rows matching an exclusion list are needed.
- Operational effect: NOT IN and NOT CONTAINS operators require ALLOW FILTERING or a suitable index for non-primary-key columns, similar to their positive counterparts. The 3VL fix affects how NULL comparisons behave in existing queries (a potential behavior change for queries involving NULL values).
- Upgrade or compatibility effect: New syntax only; no schema changes. Nodes running pre-6.0 do not recognize `NOT IN` / `NOT CONTAINS` keywords. The 3VL fix changes the behavior of queries comparing nullable columns — this is a correctness fix but may be a subtle breaking change for queries that previously relied on the old (incorrect) behavior.
- Configuration or tooling effect: cqlsh `cql3handling.py` updated to recognize `NOT IN` and `NOT CONTAINS` for syntax highlighting and tab completion. `K_NOT` was already a lexer token; no new lexer additions needed.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/changes.adoc` -- entry in CQL 3.4.8 (already updated)
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- WHERE clause section documents `CONTAINS` and `CONTAINS KEY` (lines ~166-168) but has **no mention of NOT IN, NOT CONTAINS, or NOT CONTAINS KEY** (gap)
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- operator definition updated to include `NOT CONTAINS | NOT CONTAINS KEY` (commit `e0074a31ef`), but the prose description in the WHERE clause section does not explain NOT operators
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- `operator` line updated to include `NOT IN | NOT CONTAINS | NOT CONTAINS KEY` (commit `e0074a31ef`)
  - `doc/cql3/CQL.textile` -- legacy doc updated with NOT IN and NOT CONTAINS KEY grammar (commit `e0074a31ef`); not the primary docs surface for Cassandra 6
- Relevant code paths:
  - `src/antlr/Parser.g` -- new `inOperator` grammar rule (`K_IN | K_NOT K_IN`); `containsOperator` rule extended with `K_NOT K_CONTAINS (K_KEY)?`; `relation` rule updated to dispatch through `inOperator` and `containsOperator` (commit `e0074a31ef`)
  - `src/java/org/apache/cassandra/cql3/Operator.java` -- `NOT_IN(16)`, `NOT_CONTAINS(17)`, `NOT_CONTAINS_KEY(18)` enum values added with full `isSatisfiedBy`, `requiresFilteringOrIndexingFor`, `restrict`, and `negate` implementations (commit `e0074a31ef`)
  - `src/java/org/apache/cassandra/cql3/Relation.java` -- NOT_IN / NOT_CONTAINS routing
  - `src/java/org/apache/cassandra/cql3/restrictions/ClusteringElements.java` -- NOT_IN restriction
  - `src/java/org/apache/cassandra/cql3/restrictions/MergedRestriction.java` -- NOT_IN handling
  - `src/java/org/apache/cassandra/cql3/restrictions/PartitionKeyRestrictions.java` -- NOT_IN
  - `src/java/org/apache/cassandra/cql3/restrictions/SimpleRestriction.java` -- NOT_CONTAINS, NOT_CONTAINS_KEY evaluation
  - `src/java/org/apache/cassandra/db/filter/RowFilter.java` -- row filter updated for NOT operators
- Relevant test paths:
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectMultiColumnRelationTest.java` -- 584-line addition covering NOT IN on multi-column tuples (commit `e0074a31ef`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectSingleColumnRelationTest.java` -- 499-line addition covering NOT IN, NOT CONTAINS, NOT CONTAINS KEY (commit `e0074a31ef`)
  - `test/unit/org/apache/cassandra/cql3/validation/operations/SelectTest.java` -- 312-line addition covering 3VL behavior and NULL comparisons (commit `e0074a31ef`)
  - `test/unit/org/apache/cassandra/index/sai/cql/TokenRangeReadTest.java` -- NOT IN in SAI context (commit `e0074a31ef`)
  - `test/unit/org/apache/cassandra/index/sai/cql/UnindexedExpressionsTest.java` -- NOT IN on unindexed columns (commit `e0074a31ef`)

## What Changed

### New CQL syntax

```cql
-- NOT IN on a single column
SELECT * FROM t WHERE col NOT IN (val1, val2, val3);
SELECT * FROM t WHERE col NOT IN ?;

-- NOT IN on multi-column tuple
SELECT * FROM t WHERE (col1, col2) NOT IN ((a1, a2), (b1, b2));

-- NOT CONTAINS on list/set/map columns
SELECT * FROM t WHERE list_col NOT CONTAINS val ALLOW FILTERING;

-- NOT CONTAINS KEY on map columns
SELECT * FROM t WHERE map_col NOT CONTAINS KEY key ALLOW FILTERING;
```

### New operators
- `NOT_IN(16)`: negation of `IN`; `negate()` returns `IN`
- `NOT_CONTAINS(17)`: negation of `CONTAINS`; `negate()` returns `CONTAINS`
- `NOT_CONTAINS_KEY(18)`: negation of `CONTAINS_KEY`; `negate()` returns `CONTAINS_KEY`

### Three-valued logic (3VL) fix
The patch corrects handling of `NULL` values in `isSatisfiedBy` comparisons. Previously, certain comparisons involving `NULL` operands could return incorrect (non-null) results. After the fix, comparisons where either operand is null return `null` (i.e., unknown) in accordance with SQL three-valued logic. This affects `RowFilter` evaluation for existing queries that involve nullable columns.

### Grammar changes
- `inOperator` rule introduced: `K_IN | K_NOT K_IN`
- `containsOperator` extended: added `K_NOT K_CONTAINS (K_KEY)?` alternative
- All `relation` uses of `K_IN` and `containsOperator` now route through the new grammar rules

### BNF / docs surface updated in commit
- `doc/modules/cassandra/examples/BNF/select_statement.bnf`: operator line now reads `operator::= '=' | '<' | '>' | '<=' | '>=' | '!=' | IN | NOT IN | CONTAINS | NOT CONTAINS | CONTAINS KEY | NOT CONTAINS KEY`
- `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc`: operator definition updated inline (no new prose section)

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- **PRIMARY GAP**: The WHERE clause section (lines ~166-168) explains `CONTAINS` and `CONTAINS KEY` but says nothing about `NOT CONTAINS`, `NOT CONTAINS KEY`, or `NOT IN`. These require a prose paragraph or subsection alongside the existing CONTAINS documentation.
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- BNF operator line is updated, but there is no explanatory prose about the NOT operators or 3VL semantics.
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- already updated by the commit (no gap).
- New pages likely needed: none (prose additions to dml.adoc WHERE clause section are sufficient)
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: Piotr Kolaczkowski (implementer), Benjamin Lerer, Ekaterina Dimitrova (reviewers)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `major-update`
- Recommended owner role: docs-lead or docs-contributor
- Publish blocker: yes — the WHERE clause reference page (dml.adoc) does not document NOT IN, NOT CONTAINS, or NOT CONTAINS KEY

## Open Questions
1. What ALLOW FILTERING requirement applies to `NOT IN` on clustering columns vs. non-primary-key columns? The tests suggest different behavior; this should be verified and documented.
2. Should the 3VL fix (NULL handling) be explicitly documented as a behavior change in upgrade notes, or is it treated as a pure bug fix?
3. Is `NOT IN` supported for partition key columns, or only for clustering columns and non-primary-key columns?
4. Does SAI (Storage Attached Index) support `NOT IN` / `NOT CONTAINS` query push-down, or are these always evaluated as post-scan filters?

## Next Research Steps
- Draft NOT IN / NOT CONTAINS / NOT CONTAINS KEY subsection for dml.adoc WHERE clause
- Verify ALLOW FILTERING requirements for each NOT operator type by examining `requiresFilteringOrIndexingFor` in Operator.java
- Determine if upgrade notes should mention the 3VL NULL behavior fix
- Check if SAI expression handling covers NOT_IN and NOT_CONTAINS

## Notes
- Commit `e0074a31ef` (CASSANDRA-18584, March 2024): single commit containing grammar, operator implementation, 3VL fix, and partial docs update
- The changes.adoc entry says "NOT operator" (singular) but three new operators were added: NOT_IN, NOT_CONTAINS, NOT_CONTAINS_KEY
- The 3VL fix is in `Operator.java` `isSatisfiedBy` methods; it is a correctness fix that changes runtime behavior for NULL comparisons
- `K_NOT` was already a reserved keyword in CQL; the new operators compose it with existing keywords rather than adding new lexer tokens
- The `negate()` method on each operator returns its positive counterpart, enabling query optimization (double-negation elimination)
