# CASSANDRA-11695: JMX Server Configuration in cassandra.yaml

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary

CASSANDRA-11695 moves JMX server configuration from `cassandra-env.sh` into `cassandra.yaml` via a new `jmx_server_options` section. The related CASSANDRA-18508 adds JMX SSL/TLS configuration under `jmx_encryption_options` nested within `jmx_server_options`. Both changes landed in Cassandra 5.0 (backported partially from 4.1 for SSL) and are present in 6.0. The old shell-based approach still works but operators must choose one method; enabling both causes a startup failure.

## Discovery Source

- NEWS.txt (6.0 section): "It is possible to configure JMX server in cassandra.yaml in jmx_server_options configuration section."
- CHANGES.txt: "Enable JMX server configuration to be in cassandra.yaml (CASSANDRA-11695)" under 5.0; "Make JMX SSL configurable in cassandra.yaml (CASSANDRA-18508)" under 4.1.0.
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-11695
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-18508

## Why It Matters

This is a significant operator-facing change. JMX is the primary management interface for Cassandra (nodetool, monitoring, etc.). Moving its configuration into `cassandra.yaml`:

1. **Centralizes configuration** -- operators no longer need to edit shell scripts for JMX settings.
2. **Improves security** -- JMX SSL credentials are no longer exposed in process listings (ps output) since they are read from YAML, not passed as JVM arguments.
3. **Enables configuration management** -- YAML is easier to manage with automation tools (Ansible, Chef, etc.) than shell script modifications.
4. **Requires explicit migration** -- operators must opt in and cannot enable both approaches simultaneously.

## Source Evidence

### cassandra.yaml (`conf/cassandra.yaml` on trunk)

The `jmx_server_options` section is commented out by default:

```yaml
#jmx_server_options:
  # enabled: true
  # remote: false
  # jmx_port: 7199
  # rmi_port: 7199
  #
  # jmx_encryption_options:
  #   enabled: true
  #   cipher_suites: [TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256]
  #   accepted_protocols: [TLSv1.2,TLSv1.3,TLSv1.1]
  #   keystore: conf/cassandra_ssl.keystore
  #   keystore_password: cassandra
  #   keystore_password_file: conf/keystore_passwordfile.txt
  #   truststore: conf/cassandra_ssl.truststore
  #   truststore_password: cassandra
  #   truststore_password_file: conf/truststore_passwordfile.txt
```

### JMXServerOptions.java (`src/java/org/apache/cassandra/config/JMXServerOptions.java`)

Config model class with fields:
- `enabled` (boolean) -- whether JMX is enabled
- `remote` (boolean) -- local-only vs remote connections
- `jmx_port` (int, default 7199) -- JMX server port
- `rmi_port` (int, default 7199) -- RMI registry port (can match jmx_port unless SSL is enabled)
- `authenticate` (boolean) -- enable JMX authentication
- `jmx_encryption_options` -- nested SSL/TLS config
- `login_config_name` -- JAAS login config name
- `login_config_file` -- JAAS config file path
- `password_file` (redacted) -- JMX password file path
- `access_file` -- JMX access file path
- `authorizer` -- JMX authorizer class

Supports two configuration paths:
- YAML-based via `cassandra.yaml`
- System-property-based via `cassandra-env.sh` (legacy), parsed by `createParsingSystemProperties()`

### cassandra-env.sh (`conf/cassandra-env.sh`)

The `configure_jmx` function is the legacy configuration path. It sets JVM options for:
- Local JMX (`LOCAL_JMX=yes`): `cassandra.jmx.local.port`, no authentication
- Remote JMX (`LOCAL_JMX=no`): `cassandra.jmx.remote.port`, authentication enabled, optional SSL via commented-out JVM opts

### StartupChecks.java

Two relevant startup checks:
- `checkJMXPorts`: Warns if JMX is not enabled or not configured for remote connections, referencing `jmx_server_options` in the warning message.
- `checkJMXProperties`: Warns if deprecated `com.sun.management.jmxremote.port` system property is used, recommending `cassandra.jmx.remote.port` instead.

### DuplicateJMXConfigurationTest.java

Confirms the mutual exclusion rule. Error message when both are enabled:

> "Configure either jmx_server_options in cassandra.yaml and comment out configure_jmx function call in cassandra-env.sh or keep cassandra-env.sh to call configure_jmx function but you have to keep jmx_server_options in cassandra.yaml commented out."

### Existing Documentation (`doc/modules/cassandra/pages/managing/operating/security.adoc`)

The security.adoc page already has partial coverage:
- JMX access control section references `cassandra-env.sh` for authentication/authorization setup.
- JMX SSL section now references `jmx_encryption_options` in `cassandra.yaml` as the recommended approach.
- Notes that "Hot reloading of the SSLContext is not yet supported for the JMX SSL."
- However, the page does not document `jmx_server_options` comprehensively or explain the migration path from `cassandra-env.sh`.

### Generated YAML Reference

The `convert_yaml_to_adoc.py` script lists `jmx_server_options` as a `COMPLEX_OPTIONS` entry, meaning it will be rendered as a code block in the generated YAML reference page. However, `jmx_encryption_options` is not in the `COMPLEX_OPTIONS` list separately (it is nested within `jmx_server_options`).

## What Changed

| Aspect | Before (cassandra-env.sh only) | After (cassandra.yaml option) |
|--------|-------------------------------|-------------------------------|
| Config location | `cassandra-env.sh` shell script | `jmx_server_options` in `cassandra.yaml` |
| SSL credentials | JVM args visible in `ps` output | Read from YAML file, not in process listing |
| SSL config | Manual JVM `-D` flags (commented out) | `jmx_encryption_options` nested block |
| Port config | `configure_jmx 7199` function arg | `jmx_port` and `rmi_port` fields |
| Auth config | JVM `-D` flags for password/access files | `password_file`, `access_file`, `login_config_name`, `login_config_file`, `authorizer` fields |
| Local vs remote | `LOCAL_JMX` env var | `remote` boolean field |
| Automation | Requires shell script editing | Standard YAML, automation-friendly |
| Migration | N/A | Must comment out `configure_jmx` call in `cassandra-env.sh` |
| Conflict handling | N/A | Startup fails with explicit error if both enabled |

## Docs Impact

**Impact Level:** High

### What needs documentation

1. **New cassandra.yaml reference section** -- `jmx_server_options` and nested `jmx_encryption_options` need complete field-level documentation. The generated YAML reference page will cover this partially via the conversion script, but the commented-out default state means operators may not discover it.

2. **Migration guide** -- Operators need clear instructions for switching from `cassandra-env.sh` to `cassandra.yaml` JMX configuration:
   - Uncomment `jmx_server_options` in `cassandra.yaml`
   - Comment out the `configure_jmx` call in `cassandra-env.sh`
   - Map existing JVM flags to YAML fields
   - Understand the mutual exclusion rule

3. **Security page update** -- `security.adoc` already has some JMX SSL content referencing `jmx_encryption_options` but still primarily documents the `cassandra-env.sh` approach for authentication and authorization. It should be updated to present YAML-based configuration as the primary recommended approach for Cassandra 6, with `cassandra-env.sh` as the legacy fallback.

4. **cassandra-env.sh reference update** -- `cass_env_sh_file.adoc` currently has no JMX content. It should at minimum note that JMX configuration can now be done in `cassandra.yaml` and cross-reference the relevant sections.

5. **Startup behavior documentation** -- The startup checks and the mutual-exclusion error should be documented so operators understand why startup might fail.

### Generated docs consideration

The `convert_yaml_to_adoc.py` script handles `jmx_server_options` as a complex option but `jmx_encryption_options` is nested and may not get full standalone treatment. The generated reference should be validated after a build to confirm coverage completeness.

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: security.adoc; cass_env_sh_file.adoc; cass_yaml_file.adoc
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions

1. **Is `cassandra-env.sh` JMX configuration formally deprecated in 6.0?** The startup check warns about legacy system properties, but NEWS.txt says "old way still works." Need to determine the official deprecation stance for documentation tone.

2. **Is `jmx_encryption_options` rendered correctly in generated docs?** It is nested inside `jmx_server_options` and not listed separately in `COMPLEX_OPTIONS`. A build validation is needed.

3. **What is the interaction with nodetool?** Nodetool reads `JMX_PORT` from environment. If port is configured only in YAML, does nodetool still find it? The JIRA discussion mentions keeping `JMX_PORT` in shell scripts for tool compatibility.

4. **Does the `authorizer` field in YAML replace the `-Dcassandra.jmx.authorizer` system property entirely?** The security.adoc still documents the system property approach.

5. **PEM-based SSL support** -- security.adoc mentions `PEMBasedSslContextFactory` for JMX SSL. Is this documented adequately or does it need additional coverage?

## Next Research Steps

1. Build trunk and validate the generated `cass_yaml_file.adoc` to confirm `jmx_server_options` rendering.
2. Check nodetool source to understand how it resolves the JMX port when configured via YAML vs. environment.
3. Review `security.adoc` in full to create a precise diff plan for the update.
4. Confirm deprecation stance on `cassandra-env.sh` JMX configuration with the project.
5. Test the migration path end-to-end: enable YAML config, disable shell config, verify JMX connectivity.

## Notes

- The fix version in JIRA says 5.0 for CASSANDRA-11695, but NEWS.txt covers it prominently in the 6.0 section, indicating it is a key Cassandra 6 feature to document even if it technically landed earlier.
- CASSANDRA-18508 (JMX SSL in YAML) shows fix version 4.1.0, suggesting the SSL portion was backported earlier. The combined feature surface (server + SSL) is unified in the `jmx_server_options` block on trunk.
- The `@Redacted` annotation on `password_file` in `JMXServerOptions.java` means it will be masked in virtual table output, consistent with security practices for other credential fields.
- Hot reloading of SSLContext is explicitly noted as not supported for JMX SSL -- this is a limitation operators should know about.
