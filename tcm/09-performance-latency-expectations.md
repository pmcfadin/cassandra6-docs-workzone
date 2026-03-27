# Chapter 9: Performance and Latency Expectations

The most common question operators ask after learning how TCM works is: "How much does it cost?" They mean latency. They mean overhead. They want to know whether the Paxos consensus that makes metadata operations safe also makes them slow, and whether the epoch-checking machinery adds anything to the read/write hot path.

The short answers: metadata commits take 100-300 milliseconds (Paxos round-trips plus network latency). The read/write hot path is not affected — epoch checks are in-memory integer comparisons, not serialized operations. And the metadata itself is tiny. The entire cluster state — schema, token map, directory, placements — fits in a single serialized object that is measured in kilobytes, not megabytes.

This chapter provides the numbers, explains where they come from, and tells you what to tune if your environment does not match the defaults.

## Learning Objectives

- Estimate realistic metadata commit latency across deployment topologies.
- Tune CMS sizing, timeout, and retry controls based on measured behavior.
- Define actionable performance alerts that reflect TCM-specific failure modes.

## What TCM Adds to the Critical Path

Before diving into specific operations, it is important to understand what TCM does and does not touch during normal cluster operations.

### The Read/Write Hot Path: No Overhead

TCM does not sit in the read/write request path. When a coordinator receives a read or write request, it looks up the current replica placements from an in-memory `ClusterMetadata` object. This is the same object it has always used — TCM changes how the object is populated, not how it is consulted.

The only per-request check is an epoch comparison. When a coordinator processes a request and receives a response from a replica, the response may include the replica's current epoch. If the replica's epoch is higher than the coordinator's, the coordinator triggers an asynchronous background fetch to update its local metadata. This fetch does not block the request. The request completes with the coordinator's current metadata view, and the metadata update happens in the background.

The `EpochAwareDebounce` class ensures that concurrent requests for the same epoch are deduplicated — if ten requests all discover that the coordinator is behind epoch 42, only one log fetch is triggered, not ten. The deduplication is cache-backed with a configurable maximum size.

Two metrics track how often coordinators are behind:

- `coordinatorBehindSchema` — the coordinator's schema is older than a replica's
- `coordinatorBehindPlacements` — the coordinator's placement information is older than a replica's

In a healthy cluster, both of these should be near zero. Non-zero values indicate that metadata changes are happening and some coordinators have not yet caught up — which is normal during topology changes and schema modifications. Persistently high values suggest that some nodes are not fetching log updates, which warrants investigation.

### The Metadata Path: Paxos Cost

Metadata operations — creating a table, bootstrapping a node, reconfiguring CMS — go through the Paxos consensus path. This is where TCM adds latency compared to the old gossip approach (which had no consensus cost, but also no consistency guarantee).

A metadata commit requires two Paxos phases:

1. **Prepare phase.** The CMS leader sends a prepare request to a quorum of CMS members. Each member checks whether it has seen a higher ballot and responds with its current state.

2. **Accept/Commit phase.** The leader sends the committed transformation to the quorum. Each member writes the log entry to its local `system_cluster_metadata.distributed_metadata_log` table and acknowledges.

The quorum size depends on CMS membership:

| CMS Members | Quorum Required | Paxos Participants |
|-------------|-----------------|-------------------|
| 3 | 2 | 2 of 3 |
| 5 | 3 | 3 of 5 |
| 7 | 4 | 4 of 7 |

Each Paxos phase requires a network round-trip to the quorum. In a same-datacenter deployment, a network round-trip is typically 1-5 milliseconds. Cross-datacenter round-trips range from 20-100 milliseconds depending on geography. Add local disk write time (1-5 milliseconds per member) and serialization overhead, and the total commit time falls in these ranges:

| Deployment | 3-Member CMS | 5-Member CMS | 7-Member CMS |
|-----------|-------------|-------------|-------------|
| Same DC | 50-100 ms | 100-200 ms | 150-300 ms |
| Multi-DC (US regions) | 100-200 ms | 150-300 ms | 200-400 ms |
| Multi-DC (global) | 200-400 ms | 300-500 ms | 400-700 ms |

These numbers represent the wall-clock time from submitting a transformation to receiving confirmation that it was committed. They are estimates based on typical Paxos latency characteristics — your actual numbers will vary based on network quality, disk speed, and CMS member placement.

### What This Means for Schema Changes

Schema changes (CREATE TABLE, ALTER TABLE, DROP TABLE) are metadata commits. Under gossip, schema propagation was eventually consistent — you would issue the DDL statement, and it would propagate through gossip over a period of seconds to tens of seconds. There was no confirmation that all nodes had received it, and no ordering guarantee if multiple schema changes were issued in quick succession.

Under TCM, a schema change is a single Paxos commit. It takes 100-300 milliseconds for the commit itself. After the commit, the new epoch propagates to all nodes through the log replication mechanism. The schema change is ordered — every node applies it at the same epoch, in the same sequence relative to other changes.

The net result is that schema changes are **faster to confirm** under TCM (you know within milliseconds that the change is committed) but the propagation to all nodes takes the same amount of time as log replication (50-500 milliseconds depending on topology). Under gossip, you had no confirmation at all — you issued the change and hoped it propagated.

## Log Replication Speed

After a metadata commit, non-CMS nodes need to learn about the new epoch. This happens through two mechanisms, and understanding their latency characteristics helps set expectations.

### Push: Epoch Notifications

When a topology operation commits a new epoch, the progress barrier sends `TCM_CURRENT_EPOCH_REQ` messages to affected nodes. These nodes learn about the new epoch and trigger a log fetch if they are behind. This is effectively a push notification — the committing node tells affected nodes that something changed.

The push latency is one network round-trip plus the time to fetch and apply the log entry. In a same-datacenter deployment, this is typically 50-150 milliseconds. Cross-datacenter, it is 200-500 milliseconds.

### Pull: Background Fetching

Non-CMS nodes also have a `PeerLogFetcher` that periodically checks whether new log entries are available. When a node discovers (through any mechanism — a coordinator response, a gossip exchange, a direct notification) that it is behind, it fetches the missing entries from a CMS peer or any node that is ahead.

The fetch is asynchronous and uses exponential backoff on retry. The default timeout for a single fetch is the `cms_await_timeout` value (120 seconds by default). In practice, fetches complete in milliseconds — the timeout exists to handle network partitions and unresponsive nodes.

### Progress Barrier Latency

The progress barrier is the mechanism that ensures a quorum of affected nodes has seen a new epoch before a topology operation proceeds to its next step. Its latency depends on how quickly nodes respond.

**Healthy cluster:** The barrier sends probes to all affected nodes in parallel and collects responses. If a quorum responds within the first round, the barrier completes in 100-500 milliseconds — one round-trip plus processing time.

**Partially degraded cluster:** If some nodes are slow to respond, the barrier retries with a 1-second backoff (`progress_barrier_backoff`). After the configured timeout at the current consistency level, it degrades: `EACH_QUORUM` → `QUORUM` → `LOCAL_QUORUM` → `ONE` → `NODE_LOCAL`. Each degradation produces a log message.

**Severely degraded cluster:** The barrier's maximum timeout is 1 hour (`progress_barrier_timeout`). This is deliberately long — it gives operators time to restore connectivity before the system gives up. In practice, the barrier should complete within seconds unless there is a genuine network issue.

The three metrics to watch:

- `progressBarrierLatency` — how long the barrier took to complete. Should be under 2 seconds normally.
- `progressBarrierRetries` — how many retry rounds were needed. Should be near zero in a healthy cluster.
- `progressBarrierCLRelaxed` — how many times the consistency level was degraded. Any non-zero value indicates that some nodes were unreachable at the initial consistency level.

## CMS Sizing and Performance

The number of CMS members affects both resilience and commit latency. The tradeoff is straightforward: more members means higher fault tolerance but higher Paxos latency, because the quorum (and therefore the number of nodes that must respond) is larger.

### The Practical Impact

For most clusters, the latency difference between 3-member and 5-member CMS is negligible — 50-100 milliseconds per commit. Metadata commits are infrequent operations (topology changes, schema modifications), not part of the read/write hot path. You will not notice the difference in daily operations.

The jump from 5 to 7 members adds another 50-100 milliseconds and gains one additional node of fault tolerance. Whether this is worth it depends on your failure domain architecture. If your CMS members are spread across three availability zones and a zone outage would take two members down, a 5-member CMS with 2-zone tolerance is sufficient. If your members are spread across more zones, 7 members provides extra margin.

### The Recommendation

For production clusters, **5 CMS members** provides the best balance of latency and fault tolerance. This gives you:

- 3-node quorum (fast consensus)
- 2-node failure tolerance (survives AZ outage)
- Straightforward rack-diverse placement
- Commit latency in the 100-300 millisecond range

Only move to 7 members if you have a specific fault tolerance requirement that demands it, and only stay at 3 members for development or testing environments where fault tolerance is less important than simplicity.

## Memory and Storage Footprint

### In-Memory Cost

The `ClusterMetadata` object is held entirely in memory on every node. It is a single immutable instance that contains:

- `DistributedSchema` — all keyspace and table definitions
- `Directory` — all node registrations, states, and locations
- `TokenMap` — token-to-node assignments
- `DataPlacements` — replica placement maps for all keyspaces
- `LockedRanges` — currently locked ranges from in-progress operations
- `InProgressSequences` — active topology change sequences

For a typical cluster (10-50 nodes, 50-200 tables), this object is measured in tens of kilobytes. For a large cluster (hundreds of nodes, thousands of tables), it may reach low megabytes. This is well within the memory budget of any production Cassandra node.

When a new epoch is committed, a new `ClusterMetadata` instance is created (they are immutable). The old instance is eligible for garbage collection once all references to it are released. Expensive derived values (like full CMS replica sets and settled placement maps) are lazily cached — they are computed on first access and stored for subsequent reads, avoiding recomputation on every epoch change.

### Log Storage

The metadata log is stored in the `system_cluster_metadata.distributed_metadata_log` table. Each entry contains the epoch number, an entry ID, the serialized transformation, and the transformation kind. Individual entries are small — a typical schema change serializes to a few hundred bytes; a topology change with placement deltas may be a few kilobytes.

The log grows linearly with the number of metadata changes. For a cluster that makes a few schema changes per day and occasional topology changes, the log grows very slowly. For a cluster undergoing a major rebalancing (adding many nodes), the log may accumulate hundreds of entries over a short period.

### Snapshots and Log Compaction

To prevent unbounded log growth and to speed up node recovery, TCM periodically creates metadata snapshots. A snapshot is a complete serialized `ClusterMetadata` image at a specific epoch. When a node needs to catch up from an older epoch, it can load the nearest snapshot and replay only the log entries after that point, rather than replaying the entire log from the beginning.

Snapshot frequency is configurable via `metadata_snapshot_frequency`. The tradeoff:

- **More frequent snapshots** (every 10-20 epochs): faster node recovery, but more storage and CPU for serialization
- **Less frequent snapshots** (every 100-500 epochs): lower storage overhead, but slower recovery for nodes that fall far behind

For clusters with frequent topology changes (multiple bootstraps or decommissions per day), every 10-20 epochs is reasonable. For stable clusters where metadata changes are infrequent, every 50-100 epochs is sufficient.

Snapshot serialization is the most expensive metadata operation in terms of CPU. The full `ClusterMetadata` object must be serialized to bytes using `VerboseMetadataSerializer`, which includes the entire schema, directory, and placement information. On a cluster with hundreds of tables, this can take tens of milliseconds. It happens in the background and does not block other operations.

## Timeout and Retry Configuration

TCM has several configurable timeouts that control how long the system waits before giving up or degrading. The defaults are conservative — designed to handle worst-case scenarios without operator intervention.

### Configuration Reference

| Parameter | Default | Purpose |
|-----------|---------|---------|
| `cms_await_timeout` | 120 seconds | Maximum time to wait for a CMS commit or log fetch |
| `cms_retry_delay` | `50ms*attempts <= 500ms ... 100ms*attempts <= 1s,retries=10` | Backoff specification for commit retries |
| `progress_barrier_timeout` | 3600 seconds (1 hour) | Maximum time for a progress barrier to complete |
| `progress_barrier_backoff` | 1000 ms | Time between barrier retry attempts |
| `progress_barrier_default_consistency_level` | EACH_QUORUM | Starting consistency level for barriers |
| `progress_barrier_min_consistency_level` | EACH_QUORUM | Minimum consistency level before the barrier fails |

### Tuning for Your Environment

**Same-datacenter clusters:** You can reduce timeouts significantly. Metadata commits and log replication should complete in milliseconds, not minutes. Consider:

```yaml
cms_await_timeout: 30s
progress_barrier_timeout: 300s    # 5 minutes
progress_barrier_backoff: 500ms
```

**Multi-datacenter clusters with reliable connectivity:** The defaults are reasonable. The 120-second commit timeout handles cross-datacenter latency comfortably. The 1-hour barrier timeout is generous but prevents false failures during temporary network blips.

**Multi-datacenter clusters with unreliable connectivity:** Consider increasing the barrier backoff to reduce retry pressure on already-stressed network links:

```yaml
progress_barrier_backoff: 5000ms    # 5 seconds between retries
progress_barrier_timeout: 1800s     # 30 minutes
```

### The Retry Specification Format

The `cms_retry_delay` parameter uses a compact specification format:

```
50ms*attempts <= 500ms ... 100ms*attempts <= 1s,retries=10
```

This reads as: "Back off by 50 milliseconds per attempt, up to a maximum of 500 milliseconds total for the first phase. Then switch to 100 milliseconds per attempt, up to 1 second. Stop after 10 total retries."

The default is appropriate for most deployments. If you find that metadata commits are retrying frequently (check the `commitRetries` metric), the issue is more likely network or CMS availability than retry timing.

### Startup Retry Behavior

One important exception: transformations of kind `STARTUP` (node boot operations) retry indefinitely. When a node is starting up and needs to commit its presence to the metadata log, there is no point in timing out — the node cannot serve traffic until it has joined the cluster. The retry uses 100-millisecond initial backoff with a 10-second maximum, but no overall time limit.

This means a node starting up during a CMS outage will retry forever, which is the correct behavior — it will eventually join when the CMS becomes available.

## Gossip vs. TCM: A Latency Comparison

The comparison is not entirely apples-to-apples, because gossip and TCM provide different guarantees. Gossip is faster to *initiate* a change (just broadcast to peers) but slower to *confirm* it (wait for eventual propagation). TCM is slower to *commit* (Paxos round-trips) but faster to *confirm* (epoch ordering with progress barriers).

| Operation | Gossip | TCM | Notes |
|-----------|--------|-----|-------|
| Schema change initiation | < 10 ms | 100-300 ms | Gossip: fire-and-forget. TCM: Paxos commit. |
| Schema change confirmation | Unknown (10-30s propagation) | 100-300 ms | Gossip: no confirmation. TCM: commit is confirmation. |
| Topology change visibility | 5-30 seconds (gossip propagation) | Sub-second (epoch commit) | TCM wins decisively. |
| Ring settle after topology change | 30-60 seconds (manual wait) | 0 seconds (barrier-based) | TCM eliminates this entirely. |
| Per-request overhead | None | None (epoch comparison in memory) | Both are negligible. |
| Concurrent topology changes | Unsafe | Safe with range locking | TCM adds coordination cost but prevents errors. |

The key insight is that TCM trades a small per-commit cost (100-300 milliseconds of Paxos latency) for the elimination of much larger operational costs (30-60 seconds of ring-settle waiting, seconds to minutes of gossip propagation uncertainty, and the risk of silent data loss from split-brain quorum inconsistency).

For a cluster expansion adding 10 nodes, the old gossip approach required 5-10 minutes of idle ring-settle waiting. TCM eliminates that entirely. The Paxos commits for 10 three-step bootstrap sequences (30 commits total) add perhaps 3-9 seconds of cumulative commit latency. The net time savings is measured in minutes.

## Monitoring Recommendations

### Key Metrics to Watch

The TCM metrics are exposed through the standard Cassandra metrics framework (JMX, Prometheus exporter, etc.). Here are the ones that matter for performance monitoring:

**Commit health:**
- `CommitSuccessLatency` — histogram of successful commit times. Should be under 1 second for a 5-member CMS in the same datacenter.
- `CommitRetries` — rate of commit retries. Occasional retries during Paxos contention are normal. Sustained high retry rates indicate CMS health issues.

**Replication health:**
- `FetchPeerLogLatency` / `FetchCMSLogLatency` — how long log fetches take. Should be under 1 second in a healthy cluster.
- `FetchLogRetries` — rate of log fetch retries. Should be near zero.

**Barrier health:**
- `ProgressBarrierLatency` — how long progress barriers take. Under 2 seconds is healthy. Over 5 seconds warrants investigation.
- `ProgressBarrierCLRelaxed` — any non-zero value means some nodes were unreachable at the initial consistency level. Occasional events during node restarts are normal; sustained events indicate network problems.

**Coordinator freshness:**
- `CoordinatorBehindSchema` / `CoordinatorBehindPlacements` — rate of stale-metadata hits on coordinators. Should be near zero in steady state. Spikes during schema changes or topology operations are normal.

### Alert Thresholds

| Metric | Warning | Critical |
|--------|---------|----------|
| CommitSuccessLatency (p99) | > 2 seconds | > 10 seconds |
| CommitRetries (rate) | > 5/minute | > 20/minute |
| ProgressBarrierLatency (p99) | > 5 seconds | > 30 seconds |
| ProgressBarrierCLRelaxed (rate) | > 1/hour | > 5/hour |
| FetchLogRetries (rate) | > 10/minute | > 50/minute |
| UnreachableCMSMembers | > 0 | >= quorum |

These thresholds are starting points. Adjust based on your deployment topology, network characteristics, and operational SLAs.

## Operator Self-Check

1. Why does TCM add latency to metadata commits but not to regular read/write paths?
2. When should you prefer CMS RF=5 over RF=3 or RF=7?
3. Which metrics best indicate that latency issues are network-related versus CMS logic-related?

## Summary

TCM's performance profile is straightforward: metadata operations cost 100-300 milliseconds of Paxos latency, and the read/write hot path is unaffected. The metadata itself is tiny — kilobytes, not megabytes — and propagation to all nodes happens within milliseconds to seconds through the log replication mechanism.

The practical impact on day-to-day operations is a net positive. You trade a small per-commit latency (which you will not notice, because metadata commits are infrequent) for the elimination of ring-settle waits (which you will notice, because they used to cost minutes per topology change) and the guarantee of consistent metadata across all coordinators (which you will appreciate, because it prevents silent data loss).

If performance tuning is needed, the levers are CMS sizing (3/5/7 members), timeout configuration (commit timeout, barrier timeout, barrier backoff), and snapshot frequency. The defaults are conservative and appropriate for most deployments. Tune only if your metrics indicate a specific issue.

The next chapter covers testing TCM in lower environments — how to validate behavior before deploying to production.
