# Developing/CQL Delta

## Scope
- Area: developing/cql
- Branches compared: origin/cassandra-5.0 .. origin/trunk
- Subagent: developing-cql
- Status: complete

## Inventory Summary
- Pages in 5.0: 65
- Pages in trunk: 66
- New in trunk: 1 (constraints.adoc)
- Removed from 5.0: 0
- Generated surfaces: None identified. cql_singlefile.adoc is a monolithic CQL reference (authored, not auto-generated) that mirrors content in other per-topic pages.

## Key Differences

1. **New CQL feature: Constraints** -- A brand-new 373-line page (`constraints.adoc`) documents column-level CHECK constraints (CREATE, ALTER, DROP), pluggable constraint providers, and built-in constraint types (NOT NULL, NOT EMPTY, LENGTH, BETWEEN, LIKE, NOT NAN, NOT INFINITY, ENUM, REGEX, JSON). This is a significant new Cassandra 6 feature.

2. **DDL: COMMENT and SECURITY LABEL statements** -- `ddl.adoc` gains 189 lines documenting two new DDL statement families: `COMMENT ON` (keyspace/table/column/type/field) and `SECURITY LABEL ON` (same targets). Both allow metadata annotation and `NULL` removal.

3. **Functions overhaul** -- `functions.adoc` gains ~320 net lines:
   - WRITETIME/MAXWRITETIME/TTL section moved here from `dml.adoc`, expanded with new `MINWRITETIME` function.
   - New `octet_length` and `length` functions documented.
   - New human helper functions: `format_bytes` and `format_time` with extensive examples.
   - Numerous `[source,cql]` changed to `[source,sql]` throughout.
   - Minor editorial/grammar fixes.

4. **DML updates** -- `dml.adoc` has ~83 lines of changes:
   - WRITETIME/MAXWRITETIME/TTL section removed (moved to functions.adoc) and replaced with a cross-reference; `MINWRITETIME` added to the list.
   - New "Index hints" section documenting included/excluded index sets in SELECT.
   - `update-parameters` anchor renamed to `upsert-parameters`; section renamed to "Insert and Update parameters".
   - Cross-reference fixes (JSON support link, counters link).
   - Various grammar/typo fixes.

5. **Security: Database Identities and LIST SUPERUSERS** -- `security.adoc` gains ~69 lines:
   - New `LIST SUPERUSERS` statement.
   - New "Database Identities" subsection with `ADD IDENTITY` and `DROP IDENTITY` statements (with IF NOT EXISTS / IF EXISTS support).
   - Cross-reference updates pointing to relocated authorization/caching docs.

6. **CQL version bump (changes.adoc)** -- New CQL 3.4.8 section listing BETWEEN operator, GENERATED PASSWORD clause, and NOT operator support.

7. **cql_singlefile.adoc major refactor** -- Reduced from 4193 to 2982 lines (net -1211 lines). The changes are almost entirely mechanical: replacing inline BNF/CQL snippets with `include::` directives to shared example files, plus the same editorial fixes (case-insensitive hyphenation, grammar, typo corrections) applied to the per-topic pages. No new conceptual content unique to this file.

8. **definitions.adoc** -- ~26 lines of editorial improvements: BNF notation clarification, grammar fixes ("case insensitive" to "case-insensitive", "same than" to "same as"), AsciiDoc escaping fixes for `$$` and `/* */`, added `[[prepared-statements]]` anchor, reworded prepared statements closing paragraph.

9. **types.adoc** -- Added two anchors: `[[native-types]]` and `[[collections]]` (cross-reference targets used by functions.adoc).

10. **triggers.adoc** -- Added 4-line paragraph documenting `triggers_policy` configuration (enabled/disabled/forbidden).

11. **index.adoc** -- Added xref to new constraints.adoc page.

12. **SAI monitoring.adoc** -- Virtual table names renamed: `system_views.indexes` to `system_views.sai_column_indexes`, `system_views.sstable_indexes` to `system_views.sai_sstable_indexes`, `system_views.sstable_index_segments` to `system_views.sai_sstable_index_segments`.

13. **developing/index.adoc** -- Added xref to new `developing/accord/index.adoc` (Accord).

## Page-Level Findings

| Page | Status | Notes |
|------|--------|-------|
| changes.adoc | minor-update | Added CQL 3.4.8 section (3 items) |
| constraints.adoc | new | 373 lines, comprehensive new feature doc |
| cql_singlefile.adoc | major-update | Massive refactor replacing inline snippets with includes; editorial fixes; net -1211 lines |
| ddl.adoc | major-update | +189 lines: COMMENT and SECURITY LABEL statements |
| definitions.adoc | minor-update | Grammar, escaping, and anchor fixes |
| dml.adoc | major-update | Index hints, WRITETIME moved out, anchor renames, cross-ref fixes |
| functions.adoc | major-update | +324 lines: length functions, human helpers, MINWRITETIME, WRITETIME section relocated here |
| index.adoc | minor-update | Added constraints xref |
| indexing/sai/operations/monitoring.adoc | minor-update | Renamed 3 virtual table names |
| security.adoc | major-update | +69 lines: LIST SUPERUSERS, Database Identities (ADD/DROP IDENTITY) |
| triggers.adoc | minor-update | Added triggers_policy paragraph |
| types.adoc | minor-update | Added 2 cross-reference anchors |
| developing/index.adoc | minor-update | Added Accord xref |
| All other pages (53) | unchanged | No diff between branches |

## Apparent Coverage Gaps

1. **Constraints documentation completeness** -- The constraints.adoc is substantial but could benefit from: (a) more detail on error handling when constraints are violated, (b) interaction with batch statements, (c) performance implications. The page references pluggable constraint providers but does not detail how to implement custom ones beyond pointing to a Java interface.

2. **BETWEEN operator** -- Listed in changes.adoc (CQL 3.4.8) but not explicitly documented in dml.adoc or operators.adoc. The operators.adoc page has no diff between branches, suggesting the BETWEEN operator documentation may be missing from the per-topic pages.

3. **NOT operator** -- Listed in changes.adoc (CQL 3.4.8) but no corresponding documentation found in dml.adoc WHERE clause section or operators.adoc.

4. **GENERATED PASSWORD** -- Listed in changes.adoc (CQL 3.4.8) but not documented in security.adoc. The security.adoc changes focus on identities and LIST SUPERUSERS but do not cover generated passwords.

5. **Accord** -- developing/index.adoc adds an xref to `developing/accord/index.adoc` but this is outside the CQL scope path. Should be verified separately.

6. **triggers_policy** -- The new triggers.adoc paragraph mentions the policy but does not specify where it is configured (cassandra.yaml? system property?), making it incomplete.

7. **cql_singlefile.adoc vs per-topic pages** -- After the refactor, cql_singlefile.adoc still exists as a parallel monolithic reference. It is unclear whether it is kept intentionally or should eventually be deprecated. Content drift between it and the per-topic pages is a maintenance risk.

8. **Security cross-references** -- security.adoc now points to `managing/operating/authorization/security.adoc` and `managing/operating/security.adoc` for authorization and auth-caching details. These target pages should be verified to exist on trunk.

## Generated-Doc Notes

No generated documentation surfaces were identified in this scope. All pages are authored content. The cql_singlefile.adoc is a monolithic authored reference (not auto-generated), though it includes content from shared BNF/CQL example files via AsciiDoc `include::` directives.

## Recommended Follow-Up

1. **Document BETWEEN operator** in operators.adoc and/or dml.adoc WHERE clause section.
2. **Document NOT operator** in operators.adoc and/or dml.adoc WHERE clause section.
3. **Document GENERATED PASSWORD** in security.adoc (CREATE/ALTER ROLE context).
4. **Clarify triggers_policy configuration** -- specify where and how to set it.
5. **Verify cross-reference targets** -- confirm that `managing/operating/authorization/security.adoc` and `managing/operating/security.adoc` exist on trunk.
6. **Decide fate of cql_singlefile.adoc** -- determine whether it should be maintained alongside per-topic pages or deprecated.
7. **Review constraints.adoc** for completeness around error behavior and custom provider implementation.

## Notes

- The total page count (65 on 5.0, 66 on trunk) includes partial/fragment pages prefixed with `_` (used as AsciiDoc includes in the SAI and 2i indexing sections). These are not standalone pages but included fragments.
- The `[source,cql]` to `[source,sql]` change in functions.adoc is systematic and appears intentional for syntax highlighting compatibility.
- The anchor rename from `update-parameters` to `upsert-parameters` in dml.adoc may break external links or cross-references from other documentation sets.
