# CASSANDRA-19792 + CASSANDRA-20128 Audit logging configuration enhancements

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
This file consolidates two related audit logging improvements in Cassandra 6:

**CASSANDRA-19792** adds configurable log-message formatting for `FileAuditLogger` and `BinAuditLogger`. Two new optional parameters — `key_value_separator` (default `":"`) and `field_separator` (default `"|"`) — let operators customize the output format of each audit log entry without writing a custom logger implementation.

**CASSANDRA-20128** extends audit logging to cover JMX operations. Previously, audit logging only captured CQL-protocol events. With this change, any JMX method invocation routed through `AuthorizationProxy` is also recorded in the audit log under the new `JMX` category and `AuditLogEntryType.JMX` entry type. Operators can include or exclude the `JMX` category using the existing `included_categories` / `excluded_categories` filters in `audit_logging_options`.

## Discovery Source
- `CHANGES.txt` reference (CASSANDRA-19792): "Allow configuring log format for Audit Logs (CASSANDRA-19792)"
- `CHANGES.txt` reference (CASSANDRA-20128): "Support audit logging for JMX operations (CASSANDRA-20128)"
- Related JIRAs: CASSANDRA-19792, CASSANDRA-20128

## Why It Matters
- User-visible effect (19792): Operators can change the field and key-value separators in audit log lines to match downstream log-processing pipelines without rewriting log parsing logic.
- User-visible effect (20128): JMX access (nodetool commands, third-party JMX tools) is now captured in the audit log alongside CQL events, providing a more complete audit trail for compliance and security review.
- Operational effect: The `JMX` category can be independently included/excluded in audit filters, so existing deployments that do not want JMX events can exclude the category without disrupting CQL audit coverage.
- Upgrade or compatibility effect: Both changes are additive. The new format parameters default to the previous hardcoded separators (`":"` and `"|"`), so existing log parsing is unchanged unless operators explicitly override them. The `JMX` category is new and does not appear in existing logs unless `included_categories` is set to include it.
- Configuration or tooling effect: New logger parameters in `audit_logging_options.logger[].parameters`; new `JMX` value in the audit log categories list.

## Source Evidence

### CASSANDRA-19792 — Configurable log format
- Relevant config paths:
  - `conf/cassandra.yaml`: new commented-out `parameters` block under `audit_logging_options.logger`:
    ```yaml
    audit_logging_options:
      logger:
        - class_name: BinAuditLogger
      #   parameters:
      #     - key_value_separator: ":"
      #       field_separator: "|"
    ```
- Relevant code paths:
  - `src/java/org/apache/cassandra/audit/FileAuditLogger.java` — reads `key_value_separator` and `field_separator` from the logger parameters map; falls back to `DEFAULT_KEY_VALUE_SEPARATOR` (`:`) and `DEFAULT_FIELD_SEPARATOR` (`|`) if not set.
  - `src/java/org/apache/cassandra/audit/BinAuditLogger.java` — same parameters applied to binary log formatting.
  - `src/java/org/apache/cassandra/audit/AuditLogEntry.java` — updated to use the configurable separators.
  - `src/java/org/apache/cassandra/auth/MutualTlsAuthenticator.java` — unrelated cosmetic change in the same commit.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/audit/AuditLogEntryTest.java`
  - `test/unit/org/apache/cassandra/audit/FileAuditLoggerTest.java`

### CASSANDRA-20128 — JMX audit logging
- Relevant code paths:
  - `src/java/org/apache/cassandra/audit/AuditLogEntryCategory.java` — adds `JMX` to the category enum: `QUERY, DML, DDL, DCL, OTHER, AUTH, ERROR, PREPARE, JMX, TRANSACTION`.
  - `src/java/org/apache/cassandra/audit/AuditLogEntryType.java` — adds `JMX(AuditLogEntryCategory.JMX)` entry type.
  - `src/java/org/apache/cassandra/audit/AuditLogManager.java` — implements `JmxInvocationListener` interface; logs JMX invocations via `onInvocation()` and failures via `onFailure()`.
  - `src/java/org/apache/cassandra/utils/JmxInvocationListener.java` — new interface with `onInvocation(Subject, Method, Object[])` and `onFailure(Subject, Method, Object[], Exception)` callbacks.
  - `src/java/org/apache/cassandra/auth/jmx/AuthorizationProxy.java` — calls `JmxInvocationListener` hooks to emit audit events.
  - `src/java/org/apache/cassandra/utils/JMXServerUtils.java` — wires up the `AuditLogManager` as a JMX invocation listener.
  - `src/java/org/apache/cassandra/auth/CassandraPrincipal.java` — updated to carry identity information through the JMX audit event path.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/audit/AuditLoggerTest.java`
  - `test/unit/org/apache/cassandra/auth/jmx/AbstractJMXAuthTest.java`

## What Changed

### CASSANDRA-19792
1. `FileAuditLogger` and `BinAuditLogger` now accept two optional logger-level parameters:
   - `key_value_separator` (string, default `":"`) — separates field names from values in each log token.
   - `field_separator` (string, default `"|"`) — separates fields within a single log entry.
2. Default separators match the previously hardcoded values, preserving backward compatibility.
3. Parameters are specified per-logger in the `audit_logging_options.logger[].parameters` map in `cassandra.yaml`.

### CASSANDRA-20128
1. New `JMX` audit log category added to `AuditLogEntryCategory`.
2. New `AuditLogEntryType.JMX` for JMX operation events.
3. `AuditLogManager` now records JMX invocations and failures via `JmxInvocationListener` callbacks.
4. JMX audit events include the authenticated subject, the MBean method name, and argument details.
5. `JMX` category participates in the standard `included_categories` / `excluded_categories` filter logic, so operators can selectively audit or suppress JMX events.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/audit_logging.adoc`:
    - Add documentation for `key_value_separator` and `field_separator` parameters under `BinAuditLogger` and `FileAuditLogger` configuration sections.
    - Update the list of available audit log categories (currently: "QUERY, DML, DDL, DCL, OTHER, AUTH, ERROR, PREPARE") to include `JMX` (and `TRANSACTION`).
    - Add a note that JMX operations are now audited and describe what is captured (subject, method, args).
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated; will reflect the new `parameters` sub-block automatically once the YAML comments are parsed.
- New pages likely needed: None.
- Audience home: Operators
- Authored or generated: `audit_logging.adoc` is authored content.
- Technical review needed from: Security / audit logging domain expert (Francisco Guerrero, Abe Ratnofsky)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead (security/operations focus)
- Publish blocker: no

## Open Questions
- The categories list in `audit_logging.adoc` currently ends with "PREPARE" but `TRANSACTION` also appears in the enum. Was `TRANSACTION` added pre-6.0? Should it also be added to the documented list alongside `JMX`?
- What specific JMX operation details are included in the audit entry? Does it log argument values (which may be sensitive) or only method names?
- Are JMX auth failures (wrong credentials) logged under `AUTH` or `JMX`? Clarify the boundary between the two categories for JMX.

## Next Research Steps
- Check `AuditLogManager.onInvocation()` implementation to determine what operation detail is logged for JMX entries.
- Verify whether JMX authentication failures map to `AUTH` or `JMX` category.
- Update `audit_logging.adoc` with the format parameters and JMX category sections.

## Notes
- CASSANDRA-19792 commit: `25291ff3fd` (trunk), author Francisco Guerrero, July 22 2024. Reviewers: Stefan Miklosovic, Andy Tolbert.
- CASSANDRA-20128 commit: `c853efffa8` (trunk), author Abe Ratnofsky, December 6 2024. Reviewers: Bernardo Botella, Doug Rohrer, Francisco Guerrero.
- The `AuditLogManager` class now implements both `QueryEvents.Listener`, `AuthEvents.Listener`, `AuditLogManagerMBean`, and the new `JmxInvocationListener` interface.
