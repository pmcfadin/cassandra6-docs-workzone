# CASSANDRA-19532 TriggersPolicy to allow operators to disable triggers

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-19532 introduces a `triggers_policy` configuration setting in `cassandra.yaml` that gives operators cluster-level control over whether CQL triggers are permitted to execute. The new setting has three values: `enabled` (default — triggers run normally), `disabled` (trigger logic is skipped and a warning is logged, but the underlying mutation still proceeds), and `forbidden` (any CQL statement that would invoke a trigger throws a `TriggerDisabledException` and the query fails). This addresses a security and operational concern: Cassandra triggers can run arbitrary Java code loaded from disk, and operators previously had no way to prevent trigger execution cluster-wide without removing triggers from the schema.

## Discovery Source
- `CHANGES.txt` reference: "Add new TriggersPolicy configuration to allow operators to disable triggers (CASSANDRA-19532)"
- Related JIRA: CASSANDRA-19532
- Related CEP or design doc: None identified

## Why It Matters
- User-visible effect: Developers or administrators who have defined triggers will see changed behavior if operators set `triggers_policy` to `disabled` or `forbidden`. `disabled` silently skips trigger logic; `forbidden` surfaces as a query error.
- Operational effect: Gives operators a safety valve to prevent arbitrary code execution via triggers without requiring schema changes. Useful for security-hardening shared cluster environments.
- Upgrade or compatibility effect: Default is `enabled`, which preserves existing behavior. No upgrade action required unless operators wish to restrict trigger execution.
- Configuration or tooling effect: New `triggers_policy` key in `cassandra.yaml` and `cassandra_latest.yaml`. The triggers documentation page already references this setting (the update shipped with the code change).

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/triggers.adoc` — updated in the same commit to describe `triggers_policy` and its three values
- Relevant config paths:
  - `conf/cassandra.yaml`: `triggers_policy: enabled` (with inline comment describing `disabled` and `forbidden` modes)
  - `conf/cassandra_latest.yaml`: `triggers_policy: enabled`
- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java` — defines `TriggersPolicy` enum (`enabled`, `disabled`, `forbidden`) and `public TriggersPolicy triggers_policy = TriggersPolicy.enabled`
  - `src/java/org/apache/cassandra/config/DatabaseDescriptor.java` — exposes getter for `triggers_policy`
  - `src/java/org/apache/cassandra/cql3/statements/schema/CreateTriggerStatement.java` — checks policy at trigger creation time
  - `src/java/org/apache/cassandra/triggers/TriggerExecutor.java` — checks policy at trigger execution time; skips or throws based on policy
  - `src/java/org/apache/cassandra/triggers/TriggerDisabledException.java` — new exception class thrown when policy is `forbidden`
- Relevant test paths:
  - `test/unit/org/apache/cassandra/triggers/TriggersTest.java` — tests all three policy values
  - `test/unit/org/apache/cassandra/config/DatabaseDescriptorRefTest.java` — config reflection test

## What Changed
1. **New `triggers_policy` YAML setting** with three values:
   - `enabled` (default): Triggers execute normally.
   - `disabled`: Trigger execution is skipped; the mutation continues and a WARN-level log entry is emitted.
   - `forbidden`: Any statement that would invoke a trigger fails with `TriggerDisabledException`.
2. **`TriggerDisabledException`** is a new exception class thrown when `triggers_policy = forbidden`.
3. **`triggers.adoc` updated** to document the three-value policy in the existing triggers reference page (update included in the same commit as the code change).

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/triggers.adoc` — already updated in the commit to describe `triggers_policy`; content should be reviewed for completeness and accuracy before publish.
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated from YAML; will reflect the new `triggers_policy` setting once regenerated.
- New pages likely needed: None.
- Audience home: Operators (for the policy setting) and Developers (for the CQL triggers reference).
- Authored or generated: `triggers.adoc` is authored content. The YAML reference page is generated.
- Technical review needed from: None identified; change is straightforward.

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead
- Publish blocker: no

## Open Questions
- Does the `TriggerDisabledException` error message surface to the CQL client as a specific error code, or as a generic server error? If it has a distinct client-visible message, the triggers page should quote it.
- Can `triggers_policy` be changed at runtime (e.g., via `nodetool` or JMX) or only at startup? Source review does not show any live-reload mechanism; likely restart-only — should be confirmed.
- Should the security/configuration pages reference `triggers_policy` as a hardening option?

## Next Research Steps
- Check `TriggerDisabledException` for the client-visible error message text.
- Confirm whether `triggers_policy` is hot-reloadable.
- Review `triggers.adoc` in its current trunk state to verify the documentation is complete and accurate.

## Notes
- Commit: `8d705b31e9` (trunk), author Abe Ratnofsky, April 4 2024.
- Reviewers: Stefan Miklosovic, Sam Tunnicliffe.
- The inline YAML comment reads: "`disabled` executes queries but skips trigger execution, and logs a warning. `forbidden` fails queries that would execute triggers with TriggerDisabledException."
- The documentation update was included directly in the code commit — this is an unusual positive exception to the typical separation of code and docs work.
