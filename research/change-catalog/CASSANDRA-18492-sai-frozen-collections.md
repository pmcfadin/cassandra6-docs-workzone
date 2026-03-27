# CASSANDRA-18492 SAI Frozen Collection Value/Element Indexing

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Developers |
| Docs impact | major-update |

## Summary
CASSANDRA-18492 enables SAI (Storage-Attached Indexing) to create VALUES, KEYS, and ENTRIES indexes on frozen collections, in addition to the previously-required FULL index type. Before this change, SAI treated frozen collections as opaque binary blobs and only supported FULL indexing (exact-match on the entire serialized collection). With this change, users can search for individual elements within frozen lists, sets, and maps using CONTAINS, CONTAINS KEY, and map entry equality queries -- matching the query capabilities already available on non-frozen collections.

## Discovery Source
- `NEWS.txt` reference: (not found in NEWS.txt)
- `CHANGES.txt` reference: "Allow value/element indexing on frozen collections in SAI (CASSANDRA-18492)" (in 6.0-alpha1 section on remote trunk; not yet in local copy)
- Related JIRA: [CASSANDRA-18492](https://issues.apache.org/jira/browse/CASSANDRA-18492)
- Related CEP or design doc: Part of SAI Phase 3 epic (CASSANDRA-19224)
- GitHub PR: [#4561](https://github.com/apache/cassandra/pull/4561) -- merged March 13, 2026, commit `8d325d5`

## Why It Matters
- User-visible effect: Users can now create SAI indexes on frozen collections with VALUES, KEYS, and ENTRIES targets (not just FULL). This enables element-level queries (CONTAINS, CONTAINS KEY, map entry equality) on frozen collections, matching non-frozen collection query behavior. This is a significant usability improvement because frozen collections are common in schemas that need collection columns as part of clustering keys or need atomic updates.
- Operational effect: Frozen collection element indexes decompose the serialized collection into individual terms during write, resulting in more index entries per row compared to FULL indexing. Guardrail `sai_frozen_term_size` applies to individual extracted terms.
- Upgrade or compatibility effect: New capability in Cassandra 6.0. No backward compatibility concerns for existing frozen FULL indexes. The non-SAI (legacy 2i) index path retains the restriction that frozen collections must use FULL indexing only.
- Configuration or tooling effect: No new cassandra.yaml settings. The existing SAI guardrails (`sai_frozen_term_size`) continue to apply.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/collections.adoc` -- SAI collection indexing overview; currently covers only non-frozen collections
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-set.adoc` -- set examples (non-frozen only)
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-list.adoc` -- list examples (non-frozen only)
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-map.adoc` -- map examples (non-frozen only)
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/sai-concepts.adoc` -- mentions CONTAINS logic for collections
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/sai-faq.adoc` -- FAQ on collection support (no mention of frozen)
  - `doc/modules/cassandra/partials/sai/collections-note.adoc` -- shared tip about CONTAINS clauses (no mention of frozen)
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_sai-create.adoc` -- create index examples (no frozen collection examples)
- Relevant config paths:
  - No new cassandra.yaml settings
- Relevant code paths (on remote trunk, not yet in local copy):
  - `src/java/org/apache/cassandra/cql3/statements/schema/CreateIndexStatement.java` -- validation relaxed for SAI on frozen collections; added `isSAIIndex()` helper; frozen map clustering column ENTRIES restriction
  - `src/java/org/apache/cassandra/index/sai/StorageAttachedIndex.java` -- added `supportsMapElementExpression()` and `supportsFilteringOnMapElementExpression()`; frozen collection value extraction in `validateTermSizeForRow()`
  - `src/java/org/apache/cassandra/index/sai/utils/IndexTermType.java` -- frozen collection element decomposition logic
  - `src/java/org/apache/cassandra/index/Index.java` -- new interface methods for map element expression support
  - `src/java/org/apache/cassandra/index/IndexMetadata.java` -- metadata changes
  - `src/java/org/apache/cassandra/db/filter/RowFilter.java` -- `isMapElementExpression()` helper
  - `src/java/org/apache/cassandra/cql3/restrictions/SimpleRestriction.java` -- `isMapElementExpression()` and validation
  - `src/java/org/apache/cassandra/cql3/restrictions/MergedRestriction.java` -- frozen collection restriction merging
  - `src/java/org/apache/cassandra/index/sai/disk/v1/SSTableIndexWriter.java` -- frozen collection value extraction during write
  - `src/java/org/apache/cassandra/index/sai/memory/MemtableIndexManager.java` -- frozen collection value extraction for memtable
  - `src/java/org/apache/cassandra/index/sai/plan/FilterTree.java` -- frozen collection predicate filtering
  - `src/java/org/apache/cassandra/cql3/Relation.java` -- frozen map entry predicate validation
  - `src/java/org/apache/cassandra/index/sai/plan/Expression.java` -- SAI expression handling changes
- Relevant test paths:
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/maps/MapKeysFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/maps/MapValuesFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/maps/MapEntriesFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/maps/MapFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/sets/SetFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/cql/types/collections/lists/ListFrozenCollectionTest.java`
  - `test/unit/org/apache/cassandra/index/sai/utils/IndexTermTypeTest.java`
  - New: `CollectionIndexingTest.java` (added in PR)
- Relevant generated-doc paths: None

## What Changed

### Index Creation
Before this change, creating an SAI index on a frozen collection with anything other than `FULL` would fail:
```sql
-- Previously: ONLY this was allowed for frozen collections (all index types)
CREATE INDEX ON t (FULL(frozen_set_col)) USING 'sai';

-- Previously: This would FAIL with "Cannot create values() index on frozen column..."
CREATE INDEX ON t (VALUES(frozen_set_col)) USING 'sai';
```

After this change, SAI indexes can be created with multiple target types on frozen collections:
```sql
-- Frozen set/list: VALUES indexing now allowed with SAI
CREATE INDEX ON t (VALUES(frozen_set_col)) USING 'sai';
CREATE INDEX ON t (VALUES(frozen_list_col)) USING 'sai';

-- Frozen map: KEYS, VALUES, and ENTRIES indexing now allowed with SAI
CREATE INDEX ON t (KEYS(frozen_map_col)) USING 'sai';
CREATE INDEX ON t (VALUES(frozen_map_col)) USING 'sai';
CREATE INDEX ON t (ENTRIES(frozen_map_col)) USING 'sai';

-- FULL indexing continues to work for all frozen collections
CREATE INDEX ON t (FULL(frozen_set_col)) USING 'sai';
```

### Query Support
With element-level indexes on frozen collections, these queries become possible:
```sql
-- CONTAINS on frozen set/list (requires VALUES index)
SELECT * FROM t WHERE frozen_set_col CONTAINS 'value';
SELECT * FROM t WHERE frozen_list_col CONTAINS 'value';

-- CONTAINS KEY on frozen map (requires KEYS index)
SELECT * FROM t WHERE frozen_map_col CONTAINS KEY 'key';

-- CONTAINS on frozen map values (requires VALUES index)
SELECT * FROM t WHERE frozen_map_col CONTAINS 'value';

-- Map entry equality on frozen map (requires ENTRIES index)
SELECT * FROM t WHERE frozen_map_col['key'] = 'value';
```

### Limitations
- ENTRIES indexes on frozen map clustering columns are not allowed (produces unqueryable indexes due to `FROZEN_MAP_ENTRY_PREDICATES_NOT_SUPPORTED` in the restriction layer)
- Non-SAI (legacy 2i) indexes still require FULL for frozen collections -- this relaxation is SAI-specific
- FULL indexing remains the only option for exact-match equality on the entire frozen collection

### SAI Implementation Details
- SAI decomposes frozen collection values into individual index terms during write (both memtable and SSTable paths)
- The `CreateIndexStatement` validation was modified with an `isSAIIndex()` check to conditionally allow non-FULL targets on frozen collections
- New `Index` interface methods (`supportsMapElementExpression`, `supportsFilteringOnMapElementExpression`) were added so the CQL layer can delegate capability decisions to the index implementation

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/collections.adoc` -- needs to document frozen collection support alongside existing non-frozen coverage
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-set.adoc` -- needs frozen set example
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-list.adoc` -- needs frozen list example
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_collections-map.adoc` -- needs frozen map examples (keys, values, entries)
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/_sai-create.adoc` -- should mention frozen collection index creation
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/sai-faq.adoc` -- FAQ on collection support should mention frozen collections
  - `doc/modules/cassandra/partials/sai/collections-note.adoc` -- shared tip should note frozen collection support
  - `doc/modules/cassandra/pages/developing/cql/indexing/sai/sai-concepts.adoc` -- CONTAINS logic note could mention frozen collections
- New pages likely needed: None -- existing collection pages should be extended
- Audience home: Developers (CQL reference, SAI section)
- Authored or generated: Authored (all affected pages are hand-written)
- Technical review needed from: SAI team (Caleb Rackliffe, Andres de la Pena, Sunil Ramchandra Pawar)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: collections.adoc; _collections-set.adoc; _collections-list.adoc; _collections-map.adoc; sai-faq.adoc; sai-concepts.adoc
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
- Should frozen collection examples be added inline to the existing collection pages, or should a separate subsection/page be created for frozen collection indexing?
- The ENTRIES index limitation on frozen map clustering columns -- should this be explicitly documented as a known limitation?
- Should the docs clarify the behavioral difference: non-SAI indexes still require FULL for frozen collections, while SAI now supports element-level indexing?
- Are there performance considerations (index size, write amplification) when using element-level indexing on large frozen collections that should be documented?
- The PR review noted that creating ENTRIES indexes on frozen map clustering columns was silently allowed but produced unqueryable indexes. Was this fully resolved in the final merge, or is there a remaining edge case?

## Next Research Steps
- Pull the latest trunk to obtain commit `8d325d5` and verify the final code changes
- Confirm the exact error messages and behaviors after the change lands in the local copy
- Review `CollectionIndexingTest.java` (added in PR) for comprehensive example queries that could inform doc examples
- Check whether CQL examples (.cql files) in `doc/modules/cassandra/examples/CQL/sai/` need new frozen collection examples
- Verify whether any existing doc text implies frozen collections cannot be indexed at element level (statements to remove/update)

## Notes
- The local Cassandra trunk (commit `cd707ba67d`, dated January 27, 2026) predates the merge of this JIRA (March 13, 2026). All code evidence for the actual change comes from the GitHub PR and remote trunk, not the local copy.
- The change spans 18 files across the CQL layer (validation, restrictions), SAI engine (write path, expression handling), and index interface (new capability methods). This is a substantial cross-cutting change.
- The key architectural decision was to add `isSAIIndex()` checking in `CreateIndexStatement.validateIndexTarget()` to conditionally bypass the frozen-collection-must-use-FULL restriction for SAI. The PR reviewer (adelapena) suggested using the new `Index#supportsMapElementExpression` method to keep SAI-specific logic out of the CQL layer where possible.
- Frozen collections with element-level indexes are decomposed at write time, meaning each element of the collection is indexed individually. This is transparent to the query path but has write-amplification implications for large collections.
- This is part of the SAI Phase 3 epic (CASSANDRA-19224), which includes other SAI enhancements.
- The `sai_frozen_term_size` guardrail applies to individual extracted terms, not the full serialized collection.
