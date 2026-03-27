# CASSANDRA-19366 Auth mode exposed in system_views.clients, nodetool clientstats, and ClientMetrics

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-19366 adds authentication mode visibility across three operator surfaces: the `system_views.clients` virtual table gains `authentication_mode` and `authentication_metadata` columns; `nodetool clientstats --verbose` adds "Auth-Mode" and "Auth-Metadata" columns; and `ClientMetrics` exposes per-mode `AuthSuccess`, `AuthFailure`, and `ConnectedNativeClients` metrics scoped by authentication mode (e.g. Password, MutualTls, Unauthenticated). This lets operators monitor authentication migration progress and troubleshoot failures by authentication type.

## Discovery Source
- `NEWS.txt` reference: "Authentication mode is exposed in system_views.clients table, nodetool clientstats and ClientMetrics to help operators identify which authentication modes are being used. nodetool clientstats introduces --verbose flag behind which this information is visible."
- `CHANGES.txt` reference: "Expose auth mode in system_views.clients, nodetool clientstats, metrics (CASSANDRA-19366)"
- Related JIRA: CASSANDRA-19366
- Related JIRA: CASSANDRA-18554 (mTLS authenticator implementation)

## Why It Matters
- User-visible effect: Operators can now see per-connection authentication mode (Password, MutualTls, Unauthenticated) via CQL virtual tables or nodetool, rather than guessing or relying on external log correlation.
- Operational effect: Enables monitoring of authentication migration (e.g. password to mTLS). Operators can identify which clients have not yet migrated.
- Upgrade or compatibility effect: No breaking changes. New columns are additive in `system_views.clients`. The `--verbose` flag preserves backward compatibility for `nodetool clientstats` consumers.
- Configuration or tooling effect: No new configuration required. The `--verbose` flag on `nodetool clientstats` now shows Auth-Mode and Auth-Metadata columns (in addition to Client-Options). JMX monitoring tools can consume per-mode metrics at `org.apache.cassandra.metrics:type=Client,scope=<Mode>,name=<MetricName>`.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` (clients table section -- currently missing new columns in example output)
  - `doc/modules/cassandra/pages/managing/operating/metrics.adoc` (section "Client Authentication Mode-Specific Metrics" -- already documented at line 1017)
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` (no clientstats section currently)
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/virtual/ClientsTable.java` -- defines `authentication_mode` (UTF8) and `authentication_metadata` (map<text,text>) columns
  - `src/java/org/apache/cassandra/tools/nodetool/ClientStats.java` -- `--verbose` flag adds Auth-Mode and Auth-Metadata columns to output
  - `src/java/org/apache/cassandra/metrics/ClientMetrics.java` -- `markAuthSuccess(AuthenticationMode)` and `markAuthFailure(AuthenticationMode)` register per-mode meters
  - `src/java/org/apache/cassandra/auth/IAuthenticator.java` -- defines `AuthenticationMode` abstract class with `UNAUTHENTICATED`, `PASSWORD`, `MTLS` constants
  - `src/java/org/apache/cassandra/transport/ConnectedClient.java` -- exposes `authenticationMode()` and `authenticationMetadata()`
- Relevant test paths: (not investigated)

## What Changed
1. **system_views.clients** gains two new columns:
   - `authentication_mode` (text) -- e.g. "Password", "MutualTls", "Unauthenticated"
   - `authentication_metadata` (map<text, text>) -- currently only populated for mTLS connections with the extracted identity
2. **nodetool clientstats** gains a `--verbose` flag that shows all of `--client-options` output plus two additional columns: "Auth-Mode" and "Auth-Metadata".
3. **ClientMetrics** adds per-authentication-mode scoped meters:
   - `AuthSuccess` scoped by mode
   - `AuthFailure` scoped by mode
   - `ConnectedNativeClients` gauge scoped by mode
4. **AuthenticationMode** is an extensible abstract class, allowing custom `IAuthenticator` implementations to define their own modes.

## Docs Impact
- Existing pages likely affected:
  - `virtualtables.adoc` -- The `system_views.clients` example output (lines 183-249) is missing the `authentication_mode` and `authentication_metadata` columns. The example needs updating.
  - `metrics.adoc` -- Already has a "Client Authentication Mode-Specific Metrics" section (lines 1017-1047). Appears complete and accurate.
  - `use_nodetool.adoc` -- No `clientstats` section exists. Consider adding one or noting the `--verbose` flag in existing troubleshooting guidance.
- New pages likely needed: None
- Audience home: Operators
- Authored or generated: The `virtualtables.adoc` example output is authored content. The metrics section is authored. No generated-doc surfaces affected.
- Technical review needed from: Authentication / security domain expert

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: virtualtables.adoc; metrics.adoc; use_nodetool.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
- Should the `virtualtables.adoc` example output for `system_views.clients` show the `keyspace_name` column as well? It was added in an earlier JIRA but also appears missing from the example.
- Should there be a dedicated `nodetool clientstats` reference page (currently no generated or authored nodetool subcommand page exists for clientstats)?
- What metadata keys appear in `authentication_metadata` for mTLS connections? Only the extracted identity? This should be confirmed before documenting specifics.

## Next Research Steps
- Update the `system_views.clients` example in `virtualtables.adoc` to include `authentication_mode`, `authentication_metadata`, and `keyspace_name` columns
- Confirm whether a nodetool clientstats reference page should be created or if the generated nodetool docs cover it
- Verify metadata keys by checking `MutualTlsAuthenticator` source

## Notes
- The `--verbose` flag on `clientstats` is a superset of `--client-options` (includes client options plus auth info). Using both `--all` and `--verbose` together was noted as producing duplicate output in JIRA review discussion; assignee agreed to fix.
- The `AuthenticationMode` class is abstract (not an enum) to support extensibility by custom authenticator implementations.
- Fix version: 6.0-alpha1, 6.0. Reporter/assignee: Andy Tolbert.
