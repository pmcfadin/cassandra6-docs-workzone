# Build Stack Upgrade Plan

Created: **2026-04-09**

## Purpose

This document expands the "Build Stack Gap" work in [upstream-migration-plan.md](upstream-migration-plan.md) into an implementation-ordered infra plan for the upstream docs build path in `apache/cassandra-website`.

The goal of this track is to modernize the upstream Cassandra docs render stack before broad Cassandra 6 content migration continues. This work is preparatory infra, not Cassandra 6 version-wire work. It should land first so content validation happens against the stack we actually intend to keep.

## Target State

Target state for the upstream docs build stack, as of **2026-04-09**:

- `@antora/cli` and Antora site generator pinned to `3.1.14`
- Node.js pinned to the current active LTS line, currently `v24.14.1`
- Asciidoctor behavior aligned to the Antora 3.1 line using bundled Asciidoctor.js `2.2.x`, not a standalone jump to `@asciidoctor/core` `3.x`
- upstream `./lib/tabs-block.js` and `@djencks/asciidoctor-openblock` explicitly preserved
- deprecated `antora-lunr` and `antora-site-generator-lunr` removed
- search migrated to the Antora 3 extension path
- current Cassandra branch matrix and current `stable` / `latest` alias behavior preserved until the separate Cassandra 6 version-wire change

## Current State Snapshot

The current upstream and workzone split that motivates this plan:

| Area | Workzone | Upstream `cassandra-website` |
|------|----------|------------------------------|
| Antora | `@antora/cli` `^3.1.14`, `@antora/site-generator` `^3.1.14` | global `@antora/cli@2.3`, `@antora/site-generator-default@2.3` |
| Asciidoctor line | Antora 3.1 bundle, `@asciidoctor/core` `~2.2` in lockfile | Antora 2.3 / Asciidoctor.js 1.5.9-era behavior |
| Node.js | not pinned in repo tooling | pinned to `v20.16.0` in `site-content/Dockerfile` |
| Search integration | none declared in workzone playbook | `antora-site-generator-lunr` plus `antora-lunr` |
| AsciiDoc extensions | not declared in workzone playbook | `./lib/tabs-block.js`, `@djencks/asciidoctor-openblock` |

Important observations:

- The upstream stack is older where it matters most for docs rendering: Antora, Asciidoctor behavior, and search integration.
- The upstream stack is already modern enough in some container dependencies; this is not a request to churn every tool in the image.
- The workzone currently does not declare the same required extensions as upstream, so local preview is not yet representative.
- There are **10** known `[tabs]` blocks in the workzone that depend on upstream extension behavior.
- Antora 3 removes the old `.adoc` fallback for xrefs and `page-aliases`, so explicit resource IDs have to be treated as a compatibility gate.

## Scope Boundaries

In scope:

- `apache/cassandra-website` docs build container and render pipeline
- Antora, Node, search integration, and extension wiring needed to support Antora 3
- verification that Cassandra multi-version generated docs still render correctly
- documentation changes in this workzone needed to keep local preview aligned with upstream-required extensions

Out of scope:

- Cassandra 6 branch cut or alias flip
- changing which Cassandra major version maps to `stable` or `latest`
- redesigning Cassandra website IA or navigation
- opportunistic upgrades of unrelated container dependencies

## Dependency Sequence

### Stage 1: Baseline Current Upstream Behavior

**Goal**: freeze the current `cassandra-website` behavior before changing the stack.

**Depends on**: none

**Work**:
1. Build current upstream `cassandra-website` on its existing stack.
2. Capture output for `trunk`, `cassandra-5.0`, and at least one older maintained branch such as `cassandra-4.1`.
3. Record:
   - version selector contents
   - `stable` / `latest` alias behavior
   - generated-doc presence
   - search behavior
   - representative tabs pages
   - representative xref-heavy pages
4. Inventory Antora-2-coupled pieces:
   - global npm installs in `site-content/Dockerfile`
   - custom generator invocation in `docker-entrypoint.sh`
   - `DOCSEARCH_*` env wiring
   - `./lib/tabs-block.js`
   - `@djencks/asciidoctor-openblock`
   - branch and alias copy logic in `prepare_site_html_for_publication`

**Outcome**:
- one written regression baseline exists before the upgrade
- current release-routing behavior is documented so the infra PR cannot accidentally change it

**Quality checks**:
- `./run.sh website build` succeeds on current upstream trunk
- baseline captures at least one tabs page, one xref-heavy page, and one generated-doc page
- current alias behavior is written down explicitly

### Stage 2: Align Local Validation With Upstream Extension Requirements

**Goal**: make local validation representative before upstream stack changes land.

**Depends on**: Stage 1 baseline

**Work**:
1. Update workzone/local validation assumptions so `tabs-block.js` and `@djencks/asciidoctor-openblock` are treated as required.
2. Audit sampled migrated pages for Antora-3-sensitive syntax:
   - xrefs missing `.adoc`
   - `page-aliases` values missing `.adoc`
   - extension registration in the wrong namespace
3. Confirm the registration split:
   - `asciidoc.extensions` only for Asciidoctor extensions
   - `antora.extensions` only for Antora extensions such as search

**Outcome**:
- candidate migrated content is known to be compatible with Antora 3 rules
- local preview contracts match upstream-required extension behavior

**Quality checks**:
- no unresolved xrefs in the sampled migration pages under Antora 3 validation
- all 10 known `[tabs]` pages render as tabsets, not raw example blocks
- no extension-registration warnings appear in build logs

### Stage 3: Upgrade The Upstream Build Container

**Goal**: move the upstream docs container to the supported Antora 3 stack without changing Cassandra generation behavior yet.

**Depends on**: Stage 1 baseline, Stage 2 compatibility prep

**Work**:
1. Update `site-content/Dockerfile`:
   - pin Node.js to `v24.14.1`
   - replace global Antora 2 packages with `@antora/cli@3.1.14` and the Antora 3 site generator package line
   - remove `antora-lunr` and `antora-site-generator-lunr`
   - add the Antora 3 search dependency
   - keep `@djencks/asciidoctor-openblock`
2. Leave the JDK matrix and `ant gen-asciidoc` branch-generation flow unchanged in this stage.
3. Confirm the resulting image contains no Antora-2-only render path.

**Outcome**:
- upstream container can execute Antora 3 tooling
- deprecated Antora 2 search/generator packages are gone

**Quality checks**:
- container build succeeds cleanly
- global package inventory shows only Antora 3 packages for the render path
- no Antora 2-only search packages remain in the image

### Stage 4: Migrate The Render Pipeline To Antora 3 Extension Wiring

**Goal**: replace the Antora 2 custom-generator path with the Antora 3 default generator plus explicit extensions.

**Depends on**: Stage 3 container upgrade

**Work**:
1. Change `docker-entrypoint.sh` to invoke standard Antora instead of `antora-site-generator-lunr`.
2. Update `site.template.yaml` and generated `site.yaml` behavior so:
   - search is registered as an Antora extension
   - `tabs-block.js` and openblock remain under `asciidoc.extensions`
3. Remove or trim generator-specific `DOCSEARCH_*` / `NODE_PATH` wiring only if it is no longer needed by the chosen Antora 3 search path or UI code.
4. Keep branch list and alias behavior unchanged in this stage except for edits required to preserve current rendering.

**Outcome**:
- upstream rendering uses Antora 3’s supported extension model
- search no longer depends on an Antora 2 custom site generator

**Quality checks**:
- `./run.sh website build` succeeds
- `./run.sh website build -g` succeeds
- `./run.sh website preview` succeeds
- `./run.sh website docs` succeeds
- search index generation works
- version selector contents remain unchanged
- `stable` / `latest` behavior remains unchanged

### Stage 5: Validate Multi-Version Cassandra Docs End To End

**Goal**: prove that Antora 3 works with Cassandra’s real generated-doc and branch-matrix behavior.

**Depends on**: Stage 4 render-pipeline migration

**Work**:
1. Run the upstream build against local Cassandra branches:
   - `trunk`
   - `cassandra-5.0`
   - at least one older supported branch such as `cassandra-4.1`
2. Confirm `ant gen-asciidoc` still produces:
   - `doc/antora.yml`
   - generated `cass_yaml` docs
   - generated nodetool docs
   - generated native-protocol docs
3. Verify `prepare_site_html_for_publication` still materializes the same public directory structure.
4. Compare output against the Stage 1 baseline for version directories, selector behavior, and generated surfaces.

**Outcome**:
- Antora 3 is proven against Cassandra’s multi-branch docs generation path
- publication prep still yields the expected versioned output structure

**Quality checks**:
- generated surfaces are present in the rendered output
- no branch-specific JDK-selection regressions occur
- no version directory is dropped, renamed, or silently skipped

### Stage 6: Land Infra First, Then Unblock Content PRs

**Goal**: make the Antora 3 stack the upstream baseline before large Cassandra 6 content contributions continue.

**Depends on**: Stages 1 through 5

**Work**:
1. Open one infra-focused JIRA and PR in `apache/cassandra-website`.
2. Keep Cassandra 6 version-wire work separate.
3. Land staging validation before treating the upgrade as done.
4. Update this workzone’s migration plan to treat the upstream Antora 3 stack as the baseline for content validation once the upstream PR lands.

**Outcome**:
- content work proceeds against the intended long-term stack, not a temporary compatibility lane

**Quality checks**:
- staging validation is completed on `cassandra.staged.apache.org`
- website/publish reviewers sign off on:
  - search behavior
  - versioned docs rendering
  - alias behavior
- content-track validation is only unblocked after staging parity is confirmed

## Public Interfaces And Build Contracts

These contract changes should be called out explicitly in the eventual upstream implementation:

- `site-content/Dockerfile`
  - Node and global npm package pins change
  - the image no longer carries the Antora 2 search/generator path
- `site-content/docker-entrypoint.sh`
  - render invocation changes from custom generator mode to the default Antora generator plus extensions
- `site-content/site.template.yaml`
  - search becomes an Antora extension
  - upstream-required Asciidoctor extensions remain explicit build inputs
- generated `site.yaml`
  - extension wiring changes, but visible command entrypoints remain the same
- `run.sh` and `README.md`
  - command surface stays the same
  - documented dependency stack and troubleshooting notes need to reflect Antora 3
- local workzone preview contract
  - preview should mirror upstream-required extensions so workzone rendering remains representative

## Required Test Plan

The subtask implementation should require these command checks:

```bash
./run.sh website container
./run.sh website build
./run.sh website build -g -u cassandra:/path/to/cassandra -b cassandra:trunk,cassandra-5.0,cassandra-4.1
./run.sh website preview
./run.sh website docs -u cassandra:/path/to/cassandra -b cassandra:trunk
```

Manual validation is required for:

- tabs rendering
- explicit-xref resolution
- generated-doc pages
- version selector contents
- search results
- unchanged `stable` / `latest` behavior
- unchanged published directory layout

## Decision Log

Fixed decisions for this infra track:

1. "Latest" means the current stable/LTS docs build stack, not opportunistic upgrades of every dependency in the image.
2. The Asciidoctor target follows the supported Antora 3.1 line, not standalone Asciidoctor 3.
3. The Antora 3 search path is the default target even though `@antora/lunr-extension` is currently alpha; if maintainers reject that package, that becomes an explicit blocker.
4. Cassandra 6 version-wire work stays separate from this infra upgrade.
5. The workzone preview stack must be treated as invalid if it does not declare the same required extensions as upstream.

## Risks And Blockers

- Search is the biggest technical dependency because the current upstream render path is built around an Antora 2 custom generator.
- Antora 3 xref rules may expose latent content issues that did not fail under Antora 2.
- Cassandra’s generated-doc path must keep working across multiple branches and JDK choices; this must be validated, not assumed.
- The local repo instruction file `RTK.md` was referenced but not present in this workspace during planning, so this document does not incorporate any additional local rules from that file.

## Source Basis

Primary inputs used to derive this plan:

- `backlog/upstream-migration-plan.md`
- `research/current-state.md`
- `runbooks/build-preview-publish.md`
- `runbooks/cassandra6-version-wireup.md`
- `research/publishing-model.md`
- workzone `package.json`, `package-lock.json`, and `antora-playbook.yml`
- upstream `apache/cassandra-website` `README.md`, `run.sh`, `site-content/Dockerfile`, `site-content/docker-entrypoint.sh`, `site-content/site.template.yaml`, `site-content/lib/tabs-block.js`
- Antora 3.1 upgrade and Asciidoctor upgrade documentation
