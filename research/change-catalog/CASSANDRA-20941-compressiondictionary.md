# CASSANDRA-20941: Nodetool compressiondictionary export/list/import commands

## JIRA Summary

| Field | Value |
|-------|-------|
| JIRA | [CASSANDRA-20941](https://issues.apache.org/jira/browse/CASSANDRA-20941) |
| Title | Add Nodetool command to import / export / list compression dictionary |
| Status | Resolved |
| Fix Version | 6.0-alpha1, 6.0 |
| Reporter | Yifan Cai |
| Assignee | Stefan Miklosovic |
| Commit | `136e5fd222a087d6104d9dce307d759d1f6a5d3e` |
| PR | [apache/cassandra#4458](https://github.com/apache/cassandra/pull/4458) |
| Epic | CEP-54 (ZSTD Dictionary Compression) |

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Change Description

This JIRA adds three new subcommands to the `nodetool compressiondictionary` command group (which already had `train` from CASSANDRA-17021/CEP-54). The full command group is:

### `nodetool compressiondictionary` subcommands (Cassandra 6)

1. **`train`** -- Manually trigger compression dictionary training for a table. Pre-existing from CEP-54 base.
2. **`list`** -- List available dictionaries for a specific keyspace and table. **New in this JIRA.**
3. **`export`** -- Export a dictionary from Cassandra to a local file as JSON. **New in this JIRA.**
4. **`import`** -- Import a local dictionary JSON file into Cassandra. **New in this JIRA.**

### Subcommand Details

**`nodetool compressiondictionary list <keyspace> <table>`**
- Lists all dictionaries for the specified keyspace/table
- Shows columns from `CompressionDictionaryDetailsTabularData` (excluding the raw dictionary binary)

**`nodetool compressiondictionary export <keyspace> <table> <filepath> [-i <dictId>]`**
- Exports a dictionary to a local file in JSON format
- Without `-i`/`--id`, exports the current (latest) dictionary
- With `-i`/`--id`, exports a specific dictionary by ID (must be positive integer)

**`nodetool compressiondictionary import <filepath>`**
- Imports a dictionary from a JSON file (produced by `export`)
- The JSON is validated client-side before being sent to the node
- Should be run against one node at a time (dictionary stored in `system_distributed.compression_dictionaries`)

### Not in Cassandra 5.0

Neither `CompressionDictionaryCommandGroup.java` nor any `compressiondictionary` subcommand exists in the `cassandra-5.0` branch. The entire feature set (including `train`) is Cassandra 6 only (CEP-54).

### Source Evidence

- `src/java/org/apache/cassandra/tools/nodetool/CompressionDictionaryCommandGroup.java` -- All four subcommands (`train`, `list`, `export`, `import`)
- `src/java/org/apache/cassandra/tools/nodetool/NodetoolCommand.java` (line 211) -- Registers `CompressionDictionaryCommandGroup.class`
- `src/java/org/apache/cassandra/db/compression/CompressionDictionaryDetailsTabularData.java` -- Data structures for dictionary list/export/import

### CHANGES.txt Entry

> Add export, list, import sub-commands for nodetool compressiondictionary (CASSANDRA-20941)

## User-Facing Impact

- **Operators** can now list, export, and import ZSTD compression dictionaries via nodetool
- **Use case**: Export a dictionary from one cluster and import it into another, or back up dictionaries before changes
- **Import warning**: Importing sets the imported dictionary as the current dictionary without evaluation; should only be done against one node at a time

## Docs Impact Assessment

### Generated Docs (nodetool reference)

**Status: Partially covered by regeneration.**

The `gen-nodetool-docs.py` script runs `nodetool help <command>` for each command discovered from `nodetool help` output. Because `compressiondictionary` is a command group with subcommands (`train`, `list`, `export`, `import`), there is a question of whether the generator properly captures the subcommand help. The generator regex `command_re = re.compile("(    )([_a-z]+)")` will match `compressiondictionary` from the top-level help listing and generate a page for it. However, the subcommands may not get individual generated pages -- only the parent command's help text will be captured.

**Action needed**: Verify that `nodetool help compressiondictionary` outputs sufficient detail about all four subcommands. If it only shows the subcommand list without full syntax for each, the generated page may be incomplete and authored docs become the primary reference.

### Authored Docs

**Status: Already documented.**

The authored compression page (`doc/modules/cassandra/pages/managing/operating/compression.adoc`) already contains:

1. **Section "ZSTD Dictionary Compression"** (line 75+): Detailed explanation of dictionary compression, when to use it, training, auto-training
2. **Section "Available nodetool commands for compressiondictionary"** (line 427+): Lists all four subcommands (`train`, `list`, `export`, `import`) with descriptions
3. **Train subcommand parameters** (lines 437-440): Documents `--max-dict-size` and `--max-total-sample-size` overrides
4. **Import warning** (lines 442-444): Documents single-node import guidance

The authored docs appear complete for this feature. The `list` and `export` subcommand descriptions are brief (one-liners) but adequate for an overview page. Detailed syntax is expected from the generated nodetool reference.

## Open Questions

- Does the nodetool doc generator handle picocli command groups (parent + subcommands) correctly? The generator may produce a single `compressiondictionary.adoc` page but might not capture per-subcommand help unless `nodetool help compressiondictionary` output includes all subcommand details.
- The `export` command's `-i`/`--id` option for selecting a specific dictionary version is not mentioned in the authored docs.

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: compression.adoc
- Owner role: generated-doc-owner
- Publish blocker: no

## Status Recommendation

- **Generated docs**: Regenerate, then verify that the generated `compressiondictionary.adoc` page contains meaningful detail about all four subcommands. If the generator only captures the top-level group help, this is a gap.
- **Authored docs**: Already in good shape in `compression.adoc`. Minor enhancement opportunity: mention the `-i`/`--id` flag for `export`. Not blocking.
- **Overall**: Low risk. Primary authored docs already exist. Generated doc coverage for command groups should be validated.
