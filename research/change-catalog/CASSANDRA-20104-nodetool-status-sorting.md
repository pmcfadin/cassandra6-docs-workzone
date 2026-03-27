# CASSANDRA-20104 Sorting of nodetool status output

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-20104 adds two new options to `nodetool status` that let operators sort the output by a chosen column and control sort order. Previously, node rows were displayed in a fixed default order (by token or host ID). With this change, operators can pass `-s`/`--sort` with a sort key (`ip`, `host`, `load`, `owns`, `id`, `rack`, `state`, or `token`) and optionally `-o`/`--order` (`asc` or `desc`) to control ascending or descending order. Default sort directions per key match intuitive ordering (e.g., `load` and `owns` default to descending; `ip`, `id`, `token`, `rack` default to ascending).

## Discovery Source
- `CHANGES.txt` reference (trunk): "Enable sorting of nodetool status output (CASSANDRA-20104)"
- Related JIRA: None identified

## Why It Matters
- User-visible effect: Operators can quickly identify the nodes with the highest load or lowest ownership percentage by sorting the `nodetool status` output instead of reading through all rows.
- Operational effect: Useful for capacity planning, identifying hot nodes, and cross-checking ring balance. Sorting by `state` makes it easier to see all DOWN or joining nodes grouped together.
- Upgrade or compatibility effect: No breaking changes. Existing invocations without `-s` produce the same default output. The vnodes vs. single-token default sort behavior is preserved: single-token clusters default to sort by `token`; vnode clusters default to sort by `id`.
- Configuration or tooling effect: No new cassandra.yaml configuration. Changes are at the `nodetool` CLI interface only.

## Source Evidence
- Relevant code paths:
  - `src/java/org/apache/cassandra/tools/nodetool/Status.java` — `@Command(name = "status")` class with two new `@Option` annotations:
    - `@Option(paramLabel = "sort", names = { "-s", "--sort" }, description = "Sort by one of 'ip', 'host', 'load', 'owns', 'id', 'rack', 'state' or 'token'. Default ordering is ascending for 'ip', 'host', 'id', 'token', 'rack' and descending for 'load', 'owns', 'state'. Sorting by token is possible only when cluster does not use vnodes. When using vnodes, default sorting is by id otherwise by token.")` — field `SortBy sortBy`, default null
    - `@Option(paramLabel = "sort_order", names = { "-o", "--order" }, description = "Sorting order: 'asc' for ascending, 'desc' for descending.")` — field `SortOrder sortOrder`, default null
  - `enum SortOrder` (line 260) — values: `asc`, `desc`
  - `enum SortBy` (line 266) — values with default descending flag: `state` (desc), `ip` (asc), `host` (asc), `load` (desc), `owns` (desc), `id` (asc), `token` (asc), `rack` (asc)
  - Each `SortBy` value implements `sort(Map<String, List<Object>> data)` using a corresponding `compareByX()` method.
  - Guard: sorting by `token` is rejected with `IllegalArgumentException` when the cluster uses vnodes (i.e., `!isTokenPerNode`). Sorting by `host` is rejected when `-r`/`--resolve-ip` is not set.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/tools/nodetool/test/AbstractNodetoolStatusTest.java` — base class with 339 lines of sort-related test logic (added by this JIRA)
  - `test/unit/org/apache/cassandra/tools/nodetool/test/NodeToolStatusWithVNodesTest.java` — 62 lines; tests sort behavior with vnodes
  - `test/unit/org/apache/cassandra/tools/nodetool/test/NodetoolStatusWithoutVNodesTest.java` — 61 lines; tests sort behavior without vnodes
- Relevant docs paths:
  - `doc/modules/cassandra/examples/BASH/nodetool_status.sh` — existing example; does not use new sort flags.
  - `doc/modules/cassandra/examples/BASH/nodetool_status_nobin.sh` — existing example; does not use new sort flags.
  - `doc/modules/cassandra/examples/RESULTS/` — no nodetool_status result files found; examples are BASH-only.
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` — likely contains a `nodetool status` section; may need mention of new sort flags.
  - Generated nodetool reference page for `status` (via `gen-nodetool-docs.py`) — would pick up new flags automatically on regeneration.

## Commit Reference
- CASSANDRA-20104: commit `22af7a74cc` — "Enable sorting of nodetool status output"
  - Author: Manish Pillai, co-authored Stefan Miklosovic
  - Reviewed by: Stefan Miklosovic, Bernardo Botella, Jordan West
  - Date: 2024-12-13

## What Changed
1. `nodetool status` accepts two new optional flags:
   - `-s`/`--sort <key>` — sort rows by: `ip`, `host`, `load`, `owns`, `id`, `rack`, `state`, or `token`
   - `-o`/`--order <asc|desc>` — override the default sort direction
2. Default sort directions per key:
   - Ascending by default: `ip`, `host`, `id`, `token`, `rack`
   - Descending by default: `load`, `owns`, `state`
3. Constraints:
   - `--sort token` requires a single-token-per-node cluster (not vnodes); an error is thrown otherwise
   - `--sort host` requires `-r`/`--resolve-ip` to be set; an error is thrown otherwise
4. When `-s` is not specified: existing default behavior is preserved (vnode clusters sort by `id`; single-token clusters sort by `token`).
5. The sort operates on the per-DC node list before printing; DC grouping is preserved.

## Docs Impact
- Existing pages likely affected:
  - Generated nodetool reference for `status` — needs regeneration to show new `-s` and `-o` flags.
  - `use_nodetool.adoc` — a note or example showing sort usage would be helpful for operators.
  - `nodetool_status.sh` example could optionally be updated to demonstrate `-s load` for finding hot nodes.
- New pages likely needed: None.
- Audience home: Operators
- Authored or generated: Generated reference (flags auto-documented); authored prose if the status command has its own section in `use_nodetool.adoc`.
- Technical review needed from: None specific; this is a UI-layer change.

## Proposed Disposition
- Inventory classification: minor-update
- Affected docs: generated nodetool reference for `status`; `use_nodetool.adoc` if it has a status section
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Does the sort apply within each DC section independently, or across the whole cluster output? The code uses `SortedMap<String, SetHostStatWithPort> dcs` which groups by DC — inference is that sort is within each DC. Should be verified and documented clearly.
- When `-o` is specified but `-s` is not, does the order flag apply to the default sort key, or is it ignored?
- Is the `--sort state` value documented anywhere regarding the state ordering (e.g., is UP before DOWN or vice versa)?

## Next Research Steps
- Audit `use_nodetool.adoc` for a `nodetool status` section to assess whether new flag documentation is needed there.
- Verify whether sort applies per-DC or globally by reading `Status.java` execute() method more carefully around the `dcs` SortedMap.
- Confirm whether `gen-nodetool-docs.py` would produce separate help output for the `status` command that shows `-s` and `-o`.

## Notes
- Author: Manish Pillai (manish-m-pillai on GitHub), co-authored Stefan Miklosovic. Fix version: 6.0.
- The `Status.java` file increased from roughly 130 lines to over 380 lines in this commit — the sort logic is non-trivial.
- The error messages for invalid sort combinations are printed to `errOut` (stderr) and cause `IllegalArgumentException` to be thrown — this is consistent with other picocli validation errors in the nodetool codebase.
- The `host` sort key only makes sense when `-r`/`--resolve-ip` is active because the host field is otherwise empty. The code enforces this constraint.
