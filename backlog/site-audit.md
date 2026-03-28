# Live Site Audit Report

**Audited**: 2026-03-28
**URL**: https://pmcfadin.github.io/cassandra6-docs-workzone/cassandra-6-draft/draft/index.html
**Method**: Playwright browser automation — navigated every module, checked rendering, counted unresolved xrefs, captured console errors/warnings
**Compared against**: `future/audience-information-architecture.md` (IA spec)

---

## Executive Summary

The IA reorganization is **working structurally** — all four audience modules render, navigation follows the spec's section hierarchy, and landing pages have real content with working links. However, the site is **not feature-complete for Cassandra 6** and has several categories of issues that need resolution before it can serve as a reference.

### What's Working

1. **Audience-first front door** — The homepage asks "What are you trying to do?" with four clear entry cards (Run Cassandra, Build with Cassandra, Contribute, Browse Reference). This matches the IA spec exactly.
2. **Left nav structure** — Operators shows Install > Configure > Operate > Secure > Upgrade > Tune > Backup > Observe > Troubleshoot sections. Developers shows Drivers > CQL (with SAI/Collections subsections) > Integration. Contributors shows Architecture. Reference shows Configuration > Nodetool > Tools > Protocol > CQL Commands > SAI.
3. **Quick Links** — Homepage has "What's new", "Upgrade to C6", "TCM", "Troubleshoot" quick links. All resolve correctly.
4. **Cross-module navigation** — Clicking between Operators, Developers, Contributors, Reference works. Breadcrumbs render correctly.
5. **TCM content** — All 5 TCM pages render fully under Operators > Upgrade. This is the deepest, most polished content on the site.
6. **Nodetool hub + subpages** — The 160 nodetool stubs render under Reference > Nodetool with correct include resolution from example text files.

### What's Broken or Missing

---

## Issue 1: 42 Unresolved Xrefs on CQL Commands Page

**Severity**: High (user-visible broken links)
**Page**: `reference/cql-commands/commands-toc.html`

42 CQL command links render as unstyled text (Antora `xref.unresolved` class) pointing to `#reference/cql-commands/alter-keyspace.adoc`, etc. These are pages that exist in the upstream `apache/cassandra/doc/` trunk but were never imported to the workzone because they're classified "unchanged."

**Examples**: ALTER KEYSPACE, ALTER TABLE, CREATE INDEX, CREATE TABLE, DROP TABLE, LIST SUPERUSERS, etc.

**Fix**: Either import the unchanged CQL command pages from trunk, or add the upstream cassandra repo as a second Antora content source so xrefs resolve automatically.

---

## Issue 2: CQL Syntax Highlighting Not Loaded

**Severity**: Medium (cosmetic but hurts readability)
**Pages**: Every page with CQL code blocks (security, ddl, dml, functions, etc.)

Console shows repeated: `Could not find the language 'cql', did you forget to load/include a language module?`

- DML page: 64 warnings
- DDL page: 128 warnings
- Security page: 80 warnings

All `[source,cql]` blocks fall back to no-highlight mode — code renders as plain monospace text without keyword coloring.

**Fix**: Add a CQL language definition to the Antora UI bundle's highlight.js configuration, or change source blocks to `[source,sql]` as a workaround.

---

## Issue 3: Missing Image on Security Page

**Severity**: Medium (broken image)
**Page**: `operators/secure/security.html`

Console error: `404 for cassandra_ssl_context_factory_pem.png`

The image was in the cassandra module's images directory and didn't get moved when the page moved to operators.

**Fix**: Move image assets that accompany moved pages, or add an `imagesdir` attribute pointing back to the cassandra module's images.

---

## Issue 4: What's New Page Is Embarrassing

**Severity**: High (most visible page for upgraders)
**Page**: `cassandra/new/index.html`

Content is a 3-bullet placeholder linking to **external Confluence pages**:
- ACID Transactions (Accord) → cwiki.apache.org
- Transactional Cluster Metadata → cwiki.apache.org
- Constraints → cwiki.apache.org

The Cassandra 5.0 section has **broken xrefs** — links render as `#cassandra:developing/cql/indexing/sai/sai-overview.adoc` (unresolved hash links). These are old-format xrefs that weren't updated when the CQL pages moved to the developers module.

**Missing from What's New**:
- Auto-repair (CEP-37)
- Password validation (CEP-24)
- Role name generation (CEP-55)
- ZstdDictionary compressor
- Guardrails framework
- Custom startup checks SPI
- Snitch deprecation / topology changes
- JDK 21 / Generational ZGC support
- BETWEEN, NOT, LIKE operators
- SAI frozen collection support
- Slow-query virtual table
- ~30 more documented changes

**Fix**: Complete rewrite linking to in-repo docs instead of Confluence. Cross-reference with `research/change-catalog/index.md` for the full feature list.

---

## Issue 5: Unresolved Xrefs to Non-Imported Pages

**Severity**: Medium (scattered broken links)
**Scope**: Multiple pages across all modules

Pages that reference "unchanged" trunk content render broken links:

| Page | Broken link | Target |
|------|------------|--------|
| compaction-overview | memtables, SSTable | contributors:architecture/storage-engine.adoc (not imported) |
| compaction-overview | STCS, LCS, TWCS | cassandra:managing/operating/compaction/stcs.adoc etc. (not imported) |
| install | Troubleshooting | cassandra:troubleshooting/index.adoc (not imported) |
| CQL security | permissions, roles, LIST ROLES | Self-referencing anchor links (anchor mismatch) |
| commands-toc | 42 CQL commands | reference/cql-commands/*.adoc (not imported) |

**Total estimated unresolved xrefs across site**: ~60-80

**Fix**: Add the upstream `apache/cassandra` doc tree as a second Antora content source, or selectively import the missing pages.

---

## Issue 6: Top Banner Navigation Is Default Template

**Severity**: Low (cosmetic)
**Location**: Global header bar

The top banner shows placeholder links: "Home", "Products", "Services", "Download" — these are Antora default UI placeholders that link to `#`. They're not Cassandra-specific.

**Fix**: Customize the Antora UI bundle header, or remove the placeholder links.

---

## Issue 7: Content Gaps Per IA Spec

**Severity**: High (feature completeness)

Comparing the rendered site against the IA spec's proposed sitemap:

### Operators Module — What's Missing

| IA Spec Section | Status |
|----------------|--------|
| Overview | Has "Production Recommendations" only. No operator overview/landing narrative. |
| Quickstart | **Missing entirely** — IA spec calls for operator quickstart |
| Install | Present (1 page) |
| Configure | Present (7 pages) |
| Operate | Present (9 pages) — missing STCS/LCS/TWCS compaction strategy pages |
| Secure | Present (4 pages) — crypto providers section missing from security.adoc |
| Upgrade | Present (7 pages) — TCM + Accord onboarding |
| Tune | Present (1 page) — async-profiler only. No performance tuning guide |
| Backup and Recovery | Present (1 page) |
| Observe and Troubleshoot | Present (6 pages) — metrics.adoc not updated with C6 additions |

### Developers Module — What's Missing

| IA Spec Section | Status |
|----------------|--------|
| Overview | No developer overview/landing narrative |
| Quickstart | **Missing entirely** |
| Data Modeling | **Missing entirely** — 10 pages exist in trunk but not imported |
| CQL and Querying | Present (25+ pages) — strongest section |
| Drivers | Present (1 page) — links list only |
| Application Patterns | **Missing entirely** |
| Vector Search | **Missing entirely** — 11 pages exist in trunk but not imported |
| Developer Troubleshooting | **Missing entirely** |

### Contributors Module — What's Missing

| IA Spec Section | Status |
|----------------|--------|
| Project Overview | **Missing** — no contributor overview |
| Architecture | Present (5 pages) |
| Build and Test | **Missing entirely** |
| Patch and Review | **Missing entirely** |
| Documentation Contributions | **Missing entirely** |
| Release and Website Publishing | **Missing entirely** |
| Generated-Doc Tooling | **Missing entirely** |

### Reference Module — What's Missing

| IA Spec Section | Status |
|----------------|--------|
| Configuration Reference | Present (cassandra.yaml — needs regeneration) |
| Nodetool Reference | Present (160 stubs — needs regeneration) |
| Native Protocol | Present (shell only — needs v6 protocol, regeneration) |
| Data Types and Syntax Reference | **Missing** — exists in trunk but not imported |
| Version and Compatibility Data | **Missing entirely** |
| CQL Commands | 42 of ~50 command pages missing (not imported) |

---

## Issue 8: Unresolved Open Questions in Draft Content

**Severity**: High (cannot ship without resolution)

14 files contain explicit "Open Questions", "TODO", or "WIP" language visible on the rendered site:

- TCM pages: 11 unresolved questions across 5 pages
- Guardrails: 7 TODOs + 9 unresolved questions
- Startup Checks SPI: 5 TODOs + 6 unresolved questions
- Security: 4 unresolved questions (crypto providers, native_transport_port_ssl)
- Snitch: 4 open questions for tech review
- JVM Options: 5 open questions
- Transaction Reference: 6 unresolved questions
- Onboarding to Accord: WIP language ("Before release this is likely to change")
- Configuration: explicit "Another TO DO"

**These are all visible to anyone reading the published draft site.**

---

## Issue 9: Stale Version References Visible on Site

**Severity**: Medium

- `{40_version}` renders as literal text on dynamo.adoc and production.adoc
- Java 11 references on install.adoc (should be 17/21)
- "Cassandra ???" placeholder on sai-faq.adoc
- `{product}` unresolved variable on compact-subproperties.adoc

---

## Does This Fit the Cassandra 6 Docs Spec?

### IA Structure: YES (with gaps)

The audience-first navigation matches the spec. Four modules, correct section hierarchy, proper landing pages. The structural reorganization succeeded.

### Content Completeness: NO

| Dimension | Status | Gap |
|-----------|--------|-----|
| Operators content | 70% present | Missing quickstart, performance tuning guide, STCS/LCS/TWCS |
| Developers content | 40% present | Missing data modeling (10 pages), vector search (11 pages), quickstart, patterns |
| Contributors content | 15% present | Only architecture; missing build/test, patch/review, docs, release |
| Reference content | 60% present | 42 CQL command pages missing, needs regeneration of generated docs |
| C6 feature coverage | 35 pages drafted | 48+ unresolved questions, 4 missing pages (list-superusers, cluster-metadata, guardrails, startup-checks in cassandra module) |
| Generated docs | Not regenerated | cassandra.yaml needs 46 new settings, nodetool needs picocli regen, native-protocol needs v6 |

### Publication Readiness: NO

**Blockers before this could serve as a reference**:

1. Resolve all 48+ open questions/TODOs (requires tech review against trunk)
2. Regenerate all generated docs from trunk
3. Create the 4 missing publish-blocker pages
4. Rewrite What's New page with comprehensive C6 feature list
5. Fix ~80 unresolved xrefs (import unchanged pages or add upstream source)
6. Fix CQL syntax highlighting
7. Move image assets with their pages
8. Fix stale version references
9. Import data modeling and vector search pages for developers module

---

## Recommended Priority Order

1. **Add upstream cassandra repo as Antora content source** — fixes ~80 broken xrefs in one shot
2. **Rewrite What's New page** — highest visibility, currently most embarrassing
3. **Resolve open questions** — 14 files, 48+ items requiring tech review
4. **Create missing pages** — list-superusers, cluster-metadata (cassandra module versions)
5. **Regenerate generated docs** — cassandra.yaml, nodetool, native-protocol
6. **Fix CQL syntax highlighting** — add language module to UI bundle
7. **Move missing images** — security page PNG at minimum
8. **Fix stale version refs** — `{40_version}`, Java 11, "Cassandra ???"
9. **Import data modeling + vector search** — complete the developers module
10. **Build out contributors module** — currently 85% empty vs spec
