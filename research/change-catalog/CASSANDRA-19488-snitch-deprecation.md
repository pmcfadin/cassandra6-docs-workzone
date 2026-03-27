# CASSANDRA-19488: IEndpointSnitch Deprecation and New Locator System

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
IEndpointSnitch is deprecated in Cassandra 6.0. Its responsibilities have been decomposed into four focused interfaces/classes: `Locator` (datacenter/rack lookups from ClusterMetadata), `InitialLocationProvider` (one-time DC/rack registration for new nodes), `NodeProximity` (replica list sorting/ranking), and `NodeAddressConfig` (public/private address configuration). The legacy `endpoint_snitch` YAML setting continues to work seamlessly via a `SnitchAdapter` bridge class, so no operator action is required at upgrade time.

## Discovery Source
- NEWS.txt (6.0 section, line 216)
- CHANGES.txt (line 201: "Deprecate IEndpointSnitch (CASSANDRA-19488)")
- `conf/cassandra.yaml` (lines 1484-1661)

## Why It Matters
The snitch is one of the most commonly configured and documented aspects of Cassandra. Every production deployment guide, architecture overview, and configuration reference discusses snitches. This deprecation fundamentally changes the recommended configuration model for topology, proximity, and addressing -- shifting from a single monolithic class to composable, single-responsibility settings. Documentation must guide both new users (toward the new model) and existing users (explaining that their current config still works).

## Source Evidence

### cassandra.yaml (conf/cassandra.yaml)
- **Line 1484**: `# IEndpointSnitch has been deprecated in Cassandra 6.0`
- **Line 1570**: `endpoint_snitch: SimpleSnitch` (still the default, still functional)
- **Lines 1572-1576**: New settings listed: `initial_location_provider`, `node_proximity`, `addresses_config`, `prefer_local_connections`
- **Line 1624**: `#initial_location_provider: SimpleLocationProvider` (commented out)
- **Line 1641**: `#node_proximity: NetworkTopologyProximity` (commented out)
- **Line 1649**: `#addresses_config: Ec2MultiRegionAddressConfig` (commented out)
- **Line 1661**: `#prefer_local_connections: false` (commented out)

### NEWS.txt (line 216-232)
Full explanation of the deprecation and the four replacement components, including statement that no action is required at upgrade time.

### New Interfaces (src/java/org/apache/cassandra/locator/)
- **InitialLocationProvider.java** -- Interface with `initialLocation()` returning a `Location` (DC + rack). Used exactly once when a new node joins.
- **NodeProximity.java** -- Interface for `sortedByProximity()`, `compareEndpoints()`, and `isWorthMergingForRangeQuery()`.
- **NodeAddressConfig.java** -- Interface for `configureAddresses()` and `preferLocalConnections()`. Has a DEFAULT implementation that is a no-op for addresses and reads `prefer_local_connections` from DatabaseDescriptor.
- **Locator.java** -- Concrete class (not configurable). Provides `location(endpoint)` by reading from ClusterMetadata directory, falling back to InitialLocationProvider during pre-registration phase.

### SnitchAdapter.java
Bridge class that wraps any `IEndpointSnitch` and implements all three new interfaces (`InitialLocationProvider`, `NodeProximity`, `NodeAddressConfig`). This is the backward-compatibility mechanism: when `endpoint_snitch` is configured, its snitch is wrapped in a SnitchAdapter.

### InitialLocationProvider Implementations
| New Provider | Replaces Snitch |
|---|---|
| SimpleLocationProvider | SimpleSnitch |
| RackDCFileLocationProvider | GossipingPropertyFileSnitch |
| TopologyFileLocationProvider | PropertyFileSnitch |
| Ec2LocationProvider | Ec2Snitch / Ec2MultiRegionSnitch |
| AlibabaCloudLocationProvider | AlibabaCloudSnitch |
| AzureCloudLocationProvider | AzureSnitch |
| GoogleCloudLocationProvider | GoogleCloudSnitch |
| CloudstackLocationProvider | CloudstackSnitch (also deprecated) |

### NodeProximity Implementations
| New Class | Replaces Behavior Of |
|---|---|
| NoOpProximity | SimpleSnitch |
| NetworkTopologyProximity | GossipingPropertyFileSnitch, PropertyFileSnitch, all cloud snitches |

### NodeAddressConfig Implementations
| New Class | Replaces Behavior Of |
|---|---|
| NodeAddressConfig.DEFAULT (inline) | Most snitches (no-op for addresses) |
| Ec2MultiRegionAddressConfig | Ec2MultiRegionSnitch |

## What Changed

### New YAML Settings
1. **`initial_location_provider`** -- Replaces the DC/rack determination role of endpoint_snitch. Only used once at first join, then ClusterMetadata is authoritative.
2. **`node_proximity`** -- Replaces the request-routing/proximity role of endpoint_snitch. Two options: `NoOpProximity` (like SimpleSnitch) or `NetworkTopologyProximity` (like topology-aware snitches).
3. **`addresses_config`** -- Replaces the address-configuration role (only relevant for Ec2MultiRegionSnitch equivalent scenarios). Optional.
4. **`prefer_local_connections`** -- Replaces the `prefer_local` property from cassandra-rackdc.properties and the hard-coded behavior from Ec2MultiRegionSnitch. Optional, defaults to false.

### Architectural Shift
- Location (DC/rack) is now persisted in and sourced from **ClusterMetadata** after initial registration, not continuously from the snitch.
- The `Locator` class is the central lookup mechanism; it is not user-configurable.
- The `DynamicEndpointSnitch` now implements `NodeProximity` directly.

### Backward Compatibility
- `endpoint_snitch` YAML setting still works. All existing IEndpointSnitch implementations are supported.
- `SnitchAdapter` transparently bridges old snitches to the new interface system.
- No action required at upgrade time -- this is explicitly stated in NEWS.txt.

## Docs Impact

### HIGH IMPACT: Snitch Operating Page (doc/modules/cassandra/pages/managing/operating/snitch.adoc)
- Current page is entirely about the old IEndpointSnitch model.
- Needs complete rewrite or major restructuring to present the new model as primary, with legacy snitch info in a deprecation/migration section.
- All snitch class descriptions need corresponding new-model equivalents documented.

### HIGH IMPACT: Configuration Reference (doc/modules/cassandra/pages/managing/configuration/configuration.adoc)
- Must document four new YAML settings: `initial_location_provider`, `node_proximity`, `addresses_config`, `prefer_local_connections`.
- Must mark `endpoint_snitch` as deprecated with pointer to new settings.

### MEDIUM IMPACT: cassandra-rackdc.properties Page (doc/modules/cassandra/pages/managing/configuration/cass_rackdc_file.adoc)
- Still references GossipingPropertyFileSnitch as "recommended for production" and primary use case.
- Needs note that `RackDCFileLocationProvider` is the modern equivalent.
- The `prefer_local` property explanation should reference new `prefer_local_connections` YAML setting.

### MEDIUM IMPACT: cassandra-topologies.properties Page (doc/modules/cassandra/pages/managing/configuration/cass_topo_file.adoc)
- References PropertyFileSnitch exclusively.
- Needs note about `TopologyFileLocationProvider` as modern equivalent.
- Should note that only local node's entry is relevant in new model (other entries ignored).

### MEDIUM IMPACT: Production Deployment Guide (doc/modules/cassandra/pages/getting-started/production.adoc)
- Line 156-163 discusses "Configure racks and snitch" with recommendations for GossipingPropertyFileSnitch and Ec2Snitch.
- Should be updated to recommend new configuration model.

### MEDIUM IMPACT: Architecture / Dynamo Page (doc/modules/cassandra/pages/architecture/dynamo.adoc)
- Line 199 references "the Snitch" in context of NetworkTopologyStrategy rack selection.
- Minor update needed to reflect that topology now comes from ClusterMetadata.

### LOW IMPACT: What's New Page (doc/modules/cassandra/pages/new/index.adoc)
- Line 32 mentions "New snitch for Microsoft Azure" for 5.0.
- Should add entry for 6.0 about snitch deprecation and new locator system.

### NEW CONTENT NEEDED: Upgrade Guide
- Migration mapping table (old snitch -> new settings combination).
- Clear statement that no action is required at upgrade.
- Guidance for when/why users might want to migrate to new settings.

### Navigation (doc/modules/cassandra/nav.adoc)
- Line 108: `**** xref:cassandra:managing/operating/snitch.adoc[Snitches]` -- may need renaming or expansion to cover new model.

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: snitch.adoc; configuration.adoc; cass_rackdc_file.adoc; cass_topo_file.adoc; production.adoc; dynamo.adoc
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
1. Should the snitch.adoc page be renamed (e.g., "Topology Configuration" or "Location and Proximity") to reflect the broader scope, or keep the old name for discoverability?
2. Is there a timeline for actual removal of IEndpointSnitch support, or is it deprecated indefinitely? This affects how urgently migration guidance should be presented.
3. The `addresses_config` YAML key uses `addresses_config` in the setting list (line 1575) but `addresses_config` in the actual setting (line 1649). The NEWS.txt refers to it as `address_config`. Need to verify the canonical YAML key name.
4. Should custom snitch authors receive guidance on migrating to the new interfaces?

## Next Research Steps
1. Check the JIRA ticket (CASSANDRA-19488) for discussion about documentation plans or migration guidance.
2. Review DatabaseDescriptor for how the new settings are loaded and how fallback to endpoint_snitch works.
3. Look for any test cases that demonstrate the new configuration model in action.
4. Check if there are any other doc pages that reference snitches (e.g., security.adoc was flagged in grep results).

## Notes
- The YAML file uses `addresses_config` (plural) as the setting name, not `address_config` (singular) as mentioned in NEWS.txt. The canonical name appears to be `addresses_config` based on the YAML.
- CloudstackSnitch and CloudstackLocationProvider are both marked as deprecated and scheduled for removal in a future version.
- The `Locator` class is not an interface and not configurable -- it always reads from ClusterMetadata. This is a significant conceptual shift: location is no longer "computed" by a snitch but "looked up" from cluster state.
- The `initial_location_provider` is used exactly once in a node's lifecycle (first join). This is a key distinction from the old model where the snitch was always active.
