# Cassandra 6 Docs — Upstream Migration Log

**Source plan**: `backlog/upstream-migration-plan.md`  
**Build stack plan**: `backlog/build-stack-upgrade-plan.md`  
**Started**: 2026-04-16  
**Last updated**: 2026-05-14 (Step 0a measurement: **138 Antora-3 errors** on `broken-link-fix` + PR #319-merged trunk — the gap-to-reland)

---

## How to Use This Log

Each section maps to a stage in `upstream-migration-plan.md`. Update the status table and append dated entries under each stage as work progresses. This is the audit trail for all upstream contribution activity.

---

## Overall Status

| Stage | Description | Status | Blocker |
|---|---|---|---|
| Step 0a | Build stack upgrade (Antora 3) | 🟡 In progress — **gated on broken-link workstream** | PR #315 merged 2026-04-17, **reverted 2026-04-21** (commit `b753289a` by Stefan Miklosovic) because Antora 3's `failure_level: error` fails on the existing xref backlog. 2026-05-14 local measurement: **138 Antora-3 errors remain** with PRs #319 (merged) + #4807 (open) applied. Reland blocked on driving this to 0 through `broken-link-fix-log.md` Phases 4–5. |
| Step 0b | Community process setup | ⬜ Not started | |
| Step 1 | Test PR (2-3 pages) | ⬜ Not started | Blocked: Step 0a re-blocked since 2026-04-21 revert. Step 0b also still open. |
| Stage 2 | Minor-update pages (28 pages) | ⬜ Not started | Blocked on Step 1 |
| Stage 3 | Draft-complete major-update pages (13 pages) | ⬜ Not started | Blocked on Step 1 |
| Stage 4 | Not-yet-drafted major-update pages (19 pages) | ⬜ Not started | Blocked on Stage 3 |
| Stage 5 | New pages (6 pages, all blocked) | ⬜ Not started | Publish blockers per page |
| Stage 6 | Generated surfaces (3 surfaces) | ⬜ Not started | Separate track |
| Structure | IA proposal (audience-split) | ⬜ Not started | Dev@ discussion first |

---

## Step 0a: Build Stack Upgrade

**Goal**: Upgrade `apache/cassandra-website` from Antora 2.3 to Antora 3.1.14 before content PRs begin.  
**Plan**: `backlog/build-stack-upgrade-plan.md`  
**Branch**: `antora-3-upgrade` in `pmcfadin/cassandra-website`

### Staging & Publish Path

The Apache Cassandra website does not accept direct staging pushes. The path is:

1. PR merged to `apache/cassandra-website:trunk`
2. CI auto-builds at [ci-cassandra.apache.org/job/cassandra-website](https://ci-cassandra.apache.org/job/cassandra-website/) and pushes to `asf-staging`
3. Verify at https://cassandra.staged.apache.org/
4. Promote to production:
   ```bash
   git fetch origin
   git switch asf-site
   git reset --hard origin/asf-staging
   git push -f origin asf-site
   ```

### Build Stack Target State

| Component | Before | After |
|---|---|---|
| Antora CLI | `@antora/cli@2.3` | `@antora/cli@3.1.14` |
| Site generator | `@antora/site-generator-default@2.3` | `@antora/site-generator@3.1.14` |
| Search | `antora-lunr` + `antora-site-generator-lunr` | `@antora/lunr-extension` |
| Node.js | `v20.16.0` | `v24.14.1` |
| Render invocation | `antora --generator antora-site-generator-lunr site.yaml` | `antora site.yaml` |
| DOCSEARCH env wiring | `DOCSEARCH_ENABLED`, `DOCSEARCH_ENGINE=lunr`, `NODE_PATH`, `DOCSEARCH_INDEX_VERSION` | Removed |
| AsciiDoc extensions | `tabs-block.js`, `@djencks/asciidoctor-openblock` | Unchanged |

### Build Stack Stage Checklist

| Stage | Description | Status |
|---|---|---|
| Stage 1 | Baseline current upstream behavior | ✅ Done |
| Stage 2 | Audit workzone content for Antora 3 xref compat | 🟡 Partial — 2026-05-14 local Antora 3 build of `broken-link-fix` produced a categorized error report (xref 106, image 24, section 4, table 4); see entry below |
| Stage 3 | Upgrade build container | ✅ Done |
| Stage 4 | Migrate render pipeline to Antora 3 extension wiring | ✅ Done |
| Stage 5 | Validate multi-version build end to end | ✅ Done |
| Stage 6 | Open JIRA + PR, get staging validation | 🟡 Partial — PR #315 merged 2026-04-17, reverted 2026-04-21 |

### 2026-04-16

**Repo setup**
- Cloned `pmcfadin/cassandra` → `./cassandra`
- Cloned `pmcfadin/cassandra-website` → `./cassandra-website`
- Added `upstream` remote to both repos
- Synced `cassandra-website` fork: merged `upstream/trunk` (fast-forward, only `site-content/source/modules/ROOT/pages/download.adoc` changed)
- User manually synced `cassandra` fork on GitHub; local clone reset with `git reset --hard origin/trunk`
- Fetched `cassandra-5.0` and `cassandra-4.1` from `upstream` into local cassandra clone; created local tracking branches

**Stage 1 — Baseline captured**
- Antora 2.3, Node 20.16.0, `antora-site-generator-lunr` custom generator, DOCSEARCH env wiring documented in this log

**Stage 3 — Container upgrade**
- `site-content/Dockerfile`: Node 24.14.1 (SHA256 verified x64 + arm64), Antora 3.1.14, `@antora/lunr-extension`
- `site-content/docker-entrypoint.sh`: removed `--generator` flag, removed DOCSEARCH env exports (both preview and build-site paths)
- `site-content/site.template.yaml`: added `antora.extensions` block with `@antora/lunr-extension`
- Committed as `22fa090b` on branch `antora-3-upgrade`
- Pushed to `pmcfadin/cassandra-website`

**Stage 4 — Pipeline migration**
- Docker image built successfully: `./run.sh website container` ✅
- Image: `localhost/apache/cassandra-website:latest`

**Stage 5 — Multi-version validation**
- Single-branch build (`trunk`): `./run.sh website build -g -u cassandra:../cassandra -b cassandra:trunk` ✅
  - `search-index.js` present (6.7MB) — `@antora/lunr-extension` confirmed working
  - xref errors in output are all pre-existing in upstream trunk, not Antora 3 regressions
- Multi-branch build (`trunk`, `cassandra-5.0`, `cassandra-4.1`): ✅
  - First attempt failed — `cassandra-5.0` and `cassandra-4.1` not in local clone; fetched from upstream
  - Second attempt: `./run.sh website build -g -u cassandra:../cassandra -b cassandra:trunk,cassandra-5.0,cassandra-4.1` ✅
  - Version directories in `content/doc/`: `4.1/`, `5.0/`, `6.0/`, `latest/`, `stable/` ✅
  - `stable/` and `latest/` alias behavior unchanged ✅

**Local preview**
- `./run.sh website preview` container exits before live-server starts (it tries to clone cassandra from GitHub when no `-u` flag given, or exits after build when the `entr` watch process fails)
- Workaround: `python3 -m http.server 5151` from `cassandra-website/content/` (note: not `site-content/build/html/` — that only has the homepage, not the versioned docs)
- `http://localhost:5151/doc/latest/` returns 200 ✅

### Next Actions — Step 0a

- [x] JIRA created: **CASSANDRA-21315**
- [x] PR opened: **https://github.com/apache/cassandra-website/pull/315**
- [x] Built full 5-branch site (3.11, 4.0, 4.1, 5.0, 6.0) with Antora 3.1.14 — 2026-04-16
- [x] Pushed to `upstream/asf-staging` directly (committer pre-merge verification) — 2026-04-16
- [x] Verify at https://cassandra.staged.apache.org/ — verified pre-merge
- [x] PR reviewed and merged to `apache/cassandra-website:trunk` — merged 2026-04-17 by pmcfadin (commit `15f7e91d`)
- [x] CI deploys to `asf-staging` (auto, after merge)

### 2026-04-17 — PR #315 merged

- Merged `antora-3-upgrade` → `trunk` at 2026-04-17 20:53 UTC (commit `15f7e91d58072a73f69262e6b6230b77f79ed1f2`).
- Antora 3.1.14 + Node 24.14.1 + `@antora/lunr-extension` now live in `apache/cassandra-website` trunk.
- Step 0a closed; downstream phases of the broken-link workstream (see `broken-link-fix-log.md`) are no longer blocked on the build stack.
- Step 0b (community process setup) and Step 1 (test PR) remain ⬜ — next actions for this log.

### 2026-04-21 — PR #315 REVERTED

- Stefan Miklosovic landed `b753289ae8b3918410d0f69963369634bb2419a9`
  ("Revert \"Upgrade docs build stack to Antora 3.1 and Node 24 LTS\"")
  on `apache/cassandra-website:trunk`, four days after the original
  merge.
- Commit body is a bare `This reverts commit 83e009aff9e4c1a70c381ef351aff56643618c0a.` — no failure analysis attached to the commit.
- Files touched by the revert: `site-content/Dockerfile`,
  `site-content/docker-entrypoint.sh`, `site-content/site.template.yaml`,
  `site-ui/Dockerfile`, `site-ui/preview-src/ui-model.yml`,
  `site-ui/src/partials/body.hbs`,
  `site-ui/src/partials/footer-scripts.hbs`. Antora 3.1.14 → Antora
  2.3.4, Node 24 → Node 20.16.0.
- Discovered 2026-05-13 while preparing the local PR #4807 verification
  build — the rebuilt container came up as Antora 2.3.4 / Node 20.16.0
  instead of the expected Antora 3 stack. Cross-check of
  `upstream/trunk:site-content/Dockerfile` confirmed the revert.
- **Root cause (per Patrick, 2026-05-13):** Antora 3's default
  `failure_level` is `error`, treating any error as build-fatal.
  Antora 2 only fails on `fatal`, so the existing 713-error xref
  backlog was tolerated as warnings. On Antora 3, the same backlog
  failed the build outright. The revert restored Antora 2's tolerance
  to keep CI/staging green while the xref backlog gets cleaned up
  through `broken-link-fix-log.md` Phases 2–5.
- **Sequencing implication:** Antora 3 reland (this log's Step 0a)
  must come *after* Phase 6 of the broken-link-fix log
  ("Tighten `failure_level` back to `error`"), which itself depends
  on Phases 2–5 being far enough along that fail-on-error is feasible
  on the supported branches. PR #319 (merged) and PR #4807 (open) are
  the active workstream for that backlog.
- Action: do not re-attempt Step 0a until the xref backlog on the
  in-scope branches is small enough to pass `failure_level: error`.
- [ ] Run Stage 2 xref audit on workzone content (can run in parallel with PR review)

### 2026-05-14 — Antora 3 reland measurement: 138 errors to go

Spun up an Antora 3 build locally to put a concrete number on the
"how far from reland?" question. Method:

1. **Working-tree-only Antora 3** in `cassandra-website` clone: `git
   revert b753289a --no-edit` to re-apply PR #315's changes on top of
   current trunk (`35c6027c`, post-PR-#319). One conflict in
   `site-content/docker-entrypoint.sh` (the `cassandra-6.0` branch
   addition between original merge and revert touched the same antora
   invocation line); resolved by keeping the Antora 3 form (`antora
   site.yaml` without `--generator antora-site-generator-lunr`).
   Resulting local commit `897d1a67`.
2. **JSON logging** enabled via `.xref-env` with
   `ANTORA_LOG_FORMAT=json` (per `runbooks/fix-broken-xref.md`).
3. **Container rebuild** with the un-reverted Dockerfile: Antora
   3.1.14 / Node 24.14.1 / `@antora/lunr-extension` installed. 2m29s.
4. **Build** with `./run.sh website build -e .xref-env -g
   -u cassandra:../cassandra -b cassandra:broken-link-fix`. 3m43s.
   Total wall time 6m12s. Exit 0 (the container's run.sh wrapper
   does not propagate Antora 3's failure-level signal as a non-zero
   exit on this version of `docker-entrypoint.sh`; the build still
   reports errors in its JSON log).
5. **`bin/xref-report.sh`** against the captured JSON log.

**Result: 138 error-level entries** on `broken-link-fix` after PR #319
(merged) and PR #4807 (open) fixes are applied. Breakdown:

```
xref      106
image      24
section     4
table       4
include     0
```

**Top error patterns:**

- 4 × `master@_:ROOT:bugs.adoc` — deferred A1/A3 work
- 4 × `level 0 sections can only be used when doctype is book` — `security.adoc`, `changes.adoc`
- 4 × `dropping cells from incomplete row detected end of table`
- 22 × data-modeling images (`images/data_modeling_*.png|jpg`,
  `images/Figure_*.jpg`) missing from the cassandra repo
- ~100 long-tail xref errors — legacy paths (`use_tools.adoc`,
  `architecture/snitch.adoc`, `compaction/index.adoc`,
  `tools/cqlsh.adoc`, `reading_logs.adoc`, `_/download.adoc`),
  `.html` extension usage (`troubleshooting/index.html`,
  `dml.html#writetime-and-ttl-function`), typos
  (`defintions.adoc`), and missing component-qualified targets

**Sanity checks passed:**
- All 7 PR #4807 fix patterns: 0 occurrences in error log
  (`reference:user-defined-type`, `reference:data-types`,
  `keyspace-check`, `master@_:ROOT:contactus`,
  `architecture/storage-engine/memtable`,
  `configuration/configuration/`, `cql_singlefile.html`)
- PR #319's 19 cassandra-website-side errors gone (`xref-report.sh`
  diff: `-19 asf-staging`)
- `bugs.adoc` errors still present (confirms deferred items remain
  and Antora 3 is reading the right content)

**Caveat on the baseline diff:** `xref-report.sh` reports `fixed: 713 /
introduced: 138 / net: -575`, but this is misleading because the
baseline keys by `(branch, msg)` and the baseline's 8 source branches
(trunk, cassandra-6.0, cassandra-5.0.8, cassandra-5.0, cassandra-4.1,
cassandra-4.0, cassandra-3.11, asf-staging) all "fixed" because this
build only has 1 branch (`broken-link-fix`). The 138 absolute count is
the meaningful number, not the diff.

**Implication for Step 0a (this log):**

- Reland target = **0 errors** under Antora 3 with `failure_level:
  error` (the default). Current: **138**.
- ~28 errors are clearly Phase 5 territory (4 doctype + 4 table + 24
  images).
- ~106 xref errors are remaining Phase 4 long-tail. Many look like
  message-class fixes similar to PR #4807's pattern (legacy paths,
  `.html` → `.adoc`, missing component prefix, typos).
- 4 are deferred work the contributor explicitly parked (bugs.adoc).
- The Step 0a reland is **not** the next milestone — it's the *last*
  one. Work between now and reland lives in `broken-link-fix-log.md`.

**Cleanup applied 2026-05-14:** local `897d1a67` reset to
`upstream/trunk`, `.xref-env` removed, phantom mode flips restored
from stash. cassandra-website clone is back to upstream parity.

**Artifacts kept** (gitignored, in `/tmp/`, re-analyzable):
- `/tmp/antora3-build.log` — full build output (705 JSON log lines)
- `/tmp/antora3-json.log` — extracted JSON only
- `/tmp/antora3-container.log` — container rebuild log

To re-run this measurement after future broken-link-fix PRs land, the
recipe is the same: `git revert b753289a` in working tree, resolve the
`docker-entrypoint.sh` conflict, rebuild container with `-e .xref-env
-g -u cassandra:../cassandra -b cassandra:trunk` (or whichever branch
holds the fixes under test), run `bin/xref-report.sh` against the JSON
log, then reset and stash-pop.

### Known Issues

- `./run.sh website preview` requires explicit `-u cassandra:` flag to avoid remote clone; even then the `entr` watcher may exit the container. Use `python3 -m http.server 5151` from `content/` as workaround.
- Pre-existing broken xrefs in upstream trunk (not caused by this upgrade): `cassandra_stress.adoc`, `cql_singlefile.html`, `bugs.adoc`, `contactus.adoc` in nav files.

---

## Step 0b: Community Process Setup

**Goal**: JIRA umbrella, AI disclosure acknowledgment, committer sponsor, dev@ announcement.

### Exit Criteria (from plan)

- [ ] Umbrella JIRA "Cassandra 6 Documentation Updates" created
- [ ] AI disclosure approach acknowledged (lazy consensus sufficient)
- [ ] At least one committer agreed to review docs PRs
- [ ] Build stack compatibility resolved ← blocked on Step 0a PR merge

### AI Disclosure Template (per plan)

Commit message addition: `AI-assisted: Claude (Anthropic)`  
PR description statement: "Content was drafted with AI assistance (Claude, Anthropic) and reviewed against source code in `apache/cassandra` trunk. Source provenance is maintained in workzone research artifacts available for inspection."

---

## Step 1: Test PR

**Goal**: Validate contribution mechanics with 2-3 low-controversy minor-update pages.

**Candidate pages** (from plan):
- `doc/modules/cassandra/pages/managing/operating/compaction/overview.adoc`
- `doc/modules/cassandra/pages/managing/operating/auto_repair.adoc`
- `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc`

**Blocked on**: Step 0a PR merged + Step 0b committer sponsor identified.

### Exit Criteria

- [ ] PR merged (or concrete process feedback)
- [ ] AI disclosure format accepted or adjusted
- [ ] Build verification approach confirmed

---

## Stage 2: Minor-Update Pages (28 pages)

**Blocked on**: Step 1 merged.

**JIRA groupings planned**:
- "Minor CQL and developer docs updates for Cassandra 6"
- "Minor operator and operations docs updates for Cassandra 6"
- "Minor tools and reference docs updates for Cassandra 6"

**Target**: 8-12 pages per PR, one PR per JIRA subtask.

### Exit Criteria

- [ ] All 28 minor-update authored pages merged to trunk
- [ ] No Antora build regressions

---

## Stage 3: Draft-Complete Major-Update Pages (13 pages)

**Blocked on**: Step 1 merged.  
**Note**: `ddl.adoc` and `dml.adoc` have `publish_blocker=yes` — excluded until maintainer decisions.

**JIRA groupings planned**:
- "SAI indexing documentation updates for Cassandra 6"
- "CQL syntax and security documentation updates for Cassandra 6"
- "Operator operations documentation updates for Cassandra 6"

### Exit Criteria

- [ ] All non-blocked draft-complete major-update pages merged
- [ ] Technical review completed per slice
- [ ] Blocked pages tracked in JIRAs with unblock criteria

---

## Stage 4: Not-Yet-Drafted Major-Update Pages (19 pages)

**Blocked on**: Stage 3 merged.  
**Prerequisite**: Draft each page in workzone using `cassandra-asciidoc-authoring` skill before contributing.

Notable pages: `dynamo.adoc` (snitch deprecation), 6 configuration files, `metrics.adoc`, `new/index.adoc` (What's New).

### Exit Criteria

- [ ] All non-blocked major-update pages drafted, reviewed, and merged
- [ ] Blocked pages explicitly deferred or unblocked

---

## Stage 5: New Pages (6 pages — all blocked)

**All 6 have `publish_blocker=yes`.**  Maintainer decisions required per page before any can land.

| Page | Blocker |
|---|---|
| `developing/cql/txn-reference.adoc` | Accord syntax scope |
| `managing/operating/cluster-metadata.adoc` | Maintainer decision |
| `managing/operating/guardrails.adoc` | Maintainer decision |
| `managing/operating/startup-checks-spi.adoc` | Maintainer decision |
| `managing/tools/nodetool/altertopology.adoc` | Maintainer decision |
| `reference/cql-commands/list-superusers.adoc` | Maintainer decision |

**Audience-module pages** (vector search, TCM, etc.) additionally require Structure Track resolution.

---

## Stage 6: Generated Surfaces (Separate Track)

**3 surfaces — NOT authored content. Migration = verify/fix generation scripts, not copy files.**

| Surface | Generator |
|---|---|
| `managing/configuration/cass_yaml_file.adoc` | `conf/cassandra.yaml` via `ant gen-asciidoc` |
| `managing/tools/nodetool/*.adoc` | `doc/scripts/gen-nodetool-docs.py` |
| `reference/native-protocol.adoc` | `doc/scripts/process-native-protocol-specs-in-docker.sh` |

### Exit Criteria

- [ ] `ant gen-asciidoc` on trunk produces correct output
- [ ] Any script changes submitted as separate JIRA/PR from authored content

---

## Structure Track: IA Proposal (Parallel, Non-blocking)

**Goal**: Community consensus on audience-split IA before proposing structural changes.  
**Does NOT block**: Stages 1-4.  
**Blocks**: Audience-module pages in Stage 5 (vector search, TCM, etc.)

### Exit Criteria

- [ ] Dev@ thread posted with audience-first IA proposal
- [ ] Consensus reached (or alternative agreed)
- [ ] JIRA created for restructure if accepted

---

## Per-PR Checklist (copy for each PR)

- [ ] JIRA subtask exists and linked
- [ ] Pages copied from `content/modules/cassandra/pages/` → `doc/modules/cassandra/pages/` at same relative path
- [ ] "Preview | Unofficial" admonitions removed
- [ ] Workzone-specific xrefs adjusted to upstream paths
- [ ] Local Antora build verified via `cassandra-website`
- [ ] `AI-assisted: Claude (Anthropic)` in commit message if applicable
- [ ] PR description includes source provenance statement
- [ ] `nav.adoc` updated if new pages added
