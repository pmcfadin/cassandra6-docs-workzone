# Cassandra 6 Docs Workzone — Implementation Task List

Capture date: **2026-03-26**

## How To Use This Document

Each task has a unique ID, a skill assignment, dependencies, and testable acceptance criteria. Agents should pick up tasks only when all listed dependencies are satisfied. Tasks within the same phase are parallelizable unless dependencies indicate otherwise.

### Skill Key

| Skill | Purpose |
|---|---|
| `cassandra-doc` | General docs work, repo selection, review gates |
| `cassandra-changelog-triage` | Discover changes from NEWS.txt/CHANGES.txt, triage, delegate |
| `cassandra-researcher` | Research specific JIRA, produce change-catalog entry |
| `cassandra-delta-catalog` | Compare docs between cassandra-5.0 and trunk |
| `cassandra-inventory-reconciliation` | Merge catalogs into docs-map.csv, assign dispositions |
| `cassandra-asciidoc-authoring` | Draft AsciiDoc with Antora structure |
| `cassandra-antora-preview` | Build, preview, validate, publish docs |

### Task Fields

- **Problem:** What needs to happen and why
- **Sources:** Where to get information (specific files, repos, branches)
- **Acceptance:** Concrete, testable outcomes that define "done"
- **Skill:** Which Claude skill to invoke
- **Depends on:** Task IDs that must complete first
- **Complexity:** Small / Medium / Large

---

## Phase 1: Complete Inventory and Reconciliation

**Goal:** Finish Epic 2. Expand `docs-map.csv` from 37 entries to full page coverage, reconcile with both research catalogs, assign dispositions and writing slices.

**Why first:** The inventory is the bridge from research into authoring. No content drafting should start until every page has a disposition, evidence reference, and writing-slice assignment.

---

### P1-T1: Enumerate all trunk doc pages

**Problem:** `inventory/docs-map.csv` currently has only 37 entries covering page areas, not individual pages. The trunk doc tree under `doc/modules/cassandra/pages/` contains substantially more pages (the delta catalog reports 28 pages in managing/operating alone on 5.0, 33 on trunk, plus 65-66 in developing/cql, 14 in data-modeling, etc.). Every `.adoc` page must have a row before drafting can start.

**Sources:**
- `apache/cassandra` repo, branch `trunk`, path `doc/modules/cassandra/pages/` — run `git ls-tree -r --name-only origin/trunk -- doc/modules/cassandra/pages`
- `apache/cassandra` repo, branch `trunk`, path `doc/modules/ROOT/pages/`
- Existing `inventory/docs-map.csv`
- Delta catalog index at `research/delta-catalog/index.md` (for page counts per area)

**Acceptance:**
- Every `.adoc` file under `doc/modules/cassandra/pages/` and `doc/modules/ROOT/pages/` on trunk has exactly one row in `docs-map.csv`
- The `source_type` column correctly distinguishes `authored` from `generated` for every row (use `inventory/generated-vs-authored.md` as guide)
- Row count matches `git ls-tree` output count
- No duplicate rows

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** None
**Complexity:** Medium

---

### P1-T2: Identify pages removed between 5.0 and trunk

**Problem:** Some pages were removed between 5.0 and trunk (delta catalog notes cloud snitches removed, crypto providers removed). These need `remove` dispositions in the inventory so they are not accidentally carried forward.

**Sources:**
- `apache/cassandra` repo, branch `cassandra-5.0`, path `doc/modules/cassandra/pages/`
- `git diff --name-status origin/cassandra-5.0..origin/trunk -- doc/modules/cassandra/pages/`
- Delta catalog area reports, especially `research/delta-catalog/managing-operating.md` (snitch removals, crypto provider removal)

**Acceptance:**
- Every page present on `cassandra-5.0` but absent from trunk is listed with disposition `remove` and a note citing the delta catalog evidence
- No 5.0-only pages are silently omitted

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** P1-T1
**Complexity:** Small

---

### P1-T3: Reconcile change-catalog into docs-map dispositions

**Problem:** The change catalog has 39 research files covering 81 JIRAs, each with a docs-impact classification and affected-pages list. These must be merged into `docs-map.csv` so each page gets its correct disposition (`minor-update`, `major-update`, `new`, `generated-review`, etc.) driven by product-change evidence, not just doc-diff.

**Sources:**
- `research/change-catalog/index.md` (tracker table with affected docs per JIRA)
- All 39 research files under `research/change-catalog/`
- `research/change-catalog/CHANGES-tail-triage.md` (90 likely-doc-worthy JIRAs that may affect additional pages)

**Acceptance:**
- Every page listed in the "Affected docs" column of the change-catalog index has a disposition in `docs-map.csv` that reflects the change-catalog finding
- Pages affected by multiple changes get the highest-impact disposition
- The 90 likely-doc-worthy tail-triage JIRAs are checked for pages not yet covered; any new pages are added
- An `evidence_refs` entry links to the relevant change-catalog file for each updated disposition

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** P1-T1
**Complexity:** Large

---

### P1-T4: Reconcile delta-catalog into docs-map dispositions

**Problem:** The delta catalog has 17 area reports comparing cassandra-5.0 to trunk. These contain page-level findings (new pages, major updates, minor updates, generated surfaces) that must be merged into `docs-map.csv`. Some pages may already have dispositions from P1-T3; this task ensures delta-catalog evidence is layered in.

**Sources:**
- `research/delta-catalog/index.md`
- All 17 area reports under `research/delta-catalog/`

**Acceptance:**
- Every page-level finding in the delta-catalog area reports is reflected in `docs-map.csv`
- Where delta-catalog and change-catalog disagree, the higher-impact disposition wins and both evidence refs are preserved
- Generated surfaces flagged in the delta catalog have `source_type=generated` and `publish_blocker=regen-required`

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** P1-T1, P1-T3 (to avoid overwriting change-catalog dispositions)
**Complexity:** Medium

---

### P1-T5: Research remaining high-priority tail-triage JIRAs

**Problem:** The tail triage identifies 90 likely-doc-worthy JIRAs not yet covered by the 39 existing research files. The most impactful categories — new CQL syntax (BETWEEN, NOT, LIKE, LIST SUPERUSERS), new virtual tables (slow_queries, uncaught_exceptions, partition_key_statistics), new nodetool options, and configuration/security changes — need research files so their docs impact feeds the inventory.

**Sources:**
- `research/change-catalog/CHANGES-tail-triage.md` (the 90 likely-doc-worthy items)
- `apache/cassandra` repo, branch `trunk` (for code, config, tests, docs validation per JIRA)
- Research file template visible in existing files under `research/change-catalog/`

**Acceptance:**
- At minimum, the "High Priority" categories from the tail triage (New CQL Syntax, New Virtual Tables, New Nodetool Options, Configuration/Security/Operations, Upgrade/Behavior Changes) each have research files or explicit triage-out rationale
- Each new research file follows the existing template format
- The change-catalog index (`research/change-catalog/index.md`) is updated with new entries

**Skill:** `cassandra-researcher` (per JIRA), coordinated by `cassandra-changelog-triage`
**Depends on:** None (can run in parallel with P1-T1 through P1-T4)
**Complexity:** Large

---

### P1-T6: Assign writing-slice groupings to all docs-map rows

**Problem:** Once dispositions are assigned, pages must be grouped into writing slices by audience and area (operators, developers, generated, reference) so that Phase 4 and Phase 5 content work can be planned and parallelized. The workzone spec and execution-readiness doc both require that operator-critical and release-critical content be prioritized first.

**Sources:**
- Completed `docs-map.csv` from P1-T1 through P1-T4
- `backlog/ownership-map.md` (reviewer matrix)
- `backlog/execution-readiness.md` (phase ordering)
- Change-catalog critical doc gaps list from `research/change-catalog/index.md`

**Acceptance:**
- Every non-`unchanged` row in `docs-map.csv` is assigned to a named writing slice
- Writing slices are tagged with audience (`operators`, `developers`, `contributors`, `reference`)
- Priority is assigned: `release-critical`, `operator-critical`, `standard`, `deferred`
- Generated surfaces are in their own slice, separate from authored content

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** P1-T3, P1-T4
**Complexity:** Medium

---

## Phase 2: Build Infrastructure

**Goal:** Create the Antora scaffolding, playbook, and build scripts so that draft content can be rendered locally from the workzone repo.

**Can start immediately** — no Phase 1 dependency.

---

### P2-T1: Create Antora component descriptor

**Problem:** The workzone needs an `antora.yml` component descriptor so Antora can treat it as a content source. This must define the component name (something like `cassandra-6-draft` to avoid collision with the real `cassandra` component), version, and module structure. The workzone spec (lines 127-149) specifies that draft content should live in a `drafts/` or `content/` directory with Antora-compatible structure.

**Sources:**
- `docs/workzone-spec.md` (recommended repo structure, lines 127-149; authoring model, lines 65-72)
- `apache/cassandra` repo, `trunk`, `doc/antora.yml` (reference component structure)
- Antora component descriptor documentation

**Acceptance:**
- An `antora.yml` file exists at the root of the draft content directory
- Component name clearly distinguishes this as draft/workzone content (not official)
- Module structure supports the audience-first IA: modules for `operators`, `developers`, `contributors`, `reference` at minimum
- The descriptor is valid Antora YAML

**Skill:** `cassandra-antora-preview`
**Depends on:** None
**Complexity:** Small

---

### P2-T2: Create Antora module directory structure

**Problem:** Draft AsciiDoc content needs a directory structure that Antora can consume. Per the workzone spec's IA direction (lines 103-115), the top-level audiences are Operators, Developers, Contributors, and Reference. Each module needs `pages/`, `partials/`, and `nav.adoc`. This structure should mirror what will eventually exist in `apache/cassandra/doc/` so migration cost is minimized.

**Sources:**
- `docs/workzone-spec.md` (IA direction, migration principle)
- `apache/cassandra` repo, `trunk`, `doc/modules/` (current module structure for reference)
- Delta catalog nav-partials report at `research/delta-catalog/nav-partials.md`

**Acceptance:**
- Directory tree exists under `content/` (or `drafts/`) with Antora module structure
- At least four modules: `operators`, `developers`, `contributors`, `reference`
- Each module has `pages/` and a `nav.adoc` file
- A ROOT module exists with an index page clearly labeled as unofficial/preview
- The structure passes Antora validation

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T1
**Complexity:** Medium

---

### P2-T3: Create Antora playbook for local build

**Problem:** The workzone needs a playbook YAML file that Antora can use to render the draft content locally. This playbook should reference the local workzone content source. The workzone spec (lines 607-616) requires the build to render the proposed IA, draft pages, and nav/cross-links.

**Sources:**
- `runbooks/build-preview-publish.md` (current build path reference)
- `docs/workzone-spec.md` (build expectations, lines 607-616; preview expectations, lines 619-629)
- `apache/cassandra-website` repo, `trunk`, `site-content/site.template.yaml` (reference playbook structure)

**Acceptance:**
- A playbook YAML file exists (e.g., `antora-playbook.yml`) at the workzone repo root
- It references the local content source created in P2-T2
- `npx antora antora-playbook.yml` produces HTML output in a `build/` directory
- The output site is clearly labeled as "Preview / Unofficial / For review only" per the workzone spec
- The playbook includes a default UI bundle

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T1, P2-T2
**Complexity:** Medium

---

### P2-T4: Create build script wrapper

**Problem:** Agents and contributors need a single-command entry point for building, previewing, and validating the workzone site. This wraps Antora CLI and handles dependency checks.

**Sources:**
- `runbooks/build-preview-publish.md`
- `docs/workzone-spec.md` (build expectations)

**Acceptance:**
- A `build.sh` script exists at the repo root
- `./build.sh build` runs `npx antora` with the playbook and produces output
- `./build.sh preview` starts a local HTTP server on the build output
- `./build.sh clean` removes build artifacts
- The script checks for Node.js and Antora availability and prints clear errors if missing
- The script exits non-zero on build failure

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3
**Complexity:** Small

---

### P2-T5: Add .nojekyll and GitHub Pages static publishing config

**Problem:** The workzone spec requires publishing to GitHub Pages with Jekyll bypassed. The `.nojekyll` file and publication strategy (branch or Actions) should be set up before the preview pipeline is built.

**Sources:**
- `docs/workzone-spec.md` (preview model, lines 75-88)
- GitHub Pages documentation for static site publishing

**Acceptance:**
- A `.nojekyll` file exists in the build output directory or is created by the build script
- A decision is documented on whether to use `gh-pages` branch or GitHub Actions for publishing
- The preview site banner text is defined: "Preview | Unofficial | For review only"

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3
**Complexity:** Small

---

## Phase 3: Preview Pipeline

**Goal:** Automate the build-and-publish cycle so that every push to the workzone repo produces a rendered preview on GitHub Pages.

---

### P3-T1: Create GitHub Actions workflow for Antora build

**Problem:** The workzone needs automated builds so reviewers can see rendered output without running local builds. A GitHub Actions workflow should install Antora, run the playbook, and produce the static site as an artifact.

**Sources:**
- Playbook from P2-T3
- Build script from P2-T4
- `docs/workzone-spec.md` (preview model)
- `llm/review-gates.md` (Gate 5: Render Approval)

**Acceptance:**
- A `.github/workflows/build-preview.yml` file exists
- The workflow triggers on push to `main` (or the primary branch)
- The workflow installs Node.js and Antora, runs the playbook, and uploads the build output as an artifact
- Build failures cause the workflow to fail with a clear error
- The workflow completes in under 5 minutes for a minimal site

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3, P2-T4
**Complexity:** Medium

---

### P3-T2: Add GitHub Pages deployment step

**Problem:** The built static site must be published to GitHub Pages so maintainers and reviewers can access the preview at a stable URL without local setup.

**Sources:**
- GitHub Actions `actions/deploy-pages` documentation
- `docs/workzone-spec.md` (official publish boundary, lines 92-101)

**Acceptance:**
- The GitHub Actions workflow deploys the Antora build output to GitHub Pages
- The preview site is accessible at the repo's GitHub Pages URL
- The site includes the `.nojekyll` marker
- The preview banner ("Preview | Unofficial | For review only") is visible on every page
- Deployment only happens on the primary branch (not on PRs)

**Skill:** `cassandra-antora-preview`
**Depends on:** P3-T1, P2-T5
**Complexity:** Small

---

### P3-T3: Add PR preview validation check

**Problem:** Pull requests adding or modifying AsciiDoc content should be validated: the Antora build must succeed and produce valid output. This catches broken xrefs, missing includes, and invalid AsciiDoc before merge.

**Sources:**
- `llm/review-gates.md` (Gate 5: nav, xrefs, tabs, admonitions render correctly)

**Acceptance:**
- The CI workflow runs on pull requests targeting the primary branch
- It builds the Antora site and reports success/failure
- It does not deploy to GitHub Pages on PRs
- Build output is available as a downloadable artifact for PR reviewers

**Skill:** `cassandra-antora-preview`
**Depends on:** P3-T1
**Complexity:** Small

---

## Phase 4: Priority Content Drafting

**Goal:** Draft the highest-priority content slices — operator-critical and release-critical pages — using the research catalog as input. These are pages that either have no docs at all or need major rewrites.

**Prerequisite:** Phase 1 must be complete (inventory reconciled, writing slices assigned). Phase 2 must be complete enough to render drafts (P2-T1 through P2-T3 at minimum).

---

### P4-T1: Draft TCM / Cluster Metadata content

**Problem:** TCM (CEP-21) is the most significant Cassandra 6 architectural change. The change catalog identifies it as needing new pages. There are no TCM docs in the current trunk doc tree. The workzone already has 12 TCM chapter drafts under `tcm/` that can serve as source material, but they must be converted to Antora-compatible AsciiDoc and placed in the correct module.

**Sources:**
- `tcm/` (12 chapter drafts: 01 through 11 plus glossary)
- `research/change-catalog/CASSANDRA-18330-cluster-metadata.md`
- `apache/cassandra` repo, `trunk` (implementation: `src/java/org/apache/cassandra/tcm/`, virtual tables, nodetool cms commands)
- `llm/source-pack-policy.md`

**Acceptance:**
- AsciiDoc pages exist in the `operators` module covering: what TCM is, pre-upgrade assessment, enabling CMS, post-enable validation, operational behavior changes, failure playbooks
- Every normative claim cites repo evidence
- Pages render in the Antora preview build
- Nav entry exists in the operators module `nav.adoc`
- Content is clearly marked as draft

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Large

---

### P4-T2: Draft guardrails reference page

**Problem:** No guardrails documentation page exists anywhere, yet 4+ research files (CASSANDRA-18781, CASSANDRA-20913, CASSANDRA-21024, CASSANDRA-19677) document new guardrail settings. Combined, these represent 12+ new YAML settings for bulk loading, durable writes, keyspace properties, disk usage, and per-type max sizes. Operators need a central reference.

**Sources:**
- `research/change-catalog/CASSANDRA-18781-bulk-loading-guardrail.md`
- `research/change-catalog/CASSANDRA-20913-durable-writes-guardrail.md`
- `research/change-catalog/CASSANDRA-21024-disk-usage-guardrails.md`
- `research/change-catalog/CASSANDRA-19677-per-type-max-size.md`
- `apache/cassandra` repo, `trunk`, `conf/cassandra.yaml` (guardrail settings)
- `apache/cassandra` repo, `trunk`, `src/java/org/apache/cassandra/config/GuardrailsOptions.java`

**Acceptance:**
- An AsciiDoc page exists in the `operators` module for guardrails
- All guardrail settings identified in the four research files are documented with name, default, type, and operational meaning
- Page cites `cassandra.yaml` and implementation code
- Page renders in preview build

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Medium

---

### P4-T3: Draft snitch deprecation and topology changes

**Problem:** Two related changes require major snitch documentation updates: CASSANDRA-19488 (IEndpointSnitch to Locator deprecation, 4 new YAML settings, cloud snitch removals) and CASSANDRA-20528 (nodetool altertopology for live DC/rack changes, zero docs). The delta catalog confirms snitch.adoc lost 82 lines of cloud snitch content. This is operator-critical upgrade content.

**Sources:**
- `research/change-catalog/CASSANDRA-19488-snitch-deprecation.md`
- `research/change-catalog/CASSANDRA-20528-topology-dc-rack.md`
- `research/delta-catalog/managing-operating.md` (snitch section)
- `apache/cassandra` repo, `trunk`, `doc/modules/cassandra/pages/managing/operating/snitch.adoc`

**Acceptance:**
- Updated snitch documentation reflects the Locator deprecation, removed cloud snitches, and new YAML settings
- A page or section documents `nodetool altertopology` with command syntax, flags, and operational guidance
- Upgrade notes cover what operators must change when migrating from 5.0 snitch configuration
- All claims cite trunk source

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Medium

---

### P4-T4: Draft JMX and security updates

**Problem:** Two research files identify major security doc changes: CASSANDRA-11695 (JMX configuration moving from system properties to cassandra.yaml) and CASSANDRA-19397 (native_transport_port_ssl removal, a breaking change). The delta catalog confirms security.adoc gained 204 lines and lost 90. This is operator-critical because misconfiguring JMX or SSL during upgrade could cause outages.

**Sources:**
- `research/change-catalog/CASSANDRA-11695-jmx-server-options.md`
- `research/change-catalog/CASSANDRA-19397-native-transport-ssl.md`
- `research/delta-catalog/managing-operating.md` (security section)
- `apache/cassandra` repo, `trunk`, `doc/modules/cassandra/pages/managing/operating/security.adoc`

**Acceptance:**
- Security documentation covers the new JMX-in-YAML configuration surface
- The native_transport_port_ssl removal is documented with upgrade migration steps
- PEM private key password-via-file examples are included
- Removed crypto provider content is noted
- All claims cite trunk source evidence

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Medium

---

### P4-T5: Draft JDK 21 and JVM options content

**Problem:** CASSANDRA-18831 introduces JDK 21 as the default runtime with Generational ZGC as the default GC. The research file notes a new `jvm21-server.options` file and identifies a doc gap around JVM options. This is operator-critical because GC configuration directly affects production performance.

**Sources:**
- `research/change-catalog/CASSANDRA-18831-jdk21-zgc.md`
- `apache/cassandra` repo, `trunk`, `conf/jvm*-server.options`
- `apache/cassandra` repo, `trunk`, `doc/modules/cassandra/pages/managing/configuration/cass_jvm_options_file.adoc`

**Acceptance:**
- JVM options documentation covers JDK 21 as default
- Generational ZGC default is documented with operational implications
- The `jvm21-server.options` file is referenced
- Upgrade guidance covers transitioning from JDK 11/17 GC settings

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Small

---

### P4-T6: Draft startup checks SPI page

**Problem:** CASSANDRA-21093 introduces an SPI for custom startup checks with YAML configuration. The change catalog marks this as needing a new page with zero existing documentation.

**Sources:**
- `research/change-catalog/CASSANDRA-21093-startup-checks-spi.md`
- `apache/cassandra` repo, `trunk` (SPI interface classes, YAML config)

**Acceptance:**
- An AsciiDoc page exists documenting the startup checks SPI
- Page covers: SPI interface, YAML configuration, how to implement a custom check, default behavior
- Page is placed in the `operators` module
- All claims cite source code evidence

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T3, P2-T2
**Complexity:** Small

---

## Phase 5: Full Content Production

**Goal:** Draft remaining content slices covering developer content, additional operator content, and review existing trunk docs that need minor updates.

---

### P5-T1: Draft Accord CQL transaction reference

**Problem:** BEGIN TRANSACTION syntax is undocumented. While 4 Accord-related pages exist on trunk (accord.adoc, accord-architecture.adoc, cql-on-accord.adoc, onboarding-to-accord.adoc), there is no CQL-level reference for the transaction statement syntax. This is developer-critical content.

**Sources:**
- `research/change-catalog/CASSANDRA-17092-accord.md`
- `apache/cassandra` repo, `trunk`, CQL parser files, Accord statement classes
- `apache/cassandra` repo, `trunk`, `doc/modules/cassandra/pages/architecture/cql-on-accord.adoc` (existing partial content)
- Tail triage: CASSANDRA-20857 (BEGIN TRANSACTION), CASSANDRA-20883 (binary protocol conditions)

**Acceptance:**
- AsciiDoc page documents BEGIN TRANSACTION syntax with BNF-style grammar
- Covers: supported statement types within transactions, consistency semantics, restrictions, error conditions
- Cross-references the existing Accord architecture and onboarding pages
- Placed in `developers` module

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T6, P2-T2
**Complexity:** Large

---

### P5-T2: Update CQL documentation for new syntax

**Problem:** Multiple new CQL syntax additions need documentation: BETWEEN operator (CASSANDRA-19604), NOT operators with three-valued logic (CASSANDRA-18584), LIKE expressions (CASSANDRA-17198), CREATE TABLE LIKE (CASSANDRA-19964, marked major-update), and LIST SUPERUSERS (CASSANDRA-19417). The delta catalog notes developing/cql has 4 major-update pages.

**Sources:**
- `research/change-catalog/CASSANDRA-19964-create-table-like.md`
- `research/change-catalog/CHANGES-tail-triage.md` (New CQL Syntax section)
- `research/delta-catalog/developing-cql.md`
- `apache/cassandra` repo, `trunk`, CQL grammar files, statement implementations

**Acceptance:**
- Each new CQL syntax has at minimum a section in the relevant CQL reference page with syntax, examples, restrictions
- CREATE TABLE LIKE has a full section in ddl.adoc or a standalone page
- LIST SUPERUSERS is documented in the security/auth reference
- All syntax examples are validated against parser/grammar on trunk

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T5 (research on tail-triage CQL JIRAs), P1-T6, P2-T2
**Complexity:** Large

---

### P5-T3: Update SAI documentation for frozen collections

**Problem:** CASSANDRA-18492 adds SAI indexing for frozen collections. The research file identifies 6 affected pages with no existing documentation for frozen collection element indexing.

**Sources:**
- `research/change-catalog/CASSANDRA-18492-sai-frozen-collections.md`
- `apache/cassandra` repo, `trunk`, SAI collection indexing code and tests
- `apache/cassandra` repo, `trunk`, `doc/modules/cassandra/pages/developing/cql/indexing/sai/` pages

**Acceptance:**
- SAI collection pages document frozen collection indexing support
- Examples show CREATE INDEX on frozen collections
- Behavior differences from non-frozen collection indexing are noted
- sai-faq.adoc and sai-concepts.adoc updated as needed

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T6, P2-T2
**Complexity:** Medium

---

### P5-T4: Update compaction documentation

**Problem:** CASSANDRA-18802 adds `parallelize_output_shards` and `--jobs` flag for unified compaction, both undocumented. The tail triage also identifies CASSANDRA-21169 (override compaction strategy parameters at startup).

**Sources:**
- `research/change-catalog/CASSANDRA-18802-compaction-parallelization.md`
- `apache/cassandra` repo, `trunk`, UCS implementation and config

**Acceptance:**
- `parallelize_output_shards` documented with default, type, operational meaning
- `--jobs` flag documented in nodetool compact reference
- Updated content renders correctly

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T6, P2-T2
**Complexity:** Small

---

### P5-T5: Review and update existing trunk docs marked review-only

**Problem:** The change catalog identifies 7 research files with `review-only` next action, meaning docs exist on trunk but have minor gaps: auto repair (CASSANDRA-19918), constraints (CASSANDRA-19947), password validation (CASSANDRA-17457), string functions (CASSANDRA-20102), format functions (CASSANDRA-19546), index selection (CASSANDRA-18112), and async-profiler (CASSANDRA-20854).

**Sources:**
- The 7 research files listed above under `research/change-catalog/`
- Corresponding trunk doc pages

**Acceptance:**
- Each of the 7 identified pages is reviewed against its research file
- Minor gaps noted in the research files are fixed (e.g., UTF-8 vs UTF-16 terminology in string functions, typo in format functions example, missing char sets in password validation)
- Cross-references between related pages are added where noted
- Changes are tracked as minor updates

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T6, P2-T2
**Complexity:** Medium

---

### P5-T6: Draft new virtual tables and observability content

**Problem:** The tail triage identifies 14 new observability items: new virtual tables (slow_queries, uncaught_exceptions, partition_key_statistics), expanded metrics (auth cache, hints, bootstrap, streaming), and new nodetool observability options. These need documentation so operators know what is available.

**Sources:**
- `research/change-catalog/CHANGES-tail-triage.md` (New Virtual Tables / Observability section)
- P1-T5 research outputs for these JIRAs
- `apache/cassandra` repo, `trunk`, virtual table implementations, metrics classes

**Acceptance:**
- New virtual tables are documented with table name, columns, and purpose
- New metrics are listed with name, type, and operational meaning
- Content is placed in the `operators` module under an observability section
- Each entry cites its source implementation

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T5, P1-T6, P2-T2
**Complexity:** Large

---

### P5-T7: Update miscellaneous operator docs

**Problem:** Multiple change-catalog entries require updates to existing operator pages not covered by Phase 4: TTL 2106 updates (CASSANDRA-14227), ZSTD dictionary compression (CASSANDRA-17021), chronicle queue log rolling, snapshot MBean (CASSANDRA-18111), tpstats verbose (CASSANDRA-19289), auth mode in clients (CASSANDRA-19366), sstableexpiredblockers -H flag (CASSANDRA-20448), and direct I/O compaction (CASSANDRA-19987).

**Sources:**
- Corresponding research files under `research/change-catalog/`
- Trunk doc pages identified in each research file's "Affected docs" column

**Acceptance:**
- Each identified page is updated per the research file's findings
- TTL 2106: stale 2038 references removed, upgrade guidance added
- ZSTD dictionary: nodetool training commands and CQL configuration documented
- All updates cite source evidence
- Updated pages render in preview

**Skill:** `cassandra-asciidoc-authoring`
**Depends on:** P1-T6, P2-T2
**Complexity:** Medium

---

## Phase 5G: Generated Documentation

**Goal:** Regenerate and validate machine-derived reference surfaces. This is a **separate track** from authored content per the generated-vs-authored policy. Runs in parallel with Phase 5.

---

### P5G-T1: Regenerate and validate cassandra.yaml reference

**Problem:** Many new YAML settings (guardrails, JMX, snitch, startup checks, compaction, direct I/O, etc.) must appear in the generated YAML reference. The delta catalog marks this surface as `generated-needs-review` with `regen-required`. Regeneration must happen before any AI drafting of config-related content.

**Sources:**
- `inventory/generated-vs-authored.md`
- `apache/cassandra` repo, `trunk`, `doc/scripts/convert_yaml_to_adoc.py`
- `apache/cassandra` repo, `trunk`, `conf/cassandra.yaml`
- `runbooks/build-preview-publish.md` (generation commands)

**Acceptance:**
- `convert_yaml_to_adoc.py` runs successfully against trunk
- Generated output includes all new YAML settings identified in change-catalog research
- Output is committed or staged in the workzone for preview rendering
- A diff between 5.0-generated and trunk-generated output is captured for review

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3 (playbook must exist to render)
**Complexity:** Medium

---

### P5G-T2: Regenerate and validate nodetool reference

**Problem:** The picocli migration (CASSANDRA-17445) may affect nodetool doc formatting. Multiple new commands exist (altertopology, cms subcommands, compressiondictionary, history, profile subcommands). The change catalog identifies 5 items needing `regen-validate`. Regeneration must complete before any nodetool-related prose is finalized.

**Sources:**
- `apache/cassandra` repo, `trunk`, `doc/scripts/gen-nodetool-docs.py`
- `research/change-catalog/CASSANDRA-17445-nodetool-picocli.md`
- Change catalog entries for nodetool-related JIRAs

**Acceptance:**
- `gen-nodetool-docs.py` runs successfully against trunk
- Generated output includes all new nodetool commands and subcommands identified in research
- A diff between 5.0-generated and trunk-generated nodetool docs is captured
- New commands (altertopology, cms, compressiondictionary, history) appear in generated output

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3
**Complexity:** Medium

---

### P5G-T3: Regenerate and validate native protocol spec

**Problem:** The delta catalog marks `reference/native-protocol.adoc` as `generated-needs-review` with `regen-required`. The native protocol has Accord-related additions. Regeneration must use the Docker-based process documented in the runbook.

**Sources:**
- `apache/cassandra` repo, `trunk`, `doc/scripts/process-native-protocol-specs-in-docker.sh`
- `research/delta-catalog/reference.md`

**Acceptance:**
- Native protocol spec generation runs successfully against trunk
- Output reflects Cassandra 6 protocol changes
- Diff from 5.0 generation is captured for review

**Skill:** `cassandra-antora-preview`
**Depends on:** P2-T3
**Complexity:** Small

---

## Phase 6: Version Wire-Up Preparation

**Goal:** Prepare all changes needed to add Cassandra 6 to the versioned docs system. This phase produces implementation artifacts but does not execute against the upstream repos.

**Can start anytime** — independent of content phases.

---

### P6-T1: Prepare Cassandra-side version metadata patch

**Problem:** When `cassandra-6.0` is cut, `doc/antora.yml` must be updated with `version: '6.0'`, `display_version: '6.0'`, and prerelease flag management. The patch must be prepared so it can be submitted quickly when the branch exists.

**Sources:**
- `runbooks/cassandra6-version-wireup.md` (Required Cassandra 6 Changes, items 1-3)
- `apache/cassandra` repo, `trunk`, `doc/antora.yml`
- `apache/cassandra` repo, `cassandra-5.0`, `doc/antora.yml`

**Acceptance:**
- A documented patch (or diff) shows the exact `antora.yml` changes needed
- The patch addresses: version string, display version, prerelease flag
- The patch is validated against the Antora component descriptor spec
- A note documents when to apply (after `cassandra-6.0` branch cut)

**Skill:** `cassandra-doc`
**Depends on:** None
**Complexity:** Small

---

### P6-T2: Prepare website-side branch and alias changes

**Problem:** The wire-up runbook identifies three website-side files with hardcoded version metadata: the Dockerfile (branch list), docker-entrypoint.sh (alias logic), and site.template.yaml (major-version attributes). All three need coordinated changes when Cassandra 6 goes live.

**Sources:**
- `runbooks/cassandra6-version-wireup.md` (Required Cassandra 6 Changes, items 4-6)
- `apache/cassandra-website` repo, `trunk`, `site-content/Dockerfile`
- `apache/cassandra-website` repo, `trunk`, `site-content/docker-entrypoint.sh`
- `apache/cassandra-website` repo, `trunk`, `site-content/site.template.yaml`

**Acceptance:**
- A documented patch shows changes to all three files
- Branch list includes `cassandra-6.0`
- Alias logic makes `6.0` become `stable` and `latest`
- `site.template.yaml` attributes reflect 6.0 as the current version
- Patch includes a note about what `trunk` alias should become

**Skill:** `cassandra-doc`
**Depends on:** None
**Complexity:** Medium

---

### P6-T3: Create version wire-up validation checklist

**Problem:** The wire-up runbook describes acceptance checks but does not provide a step-by-step test procedure. Before wire-up is executed, there should be a checklist a maintainer can follow to validate that stable, latest, and trunk resolve correctly.

**Sources:**
- `runbooks/cassandra6-version-wireup.md` (Acceptance Checks section)
- `runbooks/build-preview-publish.md` (Checks Before Calling A Build Good)
- `llm/review-gates.md` (Gates 5, 6, 7)

**Acceptance:**
- A validation checklist document exists with numbered steps
- Each step has: what to check, expected result, how to check (command or URL)
- Covers: local render, version selector, alias resolution, staging, production
- Includes rollback guidance if validation fails

**Skill:** `cassandra-doc`
**Depends on:** P6-T1, P6-T2
**Complexity:** Small

---

### P6-T4: Prepare workzone branch-transition updates

**Problem:** Multiple workzone files reference `trunk` as the default branch with instructions to swap to `cassandra-6.0` when it exists. These files need coordinated updates: CLAUDE.md, source-pack-policy.md, docs-map.csv comparison_target, and README.

**Sources:**
- `CLAUDE.md` (line 11)
- `llm/source-pack-policy.md` (Branch Transition section)
- `runbooks/cassandra6-version-wireup.md` (Branch-Transition Rule)
- `inventory/docs-map.csv` (current_version and comparison_target columns)

**Acceptance:**
- A documented list of all files requiring `trunk` to `cassandra-6.0` substitution
- The substitution is described as a single coordinated commit
- No workflow redesign is introduced — only branch name changes
- A trigger condition is defined: "execute this when `cassandra-6.0` branch is publicly available in `apache/cassandra`"

**Skill:** `cassandra-doc`
**Depends on:** None
**Complexity:** Small

---

## Cross-Phase Governance Tasks

These tasks run continuously across all phases.

---

### GOV-T1: Maintain review gates compliance

**Problem:** The review gates document defines 7 gates from source-pack approval through post-publish check. Each phase transition should explicitly confirm that the relevant gates are satisfied before work proceeds.

**Sources:**
- `llm/review-gates.md`
- `backlog/ownership-map.md`

**Acceptance:**
- Gate 1 (source pack) confirmed before any research or drafting task starts
- Gate 2 (inventory) confirmed before Phase 4 starts
- Gate 3 (diff) confirmed per writing slice before drafting
- Gate 4 (draft) applied to every completed draft
- Gate 5 (render) applied after each content merge
- Gates 6-7 deferred to upstream migration

**Skill:** `cassandra-doc`
**Depends on:** None (continuous)
**Complexity:** Small (per gate check)

---

### GOV-T2: Track docs-map.csv status as work progresses

**Problem:** As drafts are produced in Phases 4 and 5, the `draft_status` column in `docs-map.csv` must be updated from `not-started` to `in-progress` to `draft-complete` to `reviewed`. This is the single source of truth for work progress.

**Sources:**
- `inventory/docs-map.csv`

**Acceptance:**
- Every page with active drafting work has `draft_status=in-progress`
- Every completed draft has `draft_status=draft-complete`
- Every reviewed draft has `draft_status=reviewed`
- No page is marked complete without passing Gate 4

**Skill:** `cassandra-inventory-reconciliation`
**Depends on:** P1-T6 (initial inventory must be complete)
**Complexity:** Small (ongoing)

---

## Task Dependency Graph

```
P1-T1 ───────────┬──→ P1-T2
                  ├──→ P1-T3 ──→ P1-T4 ──→ P1-T6
                  │              P1-T5 ──→ P1-T6
                  │
P2-T1 ──→ P2-T2 ──→ P2-T3 ──→ P2-T4
                      │          P2-T5
                      │
P2-T3, P2-T4 ──→ P3-T1 ──→ P3-T2
                  P3-T1 ──→ P3-T3
                      │
P1-T3, P2-T2 ──→ P4-T1 through P4-T6 (parallel)
                      │
P1-T6, P2-T2 ──→ P5-T1 through P5-T7 (parallel)
                      │
P2-T3 ──→ P5G-T1, P5G-T2, P5G-T3 (parallel)
                      │
P6-T1 through P6-T4 (parallel, can start anytime)
P6-T1, P6-T2 ──→ P6-T3
```

## Parallelization Guide

**Within each phase:**
- **Phase 1:** P1-T1 and P1-T5 run simultaneously. P1-T3 and P1-T4 can overlap after P1-T1.
- **Phase 2:** P2-T1 is the starting gate; P2-T4 and P2-T5 run in parallel after P2-T3.
- **Phase 3:** P3-T2 and P3-T3 run in parallel after P3-T1.
- **Phase 4:** All six tasks (P4-T1 through P4-T6) run in parallel once P1-T3 and P2-T2 are done.
- **Phase 5:** All seven tasks run in parallel. Phase 5G tasks run in parallel with Phase 5 authored tasks.
- **Phase 6:** All four tasks can start anytime. P6-T3 depends on P6-T1 and P6-T2.

**Cross-phase parallelism:**
- Phase 2 can start immediately (no Phase 1 dependency)
- Phase 3 starts as soon as Phase 2 core tasks (P2-T1 through P2-T3) complete
- Phase 5G starts as soon as P2-T3 completes (independent of Phase 1 or Phase 4)
- Phase 6 tasks are independent and can start anytime

## Task Count Summary

| Phase | Tasks | Skill Coverage |
|---|---|---|
| Phase 1: Inventory & Reconciliation | 6 | `cassandra-inventory-reconciliation`, `cassandra-researcher`, `cassandra-changelog-triage` |
| Phase 2: Build Infrastructure | 5 | `cassandra-antora-preview` |
| Phase 3: Preview Pipeline | 3 | `cassandra-antora-preview` |
| Phase 4: Priority Content | 6 | `cassandra-asciidoc-authoring` |
| Phase 5: Full Content | 7 | `cassandra-asciidoc-authoring` |
| Phase 5G: Generated Docs | 3 | `cassandra-antora-preview` |
| Phase 6: Version Wire-Up | 4 | `cassandra-doc` |
| Governance | 2 | `cassandra-doc`, `cassandra-inventory-reconciliation` |
| **Total** | **36** | **All 7 skills used** |
