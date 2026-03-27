# CASSANDRA-17021 ZSTD Dictionary Compression

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
Cassandra 6.0 introduces ZSTD dictionary compression for SSTables via
the new `ZstdDictionaryCompressor` class. Operators can train compression
dictionaries on representative SSTable data, store them cluster-wide in
`system_distributed.compression_dictionaries`, and manage them through
`nodetool compressiondictionary` subcommands (train, list, export,
import, cleanup). Training parameters (`training_max_dictionary_size`,
`training_max_total_sample_size`, `training_min_frequency`) are
configured per-table in CQL compression options. Node-level dictionary
caching and refresh are configured in `cassandra.yaml`. A guardrail
warns or blocks when `training_min_frequency` is not explicitly set.

## Discovery Source
- `NEWS.txt` reference: none found (not yet listed in NEWS.txt)
- `CHANGES.txt` reference (6.0-alpha1): CASSANDRA-17021 ("Support ZSTD dictionary compression") listed under 5.0 section; related follow-on JIRAs listed under 6.0-alpha1
- Related JIRAs:
  - CASSANDRA-17021: Original ZSTD dictionary compression support
  - CASSANDRA-21209: Rework ZSTD dictionary compression logic to create a trainer per training
  - CASSANDRA-21078: Move training parameters for Zstd dictionary compression to CQL
  - CASSANDRA-20941: Add export, list, import sub-commands for nodetool compressiondictionary
  - CASSANDRA-20938: Enable CQLSSTableWriter to create SSTables compressed with a dictionary
  - CASSANDRA-21194: Harden range of values for max dictionary size / max total sample size
  - CASSANDRA-21192: Guardrail ensuring minimum training frequency parameter is provided
  - CASSANDRA-21188: Replace manual referencing with ColumnFamilyStore.selectAndReference
  - CASSANDRA-21179: Introduce check for minimum time between dictionary training/import
  - CASSANDRA-21178: Introduce created_at column to compression_dictionaries
  - CASSANDRA-21157: Detect and remove orphaned compression dictionaries
  - CASSANDRA-21074: Change eager reference counting of dictionaries to lazy
- Related CEP or design doc: none identified

## Why It Matters
- User-visible effect: New compressor class `ZstdDictionaryCompressor` available in CQL `compression` options. Achieves superior compression ratios for workloads with repetitive data patterns (JSON, XML, repeated schemas). Rated "A++" for ratio in the docs compression comparison table.
- Operational effect: New operational workflow for dictionary management -- training, listing, exporting, importing, and cleaning up dictionaries via nodetool. New system table `system_distributed.compression_dictionaries` stores dictionaries cluster-wide. Dictionary caching adds minor memory overhead per node.
- Upgrade or compatibility effect: New in Cassandra 6.0 (listed as `>= 6.0` in docs). SSTables compressed with dictionary compression require the dictionary to be present for reads; historical dictionaries must be retained until older SSTables are compacted away.
- Configuration or tooling effect: Four new `cassandra.yaml` settings for dictionary refresh and caching. Three new CQL-level training parameters per table. Five new nodetool subcommands. One guardrail for `training_min_frequency`.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/compression.adoc` -- already contains comprehensive ZSTD dictionary compression documentation including "ZSTD Dictionary Compression" section, "Dictionary Compression Configuration" section, and "Dictionary Compression Operational Considerations" subsection
  - `doc/modules/cassandra/partials/compress-subproperties.adoc` -- does NOT yet include ZstdDictionaryCompressor or dictionary training parameters
- Relevant config paths:
  - `conf/cassandra.yaml` -- the four dictionary settings are NOT present in the YAML file (they exist as Config.java defaults but are not exposed in the default cassandra.yaml)
  - `src/java/org/apache/cassandra/config/Config.java` -- defines four cassandra.yaml-mappable fields:
    - `compression_dictionary_refresh_interval` (default: `3600s`)
    - `compression_dictionary_refresh_initial_delay` (default: `10s`)
    - `compression_dictionary_cache_size` (default: `10`)
    - `compression_dictionary_cache_expire` (default: `24h`)
- Relevant code paths:
  - `src/java/org/apache/cassandra/io/compress/ZstdDictionaryCompressor.java` -- compressor implementation
  - `src/java/org/apache/cassandra/io/compress/ZstdCompressorBase.java` -- base class (compression_level default: 3)
  - `src/java/org/apache/cassandra/io/compress/IDictionaryCompressor.java` -- interface defining CQL parameter name constants:
    - `training_max_dictionary_size` (default: `64KiB`)
    - `training_max_total_sample_size` (default: `10MiB`)
    - `training_min_frequency` (default: `0m`)
  - `src/java/org/apache/cassandra/db/compression/CompressionDictionaryManager.java` -- training workflow orchestration
  - `src/java/org/apache/cassandra/db/compression/CompressionDictionaryManagerMBean.java` -- JMX interface
  - `src/java/org/apache/cassandra/db/compression/CompressionDictionaryTrainingConfig.java` -- training config builder with validation
  - `src/java/org/apache/cassandra/db/compression/CompressionDictionaryCache.java` -- Caffeine-based local cache
  - `src/java/org/apache/cassandra/db/compression/CompressionDictionaryScheduler.java` -- training scheduler
  - `src/java/org/apache/cassandra/db/compression/ZstdDictionaryTrainer.java` -- trainer implementation
  - `src/java/org/apache/cassandra/tools/nodetool/CompressionDictionaryCommandGroup.java` -- nodetool subcommands
  - `src/java/org/apache/cassandra/schema/SystemDistributedKeyspace.java` -- compression_dictionaries table schema
  - `src/java/org/apache/cassandra/schema/CompressionParams.java` -- CQL compression parameter parsing
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/compression/CompressionDictionaryIntegrationTest.java`
  - `test/unit/org/apache/cassandra/db/compression/CompressionDictionaryCacheTest.java`
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailUnsetTrainingMinFrequencyTest.java`
  - `test/resources/nodetool/help/compressiondictionary` (and subcommand help files)
  - `test/microbench/org/apache/cassandra/test/microbench/ZstdDictionaryCompressor*Bench*.java`
- Relevant generated-doc paths:
  - `doc/scripts/gen-nodetool-docs.py` -- does NOT currently handle command groups; nodetool `compressiondictionary` subcommands will likely not be auto-generated

## What Changed

### New compressor class
- `ZstdDictionaryCompressor` is a new CQL compression class available via `WITH compression = {'class': 'ZstdDictionaryCompressor'}`.
- Inherits `compression_level` (default 3) from `ZstdCompressorBase`.
- Three CQL-level training parameters: `training_max_dictionary_size`, `training_max_total_sample_size`, `training_min_frequency`.

### New system table
- `system_distributed.compression_dictionaries` stores dictionaries cluster-wide.
- Schema: `keyspace_name text, table_name text, table_id text, kind text, dict_id bigint, dict blob, dict_length int, dict_checksum int, created_at timestamp`
- Primary key: `((keyspace_name, table_name), table_id, dict_id)` with descending clustering order.

### New nodetool compressiondictionary command group
Five subcommands:
1. `train <keyspace> <table>` -- triggers dictionary training; options: `--force/-f`, `--max-dict-size`, `--max-total-sample-size`
2. `list <keyspace> <table>` -- lists available dictionaries for a table
3. `export <keyspace> <table> <path>` -- exports dictionary to JSON file; option: `--id/-i` for specific dictionary ID
4. `import <path>` -- imports dictionary from JSON file
5. `cleanup` -- removes orphaned dictionaries; option: `--dry/-d` for dry run

### New cassandra.yaml settings (in Config.java)
- `compression_dictionary_refresh_interval` (default: 3600s)
- `compression_dictionary_refresh_initial_delay` (default: 10s)
- `compression_dictionary_cache_size` (default: 10)
- `compression_dictionary_cache_expire` (default: 24h)
- Note: these are not yet present in the default `conf/cassandra.yaml` file.

### Guardrail
- `unsetTrainingMinFrequency` guardrail warns or blocks table creation with `ZstdDictionaryCompressor` when `training_min_frequency` is not explicitly set.

## Docs Impact
- Existing pages likely affected:
  - `compression.adoc` -- ALREADY extensively updated in trunk with ZSTD dictionary content (verified). Covers: how it works, when to use, training, storage, CQL configuration, cassandra.yaml settings, operational considerations, nodetool commands.
  - `compress-subproperties.adoc` -- needs update to include `ZstdDictionaryCompressor` and its parameters
  - Generated nodetool docs -- `gen-nodetool-docs.py` does not handle command groups; `compressiondictionary` subcommands need manual or script-enhanced documentation
  - `cassandra.yaml` generated reference -- four new properties need to appear in the YAML config reference
  - Guardrails documentation -- new `unsetTrainingMinFrequency` guardrail needs to be documented
- New pages likely needed: none (compression.adoc already covers the feature comprehensively)
- Audience home: Operators (primary), Developers (CQL usage)
- Authored or generated: Authored (compression.adoc is authored content), plus generated surfaces that need updates (nodetool docs, yaml reference)
- Technical review needed from: Compression/storage subsystem developers

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: compression.adoc; compress-subproperties.adoc
- Owner role: technical-owner
- Publish blocker: yes

## Open Questions
1. The four `compression_dictionary_*` settings exist in `Config.java` but are NOT present in `conf/cassandra.yaml`. Should they be added to the default YAML file with comments? The docs reference them as cassandra.yaml settings.
2. The `gen-nodetool-docs.py` script does not handle command groups (regex only matches simple command names). The `compressiondictionary` command group with its five subcommands will not be auto-generated. How should these be documented -- manual pages, or script enhancement?
3. The `compress-subproperties.adoc` partial does not include `ZstdDictionaryCompressor`. Should it be updated alongside the main compression page?
4. The compression.adoc page in trunk states cache expire default is 3600s, but Config.java shows the default is `24h` (86400s). This discrepancy needs resolution.
5. CASSANDRA-17021 appears in CHANGES.txt under 5.0 but the feature (including all follow-on JIRAs for CQL parameters, nodetool commands, guardrails) is a 6.0 feature. Confirm version attribution for docs.
6. Is auto-training planned for a future release, or is manual-only training the intended long-term design? The docs say "Cassandra supports manual training approach for now."

## Next Research Steps
- Resolve the cache expire default discrepancy (docs say 3600s vs Config.java says 24h)
- Verify whether compression_dictionary_* properties should be added to cassandra.yaml
- Assess gen-nodetool-docs.py for command group support or plan manual nodetool docs
- Update compress-subproperties.adoc to include ZstdDictionaryCompressor
- Confirm guardrails documentation coverage for unsetTrainingMinFrequency
- Identify technical reviewer for compression subsystem

## Notes
- The trunk `compression.adoc` page already contains substantial, well-structured documentation for this feature. This is one of the most thoroughly pre-documented Cassandra 6.0 features. The primary remaining work is around generated surfaces (nodetool docs, yaml reference), the compress-subproperties partial, and resolving the identified discrepancies.
- The feature involves a cluster of 12+ related JIRAs that refined the original CASSANDRA-17021 implementation, particularly around CQL parameter placement (CASSANDRA-21078), nodetool commands (CASSANDRA-20941), guardrails (CASSANDRA-21192), and training robustness (CASSANDRA-21209).
- Dictionary compression uses a Caffeine-based local cache with configurable size and TTL, plus cluster-wide storage in system_distributed.
- Training is synchronous and may be CPU-intensive; docs correctly recommend off-peak scheduling.
- The `--force` flag on `nodetool compressiondictionary train` bypasses sample sufficiency checks, useful for testing or small datasets.
- Export/import workflow enables cross-cluster dictionary portability via JSON files.
- The cleanup subcommand handles orphaned dictionaries from dropped tables.
