# CASSANDRA-19947 CEP-42 Constraints Framework

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
CEP-42 introduces a table-level constraints framework for Apache Cassandra, enabling column-level data validation at write time. The framework provides six built-in constraint types (SCALAR, LENGTH, OCTET_LENGTH, NOT_NULL, JSON, REGEXP) and a pluggable SPI for custom constraints. Constraints are defined using `CHECK` syntax in `CREATE TABLE` and `ALTER TABLE` statements, enforced on every write operation.

## Discovery Source
- `NEWS.txt` reference: "CEP-42 Constraints Framework provides flexibility to Cassandra users and operators by providing a set of usable constraints at table level"
- `CHANGES.txt` references:
  - "CEP-42 - Add Constraints Framework (CASSANDRA-19947)"
  - "Implement NOT_NULL constraint (CASSANDRA-20276)"
  - "Add JSON constraint (CASSANDRA-20273)"
  - "Add regular expression constraint (CASSANDRA-20275)"
  - "Add OCTET_LENGTH constraint (CASSANDRA-20340)"
  - "Add support for time, date, timestamp types in scalar constraint (CASSANDRA-20274)"
  - "Allow custom constraints to be loaded via SPI (CASSANDRA-20824)"
  - "Rewrite constraint framework to remove column specification from constraint definition, introduce SQL-like NOT NULL (CASSANDRA-20563)"
  - "Various fixes in constraint framework (CASSANDRA-20481)"
  - "Prevent invalid constraint combinations (CASSANDRA-20330)"
  - "Improve error messages for constraints (CASSANDRA-20266)"
  - "Improve constraints autocompletion (CASSANDRA-20341)"
- Related JIRAs: CASSANDRA-19947 (primary), CASSANDRA-20276, CASSANDRA-20273, CASSANDRA-20275, CASSANDRA-20340, CASSANDRA-20274, CASSANDRA-20824, CASSANDRA-20563, CASSANDRA-20481, CASSANDRA-20330, CASSANDRA-20266, CASSANDRA-20341
- Related CEP: CEP-42

## Why It Matters
- User-visible effect: New CQL syntax (`CHECK`, `DROP CHECK`) for defining column constraints in DDL. Write operations that violate constraints are rejected with descriptive error messages. Developers can enforce data quality rules directly in schema without application-level validation.
- Operational effect: Constraints are enforced at write time on every node, adding validation overhead. Custom constraints via SPI JARs must be present on all nodes or they will fail to start.
- Upgrade or compatibility effect: New feature, no backward compatibility concerns for existing tables. Tables created with constraints on Cassandra 6 cannot be used on earlier versions.
- Configuration or tooling effect: No cassandra.yaml configuration required. Custom constraints are loaded via Java SPI (ServiceLoader) -- JARs placed on classpath with META-INF/services registration.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/constraints.adoc` (comprehensive, authored page -- exists on trunk)
  - `doc/modules/cassandra/pages/developing/cql/index.adoc` (contains link to constraints.adoc)
- Relevant config paths:
  - No cassandra.yaml settings for constraints (none found)
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/constraints/` (19 Java files)
    - `ConstraintResolver.java` -- resolves built-in and custom constraints
    - `ConstraintProvider.java` -- SPI interface for custom constraints
    - `ScalarColumnConstraint.java` -- numeric/temporal comparisons
    - `LengthConstraint.java` -- text/binary LENGTH check
    - `OctetLengthConstraint.java` -- byte-size check
    - `NotNullConstraint.java` -- non-null enforcement
    - `JsonConstraint.java` -- valid JSON check
    - `RegexpConstraint.java` -- regex matching
    - `ColumnConstraints.java` -- constraint container per column
    - `SatisfiabilityChecker.java` -- validates constraint definitions are satisfiable
  - `src/antlr/Parser.g` -- CQL grammar rules for `columnConstraints`, `columnConstraint`, `columnConstraintsArguments`
  - `examples/constraints/` -- full example of custom SPI constraint implementation
- Relevant test paths: (not enumerated, likely under `test/unit/org/apache/cassandra/cql3/constraints/`)

## What Changed

### CQL Syntax Additions
1. **CREATE TABLE with CHECK**: `column_name type CHECK condition [AND condition]*`
2. **ALTER TABLE with CHECK**: `ALTER TABLE t ALTER col CHECK condition [AND condition]*`
3. **DROP CHECK**: `ALTER TABLE t ALTER col DROP CHECK`
4. **NOT NULL shorthand**: `column_name type NOT NULL` (syntactic sugar, stored internally as CHECK NOT NULL)
5. **ADD COLUMN with CHECK**: Constraints can be specified when adding columns via ALTER TABLE

### Built-in Constraint Types (6 total)

| Constraint | JIRA | Category | Syntax Example | Applicable Types |
|---|---|---|---|---|
| **SCALAR** | CASSANDRA-20274 | Function (binary) | `CHECK col > 100 AND col < 1000` | byte, short, int, long, float, double, decimal, counter, varint, time, date, timestamp |
| **LENGTH** | CASSANDRA-19947 | Function (binary) | `CHECK LENGTH() < 256` | text, varchar, ascii, blob |
| **OCTET_LENGTH** | CASSANDRA-20340 | Function (binary) | `CHECK OCTET_LENGTH() < 2` | text, varchar, ascii, blob |
| **NOT_NULL** | CASSANDRA-20276 | Unary | `CHECK NOT NULL` or `NOT NULL` | all non-primary-key columns |
| **JSON** | CASSANDRA-20273 | Unary | `CHECK JSON()` | text, varchar, ascii |
| **REGEXP** | CASSANDRA-20275 | Function (binary) | `CHECK REGEXP() = 'pattern'` | text, varchar, ascii |

### Custom Constraints via SPI (CASSANDRA-20824)
- Implement `ConstraintProvider` interface
- Register via `META-INF/services/org.apache.cassandra.cql3.constraints.ConstraintProvider`
- Place JAR on Cassandra classpath
- Custom constraints resolved first, built-in ones as fallback
- Only one `ConstraintProvider` loaded via ServiceLoader
- Node fails to start if expected SPI JAR is missing (safety measure)
- Example implementation provided in `examples/constraints/`

### Validation Behaviors
- Constraints enforced at write time (INSERT, UPDATE, DELETE for NOT_NULL)
- Satisfiability checking at DDL time prevents unsatisfiable constraint definitions
- Duplicate constraint operator detection (e.g., two `<` on same column rejected)
- NOT_NULL cannot be specified on primary key columns
- NOT_NULL before CHECK and after CHECK cannot be combined (duplicate detection)
- DESCRIBE TABLE shows constraints in normalized form

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/ddl.adoc` -- CREATE TABLE and ALTER TABLE syntax should reference constraints
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- mention write-time enforcement
  - `doc/modules/cassandra/pages/developing/cql/definitions.adoc` -- grammar reference
  - `doc/modules/cassandra/pages/developing/cql/changes.adoc` -- CQL changelog
- New pages likely needed: None -- `constraints.adoc` already exists and is comprehensive
- Audience home: Developers (CQL reference)
- Authored or generated: Authored (constraints.adoc is hand-written)
- Technical review needed from: CEP-42 authors / constraint framework committers

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: constraints.adoc; ddl.adoc; dml.adoc; definitions.adoc; changes.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should there be a cross-reference from the DDL page (CREATE TABLE / ALTER TABLE sections) to the constraints page? Currently only the CQL index links to it.
- The constraints.adoc ALTER syntax example has a typo: `ALTER TABLE ks.tb ALTER name LENGTH() < 512;` is missing `CHECK` keyword. Should be `ALTER TABLE ks.tb ALTER name CHECK LENGTH() < 512;`.
- Should there be guidance on performance impact of constraint evaluation at write time?
- The LENGTH constraint documentation does not explicitly state which types it applies to (text, blob, etc.), unlike other constraints.
- Should the custom SPI section in constraints.adoc link more explicitly to the examples/constraints directory or provide inline code samples?

## Next Research Steps
- Verify the ALTER syntax typo in constraints.adoc and file a fix if confirmed
- Cross-check constraints.adoc examples against actual CQL behavior in integration tests
- Review if DDL/DML pages need updates to reference constraints
- Check if `changes.adoc` (CQL changelog) has been updated for constraints
- Confirm whether DESCRIBE TABLE output for constrained tables is documented

## Notes
- The constraints framework went through significant iteration on trunk: initial framework (CASSANDRA-19947), then individual constraint types added in follow-up JIRAs, then a rewrite (CASSANDRA-20563) that removed column specification from constraint definitions and introduced SQL-like NOT NULL syntax.
- The `ConstraintResolver` has two categories of constraints:
  - **UnaryFunctions**: NOT_NULL, JSON (no operator/value, just function name)
  - **Functions**: LENGTH, OCTET_LENGTH, REGEXP (require operator and value)
  - **Scalar**: handled separately, not through function resolution (direct column comparison)
- The SPI loads only one `ConstraintProvider` via `ServiceLoader.findFirst()`. Multiple providers are not supported.
- Scalar constraint supports all Cassandra numeric types plus time, date, and timestamp (12 types total).
- Satisfiability checking is a notable design feature that prevents logically impossible constraint definitions at DDL time.
- The Parser.g grammar shows constraints can be specified on ADD COLUMN in ALTER TABLE as well, which is documented in constraints.adoc.
- No cassandra.yaml configuration exists for constraints. No guardrails specific to constraints were found.
