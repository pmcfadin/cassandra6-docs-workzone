# CASSANDRA-20854: Async-Profiler Support for Low-Overhead Profiling

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary

CASSANDRA-20854 integrates the async-profiler library directly into Cassandra, exposing profiling functionality through JMX with a corresponding `nodetool profile` command group. The feature ships disabled by default and is enabled via the `cassandra.async_profiler.enabled` JVM property. It supports CPU, memory allocation, lock contention, wall-clock, native memory, and cache-miss profiling with multiple output formats including flamegraphs and JFR. Profiling results are stored on the node and can be retrieved remotely via `nodetool profile fetch`. A dedicated authored doc page already exists on trunk at `doc/modules/cassandra/pages/managing/operating/async-profiler.adoc`.

## Discovery Source

- `NEWS.txt` reference: "It is possible to use Async-profiler for various profiling scenarios. See CASSANDRA-20854."
- `CHANGES.txt` reference: Present under 6.0 changes.
- Related JIRA: https://issues.apache.org/jira/browse/CASSANDRA-20854
- PR: https://github.com/apache/cassandra/pull/4487
- Commit: https://github.com/apache/cassandra/commit/7c3c3a1d86782a515583f89c6f17fb30e7f5e41e
- Fix version: 6.0-alpha1, 6.0
- Assignee: Bernardo Botella Corbi
- Reviewers: Dmitry Konstantinov, Stefan Miklosovic

## Why It Matters

- **User-visible effect:** Operators can now profile running Cassandra nodes (CPU hotspots, memory allocations, lock contention, etc.) without attaching external tools or restarting the JVM.
- **Operational effect:** Low-overhead profiling in production environments. Results are stored on the node and can be fetched remotely via JMX, eliminating the need for direct filesystem access to retrieve flamegraphs or JFR files.
- **Upgrade or compatibility effect:** None -- the feature is entirely additive and disabled by default. No breaking changes.
- **Configuration or tooling effect:** New JVM property (`cassandra.async_profiler.enabled`), new nodetool command group (`nodetool profile`), and optional configuration for output directory and unsafe mode.

## Source Evidence

### Relevant docs paths

- `doc/modules/cassandra/pages/managing/operating/async-profiler.adoc` -- **Authored doc already exists on trunk.** Covers enabling, all subcommands, configuration properties, and JAR replacement instructions.
- `doc/modules/cassandra/nav.adoc` -- Navigation entry exists under Managing > Operating > Async-profiler.

### Relevant config paths

- `conf/jvm-server.options` -- Contains the `cassandra.async_profiler.enabled` property (disabled by default).

### Relevant code paths

- `src/java/org/apache/cassandra/tools/profiler/AsyncProfilerService.java` -- Core service managing profiler lifecycle.
- `src/java/org/apache/cassandra/tools/profiler/AsyncProfiler.java` -- Profiler abstraction layer.
- `src/java/org/apache/cassandra/tools/profiler/AsyncProfilerMBean.java` -- JMX MBean interface.
- `src/java/org/apache/cassandra/tools/profiler/AsyncProfilerUnsafe.java` -- Unsafe mode for arbitrary profiler commands.
- `src/java/org/apache/cassandra/tools/nodetool/AsyncProfileCommandGroup.java` -- Nodetool command group registration.
- `src/java/org/apache/cassandra/tools/nodetool/Profile.java` -- Nodetool profile subcommands.

### Relevant test paths

- Multiple test files for service and command validation (included in PR #4487).

### Relevant generated-doc paths

- Nodetool generated docs may need regeneration to include the new `profile` command group and its subcommands. This requires validation.

## What Changed

| Aspect | Before | After (Cassandra 6.0) |
|--------|--------|----------------------|
| Profiling | External tools required (attach async-profiler manually) | Built-in `nodetool profile` command group |
| JMX integration | None | Full MBean for profiling lifecycle management |
| Output retrieval | Direct filesystem access required | `nodetool profile fetch` retrieves files remotely via JMX |
| Supported events | N/A | cpu, alloc, lock, wall, nativemem, cache_misses |
| Output formats | N/A | flat, traces, collapsed, flamegraph, tree, jfr, otlp |
| Default state | N/A | Disabled; enable via `cassandra.async_profiler.enabled=true` |
| Result storage | N/A | `cassandra.logdir/async-profiler` (configurable via `cassandra.logdir.async_profiler`) |
| Unsafe mode | N/A | Optional `cassandra.async_profiler.unsafe_mode` for arbitrary profiler commands |

### Nodetool subcommands

| Subcommand | Purpose |
|-----------|---------|
| `nodetool profile start` | Start profiling with configurable event, duration, and output format |
| `nodetool profile stop` | Stop profiling early and retrieve results |
| `nodetool profile status` | Check if profiling is active and duration |
| `nodetool profile list` | List stored profiling result files on the node |
| `nodetool profile fetch` | Retrieve result files from node to local filesystem |
| `nodetool profile purge` | Remove all stored profiling result files |
| `nodetool profile execute` | Run arbitrary async-profiler commands (requires unsafe mode) |

## Docs Impact

**Impact Level:** Low -- authored documentation already exists on trunk.

### Existing pages likely affected

- `doc/modules/cassandra/pages/managing/operating/async-profiler.adoc` -- **Already exists and appears comprehensive.** Covers enabling, all subcommands, configuration, and JAR replacement.
- `doc/modules/cassandra/nav.adoc` -- Navigation entry already present.
- Generated nodetool docs -- May need regeneration to include `nodetool profile` and its subcommands. Requires build validation.

### New pages likely needed

- None. The authored page already exists.

### Audience home

- Operators > Performance / Operating

### Authored or generated

- The main doc page is authored. Nodetool reference pages are generated and need validation.

### Technical review needed from

- Bernardo Botella Corbi (implementer) or Stefan Miklosovic (reviewer) for accuracy check of existing authored doc.

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: async-profiler.adoc
- Owner role: docs-lead
- Publish blocker: no

### Recommended actions

1. **Validate existing authored doc** -- Review `async-profiler.adoc` on trunk for completeness and accuracy against the implementation.
2. **Regenerate nodetool docs** -- Verify that `nodetool profile` and its subcommands appear in the generated nodetool reference pages after a trunk build.
3. **Cross-reference check** -- Ensure the page is appropriately cross-referenced from any performance tuning or monitoring pages.
4. **Update index.md** -- Change status from `queued` / `changelog-only` to `validated` / `repo-validated`.

## Open Questions

1. **Are generated nodetool docs up to date for `nodetool profile`?** The picocli migration (CASSANDRA-17445) should auto-generate these, but validation after a trunk build is needed to confirm the `profile` command group and all subcommands render correctly.

2. **Is the `jvm-server.options` property the only enablement mechanism?** Confirm there is no `cassandra.yaml` setting for async-profiler. Current evidence says JVM property only.

3. **Kernel parameter requirements** -- The PR mentions kernel parameter validation on startup. The authored doc should note any Linux-specific prerequisites (e.g., `perf_event_paranoid` sysctl setting for CPU profiling).

4. **OTLP output format** -- The `otlp` output format is listed in the code. Is OpenTelemetry export documented in the authored page? This may be a gap if operators want to send profiling data to observability platforms.

## Next Research Steps

1. Build trunk and validate generated nodetool docs include `nodetool profile` subcommands.
2. Diff `async-profiler.adoc` against the implementation to confirm all options and events are documented.
3. Check for any kernel/OS prerequisites that should be documented.
4. Confirm OTLP output format coverage in the authored doc.
5. Update `inventory/docs-map.csv` and `index.md` status fields.

## Notes

- The feature was created August 20, 2025 and resolved January 12, 2026.
- Stefan Miklosovic's contribution was key in designing the `fetch`/`list` subcommands to solve the remote profiling results retrieval problem (large files over JMX).
- The async-profiler library itself is bundled with Cassandra; operators can replace it with a compatible version if needed.
- The `execute` subcommand (unsafe mode) is intentionally gated behind a separate property to prevent accidental misuse in production.
- The `inventory/docs-map.csv` already tracks this page as `new` and `authored` on trunk.
- The `future/audience-information-architecture.md` maps this to `/operators/performance/` in the proposed future IA.
