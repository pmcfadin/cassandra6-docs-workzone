# CASSANDRA-19677: Per-Type Max Size Guardrails

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary

CASSANDRA-19677 adds type-specific size guardrails for both column values and collections. Previously, Cassandra had only a single `column_value_size` guardrail and a single `collection_size` guardrail that applied uniformly to all types. This change introduces:

- **Per-column-type value size guardrails**: Separate warn/fail thresholds for `ascii`, `blob`, and `text`/`varchar` column types
- **Per-collection-type size guardrails**: Separate warn/fail thresholds for `map`, `set`, and `list` collections
- **FallbackThreshold mechanism**: Collection-type-specific guardrails automatically fall back to the generic `collection_size` guardrail when the type-specific guardrail is not configured, providing backward compatibility

This enables operators to set different size limits per data type -- for example, allowing larger blob values while restricting text values.

## Discovery Source

- `CHANGES.txt`: "Add per type max size guardrails (CASSANDRA-19677)"
- `NEWS.txt`: Not explicitly mentioned (change is an enhancement to existing guardrails)
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-19677
- Commit: 95180bab15 (2024-06-07), author Bernardo Botella Corbi, reviewed by Jordan West and Yifan Cai

## Why It Matters

- **User-visible effect:** Operators can now set different size limits for different column/collection types. For example, blob columns can have a higher limit than text columns, or map collections can have a different limit than list collections.
- **Operational effect:** More granular control over data sizes. Operators managing workloads with mixed data types (e.g., storing both small text metadata and large binary blobs) can set appropriate limits for each type rather than a single one-size-fits-all threshold.
- **Upgrade or compatibility effect:** All new settings default to null (disabled). When disabled, the column-type-specific guardrails have no effect (the generic `column_value_size` guardrail still applies). Collection-type-specific guardrails automatically fall back to the generic `collection_size` guardrail via the `FallbackThreshold` mechanism. No behavioral change on upgrade.
- **Configuration or tooling effect:** 12 new `cassandra.yaml` settings (6 for column types, 6 for collections); all dynamically configurable via JMX.

## Source Evidence

- Relevant docs paths:
  - No existing guardrails documentation page in `doc/` directory
  - No existing documentation covers this feature

- Relevant config paths:
  - `conf/cassandra.yaml` -- Column-type-specific value size guardrails:
    ```yaml
    # Guardrail to warn or fail when writing ascii column values larger than threshold.
    # column_ascii_value_size_warn_threshold:
    # column_ascii_value_size_fail_threshold:

    # Guardrail to warn or fail when writing blob column values larger than threshold.
    # column_blob_value_size_warn_threshold:
    # column_blob_value_size_fail_threshold:

    # Guardrail to warn or fail when writing text column values larger than threshold.
    # column_text_and_varchar_value_size_warn_threshold:
    # column_text_and_varchar_value_size_fail_threshold:
    ```
  - `conf/cassandra.yaml` -- Collection-type-specific size guardrails:
    ```yaml
    # Guardrail to warn or fail when encountering larger size of map data than threshold.
    # When collection_map_size_warn/fail_threshold are defined, they take precedence
    # over the corresponding collection_size_warn/fail_threshold.
    # collection_map_size_warn_threshold:
    # collection_map_size_fail_threshold:

    # collection_set_size_warn_threshold:
    # collection_set_size_fail_threshold:

    # collection_list_size_warn_threshold:
    # collection_list_size_fail_threshold:
    ```

- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java`: 12 new nullable `DataStorageSpec.LongBytesBound` fields (6 column type + 6 collection type), all defaulting to `null`
  - `src/java/org/apache/cassandra/config/GuardrailsOptions.java`: 169 lines added -- getter/setter methods for all 12 thresholds
  - `src/java/org/apache/cassandra/db/guardrails/Guardrails.java`: 200 lines added:
    - `columnAsciiValueSize`, `columnBlobValueSize`, `columnTextAndVarcharValueSize` as `MaxThreshold` guardrails
    - `collectionMapSize`, `collectionSetSize`, `collectionListSize` as `FallbackThreshold<MaxThreshold>` wrapping `collectionSize`
  - `src/java/org/apache/cassandra/db/guardrails/FallbackThreshold.java`: New class (72 lines) that wraps a primary and fallback threshold. If the primary is enabled (has thresholds set), it is used; otherwise, the fallback is used.
  - `src/java/org/apache/cassandra/cql3/UpdateParameters.java`: New `validateColumnSize()` method dispatches to type-specific guardrails based on `CQL3Type.Native` (ASCII, BLOB, TEXT). Called after the generic `columnValueSize` check in `addCell()`.
  - `src/java/org/apache/cassandra/cql3/terms/Lists.java`: Changed from `Guardrails.collectionSize.guard()` to `Guardrails.collectionListSize.guard()`
  - `src/java/org/apache/cassandra/cql3/terms/Maps.java`: Changed from `Guardrails.collectionSize.guard()` to `Guardrails.collectionMapSize.guard()`
  - `src/java/org/apache/cassandra/cql3/terms/Sets.java`: Changed from `Guardrails.collectionSize.guard()` to `Guardrails.collectionSetSize.guard()`
  - `src/java/org/apache/cassandra/db/guardrails/GuardrailsConfig.java`: 75 lines added -- interface methods for all new thresholds
  - `src/java/org/apache/cassandra/db/guardrails/GuardrailsMBean.java`: 150 lines added -- JMX exposure for all new settings

- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/guardrails/ColumnTypeSpecificValueThresholdTester.java` (263 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailCollectionListSizeTest.java` (96 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailCollectionMapSizeTest.java` (121 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailCollectionSetSizeTest.java` (96 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailCollectionTypeSpecificSizeTester.java` (90 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailColumnAsciiValueSizeTest.java` (61 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailColumnBlobValueSizeTest.java` (180 lines)
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailColumnTextAndVarcharValueSizeTest.java` (62 lines)

## What Changed

### Column-Type-Specific Value Size Guardrails
1. **Three new guardrail pairs** for column types:
   - `column_ascii_value_size_warn_threshold` / `_fail_threshold`: Size limits for `ascii` type columns
   - `column_blob_value_size_warn_threshold` / `_fail_threshold`: Size limits for `blob` type columns
   - `column_text_and_varchar_value_size_warn_threshold` / `_fail_threshold`: Size limits for `text` and `varchar` type columns (treated as the same type)
2. **Interaction with generic guardrail**: Both the generic `column_value_size` and the type-specific guardrail are checked. The effective limit is the smaller of the two thresholds. The YAML documentation states: "If this guardrail is enabled along with column_value_size_warn/fail_threshold, size restriction for the column type will be the smallest of the two."
3. **Scope**: Only applied to regular column values, not partition keys or clustering key components (which already have a 65535 byte limit).

### Collection-Type-Specific Size Guardrails
4. **Three new guardrail pairs** for collection types:
   - `collection_map_size_warn_threshold` / `_fail_threshold`: Size limits for `map` collections
   - `collection_set_size_warn_threshold` / `_fail_threshold`: Size limits for `set` collections
   - `collection_list_size_warn_threshold` / `_fail_threshold`: Size limits for `list` collections
5. **FallbackThreshold mechanism**: Each collection-type guardrail wraps the generic `collectionSize` as a fallback. If the type-specific thresholds are set (enabled), they take precedence. If not set, the generic `collection_size` thresholds are used. This preserves backward compatibility.
6. **SSTable write-time checking**: Collection guardrails are also checked at SSTable write time for non-frozen collections. At SSTable write time, exceeding the fail threshold only logs an error (does not abort the operation).

### New Infrastructure
7. **FallbackThreshold class**: A new guardrail wrapper type that delegates to a primary threshold if enabled, otherwise to a fallback threshold. This pattern enables type-specific overrides without breaking existing generic guardrail behavior.

## Docs Impact

- Existing pages likely affected:
  - The `cassandra.yaml` configuration reference should document all 12 new settings
  - Any existing collection size or column value size guardrail documentation must be updated to explain the type-specific variants
- New pages likely needed:
  - A guardrails reference page (if not already planned) should document the fallback behavior and the interaction between generic and type-specific thresholds
- Audience home: Operators
- Authored or generated: Authored
- Technical review needed from: Bernardo Botella Corbi (patch author), Jordan West or Yifan Cai (reviewers)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

- For column-type guardrails: what happens when both the generic `column_value_size` and a type-specific guardrail are set? The YAML comment says "the smallest of the two" but the code checks both independently -- does the first-to-fail produce the error, or are both always checked?
- Are there plans to add type-specific guardrails for other types (e.g., `int`, `uuid`, `timestamp`)? The current set covers `ascii`, `blob`, and `text`/`varchar` only.
- The YAML comments for collection-type guardrails contain a typo: "cooresponding" (should be "corresponding"). Should this be fixed in a separate commit?
- Is there a guardrails documentation page planned for Cassandra 6.0?
- How do the collection-type guardrails interact with frozen collections vs. non-frozen collections? The YAML comment mentions differences in SSTable write-time behavior.

## Notes

- Commit date is 2024-06-07, placing this in the Cassandra 5.x/6.0 development cycle.
- The `FallbackThreshold` class is a reusable pattern that could be applied to other guardrails in the future.
- The `text` and `varchar` types share a single guardrail (`column_text_and_varchar_value_size`) because CQL treats them as aliases for the same underlying type.
- The column-type-specific guardrails do NOT use the `FallbackThreshold` pattern -- they are independent `MaxThreshold` instances checked alongside the generic `columnValueSize`. Only the collection-type-specific guardrails use `FallbackThreshold`.
- This is a substantial change: 1748 lines added across 20 files, with 8 new test classes.
- Patch authored by Bernardo Botella Corbi, reviewed by Jordan West and Yifan Cai.
