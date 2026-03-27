# CASSANDRA-19964 CREATE TABLE LIKE (CEP-43)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | major-update |

## Summary
CEP-43 introduces `CREATE TABLE LIKE`, a new CQL statement that creates a new empty table by copying the schema definition of an existing table. The new table can be in the same or a different keyspace. Users can override table options at copy time using `WITH`, and optionally copy indexes (`WITH INDEXES`), comments (`WITH COMMENTS`), and security labels (`WITH SECURITY_LABELS`). The new table contains no data. Dropped columns, triggers, and materialized views are intentionally excluded from the copy.

## Discovery Source
- `NEWS.txt` reference: "CEP-43 - it is possible to create a table by 'copying' as `CREATE TABLE ks.tb_copy LIKE ks.tb;`. A newly created table will have no data."
- `CHANGES.txt` references:
  - "Implementation of CEP-43 - copying a table via CQL by CREATE TABLE LIKE (CASSANDRA-19964)"
  - "Support CREATE TABLE LIKE WITH INDEXES (CASSANDRA-19965)"
  - "Add missed documentation for CREATE TABLE LIKE (CASSANDRA-20401)"
- Related JIRA: CASSANDRA-19965 (WITH INDEXES support), CASSANDRA-20401 (missed documentation)
- Related CEP or design doc: CEP-43
- Parent JIRA: CASSANDRA-7662 (Implement templated CREATE TABLE functionality)

## Why It Matters
- User-visible effect: New CQL statement for cloning table schemas. Reduces manual effort when creating tables with identical or near-identical schemas.
- Operational effect: Cross-keyspace table copying requires matching UDTs in the target keyspace. Guardrails (columns per table, table count, vector dimensions, compact tables) are enforced on the new table.
- Upgrade or compatibility effect: Statement requires cluster metadata serialization version V5+. Only available in Cassandra 6.0+.
- Configuration or tooling effect: cqlsh tab-completion updated for new keywords. Audit logging emits `CREATE_TABLE_LIKE` entry type.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/ddl.adoc` -- has CREATE TABLE section but NO CREATE TABLE LIKE section (gap)
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- has CREATE TABLE LIKE documentation (added via CASSANDRA-20401)
  - `doc/modules/cassandra/examples/BNF/create_table_like.bnf` -- BNF grammar for the statement
  - `doc/modules/cassandra/examples/CQL/create_table_like.cql` -- CQL examples
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/statements/schema/CopyTableStatement.java` -- main implementation
  - `src/antlr/Parser.g` -- CQL grammar definition (lines 1057-1077)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/schema/createlike/CreateLikeCqlParseTest.java`
  - `test/unit/org/apache/cassandra/schema/createlike/CreateLikeTest.java`
  - `test/unit/org/apache/cassandra/schema/createlike/CreateLikeWithSessionTest.java`

## What Changed

### New CQL syntax

```
CREATE TABLE [IF NOT EXISTS] <new_table> LIKE <old_table>
  [WITH <like_options>]
```

Where `like_options` can include:
- `INDEXES` -- copies SAI and legacy secondary indexes (not custom indexes); renames indexes to avoid conflicts
- `COMMENTS` -- copies table and column comments from the source
- `SECURITY_LABELS` -- copies table and column security labels from the source
- Standard table property overrides (e.g., `compaction`, `compression`, `cdc`, `ID`, etc.)

Options can be combined with `AND`, e.g.: `WITH INDEXES AND compaction = { ... }`

### What is copied
- Column definitions (primary key, clustering, regular, static)
- Data types including UDTs
- Data masking settings
- Table parameters (compaction, compression, etc.) -- overridable via WITH

### What is NOT copied
- Data (table is always empty)
- Dropped column metadata
- Triggers
- Materialized views
- Custom indexes (only SAI and legacy 2i are copied; custom indexes produce a client warning)

### Cross-keyspace behavior
- Source and target can be in different keyspaces
- All referenced UDTs must exist in the target keyspace with matching structure
- Missing or mismatched UDTs cause an error

### Permissions required
- `SELECT` on source table
- `CREATE` on target keyspace (all tables)

### Guardrails enforced
- Columns per table
- Total table count
- Vector type and dimensions
- Compact table creation
- Uncompressed tables
- Table properties

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/ddl.adoc` -- **PRIMARY GAP**: needs a new "CREATE TABLE LIKE" subsection after the existing "CREATE TABLE" section, consistent with how ALTER TABLE and DROP TABLE are documented
  - `doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` -- already updated (CASSANDRA-20401), but BNF is slightly incomplete (missing COMMENTS and SECURITY_LABELS options in the BNF file)
- New pages likely needed: none (subsection in ddl.adoc is sufficient)
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: Maxwell Guo (implementer), Benjamin Lerer or Stefan Miklosovic (reviewers)

## Assessment of CASSANDRA-20401 (Missed Documentation)
CASSANDRA-20401 was resolved and committed (`3fb88e0f9d`). It added CREATE TABLE LIKE documentation to `cql_singlefile.adoc` with BNF grammar and examples. However:

1. **ddl.adoc remains undocumented** -- The main DDL reference page (`ddl.adoc`) that developers use for CREATE TABLE, ALTER TABLE, etc. has no mention of CREATE TABLE LIKE. This is the most significant documentation gap.
2. **BNF file is incomplete** -- `create_table_like.bnf` shows `like_options::= INDEXES | options` but the actual parser also supports `COMMENTS` and `SECURITY_LABELS` (added later via CASSANDRA-20943). The BNF should be updated to reflect all valid like options.
3. **Minor typo in cql_singlefile.adoc** -- Line 780 reads "Indexs will be created" (should be "Indexes").

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: ddl.adoc; cql_singlefile.adoc; create_table_like.bnf
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
1. Should `ddl.adoc` get a full "== CREATE TABLE LIKE" H2 section or a "=== CREATE TABLE LIKE" H3 subsection under CREATE TABLE?
2. The BNF does not list COMMENTS or SECURITY_LABELS -- is this an intentional omission (because those features came from a separate JIRA, CASSANDRA-20943) or a documentation bug that should be filed?
3. Is there a need to document the index renaming strategy (system-generated names vs. user-defined names) in the DDL docs?
4. Should cross-keyspace UDT requirements be highlighted in the docs, or is the error message sufficient?

## Next Research Steps
- Draft the CREATE TABLE LIKE section for ddl.adoc
- File or confirm a JIRA for the BNF update to include COMMENTS and SECURITY_LABELS
- Fix the "Indexs" typo in cql_singlefile.adoc
- Validate examples against a running trunk build

## Notes
- The implementation class is named `CopyTableStatement`, not `CreateTableLikeStatement`. The CQL syntax uses `LIKE` but the internal class uses "Copy" terminology.
- Audit logging uses `AuditLogEntryType.CREATE_TABLE_LIKE`.
- The feature uses deep-copy semantics: it parses the source table's CQL representation and re-creates a fresh `TableMetadata`, ensuring no shared references between source and target.
- The `WITH COMMENTS` and `WITH SECURITY_LABELS` options were added later by CASSANDRA-20943, which introduced schema annotations. These are not reflected in the existing BNF or cql_singlefile documentation.
