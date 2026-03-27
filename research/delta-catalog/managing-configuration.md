# managing/configuration Delta

## Scope

Path: `doc/modules/cassandra/pages/managing/configuration/`
Compared: `origin/cassandra-5.0` vs `origin/trunk`

## Inventory Summary

| Metric | cassandra-5.0 | trunk |
|--------|--------------|-------|
| Page count | 8 | 8 |
| New pages | — | 0 |
| Removed pages | — | 0 |
| Modified pages | — | 2 |
| Unchanged pages | — | 6 |

Both branches carry the same eight files:
`cass_cl_archive_file.adoc`, `cass_env_sh_file.adoc`, `cass_jvm_options_file.adoc`, `cass_logback_xml_file.adoc`, `cass_rackdc_file.adoc`, `cass_topo_file.adoc`, `configuration.adoc`, `index.adoc`

## Key Differences

1. **JVM options file naming generalized** — version-specific file names (`jvm8-server.options`, `jvm11-server.options`) replaced with the generic `jvmN-server.options` / `jvmN-clients.options` pattern, reflecting that Cassandra 6 supports newer JDKs without enumerating each version.
2. **Slow-query virtual-table logging added** — a substantial new section in `cass_logback_xml_file.adoc` documents the `system_views.slow_queries` virtual table and the `SLOW_QUERIES_APPENDER` logback appender (CASSANDRA-19939 era).

## Page-Level Findings

### cass_jvm_options_file.adoc — Minor text update
- **Delta type:** wording refresh (small)
- References to `jvm8-server.options` / `jvm11-server.options` replaced with generic `jvmN-server.options`.
- Same change applied to the client-side options files.
- Trailing-newline fix at EOF.
- No structural or section-level changes.

### cass_logback_xml_file.adoc — New section added
- **Delta type:** content addition (medium-large, ~66 new lines)
- Existing section renamed from "Logging to Cassandra virtual table" to "Logging system logs to Cassandra virtual table" for clarity.
- New section "Logging slow queries to Cassandra virtual table" added, covering:
  - Relationship to `slow_query_log_timeout` in `cassandra.yaml`
  - How to enable `SLOW_QUERIES_APPENDER` in logback.xml
  - Full XML configuration snippet
  - Routing options (debug.log only, virtual table only, both, or custom file appender)
  - `system_views.slow_queries` virtual table schema (CQL `DESCRIBE` output)
  - Row-limit configuration via `cassandra.virtual.slow_queries.max.rows` system property
  - Truncation and deletion semantics
  - Extensibility via custom appender implementations

### Unchanged pages (6)
`index.adoc`, `configuration.adoc`, `cass_cl_archive_file.adoc`, `cass_env_sh_file.adoc`, `cass_rackdc_file.adoc`, `cass_topo_file.adoc` — identical on both branches.

## Apparent Coverage Gaps

- The `configuration.adoc` page documents CASSANDRA-15234 (parameter name/unit liberation). That content already exists on both branches and may not need updates, but should be reviewed for any new YAML parameters added in Cassandra 6.
- The slow-queries section has a typo: "virual" instead of "virtual" in the subsection heading. This exists in the trunk source.

## Generated-Doc Notes

- **cass_yaml_file.adoc** is referenced from `index.adoc` (`xref:cassandra:managing/configuration/cass_yaml_file.adoc[cassandra.yaml]`) but does **not** exist as a committed file on either branch. It is a generated documentation surface — likely produced by a build-time process that parses `cassandra.yaml` settings. Any delta in `cassandra.yaml` parameters between 5.0 and trunk will surface here but must be assessed through the generation pipeline, not by direct file diff.

## Recommended Follow-Up

1. **Review cass_yaml_file.adoc generation** — Run the doc build on both branches and diff the generated `cass_yaml_file.adoc` to capture new/changed/removed YAML parameters in Cassandra 6.
2. **Fix typo** — "virual" → "virtual" in the slow-queries section heading of `cass_logback_xml_file.adoc`.
3. **Verify JDK support matrix** — The `jvmN` generalization implies broader JDK support; confirm the docs elsewhere list which JDK versions Cassandra 6 actually supports.
4. **Validate slow_query_log_timeout** — Ensure the `cassandra.yaml` generated docs include the `slow_query_log_timeout` parameter and that cross-references are consistent.

## Notes

- The configuration area is stable between branches with only targeted, well-scoped changes.
- No pages were added or removed.
- The most impactful change is the slow-query logging documentation, which is a net-new feature surface for Cassandra 6.
