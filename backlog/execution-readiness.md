# Execution Readiness

Capture date: **2026-03-24**

## Purpose
This document closes the planning phase by turning the research package into an implementation-ready program plan for Apache Cassandra 6 documentation work.

Use it as the single handoff document for:
- fixed planning decisions
- remaining maintainer decisions
- phase order
- entry and exit criteria
- immediate next actions

## Readiness Status
Planning is sufficiently complete to start execution, with two conditions:

1. Create the umbrella and slice-level JIRAs before broad content production starts.
2. Finish the page-level inventory and owner assignment before drafting major content slices.

This means the workspace is ready for implementation kickoff, but not yet ready for unconstrained parallel authoring.

## Fixed Decisions
These decisions are already supported by the planning package and should be treated as the default execution path unless maintainers explicitly override them.

### 1. Execute Cassandra 6 docs as a tracked program
- Use one umbrella JIRA plus slice-level JIRAs.
- Treat Cassandra 6 docs as substantial change work, not typo-fix flow.
- Require explicit docs, technical, and staging review for material slices.

Evidence:
- `runbooks/governance-review-and-staging.md`
- `research/asf-governance.md`

### 2. Use `trunk` as the default Cassandra 6 discovery branch until `cassandra-6.0` exists
- Do research, inventory, and early drafting against `trunk`.
- Switch the default branch reference to `cassandra-6.0` once that branch is public.
- Do not redesign the workflow when that branch appears; only swap the default branch.

Evidence:
- `README.md`
- `research/publishing-model.md`
- `runbooks/cassandra6-version-wireup.md`

### 3. Separate authored docs from generated docs
- Narrative and explanatory pages follow editorial review.
- Generated config, protocol, and nodetool surfaces follow regeneration and provenance review first.
- No AI drafting should proceed against generated surfaces until regeneration has been rerun for the target branch.

Evidence:
- `inventory/generated-vs-authored.md`
- `runbooks/build-preview-publish.md`
- `llm/source-pack-policy.md`

### 4. Use audience-based information architecture as the target content model
- Target top-level user groups:
  - `Operators`
  - `Developers`
  - `Contributors`
  - `Reference`
- Treat this as the target structure even if the first implementation pass lands incrementally.

Evidence:
- `future/audience-information-architecture.md`
- `future/proposals.md`

### 5. Treat Proposal 1 as the default implementation path
- Keep AsciiDoc and Antora.
- Reduce contributor friction in workflow, preview, version routing, and review ownership.
- Treat larger platform migrations as future work unless maintainers explicitly choose otherwise.

Evidence:
- `future/proposals.md`
- `future/comparative-research.md`

## Decisions Still Required From Maintainers
These are the remaining decisions that should be made early in execution because they affect scope, staffing, or rollout timing.

1. Who will act as:
   - docs lead
   - technical review owners for upgrade, configuration, and operations
   - docs tooling owner for generated surfaces
   - website/publish owner for version wire-up
2. Whether Cassandra 6 docs should land as:
   - incremental module-by-module updates, or
   - one coordinated release-doc push near branch cut
3. When the `cassandra-6.0` branch becomes the default working branch.
4. Whether the audience-first IA is:
   - execution target only for Cassandra 6 pages, or
   - the start of a broader site restructure
5. Whether to formalize `OWNERS`-style review routing in-repo during this cycle or defer it.

## Execution Sequence

## Phase 0: Kickoff And Governance
### Goal
Create the review and tracking structure before content production starts.

### Actions
1. Open the umbrella JIRA for the Cassandra 6 docs program.
2. Open slice-level JIRAs for:
   - page inventory and disposition
   - generated-doc validation
   - website version wire-up
   - major content slices by area
   - staging and publish cutover
3. Assign reviewer roles using the ownership map.
4. Publish the planning summary and execution model to the public project review trail where appropriate.

### Exit criteria
- Umbrella JIRA exists.
- Slice-level JIRAs exist for the initial workstreams.
- Reviewer roles are assigned.
- The execution model is visible to maintainers and reviewers.

## Phase 1: Inventory And Ownership
### Goal
Finish deciding what each page needs before drafting starts.

### Actions
1. Expand `inventory/docs-map.csv` from high-level coverage to full page coverage.
2. Classify each page as:
   - unchanged
   - minor-update
   - major-rewrite
   - new
   - merge-split
   - remove
   - generated-needs-review
3. Assign an owner role for every page or page group.
4. Identify Cassandra 6 trunk-only pages and link them to the relevant slice JIRAs.

### Exit criteria
- Every in-scope page has one row in `inventory/docs-map.csv`.
- Every row has a disposition and owner role.
- Generated surfaces are explicitly separated.
- Trunk-only Cassandra 6 pages are captured.

## Phase 2: Change Discovery And Research
### Goal
Turn raw Cassandra 6 change signals into validated, docs-relevant research artifacts.

### Actions
1. Use `NEWS.txt` as the primary discovery list for user-visible changes.
2. Use `CHANGES.txt` to identify the related JIRAs and additional candidate changes.
3. Create one file per meaningful change under `research/change-catalog/`.
4. Validate each change against:
   - current docs
   - config
   - generated surfaces
   - implementation or tests when needed
5. Record audience, docs impact, and likely affected pages before drafting starts.

### Exit criteria
- High-value Cassandra 6 changes have per-change research files.
- Each researched change has a preliminary docs impact assessment.
- Low-value internal changes have been triaged out explicitly instead of silently ignored.

## Phase 3: Generated Docs Validation
### Goal
Lock the machine-derived reference surfaces before editorial drafting moves ahead.

### Actions
1. Reconfirm generation provenance for:
   - `cass_yaml_file.adoc`
   - `managing/tools/nodetool/*.adoc`
   - `reference/native-protocol.adoc`
2. Validate branch-specific generation prerequisites.
3. Record regeneration expectations in the relevant slice JIRAs.
4. Mark generated surfaces as blocked until regeneration is complete for the target branch.

### Exit criteria
- Generated surfaces have explicit script provenance.
- Required generation prerequisites are documented.
- No generated surface is being edited as if it were hand-authored.

## Phase 4: Content Production
### Goal
Update Cassandra 6 content slice by slice under explicit review.

### Actions
1. Draft or revise content only after:
   - source-pack approval
   - inventory approval
   - slice-level disposition approval
2. Work by audience-oriented slices where possible:
   - Operators
   - Developers
   - Contributors
   - Reference
3. Route technical claims to the correct technical owner.
4. Keep AI-assisted work inside the review gates and provenance rules in `llm/`.

### Exit criteria
- Each content slice has citations, reviewer assignment, and disposition traceability.
- Generated and authored changes remain separated.
- No unresolved technical blockers remain hidden inside draft prose.

## Phase 5: Cassandra 6 Version Wire-Up
### Goal
Make the site capable of publishing Cassandra 6 cleanly.

### Actions
1. Confirm the `cassandra-6.0` branch state.
2. Update Cassandra-side version metadata when the branch exists.
3. Update website branch inputs, alias logic, and major-version metadata.
4. Validate local render behavior before staging.

### Exit criteria
- All version touchpoints named in `runbooks/cassandra6-version-wireup.md` are addressed.
- `stable`, `latest`, and `trunk` resolve to the intended release states in staged validation.

## Phase 6: Staging And Publish Cutover
### Goal
Promote Cassandra 6 docs without alias mistakes or publish regressions.

### Actions
1. Validate staged output.
2. Record staging signoff.
3. Promote only after explicit maintainer approval.
4. Run post-publish checks against production URLs.

### Exit criteria
- Stage approval checklist passes.
- Production URLs and version selector behavior are correct.
- No supported older version aliases are broken.

## Dependency Rules
- Do not start broad drafting before Phase 1 is complete.
- Do not treat raw `NEWS.txt` or `CHANGES.txt` entries as draft-ready facts without Phase 2 validation.
- Do not approve generated reference changes before Phase 2 is complete.
- Do not switch the default source pack branch before `cassandra-6.0` exists publicly.
- Do not stage version-wire changes without a website/publish owner involved.
- Do not promote staged Cassandra 6 docs without explicit validation of `stable`, `latest`, and `trunk`.

## Immediate Next Actions
These are the next actions that should happen in order.

1. Create the umbrella JIRA and initial slice-level JIRAs.
2. Assign named reviewer roles from `backlog/ownership-map.md`.
3. Finish the full page-level expansion of `inventory/docs-map.csv`.
4. Start the per-change research catalog using `NEWS.txt` and `CHANGES.txt`.
5. Mark generated surfaces as separate work items with regeneration blockers.
6. Confirm whether a public `cassandra-6.0` branch exists before any version-wire implementation starts.
7. Start content work with the highest-value operator and upgrade slices, not with raw reference pages.

## Implementation Start Checklist
Execution should not be declared "started" until all items below are true.

- Umbrella JIRA exists.
- Initial slice-level JIRAs exist.
- Docs lead is named.
- Technical review owners are named for upgrade, configuration, and operations.
- Website/publish owner is named.
- Generated-doc owner is named.
- `inventory/docs-map.csv` is expanded to full page coverage.
- Generated surfaces are explicitly flagged and blocked on regeneration.
- The branch-transition rule is acknowledged by maintainers.
- AI source-pack and review-gate rules are accepted for any AI-assisted drafting.

## Done Criteria For Planning
Planning is complete when:
- no major implementation task requires rediscovering governance
- no major implementation task requires rediscovering version-wire scope
- ownership and review routing are explicit
- drafting can begin with known source, review, and staging rules

That threshold is now met, subject to the implementation start checklist above.
