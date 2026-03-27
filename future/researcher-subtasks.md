# Researcher Subtasks For Future Cassandra Docs Scenarios

Subtask template:

`objective,inputs,method,deliverable,reviewer,acceptance_criteria`

## Track 1: Current Process Decomposition
- Objective: prove exactly which parts of the current workflow are contributor friction versus required ASF governance.
  Inputs: `research/current-state.md`, `runbooks/build-preview-publish.md`, `runbooks/governance-review-and-staging.md`, `research/publishing-model.md`.
  Method: map each current step to one of: authoring need, generation need, staging need, release need, accidental complexity.
  Deliverable: `future/current-process-decomposition.md`.
  Reviewer: docs lead plus website maintainer.
  Acceptance criteria: every current step is classified and accidental complexity is explicit.

- Objective: define an audience-based information architecture for Cassandra docs.
  Inputs: current docs inventory, current navigation model, page areas in `doc/modules/cassandra/pages/`, and the proposed future user groups.
  Method: classify every major docs area under `Operators`, `Developers`, `Contributors`, or `Reference`; call out mixed pages that need splitting.
  Deliverable: `future/audience-information-architecture.md`.
  Reviewer: docs lead plus technical owner.
  Acceptance criteria: every major docs area has a primary audience and all ambiguous sections have a proposed disposition.

## Track 2: Proposal 1 Validation
- Objective: prototype a simplified Antora-first workflow from the Cassandra repo.
  Inputs: current Cassandra `doc/` tree, website build scripts, Antora docs.
  Method: design a proof-of-concept `preview`, `check`, and `versions.yaml` flow without changing ASF publish governance.
  Deliverable: `future/prototype-antora-lite.md`.
  Reviewer: docs tooling owner.
  Acceptance criteria: one-command preview, one declarative version manifest, and a clear publish handoff are demonstrated.

- Objective: identify every hardcoded version and alias touchpoint that Proposal 1 would eliminate.
  Inputs: `research/publishing-model.md`, website repo build and entrypoint files.
  Method: trace current branch, alias, and metadata decisions into a future manifest schema.
  Deliverable: `future/version-manifest-design.md`.
  Reviewer: website maintainer.
  Acceptance criteria: no version-routing decision remains implicit.

## Track 3: Proposal 2 Validation
- Objective: estimate the cost of moving authored docs from AsciiDoc to Markdown or MDX.
  Inputs: current Cassandra docs tree, navigation files, representative pages from each major docs area.
  Method: sample-convert pages with cross-references, includes, admonitions, tabs, and generated references; record breakage classes.
  Deliverable: `future/asciidoc-to-markdown-migration-study.md`.
  Reviewer: docs lead.
  Acceptance criteria: migration blockers, automatable conversions, and manual rewrite classes are quantified.

- Objective: design a Docusaurus import path for generated reference docs.
  Inputs: `inventory/generated-vs-authored.md`, generation scripts, Superset and Docusaurus examples.
  Method: compare static import, generated MDX, and JSON-fed reference rendering approaches.
  Deliverable: `future/docusaurus-generated-docs-options.md`.
  Reviewer: docs tooling owner plus technical owner.
  Acceptance criteria: one preferred generated-docs architecture is named with tradeoffs.

## Track 4: Proposal 3 Validation
- Objective: define the cleanest split between narrative docs and generated reference docs in a hybrid system.
  Inputs: current docs inventory, generated-doc inventory, GitLab automation examples, VitePress or Starlight docs.
  Method: classify Cassandra pages into narrative, reference, mixed, and generated-only buckets, then map narrative pages under `Operators`, `Developers`, or `Contributors`.
  Deliverable: `future/hybrid-information-architecture.md`.
  Reviewer: docs lead plus technical owner.
  Acceptance criteria: every major docs area has a destination in the hybrid model and every narrative area has a primary audience home.

- Objective: design machine-readable outputs for agent consumption.
  Inputs: `llm/source-pack-policy.md`, `llm/review-gates.md`, Next.js `llms.txt`, ASF generative tooling guidance.
  Method: draft `llms.txt`, docs version manifest, and source-provenance metadata shapes appropriate for Cassandra.
  Deliverable: `future/agent-facing-artifacts.md`.
  Reviewer: docs operations owner plus committer.
  Acceptance criteria: the artifact set is useful to agents without weakening human review or ASF governance.

## Track 5: Contribution Experience
- Objective: redesign the first-time contributor path for docs-only changes.
  Inputs: current Cassandra contributor guidance, Kubernetes docs contributor flow, Astro docs contribution flow.
  Method: write a future-state path for typo fix, single-page edit, multi-page edit, and generated-doc change.
  Deliverable: `future/contributor-journeys.md`.
  Reviewer: community lead.
  Acceptance criteria: each contributor journey has fewer required concepts than today and still reaches the correct review gates.

- Objective: design user journeys for Operators and Developers, not just contributors.
  Inputs: current docs inventory, representative task flows, and the proposed audience model.
  Method: map the top 10 operator tasks and top 10 developer tasks to future landing pages, navigation hubs, and reference handoffs.
  Deliverable: `future/user-journeys.md`.
  Reviewer: docs lead plus community lead.
  Acceptance criteria: operator and developer users can reach core tasks from the future top-level navigation in fewer steps than today.

- Objective: specify review ownership for docs areas.
  Inputs: current docs structure, maintainer expectations, Kubernetes `OWNERS` pattern.
  Method: propose `OWNERS`-style or equivalent review metadata for docs sections and generated surfaces.
  Deliverable: `future/review-routing.md`.
  Reviewer: docs lead plus PMC sponsor.
  Acceptance criteria: every docs area has a named review path and generated surfaces have a tooling owner.

## Track 6: LLM And AI Governance
- Objective: draft an ASF-compatible AI-assisted docs contribution policy for Cassandra.
  Inputs: ASF generative tooling guidance, Python generative AI guidance, OpenInfra AI policy, local `llm/` files.
  Method: convert existing source-pack and review-gate rules into contributor policy language.
  Deliverable: `future/ai-assisted-docs-policy.md`.
  Reviewer: PMC sponsor plus docs lead.
  Acceptance criteria: provenance, disclosure, source-grounding, reviewer duties, and rejection cases are explicit.

- Objective: design review automation that catches common AI-era failure modes.
  Inputs: current CI/build checks, generated-doc workflow, local `llm/review-gates.md`, GitLab docs testing patterns.
  Method: define checks for missing citations, stale generated outputs, changed version aliases, and oversized style churn.
  Deliverable: `future/ai-era-review-automation.md`.
  Reviewer: build owner plus docs operations owner.
  Acceptance criteria: the proposed checks would catch uncited normative claims, stale generated reference pages, and unsafe version routing changes.

## Track 7: Recommendation Package
- Objective: convert proposal analysis into a recommendation suitable for PMC discussion.
  Inputs: all `future/` research outputs.
  Method: compare proposals on migration risk, contributor UX, governance fit, generated-doc integrity, and long-term maintainability.
  Deliverable: `future/recommendation-for-pmc.md`.
  Reviewer: project owner.
  Acceptance criteria: the document names a preferred path, a fallback path, and the irreversible decisions to defer.
