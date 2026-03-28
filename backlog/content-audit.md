# Content Audit Report

**Generated**: 2026-03-27
**Scope**: All `.adoc` files under `content/modules/`
**Method**: Full read of every file, classified against docs-map.csv and research catalogs

---

## Executive Summary

This audit reveals a documentation set that is **far from feature-complete**. While research is thorough and some new C6 pages are well-drafted, the majority of imported trunk pages have not been updated, several critical new pages don't exist yet, and three of four audience modules are empty shells.

| Metric | Count |
|--------|-------|
| Total .adoc files in workzone | 253 |
| Substantial (real content) | 78 |
| Stub (placeholder/skeleton) | 168 |
| Blank (empty or title-only) | 0 |
| Nav files | 7 |
| Draft-complete (per docs-map + audit) | 35 |
| Not-started or needs major work | 218 |
| Publish blockers (new pages missing from disk) | 4 |
| Files with open questions / unresolved TODOs | 14 |
| Files with stale version references ({40_version}, Java 11) | 5 |

**Bottom line**: 35 pages are in reasonable draft shape. 78 pages have real content but most need C6 updates. 159 nodetool stubs need regeneration. 4 publish-blocker pages don't exist. 3 of 4 audience modules have no content.

---

## Classification Totals

| Classification | Count | Notes |
|---------------|-------|-------|
| substantial | 78 | Real documentation prose, 20+ lines |
| stub | 168 | 159 nodetool generated-includes + 9 other stubs |
| nav-file | 7 | Structural navigation files |
| **Total** | **253** | |

### By Module

| Module | Substantial | Stub | Nav | Total |
|--------|------------|------|-----|-------|
| cassandra | 68 | 165 | 1 | 234 |
| operators | 7 | 1 | 1 | 9 |
| developers | 0 | 1 | 1 | 2 |
| contributors | 0 | 1 | 1 | 2 |
| reference | 0 | 1 | 1 | 2 |
| ROOT | 1 | 0 | 1 | 2 |

---

## Nodetool Batch Classification

- **Total**: 160 files (159 subcommand stubs + 1 hub page)
- **Pattern**: Every subcommand file is exactly 7 lines: title + `== Usage` + include directive pointing to `cassandra:example$TEXT/NODETOOL/<command>.txt`
- **Exceptions**: `nodetool.adoc` (338 lines) is the hub/index page with synopsis and xrefs to all subcommands — classified as substantial
- **Status**: Marked `draft-complete` and `generated-review` in docs-map. Needs regeneration from trunk picocli migration (CASSANDRA-17445) before publication
- **New command**: `altertopology.adoc` is listed as a NEW page (CASSANDRA-20528) but follows the same 7-line stub pattern — needs real content

---

## Summary Table: Architecture + Small Directories

| file_path | class | lines | change_class | draft_status | priority | gaps |
|-----------|-------|-------|-------------|-------------|----------|------|
| cassandra/pages/architecture/accord-architecture.adoc | substantial | 360 | minor-update | not-started | release-critical | Truncated cheat sheet section, incomplete sentence line 104 |
| cassandra/pages/architecture/accord.adoc | stub | 7 | minor-update | not-started | release-critical | Hub page, title + 2 xrefs only, no conceptual overview |
| cassandra/pages/architecture/cql-on-accord.adoc | substantial | 627 | minor-update | not-started | release-critical | Pinned GitHub SHA links will go stale |
| cassandra/pages/architecture/dynamo.adoc | substantial | 529 | major-update | not-started | operator-critical | `{40_version}` placeholders, "4.next" reference, LWT text needs Accord updates |
| cassandra/pages/architecture/index.adoc | stub | 11 | minor-update | not-started | standard | Title + 6 xref bullets, no prose |
| cassandra/pages/getting-started/drivers.adoc | substantial | 87 | minor-update | not-started | deferred | Links list, needs C6 driver compatibility notes |
| cassandra/pages/getting-started/mtlsauthenticators.adoc | substantial | 186 | minor-update | not-started | operator-critical | Complete mTLS guide, no gaps |
| cassandra/pages/getting-started/production.adoc | substantial | 164 | major-update | not-started | operator-critical | `{40_version}` placeholder, missing JDK 21/ZGC, missing snitch deprecation |
| cassandra/pages/installing/installing.adoc | substantial | 283 | minor-update | not-started | standard | References Java 11/17 (needs 17/21), `{40_version}`, Python 3.8-3.11 range |
| cassandra/pages/integrating/plugins/index.adoc | substantial | 22 | minor-update | not-started | deferred | Minimal but real prose |
| cassandra/pages/new/index.adoc | substantial | 35 | major-update | not-started | standard | **3-bullet placeholder** linking to Confluence. Missing dozens of C6 features. Most visible page for upgraders. |
| cassandra/pages/troubleshooting/use_nodetool.adoc | substantial | 346 | minor-update | draft-complete | standard | Already has C6 content (tpstats --verbose, clientstats auth-mode) |

## Summary Table: Developing Directory

| file_path | class | lines | change_class | draft_status | priority | gaps |
|-----------|-------|-------|-------------|-------------|----------|------|
| cassandra/pages/developing/index.adoc | stub | 5 | minor-update | not-started | deferred | Title + 3 xrefs only |
| cassandra/pages/developing/cql/index.adoc | stub | 25 | minor-update | not-started | deferred | Title + brief intro + xref list |
| cassandra/pages/developing/cql/SASI.adoc | substantial | 809 | major-update | not-started | standard | Needs LIKE expressions update (CASSANDRA-17198) |
| cassandra/pages/developing/cql/changes.adoc | substantial | 242 | minor-update | not-started | deferred | CQL changelog, C6 entries present but linked docs missing |
| cassandra/pages/developing/cql/constraints.adoc | substantial | 373 | minor-update | draft-complete | standard | Typos: "satistfiability", "satisty", "suggar". Missing: NOT EMPTY/BETWEEN/LIKE/NOT NAN constraints |
| cassandra/pages/developing/cql/cql_singlefile.adoc | substantial | 2982 | major-update | not-started | **release-critical** | Monolithic CQL ref, fate undecided (keep vs deprecate), publish blocker |
| cassandra/pages/developing/cql/ddl.adoc | substantial | 1107 | major-update | draft-complete | standard | COMMENT ON, SECURITY LABEL, CREATE TABLE LIKE. Has Preview banner |
| cassandra/pages/developing/cql/definitions.adoc | substantial | 184 | minor-update | not-started | deferred | Broken xref: `defintions.adoc` typo on line 121 |
| cassandra/pages/developing/cql/dml.adoc | substantial | 613 | major-update | draft-complete | **release-critical** | BETWEEN, NOT IN/CONTAINS, LIKE, index hints. Has Preview banner |
| cassandra/pages/developing/cql/functions.adoc | substantial | 832 | major-update | draft-complete | standard | length/octet_length, human helpers, WRITETIME/TTL relocated here |
| cassandra/pages/developing/cql/security.adoc | substantial | 750 | major-update | draft-complete | **release-critical** | LIST SUPERUSERS, Database Identities. GENERATED PASSWORD still missing |
| cassandra/pages/developing/cql/triggers.adoc | substantial | 53 | minor-update | not-started | deferred | triggers_policy added but doesn't say where it's configured |
| cassandra/pages/developing/cql/types.adoc | substantial | 554 | minor-update | not-started | deferred | Anchor additions, minor xref typo |
| cassandra/pages/developing/cql/txn-reference.adoc | substantial | 464 | new | draft-complete | **release-critical** | BEGIN TRANSACTION ref. **6 unresolved questions** at bottom. Has Preview banner |
| cassandra/pages/developing/cql/collections/list.adoc | substantial | 38 | major-update | not-started | standard | Borderline substantial, needs SAI frozen collection updates |
| cassandra/pages/developing/cql/collections/map.adoc | substantial | 39 | major-update | not-started | standard | Borderline substantial, needs SAI frozen collection updates |
| cassandra/pages/developing/cql/collections/set.adoc | substantial | 38 | major-update | not-started | standard | Borderline substantial, needs SAI frozen collection updates |
| cassandra/pages/developing/cql/indexing/sai/collections.adoc | substantial | 127 | major-update | draft-complete | standard | Frozen collection indexing (CASSANDRA-18492). Well-structured |
| cassandra/pages/developing/cql/indexing/sai/_collections-list.adoc | substantial | 87 | major-update | draft-complete | standard | Partial. New frozen list indexing |
| cassandra/pages/developing/cql/indexing/sai/_collections-map.adoc | substantial | 132 | major-update | draft-complete | standard | Partial. New frozen map indexing |
| cassandra/pages/developing/cql/indexing/sai/_collections-set.adoc | substantial | 65 | major-update | draft-complete | standard | Partial. New frozen set indexing |
| cassandra/pages/developing/cql/indexing/sai/operations/monitoring.adoc | substantial | 177 | minor-update | not-started | deferred | Virtual table names updated for C6 |
| cassandra/pages/developing/cql/indexing/sai/sai-read-write-paths.adoc | substantial | 199 | minor-update | draft-complete | deferred | Index hints xref added |
| cassandra/pages/developing/cql/indexing/sai/sai-concepts.adoc | substantial | 56 | major-update | draft-complete | standard | Frozen collection CONTAINS noted |
| cassandra/pages/developing/cql/indexing/sai/sai-faq.adoc | substantial | 370 | major-update | draft-complete | standard | **"Cassandra ???" placeholder** lines 165-166 (version numbers missing) |

## Summary Table: Managing Configuration + Operating

| file_path | class | lines | change_class | draft_status | priority | gaps |
|-----------|-------|-------|-------------|-------------|----------|------|
| cassandra/pages/managing/configuration/cass_env_sh_file.adoc | substantial | 157 | major-update | not-started | operator-critical | Thrift RPC references obsolete, missing JMX server options (CASSANDRA-11695) |
| cassandra/pages/managing/configuration/cass_jvm_options_file.adoc | substantial | 171 | major-update | not-started | operator-critical | JDK 21/ZGC content added. **5 open questions** in draft section |
| cassandra/pages/managing/configuration/cass_logback_xml_file.adoc | substantial | 261 | major-update | not-started | deferred | Typo "virual" line 104. Slow-query logging section added |
| cassandra/pages/managing/configuration/cass_rackdc_file.adoc | substantial | 78 | major-update | not-started | operator-critical | Needs snitch deprecation + topology DC/rack updates |
| cassandra/pages/managing/configuration/cass_topo_file.adoc | substantial | 52 | major-update | not-started | operator-critical | Same snitch deprecation updates needed |
| cassandra/pages/managing/configuration/cassandra_yaml_diff_5.0_vs_trunk.adoc | substantial | 146 | N/A | N/A | N/A | Workzone research artifact, not a docs page |
| cassandra/pages/managing/configuration/cassandra_yaml_file.adoc | substantial | 4377 | generated-review | draft-complete | release-critical | GENERATED. Needs regeneration for 46 new trunk settings |
| cassandra/pages/managing/configuration/configuration.adoc | substantial | 219 | major-update | not-started | release-critical | **Explicit "Another TO DO"** line 147. JMX methods, CCM references |
| cassandra/pages/managing/operating/async-profiler.adoc | substantial | 140 | minor-update | not-started | deferred | New C6 page. Missing from operating index per delta-catalog |
| cassandra/pages/managing/operating/audit_logging.adoc | substantial | 226 | minor-update | not-started | standard | roll_cycle default discrepancy (FAST_HOURLY vs HOURLY) |
| cassandra/pages/managing/operating/auditlogging.adoc | substantial | 549 | minor-update | not-started | standard | Comprehensive 4.0+ audit logging. Minor delta only |
| cassandra/pages/managing/operating/auto_repair.adoc | substantial | 461 | minor-update | draft-complete | standard | New C6 page (CEP-37). Comprehensive |
| cassandra/pages/managing/operating/backups.adoc | substantial | 599 | major-update | draft-complete | standard | New JMX SnapshotManager MBean section |
| cassandra/pages/managing/operating/bulk_loading.adoc | substantial | 782 | minor-update | not-started | deferred | Detailed, minor trunk delta |
| cassandra/pages/managing/operating/compression.adoc | substantial | 425 | major-update | draft-complete | standard | ZstdDictionaryCompressor section. Well-structured |
| cassandra/pages/managing/operating/compaction/overview.adoc | substantial | 291 | minor-update | draft-complete | standard | "open question" about disk_access_mode mmap |
| cassandra/pages/managing/operating/compaction/tombstones.adoc | substantial | 190 | major-update | not-started | standard | Rewritten prose, "Preventing Data Resurrection" section |
| cassandra/pages/managing/operating/compaction/ucs.adoc | substantial | 753 | minor-update | draft-complete | standard | Preview banner. UCS migration, sharding, parallelization |
| cassandra/pages/managing/operating/fqllogging.adoc | substantial | 566 | minor-update | not-started | standard | Chronicle Queue rolling update needed |
| cassandra/pages/managing/operating/hints.adoc | substantial | 251 | minor-update | not-started | standard | `auto_hints_cleanup_enabled` added |
| cassandra/pages/managing/operating/index.adoc | stub | 25 | minor-update | draft-complete | deferred | Navigation page, 21 xref links |
| cassandra/pages/managing/operating/metrics.adoc | substantial | 1280 | major-update | not-started | standard | **Not updated** with C6 metrics (~80 lines needed: auto-repair, cache, encryption, auth) |
| cassandra/pages/managing/operating/onboarding-to-accord.adoc | substantial | 371 | minor-update | not-started | release-critical | **WIP language**: "Before release this is likely to change" line 327 |
| cassandra/pages/managing/operating/password_validation.adoc | substantial | 329 | minor-update | draft-complete | operator-critical | New C6 page (CEP-24). Comprehensive |
| cassandra/pages/managing/operating/repair.adoc | substantial | 230 | minor-update | not-started | standard | Auto repair scheduling xref added |
| cassandra/pages/managing/operating/role_name_generation.adoc | substantial | 121 | minor-update | not-started | operator-critical | New C6 page (CEP-55). Concise but complete |
| cassandra/pages/managing/operating/security.adoc | substantial | 1024 | major-update | not-started | operator-critical | Preview banner. **4 unresolved questions** (native_transport_port_ssl, cassandra-env.sh deprecation, nodetool JMX, crypto providers). Crypto providers section MISSING |
| cassandra/pages/managing/operating/snitch.adoc | substantial | 337 | major-update | not-started | operator-critical | Preview banner. Major rewrite. **4 open questions** for tech review |
| cassandra/pages/managing/operating/virtualtables.adoc | substantial | 941 | major-update | draft-complete | standard | Preview banner. **2 open question blocks** (system_metrics, partition_key_statistics) |

## Summary Table: Tools

| file_path | class | lines | change_class | draft_status | priority | gaps |
|-----------|-------|-------|-------------|-------------|----------|------|
| cassandra/pages/managing/tools/nodetool/*.adoc (159 files) | stub (generated-include) | 7 each | generated-review | draft-complete | release-critical | All follow identical pattern. Need regeneration |
| cassandra/pages/managing/tools/nodetool/nodetool.adoc | substantial | 338 | generated-review | draft-complete | release-critical | Hub page with all subcommand xrefs |
| cassandra/pages/managing/tools/cqlsh.adoc | substantial | 594 | minor-update | not-started | deferred | Typo "evalution" line 337 |
| cassandra/pages/managing/tools/sstable/sstabledump.adoc | substantial | 294 | minor-update | not-started | deferred | `-o` tombstone flag missing example output |
| cassandra/pages/managing/tools/sstable/sstableloader.adoc | substantial | 343 | minor-update | not-started | deferred | SSL section rewritten, verbose progress examples |
| cassandra/pages/managing/tools/sstable/sstablescrub.adoc | substantial | 108 | minor-update | draft-complete | deferred | `-r` option updated for 2106 date limit |
| cassandra/pages/managing/tools/sstable/sstableexpiredblockers.adoc | substantial | 72 | minor-update | draft-complete | deferred | New `-H` human-readable flag |

## Summary Table: Non-Cassandra Modules + Reference

| file_path | class | lines | change_class | draft_status | priority | gaps |
|-----------|-------|-------|-------------|-------------|----------|------|
| ROOT/pages/index.adoc | substantial | 22 | unchanged | complete | -- | Landing page with module xrefs |
| cassandra/pages/reference/cql-commands/commands-toc.adoc | substantial | 128 | minor-update | not-started | standard | **Dangling xref to list-superusers.adoc** (file doesn't exist) |
| cassandra/pages/reference/cql-commands/compact-subproperties.adoc | substantial | 340 | minor-update | draft-complete | standard | `{product}` placeholder unresolved. Greek symbol TODO |
| cassandra/pages/reference/native-protocol.adoc | stub | 64 | generated-review | draft-complete | release-critical | Include-only shell. No v6 protocol. Needs regen |
| cassandra/pages/reference/sai-virtual-table-indexes.adoc | substantial | 308 | major-update | not-started | standard | May already reflect trunk state, needs verification |
| operators/pages/index.adoc | stub | 8 | N/A (new module) | not-started | standard | Title + 1-line description only |
| operators/pages/guardrails-reference.adoc | substantial | 422 | new | draft-complete | operator-critical | **7 TODOs**, **9 unresolved questions** |
| operators/pages/tcm-overview.adoc | substantial | 459 | new | draft-complete | release-critical | **2 unresolved questions** |
| operators/pages/tcm-pre-upgrade.adoc | substantial | 477 | new | draft-complete | release-critical | **1 TODO**, **2 unresolved questions** |
| operators/pages/tcm-upgrade-procedure.adoc | substantial | 624 | new | draft-complete | release-critical | **2 unresolved questions** |
| operators/pages/tcm-operations.adoc | substantial | 592 | new | draft-complete | release-critical | **2 unresolved questions** |
| operators/pages/tcm-troubleshooting.adoc | substantial | 881 | new | draft-complete | release-critical | **2 unresolved questions** |
| operators/pages/startup-checks-spi.adoc | substantial | 333 | new | draft-complete | operator-critical | **5 TODOs**, **6 unresolved questions** |
| developers/pages/index.adoc | stub | 8 | N/A (new module) | not-started | deferred | **Empty shell** — no content |
| contributors/pages/index.adoc | stub | 8 | N/A (new module) | not-started | deferred | **Empty shell** — no content |
| reference/pages/index.adoc | stub | 8 | N/A (new module) | not-started | deferred | **Empty shell** — no content |

---

## Gap Analysis

### Pages in docs-map.csv That Do NOT Exist on Disk (Publish Blockers)

These are NEW pages required for C6 that have not been created:

| page_path | change_class | priority | evidence |
|-----------|-------------|----------|----------|
| `cassandra/pages/reference/cql-commands/list-superusers.adoc` | new | **release-critical** | CASSANDRA-19417. Dangling xref from commands-toc.adoc |
| `cassandra/pages/managing/operating/cluster-metadata.adoc` | new | **release-critical** | CASSANDRA-18330, CASSANDRA-19581. CMS nodetool commands |
| `cassandra/pages/managing/operating/guardrails.adoc` | new | **operator-critical** | CASSANDRA-18781, 20913, 21024, 19677 |
| `cassandra/pages/managing/operating/startup-checks-spi.adoc` | new | **operator-critical** | CASSANDRA-21093 |

**Note**: `guardrails-reference.adoc` and `startup-checks-spi.adoc` exist in the **operators** module but not in the cassandra module paths referenced by docs-map. Decision needed: use operator module versions, or create cassandra module versions, or update docs-map paths.

### Pages in docs-map.csv Not Imported to Workzone (~60 pages)

These are trunk pages classified as "unchanged" that were intentionally not imported. They exist in `apache/cassandra/doc/` but not in this workzone:

- `overview/` — 3 pages (faq, index, terminology)
- `developing/data-modeling/` — 10 pages
- `vector-search/` — 11 pages
- `tooling/` — 4 pages (cassandra-stress, generate-tokens, hash-password, index)
- `getting-started/` — 5 pages (cassandra-quickstart, configuring, index, querying, sai-quickstart, vector-search-quickstart)
- `reference/cql-commands/` — 7 pages (alter-table, create-custom-index, create-index, create-table, create-table-examples, drop-index, drop-table)
- `reference/` — 3 pages (index, java17, static, vector-data-type)
- `managing/tools/sstable/` — 8 pages (levelreset, metadata, offlinerelevel, partitions, repairedset, split, upgrade, util, verify)
- Various index pages

These are fine to omit from the workzone **unless** the Antora build needs them for xref resolution.

### Operators Module Pages NOT Tracked in docs-map.csv

| page | status | action needed |
|------|--------|--------------|
| operators/pages/tcm-overview.adoc | draft-complete | Add to docs-map |
| operators/pages/tcm-pre-upgrade.adoc | draft-complete | Add to docs-map |
| operators/pages/tcm-upgrade-procedure.adoc | draft-complete | Add to docs-map |
| operators/pages/tcm-operations.adoc | draft-complete | Add to docs-map |
| operators/pages/tcm-troubleshooting.adoc | draft-complete | Add to docs-map |
| operators/pages/guardrails-reference.adoc | draft-complete | Add to docs-map |
| operators/pages/startup-checks-spi.adoc | draft-complete | Add to docs-map |

---

## Files With Unresolved Questions / TODOs

These files contain explicit open questions, TODOs, or WIP language that MUST be resolved before publication:

| File | Issue | Count |
|------|-------|-------|
| operators/pages/guardrails-reference.adoc | TODOs for trunk verification + unresolved questions | 7 + 9 |
| operators/pages/startup-checks-spi.adoc | TODOs for trunk verification + unresolved questions | 5 + 6 |
| operators/pages/tcm-overview.adoc | Unresolved questions | 2 |
| operators/pages/tcm-pre-upgrade.adoc | TODO (discovery_timeout) + unresolved questions | 1 + 2 |
| operators/pages/tcm-upgrade-procedure.adoc | Unresolved questions | 2 |
| operators/pages/tcm-operations.adoc | Unresolved questions | 2 |
| operators/pages/tcm-troubleshooting.adoc | Unresolved questions | 2 |
| cassandra/pages/developing/cql/txn-reference.adoc | Unresolved questions at bottom | 6 |
| cassandra/pages/managing/operating/security.adoc | Unresolved questions section | 4 |
| cassandra/pages/managing/operating/snitch.adoc | Open questions for tech review | 4 |
| cassandra/pages/managing/operating/virtualtables.adoc | Open question blocks | 2 |
| cassandra/pages/managing/configuration/cass_jvm_options_file.adoc | Open questions (draft) | 5 |
| cassandra/pages/managing/configuration/configuration.adoc | Explicit "Another TO DO" | 1 |
| cassandra/pages/managing/operating/onboarding-to-accord.adoc | WIP language: "Before release this is likely to change" | 1 |

**Total: 14 files with 48+ unresolved items**

## Files With Stale References

| File | Issue |
|------|-------|
| cassandra/pages/architecture/dynamo.adoc | `{40_version}` placeholder, "4.next" reference |
| cassandra/pages/getting-started/production.adoc | `{40_version}` placeholder |
| cassandra/pages/installing/installing.adoc | Java 11/17 (needs 17/21), `{40_version}`, Python 3.8-3.11 |
| cassandra/pages/developing/cql/sai-faq.adoc | "Cassandra ???" placeholder (version numbers missing) |
| cassandra/pages/reference/cql-commands/compact-subproperties.adoc | `{product}` unresolved variable |

## Typos and Minor Errors

| File | Issue |
|------|-------|
| cassandra/pages/developing/cql/constraints.adoc | "satistfiability", "satisty", "suggar" |
| cassandra/pages/developing/cql/definitions.adoc | Broken xref: `defintions.adoc` (line 121) |
| cassandra/pages/managing/configuration/cass_logback_xml_file.adoc | "virual" (line 104) |
| cassandra/pages/managing/tools/cqlsh.adoc | "evalution" (line 337) |

---

## Work Prioritization by Audience Module

### Operators (Highest Priority)

#### Release-Critical — Must complete before C6 ships

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 1 | **cluster-metadata.adoc** (cassandra module) | DOES NOT EXIST | Create page: CMS nodetool commands, cluster metadata operations. Research: CASSANDRA-18330, CASSANDRA-19581 |
| 2 | **onboarding-to-accord.adoc** | not-started | Remove WIP language, verify consistency levels, validate batch timestamp handling |
| 3 | **configuration.adoc** | not-started | Resolve "TO DO", update for C6 YAML parameters, review CCM references |
| 4 | **cassandra_yaml_file.adoc** | draft-complete (generated) | Regenerate from trunk to capture 46 new settings |
| 5 | **tcm-overview.adoc** | draft-complete | Resolve 2 open questions |
| 6 | **tcm-pre-upgrade.adoc** | draft-complete | Resolve 1 TODO + 2 open questions |
| 7 | **tcm-upgrade-procedure.adoc** | draft-complete | Resolve 2 open questions |
| 8 | **tcm-operations.adoc** | draft-complete | Resolve 2 open questions |
| 9 | **tcm-troubleshooting.adoc** | draft-complete | Resolve 2 open questions |
| 10 | **accord-architecture.adoc** | not-started | Fix truncated cheat sheet, incomplete sentence |
| 11 | **accord.adoc** | not-started | Expand from 7-line stub to proper conceptual overview |

#### Operator-Critical — Required for operator readiness

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 12 | **guardrails.adoc** (cassandra module) | DOES NOT EXIST | Create page or reconcile with operators/guardrails-reference.adoc |
| 13 | **startup-checks-spi.adoc** (cassandra module) | DOES NOT EXIST | Create page or reconcile with operators/startup-checks-spi.adoc |
| 14 | **security.adoc** (operating) | not-started | Resolve 4 open questions, restore crypto providers section, verify native_transport_port_ssl |
| 15 | **snitch.adoc** | not-started | Resolve 4 open questions for tech review |
| 16 | **cass_env_sh_file.adoc** | not-started | Remove Thrift references, add JMX server options |
| 17 | **cass_jvm_options_file.adoc** | not-started | Resolve 5 open questions |
| 18 | **cass_rackdc_file.adoc** | not-started | Snitch deprecation + topology DC/rack updates |
| 19 | **cass_topo_file.adoc** | not-started | Same snitch deprecation updates |
| 20 | **production.adoc** | not-started | Fix `{40_version}`, add JDK 21/ZGC, snitch deprecation |
| 21 | **mtlsauthenticators.adoc** | not-started | Minor update, currently complete for 5.0 |
| 22 | **role_name_generation.adoc** | not-started | Minor update to existing content |
| 23 | **guardrails-reference.adoc** (operators) | draft-complete | Resolve 7 TODOs + 9 unresolved questions |
| 24 | **startup-checks-spi.adoc** (operators) | draft-complete | Resolve 5 TODOs + 6 unresolved questions |

#### Standard Priority

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 25 | **new/index.adoc** ("What's New") | not-started | **Complete rewrite** — currently 3-bullet placeholder, needs all C6 features |
| 26 | **dynamo.adoc** | not-started | Fix `{40_version}`, update LWT text for Accord |
| 27 | **metrics.adoc** | not-started | Add ~80 lines of C6 metrics (auto-repair, cache, encryption, auth) |
| 28 | **tombstones.adoc** | not-started | Verify rewritten prose from trunk |
| 29 | **virtualtables.adoc** | draft-complete | Resolve 2 open question blocks |

### Developers

#### Release-Critical

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 1 | **list-superusers.adoc** | DOES NOT EXIST | Create CQL command reference. Fixes dangling xref in commands-toc.adoc |
| 2 | **cql_singlefile.adoc** | not-started | Massive (2982 lines). Decide: keep or deprecate. 4 JIRA updates needed |
| 3 | **txn-reference.adoc** | draft-complete | Resolve 6 unresolved questions |
| 4 | **dml.adoc** | draft-complete | Verify BETWEEN, NOT, LIKE, index hints content |
| 5 | **security.adoc** (CQL) | draft-complete | Add GENERATED PASSWORD clause |
| 6 | **cql-on-accord.adoc** | not-started | Review pinned SHA links |

#### Standard Priority

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 7 | **SASI.adoc** | not-started | LIKE expressions update |
| 8 | **collections/list.adoc, map.adoc, set.adoc** | not-started (3 files) | SAI frozen collection updates |
| 9 | **constraints.adoc** | draft-complete | Fix typos, add missing constraint types |
| 10 | **sai-faq.adoc** | draft-complete | Fix "Cassandra ???" placeholder version numbers |
| 11 | **sai-virtual-table-indexes.adoc** | not-started | Verify reflects trunk state |

### Reference

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 1 | **native-protocol.adoc** | draft-complete (generated) | Regenerate, add v6 protocol |
| 2 | **commands-toc.adoc** | not-started | Fix dangling list-superusers xref |
| 3 | **compact-subproperties.adoc** | draft-complete | Resolve `{product}` placeholder, Greek symbol TODO |
| 4 | **nodetool/*.adoc** (160 files) | draft-complete (generated) | Regenerate from trunk picocli |
| 5 | **altertopology.adoc** | not-started | Expand from 7-line stub to real content (CASSANDRA-20528) |

### Contributors

| # | Page | Status | Work Required |
|---|------|--------|--------------|
| 1 | **contributors/pages/index.adoc** | stub | Entire module needs content: building from source, testing, contribution workflow |

---

## TCM Markdown Drafts Status

11 markdown drafts in `tcm/` (3,737 lines total) have been **largely migrated** to the 5 `.adoc` files in `operators/pages/`. The `.adoc` versions total 3,033 lines, indicating consolidation occurred. The markdown originals should be retained as reference but are not blocking.

---

## Recommended Next Steps

1. **Create the 4 missing pages** (list-superusers, cluster-metadata, guardrails cassandra-module, startup-checks-spi cassandra-module) — or decide to use operators module paths and update docs-map
2. **Resolve all 48+ open questions/TODOs** across 14 files — these require technical review against trunk source
3. **Regenerate generated docs** (cassandra_yaml_file, nodetool/*, native-protocol) from trunk
4. **Fix stale references** (`{40_version}`, Java 11, "Cassandra ???", `{product}`)
5. **Fix typos** (4 files with confirmed typos)
6. **Rewrite What's New page** — currently the most embarrassing gap for users upgrading to C6
7. **Add operators module pages to docs-map.csv** (7 pages untracked)
8. **Populate empty audience modules** (developers, contributors, reference index pages)
9. **Update metrics.adoc** with C6 additions (~80 lines needed)
10. **Address security.adoc** crypto providers gap and 4 unresolved questions
