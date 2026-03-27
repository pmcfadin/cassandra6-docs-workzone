# Cassandra 6 Docs Research Ops Workspace

This workspace is a phase-1 research and operations package for planning Apache Cassandra 6 documentation work. It is intentionally not a docs-authoring repo yet.

## Defaults
- Authoritative Cassandra 6 discovery source: [`apache/cassandra` `trunk`](https://github.com/apache/cassandra/tree/trunk) until a public `cassandra-6.0` branch exists.
- Current render and publish system: [`apache/cassandra-website` `trunk`](https://github.com/apache/cassandra-website/tree/trunk).
- Current-state observations in this workspace were captured on **2026-03-24** from the live site and current upstream repos.

## What This Workspace Contains
- `research/current-state.md`: dated evidence pack for authoring, generation, build, and publish flow.
- `research/asf-governance.md`: ASF-wide rules that constrain docs governance, AI use, and official website publication.
- `research/publishing-model.md`: current version routing, aliases, and hardcoded major-version touchpoints.
- `research/change-catalog/`: per-change research files derived from `NEWS.txt`, `CHANGES.txt`, and source validation.
- `runbooks/build-preview-publish.md`: exact current build, preview, staging, and publish path.
- `runbooks/governance-review-and-staging.md`: JIRA, review, committer, staging, and publish governance.
- `runbooks/cassandra6-version-wireup.md`: what has to change to introduce Cassandra 6 cleanly.
- `inventory/docs-map.csv`: initial page-area inventory and comparison tracker.
- `inventory/generated-vs-authored.md`: generated vs hand-authored doc surfaces.
- `llm/source-pack-policy.md`: allowed inputs, exclusions, and citation rules.
- `llm/prompt-pack.md`: bounded prompts for inventorying, diffing, drafting, and review.
- `llm/review-gates.md`: mandatory human checkpoints for AI-assisted work.
- `backlog/epics.md`: phased execution roadmap.
- `backlog/subtasks.md`: agent-ready subtasks and acceptance criteria.
- `backlog/execution-readiness.md`: final planning handoff with fixed decisions, phase order, and implementation start checklist.
- `backlog/ownership-map.md`: reviewer-role map and recommended JIRA slicing for execution.

## Operating Rules
1. Treat Cassandra code and release branches as the product-doc source of truth.
2. Treat `cassandra-website` as the render/publish orchestrator and website-content owner.
3. Regenerate machine-derived docs before asking an LLM to draft prose about them.
4. Require source links for every normative claim in planning outputs and future drafts.
5. Replace `trunk` with `cassandra-6.0` as the default discovery branch once that branch exists, without changing the rest of the process.

## How To Use This Workspace
1. Read [`research/current-state.md`](research/current-state.md), [`research/asf-governance.md`](research/asf-governance.md), and [`research/publishing-model.md`](research/publishing-model.md) to ground yourself in both ASF-wide and Cassandra-specific rules.
2. Read [`runbooks/governance-review-and-staging.md`](runbooks/governance-review-and-staging.md) before opening or reviewing substantial docs work.
3. Use [`runbooks/cassandra6-version-wireup.md`](runbooks/cassandra6-version-wireup.md) before proposing any Cassandra 6 site-version changes.
4. Use [`inventory/docs-map.csv`](inventory/docs-map.csv) as the working tracker for page review and disposition.
5. Apply the rules in [`llm/source-pack-policy.md`](llm/source-pack-policy.md) and [`llm/review-gates.md`](llm/review-gates.md) before using AI for drafting or analysis.
6. Execute work in the order defined in [`backlog/epics.md`](backlog/epics.md).
7. Use [`backlog/execution-readiness.md`](backlog/execution-readiness.md) as the start-of-execution handoff.

## Immediate Next Steps
- Create the umbrella JIRA and initial slice-level JIRAs.
- Assign named owners for docs lead, technical review, generated-doc review, and website/publish review.
- Expand `inventory/docs-map.csv` from page areas to full page coverage before broad drafting starts.
- Verify whether any public Cassandra `cassandra-6.0` branch exists before version-wire implementation begins.
