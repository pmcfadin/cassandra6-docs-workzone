# New (What's New) Delta

## Scope
- Area: new
- Branches compared: origin/cassandra-5.0 .. origin/trunk
- Subagent: small-areas-batch
- Status: complete

## Inventory Summary
- Pages in 5.0: 1
- Pages in trunk: 1
- New in trunk: 0
- Removed from 5.0: 0
- Generated surfaces: none

## Key Differences
The single page `index.adoc` gains a new "New Features in Apache Cassandra 6.0" section prepended above the existing 5.0 content. The 6.0 section is placeholder-level: three bullet points linking to external Confluence design documents rather than to in-repo docs pages.

## Page-Level Findings
- `index.adoc` — 5.0: present, trunk: present — major-update
  - Adds Cassandra 6.0 section with three items:
    1. ACID Transactions (Accord) — Confluence link
    2. Transactional Cluster Metadata — Confluence link
    3. Constraints — Confluence link
  - Existing 5.0 content preserved below the new section unchanged.
  - Delta type: major-update (structural addition, but content is stub-level)

## Apparent Coverage Gaps
- The 6.0 section lists only 3 features. Based on the full delta catalog, many more trunk changes exist (auto-repair, password validation, role name generation, async-profiler, ZstdDictionaryCompressor, slow-query logging, SAI table renames, etc.) that are not represented.
- Links point to Confluence wiki pages rather than in-repo documentation pages. For a published release, these should link to authored docs.
- No mention of breaking changes, deprecations, or removed features (e.g., cloud snitches removed, crypto providers section removed).

## Generated-Doc Notes
No generated surfaces in this area.

## Recommended Follow-Up
- draft-new-page (substantial expansion needed for 6.0 content; should cover all major features, link to in-repo docs, and note breaking changes)

## Notes
This is the most visible page for users upgrading to Cassandra 6. Its current state is a minimal placeholder. Expansion should be coordinated after other area docs are written so the what's-new page can link to completed docs pages rather than Confluence.
