# CASSANDRA-20749 Override arbitrary cassandra.yaml settings via environment variables

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
CASSANDRA-20749 adds the ability to override any `cassandra.yaml` setting using environment variables. When enabled, Cassandra reads variables with the prefix `CASSANDRA_SETTINGS_` at startup and merges them into the loaded configuration, with the environment-derived values taking effect after the YAML file is parsed. Nested settings use `__` (double underscore) as a separator, and complex (structured) values must be passed as JSON strings. The feature is opt-in: it must be activated via the JVM system property `-Dcassandra.config.allow_environment_variables=true` or by setting the environment variable `CASSANDRA_ALLOW_CONFIG_ENVIRONMENT_VARIABLES=true`.

## Discovery Source
- `CHANGES.txt` reference: "Allow overriding arbitrary settings via environment variables (CASSANDRA-20749)"
- Related JIRA: CASSANDRA-20749
- Related CEP or design doc: None identified

## Why It Matters
- User-visible effect: Operators can now supply per-deployment configuration values (e.g., listen addresses, ports, tuning knobs) via the environment rather than modifying `cassandra.yaml`. This is especially useful in containerized environments (Docker, Kubernetes) where injecting environment variables is simpler than mounting config files.
- Operational effect: Reduces the need to bake environment-specific settings into config files at image build time. Allows twelve-factor-style configuration management for Cassandra.
- Upgrade or compatibility effect: The feature is disabled by default (`cassandra.config.allow_environment_variables` defaults to `false`). Existing deployments are unaffected unless the property or env var is explicitly set.
- Configuration or tooling effect: Adds a new documented section to `conf/jvm-server.options` explaining the feature and its env var naming conventions. When enabled, Cassandra emits a WARN log for each YAML property overridden by an environment variable.

## Source Evidence
- Relevant docs paths:
  - `conf/jvm-server.options` — new block documenting `CASSANDRA_SETTINGS_*` naming convention (source of record for this feature)
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated; does not currently describe the env-var override feature
- Relevant config paths:
  - `conf/jvm-server.options`: `-Dcassandra.config.allow_environment_variables=true` (commented out by default)
- Relevant code paths:
  - `src/java/org/apache/cassandra/config/YamlConfigurationLoader.java` — implements `maybeAddEnvironmentVariables()`. Constants: `ENVIRONMENT_VARIABLE_PREFIX = "CASSANDRA_SETTINGS_"`, `NESTED_CONFIG_SEPARATOR_ENVIRONMENT = "__"`, `SYSTEM_PROPERTY_PREFIX = "cassandra.settings."`. Overridable config names are determined from the full flattened `Config.class` property tree.
  - `src/java/org/apache/cassandra/config/CassandraRelevantEnv.java` — adds `CASSANDRA_ALLOW_CONFIG_ENVIRONMENT_VARIABLES` enum constant for the activating environment variable.
  - `src/java/org/apache/cassandra/config/CassandraRelevantProperties.java` — adds `CONFIG_ALLOW_ENVIRONMENT_VARIABLES("cassandra.config.allow_environment_variables")` system property constant.
  - `src/java/org/apache/cassandra/config/Properties.java` — updated to support flattened property lookup.
  - `src/java/org/apache/cassandra/config/DatabaseDescriptor.java` — calls `maybeAddEnvironmentVariables` during config load.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/config/YamlConfigurationLoaderTest.java` — comprehensive unit tests for scalar, nested, and JSON-complex overrides
  - `test/distributed/org/apache/cassandra/distributed/shared/WithEnvironment.java` — helper for setting environment variables in distributed tests

## What Changed
1. **New feature: environment variable config overrides.** Any `cassandra.yaml` top-level or nested property can be overridden at startup via `CASSANDRA_SETTINGS_<PROPERTY_NAME>=<value>` (env var form) or `-Dcassandra.settings.<property_name>=<value>` (system property form).
2. **Naming rules:**
   - Env var name: uppercase, prefix `CASSANDRA_SETTINGS_`, nested separators become `__`. Example: `CASSANDRA_SETTINGS_CDC_ENABLED=true`.
   - Nested property example: `CASSANDRA_SETTINGS_REPLICA_FILTERING_PROTECTION__CACHED_ROWS_WARN_THRESHOLD=1000`.
   - Complex (structured) values must be JSON strings: `CASSANDRA_SETTINGS_TABLE_PROPERTIES_WARNED='["bloom_filter_fp_chance", "default_time_to_live"]'`.
3. **Activation:** The system property takes precedence over the env var when both are set. Neither is on by default.
4. **Logging:** Each override generates a WARN-level log entry: `"Detected environment variable <VAR>=<value> override for Cassandra configuration '<key>'"`.
5. **Documentation in jvm-server.options:** A new comment block explains all of the above and shows examples.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — currently has no mention of env-var overrides; a new subsection should be added describing the feature, naming rules, and activation.
  - `doc/modules/cassandra/pages/managing/operating/` — the operations/configuration landing area may need a cross-reference or tips section for container deployments.
- New pages likely needed: Possibly a short how-to page for container/Kubernetes configuration patterns, but the minimum requirement is a subsection in the existing config file page.
- Audience home: Operators
- Authored or generated: The `cass_yaml_file.adoc` page is authored content (not generated from YAML). A new subsection can be added directly there.
- Technical review needed from: Config/startup subsystem maintainers (Paulo Motta, Stefan Miklosovic)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `major-update`
- Recommended owner role: docs-lead with operator focus
- Publish blocker: no

## Open Questions
- Does system-property override (`cassandra.settings.*`) pre-date this JIRA (i.e., was it already documented somewhere)? If so, the new env-var mechanism should be introduced alongside the existing system-property mechanism as a sibling feature.
- What is the precedence order when all three sources are present: YAML file, system property, and env var? (From source review: env vars are applied first, then system properties, so system properties take final precedence — needs confirmation from tests.)
- Should the generated `cass_yaml_file.adoc` note that any setting shown there can be overridden via env var?

## Next Research Steps
- Check `YamlConfigurationLoaderTest` to confirm exact precedence ordering (env var vs. system property).
- Determine if the system-property override (`cassandra.settings.*`) was previously documented and where.
- Draft a new "Overriding configuration via environment variables" subsection for `cass_yaml_file.adoc`.

## Notes
- Commit: `b2037e473f` (trunk), author Paulo Motta, July 7 2025.
- Reviewers: Stefan Miklosovic, David Capwell.
- The feature was also added to `conf/jvm-server.options` with full inline documentation — this file is the primary reference as shipped with the product.
- `OVERRIDABLE_CONFIG_NAMES` is computed at class load time from the full `Config.class` property tree (both top-level and flattened nested), so all properties in `cassandra.yaml` are in scope.
