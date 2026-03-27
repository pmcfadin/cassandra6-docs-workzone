# CASSANDRA-18831 JDK 21 + Generational ZGC as Default Garbage Collector

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
Cassandra 6.0 adds official JDK 21 support and introduces Generational ZGC as the default garbage collector when running on JDK 21. A new `jvm21-server.options` configuration file provides ZGC-specific tuning parameters (with G1GC settings available but commented out). This is a significant operational change: prior Cassandra versions defaulted to G1GC on all supported JDKs. The `jvm21-server.options` file did not exist in Cassandra 5.0 or any earlier release.

## Discovery Source
- `NEWS.txt` reference: "JDK21 and Generational ZGC are now officially supported and generational ZGC is now the default Garbage Collector when using JDK21. See jvm21-server.options for more details and configuration parameters. We do not recommend using non-generational ZGC with Apache Cassandra."
- `CHANGES.txt` reference: Not explicitly listed in 6.0 CHANGES.txt (no JIRA entry found in CHANGES.txt for this feature)
- Related JIRA: CASSANDRA-18831 ("Add JDK21 support")
- Related CEP or design doc: None identified

## Why It Matters
- User-visible effect: None directly; this is an infrastructure/runtime change.
- Operational effect: Major. Operators running Cassandra 6.0 on JDK 21 will get Generational ZGC by default instead of G1GC. This changes GC pause characteristics, heap behavior, and tuning parameters. ZGC is designed for low-latency with sub-millisecond pauses but has different throughput and memory overhead tradeoffs compared to G1GC.
- Upgrade or compatibility effect: Operators upgrading to Cassandra 6.0 who also move to JDK 21 must be aware their GC will change. Those who wish to continue using G1GC on JDK 21 must edit `jvm21-server.options` to comment out ZGC lines and uncomment G1GC lines. The file includes both configurations.
- Configuration or tooling effect: New file `conf/jvm21-server.options` must be documented. Key flags include `-XX:+UseZGC`, `-XX:+ZGenerational`, and `-XX:-UseCompressedOops` (required workaround for jamm). Optional tuning parameters include `SoftMaxHeapSize`, `ZUncommit`, `ZUncommitDelay`, and `AlwaysPreTouch`.

## Source Evidence
- Relevant docs paths: `doc/modules/cassandra/pages/managing/configuration/cass_jvm_options_file.adoc` (currently references jvm11 and jvm17 but not jvm21)
- Relevant config paths: `conf/jvm21-server.options` (new in 6.0), `conf/jvm17-server.options` (existing, uses G1GC by default for comparison)
- Relevant code paths: Commit by Josh McKenzie, reviewed by Mick Semb Wever and Ekaterina Dimitrova for CASSANDRA-18831
- Relevant test paths: Not specifically investigated
- Relevant generated-doc paths: None identified

## What Changed
1. **New file `conf/jvm21-server.options`** -- provides JDK 21-specific JVM settings, activated automatically when Cassandra detects Java 21+.
2. **Default GC changed to Generational ZGC on JDK 21** -- `-XX:+UseZGC` and `-XX:+ZGenerational` are enabled (uncommented). G1GC settings are present but commented out.
3. **CompressedOops disabled** -- `-XX:-UseCompressedOops` is required as a workaround for jamm's incorrect default when using ZGC.
4. **ZGC-specific tuning options documented in file** -- `SoftMaxHeapSize`, `ZUncommit`, `ZUncommitDelay`, `AlwaysPreTouch`, `UseLargePages` are available but commented out by default.
5. **G1GC available as fallback** -- Full G1GC configuration block is present (commented out) with the same tuning parameters as `jvm17-server.options`.
6. **JPMS exports/opens** -- Expanded set of `--add-exports` and `--add-opens` directives for JDK 21 module system compatibility.
7. **Security manager flag** -- `-Djava.security.manager=allow` added (deprecated for removal in future JDKs).
8. **Non-generational ZGC explicitly not recommended** -- NEWS.txt states this clearly.
9. **Separate GC inspector thresholds** -- CASSANDRA-20980 (separate ticket) introduces `gc_concurrent_phase_log_threshold` and `gc_concurrent_phase_warn_threshold` in cassandra.yaml for concurrent GC phases like those in ZGC.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/configuration/cass_jvm_options_file.adoc` -- needs update to mention `jvm21-server.options` alongside jvm11 and jvm17 files
  - `doc/modules/cassandra/pages/getting-started/production.adoc` -- likely has JDK/GC recommendations
  - Any page referencing supported Java versions or GC tuning
- New pages likely needed: Possibly a dedicated GC tuning guide or a section on ZGC-specific tuning for Cassandra
- Audience home: Operators (managing/configuration)
- Authored or generated: Authored
- Technical review needed from: Josh McKenzie or Mick Semb Wever (original patch authors/reviewers)

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: cass_jvm_options_file.adoc; production.adoc
- Owner role: docs-lead
- Publish blocker: yes

## Open Questions
- Is CASSANDRA-18831 the sole JIRA for this change, or was there a separate ticket for making ZGC the default (vs. just adding JDK 21 support)?
- What are the recommended heap size ranges for ZGC vs G1GC on Cassandra workloads?
- Should the docs include migration guidance for operators switching from G1GC to ZGC (e.g., monitoring differences, tuning starting points)?
- Does `cassandra-env.sh` need updates for JDK 21 detection logic?
- How does CASSANDRA-20980 (separate GC thresholds for concurrent phases) interact with the ZGC default -- should they be documented together?

## Next Research Steps
- Verify whether there is a separate JIRA for making ZGC the default (vs. just JDK 21 support) by checking the CASSANDRA-18831 sub-tasks
- Review `cassandra-env.sh` for JDK version detection logic that selects the correct jvm*-server.options file
- Check if `production.adoc` or other getting-started docs reference supported JDK versions
- Investigate CASSANDRA-20980 (concurrent GC phase thresholds) as a related doc item
- Confirm the `jvm-server.options` header comment needs updating (currently references jvm11 and jvm17 but not jvm21)

## Notes
- The `jvm-server.options` base file header says "See jvm11-server.options and jvm17-server.options" but does not mention jvm21. This is a minor documentation gap in the config file itself.
- The jvm17-server.options file uses G1GC as default; jvm21-server.options uses ZGC. This is the first time Cassandra has shipped with different default GCs for different JDK versions.
- Non-generational ZGC is explicitly discouraged in NEWS.txt. The `-XX:+ZGenerational` flag enables the generational mode which became default in JDK 21 but was not the only mode available.
- The `-XX:-UseCompressedOops` requirement for jamm is a known constraint that increases memory footprint. This should be called out in documentation.
