# Reference Delta

## Scope
- Area: reference
- Branches compared: origin/cassandra-5.0 .. origin/trunk
- Subagent: small-areas-batch
- Status: complete

## Inventory Summary
- Pages in 5.0: 10
- Pages in trunk: 10
- New in trunk: 0
- Removed from 5.0: 0
- Generated surfaces: native-protocol specs (not committed as page; spec files in doc/ root modified on trunk)

## Key Differences
Two authored pages modified. SAI virtual table documentation significantly updated to reflect table renames and column removals. CQL commands TOC gains LIST SUPERUSERS entry. Native protocol spec files exist in doc/ root (v3, v4, v5) and are modified on trunk but do not appear as committed pages under `pages/reference/` — they require generated-doc treatment.

## Page-Level Findings
- `cql-commands/alter-table.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/commands-toc.adoc` — 5.0: present, trunk: present — minor-update (adds LIST SUPERUSERS entry linking to list-superusers.adoc)
- `cql-commands/compact-subproperties.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/create-custom-index.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/create-index.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/create-table-examples.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/create-table.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/drop-index.adoc` — 5.0: present, trunk: present — unchanged
- `cql-commands/drop-table.adoc` — 5.0: present, trunk: present — unchanged
- `index.adoc` — 5.0: present, trunk: present — unchanged
- `java17.adoc` — 5.0: present, trunk: present — unchanged
- `sai-virtual-table-indexes.adoc` — 5.0: present, trunk: present — major-update (SAI tables renamed with `sai_` prefix; 4 columns removed from sai_column_indexes; inner map type frozen; xref path fixed)
- `static.adoc` — 5.0: present, trunk: present — unchanged
- `vector-data-type.adoc` — 5.0: present, trunk: present — unchanged

## Apparent Coverage Gaps
- `list-superusers.adoc` is referenced from commands-toc.adoc but does not exist as a committed page on trunk. This page needs to be drafted or the link is dangling.
- Native protocol spec files (v3, v4, v5) are modified on trunk but have no rendered page in the reference area. If these specs feed a generated reference page, that pipeline output needs validation.

## Generated-Doc Notes
- **native-protocol specs**: `doc/native_protocol_v3.spec`, `doc/native_protocol_v4.spec`, `doc/native_protocol_v5.spec` are all modified on trunk. These are not committed as `.adoc` pages under `pages/reference/`. Classification: **generated-review / regen-validate**. The build pipeline or publish workflow must be checked to determine how these specs become rendered reference content.
- No other generated surfaces in this area.

## Recommended Follow-Up
- update-existing (sai-virtual-table-indexes, commands-toc)
- regen-validate (native-protocol specs)
- draft-new-page (list-superusers.adoc if confirmed missing)

## Notes
The SAI virtual table rename is a breaking change from 5.0 and affects cross-references in other areas (already updated in `partials/sai/queryable-paragraph.adoc`). The `list-superusers.adoc` dangling reference should be confirmed — it may exist outside the reference area or may need to be authored.
