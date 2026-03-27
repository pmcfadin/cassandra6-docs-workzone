# CASSANDRA-19397: Remove native_transport_port_ssl

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
The `native_transport_port_ssl` configuration property has been fully removed from Cassandra 6.0. This property previously allowed operators to run a second CQL native transport listener on a dedicated SSL-only port. With its removal, Cassandra supports only a single native transport port (`native_transport_port`, default 9042). Encrypted and unencrypted client connections can coexist on that single port by setting the `optional` flag in `client_encryption_options` to `true`.

## Discovery Source
- NEWS.txt upgrading section for Cassandra 6.0
- JIRA: [CASSANDRA-19397](https://issues.apache.org/jira/browse/CASSANDRA-19397)
- Preceded by deprecation in CASSANDRA-19392 (Cassandra 5.0), itself motivated by CASSANDRA-10559

## Why It Matters
Any operator currently using `native_transport_port_ssl` to segregate encrypted CQL traffic onto a separate port will encounter a startup failure or ignored configuration after upgrading to Cassandra 6.0. This is a **breaking change** for deployments relying on dual-port native transport. The migration path -- using `client_encryption_options.optional: true` on a single port -- must be clearly documented.

## Source Evidence

### Code Changes (PR #3103, commit 087a447)
| File | Change |
|------|--------|
| `conf/cassandra.yaml` | Removed 9 lines: the entire `native_transport_port_ssl` block and comments |
| `src/java/org/apache/cassandra/config/Config.java` | Removed `public Integer native_transport_port_ssl = null;` and `@Deprecated` annotation |
| `src/java/org/apache/cassandra/config/DatabaseDescriptor.java` | Removed 28 lines: validation logic, `getNativeTransportPortSSL()`, and `setNativeTransportPortSSL()` methods |
| `src/java/org/apache/cassandra/service/NativeTransportService.java` | Replaced `Collection<Server>` with single `Server`; removed dual-server creation logic (-52/+13 lines) |
| `src/java/org/apache/cassandra/metrics/ClientMetrics.java` | Simplified metrics from multi-server to single-server model |
| `src/java/org/apache/cassandra/tools/LoaderOptions.java` | Removed SSL port option from sstableloader |
| `test/unit/.../ConfigCompatibilityTest.java` | Added `native_transport_port_ssl` to `REMOVED_IN_51` allow-list |
| `doc/modules/cassandra/pages/managing/operating/security.adoc` | Added 5-line NOTE about deprecation/removal |

### NEWS.txt Entry
> "native_transport_port_ssl property was removed. Please transition to using one port only. Encrypted communication may be optional by setting `optional` flag in `client_encryption_options` to `true` and it should be set only while in unencrypted or transitional operation."

### Cassandra 5.0 Deprecation Context (NEWS.txt)
> "Usage of dual native ports (native_transport_port and native_transport_port_ssl) is deprecated and will be removed in a future release. A single native port can be used for both encrypted and unencrypted traffic; see CASSANDRA-10559. Cluster hosts running with dual native ports were not correctly identified in the system.peers tables and server-sent EVENTs, causing clients that encrypt traffic to fail to maintain correct connection pools."

### Current State on Trunk
- `conf/cassandra.yaml`: No mention of `native_transport_port_ssl` -- confirmed removed.
- `Config.java`: Field is gone -- confirmed removed.
- `security.adoc`: Contains a note that the property "was deprecated in Cassandra 5.0" but the note text may need updating to also state it was **removed in 6.0**.
- Remaining references in `test/data/config/version=*.yml` files are historical version snapshots (expected).

## What Changed

### Removed
- **Configuration property**: `native_transport_port_ssl` (yaml + Java config)
- **Getter/setter**: `DatabaseDescriptor.getNativeTransportPortSSL()` / `setNativeTransportPortSSL()`
- **Dual-server architecture**: `NativeTransportService` no longer manages a collection of servers; it runs exactly one `Server` instance
- **sstableloader option**: SSL port argument removed from `LoaderOptions`

### Modified
- **`client_encryption_options`**: Now the sole mechanism for controlling CQL transport encryption. The `optional` flag controls whether unencrypted connections are also accepted on the single port.

### Migration Path
1. Stop using `native_transport_port_ssl` in `cassandra.yaml`
2. Configure `client_encryption_options` with `enabled: true`
3. During transition, set `optional: true` to allow both encrypted and unencrypted connections on the single `native_transport_port`
4. Once all clients connect via TLS, set `optional: false` to enforce encryption

## Docs Impact

### HIGH -- Multiple documentation updates required

1. **`security.adoc`** (`doc/modules/cassandra/pages/managing/operating/security.adoc`):
   - The existing note says the property "was deprecated in Cassandra 5.0" but should be updated to state it was **removed in Cassandra 6.0**.
   - The paragraph describing "separate ports can also be configured for secure and unsecure connections" should be removed or rewritten since this is no longer possible.
   - Add explicit migration steps for users upgrading from dual-port configurations.

2. **Configuration reference** (if a cassandra.yaml reference doc exists):
   - Remove any reference to `native_transport_port_ssl`.
   - Document that `native_transport_port` is the only CQL listener port.

3. **Upgrade guide / migration docs**:
   - Add a clear upgrading note explaining the removal and the migration path via `client_encryption_options.optional`.
   - Reference the original bug (CASSANDRA-10559) that motivated this: dual ports caused incorrect `system.peers` entries and broken client connection pools.

4. **sstableloader docs** (if any):
   - Remove any reference to SSL port options.

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: security.adoc
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
1. Does the security.adoc note currently say "deprecated in 5.0" without stating "removed in 6.0"? (Evidence suggests yes -- needs explicit verification of current trunk text.)
2. Does `cassandra.yaml` on trunk silently ignore `native_transport_port_ssl` if a user includes it, or does startup fail? This affects how urgent the migration guidance is.
3. Are there any driver-side docs or recommendations needed? Clients previously connecting to the SSL-specific port need to be reconfigured.
4. The `ConfigCompatibilityTest` lists this in `REMOVED_IN_51` -- was this actually removed in 5.1 (pre-6.0) or is "5.1" what became 6.0? Version numbering should be clarified.

## Next Research Steps
- [ ] Verify exact current text of `security.adoc` on trunk for the native_transport_port_ssl note
- [ ] Test behavior when `native_transport_port_ssl` is present in yaml on Cassandra 6.0 (silent ignore vs. error)
- [ ] Check if there is a standalone cassandra.yaml configuration reference page in docs
- [ ] Check CASSANDRA-19392 (the deprecation JIRA) for any additional context
- [ ] Review whether any other doc pages (e.g., networking, getting started) reference the SSL port

## Notes
- The PR was authored by Stefan Miklosovic and reviewed by Brandon Williams.
- The commit landed on 2024-02-18.
- The `REMOVED_IN_51` label in ConfigCompatibilityTest suggests this was targeted at version 5.1, which may have been renumbered to 6.0-alpha1 based on the JIRA fix version.
- The original motivation (CASSANDRA-10559) was that dual ports caused broken `system.peers` entries and client connection pool failures -- this is useful context for explaining the "why" in docs.
- The `optional` flag in `client_encryption_options` defaults to `true` when `enabled` is `false`, and defaults to `false` when `enabled` is `true`, per the yaml comments on trunk.
