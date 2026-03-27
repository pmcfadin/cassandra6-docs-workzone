# CASSANDRA-20858 system_views.uncaught_exceptions virtual table

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | new-page |

## Summary
CASSANDRA-20858 introduces `system_views.uncaught_exceptions`, a virtual table that captures unhandled JVM exceptions thrown during Cassandra node operation. Each distinct exception class/location pair is tracked with a count, the last message, last stack trace (as a list of strings), and last occurrence timestamp. The table holds up to 1,000 distinct exception entries in memory. Exceptions that occur before the virtual table initializes are buffered in `ExceptionsTable.preInitialisationBuffer` and flushed once the table is ready. The table supports `TRUNCATE` to clear all entries.

## Discovery Source
- `NEWS.txt` reference: not verified
- `CHANGES.txt` reference: "Expose uncaught exceptions in system_views.uncaught_exceptions table (CASSANDRA-20858)"
- Related JIRA: CASSANDRA-20858

## Why It Matters
- User-visible effect: Operators can query `SELECT * FROM system_views.uncaught_exceptions` to detect recurring internal errors without log file access. The table aggregates repeated occurrences of the same exception at the same location, showing total count and most recent occurrence.
- Operational effect: Enables programmatic alerting on exception frequency via CQL. Particularly useful for automated health checks in managed environments where log file access is restricted.
- Upgrade or compatibility effect: Additive. New table; no existing APIs or tables changed. Not present in Cassandra 5.0.
- Configuration or tooling effect: No configuration required. Buffer is capped at 1,000 entries (not currently configurable). `TRUNCATE system_views.uncaught_exceptions` clears the buffer.

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — `uncaught_exceptions` is not mentioned anywhere in the current doc (confirmed by text search on trunk)
- Relevant code paths:
  - `src/java/org/apache/cassandra/db/virtual/ExceptionsTable.java` — table class; table name constant `EXCEPTIONS_TABLE_NAME = "uncaught_exceptions"`; schema: partition key `exception_class` (text), clustering `exception_location` (text); regular columns `count` (int), `last_message` (text), `last_stacktrace` (list\<text\>), `last_occurrence` (timestamp)
  - `src/java/org/apache/cassandra/db/virtual/SystemViewsKeyspace.java` — registered as `.add(new ExceptionsTable(VIRTUAL_VIEWS))`
  - `src/java/org/apache/cassandra/utils/logging/AbstractVirtualTableAppender.java` — used to initialize the singleton `INSTANCE` lazily; exceptions before initialization go to `preInitialisationBuffer`
- Relevant test paths:
  - `test/unit/org/apache/cassandra/db/virtual/ExceptionsTableTest.java`

## What Changed
1. New virtual table `system_views.uncaught_exceptions` registered in `SystemViewsKeyspace`.
2. Schema (from `ExceptionsTable.java`):
   - Partition key: `exception_class text`
   - Clustering: `exception_location text`
   - Regular: `count int`, `last_message text`, `last_stacktrace list<text>`, `last_occurrence timestamp`
3. Exception tracking logic:
   - When an uncaught exception fires, `ExceptionsTable.persist(Throwable t)` is called. It unwraps the root cause and records the class name and the first stack frame as the location.
   - If the same (class, location) pair recurs, `count` is incremented and `last_message`/`last_stacktrace`/`last_occurrence` are updated in place.
   - The buffer is bounded to 1,000 total entries. When full, the oldest entry (by `last_occurrence`) is evicted.
4. `TRUNCATE` is supported and clears all entries.
5. Partition-level reads (`data(DecoratedKey)`) are supported for efficient single-class queries.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/virtualtables.adoc` — needs a new section for `uncaught_exceptions` describing the schema, how exceptions are captured, how to use it for health monitoring, and how to clear it with `TRUNCATE`
- New pages likely needed: None
- Audience home: Operators
- Authored or generated: Authored
- Technical review needed from: No specialized domain required; general Cassandra operations reviewer sufficient

## Proposed Disposition
- `inventory/docs-map.csv` classification: major-update
- Affected docs: `virtualtables.adoc`
- Recommended owner role: docs-contributor or docs-lead
- Publish blocker: no

## Open Questions
- Which Cassandra code paths call `ExceptionsTable.persist()`? Is it a global uncaught exception handler, or are specific catch blocks instrumented? This determines how complete the coverage is.
- Is the 1,000-entry cap ever likely to be configurable in a future release? Worth noting as a caveat or deferring mention.
- Does `exception_location` always correspond to the first stack frame, or can it be `"unknown"` when the stack trace is empty?

## Next Research Steps
- Search for all call sites of `ExceptionsTable.persist()` to document the scope of exception capture
- Confirm whether there is a global uncaught-exception-handler wiring or only explicit instrumentation
- Draft a `virtualtables.adoc` section with schema, sample query, eviction behavior note, and `TRUNCATE` usage

## Notes
- Commit: `e42599a094` on trunk — "Expose uncaught exceptions in system_views.uncaught_exceptions table"
- Root cause unwrapping: `ExceptionsTable.persist()` walks `getCause()` until it reaches the root exception before recording class/location, so the class and location shown are always from the innermost cause.
- Pre-initialization buffer: If Cassandra throws an exception before the virtual table is registered (very early startup), those exceptions are held in `preInitialisationBuffer` (a synchronized `ArrayList`) and flushed when the table initializes via `flush()`.
- Not present in cassandra-5.0.
