# Cassandra 6 Documentation — JIRA Epic and Issues

Created: **2026-04-16**  
Source plans: `backlog/upstream-migration-plan.md`, `backlog/build-stack-upgrade-plan.md`

All issues target `apache/cassandra` or `apache/cassandra-website` as noted.  
Issues are listed in the order they should be created and executed.

---

## EPIC

**Project**: CASSANDRA  
**Issue type**: Epic  
**Summary**: Cassandra 6 documentation updates: content, navigation, and build stack modernization

**Description**:

This epic covers the full program of documentation work required for the Cassandra 6 release. It includes three parallel tracks:

1. **Build stack modernization** — Upgrade the `apache/cassandra-website` docs render pipeline from Antora 2.3 to Antora 3.1 before content contributions begin.

2. **Content contributions** — Contribute updated and new documentation pages to `apache/cassandra` covering Cassandra 6 features: Accord/ACID transactions, SAI frozen collection indexing, TCM (Topology Cluster Metadata), guardrails, new CQL commands (LIST SUPERUSERS, RESTRICT/UNRESTRICT ROWS, BETWEEN, LIKE), configuration changes, and deprecation of legacy components (gossip-based snitches, SASI).

3. **Navigation and information architecture overhaul** — Restructure the Cassandra documentation from a single topic-based module into audience-oriented sections (Operators, Developers, Contributors, Reference). This track requires dev@cassandra discussion before implementation and does not block the content track.

Content contributions follow the two-track approach requested in community feedback: content PRs land at existing paths first, IA restructuring happens as a separate coordinated effort after community consensus.

**Acceptance criteria**:
- Antora 3.1 upgrade landed and verified on cassandra.staged.apache.org
- All non-blocked minor-update pages for Cassandra 6 merged to trunk
- All non-blocked draft-complete major-update pages merged to trunk
- Generated surfaces (cassandra.yaml, nodetool, native protocol) validated for Cassandra 6
- Navigation/IA restructure proposal posted to dev@cassandra and consensus reached
- All publish-blocked new pages tracked individually with clear unblock criteria

---

## TRACK 0 — BUILD STACK AND PROCESS

---

### CASSANDRA-21315

**Project**: CASSANDRA-WEBSITE  
**Issue type**: Task  
**Summary**: Upgrade docs build stack to Antora 3.1 and Node.js 24 LTS  
**Priority**: Blocker  
**Labels**: documentation, build-infrastructure  
**Epic link**: (link to epic above)

**Description**:

The `apache/cassandra-website` docs build pipeline runs Antora 2.3, which is incompatible with content authored against Antora 3.x. This is a blocker for all Cassandra 6 documentation contributions from the workzone, which was built and validated against Antora 3.1.14.

**Changes required**:

`site-content/Dockerfile`
- Node.js: `v20.16.0` → `v24.14.1` (current active LTS; SHA256 verified for linux/amd64 and linux/arm64)
- Replace `@antora/cli@2.3` and `@antora/site-generator-default@2.3` with `@antora/cli@3.1.14` and `@antora/site-generator@3.1.14`
- Replace `antora-lunr` and `antora-site-generator-lunr` with `@antora/lunr-extension`

`site-content/docker-entrypoint.sh`
- Remove `--generator antora-site-generator-lunr` flag from the Antora invocation
- Remove `DOCSEARCH_ENABLED`, `DOCSEARCH_ENGINE=lunr`, `NODE_PATH`, and `DOCSEARCH_INDEX_VERSION` env exports (required only by the deprecated Antora 2 custom generator)

`site-content/site.template.yaml`
- Add `antora.extensions` block registering `@antora/lunr-extension` (Antora 3 extension registration model)
- `asciidoc.extensions` (`tabs-block.js`, `@djencks/asciidoctor-openblock`) left unchanged

**What is NOT changed**:
- Branch matrix (`trunk`, `cassandra-5.0`, `cassandra-4.1`, `cassandra-4.0`, `cassandra-3.11`)
- `stable` / `latest` alias behavior
- `run.sh` command surface
- JDK selection logic for generated docs per branch
- `tabs-block.js` and `@djencks/asciidoctor-openblock` AsciiDoc extensions

**Validation performed locally**:
- Docker image built clean with Antora 3.1.14 and Node 24.14.1
- Single-branch build (`trunk`) succeeded; `search-index.js` present confirming `@antora/lunr-extension` functional
- Multi-branch build (`trunk`, `cassandra-5.0`, `cassandra-4.1`) succeeded; version directories `4.1/`, `5.0/`, `6.0/`, `latest/`, `stable/` all present
- `stable/` and `latest/` alias behavior confirmed unchanged
- xref errors in build output are all pre-existing in upstream trunk content, not regressions from this upgrade

**PR**: (link to PR from `pmcfadin/cassandra-website:antora-3-upgrade`)

**Acceptance criteria**:
- `./run.sh website container` builds clean
- `./run.sh website build -g -b cassandra:trunk,cassandra-5.0,cassandra-4.1` succeeds
- Search index present in rendered output
- Version selector shows all expected versions with correct aliases
- Site verified at https://cassandra.staged.apache.org/ after CI deploys

---

### ISSUE-02

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Audit Cassandra 6 docs workzone content for Antora 3 xref compatibility  
**Priority**: High  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-01

**Description**:

The docs workzone contains 378 authored `.adoc` files. Before any content is contributed upstream, all pages must be audited for Antora 3 breaking changes:

- **Bare xrefs missing `.adoc` suffix**: Antora 3 removed the automatic `.adoc` fallback that Antora 2 supported. Any `xref:some-page[]` without `.adoc` will produce an unresolved reference error.
- **`page-aliases` values missing `.adoc`**: Same requirement — aliases must include the file extension.
- **`[tabs]` block pages**: 10+ workzone pages use `[tabs]` blocks. These depend on `tabs-block.js` being registered in the playbook. Confirm all tab blocks render correctly.
- **Extension registration namespace**: Verify no extension is registered in the wrong namespace (`antora.extensions` vs `asciidoc.extensions`).

Output: a list of files requiring fixes before they can be submitted as upstream PRs.

**Acceptance criteria**:
- All 71 import-candidate pages scanned
- List of xref/alias issues documented
- All issues fixed in workzone content before first content PR opens

---

### ISSUE-03

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Establish committer sponsor and AI disclosure approach for Cassandra 6 docs program  
**Priority**: High  
**Labels**: documentation, process  
**Epic link**: (link to epic above)

**Description**:

Before content PRs begin, two process items must be settled:

**1. Committer sponsor**
Identify at least one committer willing to review and merge Cassandra 6 documentation PRs. The volume of changes (28 minor-update pages, 13 major-update pages, 6 new pages) requires a committed reviewer. Existing docs contributors or the PMC documentation lead are the natural candidates.

**2. AI disclosure approach**
Content in this program was drafted with AI assistance (Claude, Anthropic). The ASF has not yet issued binding policy on AI-generated content. The proposed disclosure approach, consistent with current ASF guidance, is:

- Commit messages include: `AI-assisted: Claude (Anthropic)` when AI materially contributed to the content
- PR description states: which tool was used, that output was reviewed against source code in `apache/cassandra` trunk, and that source provenance is maintained in workzone research artifacts available for inspection
- No AI-generated content is committed without human review and source validation

This approach requires lazy consensus on dev@cassandra — a formal vote is not required for routine process.

**Acceptance criteria**:
- At least one committer has agreed to review docs PRs
- AI disclosure format posted to dev@cassandra and no blocking objections raised within 72 hours

---

### ISSUE-04

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Announce Cassandra 6 docs contribution program on dev@cassandra  
**Priority**: High  
**Labels**: documentation, community  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-03

**Description**:

Post a brief, clear announcement to dev@cassandra describing the Cassandra 6 documentation update program so the community knows what PRs to expect and can raise concerns early.

The announcement should cover:
- The staged approach: content track first (existing paths), IA restructure as a separate parallel track requiring community discussion
- The two JIRA tracks under this epic
- The expected volume: approximately 47 content pages across minor-update, major-update, and new-page categories
- The AI disclosure approach being used
- An invitation for committer volunteers to review docs PRs

**Acceptance criteria**:
- Email sent to dev@cassandra
- No blocking community objections within one week
- Thread archived and linked from this JIRA

---

## TRACK 1 — NAVIGATION AND INFORMATION ARCHITECTURE

---

### ISSUE-05

**Project**: CASSANDRA  
**Issue type**: Epic or Task  
**Summary**: Propose audience-first documentation IA restructure on dev@cassandra  
**Priority**: Medium  
**Labels**: documentation, architecture  
**Epic link**: (link to epic above)

**Description**:

The current Cassandra documentation uses a single `cassandra` Antora module with topic-based directories. The Cassandra 6 docs program has developed content organized around four audience-oriented sections:

- **Operators**: Installation, configuration, deployment, backup/recovery, observability, troubleshooting, upgrading
- **Developers**: Drivers, CQL, data modeling, vector search, ACID transactions, quickstarts
- **Contributors**: Architecture, build/test, development workflow, patch review, release process
- **Reference**: CQL commands, configuration parameters, cqlsh, native protocol

This structure makes the docs more navigable for the primary personas who use Cassandra documentation. It also allows audience-specific navigation, search, and versioning.

**This issue covers the community discussion phase only** — implementation is a separate issue and is blocked on consensus.

The proposal should be posted to dev@cassandra with:
- Concrete examples of the current structure vs. proposed structure
- The rationale (audience clarity, discoverability, reduced noise per persona)
- The implementation approach (migration path, backward compatibility for existing links)
- An explicit invitation for alternative proposals

This track does NOT block content PRs to existing paths (Stages 1-3 of the content track). It is a prerequisite only for new audience-module pages (vector search guides, TCM operations, agentic patterns) that have no natural home in the current structure.

**Acceptance criteria**:
- Thread posted to dev@cassandra
- Community feedback gathered (minimum 2 weeks open)
- Consensus documented (for, against, or modified approach)
- Outcome recorded in this JIRA and linked to implementation issue if approved

---

### ISSUE-06

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Implement audience-first IA restructure in apache/cassandra and apache/cassandra-website  
**Priority**: Medium  
**Labels**: documentation, architecture  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-05 (dev@cassandra consensus required)

**Description**:

If the IA restructure proposed in ISSUE-05 reaches consensus, implement the new module structure across both repositories.

**Scope in `apache/cassandra`**:
- Create new Antora component directories: `doc/modules/operators/`, `doc/modules/developers/`, `doc/modules/contributors/`, `doc/modules/reference/`
- Migrate pages from `doc/modules/cassandra/pages/` to new audience paths per the agreed mapping
- Update all `nav.adoc` files
- Add `page-aliases` for all moved pages to preserve existing inbound links
- Update all internal xrefs

**Scope in `apache/cassandra-website`**:
- Update the Antora playbook to include the new components as content sources
- Update version-selector configuration if needed
- Validate navigation renders correctly across all supported Cassandra versions

**Implementation constraint**: The existing `cassandra` module must remain functional during the transition. All moved pages require `page-aliases` pointing from old paths to new paths so external links and search results do not break.

**Acceptance criteria**:
- All audience-module pages accessible at new paths
- All old paths redirect correctly via `page-aliases`
- Navigation renders correctly in local build and on cassandra.staged.apache.org
- No version-selector regressions

---

### ISSUE-07

**Project**: CASSANDRA-WEBSITE  
**Issue type**: Task  
**Summary**: Wire Cassandra 6 audience components into cassandra-website Antora playbook  
**Priority**: Medium  
**Labels**: documentation, build-infrastructure  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-06

**Description**:

Once the audience-first module structure lands in `apache/cassandra`, update `apache/cassandra-website` to include the new components in the Antora playbook and validate the full build.

Changes required:
- Add new component sources to the playbook for operators, developers, contributors, reference modules
- Update version aliases (`stable`, `latest`) to include new components
- Update start page configuration
- Validate that the existing cassandra module and new audience modules render without conflicts

**Acceptance criteria**:
- Full multi-branch build succeeds with new components
- All new audience-module pages accessible in rendered output
- Version selector and alias behavior unchanged for existing content

---

## TRACK 2 — CONTENT (existing doc/ paths)

---

### ISSUE-08

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Test PR: minor docs updates for compaction overview, auto repair, and nodetool troubleshooting  
**Priority**: High  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-01 merged, ISSUE-03 committer identified

**Description**:

Validate the full contribution mechanic end-to-end with a deliberately small PR of 2-3 low-controversy minor-update pages. This PR establishes the pattern (path mapping, xref cleanup, AI disclosure format, review process) for all subsequent content PRs.

**Pages**:
- `doc/modules/cassandra/pages/managing/operating/compaction/overview.adoc`
- `doc/modules/cassandra/pages/managing/operating/auto_repair.adoc`
- `doc/modules/cassandra/pages/troubleshooting/use_nodetool.adoc`

**Per-PR checklist**:
- [ ] Pages copied from workzone `content/modules/cassandra/pages/` at same relative path
- [ ] "Preview | Unofficial" admonitions removed
- [ ] Workzone-specific xrefs adjusted to upstream paths
- [ ] Local Antora build verified via `cassandra-website`
- [ ] `AI-assisted: Claude (Anthropic)` in commit message
- [ ] PR description includes source provenance statement
- [ ] `nav.adoc` updated if needed

**Acceptance criteria**:
- PR merged or concrete process feedback received
- AI disclosure format accepted or adjusted per reviewer guidance
- Build verification approach confirmed for subsequent PRs

---

### ISSUE-09

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Minor CQL and developer docs updates for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute minor-update pages for CQL and developer-facing content. These are small diffs — clarifications, new parameter documentation, and additions for Cassandra 6 features.

**Pages (~10)**:
- `developing/cql/changes.adoc` — CQL language changes in Cassandra 6
- `developing/cql/definitions.adoc` — Updated definitions
- `developing/cql/index.adoc` — CQL section index
- `developing/cql/triggers.adoc` — Trigger documentation updates
- `developing/cql/types.adoc` — Type system updates
- `developing/cql/constraints.adoc` — Schema constraints (new in Cassandra 6)
- `developing/cql/indexing/sai/operations/monitoring.adoc` — SAI monitoring
- `developing/cql/indexing/sai/sai-read-write-paths.adoc` — SAI read/write paths
- `developing/index.adoc` — Developer section landing page
- `getting-started/drivers.adoc` — Driver selection guide updates

**Acceptance criteria**:
- All pages merged to trunk
- No Antora build regressions
- Technical review completed

---

### ISSUE-10

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Minor operator and operations docs updates for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute minor-update pages for operator and operations content. These cover new operational behaviors, configuration additions, and procedure clarifications in Cassandra 6.

**Pages (~12)**:
- `managing/operating/async-profiler.adoc`
- `managing/operating/audit_logging.adoc` — Audit logging updates
- `managing/operating/bulk_loading.adoc`
- `managing/operating/fqllogging.adoc` — Full query logging updates
- `managing/operating/hints.adoc`
- `managing/operating/onboarding-to-accord.adoc` — Accord onboarding procedure
- `managing/operating/repair.adoc` — Auto-repair updates (CEP-37)
- `managing/operating/role_name_generation.adoc`
- `managing/operating/password_validation.adoc` — New password validation guardrail
- `managing/operating/compaction/ucs.adoc` — Unified Compaction Strategy updates
- `installing/installing.adoc`
- `getting-started/mtlsauthenticators.adoc`

**Acceptance criteria**:
- All pages merged to trunk
- No Antora build regressions
- Technical review completed

---

### ISSUE-11

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Minor tools and reference docs updates for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute minor-update pages for tools and reference content covering Cassandra 6 changes.

**Pages (~7)**:
- `managing/tools/cqlsh.adoc` — cqlsh updates for Cassandra 6
- `managing/tools/sstable/sstabledump.adoc`
- `managing/tools/sstable/sstableloader.adoc`
- `managing/tools/sstable/sstableexpiredblockers.adoc`
- `managing/tools/sstable/sstablescrub.adoc`
- `reference/cql-commands/commands-toc.adoc`
- `reference/cql-commands/compact-subproperties.adoc`

**Acceptance criteria**:
- All pages merged to trunk
- No Antora build regressions

---

### ISSUE-12

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: SAI indexing documentation major updates for Cassandra 6  
**Priority**: High  
**Labels**: documentation, SAI  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute major-update pages covering Storage Attached Indexing (SAI) changes in Cassandra 6, including frozen collection indexing support (CASSANDRA-18492).

**Pages (draft-complete)**:
- `developing/cql/indexing/sai/sai-concepts.adoc` — Updated concepts covering new capabilities
- `developing/cql/indexing/sai/sai-faq.adoc` — Updated FAQ
- `developing/cql/indexing/sai/collections.adoc` — Frozen collection SAI support
- `developing/cql/indexing/sai/collections/_collections-list.adoc`
- `developing/cql/indexing/sai/collections/_collections-map.adoc`
- `developing/cql/indexing/sai/collections/_collections-set.adoc`

Requires technical review by a SAI maintainer.

**Acceptance criteria**:
- All pages merged with technical-owner sign-off
- No Antora build regressions
- Source evidence trail in PR description

---

### ISSUE-13

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: CQL syntax and security documentation major updates for Cassandra 6  
**Priority**: High  
**Labels**: documentation, CQL  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute major-update pages for CQL functions and security in Cassandra 6.

**Pages (draft-complete)**:
- `developing/cql/functions.adoc` — Updated function reference covering Cassandra 6 additions
- `developing/cql/security.adoc` — Security documentation updates including new auth options

Requires technical review.

**Acceptance criteria**:
- Both pages merged with technical-owner sign-off
- No Antora build regressions

---

### ISSUE-14

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Operator and operations major documentation updates for Cassandra 6  
**Priority**: High  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-08 merged

**Description**:

Contribute major-update pages for operator-facing operations documentation in Cassandra 6.

**Pages (draft-complete)**:
- `managing/operating/backups.adoc` — Updated backup strategy and tooling
- `managing/operating/compression.adoc` — Compression options updates
- `managing/operating/virtualtables.adoc` — Virtual tables reference updates for Cassandra 6

Requires technical review.

**Acceptance criteria**:
- All pages merged with technical-owner sign-off
- No Antora build regressions

---

### ISSUE-15

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Draft and contribute configuration file documentation for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation, configuration  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-09, ISSUE-10 merged

**Description**:

Draft and contribute six interdependent configuration file documentation pages covering Cassandra 6 changes. These pages are treated as a unit because they share cross-references and cover related configuration changes (snitch removal, new YAML parameters, JVM options for Java 17/21).

**Pages (require drafting)**:
- `managing/configuration/configuration.adoc` — Configuration overview
- `managing/configuration/cass_env_sh_file.adoc` — cassandra-env.sh
- `managing/configuration/cass_jvm_options_file.adoc` — JVM options (Java 17/21 updates)
- `managing/configuration/cass_logback_xml_file.adoc` — Logging configuration
- `managing/configuration/cass_rackdc_file.adoc` — Rack and DC configuration (snitch changes)
- `managing/configuration/cass_topo_file.adoc` — Topology file

Draft each page in the workzone using the `cassandra-asciidoc-authoring` skill against change-catalog research before contributing upstream.

**Acceptance criteria**:
- All six pages drafted, internally reviewed, and merged to trunk
- Snitch deprecation documented correctly across config pages
- Technical review completed

---

### ISSUE-16

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Draft and contribute architecture and operations major updates for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-09, ISSUE-10 merged

**Description**:

Draft and contribute remaining major-update pages covering architecture and operational changes in Cassandra 6.

**Pages (require drafting)**:
- `architecture/dynamo.adoc` — Significant rewrite covering snitch deprecation and Accord topology
- `managing/operating/snitch.adoc` — Snitch deprecation and migration guidance
- `managing/operating/metrics.adoc` — Updated metrics reference for Cassandra 6
- `managing/operating/compaction/tombstones.adoc` — Tombstone compaction updates
- `getting-started/production.adoc` — Production readiness guide (JDK 21, new config defaults)

Draft in workzone first. Validate against change-catalog research.

**Acceptance criteria**:
- All pages drafted, reviewed, and merged
- Technical review from relevant maintainers

---

### ISSUE-17

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Draft and contribute CQL collection and SASI major updates for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation, CQL  
**Epic link**: (link to epic above)  
**Blocked by**: ISSUE-09 merged

**Description**:

Draft and contribute major-update pages covering CQL collection behavior and SASI deprecation in Cassandra 6.

**Pages (require drafting)**:
- `developing/cql/indexing/SASI.adoc` — SASI deprecation and migration to SAI
- `developing/cql/collections/list.adoc` — List collection updates (LIKE expressions)
- `developing/cql/collections/map.adoc` — Map collection updates
- `developing/cql/collections/set.adoc` — Set collection updates

**Acceptance criteria**:
- All pages drafted, reviewed, and merged
- SASI deprecation messaging reviewed by a maintainer

---

### ISSUE-18

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Draft and contribute What's New in Cassandra 6 page  
**Priority**: Medium  
**Labels**: documentation  
**Epic link**: (link to epic above)  
**Blocked by**: Major-update PRs stable (ISSUE-12 through ISSUE-17)

**Description**:

Draft and contribute the Cassandra 6 release summary page and the SAI virtual table indexes reference.

**Pages**:
- `new/index.adoc` — What's New in Cassandra 6 (release-oriented summary of major changes)
- `reference/sai-virtual-table-indexes.adoc` — SAI virtual table index reference

The What's New page should be written last, after major feature documentation is stable, so it accurately summarizes what's available.

**Acceptance criteria**:
- Both pages merged to trunk
- What's New page reviewed by PMC or release manager for accuracy

---

## TRACK 3 — NEW PAGES (publish-blocked)

*All six issues below have `publish_blocker=yes`. Each requires a maintainer decision on scope and correctness before the page can land. Create these JIRAs now to track the blocker conversation.*

---

### ISSUE-19

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: ACID transactions reference (`developing/cql/txn-reference.adoc`)  
**Priority**: High  
**Labels**: documentation, Accord  
**Epic link**: (link to epic above)

**Description**:

Add a new reference page for ACID transaction syntax in Cassandra 6 (Accord). Draft is complete in the workzone. This page is blocked pending maintainer confirmation that the Accord CQL syntax documented is final and correct for the Cassandra 6 release.

**Proposed path**: `doc/modules/cassandra/pages/developing/cql/txn-reference.adoc`

**Unblock criteria**: An Accord maintainer reviews the draft and confirms the syntax is final.

---

### ISSUE-20

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: Topology Cluster Metadata operations (`managing/operating/cluster-metadata.adoc`)  
**Priority**: High  
**Labels**: documentation, TCM  
**Epic link**: (link to epic above)

**Description**:

Add a new page covering TCM (Topology Cluster Metadata) operations introduced in Cassandra 6. Draft exists in workzone. Blocked pending maintainer review of operational procedures.

**Proposed path**: `doc/modules/cassandra/pages/managing/operating/cluster-metadata.adoc`

**Unblock criteria**: A TCM maintainer reviews the draft and confirms accuracy.

---

### ISSUE-21

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: Guardrails reference (`managing/operating/guardrails.adoc`)  
**Priority**: Medium  
**Labels**: documentation, guardrails  
**Epic link**: (link to epic above)

**Description**:

Add a new guardrails reference page covering all guardrail configuration options in Cassandra 6. Blocked pending review of guardrail parameter completeness and defaults.

**Proposed path**: `doc/modules/cassandra/pages/managing/operating/guardrails.adoc`

**Unblock criteria**: Guardrails maintainer confirms parameter list and defaults are accurate for the release.

---

### ISSUE-22

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: Startup checks SPI (`managing/operating/startup-checks-spi.adoc`)  
**Priority**: Low  
**Labels**: documentation  
**Epic link**: (link to epic above)

**Description**:

Add a new page documenting the startup checks service provider interface introduced in Cassandra 6. Blocked pending maintainer decision on whether this is public API suitable for user-facing documentation.

**Proposed path**: `doc/modules/cassandra/pages/managing/operating/startup-checks-spi.adoc`

**Unblock criteria**: Maintainer confirms this SPI is public and stable for Cassandra 6.

---

### ISSUE-23

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: nodetool altertopology (`managing/tools/nodetool/altertopology.adoc`)  
**Priority**: Medium  
**Labels**: documentation, nodetool  
**Epic link**: (link to epic above)

**Description**:

Add a new nodetool reference page for `altertopology`, a new command in Cassandra 6 for TCM-based topology changes. Blocked pending confirmation that the command signature and behavior are final.

**Proposed path**: `doc/modules/cassandra/pages/managing/tools/nodetool/altertopology.adoc`

**Unblock criteria**: TCM/nodetool maintainer confirms command signature is final for the release.

---

### ISSUE-24

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: New page: LIST SUPERUSERS CQL command (`reference/cql-commands/list-superusers.adoc`)  
**Priority**: Medium  
**Labels**: documentation, CQL  
**Epic link**: (link to epic above)

**Description**:

Add a new CQL reference page for the `LIST SUPERUSERS` command introduced in Cassandra 6. Blocked pending confirmation that the command syntax and permissions behavior are finalized.

**Proposed path**: `doc/modules/cassandra/pages/reference/cql-commands/list-superusers.adoc`

**Unblock criteria**: CQL/auth maintainer confirms command is final and documents the correct required permissions.

---

## TRACK 4 — GENERATED SURFACES

---

### ISSUE-25

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Validate and update cassandra.yaml generated docs for Cassandra 6  
**Priority**: High  
**Labels**: documentation, generated  
**Epic link**: (link to epic above)

**Description**:

The `managing/configuration/cass_yaml_file.adoc` page is generated from `conf/cassandra.yaml` via `ant gen-asciidoc`. It must not be manually edited. This issue covers validating and if necessary fixing the generation script so the output accurately reflects the Cassandra 6 configuration file.

**Actions**:
1. Run `ant gen-asciidoc` on trunk
2. Diff the generated `cass_yaml_file.adoc` against the current committed version
3. Identify any new, removed, or changed parameters not covered by the existing generator
4. Fix `doc/scripts/` generation tooling if needed
5. Submit script fixes as a separate PR from authored content

**Acceptance criteria**:
- Generated `cass_yaml_file.adoc` accurately reflects all Cassandra 6 `cassandra.yaml` parameters
- No manual edits to the generated file — only script fixes

---

### ISSUE-26

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Validate and update nodetool generated docs for Cassandra 6  
**Priority**: High  
**Labels**: documentation, generated, nodetool  
**Epic link**: (link to epic above)

**Description**:

The `managing/tools/nodetool/*.adoc` pages are generated via `doc/scripts/gen-nodetool-docs.py`. This issue covers validating the generator produces correct output for all Cassandra 6 nodetool commands including any new commands (`altertopology` and others).

**Actions**:
1. Run the nodetool docs generator on trunk
2. Identify any new or changed commands not covered
3. Fix the generation script if needed
4. Verify generated pages match actual nodetool `--help` output

**Acceptance criteria**:
- All Cassandra 6 nodetool commands have generated reference pages
- No manual edits to generated files

---

### ISSUE-27

**Project**: CASSANDRA  
**Issue type**: Task  
**Summary**: Validate and update native protocol generated docs for Cassandra 6  
**Priority**: Medium  
**Labels**: documentation, generated, native-protocol  
**Epic link**: (link to epic above)

**Description**:

The `reference/native-protocol.adoc` page is generated via `doc/scripts/process-native-protocol-specs-in-docker.sh` from the protocol specification source. This issue covers validating the generator produces correct output reflecting any Cassandra 6 native protocol changes (CASSANDRA-13342 failure reason codes and others).

**Actions**:
1. Run the native protocol generator on trunk
2. Diff output against current committed `native-protocol.adoc`
3. Fix generation script if any protocol additions are missing
4. Verify output against `doc/native_protocol_v*.spec` source files

**Acceptance criteria**:
- Generated `native-protocol.adoc` reflects all Cassandra 6 protocol changes
- No manual edits to the generated file

---

## Issue Dependency Map

```
EPIC
├── CASSANDRA-21315  Antora 3 upgrade (cassandra-website)   [BLOCKER for content track]
├── ISSUE-02  Xref compatibility audit                       [blocked by CASSANDRA-21315]
├── ISSUE-03  Committer sponsor + AI disclosure              [independent]
├── ISSUE-04  dev@cassandra announcement                     [blocked by ISSUE-03]
│
├── ISSUE-05  Propose audience-first IA on dev@cassandra     [independent]
├── ISSUE-06  Implement IA restructure                       [blocked by ISSUE-05]
├── ISSUE-07  Wire new components into cassandra-website     [blocked by ISSUE-06]
│
├── ISSUE-08  Test PR (3 pages)                             [blocked by CASSANDRA-21315 + ISSUE-03]
│   ├── ISSUE-09  Minor CQL/developer updates (10p)         [blocked by ISSUE-08]
│   ├── ISSUE-10  Minor operator/ops updates (12p)          [blocked by ISSUE-08]
│   ├── ISSUE-11  Minor tools/reference updates (7p)        [blocked by ISSUE-08]
│   ├── ISSUE-12  SAI major updates (6p, draft-complete)    [blocked by ISSUE-08]
│   ├── ISSUE-13  CQL syntax/security major (2p)            [blocked by ISSUE-08]
│   ├── ISSUE-14  Operator ops major (3p, draft-complete)   [blocked by ISSUE-08]
│   ├── ISSUE-15  Config file docs (6p, needs drafting)     [blocked by ISSUE-09+10]
│   ├── ISSUE-16  Architecture/ops major (5p, needs draft)  [blocked by ISSUE-09+10]
│   ├── ISSUE-17  Collections/SASI major (4p, needs draft)  [blocked by ISSUE-09]
│   └── ISSUE-18  What's New page                           [blocked by ISSUE-12 thru 17]
│
├── ISSUE-19  New: ACID txn reference                       [publish-blocked]
├── ISSUE-20  New: Cluster metadata ops                     [publish-blocked]
├── ISSUE-21  New: Guardrails reference                     [publish-blocked]
├── ISSUE-22  New: Startup checks SPI                       [publish-blocked]
├── ISSUE-23  New: nodetool altertopology                   [publish-blocked]
├── ISSUE-24  New: LIST SUPERUSERS                          [publish-blocked]
│
├── ISSUE-25  Generated: cassandra.yaml docs                [independent]
├── ISSUE-26  Generated: nodetool docs                      [independent]
└── ISSUE-27  Generated: native protocol docs               [independent]
```

**Total: 1 Epic + 27 Issues**
