# Chapter 11: Glossary

This glossary defines the core terms used throughout the Transactional Cluster Metadata (TCM) guide. Definitions are written for Cassandra operators and focus on operational meaning, not only implementation details.

## A

**Accord**: Cassandra's distributed transaction subsystem (introduced for newer transaction semantics). In TCM contexts, certain topology operations may wait for Accord metadata readiness before finalizing.

**AlterSchema**: A TCM transformation type that applies schema changes through the metadata log. It replaces gossip-era, eventually consistent schema propagation with ordered commits.

**ApplicationState**: Gossip key/value state slots (for example `TOKENS`, `STATUS_WITH_PORT`, `SCHEMA`). Under TCM, many of these states are still published for compatibility, even though authoritative metadata comes from the log.

**Assassinate**: A forceful node-removal operation (`nodetool assassinate`) historically used as a last resort. It is high risk during upgrade windows and should be avoided unless explicitly required by incident procedure.

## B

**Bootstrap**: The process of adding a node and streaming its owned ranges. Under TCM, bootstrap is a tracked multi-step operation with explicit metadata transitions.

**BTI format**: A Cassandra SSTable format option. TCM is storage-format agnostic and works regardless of BTI/BIG usage.

## C

**Cassandra 6.0 threshold**: The minimum Cassandra version required to initialize TCM (CEP-21 implementation boundary). Nodes below this version block CMS initialization unless intentionally ignored.

**`cassandra.yaml`**: Primary Cassandra node configuration file. TCM-related controls such as `unsafe_tcm_mode`, progress barrier settings, and timeout parameters are configured here.

**Cluster Metadata**: The complete logical state that describes cluster identity and behavior (directory, token ownership, schema, placements, locks, and in-progress operations).

**Cluster Metadata Service (CMS)**: The Paxos-backed group of nodes that serializes metadata commits for TCM.

**`ClusterMetadataService`**: Core service class that coordinates metadata commit/replication behavior on each node.

**Commit (metadata)**: The act of durably appending a transformation to the distributed metadata log at a new epoch.

**Commit pause**: A deliberate operational pause of metadata commits (`nodetool cms set_commits_paused true`) used during investigation or incident containment.

**Consistency level (progress barrier)**: The acknowledgement requirement used by progress barriers (`EACH_QUORUM`, `QUORUM`, `LOCAL_QUORUM`, `ONE`, `NODE_LOCAL`) to ensure propagation before advancing an operation.

## D

**Data placements**: Replica placement mappings derived from topology and keyspace replication settings. TCM updates placements deterministically via ordered transformations.

**Decommission**: Graceful node removal operation. Under TCM, decommission is explicit and resumable across metadata phases.

**Directory**: TCM metadata structure that tracks nodes, addresses, versions, states, and related identity data.

**Discovery**: Mechanism used by nodes to locate CMS/seed peers and establish metadata synchronization paths.

**Distributed metadata log**: The ordered, replicated log of cluster metadata transformations, stored in `system_cluster_metadata.distributed_metadata_log`.

**Distributed schema**: Schema representation bundled into immutable metadata snapshots and advanced by epochs.

**Driver topology events**: Notifications sent to drivers when cluster topology changes. These remain supported under TCM.

## E

**Election (CMS initialization)**: The startup/upgrade process that confirms cluster agreement and establishes the first CMS member.

**EndpointState**: Gossip-level representation of node state exchanged between peers.

**Epoch**: Monotonically increasing metadata version number. Each committed transformation advances the epoch.

**Epoch divergence**: Temporary state where nodes report different epochs. Usually self-healing; persistent gaps indicate connectivity or log-application issues.

## F

**Failure detector (FD)**: Gossip-based heartbeat suspicion mechanism. TCM does not replace this; failure detection remains gossip-driven.

**`FetchCMSLog` / `FetchPeerLog`**: Log synchronization handlers used to retrieve missing metadata entries from CMS members or peers.

**`finishInProgressSequences()`**: Recovery behavior that resumes interrupted multi-step topology operations after restart.

**ForceSnapshot**: Emergency transformation path (unsafe workflows) that can force metadata state to a specific snapshot.

## G

**Gossip**: Cassandra's peer-to-peer dissemination subsystem. Under TCM, it remains active for failure detection and transient states but no longer acts as metadata authority.

**GOSSIP service state**: Transitional node service state where TCM-capable binaries are running but CMS has not been initialized.

**`GossipHelper`**: Compatibility bridge that translates TCM state into legacy gossip application states.

## H

**Host ID**: Persistent node identity UUID used in cluster membership and operational tooling.

## I

**InProgressSequences**: Metadata structure that tracks active multi-step topology operations (join, leave, move, replace, reconfigure CMS).

**Initialize CMS**: `nodetool cms initialize` operation that migrates metadata authority from gossip-era behavior to TCM log authority.

**Is Migrating**: `nodetool cms describe` field showing whether a CMS migration/reconfiguration workflow is currently in progress.

## J

**JOINED state**: Stable membership state indicating a node is fully participating in cluster operations.

**JMX `CMSOperations`**: MBean interface exposing administrative CMS actions, including advanced and unsafe operations.

## L

**`LegacyStateListener`**: Component that mirrors TCM-managed metadata into gossip states for tooling and compatibility.

**`LOCAL` / `REMOTE` service states**: `LOCAL` indicates CMS member behavior on the node; `REMOTE` indicates non-CMS nodes forwarding commits to CMS.

**Local pending count**: `nodetool cms describe` signal for out-of-order entries waiting for predecessors before apply.

**`LocalLog`**: Per-node manager of metadata entries, ordering, and apply progression.

**Locked ranges**: Range-level locks used to prevent conflicting concurrent topology operations.

**Log watermark**: The highest epoch a node has applied, used as the primary synchronization indicator.

## M

**Metadata snapshot**: Serialized full cluster metadata image at a specific epoch, used to speed catch-up for lagging/restarting nodes.

**Messaging version**: Inter-node protocol version. Mixed messaging versions during major upgrades are a key reason schema changes are unsafe.

**MID phase**: The data-movement phase of TCM topology workflows (`MidJoin`, `MidLeave`, `MidMove`, `MidReplace`).

**Mixed-version window**: Upgrade period where nodes run different major/minor binaries. Metadata-changing operations are restricted here.

**`MultiStepOperation`**: Base lifecycle pattern for coordinated topology operations executed across multiple epochs.

## N

**NetworkTopologyStrategy (NTS)**: Replication strategy that distributes replicas across racks/DCs. CMS placement logic follows similar failure-domain principles.

**Node ID (`NodeId`)**: Internal metadata identity used in TCM maps and transforms.

**Node lifecycle state**: Membership progression states such as `REGISTERED`, `BOOTSTRAPPING`, `JOINED`, `LEAVING`, `LEFT`.

**`nodetool cms describe`**: Primary command for checking CMS membership, epoch, service state, and migration/commit status.

**`nodetool cms initialize`**: Command that starts CMS and activates TCM metadata authority.

**`nodetool cms reconfigure`**: Command that adjusts CMS membership size/distribution.

## P

**Paxos (TCM context)**: Consensus protocol used by CMS to linearize metadata commits.

**`PaxosBackedProcessor`**: CMS-side commit processor implementation that uses Paxos writes for metadata entries.

**PeerLogFetcher**: Background mechanism for non-CMS nodes to fetch and apply missing log entries.

**PREPARE phase**: Validation/locking phase before topology data movement begins.

**Progress barrier**: Synchronization mechanism that waits for affected nodes to acknowledge an epoch before operation progression.

**Progress barrier CL relaxation**: Controlled fallback sequence that lowers acknowledgement strictness when some nodes are unavailable.

## Q

**Quorum (CMS)**: Majority requirement for metadata consensus. If quorum is lost, metadata changes pause while normal data reads/writes can continue.

**Quorum loss**: Condition where more than half of CMS members are unavailable, blocking metadata commits.

## R

**Range locking**: Conflict-prevention mechanism that blocks overlapping topology operations affecting the same token ranges.

**Registration status**: Indicator showing whether a node completed TCM registration in cluster metadata.

**`ReconfigureCMS`**: Transformation family for safely changing CMS membership.

**`RemoteProcessor`**: Non-CMS commit path that forwards transformations to CMS for consensus.

**Repair state**: Ongoing repair operations that should generally be drained before major upgrade/migration steps.

## S

**Schema convergence**: Condition where all nodes share one schema version/digest.

**Schema digest**: Hash-based schema fingerprint used during initialization agreement checks.

**Service state**: TCM execution mode on a node (`LOCAL`, `REMOTE`, or `GOSSIP` during transition).

**`SimpleStrategy` (initial CMS state)**: Replication strategy used for initial metadata keyspace setup before production reconfiguration.

**Snapshot frequency**: Configuration controlling how often metadata snapshots are created to cap replay/catch-up cost.

**Split-brain metadata**: Divergent cluster-state views across coordinators. TCM is designed to eliminate this for managed metadata domains.

**START phase**: Phase where operation intent is committed and visible cluster-wide before data transfer.

**Streaming**: Data transfer process used by bootstrap/decommission/move/replace operations.

**`system_cluster_metadata` keyspace**: System keyspace that stores TCM metadata log and related internal state.

**`system_views.cluster_metadata_log`**: Virtual table view for inspecting recent metadata entries and epochs.

**`system_views.cluster_metadata_directory`**: Virtual table view for inspecting node directory/state from TCM metadata.

## T

**TCM (Transactional Cluster Metadata)**: Cassandra metadata model that uses an ordered, consensus-backed log for correctness-critical cluster state.

**`TCM_COMMIT_REQ`**: Internal message verb used by non-CMS nodes to submit metadata commits to CMS.

**`TCM_CURRENT_EPOCH_REQ`**: Internal message verb used by progress barriers to confirm epoch visibility on peers.

**Token map**: Mapping between tokens/ranges and owning nodes, now updated by committed transformations.

**Topology operation**: Metadata-changing cluster operation such as join, leave, move, replace, remove, or CMS reconfiguration.

**Transformation**: Atomic metadata change unit committed at one epoch.

## U

**`unsafe_tcm_mode`**: Configuration gate that enables dangerous/manual metadata recovery procedures.

**`unsafeLoadClusterMetadata`**: JMX recovery method that loads metadata state from a dump file under unsafe mode.

**`unsafeRevertClusterMetadata`**: JMX recovery method that reverts metadata to a prior epoch under unsafe mode.

**`unreachableCMSMembers`**: Key health metric indicating currently unreachable CMS nodes.

## V

**Validation smoke test**: Post-enable confirmation workflow (typically schema create/propagate/drop plus epoch checks).

**`Version.OLD`**: Internal metadata-version marker for pre-upgraded nodes during migration checks.

## W

**Watermark**: See **Log watermark**.
