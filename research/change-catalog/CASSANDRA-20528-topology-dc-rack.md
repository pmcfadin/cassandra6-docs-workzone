# CASSANDRA-20528: Topology-safe DC/Rack Changes for Live Nodes

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary
Cassandra 6.0 introduces a new `nodetool altertopology` command that allows operators to change the datacenter and/or rack assignment of live nodes without the previous requirement to decommission and recommission. The operation is safety-gated: it is only permitted when the proposed changes do not materially alter data placements (replica distribution). This is implemented as a new TCM (Transactional Cluster Metadata) transformation, `AlterTopology`, which atomically validates proposed changes against current placement calculations before committing.

## Discovery Source
- `NEWS.txt` reference: Not explicitly mentioned in NEWS.txt (should be added)
- `CHANGES.txt` reference: Line 117: "Support topology-safe changes to Datacenter & Rack for live nodes (CASSANDRA-20528)"
- Related JIRA: [CASSANDRA-20528](https://issues.apache.org/jira/browse/CASSANDRA-20528) (Resolved/Fixed, Fix Version: 6.0-alpha1, 6.0)
- Related CEP or design doc: Builds on CEP-21 / CASSANDRA-19488 (IEndpointSnitch deprecation / ClusterMetadata as topology source of truth)
- PR: [apache/cassandra#4050](https://github.com/apache/cassandra/pull/4050)
- Commit: `7a888149dff4afaea8753571097bd8bca6a4fbfd`

## Why It Matters
- **User-visible effect:** Operators gain a new nodetool command (`altertopology`) that allows datacenter and rack reassignment on running nodes, eliminating the need for costly decommission/recommission cycles for topology corrections.
- **Operational effect:** Significantly reduces operational burden for DC renames, rack reorganizations, and topology corrections in production clusters. The operation is atomic and validates safety before committing.
- **Upgrade or compatibility effect:** New in 6.0 only. Requires TCM (Transactional Cluster Metadata). Not available in pre-6.0 clusters. No backward compatibility concerns since this is purely additive.
- **Configuration or tooling effect:** New nodetool subcommand `altertopology`. Exposed via JMX through `StorageServiceMBean.alterTopology()`. Changes propagate to system tables (`system.local`, `system.peers_v2`) and gossip state automatically.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/snitch.adoc` -- existing snitch/topology page, no mention of altertopology
  - `doc/modules/cassandra/pages/managing/configuration/cass_rackdc_file.adoc` -- DC/rack configuration reference
  - `doc/modules/cassandra/pages/managing/configuration/cass_topo_file.adoc` -- topology properties reference
  - No generated nodetool doc for `altertopology` exists yet (nodetool docs are generated surfaces)
- Relevant config paths: None (no new YAML settings; this is a nodetool/JMX operation)
- Relevant code paths:
  - `src/java/org/apache/cassandra/tcm/transformations/AlterTopology.java` -- core transformation logic and safety validation
  - `src/java/org/apache/cassandra/tools/nodetool/AlterTopology.java` -- nodetool command definition
  - `src/java/org/apache/cassandra/tools/nodetool/NodetoolCommand.java` (line 62) -- command registration
  - `src/java/org/apache/cassandra/service/StorageService.java` (lines 5730-5747) -- JMX entry point
  - `src/java/org/apache/cassandra/service/StorageServiceMBean.java` (line 1397) -- MBean interface
  - `src/java/org/apache/cassandra/tcm/membership/Directory.java` -- `withUpdatedRackAndDc()` method
  - `src/java/org/apache/cassandra/tcm/membership/Location.java` -- `fromString()` parser (dc:rack format)
  - `src/java/org/apache/cassandra/tcm/ownership/DataPlacements.java` -- `equivalentTo()` safety check
  - `src/java/org/apache/cassandra/tcm/Transformation.java` (line 265) -- `ALTER_TOPOLOGY` kind registration
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/test/log/AlterTopologyTest.java` -- comprehensive dtest covering accepted/rejected scenarios
  - `test/unit/org/apache/cassandra/service/AlterTopologyArgParsingTest.java` -- argument parsing unit tests
  - `test/unit/org/apache/cassandra/tcm/membership/DirectoryTest.java` -- directory update tests
- Relevant generated-doc paths: nodetool docs are generated; `altertopology` will need to be included in the generated nodetool reference

## What Changed

### New nodetool command: `altertopology`
- **Syntax:** `nodetool altertopology <node>=<dc>:<rack> [<node>=<dc>:<rack> ...]`
- **Node identifiers:** Can be a numeric node ID, UUID host ID, or broadcast address (IP:port or IP)
- **Multiple changes:** Supports multiple node reassignments in a single atomic operation, comma-separated or space-separated
- **Description:** "Modify the datacenter and/or rack of one or more nodes"

### Safety validation rules
The transformation is rejected (with descriptive error messages) in these cases:
1. **Placement-altering changes:** If the proposed DC/rack changes would cause any change to data placements (replica distribution), the operation is rejected with: "Proposed updates modify data placements, violating consistency guarantees"
2. **In-flight range movements:** If there are locked ranges (indicating ongoing range movements like bootstrap, decommission, or move), the operation is rejected with: "The requested topology changes cannot be executed while there are ongoing range movements"
3. **Unregistered nodes:** If any specified node ID is not found in the cluster directory

### Scenarios that ARE permitted (from test evidence)
- Rack renames that do not change which racks replicas land on (e.g., when each node is in its own unique rack with NTS)
- Bulk rack changes for all nodes simultaneously (atomic update)
- DC renames when the DC is not referenced in any NTS replication parameters
- DC renames when all keyspaces use SimpleStrategy (which ignores DC names)
- Combined DC + rack changes when placements are unaffected

### Scenarios that are REJECTED (from test evidence)
- Moving a node to a different DC when that DC is referenced in NTS replication params
- Moving a node to a rack already occupied by another replica for the same range (would reduce rack diversity)
- Any topology change while range movements are in progress

### Propagation
- Changes commit atomically through TCM
- System tables (`system.local` and `system.peers_v2`) are updated asynchronously on all nodes
- Gossip state (DC, RACK application states) is updated on all nodes

### JMX interface
- `StorageServiceMBean.alterTopology(String updates)` -- accepts comma-delimited `nodeId=dc:rack` pairs

## Docs Impact
- **Existing pages likely affected:**
  - `doc/modules/cassandra/pages/managing/operating/snitch.adoc` -- should reference `altertopology` as the approved way to change DC/rack for live nodes in Cassandra 6.0 (replacing the old guidance to decommission and rejoin)
  - `doc/modules/cassandra/pages/managing/configuration/cass_rackdc_file.adoc` -- should note that changing the rackdc file alone does not change a node's registered topology in 6.0; `altertopology` is needed
  - `doc/modules/cassandra/pages/managing/configuration/cass_topo_file.adoc` -- same note as above
  - `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc` -- may need reference
  - `doc/modules/cassandra/pages/new/index.adoc` -- should mention this as a new 6.0 operational capability
- **New pages likely needed:**
  - Generated nodetool reference page for `altertopology` (generated surface -- needs generator run)
  - Possible new operator guide section on topology management (could be added to snitch.adoc or a new page)
- **Audience home:** Operators > Managing > Operating or Operators > Managing > Tools > nodetool
- **Authored or generated:** Mixed -- nodetool reference is generated; operator guidance is authored
- **Technical review needed from:** Sam Tunnicliffe (author), Marcus Eriksson (reviewer)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: snitch.adoc; cass_rackdc_file.adoc; cass_topo_file.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions
1. Should `altertopology` be mentioned in NEWS.txt? It is currently absent despite being a significant new operator capability.
2. What is the interaction with the CASSANDRA-19488 snitch deprecation docs? The snitch page will likely need restructuring anyway; should `altertopology` guidance be folded into that rewrite?
3. Are there plans for a CQL-level equivalent (e.g., `ALTER NODE` or `ALTER TOPOLOGY`)? Currently this is nodetool/JMX only.
4. Should the generated nodetool docs be regenerated now to pick up `altertopology`, or wait until a full generated-doc pass?

## Next Research Steps
- Regenerate nodetool docs to confirm `altertopology` appears in the generated output
- Coordinate with CASSANDRA-19488 snitch deprecation docs work to avoid duplication
- Determine if NEWS.txt should be updated to mention this feature
- Draft operator guidance section covering common topology change scenarios and safety rules

## Notes
- This feature is only possible because of TCM (CASSANDRA-18330 / CEP-21): ClusterMetadata is now the single source of truth for topology, so DC/rack can be changed in one place and propagated consistently.
- The safety validation is a key design feature: the transformation calculates what placements would look like after the change and compares them to current placements. Only changes that produce identical placements are accepted.
- The `DataPlacements.equivalentTo()` method was added specifically for this feature to compare placement outcomes while being tolerant of Location differences.
- Node identifiers are flexible: operators can use the numeric node ID (from `nodetool ring`), the UUID host ID (from `nodetool info`), or the broadcast IP address. This makes the command accessible regardless of which identifier the operator has at hand.
- The argument parsing supports both comma-separated (via JMX: `"1=dc1:rack1,2=dc2:rack2"`) and space-separated (via nodetool CLI: `1=dc1:rack1 2=dc2:rack2`) formats, as the nodetool command joins args with commas before passing to the MBean.
