# Architecture Delta

## Scope
- Area: architecture
- Branches compared: `origin/cassandra-5.0` vs `origin/trunk`
- Subagent: architecture
- Status: complete

## Inventory Summary
- Pages in 5.0: 9 (dynamo.adoc, guarantees.adoc, images/ring.svg, images/vnodes.svg, index.adoc, messaging.adoc, overview.adoc, storage-engine.adoc, streaming.adoc)
- Pages in trunk: 12 (all of the above plus accord.adoc, accord-architecture.adoc, cql-on-accord.adoc)
- New in trunk: accord.adoc, accord-architecture.adoc, cql-on-accord.adoc
- Removed from 5.0: none
- Generated surfaces: none identified

## Key Differences

The sole material change to the architecture section is the addition of Accord consensus protocol documentation. Three new files are added, and `index.adoc` gains a single line linking to the new `accord.adoc` hub page. All other existing pages (dynamo, guarantees, messaging, overview, storage-engine, streaming, images) are byte-identical between the two branches.

Accord is the new distributed transaction protocol in Cassandra 5.x/trunk, replacing Paxos for certain transactional workloads. The documentation is developer-oriented (not end-user-oriented) and substantial in depth.

## Page-Level Findings

| Page | Status | Notes |
|------|--------|-------|
| index.adoc | minor-update | One line added: `* xref:architecture/accord.adoc[Accord]` |
| accord.adoc | new | Hub/landing page (~8 lines). Links to accord-architecture.adoc and cql-on-accord.adoc. |
| accord-architecture.adoc | new | ~360 lines. Deep technical document covering Accord internals: coordinator side, replica side, CommandStore, ProgressLog, Command state, CommandsForKey, RedundantBefore, DurabilityService/SyncPoints, ConfigurationService/TopologyManager, DataStore, Journal/GC, contributing guide, and a cheat sheet. Developer-focused. |
| cql-on-accord.adoc | new | ~626 lines. Developer guide for CQL-on-Accord integration: transaction anatomy, key/range transactions, reads/writes, migration from Paxos, transactional modes (FULL, MIXED_READS, OFF), range reads on Accord. Contains many GitHub source links. |
| dynamo.adoc | unchanged | |
| guarantees.adoc | unchanged | |
| messaging.adoc | unchanged | |
| overview.adoc | unchanged | |
| storage-engine.adoc | unchanged | |
| streaming.adoc | unchanged | |
| images/ring.svg | unchanged | |
| images/vnodes.svg | unchanged | |

## Apparent Coverage Gaps

1. **No user-facing Accord architecture overview**: Both `accord-architecture.adoc` and `cql-on-accord.adoc` are explicitly developer/contributor-oriented documents. There is no user-level conceptual overview of Accord for operators or application developers who simply want to understand what Accord does and when to use it. The cql-on-accord doc itself states users should start with `managing/operating/onboarding-to-accord.adoc` for user context, so this may be intentional -- the architecture section targets developers only.

2. **accord-architecture.adoc ends abruptly in cheat sheet**: The "Cheat Sheet" section at the end of accord-architecture.adoc defines Partial vs Full route concepts but the last bullet appears to trail off ("Partial vs Full route are understood in the context of a single transaction.") without a complete explanation. This may be incomplete.

3. **cql-on-accord.adoc references GitHub source links extensively**: Many links point to specific commit SHAs (e.g., `122f530...`). These will become stale as the codebase evolves. This is a maintenance concern rather than a content gap.

4. **No diagrams for Accord**: The existing architecture section has ring.svg and vnodes.svg for the dynamo/overview content, but there are no architectural diagrams for Accord despite the complexity of the protocol.

## Generated-Doc Notes

No generated documentation surfaces were identified in this area. All content is hand-authored AsciiDoc.

## Recommended Follow-Up

1. **Review accord-architecture.adoc cheat sheet ending** for completeness -- the Partial/Full route section may be truncated.
2. **Consider whether user-facing Accord architecture content is needed** in this section, or whether the cross-reference to `onboarding-to-accord.adoc` is sufficient.
3. **Evaluate GitHub permalink stability** in cql-on-accord.adoc -- links to specific SHAs will break over time.
4. **Consider adding Accord diagrams** to match the visual documentation style established by ring.svg/vnodes.svg.

## Notes

- The Accord documentation is highly technical and targets contributors/developers rather than operators. This is consistent with the `accord-architecture.adoc` preamble which states readers should be "closely familiar at very least with Single-Decree Paxos."
- The `cql-on-accord.adoc` doc cross-references `managing/operating/onboarding-to-accord.adoc` which lives outside this architecture scope -- that page should be reviewed as part of the managing/operating delta.
- All six pre-existing authored pages are completely unchanged between 5.0 and trunk.
