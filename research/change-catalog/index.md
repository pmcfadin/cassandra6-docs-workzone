# Change Catalog Index

Last updated: **2026-03-27**

## Purpose
Operational tracker for Cassandra 6 changes researched for docs impact. Each row is one research file. Used for subagent coordination, page-level routing, and completeness tracking.

## Accounting
- **Research files**: 60 (each following `CASSANDRA-<jira>-<slug>.md` naming)
- **Unique JIRAs covered by research files**: 116 (some files cover multiple related JIRAs)
- **Tail-triaged JIRAs** (in `CHANGES-tail-triage.md`): 235 (90 likely-doc-worthy, 143 not-doc-worthy, 2 uncertain)
- **Total 6.0-alpha1 JIRAs accounted for**: 351

## Tracker

| File | JIRA | Topic | Audience | Docs impact | Status | Evidence | Affected docs | Next action | Blocked on | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CASSANDRA-18330-cluster-metadata.md` | CASSANDRA-18330 | CEP-21 Transactional Cluster Metadata | Operators | new-page | validated | repo-validated | virtualtables.adoc; onboarding-to-accord.adoc; snitch.adoc | draft-new-page | | Most significant C6 change; needs concept + upgrade + nodetool cms pages |
| `CASSANDRA-14227-ttl-2106.md` | CASSANDRA-14227 | TTL expiration extended to 2106 / storage_compatibility_mode | Operators | minor-update | validated | repo-validated | sstablescrub.adoc; dml.adoc; configuration.adoc | update-existing | | 5.0 feature; C6 upgrade guidance + stale 2038 refs |
| `CASSANDRA-19397-native-transport-ssl.md` | CASSANDRA-19397 | native_transport_port_ssl removal | Operators | major-update | validated | repo-validated | security.adoc | update-existing | | Breaking change; security.adoc needs revision |
| `CASSANDRA-19809-deterministic-table-id.md` | CASSANDRA-19809 | use_deterministic_table_id deprecation | Operators | minor-update | validated | repo-validated | cass_yaml_file.adoc | regen-validate | | Deprecated since 5.0.1; removed from default yaml |
| `CASSANDRA-19488-snitch-deprecation.md` | CASSANDRA-19488 | IEndpointSnitch → Locator deprecation | Operators | major-update | validated | repo-validated | snitch.adoc; configuration.adoc; cass_rackdc_file.adoc; cass_topo_file.adoc; production.adoc; dynamo.adoc | update-existing | | 4 new yaml settings; snitch.adoc needs major revision |
| `CASSANDRA-18831-jdk21-zgc.md` | CASSANDRA-18831 | JDK 21 + Generational ZGC default | Operators | major-update | validated | repo-validated | cass_jvm_options_file.adoc; production.adoc | update-existing | | New jvm21-server.options file; jvm options doc gap |
| `CASSANDRA-17445-nodetool-picocli.md` | CASSANDRA-17445 | Nodetool picocli migration | Operators | generated-review | validated | repo-validated | (generated nodetool docs) | regen-validate | | Internal refactor; regen nodetool docs + diff needed |
| `CASSANDRA-11695-jmx-server-options.md` | CASSANDRA-11695 | JMX configuration in cassandra.yaml | Operators | major-update | validated | repo-validated | security.adoc; cass_env_sh_file.adoc; cass_yaml_file.adoc | update-existing | | New yaml surface; security.adoc + env.sh docs need update |
| `CASSANDRA-17092-accord.md` | CASSANDRA-17092 | Accord / General Purpose Transactions (CEP-15) | Mixed | new-page | validated | repo-validated | accord.adoc; accord-architecture.adoc; cql-on-accord.adoc; onboarding-to-accord.adoc | draft-new-page | | 4 docs exist but CQL txn reference page missing |
| `CASSANDRA-19918-auto-repair.md` | CASSANDRA-19918 | Auto Repair (CEP-37) | Operators | minor-update | validated | repo-validated | auto_repair.adoc; repair.adoc; metrics.adoc | review-only | | Docs comprehensive on trunk; minor gaps |
| `CASSANDRA-19947-constraints.md` | CASSANDRA-19947 | Constraints Framework (CEP-42) | Developers | minor-update | validated | repo-validated | constraints.adoc; ddl.adoc; dml.adoc; definitions.adoc; changes.adoc | review-only | | Docs exist on trunk; minor fixes + cross-refs needed |
| `CASSANDRA-17457-password-validation.md` | CASSANDRA-17457 | CEP-24 Password validation + CEP-55 Role name generation | Operators | minor-update | validated | repo-validated | password_validation.adoc; role_name_generation.adoc; security.adoc | review-only | | Docs exist; minor gaps (char sets, max_length) |
| `CASSANDRA-19964-create-table-like.md` | CASSANDRA-19964 | CREATE TABLE LIKE (CEP-43) | Developers | major-update | validated | repo-validated | ddl.adoc; cql_singlefile.adoc; create_table_like.bnf | update-existing | | ddl.adoc missing entirely; BNF stale |
| `CASSANDRA-17021-zstd-dictionary.md` | CASSANDRA-17021 | ZSTD dictionary compression | Operators | minor-update | validated | repo-validated | compression.adoc; compress-subproperties.adoc | update-existing | | Docs exist; generated nodetool + subproperties gaps |
| `CASSANDRA-18802-compaction-parallelization.md` | CASSANDRA-18802 | Unified compaction parallelization | Operators | minor-update | validated | repo-validated | ucs.adoc; compact-subproperties.adoc | update-existing | | parallelize_output_shards + --jobs undocumented |
| `CASSANDRA-20102-string-functions.md` | CASSANDRA-20102 | octet_length and length functions | Developers | minor-update | validated | repo-validated | functions.adoc | review-only | | Docs exist; UTF-8 vs UTF-16 terminology question |
| `CASSANDRA-19546-format-functions.md` | CASSANDRA-19546 | format_bytes and format_time functions | Developers | minor-update | validated | repo-validated | functions.adoc | review-only | | Docs exist; minor typo in example |
| `CASSANDRA-20943-schema-annotations.md` | CASSANDRA-20943 | Schema comments and security labels | Developers | minor-update | validated | repo-validated | ddl.adoc; cql_singlefile.adoc; table-properties.adoc; cass_yaml_file.adoc | update-existing | | Docs in ddl.adoc; gaps in cql_singlefile, BNF, generated yaml |
| `CASSANDRA-18112-index-selection.md` | CASSANDRA-18112 | Manual secondary index selection at CQL level | Developers | minor-update | validated | repo-validated | dml.adoc; select_statement.bnf; sai-read-write-paths.adoc | review-only | | Docs exist in dml.adoc; could expand |
| `CASSANDRA-18492-sai-frozen-collections.md` | CASSANDRA-18492 | SAI frozen collection indexing | Developers | major-update | validated | repo-validated | collections.adoc; _collections-set.adoc; _collections-list.adoc; _collections-map.adoc; sai-faq.adoc; sai-concepts.adoc | update-existing | | No docs for frozen collection element indexing |
| `CASSANDRA-20949-sai-verify.md` | CASSANDRA-20949 | SAI file validation via nodetool verify | Operators | generated-review | validated | repo-validated | (generated nodetool docs) | regen-validate | | Two new verify flags; generated docs already reflect |
| `CASSANDRA-19987-direct-io-compaction.md` | CASSANDRA-19987 | Direct I/O for compaction reads | Operators | minor-update | validated | repo-validated | cass_yaml_file.adoc | regen-validate | | New compaction_read_disk_access_mode setting |
| `CASSANDRA-20528-topology-dc-rack.md` | CASSANDRA-20528 | Topology-safe DC/rack changes for live nodes | Operators | new-page | validated | repo-validated | snitch.adoc; cass_rackdc_file.adoc; cass_topo_file.adoc | update-existing | | New nodetool altertopology; zero docs |
| `CASSANDRA-20081-compactionhistory.md` | CASSANDRA-20081 | Nodetool compactionhistory enhancements | Operators | generated-review | validated | repo-validated | overview.adoc (compaction) | regen-validate | | New -H flag + strategy info; regenerate |
| `CASSANDRA-20941-compressiondictionary.md` | CASSANDRA-20941 | Nodetool compressiondictionary commands | Operators | generated-review | validated | repo-validated | compression.adoc | regen-validate | | 3 new subcommands; authored docs in compression.adoc |
| `CASSANDRA-20851-nodetool-history.md` | CASSANDRA-20851 | Nodetool history command | Operators | generated-review | validated | repo-validated | (generated nodetool docs) | regen-validate | | New command; regen covers it |
| `CASSANDRA-20448-sstableexpiredblockers.md` | CASSANDRA-20448 | sstableexpiredblockers human-readable output | Operators | minor-update | validated | repo-validated | sstableexpiredblockers.adoc | update-existing | | New -H flag; update existing page |
| `CASSANDRA-21129-offline-dump.md` | CASSANDRA-21129 | Offline dump tool for cluster metadata/logs | Operators | new-page | blocked | needs-code | (none existing) | awaiting-merge | PR #4581 | New tool needs reference page |
| `CASSANDRA-20854-async-profiler.md` | CASSANDRA-20854 | Async-profiler support | Operators | minor-update | validated | repo-validated | async-profiler.adoc | review-only | | Authored doc exists on trunk |
| `CASSANDRA-21093-startup-checks-spi.md` | CASSANDRA-21093 | Custom startup checks via SPI | Operators | new-page | validated | repo-validated | (none existing) | draft-new-page | | No doc page on trunk; SPI interface + yaml config |
| `CASSANDRA-19366-auth-mode-clients.md` | CASSANDRA-19366 | Auth mode in system_views.clients and clientstats | Operators | minor-update | validated | repo-validated | virtualtables.adoc; metrics.adoc; use_nodetool.adoc | update-existing | | virtualtables.adoc example missing new columns |
| `CASSANDRA-18111-snapshot-mbean.md` | CASSANDRA-18111 | SnapshotManager MBean | Operators | minor-update | validated | repo-validated | backups.adoc; metrics.adoc; virtualtables.adoc | update-existing | | New MBean; StorageServiceMBean methods deprecated |
| `CASSANDRA-19289-tpstats-verbose.md` | CASSANDRA-19289 | Thread pool stats in nodetool tpstats --verbose | Operators | minor-update | validated | repo-validated | virtualtables.adoc; use_nodetool.adoc | update-existing | | virtualtables.adoc + use_nodetool.adoc need --verbose |
| `CASSANDRA-18781-bulk-loading-guardrail.md` | CASSANDRA-18781 | Bulk SSTable loading guardrail | Operators | major-update | validated | repo-validated | (none existing) | update-existing | | No guardrails doc page exists |
| `CASSANDRA-20913-durable-writes-guardrail.md` | CASSANDRA-20913 | DDL + keyspace properties guardrails | Operators | major-update | validated | repo-validated | (none existing) | update-existing | | 3+3 new yaml settings; no guardrails doc page |
| `CASSANDRA-21024-disk-usage-guardrails.md` | CASSANDRA-21024 | Disk usage guardrails for keyspace protection | Operators | major-update | validated | repo-validated | (none existing) | update-existing | | Strategy-aware DC protection |
| `CASSANDRA-19677-per-type-max-size.md` | CASSANDRA-19677 | Per type max size guardrails | Operators | major-update | validated | repo-validated | (none existing) | update-existing | | 12 new yaml settings |
| `CASSANDRA-18831-chronicle-queue-rolling.md` | CASSANDRA-18831 | Chronicle Queue log rolling deprecation | Operators | minor-update | validated | repo-validated | fqllogging.adoc; audit_logging.adoc | update-existing | | FAST_HOURLY default; docs stale |
| `CASSANDRA-20728-streaming.md` | CASSANDRA-20728 | Stream individual files in own transactions | Operators | none | not-doc-worthy | repo-validated | (none) | none | | Internal bug fix |
| `CASSANDRA-13001-slow-queries-vtable.md` | CASSANDRA-13001 | system_views.slow_queries virtual table | Operators | major-update | validated | repo-validated | virtualtables.adoc | update-existing | | New vtable not documented on trunk; schema + sample queries needed |
| `CASSANDRA-14572-metrics-virtual-tables.md` | CASSANDRA-14572 | All Dropwizard metrics in system_metrics virtual keyspace | Operators | major-update | validated | repo-validated | virtualtables.adoc; metrics.adoc | update-existing | | system_metrics keyspace docs incomplete; per-group schemas undocumented |
| `CASSANDRA-17198-like-expressions.md` | CASSANDRA-17198 | LIKE expressions in filtering queries | Developers | major-update | validated | repo-validated | dml.adoc; SASI.adoc; cql_singlefile.adoc | update-existing | | LIKE operator not documented in dml.adoc WHERE section |
| `CASSANDRA-18584-not-operators.md` | CASSANDRA-18584 | NOT operators in WHERE clauses (3VL) | Developers | major-update | validated | repo-validated | dml.adoc; cql_singlefile.adoc | update-existing | | NOT IN / NOT CONTAINS / NOT CONTAINS KEY not documented in dml.adoc |
| `CASSANDRA-18688-runtime-environment-changes.md` | CASSANDRA-18688; CASSANDRA-16565 | JDK version enforcement + Sigar to OSHI migration | Operators | minor-update | validated | repo-validated | installing.adoc | update-existing | | JDK hard-stop and Sigar removal need docs updates |
| `CASSANDRA-18951-security-config-additions.md` | CASSANDRA-18951; CASSANDRA-13428; CASSANDRA-18857 | mTLS cert validity, password files, early auth | Operators | minor-update | validated | repo-validated | security.adoc; cass_yaml_file.adoc | update-existing | | security.adoc updated for 13428; gaps for 18951 and 18857 |
| `CASSANDRA-19385-disconnect-revoked-roles.md` | CASSANDRA-19385 | Periodic disconnect of revoked/LOGIN=FALSE roles | Operators | minor-update | validated | repo-validated | security.adoc; cass_yaml_file.adoc | update-existing | | New YAML settings + background task undocumented in security.adoc |
| `CASSANDRA-19417-list-superusers.md` | CASSANDRA-19417 | LIST SUPERUSERS CQL statement | Operators | new-page | validated | repo-validated | security.adoc; commands-toc.adoc | draft-new-page | | list-superusers.adoc missing; xref from commands-toc.adoc is broken |
| `CASSANDRA-19532-triggers-policy.md` | CASSANDRA-19532 | TriggersPolicy to allow operators to disable triggers | Operators | minor-update | validated | repo-validated | triggers.adoc; cass_yaml_file.adoc | review-only | | triggers.adoc updated in commit; review for completeness |
| `CASSANDRA-19581-cms-nodetool-commands.md` | CASSANDRA-19581; CASSANDRA-20525; CASSANDRA-20482; CASSANDRA-19216; CASSANDRA-19393 | CMS nodetool commands (cms group) | Operators | new-page | validated | repo-validated | use_nodetool.adoc | draft-new-page | | Old command names removed; cms command group needs authored reference |
| `CASSANDRA-19604-between-operator.md` | CASSANDRA-19604; CASSANDRA-19688 | BETWEEN operator in WHERE clauses with SAI support | Developers | major-update | validated | repo-validated | dml.adoc; cql_singlefile.adoc | update-existing | | BETWEEN operator not documented in dml.adoc WHERE section |
| `CASSANDRA-19671-nodetool-stats-formatting.md` | CASSANDRA-19671; CASSANDRA-20820; CASSANDRA-20940; CASSANDRA-19104; CASSANDRA-19015; CASSANDRA-19022; CASSANDRA-19771 | nodetool tablestats and gcstats formatting improvements | Operators | generated-review | validated | repo-validated | (generated nodetool docs); use_nodetool.adoc | regen-validate | | New flags + fields; regen covers flags; use_nodetool examples may be stale |
| `CASSANDRA-19792-audit-logging-config.md` | CASSANDRA-19792; CASSANDRA-20128 | Audit logging format params + JMX audit support | Operators | minor-update | validated | repo-validated | audit_logging.adoc; cass_yaml_file.adoc | update-existing | | Format params and JMX category undocumented in audit_logging.adoc |
| `CASSANDRA-19939-sstabledump-tombstones.md` | CASSANDRA-19939 | sstabledump -o tombstones-only option | Operators | minor-update | validated | repo-validated | sstabledump.adoc | review-only | | Section exists but thin; add example invocation |
| `CASSANDRA-20104-nodetool-status-sorting.md` | CASSANDRA-20104 | Sorting of nodetool status output | Operators | minor-update | validated | repo-validated | (generated nodetool docs); use_nodetool.adoc | regen-validate | | New -s/-o flags; regen covers flags |
| `CASSANDRA-20151-listsnapshots-filtering.md` | CASSANDRA-20151 | Snapshot filtering on keyspace/table/name in listsnapshots | Operators | minor-update | validated | repo-validated | (generated nodetool docs); use_nodetool.adoc | regen-validate | | New -k/-t/-n flags; regen covers flags |
| `CASSANDRA-20161-partition-key-statistics.md` | CASSANDRA-20161 | system_views.partition_key_statistics virtual table | Operators | minor-update | validated | repo-validated | virtualtables.adoc | update-existing | | Section exists but has gaps: section title, constraints, size_estimate semantics |
| `CASSANDRA-20466-metrics-surface-changes.md` | CASSANDRA-20466; CASSANDRA-19486; CASSANDRA-20499; CASSANDRA-20132; CASSANDRA-20502; CASSANDRA-20864; CASSANDRA-13890; CASSANDRA-17062; CASSANDRA-20870; CASSANDRA-19447 | Multiple metrics surface additions | Operators | minor-update | validated | repo-validated | metrics.adoc; virtualtables.adoc | update-existing | | Small gaps across metrics.adoc and virtualtables.adoc |
| `CASSANDRA-20477-cas-decrement.md` | CASSANDRA-20477 | CAS support for -= on numeric types | Developers | minor-update | validated | repo-validated | dml.adoc | update-existing | | UPDATE SET section inaccurate for CAS -=; needs clarification |
| `CASSANDRA-20749-env-var-overrides.md` | CASSANDRA-20749 | Override cassandra.yaml settings via environment variables | Operators | major-update | validated | repo-validated | cass_yaml_file.adoc | update-existing | | Feature undocumented in authored pages; authored section needed |
| `CASSANDRA-20858-uncaught-exceptions-vtable.md` | CASSANDRA-20858 | system_views.uncaught_exceptions virtual table | Operators | major-update | validated | repo-validated | virtualtables.adoc | update-existing | | New vtable not documented on trunk; schema + operational guidance needed |

---

## Summary

| Docs impact | Count |
|---|---|
| new-page | 7 |
| major-update | 18 |
| minor-update | 27 |
| generated-review | 7 |
| none | 1 |
| blocked (new-page) | 1 |
| **Total files** | **60** (includes 21 added 2026-03-27) |

| Next action | Count |
|---|---|
| draft-new-page | 4 |
| update-existing | 30 |
| regen-validate | 11 |
| review-only | 8 |
| awaiting-merge | 1 |
| none | 1 |
| incomplete (blocked) | 5 (cms nodetool group sub-items) |
| **Total** | **60** |

## Critical Doc Gaps (New Pages Needed)
1. **CEP-21 Cluster Metadata** — No docs at all for the most significant C6 architectural change
2. **Accord CQL Transaction Reference** — BEGIN TRANSACTION syntax undocumented
3. **Guardrails Reference Page** — No guardrails doc page exists anywhere (affects 4+ research files)
4. **nodetool altertopology** — Zero docs for live DC/rack changes
5. **Startup Checks SPI** — No doc page for custom startup check extension point
6. **LIST SUPERUSERS reference page** — commands-toc.adoc links to list-superusers.adoc which does not exist (broken xref, build risk)
7. **nodetool cms command group** — Authored overview needed; old command names (describecms, initializecms, reconfigurecms) removed

## Major Updates Required
1. **IEndpointSnitch deprecation** — snitch.adoc + 5 other pages need rewrite
2. **JMX server options** — security.adoc + env.sh docs need significant update
3. **SAI frozen collection indexing** — 6 SAI collection pages need frozen section
4. **CREATE TABLE LIKE** — ddl.adoc missing entirely; BNF stale
5. **All guardrails** — bulk loading, durable_writes, keyspace properties, disk usage, per-type max size

## Generated Doc Actions
1. Regenerate all nodetool docs (picocli migration may affect formatting)
2. Regenerate cassandra.yaml reference (many new settings)
3. Verify compressiondictionary subcommand group coverage
4. Verify nodetool profile (async-profiler) subcommand coverage

## Key Finding
Most CEP features (Accord, Auto Repair, Constraints, Password/Role, ZSTD, Async Profiler) already have authored docs on trunk. The biggest gaps are operational infrastructure — CMS, guardrails, topology changes. Wave 2 research (21 new files) surfaced significant additional CQL documentation gaps: LIKE, BETWEEN, and NOT operators are each missing from dml.adoc; the system_metrics virtual keyspace, slow_queries table, and uncaught_exceptions table are undocumented; and the environment-variable config override feature lacks authored docs entirely. The LIST SUPERUSERS missing reference page is the most acute publish blocker — it produces a broken xref in the current docs build.
