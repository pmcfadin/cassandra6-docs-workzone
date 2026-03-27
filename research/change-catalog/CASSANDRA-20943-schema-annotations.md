# CASSANDRA-20943 Schema Comments and Security Labels

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
Cassandra 6 introduces standalone `COMMENT ON` and `SECURITY LABEL ON` CQL statements for attaching metadata to schema elements (keyspaces, tables, columns, user-defined types, and UDT fields). These are new DDL statements separate from the existing `WITH comment = '...'` table property. Security labels provide a classification mechanism (e.g., PII, CONFIDENTIAL) stored in schema metadata and surfaced in `DESCRIBE` output. Both features are guarded by configurable length limits in `cassandra.yaml`. CASSANDRA-21046 adds CQL injection prevention via single-quote escaping in `DESCRIBE` output.

## Discovery Source
- `NEWS.txt` reference: Not listed in NEWS.txt (gap)
- `CHANGES.txt` reference: Line 44: "Introducing comments and security labels for schema elements (CASSANDRA-20943)"
- `CHANGES.txt` reference: Line 26: "Schema annotations escape validation on CREATE and ALTER DDL statements (CASSANDRA-21046)"
- Related JIRA: CASSANDRA-20943 (primary), CASSANDRA-21046 (escape validation)
- Related CEP or design doc: None identified

## Why It Matters
- **User-visible effect:** New CQL statements (`COMMENT ON`, `SECURITY LABEL ON`) that operators and developers can use to annotate schema elements. Comments and security labels appear in `DESCRIBE` output.
- **Operational effect:** Security labels enable data classification workflows (PII tagging, compliance labeling). Labels can be used with custom authorization plugins or audit systems.
- **Upgrade or compatibility effect:** The existing `WITH comment = '...'` table property continues to work. The new `COMMENT ON` statements extend annotation capabilities to keyspaces, columns, UDTs, and UDT fields -- previously only tables had comment support.
- **Configuration or tooling effect:** Two new `cassandra.yaml` guardrails: `max_comment_length` (default: 128) and `max_security_label_length` (default: 48). `DESCRIBE` output includes escape handling for injected single-quotes (CASSANDRA-21046).

## Source Evidence
- Relevant docs paths:
  - `/doc/modules/cassandra/pages/developing/cql/ddl.adoc` lines 807-994 (COMMENT and SECURITY LABEL sections -- already authored)
  - `/doc/modules/cassandra/partials/table-properties.adoc` line 58 (existing `comment` table property)
  - `/doc/modules/cassandra/pages/developing/cql/cql_singlefile.adoc` line 571 (legacy `comment` field reference)
- Relevant config paths:
  - `/conf/cassandra.yaml` lines 2621-2627 (`max_comment_length`, `max_security_label_length`)
  - `/src/java/org/apache/cassandra/config/Config.java` lines 113-114 (defaults)
- Relevant code paths:
  - `/src/java/org/apache/cassandra/cql3/statements/schema/CommentOn{Keyspace,Table,Column,UserType,UserTypeField}Statement.java` (5 statement classes)
  - `/src/java/org/apache/cassandra/cql3/statements/schema/SecurityLabelOn{Keyspace,Table,Column,UserType,UserTypeField}Statement.java` (5 statement classes)
  - `/src/java/org/apache/cassandra/cql3/statements/SchemaDescriptionsUtil.java` (DESCRIBE output with escape handling)
  - `/src/antlr/Parser.g` lines 1291-1367 (CQL grammar rules)
- Relevant test paths: Not searched in detail
- Relevant generated-doc paths: The generated cassandra.yaml reference doc (if regenerated) should pick up the two new config parameters. Currently the generated doc does not exist in the trunk doc tree.

## What Changed

### New CQL Statements
Ten new DDL statement types added to the CQL grammar:

| Statement | Target | Permission Required |
|-----------|--------|-------------------|
| `COMMENT ON KEYSPACE` | Keyspace | ALTER on keyspace |
| `COMMENT ON TABLE` | Table | ALTER on keyspace |
| `COMMENT ON COLUMN` | Column | ALTER on keyspace |
| `COMMENT ON TYPE` | User-defined type | ALTER on keyspace |
| `COMMENT ON FIELD` | UDT field | ALTER on keyspace |
| `SECURITY LABEL ON KEYSPACE` | Keyspace | ALTER on keyspace |
| `SECURITY LABEL ON TABLE` | Table | ALTER on keyspace |
| `SECURITY LABEL ON COLUMN` | Column | ALTER on keyspace |
| `SECURITY LABEL ON TYPE` | User-defined type | ALTER on keyspace |
| `SECURITY LABEL ON FIELD` | UDT field | ALTER on keyspace |

### Setting and Removing Annotations
- Set: `COMMENT ON <element> <name> IS '<text>';`
- Remove: `COMMENT ON <element> <name> IS NULL;`
- Same pattern for `SECURITY LABEL ON`.

### Provider Clause (Undocumented in Docs)
The CQL parser accepts an optional `FOR <provider>` clause on `SECURITY LABEL` statements:
```
SECURITY LABEL [FOR provider_name] ON KEYSPACE keyspace_name IS 'label';
```
Per source code Javadoc: "Provider functionality is not currently implemented. If a provider is specified, a warning will be issued but the security label will still be applied. The provider parameter is reserved for future use."

**The current doc does not mention the `FOR <provider>` clause.** This is intentional omission of unimplemented functionality but should be noted for future tracking.

### Configuration Guardrails
| Parameter | Default | Purpose |
|-----------|---------|---------|
| `max_comment_length` | 128 | Maximum characters for comment text |
| `max_security_label_length` | 48 | Maximum characters for security label text |

### Escape Validation (CASSANDRA-21046)
`SchemaDescriptionsUtil.addDescription()` escapes single quotes in comments and security labels when generating `DESCRIBE` output. This prevents CQL injection when schema is exported from one database and imported into another (e.g., a malicious comment like `'a'; DROP TABLE ...;'` is safely escaped to `'a''; DROP TABLE ...;'''`).

## Docs Impact
- **Existing pages likely affected:**
  - `developing/cql/ddl.adoc` -- already updated with full COMMENT and SECURITY LABEL sections (lines 807-994)
  - `developing/cql/cql_singlefile.adoc` -- the unified CQL reference does NOT yet include the new statements
  - `partials/table-properties.adoc` -- may need a cross-reference to the new standalone COMMENT ON approach
  - Generated cassandra.yaml reference -- needs regeneration to pick up `max_comment_length` and `max_security_label_length`
- **New pages likely needed:** None; the ddl.adoc additions cover the feature
- **Audience home:** Developers (CQL syntax), Operators (security labels, guardrails), Reference (syntax reference)
- **Authored or generated:** The ddl.adoc content is authored. The cassandra.yaml doc is generated
- **Technical review needed from:** Schema/CQL committer familiar with CASSANDRA-20943

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: ddl.adoc; cql_singlefile.adoc; table-properties.adoc; cass_yaml_file.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
1. **Missing from NEWS.txt:** CASSANDRA-20943 is not mentioned in `NEWS.txt`. For a feature introducing 10 new CQL statement types, this seems like an omission. Should a NEWS.txt entry be proposed?
2. **`FOR <provider>` clause:** The parser and source code accept an optional provider parameter on SECURITY LABEL statements. The docs intentionally omit it since the feature is unimplemented. Should the docs mention it as reserved/future syntax?
3. **cql_singlefile.adoc gap:** The unified CQL reference (`cql_singlefile.adoc`) does not include COMMENT ON or SECURITY LABEL ON syntax. This file appears to be a legacy artifact but should be checked for currency requirements.
4. **Relationship to existing table comment property:** The existing `WITH comment = '...'` table property (documented in `table-properties.adoc` and `cql_singlefile.adoc`) coexists with the new `COMMENT ON TABLE`. Are they stored in the same schema field? Does one override the other? The docs should clarify the relationship.
5. **BNF syntax files:** No BNF include files exist for the new statements (unlike `truncate_table.bnf` and others). Should BNF files be created for formal syntax documentation?
6. **Generated cassandra.yaml doc:** The two new config parameters (`max_comment_length`, `max_security_label_length`) need to appear in the generated cassandra.yaml reference. This requires doc regeneration.

## Next Research Steps
- Verify whether `COMMENT ON TABLE` and `WITH comment = '...'` write to the same schema field (check `TableParams` or `TableMetadata`)
- Confirm CASSANDRA-21046 escape validation applies to DDL input (CREATE/ALTER comment text) in addition to DESCRIBE output
- Check whether cqlsh autocomplete supports the new statements
- Compare with cassandra-5.0 to confirm these statements are entirely new
- Regenerate cassandra.yaml reference doc and verify the two guardrail parameters appear
- Identify technical reviewer for the authored ddl.adoc content

## Notes
- The ddl.adoc documentation is already well-structured with clear subsections per schema element type, syntax blocks, and examples. The content appears accurate relative to the source code.
- All ten statement classes require `ALTER` permission on the keyspace, consistent with other DDL operations.
- The escape validation in CASSANDRA-21046 is in the DESCRIBE output path (`SchemaDescriptionsUtil`), not in the DDL input parsing path. The CHANGES.txt description ("escape validation on CREATE and ALTER DDL statements") refers to annotations set via CREATE/ALTER being safely escaped when later output via DESCRIBE.
- Security labels support five target types: keyspace, table, column, UDT, UDT field. The same five targets are supported for comments. This is broader than the pre-existing `WITH comment` property which only applied to tables.
