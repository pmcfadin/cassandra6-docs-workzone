# CASSANDRA-17198 LIKE expressions in filtering queries

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | major-update |

## Summary
CASSANDRA-17198 extends the `LIKE` operator to work in filtering queries with `ALLOW FILTERING`, removing the previous restriction that `LIKE` could only be used on columns with a suitable index (specifically SASI). After this change, `LIKE` queries against text columns are valid with `ALLOW FILTERING` even when no index exists, enabling pattern matching (prefix `foo%`, suffix `%foo`, contains `%foo%`, exact match `foo`) as a post-scan filter. SAI (Storage Attached Index) support for LIKE as an indexed operation was also added in this commit through `Expression.IndexOperator` additions.

## Discovery Source
- `CHANGES.txt` reference: "Support LIKE expressions in filtering queries (CASSANDRA-17198)"
- `NEWS.txt` reference: "Support LIKE expressions in filtering queries (CASSANDRA-17198)"
- Related JIRA: none listed
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: `LIKE` can now be used on any text column with `ALLOW FILTERING`, not just SASI-indexed columns. Error message updated from "only supported on properly indexed columns" to "only supported on properly indexed columns or with ALLOW FILTERING". Four LIKE patterns are supported: `'prefix%'` (prefix), `'%suffix'` (suffix), `'%contains%'` (contains), `'exact'` (matches).
- Operational effect: LIKE with ALLOW FILTERING performs a full-partition scan with in-memory filtering. This has the same performance profile as other ALLOW FILTERING queries — suitable for low-cardinality or testing scenarios, not recommended for production large tables without an index. When an SAI or SASI index is present on the column, LIKE is still served by the index.
- Upgrade or compatibility effect: Queries that previously failed with "only supported on properly indexed columns" will now succeed if `ALLOW FILTERING` is appended. No schema changes required. Existing indexed LIKE queries are unaffected.
- Configuration or tooling effect: None beyond the behavior change. No new keywords, no new grammar rules, no cqlsh changes. The `LIKE` keyword existed before this change.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- **GAP**: The WHERE clause section does not document the `LIKE` operator at all. This is the primary gap — no mention of `LIKE`, its pattern syntax, or when ALLOW FILTERING is required.
  - `doc/modules/cassandra/pages/developing/cql/SASI.adoc` -- SASI documentation page mentions `LIKE` extensively (lines 12, 72, 123, 150, 165, 189, etc.) but contextualizes it as a SASI-specific feature. After CASSANDRA-17198, `LIKE` is also usable without SASI.
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- `LIKE` appears only in the keyword table (line 2889) as a non-reserved keyword; no operator documentation.
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- `operator` line does not include `LIKE` (gap).
  - No docs files were modified in commit `cf806cac1a`.
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/restrictions/SimpleRestriction.java` -- key behavioral change: `allowFiltering` field added to `SimpleRestriction`; LIKE path changed from requiring an index (`getBestIndexFor(...).orElseThrow(...)`) to checking `!index.isPresent() && !allowFiltering` (commit `cf806cac1a`)
  - `src/java/org/apache/cassandra/cql3/restrictions/StatementRestrictions.java` -- `allowFiltering` flag threaded through restriction building (commit `cf806cac1a`)
  - `src/java/org/apache/cassandra/index/sai/plan/Expression.java` -- `IndexOperator` enum extended with `LIKE_PREFIX`, `LIKE_SUFFIX`, `LIKE_MATCHES`, `LIKE_CONTAINS`; `isLikeVariant()` method added; `isEquality()` updated to include like variants; SAI index expression bounds built for LIKE patterns (commit `cf806cac1a`)
  - `src/java/org/apache/cassandra/cql3/Operator.java` -- minor: `isSatisfiedBy` null check fixed for LIKE_PREFIX/SUFFIX/CONTAINS/MATCHES (commit `cf806cac1a`)
  - `src/java/org/apache/cassandra/cql3/Ordering.java` -- minor update (commit `cf806cac1a`)
  - `src/java/org/apache/cassandra/cql3/Relation.java` -- LIKE routing update (commit `cf806cac1a`)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/index/sai/cql/AllowFilteringTest.java` -- 81-line addition with four new test methods: `testAllowFilteringWithLikePrefixPostFiltering`, `testAllowFilteringWithLikeSuffixPostFiltering`, `testAllowFilteringWithLikeContainsPostFiltering`, `testAllowFilteringWithLikeMatchesPostFiltering` (commit `cf806cac1a`)
  - `test/unit/org/apache/cassandra/index/sai/cql/UnindexedExpressionsTest.java` -- LIKE in unindexed scenario (commit `cf806cac1a`)
  - `test/unit/org/apache/cassandra/cql3/validation/entities/SecondaryIndexTest.java` -- LIKE on 2i (updated expectations, commit `cf806cac1a`)
  - `test/unit/org/apache/cassandra/cql3/restrictions/ClusteringColumnRestrictionsTest.java` -- restriction test updates (commit `cf806cac1a`)
  - `test/unit/org/apache/cassandra/index/sasi/SASIIndexTest.java` -- SASI LIKE test updates (commit `cf806cac1a`)

## What Changed

### Behavior change: LIKE with ALLOW FILTERING

Before CASSANDRA-17198:
```
-- Would throw: "... is only supported on properly indexed columns"
SELECT * FROM t WHERE name LIKE 'foo%' ALLOW FILTERING;
```

After CASSANDRA-17198:
```cql
-- Now valid: post-scan filter applied
SELECT * FROM t WHERE name LIKE 'foo%' ALLOW FILTERING;

-- Without ALLOW FILTERING still requires an index
SELECT * FROM t WHERE name LIKE 'foo%';
-- throws: "... is only supported on properly indexed columns or with ALLOW FILTERING"
```

### LIKE pattern variants

| Pattern | Meaning | SAI operator |
|---|---|---|
| `'prefix%'` | starts with | `LIKE_PREFIX` |
| `'%suffix'` | ends with | `LIKE_SUFFIX` |
| `'%contains%'` | substring match | `LIKE_CONTAINS` |
| `'exact'` | exact match (no wildcards) | `LIKE_MATCHES` |

### SAI index support for LIKE
When an SAI index exists on the column and the `LIKE` pattern can be served by the index, the query is pushed down to SAI rather than performing a full scan. The `Expression.IndexOperator` enum now includes `LIKE_PREFIX`, `LIKE_SUFFIX`, `LIKE_MATCHES`, and `LIKE_CONTAINS`. SAI `isLikeVariant()` returns true for all four; they are treated as equality-class operators for index bounds construction.

### Relationship to SASI
SASI (`SASIIndex`) has supported `LIKE` since Cassandra 3.x and continues to support it. CASSANDRA-17198 does not change SASI behavior; it adds non-SASI (including ALLOW FILTERING and SAI) support for `LIKE`.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- **PRIMARY GAP**: The WHERE clause section does not mention `LIKE` at all. Needs a prose entry documenting: the pattern syntax (`%` as wildcard), that LIKE requires ALLOW FILTERING or an index on the column, the four pattern types, and applicable column types (text/ascii/varchar). Should be added near the `CONTAINS` documentation.
  - `doc/modules/cassandra/pages/developing/cql/SASI.adoc` -- Should be updated to clarify that `LIKE` is no longer SASI-only; it now works with ALLOW FILTERING and SAI. Currently the SASI page implies LIKE is a SASI-specific capability.
  - `doc/modules/cassandra/examples/BNF/select_statement.bnf` -- `operator` line should include `LIKE` (currently absent).
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- operator definition should include `LIKE`.
- New pages likely needed: none
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: Pranav Shenoy (implementer), Caleb Rackliffe, David Capwell (reviewers)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `major-update`
- Recommended owner role: docs-lead or docs-contributor
- Publish blocker: yes — no documentation exists for the `LIKE` operator behavior, its patterns, or ALLOW FILTERING semantics

## Open Questions
1. What column types support `LIKE`? The tests use `text`; does it work on `ascii` and `varchar` as well? Are numeric columns excluded?
2. Does SAI serve all four LIKE pattern variants as indexed queries, or only prefix? SASI historically only supported prefix and contains for certain analyzer configurations.
3. Should the SASI page (`SASI.adoc`) be updated to note that LIKE is now available without SASI, or should it remain a SASI-specific doc?
4. Is LIKE case-sensitive? (SASI has case-sensitivity options via `case_sensitive` analyzer option — does filtering-mode LIKE inherit the same behavior?)

## Next Research Steps
- Draft LIKE operator subsection for `dml.adoc` WHERE clause section
- Update `select_statement.bnf` to include `LIKE` in operator alternatives
- Check what SAI analyzer support (if any) is required for SAI-backed LIKE queries
- Determine applicable column types and case-sensitivity behavior

## Notes
- Commit `cf806cac1a` (CASSANDRA-17198, September 2025): single commit, no docs files changed
- The prior error message was: "X is only supported on properly indexed columns"
- The new error message is: "X is only supported on properly indexed columns or with ALLOW FILTERING"
- The change is in `SimpleRestriction.java` at the LIKE case in `addToRowFilter()`
- `LikePattern.parse(buffer)` returns the pattern kind (prefix/suffix/contains/matches) and the processed value without wildcards
- `LIKE` is listed as a non-reserved keyword in `cql_singlefile.adoc` keyword table (line 2889)
- Commit date September 2025 makes this among the later trunk changes in this batch
