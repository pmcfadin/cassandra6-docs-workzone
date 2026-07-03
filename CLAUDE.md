# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A phase-1 research and operations workspace for Apache Cassandra 6 documentation. This is **not** a docs-authoring repo yet — it is a public incubation environment for planning, researching, and eventually drafting Cassandra 6 docs before content migrates into `apache/cassandra` and `apache/cassandra-website`.

## Authoritative Sources

- **Product truth**: `apache/cassandra` repo, branch `trunk` (switch to `cassandra-6.0` once it exists publicly)
- **Publish/render truth**: `apache/cassandra-website` repo, `trunk`
- JIRA descriptions, `NEWS.txt`, and `CHANGES.txt` are discovery aids, **not** source of truth — always validate against the repo
- Blog posts, wiki content, forum answers, and third-party guides are excluded by default

## Workspace Structure

| Directory | Purpose |
|---|---|
| `research/change-catalog/` | Per-JIRA research files for Cassandra 6 changes (one file per change) |
| `research/delta-catalog/` | Docs-to-docs diff reports between `cassandra-5.0` and `trunk` |
| `inventory/` | `docs-map.csv` page tracker and generated-vs-authored classification |
| `runbooks/` | Build/preview/publish, governance/review, version wire-up procedures |
| `backlog/` | Epics, subtasks, execution readiness, ownership map |
| `llm/` | Source-pack policy, prompt pack, review gates |
| `tcm/` | Transactional Cluster Metadata (TCM) documentation drafts |
| `docs/` | Workzone spec |
| `future/` | IA proposals, website design prototypes, comparative research |

## Skills

This project has 7 specialized skills. **Use the appropriate skill instead of working from scratch.**

| Task | Skill to invoke |
|---|---|
| General Cassandra docs work, repo selection, review gates | `cassandra-doc` |
| Discover changes from NEWS.txt/CHANGES.txt, triage, delegate research | `cassandra-changelog-triage` |
| Research a specific JIRA against the repo, produce change-catalog entry | `cassandra-researcher` |
| Compare docs between cassandra-5.0 and trunk branches | `cassandra-delta-catalog` |
| Merge catalogs into docs-map.csv, assign dispositions and writing slices | `cassandra-inventory-reconciliation` |
| Draft AsciiDoc content with Antora structure and audience-first IA | `cassandra-asciidoc-authoring` |
| Build, preview, validate, or publish docs locally or to GitHub Pages | `cassandra-antora-preview` |

## Key Rules

- Every normative claim requires a source link or source-pack reference
- Label inferences explicitly as inferences
- Never invent defaults, compatibility guarantees, upgrade semantics, or command behavior
- Generated docs surfaces must stay separate from authored prose
- AI-assisted content must be defensible for source provenance per ASF generative tooling guidance
- Do not draft final docs prose in research artifacts — research extracts facts and docs consequences, drafting is a separate phase

## Research Workflow Summary

Two parallel research tracks feed into the docs inventory:

1. **Change catalog** → use `cassandra-changelog-triage` to discover and triage, then `cassandra-researcher` per JIRA
2. **Delta catalog** → use `cassandra-delta-catalog` to compare branches

Both merge via `cassandra-inventory-reconciliation` into `inventory/docs-map.csv` which assigns each page a disposition: `unchanged`, `minor-update`, `major-update`, `new`, `generated-review`, or `remove`.

Drafting uses `cassandra-asciidoc-authoring`. Build and preview uses `cassandra-antora-preview`.

## Useful Research Commands

```bash
# Compare docs between 5.0 and trunk
git diff --name-status origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/ test/

# List trunk docs pages
git ls-tree -r --name-only origin/trunk -- doc/modules/cassandra/pages

# Show a specific file on trunk
git show origin/trunk:path/to/file

# Search the Cassandra repo for a term
rg "term" /path/to/cassandra/repo
```

These commands target a local clone of `apache/cassandra`.
