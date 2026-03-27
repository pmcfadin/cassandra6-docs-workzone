# Subtasks

Subtask template:

`objective,inputs,method,deliverable,reviewer,acceptance_criteria`

## Track 1: Current-State Evidence Pack
- Objective: document governance and approval flow.
  Inputs: `CONTRIBUTING.md`, `development/patches.adoc`, `development/documentation.adoc`, website README.
  Method: extract JIRA expectations, review model, committer role, and staging/publish approvals.
  Deliverable: `runbooks/governance-review-and-staging.md`.
  Reviewer: docs lead plus committer.
  Acceptance criteria: JIRA, PR review, staging validation, and publish approval responsibilities are explicit.

- Objective: verify current live version behavior.
  Inputs: live `stable`, `latest`, `trunk` URLs; website build files.
  Method: compare live URLs to alias logic in `site-content/docker-entrypoint.sh`.
  Deliverable: updated `research/publishing-model.md`.
  Reviewer: docs ops owner.
  Acceptance criteria: live behavior and alias rules match or any mismatch is explicitly documented.

- Objective: validate current local build commands.
  Inputs: `cassandra-website/README.md`, `run.sh`.
  Method: extract supported command paths and options.
  Deliverable: updated `runbooks/build-preview-publish.md`.
  Reviewer: docs tooling owner.
  Acceptance criteria: all documented commands exist in current tooling.

## Track 2: Content Inventory
- Objective: expand inventory from page areas to full page coverage.
  Inputs: `trunk` docs tree, `cassandra-5.0` docs tree.
  Method: enumerate `.adoc` pages, then classify by comparison to 5.0.
  Deliverable: expanded `inventory/docs-map.csv`.
  Reviewer: docs lead.
  Acceptance criteria: every in-scope page has one row and one disposition.

- Objective: identify new `trunk` pages likely to be Cassandra 6 additions.
  Inputs: `trunk` and `cassandra-5.0` trees.
  Method: branch diff on `doc/modules/cassandra/pages/`.
  Deliverable: new-page list linked from the inventory.
  Reviewer: technical docs owner.
  Acceptance criteria: all trunk-only pages are captured and cited.

## Track 3: Change Discovery And Research
- Objective: turn `NEWS.txt` into a docs-relevant candidate list.
  Inputs: `NEWS.txt`, current docs inventory, `cassandra-5.0` comparison target.
  Method: extract user-visible features, upgrade notes, and operational changes likely to need docs.
  Deliverable: initial entries in `research/change-catalog/` and `research/change-catalog/index.md`.
  Reviewer: docs lead plus technical owner.
  Acceptance criteria: major user-visible Cassandra 6 changes have a research file and preliminary docs impact.

- Objective: mine `CHANGES.txt` for additional JIRA-backed docs-impacting changes.
  Inputs: `CHANGES.txt`, current docs inventory, source tree diff.
  Method: triage entries into docs-relevant vs low-value internal changes, then create one research file per retained change.
  Deliverable: expanded `research/change-catalog/` coverage.
  Reviewer: technical docs owner.
  Acceptance criteria: docs-impacting JIRAs are cataloged and low-value internal items are triaged explicitly.

## Track 4: Generated Docs
- Objective: prove provenance for generated outputs.
  Inputs: `doc/Makefile`, generation scripts, `.gitignore`, built outputs if available.
  Method: map each generated output to the script and upstream source that produce it.
  Deliverable: updated `inventory/generated-vs-authored.md`.
  Reviewer: docs tooling owner.
  Acceptance criteria: each generated surface has a script path and evidence link.

- Objective: document regeneration prerequisites by branch.
  Inputs: `build.xml`, `docker-entrypoint.sh`.
  Method: capture JDK and build expectations for generated-doc runs.
  Deliverable: add branch-specific notes to `runbooks/build-preview-publish.md`.
  Reviewer: build owner.
  Acceptance criteria: required JDK and generation path are explicit for the target branch.

## Track 5: Cassandra 6 Version Wire-Up
- Objective: list all Cassandra repo edits needed for 6.0 docs.
  Inputs: `trunk/doc/antora.yml`, `cassandra-5.0/doc/antora.yml`.
  Method: compare release-branch vs prerelease metadata.
  Deliverable: Cassandra repo section in `runbooks/cassandra6-version-wireup.md`.
  Reviewer: Cassandra maintainer.
  Acceptance criteria: no Cassandra-side version metadata decisions remain ambiguous.

- Objective: list all website repo edits needed for 6.0 docs.
  Inputs: `site-content/Dockerfile`, `site-content/docker-entrypoint.sh`, `site-content/site.template.yaml`.
  Method: trace branch list, alias logic, and major-version metadata.
  Deliverable: website repo section in `runbooks/cassandra6-version-wireup.md`.
  Reviewer: website maintainer.
  Acceptance criteria: every hardcoded major-version touchpoint is named.

## Track 6: LLM Workflow
- Objective: lock approved source-pack rules.
  Inputs: research docs, generation provenance, branch policy.
  Method: reduce allowed inputs to an auditable default set.
  Deliverable: `llm/source-pack-policy.md`.
  Reviewer: docs lead plus technical owner.
  Acceptance criteria: uncited normative claims are explicitly forbidden.

- Objective: standardize AI tasks for inventory, diff, drafting, and review.
  Inputs: approved source pack, inventory schema, review gates.
  Method: write bounded prompts with required outputs and constraints.
  Deliverable: `llm/prompt-pack.md`.
  Reviewer: docs operations owner.
  Acceptance criteria: prompts are reusable without re-deciding guardrails.

## Track 7: Consolidation
- Objective: define phase order and readiness criteria.
  Inputs: all prior track outputs.
  Method: collapse findings into epics, dependencies, and done criteria.
  Deliverable: `backlog/epics.md`, `backlog/execution-readiness.md`.
  Reviewer: project owner.
  Acceptance criteria: execution can begin without additional planning work and the implementation start checklist is explicit.

- Objective: maintain the branch-transition rule.
  Inputs: current discovery default, future `cassandra-6.0` branch availability.
  Method: update source-pack and inventory defaults when the release branch appears.
  Deliverable: synchronized updates across README, runbooks, and source-pack policy.
  Reviewer: docs lead.
  Acceptance criteria: the workspace can swap from `trunk` to `cassandra-6.0` without process redesign.

- Objective: define reviewer-role routing and execution ownership.
  Inputs: governance runbook, generated-doc inventory, version-wire runbook, content inventory.
  Method: map workstreams and docs areas to role-based ownership and required review paths.
  Deliverable: `backlog/ownership-map.md`.
  Reviewer: docs lead plus committer sponsor.
  Acceptance criteria: every execution track has a named review path before drafting starts.
