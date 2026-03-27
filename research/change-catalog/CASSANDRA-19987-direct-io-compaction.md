# CASSANDRA-19987 Direct I/O for compaction reads

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
Adds a new `compaction_read_disk_access_mode` setting in `cassandra.yaml` that allows operators to use Direct I/O (O_DIRECT) for SSTable reads during compaction. This bypasses the OS page cache, preventing cache pollution from read-once compaction workloads. Benchmarks show up to 48% p99 latency improvement for concurrent read workloads under memory pressure. The feature defaults to `auto` (inheriting from `disk_access_mode`), preserving existing behavior.

## Discovery Source
- `NEWS.txt` reference: not checked (trunk)
- `CHANGES.txt` reference: "Direct IO support for compaction reads (CASSANDRA-19987)"
- Related JIRA: [CASSANDRA-19987](https://issues.apache.org/jira/browse/CASSANDRA-19987)
- Parent JIRA: [CASSANDRA-14466](https://issues.apache.org/jira/browse/CASSANDRA-14466) (Enable Direct I/O -- umbrella)
- Follow-up: [CASSANDRA-21147](https://issues.apache.org/jira/browse/CASSANDRA-21147) (Direct IO for cursor-based compaction -- resolved)
- PR: [#4178](https://github.com/apache/cassandra/pull/4178)

## Why It Matters
- User-visible effect: Reduced read latency spikes during compaction. Benchmarks showed p99 latency dropping from 34.6ms to 18.0ms (48% improvement) and mean latency from 1.88ms to 1.41ms (25% improvement) in a constrained-memory scenario.
- Operational effect: Page cache stays warmer for client reads when compaction is running. Memory pressure stalls reduced ~29%. Particularly benefits Size-Tiered Compaction with large SSTables.
- Upgrade or compatibility effect: None. Default is `auto` which preserves pre-6.0 behavior. Opt-in only.
- Configuration or tooling effect: New `cassandra.yaml` setting `compaction_read_disk_access_mode` with values `auto` (default) and `direct`.

## Source Evidence
- Relevant docs paths:
  - Generated `cass_yaml_file.adoc` -- should include `compaction_read_disk_access_mode` after regeneration
  - Compaction overview docs -- no current mention of Direct I/O or disk access mode for compaction
  - `disk_access_mode` existing documentation -- related context
- Relevant config paths:
  - `conf/cassandra.yaml` -- new `compaction_read_disk_access_mode` setting with inline documentation
  - `conf/cassandra_latest.yaml` -- same
- Relevant code paths:
  - `src/java/org/apache/cassandra/config/Config.java` -- `public DiskAccessMode compaction_read_disk_access_mode = DiskAccessMode.auto;`
  - `src/java/org/apache/cassandra/config/DatabaseDescriptor.java` -- resolution logic, getter/setter, validation (rejects values other than `auto` and `direct`)
  - `src/java/org/apache/cassandra/db/compaction/AbstractCompactionStrategy.java` -- passes disk access mode to scanner
  - `src/java/org/apache/cassandra/db/compaction/CompactionManager.java` -- passes disk access mode to scanner
  - `src/java/org/apache/cassandra/db/compaction/LeveledCompactionStrategy.java` -- passes disk access mode to scanner
  - `src/java/org/apache/cassandra/io/sstable/format/SSTableReader.java` -- scanner creation accepts DiskAccessMode
  - `src/java/org/apache/cassandra/io/util/FileHandle.java` -- builder changes for direct I/O readers
- Relevant test paths: Not explicitly named in JIRA; performance benchmarks cited in PR
- Relevant generated-doc paths: `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` (generated surface)
- Commit: [6f5fe8c06d5831daae1f1a4f2412f3185798dca0](https://github.com/apache/cassandra/commit/6f5fe8c06d5831daae1f1a4f2412f3185798dca0)

## What Changed

1. **New cassandra.yaml setting: `compaction_read_disk_access_mode`**
   - Values: `auto` (default, inherits from `disk_access_mode`) or `direct` (uses O_DIRECT)
   - Only `auto` and `direct` are valid; other values cause `IllegalArgumentException` at startup
   - Appears in both `cassandra.yaml` and `cassandra_latest.yaml`

2. **Scanner path updated** to accept a `DiskAccessMode` parameter. All compaction strategy classes (`AbstractCompactionStrategy`, `CompactionManager`, `LeveledCompactionStrategy`) now pass `DatabaseDescriptor.getCompactionReadDiskAccessMode()` when creating SSTable scanners.

3. **Direct I/O infrastructure:**
   - New `ByteBufferHolder` interface for abstracting aligned buffer management
   - `DirectThreadLocalByteBufferHolder` and `DirectThreadLocalReadAheadBuffer` for O_DIRECT alignment requirements
   - `FileHandle` updated to support building direct I/O readers
   - Startup verification that data directories support Direct I/O

4. **Scope limitation:** Initially applies only to iterator-based (scanner) compaction. Cursor-based compaction support was delivered separately in CASSANDRA-21147 (also resolved for 6.0).

## Docs Impact
- Existing pages likely affected:
  - **Generated `cass_yaml_file.adoc`** -- must include `compaction_read_disk_access_mode` after regeneration
  - **Compaction overview/strategy docs** -- should mention Direct I/O as a tuning option for reducing page cache pressure during compaction
  - **`disk_access_mode` documentation** -- should cross-reference the new compaction-specific setting
- New pages likely needed: None (fits within existing compaction tuning guidance)
- Audience home: Operators (managing/configuration, managing/operating/compaction)
- Authored or generated: **Both** -- generated yaml reference + authored compaction guidance
- Technical review needed from: Compaction maintainers (Sam Lightfoot, Jon Haddad, Ariel Weisberg)

## Proposed Disposition
- Inventory classification: regen-validate
- Affected docs: cass_yaml_file.adoc
- Owner role: generated-doc-owner
- Publish blocker: no

## Open Questions
- Does the generated `cass_yaml_file.adoc` on trunk already include `compaction_read_disk_access_mode`? Needs regeneration check.
- Is Direct I/O supported on all platforms (Linux, macOS, Windows)? The parent JIRA (CASSANDRA-14466) references JDK 10 API; need to confirm platform requirements and what happens on unsupported platforms.
- With CASSANDRA-21147 also resolved for 6.0, does `compaction_read_disk_access_mode: direct` now cover both iterator and cursor compaction paths? If so, the "scope limitation" note may not apply to final 6.0.
- Are there alignment or filesystem requirements (e.g., sector-aligned buffers, filesystem support for O_DIRECT)?
- What is the interaction with `disk_access_mode: mmap`? Does `compaction_read_disk_access_mode: auto` inherit mmap, and is that a valid compaction read mode?

## Next Research Steps
- Regenerate cass_yaml_file.adoc and confirm `compaction_read_disk_access_mode` appears with correct documentation
- Check CASSANDRA-21147 commit to determine if cursor compaction path is also covered for 6.0
- Verify platform support / failure behavior on non-Linux systems
- Review compaction authored docs for best insertion point for Direct I/O tuning guidance
- Compare `cassandra-5.0` cassandra.yaml to confirm this setting is net-new in 6.0

## Notes
- Fix versions: 6.0-alpha1, 6.0
- Reporter: Jon Haddad; Assignee: Sam Lightfoot
- PR merged February 4, 2026, with approvals from Ariel Weisberg and Maxwell Guo
- Performance benchmarks (1GB hot dataset, 3GB page cache scenario):
  - p99 latency: 48.1% improvement (34.60ms to 17.96ms)
  - Mean latency: 25.0% improvement (1.88ms to 1.41ms)
  - Memory pressure stalls: 29% reduction
  - Page cache stability: 2.5x more stable
- The parent umbrella JIRA CASSANDRA-14466 ("Enable Direct I/O") has been open since 2018; this is the first concrete deliverable for compaction reads
