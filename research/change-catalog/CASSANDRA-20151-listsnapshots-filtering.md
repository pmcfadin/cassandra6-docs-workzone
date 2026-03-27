# CASSANDRA-20151 Snapshot filtering on keyspace/table/name in listsnapshots

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-20151 adds three filter options to `nodetool listsnapshots`: `--keyspace` / `-k`, `--table` / `-t`, and `--snapshot` / `-n`. Previously, `listsnapshots` always returned all snapshots across all keyspaces and tables. Operators can now narrow output to snapshots belonging to a specific keyspace, table, or with a specific snapshot name. The options can be combined. The change is purely additive — existing invocations without the new flags continue to behave identically.

## Discovery Source
- `CHANGES.txt` reference (trunk): "Enable filtering of snapshots on keyspace, table and snapshot name in nodetool listsnapshots (CASSANDRA-20151)"
- Related JIRA: CASSANDRA-18111 (snapshot MBean — earlier snapshot management work)

## Why It Matters
- User-visible effect: Operators running `nodetool listsnapshots` on clusters with many keyspaces and tables can now filter output without post-processing. Especially useful in large clusters where snapshot output is very long.
- Operational effect: Reduces cognitive load when auditing snapshots for a specific keyspace or table. Useful in backup workflows where snapshots are taken per-keyspace.
- Upgrade or compatibility effect: No breaking changes. The three new flags are optional; no existing behavior changes when they are omitted.
- Configuration or tooling effect: No new cassandra.yaml configuration. Changes are exclusively at the `nodetool` CLI interface.

## Source Evidence
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/ListSnapshots.java` — `@Command(name = "listsnapshots")` class with three new `@Option` annotations:
    - `@Option(paramLabel = "keyspace", names = { "-k", "--keyspace" }, description = "Include snapshots of specified keyspace name")` — field `String keyspace`, default null
    - `@Option(paramLabel = "table", names = { "-t", "--table" }, description = "Include snapshots of specified table name")` — field `String table`, default null
    - `@Option(paramLabel = "snapshot", names = { "-n", "--snapshot" }, description = "Include snapshots of specified name")` — field `String snapshotName`, default null
  - The `execute()` method passes the three new options as entries in an `options` Map (keys `"keyspace"`, `"table"`, `"snapshot"`) to `probe.getSnapshotDetails(options)`. Options are only added to the map when non-null.
  - `src/java/org/apache/cassandra/service/snapshot/SnapshotManagerMBean.java` — updated to accept a filter map in `getSnapshotDetails(Map<String, String>)`.
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/test/SnapshotsTest.java` — updated (78 lines added) with test cases for keyspace, table, and snapshot-name filtering.
- Relevant docs paths:
  - `doc/modules/cassandra/examples/BASH/nodetool_list_snapshots.sh` — existing example script; does not use new flags; may want an updated example.
  - `doc/modules/cassandra/examples/RESULTS/nodetool_list_snapshots.result` — existing result file; unaffected by new flags.
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` — may contain a `listsnapshots` section.
  - Generated nodetool reference page for `listsnapshots` (via `gen-nodetool-docs.py`) — would pick up new flags automatically on regeneration.

## Commit Reference
- CASSANDRA-20151: commit `407dbacb0a` — "Enable filtering of snapshots on keyspace, table and snapshot name in nodetool listsnapshots"
  - Author: Stefan Miklosovic
  - Reviewed by: Jordan West, Bernardo Botella, Cheng Wang, Maxim Muzafarov
  - Date: 2024-12-18

## What Changed
1. `nodetool listsnapshots` accepts three new optional filter flags:
   - `-k`/`--keyspace <name>` — only list snapshots for the named keyspace
   - `-t`/`--table <name>` — only list snapshots for the named table
   - `-n`/`--snapshot <name>` — only list snapshots with the given snapshot name
2. Flags can be combined (e.g., `nodetool listsnapshots -k my_keyspace -n backup_20240101`).
3. Filter logic is delegated to `SnapshotManagerMBean.getSnapshotDetails(Map)` on the server side, so no client-side filtering is needed.
4. The existing `-nt`/`--no-ttl` and `-e`/`--ephemeral` flags are unchanged.

## Docs Impact
- Existing pages likely affected:
  - Generated nodetool reference for `listsnapshots` — needs regeneration to show new flags.
  - `use_nodetool.adoc` — if it describes `listsnapshots`, a note about filtering options should be added.
  - `doc/modules/cassandra/examples/BASH/nodetool_list_snapshots.sh` — could be updated to show filter usage, but it's a minor change.
- New pages likely needed: None.
- Audience home: Operators
- Authored or generated: Generated reference (option flags auto-documented); authored if any prose description of the command exists.
- Technical review needed from: Backup/snapshot domain expert

## Proposed Disposition
- Inventory classification: minor-update
- Affected docs: generated nodetool reference for `listsnapshots`; `use_nodetool.adoc` if it has a listsnapshots section
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Are the three new flags documented in any generated output currently committed to the repo (e.g., in a pre-generated nodetool help file)?
- Does `use_nodetool.adoc` have a listsnapshots section? If so, does it need examples updated to show the filtering options?
- Can `--table` be used without `--keyspace`? The source code adds both independently to the options map, suggesting yes, but a cross-keyspace table-name match may be surprising behavior. Worth noting in docs.

## Next Research Steps
- Audit `use_nodetool.adoc` for a listsnapshots entry.
- Run `gen-nodetool-docs.py` logic mentally for `listsnapshots` to confirm it would pick up the new `-k`, `-t`, `-n` flags.
- Verify server-side filtering behavior when both `--keyspace` and `--table` are specified — is it AND-logic?

## Notes
- Patch author: Stefan Miklosovic. Fix version: 6.0.
- The existing `nodetool_list_snapshots.sh` example file does not use any flags; it simply runs `nodetool listsnapshots`. A new example showing filtered output would be useful but is not strictly required for correctness.
- Related file `doc/modules/cassandra/examples/RESULTS/nodetool_snapshot_help.result` may contain the help text for the `snapshot` command (not `listsnapshots`); check whether a corresponding `listsnapshots_help.result` exists and needs updating.
