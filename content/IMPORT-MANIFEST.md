# P3A-T1 Trunk Page Import Manifest

**Import date:** 2026-03-27
**Source:** `apache/cassandra` repo, branch `trunk`
**Trunk commit SHA:** `bf755d0ade706904d7b35bf41b04f64c7e0afe17`
**Destination:** `content/modules/cassandra/pages/`

## Summary

- **71 pages imported** (major-update, minor-update, or generated-review disposition)
- **2 pages skipped** — generated at build time, not present in trunk source tree:
  - `cassandra/pages/managing/configuration/cass_yaml_file.adoc` (generated-review, regen-required)
  - `cassandra/pages/reference/native-protocol.adoc` (generated-review, regen-required)
- **1 glob entry skipped** — `cassandra/pages/managing/tools/nodetool/*.adoc` (generated at build time via `doc/scripts/gen-nodetool-docs.py`)
- Pages with `unchanged` disposition: NOT imported (render from trunk content source)
- Pages with `new` disposition: NOT imported (will be created from scratch in Phases 4-5)

## Imported Pages

| Page Path | Disposition |
|---|---|
| cassandra/pages/architecture/accord-architecture.adoc | minor-update |
| cassandra/pages/architecture/accord.adoc | minor-update |
| cassandra/pages/architecture/cql-on-accord.adoc | minor-update |
| cassandra/pages/architecture/dynamo.adoc | major-update |
| cassandra/pages/architecture/index.adoc | minor-update |
| cassandra/pages/developing/cql/SASI.adoc | major-update |
| cassandra/pages/developing/cql/changes.adoc | minor-update |
| cassandra/pages/developing/cql/collections/list.adoc | major-update |
| cassandra/pages/developing/cql/collections/map.adoc | major-update |
| cassandra/pages/developing/cql/collections/set.adoc | major-update |
| cassandra/pages/developing/cql/constraints.adoc | minor-update |
| cassandra/pages/developing/cql/cql_singlefile.adoc | major-update |
| cassandra/pages/developing/cql/ddl.adoc | major-update |
| cassandra/pages/developing/cql/definitions.adoc | minor-update |
| cassandra/pages/developing/cql/dml.adoc | major-update |
| cassandra/pages/developing/cql/functions.adoc | major-update |
| cassandra/pages/developing/cql/index.adoc | minor-update |
| cassandra/pages/developing/cql/indexing/sai/_collections-list.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/_collections-map.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/_collections-set.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/collections.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/operations/monitoring.adoc | minor-update |
| cassandra/pages/developing/cql/indexing/sai/sai-concepts.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/sai-faq.adoc | major-update |
| cassandra/pages/developing/cql/indexing/sai/sai-read-write-paths.adoc | minor-update |
| cassandra/pages/developing/cql/security.adoc | major-update |
| cassandra/pages/developing/cql/triggers.adoc | minor-update |
| cassandra/pages/developing/cql/types.adoc | minor-update |
| cassandra/pages/developing/index.adoc | minor-update |
| cassandra/pages/getting-started/drivers.adoc | minor-update |
| cassandra/pages/getting-started/mtlsauthenticators.adoc | minor-update |
| cassandra/pages/getting-started/production.adoc | major-update |
| cassandra/pages/installing/installing.adoc | minor-update |
| cassandra/pages/integrating/plugins/index.adoc | minor-update |
| cassandra/pages/managing/configuration/cass_env_sh_file.adoc | major-update |
| cassandra/pages/managing/configuration/cass_jvm_options_file.adoc | major-update |
| cassandra/pages/managing/configuration/cass_logback_xml_file.adoc | major-update |
| cassandra/pages/managing/configuration/cass_rackdc_file.adoc | major-update |
| cassandra/pages/managing/configuration/cass_topo_file.adoc | major-update |
| cassandra/pages/managing/configuration/configuration.adoc | major-update |
| cassandra/pages/managing/operating/async-profiler.adoc | minor-update |
| cassandra/pages/managing/operating/audit_logging.adoc | minor-update |
| cassandra/pages/managing/operating/auditlogging.adoc | minor-update |
| cassandra/pages/managing/operating/auto_repair.adoc | minor-update |
| cassandra/pages/managing/operating/backups.adoc | major-update |
| cassandra/pages/managing/operating/bulk_loading.adoc | minor-update |
| cassandra/pages/managing/operating/compaction/overview.adoc | minor-update |
| cassandra/pages/managing/operating/compaction/tombstones.adoc | major-update |
| cassandra/pages/managing/operating/compaction/ucs.adoc | minor-update |
| cassandra/pages/managing/operating/compression.adoc | major-update |
| cassandra/pages/managing/operating/fqllogging.adoc | minor-update |
| cassandra/pages/managing/operating/hints.adoc | minor-update |
| cassandra/pages/managing/operating/index.adoc | minor-update |
| cassandra/pages/managing/operating/metrics.adoc | major-update |
| cassandra/pages/managing/operating/onboarding-to-accord.adoc | minor-update |
| cassandra/pages/managing/operating/password_validation.adoc | minor-update |
| cassandra/pages/managing/operating/repair.adoc | minor-update |
| cassandra/pages/managing/operating/role_name_generation.adoc | minor-update |
| cassandra/pages/managing/operating/security.adoc | major-update |
| cassandra/pages/managing/operating/snitch.adoc | major-update |
| cassandra/pages/managing/operating/virtualtables.adoc | major-update |
| cassandra/pages/managing/tools/cqlsh.adoc | minor-update |
| cassandra/pages/managing/tools/sstable/sstabledump.adoc | minor-update |
| cassandra/pages/managing/tools/sstable/sstableexpiredblockers.adoc | minor-update |
| cassandra/pages/managing/tools/sstable/sstableloader.adoc | minor-update |
| cassandra/pages/managing/tools/sstable/sstablescrub.adoc | minor-update |
| cassandra/pages/new/index.adoc | major-update |
| cassandra/pages/reference/cql-commands/commands-toc.adoc | minor-update |
| cassandra/pages/reference/cql-commands/compact-subproperties.adoc | minor-update |
| cassandra/pages/reference/sai-virtual-table-indexes.adoc | major-update |
| cassandra/pages/troubleshooting/use_nodetool.adoc | minor-update |

## Build Verification

Antora build (`npx antora antora-playbook.yml`) succeeds after import. 555 xref/image/include warnings are expected — they reference pages, images, and partials that were not imported (unchanged disposition pages, images, examples, partials). These will resolve as:
- The full Cassandra docs content source is wired into the playbook, or
- Content is drafted/updated in Phases 4-5

## Not Imported (by design)

- **Pages with `unchanged` disposition** (~120 pages) — will render from the trunk content source in the final playbook
- **Pages with `new` disposition** (~10 pages) — will be created from scratch in Phases 4-5
- **Pages with `remove` disposition** — being deprecated, not carried forward
- **Generated pages** (cass_yaml_file.adoc, native-protocol.adoc, nodetool/*.adoc) — require build-time regeneration, not source import
