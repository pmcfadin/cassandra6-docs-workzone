# managing/tools Delta

## Scope

Path: `doc/modules/cassandra/pages/managing/tools/`
Compared: `origin/cassandra-5.0` vs `origin/trunk`

## Inventory Summary

| Metric | cassandra-5.0 | trunk |
|--------|--------------|-------|
| Page count | 16 | 16 |
| New pages | — | 0 |
| Removed pages | — | 0 |
| Modified pages | — | 3 |
| Unchanged pages | — | 13 |

Both branches carry the same sixteen files:
- `cqlsh.adoc`, `index.adoc`
- `sstable/index.adoc`, `sstabledump.adoc`, `sstableexpiredblockers.adoc`, `sstablelevelreset.adoc`, `sstableloader.adoc`, `sstablemetadata.adoc`, `sstableofflinerelevel.adoc`, `sstablepartitions.adoc`, `sstablerepairedset.adoc`, `sstablescrub.adoc`, `sstablesplit.adoc`, `sstableupgrade.adoc`, `sstableutil.adoc`, `sstableverify.adoc`

## Key Differences

1. **cqlsh gains `ELAPSED` command** — new section documenting elapsed-time display for CQL queries, complementary to `TRACING`.
2. **sstabledump gains `-o` tombstone-only flag** — new option and section documenting tombstone-only enumeration (CASSANDRA-19939).
3. **sstableloader SSL docs rewritten** — clarifies dual-port SSL (native vs internode/storage), replaces brief guidance with detailed explanation of when command-line SSL options vs `cassandra.yaml` config are needed.

## Page-Level Findings

### cqlsh.adoc — New section added
- **Delta type:** content addition (medium, ~29 new lines)
- New `=== ELAPSED` section inserted between `EXPAND` and `LOGIN`.
- Documents the `ELAPSED ON`/`ELAPSED OFF` toggle.
- Includes example output showing per-statement timing (e.g., `(6ms elapsed)`, `(510ms elapsed)`).
- Notes that ELAPSED complements TRACING by showing client-side latency vs server-side latency.

### sstable/sstabledump.adoc — New option and section
- **Delta type:** content addition (small-medium)
- Options table updated: new `-o` flag ("Enumerate tombstones only") added; options reordered alphabetically (`-l`, `-o`, `-t`, `-x`).
- New section "Dump tombstones only" added after the exclude-keys example, referencing CASSANDRA-19939.
- Describes the use case: filtering large output to find tombstones faster.

### sstable/sstableloader.adoc — Documentation rewrite
- **Delta type:** content rewrite (medium, ~25 lines replaced/expanded)
- All SSL option descriptions in the options table changed from "Client SSL:" to "Client SSL (for native connection):" to clarify they apply only to the native port connection.
- The "Use a Config File for SSL Clusters" section was significantly rewritten:
  - Old text: brief recommendation to use `--conf-path` for `server_encryption_options`.
  - New text: explains that sstableloader connects to both native and storage (internode) ports; documents when CLI SSL options suffice (native-only SSL) vs when `--conf-path` is required (both ports); notes CLI options override `cassandra.yaml` for native port only; clarifies that `require_client_auth` in `client_encryption_options` has no significance in this context.

### Unchanged pages (13)
`index.adoc`, `sstable/index.adoc`, and 11 sstable tool pages — identical on both branches.

## Apparent Coverage Gaps

- The `ELAPSED` section has a minor typo: "evalution" should be "evaluation".
- No example output is shown for the `-o` tombstone-only flag in `sstabledump.adoc`; the section describes the feature but does not include sample output as other options do.

## Generated-Doc Notes

- **nodetool pages** are referenced from `index.adoc` (`xref:cassandra:managing/tools/nodetool/nodetool.adoc[nodetool]`) but **no nodetool pages exist as committed files** on either branch under the `pages/` directory.
- Nodetool documentation is generated at build time by `doc/scripts/gen-nodetool-docs.py`, which outputs to `modules/cassandra/pages/managing/tools/nodetool/`. The script is **identical** on both branches (no diff).
- Since nodetool subcommands may have changed between Cassandra 5.0 and trunk (new commands, changed options, removed commands), the generated output will differ even though the generation script is the same. The delta must be assessed by running the generation script against each branch's binary and diffing the output.

## Recommended Follow-Up

1. **Generate and diff nodetool docs** — Run `gen-nodetool-docs.py` against both the 5.0 and trunk builds to identify new/changed/removed nodetool subcommands. This is the primary gap in this area.
2. **Fix typo** — "evalution" → "evaluation" in `cqlsh.adoc` ELAPSED section.
3. **Add sstabledump -o example** — Consider adding sample tombstone-only output to `sstabledump.adoc` for consistency with other options that include examples.
4. **Review sstableloader SSL guidance** — The rewritten SSL section is substantially improved; verify it aligns with the actual Cassandra 6 SSL configuration options and any changes to `client_encryption_options` / `server_encryption_options`.

## Notes

- The tools area is stable between branches — same page count, no structural changes.
- All three modifications are well-scoped: one new cqlsh command, one new sstable option, and one SSL documentation improvement.
- The biggest documentation risk in this area is the **nodetool generated surface**, which cannot be assessed by file diff alone and requires a build-time comparison.
