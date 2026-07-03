# Upstream Migration Plan

Created: **2026-04-09**

## Purpose

Step-by-step plan for moving Cassandra 6 documentation from this workzone into `apache/cassandra` `trunk` (`doc/modules/cassandra/pages/`). Content changes are separated from structural/IA changes. Website wire-up (`apache/cassandra-website`) is out of scope.

This plan incorporates community feedback received on the initial contribution proposal, specifically:
- Keep new content additions and layout restructuring as separate tracks
- Use focused, reviewable PRs rather than large bundled contributions
- Address AI-generated content provenance incrementally, building on ASF guidance and the unresolved community thread on AI vetting

## Two Parallel Tracks

| Track | Scope | Forum |
|-------|-------|-------|
| **Content** | Updated and new pages contributed as focused PRs to existing paths in `doc/modules/cassandra/pages/` | JIRA + GitHub PRs |
| **Structure** | Proposed layout/IA changes (audience-split modules, new directory locations) | dev@cassandra mailing list discussion first, then JIRA + PRs after consensus |

The content track is what this plan sequences. The structure track is a prerequisite for Stage 4 only.

## Structural Constraint

The workzone uses an audience-split IA (operators, developers, contributors, reference as separate Antora components). The upstream repo uses a single `cassandra` module with topic-based directories.

- **71 imported-and-edited pages** in `content/modules/cassandra/pages/` map 1:1 back to `doc/modules/cassandra/pages/`. These move without any structural debate.
- **New audience-module pages** (vector search, TCM content) live in `content/operators/`, `content/developers/`, etc. These need the structure track resolved before they can land upstream.

## Build Stack Gap

**Critical finding**: The workzone and upstream use incompatible Antora versions.

Detailed implementation sequencing for this gap now lives in [build-stack-upgrade-plan.md](build-stack-upgrade-plan.md). Treat that document as the operative plan for the infra track under Step 0.

| Component | Workzone | Upstream (cassandra-website) |
|-----------|----------|------------------------------|
| Antora | 3.1.14 | 2.3 |
| Asciidoctor | 2.2.8 (@asciidoctor/core) | ~1.5.9 (bundled with Antora 2.3) |
| AsciiDoc extensions | None declared in playbook | `./lib/tabs-block.js`, `@djencks/asciidoctor-openblock` |
| Node.js | Not pinned | v20.16.0 (pinned in Dockerfile) |

Antora 2.3 to 3.x is a major version jump with breaking changes including Asciidoctor incompatibilities and extension handling. Content authored against Asciidoctor 2.2 may not render correctly with Asciidoctor 1.5.

**Specific risks**:
- `[tabs]` blocks used in 10+ workzone pages — workzone playbook doesn't declare the `tabs-block.js` extension that upstream requires
- Cross-reference handling changed between Antora 2.3 and 3.x (automatic `.adoc` extension fallback removed in 3.x)
- AsciiDoc attribute behavior differences between Asciidoctor 1.5 and 2.2

**Resolution options** (one must be completed before content PRs):

1. **Upgrade cassandra-website to Antora 3.x** — Bigger lift but correct long-term direction. Requires a JIRA + PR to cassandra-website, testing all version branches still render. This could be proposed as a preparatory step for the C6 docs program.
2. **Validate workzone content against Antora 2.3** — Build workzone pages using the upstream Docker stack, identify and fix any rendering failures before submitting PRs. Conservative but avoids blocking on a website upgrade.
3. **Hybrid** — Submit a cassandra-website Antora upgrade PR in parallel with content work. Validate content against both stacks during the transition.

**Recommendation**: Option 1 (upgrade upstream) if a cassandra-website committer is supportive. Option 2 (validate against 2.3) as fallback. Either way, build verification must happen before the first content PR.

## Step-By-Step Sequence

### Step 0: Establish Community Process and Validate Build Stack

**Goal**: Set up the JIRA structure, settle the AI provenance question, and resolve the build stack compatibility gap before content PRs start.

Actions:
1. Create umbrella JIRA: "Cassandra 6 Documentation Updates"
2. Revive or reference Ariel's mailing list thread on AI-generated content vetting — propose a concrete disclosure approach for this docs program
3. Identify a committer sponsor willing to review and merge docs PRs
4. Post a brief summary to dev@cassandra describing the staged approach: content PRs first, IA discussion separate
5. **Resolve build stack compatibility**: Test workzone content against the upstream Antora 2.3 build stack using the cassandra-website Docker container. Identify rendering failures (tabs, xrefs, attributes). Either:
   - Fix content to render cleanly with Antora 2.3, OR
   - Propose and land an Antora 3.x upgrade PR to cassandra-website first
6. **Add missing extension declarations** to workzone playbook (`tabs-block.js`, `@djencks/asciidoctor-openblock`) so local preview matches upstream rendering

Build-stack sequencing note:
- The detailed dependency chain, target state, and quality gates for item 5 now live in [build-stack-upgrade-plan.md](build-stack-upgrade-plan.md).

AI disclosure approach to propose:
- Commit messages include `AI-assisted: Claude (Anthropic)` when AI materially contributed
- PR description states which tool was used and that output was reviewed for third-party material
- Source provenance trail maintained in workzone research artifacts (available for inspection)

Exit criteria:
- [ ] Umbrella JIRA exists
- [ ] AI disclosure approach is acknowledged (not necessarily formally voted — lazy consensus is sufficient for routine process)
- [ ] At least one committer has agreed to review docs PRs
- [ ] Build stack compatibility validated — workzone content renders correctly with upstream stack (or upstream upgraded)

---

### Step 1: Test PR (2-3 pages)

**Goal**: Validate the contribution mechanics end-to-end with a deliberately small PR.

Pick 2-3 minor-update pages that are low-controversy and already draft-complete:
- `cassandra/pages/managing/operating/compaction/overview.adoc`
- `cassandra/pages/managing/operating/auto_repair.adoc`
- `cassandra/pages/troubleshooting/use_nodetool.adoc`

Actions:
1. Create JIRA subtask under the umbrella: "Minor docs updates: compaction overview, auto repair, nodetool troubleshooting"
2. Branch off `trunk` in `apache/cassandra`
3. Copy pages from workzone `content/modules/cassandra/pages/` to branch `doc/modules/cassandra/pages/` at the same relative path
4. Strip workzone-only markers (remove "Preview | Unofficial" admonitions, fix workzone-specific xrefs)
5. Verify local Antora build via `cassandra-website`
6. Open PR with AI disclosure in the description and commit message
7. Iterate on review feedback — this PR establishes the pattern for everything that follows

Exit criteria:
- [ ] PR merged (or concrete feedback on what to change in the process)
- [ ] AI disclosure format accepted or adjusted per reviewer feedback
- [ ] Build verification approach confirmed

---

### Stage 2: Minor-Update Pages

**Goal**: Land all remaining minor-update authored pages. These are small diffs — clarifications, small additions, no behavioral changes.

**28 pages** in this stage (not-started: 28, draft-complete: 11 — some overlap with Step 1 test pages):

| Group | Pages | Slice |
|-------|-------|-------|
| Architecture | `accord-architecture.adoc`, `accord.adoc`, `cql-on-accord.adoc`, `index.adoc` | ops-release-critical |
| CQL | `changes.adoc`, `definitions.adoc`, `index.adoc`, `triggers.adoc`, `types.adoc`, `constraints.adoc`, `sai/operations/monitoring.adoc`, `sai/sai-read-write-paths.adoc` | dev-standard / dev-deferred |
| Developing index | `developing/index.adoc` | dev-deferred |
| Getting started | `drivers.adoc`, `mtlsauthenticators.adoc` | dev-deferred / ops-critical |
| Installing | `installing.adoc` | ops-standard |
| Integrating | `plugins/index.adoc` | ops-deferred |
| Operations | `async-profiler.adoc`, `audit_logging.adoc`, `auditlogging.adoc`, `bulk_loading.adoc`, `fqllogging.adoc`, `hints.adoc`, `onboarding-to-accord.adoc`, `repair.adoc`, `role_name_generation.adoc`, `password_validation.adoc`, `compaction/ucs.adoc`, `index.adoc` | ops-standard / ops-critical |
| Tools | `cqlsh.adoc`, `sstabledump.adoc`, `sstableloader.adoc`, `sstableexpiredblockers.adoc`, `sstablescrub.adoc` | ops-deferred / dev-deferred |
| Reference | `commands-toc.adoc`, `compact-subproperties.adoc` | ref-standard |
| Troubleshooting | `use_nodetool.adoc` | ops-standard |

JIRA approach: 3-4 subtask JIRAs grouped by topic area:
- "Minor CQL and developer docs updates for Cassandra 6"
- "Minor operator and operations docs updates for Cassandra 6"
- "Minor tools and reference docs updates for Cassandra 6"

PR approach: One PR per JIRA subtask (aim for 8-12 pages per PR, reviewable in one sitting).

Exit criteria:
- [ ] All minor-update authored pages are merged to trunk
- [ ] No regressions in Antora build

---

### Stage 3: Draft-Complete Major-Update Pages

**Goal**: Land the substantial rewrites that are already drafted and internally reviewed.

**13 authored pages** (excludes pages with `publish_blocker=yes`):

| Group | Pages | Slice |
|-------|-------|-------|
| CQL syntax | `functions.adoc` | dev-standard |
| CQL security | `security.adoc` | dev-release-critical |
| SAI indexing | `sai-concepts.adoc`, `sai-faq.adoc`, `collections.adoc`, `_collections-list.adoc`, `_collections-map.adoc`, `_collections-set.adoc` | dev-standard |
| Operations | `backups.adoc`, `compression.adoc`, `virtualtables.adoc` | ops-standard |

**Blocked pages** (publish_blocker=yes, need maintainer decisions first):
- `ddl.adoc` — blocked on constraints and schema annotations scope
- `dml.adoc` — blocked on multiple feature interactions (TTL, NOT operators, BETWEEN, CAS)

JIRA approach: Slice-level JIRAs:
- "SAI indexing documentation updates for Cassandra 6"
- "CQL syntax and security documentation updates for Cassandra 6"
- "Operator operations documentation updates for Cassandra 6"

PR approach: One PR per JIRA subtask. These carry larger diffs and need technical-owner review.

Exit criteria:
- [ ] All non-blocked draft-complete major-update pages merged
- [ ] Technical review completed for each slice
- [ ] Blocked pages tracked in their respective JIRAs with clear unblock criteria

---

### Stage 4: Not-Yet-Drafted Major-Update Pages

**Goal**: Draft and land the remaining major-update pages.

**19 authored pages** that need drafting work before they can move:

| Group | Pages | Notes |
|-------|-------|-------|
| Architecture | `dynamo.adoc` | Snitch deprecation — significant rewrite |
| CQL | `SASI.adoc`, `collections/list.adoc`, `collections/map.adoc`, `collections/set.adoc` | LIKE expressions, frozen collection indexing |
| CQL (blocked) | `cql_singlefile.adoc` | publish_blocker=yes, multiple features |
| Getting started | `production.adoc` | JDK 21, config changes |
| Configuration | `configuration.adoc`, `cass_env_sh_file.adoc`, `cass_jvm_options_file.adoc`, `cass_logback_xml_file.adoc`, `cass_rackdc_file.adoc`, `cass_topo_file.adoc` | 6 config files, snitch removal |
| Operations | `security.adoc` (blocked), `snitch.adoc`, `metrics.adoc`, `compaction/tombstones.adoc` | |
| What's new | `new/index.adoc` | Release notes page |
| Reference | `sai-virtual-table-indexes.adoc` | |

Prerequisite: Draft each page in the workzone first using `cassandra-asciidoc-authoring` skill, validated against change-catalog research.

JIRA approach: Slice-level JIRAs by topic. Configuration pages should be one JIRA given their interdependency.

Exit criteria:
- [ ] All non-blocked major-update pages drafted, reviewed, and merged
- [ ] Blocked pages unblocked or explicitly deferred to next cycle

---

### Stage 5: New Pages

**Goal**: Land net-new pages that don't exist on cassandra-5.0.

**6 known new pages:**

| Page | Draft Status | Blocker |
|------|-------------|---------|
| `developing/cql/txn-reference.adoc` | draft-complete | publish_blocker=yes (Accord syntax) |
| `managing/operating/cluster-metadata.adoc` | not-started | publish_blocker=yes |
| `managing/operating/guardrails.adoc` | not-started | publish_blocker=yes |
| `managing/operating/startup-checks-spi.adoc` | not-started | publish_blocker=yes |
| `managing/tools/nodetool/altertopology.adoc` | not-started | publish_blocker=yes |
| `reference/cql-commands/list-superusers.adoc` | not-started | publish_blocker=yes |

Note: All 6 have `publish_blocker=yes`. These need maintainer decisions on scope and correctness before they can land.

Additional new pages from the workzone audience modules (vector search, TCM operational content) require the **structure track** to resolve first — they don't have natural homes in the current `doc/modules/cassandra/pages/` hierarchy without proposing new locations.

JIRA approach: One JIRA per new page with proposed path and rationale.

Exit criteria:
- [ ] Publish blockers resolved for each page
- [ ] Pages merged with individual technical review

---

### Stage 6: Generated Surfaces (Separate Track)

**Goal**: Ensure generated reference docs are correct for Cassandra 6.

**3 generated entries:**
- `managing/configuration/cass_yaml_file.adoc` — generated from `conf/cassandra.yaml`
- `managing/tools/nodetool/*.adoc` — generated via `doc/scripts/gen-nodetool-docs.py`
- `reference/native-protocol.adoc` — generated via `doc/scripts/process-native-protocol-specs-in-docker.sh`

These are NOT authored content. Migration means verifying and updating the generation scripts, not copying files.

Actions:
1. Run `ant gen-asciidoc` on trunk and diff the output against current generated pages
2. Identify any new settings, commands, or protocol changes not covered by existing scripts
3. Fix generation scripts if needed
4. Submit script fixes as a separate JIRA/PR from authored content

Exit criteria:
- [ ] Generation scripts produce correct output for trunk
- [ ] Generated output committed to trunk via normal build process

---

### Structure Track: IA Proposal (Parallel)

**Goal**: Get community input on the audience-split information architecture before proposing structural changes.

This runs in parallel with the content stages above. It does NOT block Stages 1-4.

Actions:
1. Post to dev@cassandra proposing the audience-first IA (Operators, Developers, Contributors, Reference)
2. Include concrete examples of what changes and why
3. Invite feedback and alternative proposals
4. Reach consensus before implementing any structural changes
5. If accepted, create a JIRA for the restructure and implement as a separate PR track

This is the "separate discussion thread" the community feedback requested.

---

## Per-PR Checklist

For every PR submitted upstream:

- [ ] JIRA subtask exists and is linked
- [ ] Pages copied from `content/modules/cassandra/pages/` to `doc/modules/cassandra/pages/` at same relative path
- [ ] Workzone-only markers removed ("Preview | Unofficial" admonitions)
- [ ] Workzone-specific xrefs adjusted to upstream paths
- [ ] Local Antora build verified via `cassandra-website`
- [ ] Commit message includes `AI-assisted: Claude (Anthropic)` if applicable
- [ ] PR description includes source provenance statement
- [ ] Nav file (`nav.adoc`) updated if new pages are added

## Blockers Summary

| Blocker | Affects | Resolution Path |
|---------|---------|-----------------|
| **Antora version mismatch (3.1.14 vs 2.3)** | **All stages** | **Validate content against Antora 2.3 or upgrade cassandra-website — Step 0** |
| **Missing AsciiDoc extensions in workzone** | **All stages** | **Add tabs-block.js and openblock to playbook — Step 0** |
| No umbrella JIRA | All stages | Create in Step 0 |
| No committer sponsor | All stages | Identify in Step 0 |
| AI disclosure not community-accepted | All stages | Settle in Step 0, test in Step 1 |
| 10 pages with publish_blocker=yes | Stages 3-5 | Maintainer decisions per page |
| Audience-first IA not decided | Stage 5 (audience-module pages only) | Structure track |
| ~90 tail-triage JIRAs unresearched | Completeness | Doesn't block early stages |
| `cassandra-6.0` branch doesn't exist | Timing | Land on trunk for now; pages carry forward when branch is cut |

## Related Documents

- `inventory/docs-map.csv` — page-level tracker with dispositions and draft status
- `content/IMPORT-MANIFEST.md` — lists all 71 imported pages with path mapping
- `backlog/execution-readiness.md` — workzone execution phases and blockers
- `runbooks/governance-review-and-staging.md` — JIRA, review, and merge process
- `llm/review-gates.md` — review gates for AI-assisted content
- `llm/source-pack-policy.md` — source provenance rules
