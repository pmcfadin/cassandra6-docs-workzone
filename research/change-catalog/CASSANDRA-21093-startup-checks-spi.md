# CASSANDRA-21093: Custom Startup Checks via Java SPI

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary

CASSANDRA-21093 adds support for custom startup checks in Cassandra via Java's ServiceLoader (SPI) mechanism. Operators and developers can implement the `org.apache.cassandra.service.StartupCheck` interface, register their implementation in `META-INF/services`, place the JAR on Cassandra's classpath, and have their custom validation logic execute automatically during node startup. Custom checks can be configured per-check via the `startup_checks` section in `cassandra.yaml`, including the ability to disable individual checks or pass arbitrary key-value parameters. No documentation page exists on trunk; only a `NEWS.txt` mention and an example under `examples/startup-checks/`.

## Discovery Source

- `NEWS.txt` reference: "It is possible to provide custom startup check via Java SPI. See CASSANDRA-21093."
- `CHANGES.txt` reference: Present under 6.0 changes.
- Related JIRA: https://issues.apache.org/jira/browse/CASSANDRA-21093
- PRs: https://github.com/apache/cassandra/pull/4555 (initial), https://github.com/apache/cassandra/pull/4557 (reworked)
- Commit: https://github.com/apache/cassandra/commit/585f89bb4274b1af471ae43aeef01796d0e503d0
- Fix version: 6.0-alpha1, 6.0
- Assignee: Nick Doan
- Reviewer: Stefan Miklosovic

## Why It Matters

- **User-visible effect:** Organizations can now enforce custom pre-flight validation during Cassandra startup without patching Cassandra or running external wrapper scripts. Examples: compliance checks, environment validation, custom hardware checks, license verification.
- **Operational effect:** Eliminates the need for external orchestration (shell scripts, init wrappers) to perform pre-startup validation. Custom checks integrate natively into the startup sequence and can block startup with meaningful error messages.
- **Upgrade or compatibility effect:** Additive feature with no breaking changes. Existing startup checks are unaffected.
- **Configuration or tooling effect:** New `startup_checks` YAML section for per-check configuration. New SPI contract (`StartupCheck` interface). Bundled example project under `examples/startup-checks/`.

## Source Evidence

### Relevant docs paths

- **No authored doc page exists on trunk.** There is no `startup-checks.adoc` or similar page in `doc/modules/cassandra/pages/`.
- `doc/modules/cassandra/nav.adoc` -- No navigation entry for startup checks.
- `examples/startup-checks/README.adoc` -- Example project documentation exists but is not part of the published Antora docs.

### Relevant config paths

- `conf/cassandra.yaml` / `conf/cassandra_latest.yaml` -- `startup_checks` section added (may be commented out by default or added only in `cassandra_latest.yaml`).

### Relevant code paths

- `src/java/org/apache/cassandra/service/StartupCheck.java` -- The SPI interface. Methods:
  - `String name()` -- check identifier matching the key in `cassandra.yaml`
  - `void execute(StartupChecksConfiguration configuration)` -- performs validation, throws `StartupException` to block startup
  - `boolean isConfigurable()` -- default `false`; whether the check accepts YAML configuration
  - `boolean isDisabledByDefault()` -- default `false`; whether a check runs when not mentioned in config
  - `void postAction(StartupChecksConfiguration configuration)` -- hook executed after all checks succeed
- `src/java/org/apache/cassandra/service/StartupChecks.java` -- `withServiceLoaderTests()` method loads SPI-provided checks via `ServiceLoader.load(StartupCheck.class)`. Includes:
  - Duplicate name detection (throws `IllegalStateException`)
  - Conflict prevention with built-in checks (cannot shadow built-in check names)
  - Graceful degradation if `ServiceConfigurationError` occurs (logs warning, continues without custom checks)
- `src/java/org/apache/cassandra/service/StartupChecksConfiguration.java` -- Configuration accessor; custom checks call `getConfig(name())` and `isDisabled(name())`.

### Relevant test paths

- Tests included in the commit for service loader integration and configuration handling.

### Example project

- `examples/startup-checks/README.adoc` -- Build and install instructions.
- `examples/startup-checks/build.xml` -- Ant build script with `install` and `clean` targets.
- `examples/startup-checks/src/` -- Contains:
  - `org/apache/cassandra/service/checks/` -- Example check implementation(s)
  - `resources/META-INF/services/org.apache.cassandra.service.StartupCheck` -- SPI registration file

## What Changed

| Aspect | Before | After (Cassandra 6.0) |
|--------|--------|----------------------|
| Custom startup validation | Not possible without patching Cassandra or using external scripts | Native SPI-based extensibility via `StartupCheck` interface |
| Configuration | No per-check YAML config | `startup_checks` section in `cassandra.yaml` for per-check settings |
| Check discovery | Only built-in checks hardcoded in `StartupChecks.java` | Built-in + ServiceLoader-discovered custom checks |
| Check disabling | No granular control | Individual checks can be disabled via YAML config |
| Error handling | Fixed startup error messages | Custom checks provide their own error messages and remediation guidance |
| Examples | None | Bundled example project under `examples/startup-checks/` |

### StartupCheck interface contract

```java
public interface StartupCheck {
    String name();
    void execute(StartupChecksConfiguration configuration) throws StartupException;
    default boolean isConfigurable() { return false; }
    default boolean isDisabledByDefault() { return false; }
    default void postAction(StartupChecksConfiguration configuration) {}
}
```

### YAML configuration shape

```yaml
startup_checks:
  my_custom_check:
    enabled: true
    key1: value1
    key2: value2
  another_check:
    enabled: false
```

### Implementation steps for custom checks

1. Implement `org.apache.cassandra.service.StartupCheck`
2. Create `META-INF/services/org.apache.cassandra.service.StartupCheck` listing the implementation class
3. Package into a JAR
4. Place JAR on Cassandra's classpath
5. Optionally configure per-check settings in `cassandra.yaml` under `startup_checks`

## Docs Impact

**Impact Level:** Medium -- no documentation exists on trunk beyond the example README. A new authored page is recommended.

### Existing pages likely affected

- `doc/modules/cassandra/pages/managing/operating/index.adoc` -- Should link to the new startup checks page.
- `doc/modules/cassandra/nav.adoc` -- Needs a navigation entry for the new page.
- Generated YAML reference (`cass_yaml_file.adoc`) -- Should include the `startup_checks` section if it appears in `cassandra.yaml`. Requires build validation.

### New pages likely needed

- **`doc/modules/cassandra/pages/managing/operating/startup-checks.adoc`** -- New authored page covering:
  - What startup checks are and when they run
  - The `StartupCheck` SPI interface and its methods
  - How to implement a custom check (step-by-step)
  - YAML configuration for custom checks
  - How to build, install, and remove custom check JARs
  - Error handling and `StartupException` behavior
  - Reference to the bundled example project
  - Constraints: cannot shadow built-in check names, duplicate name detection

### Audience home

- Operators > Operating (primary)
- Contributors / Plugin developers (secondary -- SPI extensibility)

### Authored or generated

- New page must be authored. The generated YAML reference may partially cover `startup_checks` config.

### Technical review needed from

- Nick Doan (implementer) or Stefan Miklosovic (reviewer) for interface contract accuracy and configuration behavior.

## Proposed Disposition
- Inventory classification: draft-new-page
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

### Recommended actions

1. **Author new page** -- Create `startup-checks.adoc` (or similar) under `managing/operating/` covering the SPI contract, implementation steps, YAML configuration, and the bundled example.
2. **Update nav.adoc** -- Add navigation entry under Managing > Operating.
3. **Validate generated YAML docs** -- Confirm `startup_checks` section renders in the generated `cass_yaml_file.adoc` after a trunk build.
4. **Cross-reference** -- Link from any existing startup/bootstrap documentation if applicable.
5. **Update index.md** -- Change status from `queued` / `changelog-only` to `validated` / `repo-validated`.

## Open Questions

1. **Is `startup_checks` present in `cassandra.yaml` or only `cassandra_latest.yaml`?** The WebFetch of `cassandra.yaml` did not surface the section, but the commit modifies both files. Need to confirm whether the section is commented out or only in the "latest" variant. This affects operator discoverability.

2. **What built-in check names exist?** Custom checks cannot shadow built-in names. The docs should list (or cross-reference) the set of reserved names so implementers avoid collisions.

3. **Is `isConfigurable()` required to return `true` for YAML config to be read?** The interface defaults to `false`. Docs should clarify whether returning `false` silently ignores YAML config or causes an error.

4. **What happens when `ServiceConfigurationError` occurs?** The code logs a warning and skips all custom checks. Docs should note this failure mode so operators know to check logs if their custom checks do not execute.

5. **Is there a classloading constraint?** Custom check JARs must be on the Cassandra classpath. Does this mean `lib/` directory only, or are other classpath extension mechanisms supported (e.g., `CLASSPATH` environment variable, `JVM_EXTRA_OPTS`)?

6. **What is the `postAction` hook used for?** The interface includes a `postAction()` method executed after all checks succeed. This is not well documented in the example. Use cases and timing should be clarified.

## Next Research Steps

1. Build trunk and validate `startup_checks` appears in generated YAML reference docs.
2. Enumerate built-in check names from `StartupChecks.java` to document reserved names.
3. Test the example project end-to-end: build, install, configure in YAML, start Cassandra, observe logs.
4. Confirm classloading behavior: which directories/mechanisms place JARs on the Cassandra classpath.
5. Clarify interaction between `isConfigurable()` and YAML config parsing.
6. Draft the new `startup-checks.adoc` page based on validated findings.

## Notes

- The initial PR (#4555) was replaced by a reworked approach in PR #4557 that supports multiple custom checks via list-based configuration rather than a single `custom_check` type.
- Stefan Miklosovic's review drove the design toward a more flexible multi-check YAML configuration model.
- The SPI approach follows the same pattern used successfully in other Java frameworks (JDBC drivers, logging backends, etc.) and is a well-understood extensibility mechanism.
- The bundled example under `examples/startup-checks/` includes an Ant build script (`ant install` / `ant clean`) for easy experimentation, but this example is not part of the published Antora docs.
- The `StartupCheck` interface Javadoc emphasizes that failed checks should log explanatory messages and remediation steps -- this guidance should be reflected in documentation for implementers.
- This feature is related to but distinct from the existing built-in startup checks (data directory validation, cluster name check, JMX port check, etc.) which are hardcoded in `StartupChecks.java`.
