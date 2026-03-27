# Managing/Operating Delta

## Scope
- Area: managing/operating
- Branches compared: `origin/cassandra-5.0` vs `origin/trunk`
- Subagent: managing-operating
- Status: complete

## Inventory Summary
- Pages in 5.0: 28 (including 7 compaction subpages)
- Pages in trunk: 33 (including 7 compaction subpages)
- New in trunk: 5 (`async-profiler.adoc`, `auto_repair.adoc`, `onboarding-to-accord.adoc`, `password_validation.adoc`, `role_name_generation.adoc`)
- Removed from 5.0: 0
- Generated surfaces: Some pages include `include::` directives for example output files (e.g., `backups.adoc` references several new `RESULTS/` files for ephemeral/TTL snapshot output). These are static example output, not auto-generated.

## Key Differences

The trunk operating docs reflect several major Cassandra 6.0 features:

1. **Auto Repair (CEP-37)**: A fully automated, built-in repair scheduler replacing the need for external repair tools. ~460 lines of new, comprehensive documentation covering configuration, token range splitting strategies, nodetool commands, and table-level overrides.

2. **Accord consensus migration**: Detailed guide (~370 lines) for migrating tables between Paxos and the new Accord consensus protocol. Covers two-phase migration, consistency level support, metrics, batchlog/hints behavior, and partition range read performance implications.

3. **Password validation and generation (CEP-24)**: ~320 lines documenting configurable password strength policies via Guardrails, including dictionary checks, characteristic-based validation (length, uppercase, lowercase, digits, special chars), and the `GENERATED PASSWORD` CQL clause.

4. **Role name generation (CEP-55)**: ~122 lines documenting UUID-based role name generation with prefix/suffix support, building on the CEP-24 guardrails framework.

5. **Async-profiler integration**: ~141 lines documenting built-in async-profiler support via `nodetool profile` subcommands (start, stop, status, list, fetch, purge, execute).

6. **Metrics expansion**: +294/-30 lines. Major additions include unweighted cache metrics (auth caches), client encryption metrics, client authentication mode metrics, automated repair metrics (~80 lines), bootstrap storage metrics, preview repair table metrics, and hints metrics expansion (HintsFileSize, HintsThrottle, HintsApplySucceeded/Failed).

7. **Compression**: +230 lines adding ZstdDictionaryCompressor documentation including dictionary training via nodetool, CQL configuration, dictionary storage/refresh/caching, and operational considerations.

8. **Security**: +204/-90 lines. Added PEM private key password-via-file configuration examples, JMX SSL configuration in `cassandra.yaml` (replacing legacy system property approach), cross-references to new password_validation and role_name_generation pages. **Removed** the entire "Crypto providers" section (~70 lines on `DefaultCryptoProvider`/Amazon Corretto Crypto Provider) -- this content does not appear to have been relocated elsewhere in trunk docs.

9. **Snitch**: -82 lines. Removed detailed documentation for cloud-based snitches (AlibabaCloudSnitch, AzureSnitch, GoogleCloudSnitch, EC2 IMDS details, AbstractCloudMetadataServiceSnitch architecture). The Ec2Snitch and Ec2MultiRegionSnitch entries remain but are briefer. RackInferringSnitch was moved to the end. Possible interface rename: `IEndpointSnitch` -> `IEndPointSnitch`.

10. **Tombstones**: +94 lines. Improved prose clarity, renamed "Zombies" section to "Preventing Data Resurrection", added three `sstabledump` JSON output examples showing live rows, expired TTL rows, and deletion tombstones.

## Page-Level Findings

| Page | Status | Delta Size | Notes |
|------|--------|-----------|-------|
| `async-profiler.adoc` | new | +141 | `nodetool profile` subcommands, async-profiler shipped with Cassandra |
| `auto_repair.adoc` | new | +460 | CEP-37, comprehensive: config, splitters, nodetool, table CQL property |
| `onboarding-to-accord.adoc` | new | +371 | Accord migration guide: two-phase process, consistency levels, metrics |
| `password_validation.adoc` | new | +320 | CEP-24, password guardrails, `GENERATED PASSWORD`, runtime JMX config |
| `role_name_generation.adoc` | new | +122 | CEP-55, `CREATE GENERATED ROLE`, UUID generator, prefix/suffix support |
| `audit_logging.adoc` | minor-update | +8/-4 | Updated roll_cycle options for Chronicle Queue (FAST_HOURLY default) |
| `auditlogging.adoc` | minor-update | +1/-1 | Typo fix: "shoudl" -> "should" |
| `backups.adoc` | major-update | +61/-2 | Ephemeral snapshots, TTL snapshots with examples, virtual table listing |
| `bulk_loading.adoc` | minor-update | +1/-77 | Removed inline CLI options list, replaced with xref to sstableloader doc |
| `compaction/tombstones.adoc` | major-update | +94/-8 | Prose rewrite for clarity, three new sstabledump JSON examples |
| `compression.adoc` | major-update | +230 | ZstdDictionaryCompressor: training, config, nodetool commands, ops notes |
| `hints.adoc` | minor-update | +4 | Added `auto_hints_cleanup_enabled` config parameter |
| `index.adoc` | minor-update | +6/-1 | Added nav links for auto_repair, password_validation, role_name_generation, onboarding-to-accord |
| `metrics.adoc` | major-update | +294/-30 | New metric sections: unweighted cache, client encryption, auth mode, auto repair, bootstrap. Renamed "Cache Metrics" to "Weighted Cache Metrics". JMX MBean format fixes (commas). |
| `repair.adoc` | minor-update | +19/-5 | Added "Automated Repair Scheduling" section with xref to auto_repair, minor reformatting |
| `security.adoc` | major-update | +204/-90 | JMX SSL in yaml, PEM password-file config, CEP-24/55 xrefs. Removed Crypto providers section. |
| `snitch.adoc` | major-update | -82 | Removed cloud snitch details (Alibaba, Azure, Google Cloud, EC2 IMDS details) |
| `virtualtables.adoc` | major-update | +113 | New `system_metrics` keyspace docs, `partition_key_statistics` virtual table, thread_pools core/max pool size note |
| All other pages | unchanged | 0 | bloom_filters, cdc, compaction/index, compaction/lcs, compaction/overview, compaction/stcs, compaction/twcs, compaction/ucs, denylisting_partitions, fqllogging, hardware, logging, read_repair, topo_changes, transientreplication |

## Apparent Coverage Gaps

1. **Crypto providers section removed from security.adoc**: The 5.0 documentation on `DefaultCryptoProvider`, Amazon Corretto Crypto Provider, and custom `AbstractCryptoProvider` implementations was entirely removed from trunk. No replacement content was found anywhere in the trunk docs tree. If this feature still exists in Cassandra 6.0, its documentation is missing. If the feature was removed or changed, this should be confirmed.

2. **Cloud-based snitch documentation removed from snitch.adoc**: Detailed documentation for AlibabaCloudSnitch, AzureSnitch, GoogleCloudSnitch, EC2 IMDS version configuration, and the AbstractCloudMetadataServiceSnitch architecture was removed. Only brief Ec2Snitch and Ec2MultiRegionSnitch entries remain. Need to verify if these cloud snitches were actually removed from Cassandra 6.0 code, or if the docs were moved/consolidated elsewhere.

3. **onboarding-to-accord.adoc incompleteness signals**: The doc contains the phrase "Before release this is likely to change" regarding batch handling of Accord/non-Accord data, suggesting pre-release WIP content that should be verified against final implementation.

4. **async-profiler.adoc not in index.adoc**: While it is properly listed in `nav.adoc`, it is not referenced from the operating `index.adoc` page. Other new pages (auto_repair, password_validation, role_name_generation, onboarding-to-accord) were added to `index.adoc`.

5. **denylisting_partitions.adoc unchanged**: This page references `system_distributed.partition_denylist` -- should be verified that no schema or behavior changes occurred in trunk.

6. **IEndpointSnitch vs IEndPointSnitch**: The snitch.adoc diff shows a change from `IEndpointSnitch` to `IEndPointSnitch`. This may be either a correction or an error -- should verify against actual trunk code.

## Generated-Doc Notes

- `backups.adoc` uses `include::` directives to pull in example output files. Six new result files were added on trunk for ephemeral/TTL snapshot features. These are static example content, not auto-generated from code.
- No metrics pages appear to be auto-generated; all metric tables are hand-authored.
- No nodetool help output is auto-generated in these pages.

## Recommended Follow-Up

1. **Verify crypto provider status**: Determine if the crypto provider feature was removed, moved, or if docs were accidentally dropped. Check trunk Java source for `AbstractCryptoProvider` and related classes.

2. **Verify cloud snitch removal**: Check trunk source for `AlibabaCloudSnitch`, `AzureSnitch`, `GoogleCloudSnitch` classes to determine if they were removed or if documentation needs to be restored/relocated.

3. **Review onboarding-to-accord.adoc for WIP language**: Search for speculative/pre-release language and update to reflect final 6.0 behavior.

4. **Add async-profiler to index.adoc**: The page is in `nav.adoc` but missing from the operating section's `index.adoc`.

5. **Verify IEndPointSnitch naming**: Confirm the correct interface name in trunk source code.

6. **Metrics completeness**: The metrics page received major additions but should be cross-checked against actual Cassandra 6.0 MBeans to ensure completeness. New features like Accord, auto repair, and ZstdDictionaryCompressor all add metrics that should be documented.

7. **Review auto_repair.adoc thoroughness**: This is by far the largest new page (~460 lines). Given the complexity of CEP-37, verify that all configuration parameters match the actual `cassandra.yaml` defaults and that nodetool commands match implementation.

## Notes

- This is the largest delta area with 2305 insertions and 304 deletions across 18 files.
- Five entirely new pages account for ~1,414 lines of new content (auto_repair alone is ~460 lines).
- The documentation quality of new pages is generally high, with thorough configuration tables, CQL examples, and nodetool usage.
- The `onboarding-to-accord.adoc` page is the most complex new page conceptually, covering a multi-phase migration process with nuanced consistency semantics.
- The removal of content (crypto providers, cloud snitches) needs verification to determine whether these reflect actual code removals or documentation oversights.
