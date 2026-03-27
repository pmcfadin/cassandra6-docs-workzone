# CASSANDRA-17445 Nodetool migration from airline to picocli

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Summary
All nodetool commands have been migrated from the deprecated airlift/airline CLI framework to picocli. The migration was explicitly designed for backward compatibility: a custom `CassandraCliHelpLayout` class reproduces airline's help output format, command names are unchanged, and all option names (short and long forms) are preserved. The `gen-nodetool-docs.py` doc generation script was not modified, indicating the picocli help output is format-compatible with the existing doc generation pipeline. This is primarily an internal refactoring with no user-visible syntax changes by design, but the generated nodetool documentation should be regenerated and reviewed to confirm no formatting regressions.

## Discovery Source
- `NEWS.txt` reference: not checked (file not in sparse checkout)
- `CHANGES.txt` reference: "Migrate all nodetool commands from airline to picocli (CASSANDRA-17445)" listed under 6.0-alpha1
- Related JIRA: [CASSANDRA-17445](https://issues.apache.org/jira/browse/CASSANDRA-17445)
- Related PR: [apache/cassandra#2497](https://github.com/apache/cassandra/pull/2497) (493 files changed, +14946/-4062)
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: **Minimal by design.** Help output format is preserved via `CassandraCliHelpLayout`. Command names and option syntax are unchanged.
- Operational effect: No change to nodetool invocation syntax. Performance benchmarks show no regression (5.661s vs 5.654s for `nodetool status`).
- Upgrade or compatibility effect: Users upgrading from Cassandra 5.x should see identical nodetool command syntax. The `@CassandraUsage` annotation exists specifically to preserve backward-compatible argument formatting in help text.
- Configuration or tooling effect: The `gen-nodetool-docs.py` script parses `nodetool help` output using regex `(    )([_a-z]+)` to discover commands. The picocli help layout was designed to match this format, so doc generation should continue working.

## Source Evidence
- Relevant docs paths:
  - `doc/scripts/gen-nodetool-docs.py` -- nodetool doc generation script (unchanged)
  - `doc/Makefile` -- invokes gen-nodetool-docs.py via `make gen-asciidoc`
  - `doc/modules/cassandra/pages/managing/tools/nodetool/` -- generated output dir (not in repo, created at build time)
- Relevant config paths: none
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/NodeTool.java` -- main entry point, now uses picocli `CommandLine`
  - `src/java/org/apache/cassandra/tools/nodetool/NodetoolCommand.java` -- top-level `@Command` with all subcommands registered
  - `src/java/org/apache/cassandra/tools/nodetool/AbstractCommand.java` -- base class for all commands (replaces airline's `NodeToolCmd`)
  - `src/java/org/apache/cassandra/tools/nodetool/Help.java` -- custom help command with `printTopCommandUsage()` for airline-compatible format
  - `src/java/org/apache/cassandra/tools/nodetool/layout/CassandraCliHelpLayout.java` -- picocli `Help` subclass that replicates airline's help output format (width=88, same section headings: NAME, SYNOPSIS, OPTIONS, COMMANDS)
  - `src/java/org/apache/cassandra/tools/nodetool/layout/CassandraUsage.java` -- annotation for backward-compatible argument help text
  - 159 command classes annotated with picocli `@Command` in `src/java/org/apache/cassandra/tools/nodetool/`
- Relevant test paths: not examined in detail (493 files changed in the PR)
- Relevant generated-doc paths: `doc/modules/cassandra/examples/TEXT/NODETOOL/` (generated at build time)

## What Changed
1. **CLI framework replaced**: All 159+ nodetool commands migrated from airline `@Command`/`@Option`/`@Arguments` annotations to picocli `@Command`/`@Option`/`@Parameters` annotations.
2. **Help output format preserved**: `CassandraCliHelpLayout` extends picocli's `Help` class to reproduce airline's section format (NAME, SYNOPSIS, OPTIONS headings at width 88).
3. **Command names unchanged**: All commands retain their lowercase names (e.g., `status`, `compact`, `repair`, `compactionstats`).
4. **Option names unchanged**: Both short and long option forms preserved (e.g., `-r`/`--resolve-ip`, `-s`/`--split-output`).
5. **Argument validation approach**: For backward compatibility, most commands set picocli arity to `"0..*"` and validate arguments in the `execute()` method rather than at parse time (documented in `AbstractCommand` javadoc as legacy behavior).
6. **Subcommand groups**: Some commands now use picocli subcommand groups (e.g., `accord`, `cms`, `profile`, `bootstrap`, `compressiondictionary`, `consensusmigration`).
7. **Print-port option handling**: Special logic in `NodeTool` to support `--print-port` both before and after the subcommand name for backward compatibility.
8. **Known regression**: CASSANDRA-20805 filed for `PaxosSimulationRunner` returning help text instead of running (identified post-merge by Ariel Weisberg).

## Docs Impact
- Existing pages likely affected: All generated nodetool reference pages (created by `gen-nodetool-docs.py`). These are generated at build time, so the key concern is whether the generation script still parses picocli's help output correctly.
- New pages likely needed: None. No new user-facing commands were added as part of this migration.
- Audience home: Operators (nodetool reference), Contributors (internal architecture)
- Authored or generated: **Generated** -- nodetool docs are auto-generated from `nodetool help` output
- Technical review needed from: Maxim Muzafarov (author), build/doc team to run `make gen-asciidoc` and compare output

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: (generated nodetool docs)
- Owner role: generated-doc-owner
- Publish blocker: no

## Open Questions
- Has anyone run `make gen-asciidoc` against trunk post-merge to verify the generated nodetool docs are correct?
- Does the `command_re = re.compile("(    )([_a-z]+)")` regex in `gen-nodetool-docs.py` still match picocli's top-level help output format exactly? (The `CassandraCliHelpLayout` was designed to produce matching output, but this should be empirically verified.)
- Are there any subtle formatting differences in per-command help output (e.g., option descriptions, argument labels) that might affect the generated `.txt` files?
- Do the new subcommand groups (accord, cms, profile, bootstrap, compressiondictionary, consensusmigration) get correctly discovered and documented by the generation script, or does it only list top-level commands?

## Next Research Steps
- Run `make gen-asciidoc` on a full trunk build and diff the generated nodetool pages against the Cassandra 5.0 output
- Verify that subcommand groups (e.g., `nodetool accord describe`) are properly handled by the doc generation script
- Confirm CASSANDRA-20805 (PaxosSimulationRunner regression) has been resolved
- Spot-check a few command help outputs (e.g., `nodetool help status`, `nodetool help repair`) to verify identical formatting

## Notes
- The migration touched 493 files with +14,946/-4,062 lines -- one of the largest single changes in Cassandra 6.0.
- The `CassandraCliHelpLayout` class (364+ lines) is dedicated entirely to reproducing airline's help format in picocli, showing the team prioritized backward compatibility of help output.
- The `AbstractCommand` javadoc explicitly notes that argument validation is done in `execute()` rather than at picocli parse time for backward compatibility, but recommends new commands use picocli's built-in validation.
- Performance is unchanged: hyperfine benchmarks showed `nodetool status` at 5.661s (picocli) vs 5.654s (airline).
- Fix version: 6.0-alpha1 / 6.0
- Author: Maxim Muzafarov; Reviewers: Caleb Rackliffe, Dmitry Konstantinov, Stefan Miklosovic
