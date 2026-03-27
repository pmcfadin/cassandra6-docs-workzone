# CASSANDRA-18781: Bulk SSTable Loading Guardrail

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary

CASSANDRA-18781 adds a new `EnableFlag` guardrail, `bulk_load_enabled`, that allows operators to allow or disallow bulk loading of SSTables via tools like `sstableloader`. When set to `false`, any incoming bulk-load streaming session is aborted on the receiving node with a `GuardrailViolatedException`. The guardrail defaults to `true` (bulk loading allowed), preserving backward compatibility.

## Discovery Source

- `NEWS.txt` (5.0/trunk section): "New Guardrails added: Whether bulk loading of SSTables is allowed."
- `CHANGES.txt`: "Add the ability to disable bulk loading of SSTables (CASSANDRA-18781)"
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-18781
- Commit: 20d80118ac (2023-08-29), author Runtian Liu, reviewed by Stefan Miklosovic, Andres de la Pena, Brandon Williams

## Why It Matters

- **User-visible effect:** When disabled, `sstableloader` and other bulk-load tools will fail when attempting to stream SSTables to a node. The receiving node aborts the stream session.
- **Operational effect:** Operators can prevent uncontrolled bulk loads that may destabilize nodes through unexpected I/O, compaction pressure, or data integrity risks.
- **Upgrade or compatibility effect:** Default is `true` (enabled), so no behavioral change on upgrade. Operators must explicitly set `bulk_load_enabled: false` to activate the restriction.
- **Configuration or tooling effect:** One new `cassandra.yaml` setting; dynamically configurable via JMX (`GuardrailsMBean`).

## Source Evidence

- Relevant docs paths:
  - No existing guardrails documentation page found in `doc/` directory
  - No existing documentation covers this feature specifically

- Relevant config paths:
  - `conf/cassandra.yaml` (lines ~2320-2321):
    ```yaml
    # Guardrail to allow/disallow bulk load of SSTables
    # bulk_load_enabled: true
    ```

- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java`: Declares `public volatile boolean bulk_load_enabled = true;`
  - `src/java/org/apache/cassandra/config/GuardrailsOptions.java`: `getBulkLoadEnabled()` / `setBulkLoadEnabled()` methods
  - `src/java/org/apache/cassandra/db/guardrails/Guardrails.java`: Declares `bulkLoadEnabled` as an `EnableFlag` with message "Bulk loading of SSTables might potentially destabilize the node." and `.throwOnNullClientState(true)` (enforced even for internal/null-state operations)
  - `src/java/org/apache/cassandra/streaming/StreamDeserializingTask.java`: Enforcement point -- checks `Guardrails.bulkLoadEnabled.ensureEnabled(null)` when `session.getStreamOperation() == StreamOperation.BULK_LOAD`. On `GuardrailViolatedException`, logs a warning and aborts the message/session.
  - `src/java/org/apache/cassandra/db/guardrails/GuardrailsMBean.java`: JMX get/set for `bulkLoadEnabled`

- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailBulkLoadEnabledTest.java`

## What Changed

1. **New cassandra.yaml setting**: `bulk_load_enabled` (boolean, default `true`) in the guardrails section.
2. **Enforcement point**: `StreamDeserializingTask` checks the guardrail before processing each incoming bulk-load stream message. If disabled, the message is not processed and a warning is logged.
3. **Guardrail type**: `EnableFlag` -- binary allow/disallow with no warn threshold (either allowed or rejected).
4. **Null ClientState handling**: Uses `.throwOnNullClientState(true)`, meaning the guardrail is enforced even when there is no client session context (streaming operations do not have a traditional client state).
5. **JMX**: Dynamically configurable at runtime via `GuardrailsMBean`.

## Docs Impact

- Existing pages likely affected:
  - The `cassandra.yaml` configuration reference (generated) should document this setting
  - If a guardrails documentation page exists or is created for 6.0, it must cover this feature
  - Streaming/bulk-load operations documentation should reference this guardrail
- New pages likely needed:
  - A guardrails reference page (if not already planned) covering all guardrails
- Audience home: Operators
- Authored or generated: The cassandra.yaml reference is generated; any guardrails guide would be authored
- Technical review needed from: Runtian Liu (patch author), Stefan Miklosovic (reviewer)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

- Does the guardrail also block `nodetool import` or only `sstableloader`-based streaming? The enforcement is in `StreamDeserializingTask` for `StreamOperation.BULK_LOAD` -- need to verify which tools use that operation type.
- Is there a guardrails documentation page planned for Cassandra 6.0? Currently no `.adoc` file for guardrails exists in the `doc/` tree.
- Should the guardrails page document the `throwOnNullClientState` behavior, or is that an implementation detail?

## Notes

- The guardrail was introduced in the 5.0 development cycle (commit date 2023-08-29) and is present in trunk/6.0.
- The warning message when the guardrail fires is: "Bulk loading of SSTables might potentially destabilize the node."
- Unlike most guardrails which only apply to user queries (superusers/internal queries excluded), this guardrail applies to streaming operations with null client state, making it a cluster-wide hard block.
- Patch authored by Runtian Liu, reviewed by Stefan Miklosovic, Andres de la Pena, and Brandon Williams.
