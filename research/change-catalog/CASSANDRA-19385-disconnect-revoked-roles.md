# CASSANDRA-19385 Periodically disconnect roles that are revoked or have LOGIN=FALSE set

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
CASSANDRA-19385 adds a background task to `CassandraRoleManager` that periodically checks all active native-transport connections and disconnects any whose role has been revoked or altered to `LOGIN=FALSE` (or `LOGIN=false`). Previously, revoking a role or setting `LOGIN=FALSE` prevented new logins but left existing connections open indefinitely until the client disconnected naturally. The new task runs on a configurable periodic schedule (default: 4 hours, plus up to 1 hour of random jitter) and can be disabled by setting the period to `0h`. The period and jitter are also tunable at runtime via a new JMX MBean (`CassandraRoleManager`).

## Discovery Source
- `CHANGES.txt` reference: "Periodically disconnect roles that are revoked or have LOGIN=FALSE set (CASSANDRA-19385)"
- Related JIRA: CASSANDRA-19385
- Related CEP or design doc: None identified

## Why It Matters
- User-visible effect: Clients connected under a revoked or login-disabled role will have their connections forcibly closed on the next scheduled task run (within the configured period), rather than remaining connected indefinitely.
- Operational effect: Operators gain assurance that access revocation fully takes effect within a bounded time window without requiring a node restart or manual intervention.
- Upgrade or compatibility effect: The task is enabled by default (period = 4h, max jitter = 1h) in `cassandra_latest.yaml`. In `cassandra.yaml` the settings are commented out with the same defaults. Operators upgrading with existing connections should be aware that connections under revoked roles will be disconnected on the first task execution after upgrade.
- Configuration or tooling effect: New `role_manager.parameters` sub-keys in `cassandra.yaml`: `invalid_role_disconnect_task_period` (default `4h`) and `invalid_role_disconnect_task_max_jitter` (default `1h`). A new MBean `org.apache.cassandra.auth:type=CassandraRoleManager` exposes `getInvalidClientDisconnectPeriodMillis`, `setInvalidClientDisconnectPeriodMillis`, `getInvalidClientDisconnectMaxJitterMillis`, and `setInvalidClientDisconnectMaxJitterMillis` for runtime adjustment.

## Source Evidence
- Relevant docs paths:
  - No existing doc page covers the `role_manager` parameters subsection of `cassandra.yaml`.
  - `doc/modules/cassandra/pages/managing/operating/security.adoc` — may be the appropriate place to document the behavior.
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated; will pick up the new YAML comments on regeneration.
- Relevant config paths:
  - `conf/cassandra.yaml`: `role_manager.parameters.invalid_role_disconnect_task_period` and `role_manager.parameters.invalid_role_disconnect_task_max_jitter` (commented out, defaults 4h / 1h)
  - `conf/cassandra_latest.yaml`: same settings uncommented with defaults `4h` / `1h`
- Relevant code paths:
  - `src/java/org/apache/cassandra/auth/CassandraRoleManager.java` — `scheduleDisconnectInvalidRoleTask()`, `disconnectInvalidRoles()`, `PARAM_INVALID_ROLE_DISCONNECT_TASK_PERIOD`, `PARAM_INVALID_ROLE_DISCONNECT_TASK_MAX_JITTER`
  - `src/java/org/apache/cassandra/auth/CassandraRoleManagerMBean.java` — new MBean interface exposing getters/setters for period and max jitter
  - `src/java/org/apache/cassandra/service/StorageService.java` — `disconnectInvalidRoles()` method called by the task
  - `src/java/org/apache/cassandra/service/NativeTransportService.java` — performs the actual connection teardown
  - `src/java/org/apache/cassandra/transport/Server.java` — updated to support role-based connection filtering
  - `src/java/org/apache/cassandra/service/CassandraDaemon.java` — wires up the task at startup
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/test/auth/RoleRevocationTest.java` — end-to-end distributed test for the revocation disconnect behavior
  - `test/unit/org/apache/cassandra/auth/CassandraRoleManagerTest.java`
  - `test/unit/org/apache/cassandra/auth/RolesTest.java`

## What Changed
1. **New background task** in `CassandraRoleManager`: runs `disconnectInvalidRoles()` at a configurable interval with jitter.
2. **New `role_manager` parameters** in `cassandra.yaml`:
   - `invalid_role_disconnect_task_period`: duration (default `4h`); set to `0h` to disable.
   - `invalid_role_disconnect_task_max_jitter`: duration (default `1h`); adds randomized delay to avoid thundering-herd disconnects across nodes.
   - Note from YAML comments: "It's recommended to set these longer than the roles cache refresh period, since the invalidation check depends on cache contents."
3. **New MBean `org.apache.cassandra.auth:type=CassandraRoleManager`** with runtime controls:
   - `getInvalidClientDisconnectPeriodMillis()` / `setInvalidClientDisconnectPeriodMillis(long)`
   - `getInvalidClientDisconnectMaxJitterMillis()` / `setInvalidClientDisconnectMaxJitterMillis(long)`
4. **Behavior:** The task checks each connected client's role against the current roles cache. Roles with `can_login=false` or that no longer exist are disconnected. The check is cache-dependent — if the roles cache has not yet refreshed after an `ALTER ROLE` or `DROP ROLE`, the disconnect may not fire until the next cache refresh cycle.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/security.adoc` — should document the new background disconnect behavior, the YAML parameters, and the interaction with roles cache TTL.
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated; picks up YAML comments automatically.
- New pages likely needed: None (fits within existing security operations page).
- Audience home: Operators
- Authored or generated: `security.adoc` is authored content.
- Technical review needed from: Auth/security domain expert

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead (security/operations focus)
- Publish blocker: no

## Open Questions
- What is the roles cache refresh interval and how does it interact with the disconnect period? (The YAML comment says task period should be longer than the cache refresh period, but the cache TTL is not prominently documented.)
- Is the disconnect graceful (CQL-level closure) or is it a TCP-level teardown? This matters for client reconnection behavior.
- Does the task run on all nodes independently, or is it coordinated? The use of random jitter suggests independent per-node execution; this should be stated explicitly in the docs.

## Next Research Steps
- Check `Server.java` / `NativeTransportService.java` to determine whether the disconnect is graceful or abrupt.
- Confirm that the task runs independently on each node (not via coordinator).
- Add a note to `security.adoc` alongside the `ALTER ROLE` and `DROP ROLE` documentation.

## Notes
- Commit: `aa5b8e3d3f` (trunk), author Abe Ratnofsky, November 21 2024.
- Reviewers: Bernardo Botella Corbi, Francisco Guerrero Hernandez, Jon Meredith.
- The jitter is designed to prevent all nodes from disconnecting clients simultaneously ("thundering herd"), as noted in the source code comment on `disconnectInvalidRoles()`.
- MBean name: `org.apache.cassandra.auth:type=CassandraRoleManager`.
