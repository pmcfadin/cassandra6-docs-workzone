# CASSANDRA-19809 use_deterministic_table_id Deprecation

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
The `use_deterministic_table_id` configuration property in `cassandra.yaml` has been deprecated and is now ignored. When set to `true`, Cassandra 6.0 logs a warning: "use_deterministic_table_id is no longer supported and should be removed from cassandra.yaml." The property still exists in `Config.java` (annotated `@Deprecated(since = "5.0.1")`) but has no functional effect. It has been removed from the default `cassandra.yaml` on trunk. Operators upgrading should remove this setting from their configuration files.

## Discovery Source
- `NEWS.txt` reference: "use_deterministic_table_id is no longer supported and should be removed from cassandra.yaml."
- `CHANGES.txt` reference: `* Deprecate and ignore use_deterministic_table_id (CASSANDRA-19809)` (present in trunk CHANGES.txt)
- Related JIRA: CASSANDRA-19809
- Related CEP or design doc: None

## Why It Matters
- User-visible effect: None. The property had a narrow use case (deterministic table IDs for testing/tooling) and ignoring it does not change runtime behavior for production clusters.
- Operational effect: Minor. Operators with `use_deterministic_table_id: true` in their cassandra.yaml will see a warning in logs on startup. The setting should be removed to clean up configuration.
- Upgrade or compatibility effect: Low risk. The property is silently ignored (with a warning log). No functional breakage occurs if it remains in the config file. However, it may eventually be fully removed in a future major version, which would cause a startup parse error.
- Configuration or tooling effect: The property should be removed from any cassandra.yaml templates, Ansible/Chef/Puppet configurations, or documentation that references it.

## Source Evidence
- Relevant docs paths: Any cassandra.yaml reference documentation
- Relevant config paths:
  - `conf/cassandra.yaml` on trunk: property is absent (removed from default config)
  - `conf/cassandra.yaml` on cassandra-5.0: property was still present (confirmed absent on trunk)
  - `src/java/org/apache/cassandra/config/Config.java` line 135: `@Deprecated(since = "5.0.1") public volatile boolean use_deterministic_table_id = false;`
  - `src/java/org/apache/cassandra/config/DatabaseDescriptor.java` lines 1238-1239: warning log if property is set to true
- Relevant code paths:
  - Commit `7903ce27` by Caleb Rackliffe, reviewed by David Capwell
  - Merge commit `f95c1b5b` merging cassandra-5.0 into trunk
- Relevant test paths:
  - `test/data/config/version=4.1-alpha1.yml`, `version=5.0-alpha1.yml`, `version=6.0-alpha1.yml` (test configs referencing the property)
  - `test/simulator/main/org/apache/cassandra/simulator/ClusterSimulation.java`
- Relevant generated-doc paths: None identified

## What Changed
1. **Property deprecated** -- `use_deterministic_table_id` is annotated `@Deprecated(since = "5.0.1")` in `Config.java`.
2. **Property ignored at runtime** -- When set to `true`, a warning is logged but the value has no effect on table ID generation.
3. **Removed from default cassandra.yaml** -- The property no longer appears in the shipped `conf/cassandra.yaml` on trunk.
4. **Warning message on startup** -- `DatabaseDescriptor` logs: "use_deterministic_table_id is no longer supported and should be removed from cassandra.yaml."

## Docs Impact
- Existing pages likely affected:
  - cassandra.yaml reference/configuration documentation (remove or mark deprecated)
  - Any upgrade guide should mention removing this property
- New pages likely needed: None
- Audience home: Operators (managing/configuration)
- Authored or generated: Could be generated-review (if cassandra.yaml docs are auto-generated from config) or minor authored update
- Technical review needed from: Caleb Rackliffe (patch author)

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: cass_yaml_file.adoc
- Owner role: generated-doc-owner
- Publish blocker: no

## Open Questions
- Will `use_deterministic_table_id` be fully removed (not just deprecated) in a future version, causing YAML parse failures for users who did not clean up?
- Are there any downstream tools or test frameworks that relied on deterministic table IDs that need updated documentation?

## Next Research Steps
- Check if cassandra.yaml reference docs are auto-generated and whether this property will be automatically excluded
- Verify the property is also absent from any Docker/Kubernetes default config templates in the repo
- Confirm the deprecation version annotation (`since = "5.0.1"`) is accurate -- the JIRA was merged to cassandra-5.0 branch

## Notes
- The original commit message is terse: "Deprecate and ignore use_deterministic_table_id". The property was originally introduced to enable deterministic (reproducible) table UUIDs, primarily useful for testing scenarios.
- The deprecation annotation says `since = "5.0.1"` but the change landed via merge into trunk for Cassandra 6.0. It may have been backported to a 5.0.x patch release as well.
- The property default is `false`, so most production deployments would never have set it. The primary audience for this deprecation notice is operators or tool authors who explicitly enabled it.
- NEWS.txt wording ("is no longer supported and should be removed") matches the warning log message exactly.
