# CASSANDRA-20728: Stream individual files in their own transactions

## Status
| Field | Value |
|---|---|
| Research state | not-doc-worthy |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | none |

## Summary

This change restructures the internal transaction management for streaming so that each incoming SSTable file is streamed within its own `LifecycleTransaction`. Upon successful completion, ownership of the file is atomically transferred to a parent `StreamingLifecycleTransaction`. If a stream is aborted mid-flight, only the per-file transaction needs to be rolled back, which prevents orphaned partially-written SSTables from being left on disk.

Previously, streaming abort races could leave incomplete SSTable files on disk that operators had to clean up manually on restart. This bug fix eliminates that operational hazard.

## User-Facing Impact

**None.** This is a purely internal bug fix to streaming transaction management. There are:

- No new configuration parameters in `cassandra.yaml`
- No new nodetool commands or flags
- No new JMX metrics or MBeans
- No changes to CQL syntax or behavior
- No changes to the streaming protocol observable by operators
- No entry in `NEWS.txt` (only in `CHANGES.txt`)

The only operator-visible effect is the absence of a previous misbehavior: orphaned SSTable files after streaming failures will no longer appear, reducing manual cleanup burden. This is a transparent reliability improvement.

## Docs Impact

No documentation changes required. The existing streaming architecture page (`doc/modules/cassandra/pages/architecture/streaming.adoc`) does not discuss internal transaction lifecycle management and does not need to be updated for this fix.

## Source Evidence

| Evidence | Location |
|----------|----------|
| CHANGES.txt entry | Line 87: "Stream individual files in their own transactions and hand over ownership to a parent transaction on completion (CASSANDRA-20728)" |
| NEWS.txt entry | **Not present** -- confirms not user-facing |
| Commit | `f6c1002e44` on trunk, by Marcus Eriksson, reviewed by Caleb Rackliffe and Jon Meredith |
| New class | `src/java/org/apache/cassandra/io/sstable/SSTableTxnSingleStreamWriter.java` -- per-file transaction wrapper |
| New class | `src/java/org/apache/cassandra/db/lifecycle/StreamingLifecycleTransaction.java` -- parent transaction with `takeOwnership()` |
| Modified | `CassandraStreamReceiver.java`, `CassandraStreamReader.java`, `CassandraEntireSSTableStreamReader.java`, `CassandraIncomingFile.java` -- wiring changes |
| Fix version | 6.0-alpha1, 6.0 |
| JIRA type | Bug |
| Files changed | 54 files, +970/-280 lines (includes tests) |

## Classification

- **Type:** Bug fix (internal reliability improvement)
- **Component:** Consistency/Streaming
- **Audience:** None (transparent to all user roles)
- **Doc-worthy:** No

## Proposed Disposition
- Inventory classification: none
- Affected docs: (none)
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

None. The change is clearly internal with no operator-facing surface.
