# CASSANDRA-21024: Disk Usage Guardrails -- Keyspace-Wide Protection

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary

CASSANDRA-21024 extends the existing disk usage guardrails with a new configuration, `data_disk_usage_keyspace_wide_protection_enabled`, which blocks all writes to a keyspace if any node that replicates that keyspace exceeds the disk usage failure threshold. Previously, the disk usage guardrail (`replicaDiskUsage`) only blocked writes to specific partition keys whose replicas were on full nodes. This new mode provides broader protection: if any node in a datacenter replicating a keyspace is full, all writes to that keyspace are rejected, regardless of which specific replicas would handle the write.

## Discovery Source

- `CHANGES.txt`: "Add configuration to disk usage guardrails to stop writes across all replicas of a keyspace when any node replicating that keyspace exceeds the disk usage failure threshold. (CASSANDRA-21024)"
- `NEWS.txt`: Not explicitly mentioned (change is an enhancement to existing guardrails)
- JIRA: https://issues.apache.org/jira/browse/CASSANDRA-21024
- Commit: 7fe688b000 (2025-11-13), author Isaac Reath, reviewed by Stefan Miklosovic and Paulo Motta

## Why It Matters

- **User-visible effect:** When enabled, write requests to a keyspace may be rejected even if the specific partition replicas have available disk space, as long as any node in the keyspace's datacenter is full. This prevents cascading failures where writes redirected away from full nodes overload remaining nodes.
- **Operational effect:** Provides stronger protection than per-replica disk usage checks. Operators can ensure that a single full node in a datacenter triggers write rejection across the entire keyspace, preventing the cluster from entering an unrecoverable state.
- **Upgrade or compatibility effect:** Default is `false` (disabled), so no behavioral change on upgrade. Operators must explicitly enable it.
- **Configuration or tooling effect:** One new `cassandra.yaml` boolean setting; dynamically configurable via JMX (`GuardrailsMBean`). Works in conjunction with existing `data_disk_usage_percentage_warn_threshold` and `data_disk_usage_percentage_fail_threshold`.

## Source Evidence

- Relevant docs paths:
  - No existing guardrails documentation page in `doc/` directory
  - No existing documentation covers this feature

- Relevant config paths:
  - `conf/cassandra.yaml`:
    ```yaml
    # Configures the disk usage guardrails to block all writes to a keyspace if any node which replicates
    # that keyspace is full. By default, this is disabled.
    # data_disk_usage_keyspace_wide_protection_enabled: false
    ```
  - This setting sits alongside the existing disk usage guardrail settings:
    ```yaml
    # data_disk_usage_percentage_warn_threshold: -1
    # data_disk_usage_percentage_fail_threshold: -1
    # data_disk_usage_max_disk_size:
    # data_disk_usage_keyspace_wide_protection_enabled: false
    ```

- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java`: `public volatile boolean data_disk_usage_keyspace_wide_protection_enabled = false;`
  - `src/java/org/apache/cassandra/config/GuardrailsOptions.java`: `getDataDiskUsageKeyspaceWideProtectionEnabled()` / `setDataDiskUsageKeyspaceWideProtectionEnabled()` methods
  - `src/java/org/apache/cassandra/db/guardrails/Guardrails.java`: New `diskUsageKeyspaceWideProtection` as a `Predicates<String>` guardrail that checks `DiskUsageBroadcaster.instance::isDatacenterFull` and `isDatacenterStuffed`
  - `src/java/org/apache/cassandra/service/disk/usage/DiskUsageBroadcaster.java`: Major changes:
    - New `fullNodesByDatacenter` and `stuffedNodesByDatacenter` concurrent maps tracking per-datacenter disk state
    - `isDatacenterFull(String datacenter)`: Returns true if any node in the datacenter has FULL disk usage
    - `isDatacenterStuffed(String datacenter)`: Returns true if any node in the datacenter has STUFFED (warn-level) disk usage
    - `computeUsageStateForEpDatacenter()`: Updates per-datacenter tracking when a node's disk usage state changes via gossip
    - `updateDiskUsageStateForDatacenterOnRemoval()`: Cleans up tracking when a node is removed
    - Uses `Locator` and `Location` from TCM for datacenter resolution
  - `src/java/org/apache/cassandra/cql3/statements/ModificationStatement.java`: `validateDiskUsage()` method restructured:
    - If `diskUsageKeyspaceWideProtection` is enabled AND the guardrail instance flag is true AND there are stuffed/full nodes: iterates over datacenters replicating the keyspace and calls `diskUsageKeyspaceWideProtection.guard(datacenter, state)` for each
    - For `NetworkTopologyStrategy`: checks only the datacenters where the keyspace is actually replicated
    - For `SimpleStrategy`: checks all known datacenters
    - Falls back to original per-replica `replicaDiskUsage` check when keyspace-wide protection is disabled
  - `src/java/org/apache/cassandra/db/guardrails/GuardrailsMBean.java`: JMX get/set for the boolean setting

- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/guardrails/GuardrailDataDiskUsageKeyspaceWideProtectionTest.java` (324 lines)
  - `test/unit/org/apache/cassandra/tools/nodetool/GuardrailsConfigCommandsTest.java` (updated)

## What Changed

1. **New cassandra.yaml setting**: `data_disk_usage_keyspace_wide_protection_enabled` (boolean, default `false`) in the guardrails section, placed after the existing disk usage settings.
2. **New guardrail**: `diskUsageKeyspaceWideProtection` of type `Predicates<String>` that evaluates datacenter names against `DiskUsageBroadcaster` state.
3. **Per-datacenter tracking**: `DiskUsageBroadcaster` now maintains per-datacenter sets of full and stuffed nodes, updated via gossip state changes.
4. **Write-path enforcement**: `ModificationStatement.validateDiskUsage()` checks all datacenters replicating the keyspace, not just specific partition replicas.
5. **Datacenter resolution**: Uses TCM `Locator` and `Location` for mapping endpoints to datacenters, with graceful handling of unknown locations.
6. **Strategy-aware checking**: For `NetworkTopologyStrategy`, only checks relevant datacenters; for `SimpleStrategy`, checks all known datacenters.
7. **JMX**: Dynamically configurable at runtime.

## Interaction with Existing Guardrails

This feature builds on the existing disk usage guardrail infrastructure:
- `data_disk_usage_percentage_warn_threshold` / `data_disk_usage_percentage_fail_threshold`: Define what "stuffed" and "full" mean
- `data_disk_usage_max_disk_size`: Optional cap on disk size used in threshold calculations
- `replicaDiskUsage` (existing guardrail): Per-replica check that still operates when keyspace-wide protection is disabled
- `data_disk_usage_keyspace_wide_protection_enabled` (new): When enabled, overrides the per-replica check with a broader datacenter-level check

## Docs Impact

- Existing pages likely affected:
  - The `cassandra.yaml` configuration reference should document the new setting alongside the existing disk usage guardrails
  - Any existing disk usage guardrails documentation must be updated to explain the keyspace-wide protection mode
- New pages likely needed:
  - A guardrails reference page (if not already planned) should explain both per-replica and keyspace-wide disk usage protection modes
- Audience home: Operators
- Authored or generated: Authored
- Technical review needed from: Isaac Reath (patch author), Stefan Miklosovic or Paulo Motta (reviewers)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

- How does the keyspace-wide protection interact with `data_disk_usage_max_disk_size`? Presumably the "full"/"stuffed" states are still derived from the same percentage thresholds applied to that max size.
- What happens when keyspace-wide protection is enabled but `data_disk_usage_percentage_fail_threshold` is not set (-1)? Are the warn/fail states effectively never triggered?
- The commit message references "CASSANDRA-20124" in the reviewed-for line -- this appears to be a typo for CASSANDRA-21024.
- Does this feature work correctly with virtual nodes (vnodes) and token-aware routing?
- What error message does the client receive when a write is rejected due to keyspace-wide disk protection?

## Notes

- Commit date is 2025-11-13, placing this firmly in the Cassandra 6.0 development cycle.
- The `DiskUsageBroadcaster` changes are substantial (140+ lines added) and introduce per-datacenter tracking as a new architectural element.
- The `NoSpamLogger` class was also modified (10 lines) to support the new logging pattern.
- The feature integrates with TCM (Transactional Cluster Metadata) for location resolution, which is itself a Cassandra 5.0+ feature.
- This is the only disk usage guardrail that operates at datacenter/keyspace granularity rather than per-replica granularity.
