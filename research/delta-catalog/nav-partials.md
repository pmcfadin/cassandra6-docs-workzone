# Nav + Partials Delta

## Scope
- Area: nav + partials (cross-cutting)
- Branches compared: origin/cassandra-5.0 .. origin/trunk
- Subagent: small-areas-batch
- Status: complete

## Inventory Summary
- Pages in 5.0: n/a (nav and partials are not pages)
- Pages in trunk: n/a
- New in trunk: 0 files
- Removed from 5.0: 0 files
- Generated surfaces: none

## Key Differences
Four cross-cutting files modified: the navigation file adds entries for all new trunk pages, and three partials update version numbers, fix rendering issues, and align with SAI table renames.

## Page-Level Findings
- `nav.adoc` — 5.0: present, trunk: present — major-update
  - Adds 8 new navigation entries across multiple areas:
    - Architecture: `accord.adoc`, `accord-architecture.adoc` (nested), `cql-on-accord.adoc` (nested)
    - Developing/CQL: `constraints.adoc`
    - Managing/Operating: `auto_repair.adoc`, `password_validation.adoc`, `role_name_generation.adoc`, `onboarding-to-accord.adoc`, `async-profiler.adoc`
  - No entries removed. All existing nav structure preserved.
  - Trailing newline fix added.

- `partials/masking_functions.adoc` — 5.0: present, trunk: present — minor-update
  - Fixes AsciiDoc escaping: backslash-escaped `*` and `#` replaced with passthrough syntax (`$$****$$`, `$$#$$`) for correct rendering.
  - Two new masking examples added: SSN (`mask_inner`) and timestamp (`mask_outer`).

- `partials/package_versions.adoc` — 5.0: present, trunk: present — major-update
  - Version attributes changed: `{50_version}` → `{51_version}`, distribution `50x` → `51x`.
  - Version list updated: `51x` added, `40x` removed.
  - Note: uses `51_version` / `51x` naming, not `60x`. Confirm whether this is the intended distribution codename for Cassandra 6.0.

- `partials/sai/queryable-paragraph.adoc` — 5.0: present, trunk: present — minor-update
  - SAI virtual table name updated: `system_views.indexes` → `system_views.sai_column_indexes`.
  - Consistent with changes in `reference/sai-virtual-table-indexes.adoc`.

## Apparent Coverage Gaps
- `async-profiler.adoc` appears in `nav.adoc` but is reportedly missing from `managing/operating/index.adoc` (flagged in managing-operating report). Nav entry exists but the area index does not link to it.
- The `51x` / `{51_version}` naming in `package_versions.adoc` should be verified against the actual Cassandra 6 distribution packaging plan.

## Generated-Doc Notes
No generated surfaces. All four files are authored content.

## Recommended Follow-Up
- review-only (nav entries are structurally correct and match new pages)
- needs-change-catalog-check (package_versions `51x` naming needs confirmation)

## Notes
Nav changes are purely additive and correctly mirror the new pages added across architecture, developing, and managing areas. The masking_functions fix addresses a rendering bug that affected the published 5.0 docs. The package_versions update is infrastructure-level and ties into version-wire planning.
