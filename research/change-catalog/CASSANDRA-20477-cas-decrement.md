# CASSANDRA-20477 CAS support for -= on numeric types

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
CASSANDRA-20477 extends lightweight transactions (LWT / CAS) to support the `-=` decrement assignment operator on numeric columns. Previously, `-=` (subtraction assignment) was only valid for counter columns outside CAS context. After this change, a CAS UPDATE statement with an `IF` condition can include `col -= value` on any numeric type (`int`, `bigint`, `float`, `double`, `decimal`, `varint`). A related bug where empty byte values caused a NullPointerException during subtraction is also fixed.

## Discovery Source
- `CHANGES.txt` reference: "Add support in CAS for -= on numeric types, and fixed improper handling of empty bytes which lead to NPE (CASSANDRA-20477)"
- `NEWS.txt` reference: "Add support in CAS for -= on numeric types, and fixed improper handling of empty bytes which lead to NPE (CASSANDRA-20477)"
- Related JIRA: none listed
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Developers can use `col -= n` in a CAS UPDATE statement (one with an `IF` clause). This is now valid for numeric columns, not just counters. A CAS decrement reads the current value, subtracts the operand, and writes the result atomically within the Paxos round. Also, `+=` on numeric types in CAS context was presumably already supported (the `Addition` class has the same `canReadExistingState` path for `NumberType`).
- Operational effect: CAS with numeric arithmetic requires a read (pre-image fetch) as part of the Paxos round, similar to collection mutations in CAS. The `requiresRead()` method on `Substracter` returns true for non-counter columns, triggering the pre-fetch. This is expected behavior for CAS.
- Upgrade or compatibility effect: No syntax change; `-=` was already valid grammar. The change relaxes a runtime type check: previously `-=` in a CAS statement on an `int` column would throw "Invalid operation for non counter column"; now it succeeds. Existing non-CAS uses of `-=` (on counter columns) are unaffected.
- Configuration or tooling effect: None. No new grammar, no new keywords, no cqlsh changes.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- The UPDATE section (line ~337-341) documents SET assignments: "c = c + 3 will increment/decrement counters, the only operation allowed... Increment/decrement is only allowed on counters." This statement is now **inaccurate** for CAS context — increment/decrement is also allowed on numeric columns in CAS UPDATE statements. This is the documentation gap.
  - No docs files were changed in commit `b56edf2a5d`.
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/Operation.java` -- `Substraction.prepare()`: the type check for `-=` now branches on `canReadExistingState`; when true (CAS context), accepts `NumberType<?>` instead of `CounterColumnType` only. Same pattern exists for `Addition.prepare()` (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/cql3/terms/Constants.java` -- `Substracter.execute()`: new `else if (column.type instanceof NumberType<?>)` branch reads current cell value via `getCurrentCellBuffer()`, subtracts using `type.substract(current, increment)`, writes new value. Also: `sanitize()` helper added to handle empty-byte edge case. `requiresRead()` returns `!column.type.isCounter()` (i.e., true for numeric non-counter types) (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/db/marshal/AbstractType.java` -- `sanitize()` method added: converts empty ByteBuffer to null for types where empty is meaningless (e.g., `Int32Type`). `isEmptyValueMeaningless()` method added returning false by default (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/db/RegularAndStaticColumns.java` -- minor update (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/service/CASRequest.java` -- interface update (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/service/paxos/Paxos.java` -- Paxos integration (commit `b56edf2a5d`)
  - `src/java/org/apache/cassandra/transport/Dispatcher.java` -- `RequestTime` threading for CAS (commit `b56edf2a5d`)
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/test/cql3/CasMultiNodeTableWalkBase.java` -- 129-line addition, CAS with numeric `-=` in multi-node table walk test (commit `b56edf2a5d`)
  - `test/distributed/org/apache/cassandra/distributed/test/cql3/PaxosV1MultiNodeTableWalkTest.java` -- Paxos V1 CAS walk test (commit `b56edf2a5d`)
  - `test/distributed/org/apache/cassandra/distributed/test/cql3/PaxosV2MultiNodeTableWalkTest.java` -- Paxos V2 CAS walk test (commit `b56edf2a5d`)
  - `test/distributed/org/apache/cassandra/distributed/test/cql3/SingleNodeTableWalkTest.java` -- single-node CAS walk test (commit `b56edf2a5d`)
  - `test/unit/org/apache/cassandra/cql3/ast/AssignmentOperator.java` -- AST assignment operator test (commit `b56edf2a5d`)
  - `test/unit/org/apache/cassandra/cql3/ast/CasCondition.java` -- CAS condition AST (commit `b56edf2a5d`)
  - `test/unit/org/apache/cassandra/cql3/ast/Mutation.java` -- AST mutation test (commit `b56edf2a5d`)

## What Changed

### New behavior: CAS UPDATE with numeric -=

```cql
-- Previously: throws "Invalid operation (int_col = int_col - 1) for non counter column int_col"
-- Now: valid CAS decrement on numeric column
UPDATE t SET int_col = int_col - 1 WHERE pk = x IF some_condition = true;

-- Also valid (addition in CAS context was likely already supported through same path)
UPDATE t SET int_col = int_col + 5 WHERE pk = x IF int_col > 0;
```

### Supported numeric types for CAS -=
All subclasses of `NumberType` in `org.apache.cassandra.db.marshal`:
- `Int32Type` (CQL `int`)
- `LongType` (CQL `bigint`)
- `FloatType` (CQL `float`)
- `DoubleType` (CQL `double`)
- `DecimalType` (CQL `decimal`)
- `IntegerType` (CQL `varint`)

Counter columns continue to use the existing counter decrement path (no change).

### NPE fix for empty bytes
When a column's current value is an empty ByteBuffer (which some types treat as null/missing), the `sanitize()` method now converts it to null before arithmetic. This prevents a NullPointerException during subtraction on columns that were set to empty values.

### canReadExistingState flag
The `canReadExistingState` boolean in `Operation.prepare()` is set to true when the statement is a conditional (CAS) statement. This flag is what enables the numeric type path — without it, `-=` on a non-counter is still rejected outside CAS context.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/dml.adoc` -- **GAP** (lines ~337-341): The UPDATE SET section states "increment/decrement is only allowed on counters" — this is now inaccurate for CAS context. Needs a clarification or new sentence noting that `-=` and `+=` are also available for numeric types in CAS UPDATE statements.
  - `doc/modules/cassandra/pages/developing/cql/counter-column.adoc` -- No change needed (counter-specific docs remain accurate).
- New pages likely needed: none
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: David Capwell (implementer), Ariel Weisberg (reviewer)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead or docs-contributor
- Publish blocker: no — the existing docs are not wrong for the non-CAS case; the gap is a missing clarification for CAS context

## Open Questions
1. Does `+=` on numeric types in CAS context already work (the `Addition.prepare()` code has the same `canReadExistingState` path for `NumberType`)? If so, should both `+=` and `-=` be documented together?
2. What happens when the current cell value is null (column not set) and `-=` is applied? Does it return null or throw an error? (The `sanitize()` path returns null which causes `Substracter.execute()` to return without writing — behavior should be documented.)
3. Are there similar restrictions with `*=` or `/=`? (CQL does not appear to have multiply/divide assignment operators, but should be confirmed.)

## Next Research Steps
- Update dml.adoc UPDATE section to note numeric `-=` in CAS context
- Verify whether `+=` for numeric types in CAS was already working before this patch, or was also newly enabled
- Confirm behavior when current cell value is null/unset during CAS decrement

## Notes
- Commit `b56edf2a5d` (CASSANDRA-20477, March 2025): 34 files changed, 934 insertions
- The typo "Substracter" (not "Subtracter") is present in the original code and maintained in the class name
- The `canReadExistingState` parameter flows from `ModificationStatement.prepareColumnOperations()` which checks `hasConditions()` — this is the CAS flag
- NPE fix: `sanitize()` called on both `increment` and `current` ByteBuffers before composing values; if either is null after sanitization, the operation returns without writing
- This change brings numeric types in line with collections, which also support mutation operators in CAS context
