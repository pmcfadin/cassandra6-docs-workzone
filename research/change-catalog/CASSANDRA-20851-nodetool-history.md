# CASSANDRA-20851: Nodetool history command

## JIRA Summary

| Field | Value |
|-------|-------|
| JIRA | [CASSANDRA-20851](https://issues.apache.org/jira/browse/CASSANDRA-20851) |
| Title | Implement nodetool history command |
| Status | Resolved |
| Fix Version | 6.0-alpha1, 6.0 |
| Reporter | Stefan Miklosovic |
| Assignee | Stefan Miklosovic |
| Commit | `9c93d52ac9aa422dcc3c3d40cb090467ee02e953` |
| PR | [apache/cassandra#4323](https://github.com/apache/cassandra/pull/4323) |

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | generated-review |

## Change Description

This JIRA introduces a brand-new `nodetool history` command that displays previously executed nodetool commands from the local history file (`~/.cassandra/nodetool.history`).

### Command Syntax

```
nodetool history [-n <number>]
```

### Options

| Flag | Long form | Description | Default |
|------|-----------|-------------|---------|
| `-n` | `--num`, `--number-of-commands` | Number of commands to print | 1000 |

### Key Implementation Details

- **Offline command**: Does NOT connect to a Cassandra node (`shouldConnect()` returns `false`). Runs entirely client-side.
- **Reads from**: `~/.cassandra/nodetool.history` (same file that nodetool already appends commands to)
- **Behavior**: Reads the full history file, then returns the last N commands (default 1000)
- **Validation**: Checks that the history file exists, is a regular file, and is readable
- **Error handling**: Throws `IllegalArgumentException` if `-n` value is less than 1; throws `IllegalStateException` if history file is missing/unreadable
- **Performance**: Per the JIRA comments, reads of up to 400K lines (28 MB) complete in ~0.8 seconds

### Not in Cassandra 5.0

`History.java` does not exist in the `cassandra-5.0` branch. This is a Cassandra 6-only feature. The history file mechanism (`~/.cassandra/nodetool.history`) itself has existed since the nodetool interactive shell, but there was no dedicated command to display it.

### Source Evidence

- `src/java/org/apache/cassandra/tools/nodetool/History.java` -- Full implementation
- `src/java/org/apache/cassandra/tools/nodetool/NodetoolCommand.java` (line 131) -- Registers `History.class`
- `src/java/org/apache/cassandra/tools/NodeTool.java` (line 149) -- `getHistoryFile()` returns the history file path

### CHANGES.txt Entry

> Implement nodetool history (CASSANDRA-20851)

## User-Facing Impact

- **Operators** can now run `nodetool history` to see recently executed nodetool commands without manually inspecting `~/.cassandra/nodetool.history`
- **Operators** can use `-n` to control how many recent commands to display
- **No server connection required**: Works even when the Cassandra node is down
- **Convenience feature**: No behavior change to existing commands; purely additive

## Docs Impact Assessment

### Generated Docs (nodetool reference)

**Status: Automatically covered by regeneration.**

The `gen-nodetool-docs.py` script will discover `history` from `nodetool help` output and generate:
- `doc/modules/cassandra/pages/managing/tools/nodetool/history.adoc` -- reference page
- `doc/modules/cassandra/examples/TEXT/NODETOOL/history.txt` -- help text

The generated page will include the command description ("Print previously executed nodetool commands") and the `-n` option with its description. No manual intervention needed.

### Authored Docs

**Status: No authored docs exist. Low priority to add.**

- No current authored doc page mentions `nodetool history`
- The troubleshooting page (`use_nodetool.adoc`) discusses various nodetool commands but does not reference the history feature
- This is a simple convenience command. The generated reference page provides adequate coverage.
- An optional enhancement would be to mention `nodetool history` in a "Getting Started with nodetool" or troubleshooting context, but this is not required for completeness.

## Open Questions

- The history file (`~/.cassandra/nodetool.history`) location is hardcoded via `NodeTool.getHistoryFile()`. Is this path configurable? The implementation suggests it is not -- it uses the fixed `CASSANDRA_HOME/.cassandra/` directory. This could be worth noting in docs.
- Related JIRA CASSANDRA-20876 (offline nodetool command help) may affect how `history` is categorized in the docs (as an offline/client-side command).

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: (generated nodetool docs)
- Owner role: generated-doc-owner
- Publish blocker: no

## Status Recommendation

- **Generated docs**: Regenerate. The new `history` command will automatically appear in the generated nodetool reference.
- **Authored docs**: No action required. The generated reference page is sufficient for this simple command. Optional: mention in troubleshooting or getting-started guides.
- **Overall**: No doc blocker. Fully covered by standard nodetool doc regeneration.
