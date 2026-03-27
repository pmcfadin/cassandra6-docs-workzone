# Epics

## Epic 1: Current-State Evidence Pack
- Reverse-engineer the current authoring, generation, build, preview, staging, and publish workflow.
- Capture the current governance path for JIRA, PR review, committer action, and staging approval.
- Capture hardcoded versioning touchpoints in `apache/cassandra-website`.
- Validate live site behavior against upstream build logic.
- Exit criteria: research and runbooks are source-linked, dated, and internally consistent.

## Epic 2: Content Inventory And Disposition
- Expand `inventory/docs-map.csv` from page areas to full page coverage.
- Compare `trunk` against `cassandra-5.0`.
- Classify every page as unchanged, minor-update, major-rewrite, new, merge-split, or remove.
- Exit criteria: every in-scope page has an owner, disposition, and evidence reference.

## Epic 3: Change Discovery And Research
- Use `NEWS.txt` and `CHANGES.txt` to build the Cassandra 6 change candidate list.
- Create one research file per meaningful change or JIRA-backed feature under `research/change-catalog/`.
- Validate docs-relevant changes against source, config, generated docs, and implementation evidence.
- Exit criteria: high-value changes have a docs-impact assessment before drafting starts.

## Epic 4: Generated Docs Track
- Isolate generated docs and their provenance.
- Validate regeneration steps and branch-specific prerequisites.
- Prevent AI drafting from running ahead of generated outputs.
- Exit criteria: generated surfaces have explicit evidence and review owners.

## Epic 5: Cassandra 6 Version Wire-Up
- Define all changes required to add `6.0` to the site version matrix.
- Cover Cassandra branch metadata, website branch inputs, alias-copy logic, and major-version labels.
- Exit criteria: a maintainer can implement Cassandra 6 version wiring without discovering new scope midstream.

## Epic 6: LLM Workflow And Governance
- Finalize source-pack rules, prompt pack, and review gates.
- Define handoff rules between AI drafting and human review.
- Exit criteria: AI work is bounded, reproducible, and auditable.

## Epic 7: Consolidation And Execution Readiness
- Produce final roadmap, ownership map, and acceptance checklist.
- Decide when to switch default discovery from `trunk` to `cassandra-6.0`.
- Publish the implementation start checklist and reviewer-role map.
- Exit criteria: the team can start docs implementation with no planning blockers.
