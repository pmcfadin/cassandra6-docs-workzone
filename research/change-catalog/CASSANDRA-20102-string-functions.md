# CASSANDRA-20102 octet_length and length CQL functions

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | minor-update |

## Summary
CASSANDRA-20102 adds two SQL99-aligned native CQL functions: `octet_length` (returns byte count of any CQL type's ByteBuffer representation) and `length` (returns UTF-8 code unit count for `text` columns). These eliminate the need for custom UDFs or application-level workarounds when users need to query column data lengths without retrieving the full data. The feature shipped in Cassandra 6.0-alpha1 and 6.0, implemented by Joey Lynch via PR #3707 (commit 0d39ea4).

## Discovery Source
- `NEWS.txt` reference: Listed under "6.0 New features" -- describes `octet_length` defined on all types and `length` defined on UTF8 strings as a subset of SQL99 binary string functions.
- `CHANGES.txt` reference: `Support octet_length and length functions (CASSANDRA-20102)`
- Related JIRA: [CASSANDRA-20102](https://issues.apache.org/jira/browse/CASSANDRA-20102) (Resolved, Fix Version 6.0-alpha1, 6.0)
- Related CEP or design doc: None. Related ticket CASSANDRA-19546 (format_bytes and format_time) mentioned in discussion.

## Why It Matters
- User-visible effect: Two new CQL built-in functions available in queries. `octet_length(col)` works on any column type; `length(col)` works on `text` columns. Both return `int` and return `null` on `null` input.
- Operational effect: Reduces network bandwidth and frees memory earlier compared to reading full column data to check length. Data still requires disk reads.
- Upgrade or compatibility effect: New functions only; no breaking changes. Not backported to 4.1 or 5.x -- trunk/6.0 only.
- Configuration or tooling effect: None. Functions are registered automatically as native functions.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/functions.adoc` -- New "Length Functions" section (48 lines added) with full documentation including type tables and examples.
- Relevant config paths: None.
- Relevant code paths:
  - `src/java/org/apache/cassandra/cql3/functions/LengthFcts.java` -- New file (93 lines). Implements `octet_length` for all native CQL types via `ByteBuffer#remaining()` (no deserialization), and `length` for UTF8Type via `String#length()`.
  - `src/java/org/apache/cassandra/cql3/functions/NativeFunctions.java` -- Registration call: `LengthFcts.addFunctionsTo(this)`.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/cql3/functions/LengthFctsTest.java` -- New file (98 lines). Tests octet_length across numeric types, length vs byte length for UTF-8, null handling, argument count validation, and property-based fuzz testing (1024 random strings via QuickTheories).
- Relevant generated-doc paths: None identified.

## What Changed
1. **New `octet_length` function**: Defined for every native CQL type. Returns `int` representing byte count of the underlying ByteBuffer. Uses noop argument handler to avoid deserialization. Fixed sizes for fixed-width types (e.g., tinyint=1, smallint=2, int=4, bigint=8, float=4, double=8); variable for blob and text.
2. **New `length` function**: Defined only for `text` (UTF8Type). Returns `int` representing UTF-8 code unit count (equivalent to Java `String#length()`). Example: Japanese string with 7 codepoints returns length=7 but octet_length=21.
3. **Documentation added inline**: The `functions.adoc` page already contains a complete "Length Functions" subsection with a reference table of octet_length values per type and behavioral notes.

## Docs Impact
- Existing pages likely affected: `doc/modules/cassandra/pages/developing/cql/functions.adoc` -- already updated with a full "Length Functions" section. Should be reviewed for accuracy and completeness.
- New pages likely needed: None.
- Audience home: Developers (CQL reference)
- Authored or generated: Authored (inline documentation committed with the feature).
- Technical review needed from: CQL functions maintainer or original author (Joey Lynch).

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: functions.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- The docs say `length` returns "UTF-8 code units" and is equivalent to Java `String#length()`. Java's `String#length()` returns UTF-16 code units, not UTF-8 code units. For BMP characters these are the same, but for supplementary characters (emoji, etc.) they differ. The documentation wording should be verified for technical accuracy -- is "UTF-8 code units" the intended description, or should it say "UTF-16 code units" or simply "character count"?
- Should the functions.adoc page cross-reference these functions from any "What's New in 6.0" landing page or migration guide?
- Are there any additional SQL99 string functions planned beyond these two (e.g., `char_length`, `bit_length`, `substring`, `trim`)?

## Next Research Steps
- Review the exact wording in functions.adoc for the UTF-8 vs UTF-16 code unit distinction and confirm correctness.
- Check whether `cql_singlefile.adoc` (if it exists as a generated aggregate) picks up the new section automatically.
- Verify no additional functions were added in follow-up commits beyond the original PR.
- Confirm style consistency of the new doc section with surrounding sections in functions.adoc.

## Notes
- The JIRA was marked as Low priority but addresses a frequently requested feature.
- The `octet_length` function deliberately avoids deserializing data for performance -- it operates directly on the ByteBuffer.
- The commit message references SQL99 compatibility, positioning these as the beginning of broader SQL standard function support in CQL.
- NEWS.txt explicitly frames this as "a subset of the SQL99 (binary) string functions," suggesting future expansion is possible.
- QuickTheories property-based testing framework is used in the test, which is notable as a testing pattern.
