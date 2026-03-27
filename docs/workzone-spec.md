# Cassandra 6 Docs Workzone Spec

Capture date: **2026-03-26**

## Purpose
This document defines what the Cassandra 6 docs workzone is, what it is intended to produce, how it should be structured, how research should be done, and how work should move from research into draft documentation and eventually into the authoritative Apache Cassandra documentation repositories.

This spec is for a **public workzone** dedicated to creating and proving out Cassandra 6 documentation before selected content is migrated into:
- `apache/cassandra`
- `apache/cassandra-website`

## Working Position
The workzone is not just a scratch repo and not just a preview host.

It has four roles:
1. Public workzone for Cassandra 6 docs planning, research, and drafting.
2. Antora-compatible source repo for proposed Cassandra 6 docs content and information architecture.
3. Preview host for a rendered review build published through GitHub Pages.
4. Migration staging area for content and structure that will later move into the real Cassandra docs system.

## Goals
The workzone exists to:
- research Cassandra 6 changes in a repeatable and source-grounded way
- prove a better information architecture for Cassandra docs
- draft AsciiDoc content in a format close to the eventual production target
- publish an unofficial review preview for maintainers and reviewers
- reduce migration cost by keeping the work Antora- and AsciiDoc-compatible from the start

## Non-Goals
The workzone does not replace:
- the Apache Cassandra source repo as product-doc source of truth
- the Apache Cassandra website repo as official render/publish orchestrator
- ASF staging and production publication flow

The workzone preview is not:
- the official Cassandra docs site
- the final Apache staging environment
- a substitute for committer review or ASF publish controls

## Source Of Truth
Authoritative sources remain:
- `apache/cassandra` for product documentation sources, configuration, code, generated-doc inputs, and implementation evidence
- `apache/cassandra-website` for current render/publish orchestration and official website publication behavior

The workzone may contain drafts, summaries, and previews, but it does not become authoritative for product behavior simply by existing.

## Repository Intent
The workzone repo should be treated as a public incubation repo for Cassandra 6 docs work.

It should contain:
- research artifacts
- planning artifacts
- AsciiDoc draft content
- Antora configuration for preview builds
- documentation IA experiments
- migration notes
- automation or scripts required to build or validate the preview

It should not become:
- a second source of truth for Cassandra behavior
- a dumping ground for unsourced text
- a permanent fork of the Cassandra docs system

## Authoring Model
Use:
- AsciiDoc
- Antora-compatible structure

The reason is migration cost:
- content written in AsciiDoc is far easier to migrate into `apache/cassandra/doc/`
- Antora-compatible structure makes navigation and module concepts easier to port later
- this keeps the workzone close to the existing Cassandra docs ecosystem instead of inventing a separate content system

## Preview Model
The preview build should:
- render the full workzone site as static HTML
- publish to GitHub Pages
- bypass Jekyll by publishing static output directly and using `.nojekyll` where needed

The preview is:
- unofficial
- for review only
- a place to show the proposed information architecture and draft content direction

It should be clearly labeled:
- `Preview`
- `Unofficial`
- `For review only`

The preview should not be presented as the official Cassandra docs site.

## Official Publish Boundary
GitHub Pages preview is acceptable as a review environment.
Official project publication still happens through the ASF-controlled Cassandra website flow and staging process.

The expected lifecycle is:
1. research and draft in the workzone
2. render and review in the workzone preview
3. migrate approved content into `apache/cassandra` and related website changes into `apache/cassandra-website`
4. validate through ASF staging
5. publish through the official Apache flow

## Information Architecture Direction
The workzone should demonstrate and test an audience-first documentation structure.

Target top-level audiences:
- `Operators`
- `Developers`
- `Contributors`
- `Reference`

This should shape both:
- the preview site navigation
- the placement of draft content in the repo

The workzone is where the new IA is proven in rendered form before corresponding changes are proposed upstream.

## Content Categories
Treat content as one of:
- authored narrative docs
- generated reference surfaces
- cross-cutting navigation or metadata
- research artifacts

Generated surfaces must remain separate from authored prose. The workzone may plan or validate generated docs, but should not casually rewrite machine-derived outputs as if they were hand-authored pages.

## Recommended Repo Structure
The repo should evolve toward a structure like:

```text
docs/
  workzone-spec.md
research/
  change-catalog/
  delta-catalog/
inventory/
  docs-map.csv
runbooks/
future/
backlog/
site/ or antora/ or preview/   # Antora playbook / site scaffolding when added
drafts/ or content/            # Antora-compatible AsciiDoc content for the preview
```

The exact build directories may vary, but the separation should remain:
- research and planning
- draft content
- build configuration
- published preview output

## Migration Principle
Anything authored in the workzone should be either:
- directly migratable into Cassandra docs, or
- explicitly marked as exploratory

That means:
- use Cassandra terminology
- keep claims source-grounded
- avoid placeholder prose that cannot survive review
- prefer module/page structures that can later map into `doc/modules/...`

## Research System
Research in the workzone is a formal, multi-stage process.
It is not “read NEWS.txt and start writing.”

There are two core research tracks:
1. **Change research**
2. **Docs delta research**

Both are required before broad drafting begins.

## Research Inputs
The default input set for Cassandra 6 research is:
- `apache/cassandra` `origin/trunk`
- `apache/cassandra` `origin/cassandra-5.0`
- `NEWS.txt`
- `CHANGES.txt`
- current docs under `doc/`
- configuration under `conf/`
- generated-doc scripts under `doc/scripts/`
- build metadata such as `build.xml`

Use `cassandra-6.0` instead of `trunk` once that branch exists publicly and becomes the intended release-doc branch.

## Research Evidence Hierarchy
When researching documentation changes, not all sources carry the same weight.

Use this evidence hierarchy:

1. **Authoritative implementation evidence**
   - source code
   - `conf/cassandra.yaml`
   - `doc/`
   - parser grammars
   - CLI command implementations
   - build and generation scripts
   - tests that demonstrate behavior
2. **Strong project-authored discovery signals**
   - `NEWS.txt`
   - `CHANGES.txt`
   - accepted CEPs
   - merged PR discussion where needed
3. **Supporting issue context**
   - JIRA descriptions
   - JIRA comments
   - linked PRs
4. **Non-authoritative or excluded material**
   - blog posts
   - stale wiki text
   - random tutorials
   - forum answers

Working rule:
- JIRA and changelog text can tell us **where to look**
- code, config, docs, tests, and generated-doc inputs tell us **what is true**

## How Research Extracts Docs-Relevant Information
Research is not just a page diff and not just a JIRA summary.
It is an extraction process that converts implementation changes into documentation decisions.

The core research question for each change is:

`What changed in the product, how can we prove it from the repo, and what documentation consequence follows from that?`

To answer that, researchers must extract information from:
- code structure
- configuration surfaces
- parser/grammar changes
- CLI and nodetool command definitions
- tests and test fixtures
- JIRA and PR context

## Code-First Extraction Method
For every meaningful change, the first pass should identify the implementation surfaces that could affect docs.

### 1. Find the implementation entry points
Examples:
- new command class under `src/java/org/apache/cassandra/tools/nodetool/`
- new config fields in `src/java/org/apache/cassandra/config/Config.java`
- new parser grammar in CQL parser files
- new or changed schema/property handling in statement classes
- new feature package under `src/java/org/apache/cassandra/...`

Questions to answer:
- what new class or package exists?
- what user-facing names appear in code?
- what configuration keys or CLI flags were added?
- what old names or behaviors were removed or deprecated?

### 2. Extract user-facing surfaces from implementation
Researchers should explicitly pull out:
- command names
- flags and options
- config keys
- default values
- type names
- statement syntax
- table properties
- virtual table names
- metrics/MBean names
- system keyspaces/tables

These are the raw facts that later become docs content.

### 3. Identify behavioral consequences
After finding the surfaces, determine:
- what a user can now do
- what a user can no longer do
- what changed operationally
- what changed during upgrade or migration
- what changed for developers or operators

The goal is to move from:
- “class X was added”
to:
- “operators now have command Y with flags Z”

## Configuration Extraction Method
Configuration research should always compare:
- what exists in `Config.java` or related spec/binding classes
- what exists in `conf/cassandra.yaml`
- what exists in current docs

This reveals:
- undocumented config keys
- stale defaults
- deprecated settings still documented
- settings present in code but absent from yaml
- settings in yaml but not represented in generated docs yet

Researchers should capture for each config-related change:
- key name
- default
- type or allowed values
- whether it is present in yaml comments
- whether it appears in generated config docs
- operational meaning

## CQL And Syntax Extraction Method
For CQL and query-language changes, always inspect:
- grammar or parser files
- statement implementation classes
- current CQL docs and BNF/example files

Extract:
- exact new syntax
- supported forms
- restrictions
- examples implied by tests or implementation
- whether the syntax is already documented in:
  - reference pages
  - BNF files
  - monolithic CQL reference

This is how we detect cases such as:
- syntax implemented but not documented
- syntax listed in `changes.adoc` but missing from per-topic docs

## CLI And Nodetool Extraction Method
For command-line and nodetool changes, inspect:
- command registration points
- command classes
- help/usage output shape
- doc generation scripts

Extract:
- command name
- subcommands
- flags/options
- defaults
- whether the docs are authored or generated
- whether regeneration alone covers the delta

Important distinction:
- some command changes require authored docs updates
- some require only regeneration and validation of generated command reference pages

## Test-Driven Extraction Method
Tests are often the fastest way to understand intended behavior.

Use tests to extract:
- valid and invalid input examples
- precedence rules
- edge cases
- migration constraints
- expected error conditions
- runtime behavior that is difficult to infer from code alone

Tests are especially useful when:
- the code is generic but the user-facing behavior is subtle
- the feature adds warnings, failures, or validation logic
- upgrade or migration paths have guarded failure modes

Researchers should not treat tests as the only evidence, but they are often the clearest proof of behavior.

## JIRA And PR Extraction Method
JIRAs are supporting research inputs, not source of truth.

Use JIRA to extract:
- the problem statement
- intended user story
- related issues
- linked PRs
- terminology used by maintainers
- open questions or unresolved caveats

Use PRs to extract:
- scope of changed files
- reviewer concerns
- naming decisions
- whether maintainers considered something user-facing or internal

But always validate JIRA/PR claims against the repo before promoting them into docs research artifacts.

## Detailed JIRA Research Workflow
For a JIRA-backed feature or change:

1. Start from the JIRA ID and title.
2. Find the corresponding repo evidence:
   - changed source files
   - docs
   - config
   - tests
   - generation scripts
3. Extract the user-facing surfaces.
4. Determine whether the change is:
   - new feature
   - behavior change
   - deprecation/removal
   - generated-doc change
   - internal-only
5. Record the docs consequence:
   - new page
   - major update
   - minor update
   - generated review
   - no docs needed

This is the required method for all change-catalog work.

## Practical Research Questions
For each change, researchers should explicitly answer:
- What is the exact user-visible change?
- Which repo files prove it?
- Which audience does it affect?
- Is the affected docs surface authored or generated?
- Which existing docs pages should change?
- Is there already documentation on trunk?
- If yes, is it complete, partial, stale, or misplaced?
- What still needs to be written?

If the researcher cannot answer those questions, the research is not finished.

## Recommended Extraction Commands
Researchers should prefer direct repo inspection over broad speculation.

Useful commands include:

```bash
git diff --name-status origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/ test/
```

```bash
git log --oneline origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/
```

```bash
rg "setting_name|command_name|feature_term" /Users/patrick/local_projects/cassandra
```

```bash
git ls-tree -r --name-only origin/trunk -- doc/modules/cassandra/pages
```

```bash
git show origin/trunk:path/to/file
```

Use these to build evidence, not just summaries.

## Research Output Requirements
Every durable research artifact should preserve:
- discovery source
- repo evidence
- extracted user-facing surfaces
- docs impact
- unresolved questions

That means change and delta reports must not stop at “this changed.”
They must explain:
- how we know
- what docs consequence follows

## Research Completion Standard
Research is complete only when:
- the implementation evidence has been inspected
- the user-facing consequences have been extracted
- the docs impact is classified
- the result can be used to update `docs-map.csv` without redoing the investigation

## Research Track 1: Change Catalog
The change catalog answers:
- what changed in Cassandra 6
- which changes are actually doc-worthy
- who each change affects
- whether the work is authored or generated
- which pages are likely affected

Inputs:
- `NEWS.txt`
- `CHANGES.txt`
- relevant source, config, code, tests, and existing docs

Primary outputs:
- `research/change-catalog/index.md`
- one file per meaningful change under `research/change-catalog/`

Each change file should answer:
- what changed
- why it matters
- what evidence supports it
- what docs are affected
- what the likely disposition is

The change catalog is the product-change research layer.

## Research Track 2: Delta Catalog
The delta catalog answers:
- what changed between Cassandra 5.0 docs and trunk docs
- which pages were added, removed, or modified
- where trunk docs already contain Cassandra 6 documentation
- where generated surfaces require regeneration rather than prose edits

Inputs:
- `origin/cassandra-5.0`
- `origin/trunk`
- docs tree under `doc/modules/...`

Primary outputs:
- `research/delta-catalog/index.md`
- one report per docs area under `research/delta-catalog/`

The delta catalog is the docs-to-docs comparison layer.

## Why Both Research Tracks Exist
A plain docs diff is insufficient because:
- some product changes still lack docs
- some trunk docs are only partial
- some changes affect generated surfaces
- some new features already have docs on trunk and do not need fresh pages

A plain change catalog is also insufficient because:
- it does not show where docs already changed between 5.0 and trunk
- it does not reveal page structure or nav changes by itself

So the workzone research method is:

`product delta` + `docs delta` -> `page disposition` -> `drafting plan`

## Detailed Research Workflow

## Phase A: Initial Discovery
1. Read `NEWS.txt` to identify likely high-value Cassandra 6 changes.
2. Read `CHANGES.txt` to identify JIRA-backed changes and additional candidates.
3. Build the initial candidate list of user-visible or docs-relevant changes.

## Phase B: Per-Change Research
1. Create one file per retained change in `research/change-catalog/`.
2. Validate each change against:
   - docs
   - config
   - generated-doc inputs
   - implementation code
   - tests when needed
3. Classify:
   - audience
   - docs impact
   - authored vs generated
   - likely affected docs pages
4. Explicitly mark low-value internal changes as not doc-worthy.

## Phase C: Docs Delta Comparison
1. Compare `origin/cassandra-5.0` vs `origin/trunk` under `doc/`.
2. Partition comparison by docs area.
3. Record:
   - new pages on trunk
   - removed pages
   - major updates
   - minor updates
   - generated surfaces
4. Capture this in `research/delta-catalog/`.

## Phase D: Inventory Reconciliation
Merge the change-catalog and delta-catalog results into:
- `inventory/docs-map.csv`

Each page or page group should receive a disposition such as:
- `unchanged`
- `minor-update`
- `major-update`
- `new`
- `generated-review`
- `remove`

This is the bridge from research into authoring work.

## Phase E: Writing Slice Planning
Once `docs-map.csv` is updated:
1. group work into writing slices
2. assign owners/reviewers
3. separate authored work from generated work
4. prioritize operator-critical and release-critical content first

## Research Quality Rules
Research outputs must:
- be source-grounded
- cite repo evidence
- distinguish evidence from inference
- separate authored from generated content
- call out uncertainty clearly
- avoid turning JIRA titles into facts without source validation

Research outputs must not:
- invent behavior
- treat changelog text alone as authoritative
- assume trunk docs are complete just because pages exist

## Research Deliverables
The minimum durable artifacts are:
- `research/change-catalog/`
- `research/delta-catalog/`
- `inventory/docs-map.csv`

These together must be sufficient for a docs author to answer:
- what changed
- where it belongs
- whether it is already documented
- what still needs to be written

## Review And Governance Expectations
Even in the workzone:
- major decisions should still be fit for public ASF review later
- claims about Cassandra behavior must be defensible
- AI-assisted work must remain source-grounded and reviewable

The workzone is a public incubation environment, not a shortcut around governance.

## Build Expectations
The workzone should eventually support:
- local Antora build
- preview-ready static HTML output
- GitHub Pages publication of the built site

The build should render:
- the proposed IA
- draft Cassandra 6 pages
- nav and cross-links close to the intended future structure

## Preview Expectations
The preview site should be able to demonstrate:
- the top-level audience-first IA
- representative Cassandra 6 pages
- clear movement from current docs structure toward the proposed one
- enough fidelity that maintainers can review the direction, not just raw files

## Definition Of Done For The Workzone Phase
The workzone is successful when it provides:
- a credible research base for Cassandra 6 docs
- a rendered preview of the proposed IA and direction
- draft content written in migratable AsciiDoc
- a clear path for moving approved content upstream

## Immediate Next Steps For This Repo
1. Add the Antora-compatible draft content structure.
2. Add the Antora playbook and local build path.
3. Define the preview publish path to GitHub Pages.
4. Use the existing research outputs to drive `inventory/docs-map.csv`.
5. Start drafting the highest-priority Cassandra 6 content slices in AsciiDoc.
