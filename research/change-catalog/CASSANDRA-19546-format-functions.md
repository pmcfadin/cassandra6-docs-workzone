# CASSANDRA-19546 format_bytes and format_time CQL functions

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
Two new native CQL scalar functions, `format_bytes` and `format_time`, convert numeric column values into human-readable size and duration strings. Both accept 1-3 arguments: value only (auto-selects best unit), value + target unit, or value + source unit + target unit. They support `INT`, `TINYINT`, `SMALLINT`, `BIGINT`, `VARINT`, `ASCII`, and `TEXT` input types and return `TEXT`.

## Discovery Source
- `NEWS.txt` reference: line 137 -- "New functions `format_bytes` and `format_time` were added. See CASSANDRA-19546."
- `CHANGES.txt` reference: line 164 -- "Add format_bytes and format_time functions (CASSANDRA-19546)"
- Related JIRA: CASSANDRA-19546
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Users can format byte counts and durations directly in CQL SELECT queries without client-side conversion.
- Operational effect: Operators can get human-readable output from system tables (e.g., compaction stats, memory metrics) without external tooling.
- Upgrade or compatibility effect: Purely additive -- no breaking changes. Functions are new in Cassandra 6 / trunk.
- Configuration or tooling effect: None. These are built-in CQL functions with no configuration.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/functions.adoc` (lines 341-522, section "Human helper functions")
- Relevant config paths: none
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/functions/FormatFcts.java` -- full implementation of both functions
  - `src/java/org/apache/cassandra/config/DataStorageSpec.java` -- `DataStorageUnit.fromSymbol()` for byte unit parsing
  - `src/java/org/apache/cassandra/config/DurationSpec.java` -- `fromSymbol()` for time unit parsing
- Relevant test paths:
  - `test/unit/org/apache/cassandra/cql3/functions/FormatBytesFctTest.java`
  - `test/unit/org/apache/cassandra/cql3/functions/FormatTimeFctTest.java`
- Relevant generated-doc paths: none

## What Changed
1. **New `format_bytes` function**: Converts numeric values (treated as bytes by default) to human-readable size strings. Supported target units: `B`, `KiB`, `MiB`, `GiB`. Auto-selects the closest unit when called with one argument.
2. **New `format_time` function**: Converts numeric values (treated as milliseconds by default) to human-readable duration strings. Supported units: `d`, `h`, `m`, `s`, `ms`, `us`, `us` (also `µs`), `ns`. Auto-selects the closest unit when called with one argument.
3. Both functions: accept 1, 2, or 3 arguments; return `TEXT`; reject null arguments (return null if the value column itself is null); reject negative values; round results to two decimal places.

## Docs Impact
- Existing pages likely affected: `doc/modules/cassandra/pages/developing/cql/functions.adoc` -- **already documented** with a full section (lines 341-522) including summary table, detailed descriptions, and worked examples for both functions.
- New pages likely needed: none
- Audience home: Developers (CQL reference)
- Authored or generated: authored
- Technical review needed from: none -- documentation is already in place and matches implementation

## Documentation Quality Notes
The existing documentation is thorough and covers all three calling conventions for both functions with examples. One minor issue was found:

- **Typo on line 446**: The example query reads `format_bytes(val, 'Kib', 'MiB')` with a lowercase 'b' in `Kib`. The `DataStorageUnit.fromSymbol()` method is case-sensitive and expects `KiB` (uppercase B). The output line 448 correctly shows `KiB`. This is likely a cosmetic typo in the doc example input that would cause an error if executed literally.

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: functions.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should the `Kib` typo on line 446 of `functions.adoc` be fixed to `KiB`? (Minor, but would cause an error if a user copy-pastes the example.)

## Next Research Steps
- Fix the `Kib` -> `KiB` typo in `functions.adoc` line 446 if confirmed as a bug.
- No other research needed -- this feature is fully documented.

## Notes
- Commit `ba4a0d4fcb` (2024-04-26) added both the implementation and documentation together.
- The functions are registered via `FormatFcts.addFunctionsTo()` which adds both `FormatBytesFct.factory()` and `FormatTimeFct.factory()`.
- `format_bytes` uses binary units (KiB/MiB/GiB = powers of 1024), not decimal units (KB/MB/GB).
- `format_time` default source unit is milliseconds; `format_bytes` default source unit is bytes.
