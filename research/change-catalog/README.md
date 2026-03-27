# Change Catalog

Capture date: **2026-03-24**

## Purpose
This directory is the preliminary research layer for Cassandra 6 docs work.

Use it to break the `NEWS.txt` and `CHANGES.txt` streams into one markdown file per meaningful change so each change can be:
- understood on its own terms
- validated against source and implementation
- linked to the right docs pages
- reused later during drafting and review

This catalog sits between raw release-change discovery and page-level docs authoring.

## Why This Exists
`NEWS.txt` is useful for identifying high-value changes that likely require docs.
`CHANGES.txt` is useful for enumerating JIRA-backed changes, but it is too noisy to draft from directly.

The practical problem is that many Cassandra 6 changes will require preliminary technical research before anyone can decide:
- whether the change needs docs
- which audience it affects
- which existing pages it changes
- whether it is authored or generated content
- what evidence is strong enough to support a docs update

This directory solves that by making each change a small research artifact first.

## Working Rule
Create one markdown file per change candidate that survives initial triage.

Good candidates include:
- features called out in `NEWS.txt`
- JIRAs in `CHANGES.txt` that appear user-visible
- upgrade, compatibility, operational, security, CQL, tooling, or configuration changes
- generated-doc affecting changes

Do not create files for every low-level performance or internal refactor item unless it has likely docs impact.

## Suggested Filename Format
Use:

`CASSANDRA-<jira>-<short-slug>.md`

Examples:
- `CASSANDRA-20897-role-name-generation.md`
- `CASSANDRA-20941-nodetool-compressiondictionary.md`
- `CASSANDRA-17021-zstd-dictionary-compression.md`

If a `NEWS.txt` item maps to multiple JIRAs, either:
- create one file for the primary JIRA and list the others inside, or
- create a grouped topic file if the docs impact is better treated as one feature

## Minimal Workflow
1. Triage `NEWS.txt` into likely docs-impact topics.
2. Use `CHANGES.txt` to find the related JIRA IDs.
3. Create one file from `template.md` for each selected change.
4. Validate the change against actual Cassandra repo evidence:
   - docs tree
   - config
   - generated docs
   - implementation or tests when needed
5. Record:
   - summary
   - user-facing impact
   - docs impact
   - evidence
   - unresolved questions
6. Only then map the change to page-level work in `inventory/docs-map.csv`.

## Triage Heuristic
Prioritize changes that affect:
- upgrade paths
- new features
- removed or deprecated behavior
- cluster operations
- security or identity
- configuration
- CQL or schema behavior
- nodetool or operational tooling
- generated reference surfaces

Deprioritize changes that are:
- purely internal refactors
- micro-optimizations with no user-facing operational guidance
- test-only changes
- implementation cleanups with no product or operator effect

## Output Quality Bar
Each change file should be good enough that a docs author can answer:
- what changed
- who it affects
- where it belongs in the docs
- whether more technical review is needed

If that is still unclear, the file is still in research, not ready for drafting.
