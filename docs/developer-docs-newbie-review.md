# Developer Docs: Newbie Review Findings

Review date: **2026-04-01**

## Method

Eight agents were dispatched in parallel, each playing a junior developer with 1-2 years of general backend experience and zero Cassandra knowledge. Each agent was assigned a specific doc section and asked to flag issues from a first-time reader's perspective. Findings were compiled and deduplicated by an experienced Cassandra developer acting as gatekeeper.

Severity levels:
- **P1 — Blocker**: Missing or misleading content that causes a developer to fail, give up, or ship broken code
- **P2 — Major**: Confusing content, missing examples for key concepts, cross-file inconsistencies
- **P3 — Minor**: Typos, polish, nice-to-have diagrams

---

## P1 — Blockers

### Getting Started (`index.adoc`, `quickstart.adoc`)

**P1-01** — No diagram of Cassandra's data hierarchy (keyspace → table → partition → row). The entire quickstart is command execution without mental model. A developer copying these commands into production won't understand what they're running.

**P1-02** — `replication_factor: 1` has zero warning that this means "no fault tolerance, dev only." A junior dev will copy this verbatim to production. Needs a prominent `WARNING:` admonition. `quickstart.adoc:52-53`

**P1-03** — Docker is an undisclosed prerequisite. The quickstart opens with `docker run` but never says "you need Docker installed." `quickstart.adoc:8`

**P1-04** — `uuid()` and `toTimestamp(now())` used in CQL examples with no explanation. Why UUID instead of an integer ID? What does `toTimestamp()` wrap and why? `quickstart.adoc:62-75`

### CQL Fundamentals (`dml.adoc`, `ddl.adoc`, `types.adoc`)

**P1-05** — `INSERT` behaves as an upsert (create-or-overwrite) and this is never clearly stated. A SQL developer will assume `INSERT` enforces uniqueness. The statement "there is no means of knowing which action occurred" is buried at `dml.adoc:437-443` with no warning callout.

**P1-06** — No "SQL Developers: Key Differences" section at the start of `cql/index.adoc`. The critical landmines (no JOINs, no arbitrary WHERE, upsert semantics, no full table scan by default) are scattered across pages. A SQL developer needs these upfront in one place.

**P1-07** — `ALLOW FILTERING` danger is understated. No red `WARNING:` box explaining that this scans the entire cluster on large tables. The current explanation reads like a footnote. `dml.adoc:344-388`

**P1-08** — PRIMARY KEY (partition key vs. clustering columns) has no diagram. The double-parenthesis syntax `PRIMARY KEY ((a, b), c)` is genuinely confusing without a visual showing what each part controls. `ddl.adoc:327-360`

### Accord Transactions (`txn-reference.adoc`)

**P1-09** — `BEGIN TRANSACTION` cannot be used as a prepared statement. This is a critical production constraint buried as a note at `txn-reference.adoc:28`. Needs to be a top-level `IMPORTANT:` admonition. Developers will hit this when optimizing performance.

**P1-10** — The page has a `[IMPORTANT] Preview | Unofficial | For review only` status indicator that is not prominent enough. A developer following a link here won't realize they're reading draft content.

**P1-11** — No explanation of how Accord transactions interact with eventual consistency. A developer needs to understand: "When NOT in a transaction, Cassandra is eventually consistent. When IN a transaction, it's serializable." Never stated clearly. `txn-reference.adoc:259-291`

### Vector Search (`vector-search/index.adoc`, `examples/index.adoc`)

**P1-12** — Embedding dimensions are never explained with real model examples. "Dimension must match your embedding model" is useless without reference points (OpenAI text-embedding-3-small = 1536, Cohere embed-v3 = 1024). Without this, developers create tables with wrong dimensions and break their vector search silently. `vector-search/index.adoc:27`

**P1-13** — `examples/index.adoc` uses `dimension = 3` for vector examples — a toy value no developer can copy to production. Should use 1536 (matching a real model) with a note. `examples/index.adoc:259`

**P1-14** — No end-to-end vector search example showing the actual embedding API call. Every example shows `[0.1, 0.2, 0.3]` hardcoded. A developer building a real AI application needs: call embedding API → get vector → store/query in Cassandra. This is the biggest gap in the agentic section.

---

## P2 — Major Issues

### Language Quickstarts (all 4 files)

**P2-01** — Readiness verification is inconsistent across languages:
- Java: `docker exec cassandra cqlsh -e "DESCRIBE KEYSPACES"`
- Python: "wait about 30 seconds" (no command)
- Go: `nodetool status` looking for `UN`
- Node: `cqlsh -e "SHOW VERSION"`

Pick one and standardize. The current state signals the four quickstarts were written independently without cross-review.

**P2-02** — UUID generation strategy is inconsistent: Java/Python/Node use random UUIDs, Go uses `gocql.TimeUUID()` (time-based) with no explanation of why or the tradeoff. `go.adoc:143`

**P2-03** — Cassandra 6 features are mentioned inconsistently. Java mentions C6 compatibility; Python mentions "lightweight transactions"; Go mentions nothing; Node mentions `BEGIN TRANSACTION`. Should appear in all 4 with the same framing.

**P2-04** — Python quickstart uses both `?` and `%s` as bind parameter placeholders in different sections without explaining the difference. Looks like a bug. `python.adoc:135`

**P2-05** — Container is named `cassandra-go` in the Go quickstart but `cassandra` in all others. Breaks copy-paste muscle memory. `go.adoc:32`

### Core Concepts (`drivers.adoc`, `data-modeling/index.adoc`)

**P2-06** — The #1 mental shift in Cassandra ("design tables around your queries, not your data") gets one sentence. This needs a full example showing the same domain in SQL (entity-relationship) vs. Cassandra (query-driven tables), with an explanation of why Cassandra's storage model requires this. `data-modeling/index.adoc:10-14`

**P2-07** — `drivers.adoc` provides no decision support. No "choose your driver" guidance, no feature comparison showing Cassandra 6 support (Accord, constraints), no recommendation for beginners. The page is a list of links.

**P2-08** — `integration-patterns.adoc` is almost entirely CQL with no application code. Patterns like "update multiple denormalized tables atomically" need driver code (Python/Java), not just CQL snippets. `integration-patterns.adoc:27-31`

**P2-09** — "Cassandra Lucene Index (Retired)" section in `integration-patterns.adoc` is a distraction in a Cassandra 6 doc. Should be one line: "Deprecated as of Cassandra 5.0. Use SAI instead." `integration-patterns.adoc:105-110`

### CQL Advanced

**P2-10** — SAI vs. legacy secondary indexes (2i) is never clearly explained. The SAI docs reference "advantages over existing indexes" without saying what those indexes are. `sai-concepts.adoc:8`

**P2-11** — Critical SAI performance caveat buried in FAQ: "AND queries will process up to two SAI indexes; if more than two SAI indexes are used, SAI performs post-filtering on the remaining clauses." This is a design constraint that belongs in `sai-concepts.adoc` as a prominent warning, not in a FAQ answer. `sai-faq.adoc:267-280`

**P2-12** — Collection performance gotchas (entire collection read for any access, list prepend/append not idempotent) appear AFTER the syntax examples. The warnings need to precede the examples. `types.adoc:339-381`

**P2-13** — Counters section opens with "a column whose value is a 64-bit signed integer" — sounds benign. The severe limitations (non-idempotent, no retry guarantee, broken deletion semantics) are buried. The opening sentence should be a warning. `types.adoc:58-85`

**P2-14** — Accord `LET` clause restrictions (no range queries, equality-only partition key, at most one row per LET) have no explanation of why they exist or what the workaround is. `txn-reference.adoc:57-61`

### Task Guides

**P2-15** — `adopting-acid-transactions.adoc:227-235` gives contradictory prepared statement guidance: "driver-level `session.prepare()` calls do function in practice" but "the prepared statement is not reused." Developers need a clear directive: avoid PreparedStatement for transaction statements for now.

**P2-16** — `pagination.adoc` never explains the failure mode of skipping pagination. Does the driver buffer everything in memory? OOM? Timeout? Knowing the failure mode is more motivating than the best practice alone.

**P2-17** — `schema-migrations.adoc` recommends polling for schema agreement ("check every 500ms, timeout after 30s") but shows no code for the polling loop. The guidance is unimplementable as written.

**P2-18** — `time-series-modeling.adoc` uses `'2024-03-15 08:00:00'` in a query without clarifying whether this is a string literal, CQL timestamp syntax, or a function call. `time-series-modeling.adoc:223-233`

### Production & Operations

**P2-19** — `readiness-checklist.adoc:200` contains: "full observability guide is planned for Phase 4.3." This is an internal planning note in a developer-facing doc. Remove or replace with current guidance.

**P2-20** — `observability.adoc:334` says "Use the community Cassandra driver Grafana dashboard as a starting point" with no link and no dashboard name. Find the link or remove the recommendation.

**P2-21** — `upgrading-to-cassandra6.adoc:155` checklist item says "Verify your driver version supports Cassandra 6" but gives no minimum version numbers for any driver. This makes the checklist unactionable.

**P2-22** — `driver-tuning.adoc:194` config name `max-executions = 2` has a confusing inline comment: "1 original + 2 speculative = 3 total max." The setting name implies 2 total executions but the comment says 3. Needs a rewrite.

### Modern Features / Agentic

**P2-23** — `mcp-server.adoc:28-29` says "Several Cassandra MCP server implementations exist. Search for..." with no links. Either link to specific implementations or remove the section.

**P2-24** — `ai-application-patterns.adoc` "Why Cassandra for vectors" section is a sales pitch, not decision guidance. Reframe around: "Use Cassandra for vectors when your vectors augment existing relational/time-series data. Use a dedicated vector DB when semantic search is your only workload."

**P2-25** — `ai-application-patterns.adoc:347` shows LangChain integration with `cassio.init()` but never explains where `cassio` comes from, what `pip install cassio` installs, or its current maintenance status.

---

## P3 — Minor Issues

**P3-01 TYPO** — `dml.adoc:149`: `blog_tile` → `blog_title`

**P3-02 TYPO** — `types.adoc:81`: `idemptotent` → `idempotent`

**P3-03 TYPO** — `constraints.adoc:345`: `againt` → `against`

**P3-04 BROKEN COMMENT** — `security.adoc:1`: First line contains `// role_name ::= identifier | string= Security` — appears to be a broken AsciiDoc comment merged with the section title.

**P3-05 GRAMMAR** — `dml.adoc:381`: "Cassandra cannot guarantee that large amounts of data won't have to scanned amount of data" — sentence is broken. Rewrite.

**P3-06 GRAMMAR** — `types.adoc:155`: "Values of the `duration` type are encoded as 3 signed integer" → "integers"

**P3-07 MISSING DIAGRAM** — `time-series-modeling.adoc`: A visual of the partition structure would anchor the guide. Example: `Partition: (sensor_id='dev-001', day='2024-03-15') → [Row@14:30, Row@14:25, Row@14:20 sorted DESC]`

**P3-08 MISSING DIAGRAM** — `pagination.adoc`: Token-range parallel pagination needs a visual of the token ring divided into worker-assigned ranges.

**P3-09 MISSING DIAGRAM** — `sai-read-write-paths.adoc:172-196`: The match streaming and post-filtering pipeline is impossible to follow in prose alone. Needs a flow diagram.

**P3-10 PLACEMENT** — `ddl.adoc`: `CREATE TABLE LIKE` section sits between `DROP TABLE` and `TRUNCATE`. Move it adjacent to `CREATE TABLE`. The "What is NOT copied" warning should be in a callout at the top of the section, not buried in the body.

**P3-11 VAGUE TIMING** — `quickstart.adoc`: "Wait about 30 seconds for the node to initialize" should be: "Wait 30-60 seconds, then verify with `docker exec cassandra cqlsh -e 'DESCRIBE KEYSPACES'`. If it fails, wait another 30 seconds and retry."

---

## Summary by Section

| Section | P1 | P2 | P3 |
|---|---|---|---|
| Getting Started | 4 | 0 | 1 |
| Language Quickstarts | 0 | 5 | 0 |
| Core Concepts | 0 | 4 | 0 |
| CQL Fundamentals | 4 | 1 | 3 |
| CQL Advanced | 3 | 5 | 1 |
| Task Guides | 0 | 4 | 1 |
| Production & Ops | 0 | 4 | 0 |
| Modern Features | 3 | 7 | 1 |
| **Total** | **14** | **30** | **7** |

---

## Top 5 Highest-Impact Fixes

1. **Add a keyspace → table → partition → row diagram** to the quickstart. Every downstream concept depends on this mental model.

2. **Add a "SQL Developers: Read This First" callout** at the top of `cql/index.adoc` listing the 5 biggest CQL surprises: INSERT=upsert, no JOINs, partition key required in WHERE, ALLOW FILTERING danger, replication ≠ SQL clustering.

3. **Add real embedding dimension examples** to `vector-search/index.adoc` and change `examples/index.adoc` dimension from 3 to 1536 with an actual embedding API call.

4. **Standardize language quickstarts**: same container name, same readiness check command, same Cassandra 6 feature callout at the end.

5. **Add `WARNING:` admonition before `replication_factor: 1`** in the quickstart. This is the most dangerous copy-paste trap in the docs.
