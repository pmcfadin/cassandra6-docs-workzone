# CASSANDRA-20913: DDL Guardrail for Keyspace Properties (durable_writes)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

**Note:** An earlier research file `allowed-keyspace-properties-guardrail.md` covered the same JIRA and has been merged into this canonical file (2026-03-25).

## Summary

CASSANDRA-20913 adds a `Values<String>` guardrail for keyspace properties, enabling operators to warn about, silently ignore, or disallow specific properties when creating or altering keyspaces. The primary motivation is preventing `durable_writes = false` on keyspaces (which disables the commitlog and risks data loss), but the implementation is generic and supports any keyspace property name. Three new `cassandra.yaml` settings are introduced: `keyspace_properties_warned`, `keyspace_properties_ignored`, and `keyspace_properties_disallowed`. This mirrors the existing `table_properties` guardrail pattern.

## Discovery Source

- `NEWS.txt` (6.0 section): "New Guardrails added: ... Allowed keyspace properties."
- `CHANGES.txt`: "Add DDL Guardrail enabling administrators to disallow creation/modification of keyspaces with durable_writes = false (CASSANDRA-20913)"
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-20913
- Commit: 61959e215c (2025-09-26), author Aparna Naik, reviewed by Caleb Rackliffe and Stefan Miklosovic

## Why It Matters

- **User-visible effect:** `CREATE KEYSPACE` and `ALTER KEYSPACE` statements may now warn, silently strip properties, or fail depending on guardrail configuration.
- **Operational effect:** Operators can enforce cluster-wide policies on keyspace properties. The canonical use case is preventing `durable_writes = false`, which disables the commitlog and risks data loss on crash.
- **Upgrade or compatibility effect:** Default configuration is empty sets for all three levels, so no behavioral change on upgrade. Operators must explicitly opt in.
- **Configuration or tooling effect:** Three new `cassandra.yaml` guardrail settings; dynamically configurable via JMX (`GuardrailsMBean` exposes get/set methods with both `Set<String>` and CSV variants).

## Source Evidence

- Relevant docs paths:
  - No existing guardrails documentation page in `doc/` directory
  - No existing documentation covers this feature

- Relevant config paths:
  - `conf/cassandra.yaml`:
    ```yaml
    # Guardrail to warn about, ignore or reject properties when creating or modifying keyspaces.
    # By default all properties are allowed.
    # keyspace_properties_warned: []
    # keyspace_properties_ignored: []
    # keyspace_properties_disallowed: []
    ```

- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java`: Declares `keyspace_properties_warned`, `keyspace_properties_ignored`, `keyspace_properties_disallowed` as `volatile Set<String>` defaulting to `Collections.emptySet()`
  - `src/java/org/apache/cassandra/config/GuardrailsOptions.java`: Getter/setter methods for all three levels, plus `validateKeyspaceProperties()` which lowercases input, rejects null values, rejects required keywords (from `KeyspaceAttributes.requiredKeywords()` -- i.e., `replication`), and validates against `KeyspaceAttributes.allKeywords()`
  - `src/java/org/apache/cassandra/db/guardrails/Guardrails.java`: Declares `keyspaceProperties` as `Values<String>` guardrail with warned/ignored/disallowed providers
  - `src/java/org/apache/cassandra/cql3/statements/schema/CreateKeyspaceStatement.java`: Calls `Guardrails.keyspaceProperties.guard(attrs.updatedProperties(), attrs::removeProperty, state)` during validation
  - `src/java/org/apache/cassandra/cql3/statements/schema/AlterKeyspaceStatement.java`: Same guardrail check added in `validate()` method
  - `src/java/org/apache/cassandra/cql3/statements/schema/KeyspaceAttributes.java`: New `allKeywords()` and `requiredKeywords()` static methods to support validation. Required keywords = `{replication}`.

- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailKeyspacePropertiesTest.java`: Tests CREATE/ALTER with warned, ignored, and disallowed properties; tests `durable_writes` as primary property; verifies disallowed takes precedence over warned; tests config validation.
  - `test/unit/org/apache/cassandra/tools/nodetool/GuardrailsConfigCommandsTest.java`: Tests nodetool configuration commands for guardrails

## What Changed

1. **Three new cassandra.yaml settings** under the guardrails section:
   - `keyspace_properties_warned`: Set of property names that trigger a client warning when used in CREATE/ALTER KEYSPACE
   - `keyspace_properties_ignored`: Set of property names that are silently stripped from CREATE/ALTER KEYSPACE statements
   - `keyspace_properties_disallowed`: Set of property names that cause CREATE/ALTER KEYSPACE to fail
2. **Validation rules**: Properties are lowercased; required keyspace keywords (like `replication`) cannot be disallowed or ignored; only recognized `KeyspaceAttributes.allKeywords()` values are accepted in configuration.
3. **Precedence**: Disallowed takes precedence over warned if a property appears in both sets.
4. **JMX/nodetool**: All three settings are dynamically configurable at runtime via JMX, with both `Set<String>` and CSV accessors.
5. **Design pattern**: Follows the same `Values<T>` guardrail pattern as the existing `table_properties_warned/ignored/disallowed` guardrail, placed immediately after it in `cassandra.yaml`.

## Docs Impact

- Existing pages likely affected:
  - The `cassandra.yaml` configuration reference should document the three new settings
  - If a guardrails documentation page exists or is created, it must cover this feature
  - CQL reference for CREATE KEYSPACE / ALTER KEYSPACE should note guardrail interaction
- New pages likely needed:
  - A guardrails reference page (if not already planned) covering all guardrails
- Audience home: Operators
- Authored or generated: Authored (no generated-doc pipeline for guardrails)
- Technical review needed from: Aparna Naik (patch author), Caleb Rackliffe or Stefan Miklosovic (reviewers)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

- What are the complete set of valid keyspace property names from `KeyspaceAttributes.allKeywords()`? The test uses `durable_writes` and `replication`, but the full list should be documented.
- Can `replication` be set as warned (to generate a warning) even though it cannot be disallowed/ignored (since it is a required keyword)?
- Should the documentation show a worked example of disallowing `durable_writes`, given that is the JIRA's primary use case?
- Are the existing `table_properties_warned/ignored/disallowed` guardrails documented anywhere? If so, the keyspace properties guardrail docs should follow the same pattern.

## Notes

- The commit message frames the feature narrowly around `durable_writes = false`, but the implementation is generic and supports any keyspace property name.
- The YAML comment says "By default all properties are allowed," which is accurate since all three sets default to empty.
- This is a Cassandra 6.0 feature (commit date 2025-09-26).
- An earlier research file `allowed-keyspace-properties-guardrail.md` in this directory covered the same JIRA with compatible findings and has been merged into this file.
- Next research steps (from merged file): Review `KeyspaceAttributes` class for full list of valid property names; check if guardrails documentation page is planned for 6.0; compare with existing table properties guardrail docs; verify dynamic reconfiguration via nodetool; check `GuardrailsMBean` interface for exact JMX method signatures.
