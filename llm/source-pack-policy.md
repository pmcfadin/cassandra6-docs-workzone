# Source Pack Policy

Capture date: **2026-03-24**

## Purpose
Use LLMs as bounded drafting and analysis tools, not as authoritative sources for Cassandra behavior.

## Default Source Pack
Until `cassandra-6.0` exists publicly, the default source pack is:

| repo | branch | path | class | allowed_use | excluded |
| --- | --- | --- | --- | --- | --- |
| `apache/cassandra` | `trunk` | `doc/` | product-doc-source | inventory, diff, drafting, citation | no |
| `apache/cassandra` | `trunk` | `conf/cassandra.yaml` | config-source | generated-doc validation, factual lookup | no |
| `apache/cassandra` | `trunk` | `doc/scripts/` | generation-source | provenance, workflow, review | no |
| `apache/cassandra` | `trunk` | `build.xml` | build-source | generation prerequisites, JDK assumptions | no |
| `apache/cassandra-website` | `trunk` | `README.md` | website-runbook | build/publish runbook, command lookup | no |
| `apache/cassandra-website` | `trunk` | `run.sh` | website-build-source | command behavior, option lookup | no |
| `apache/cassandra-website` | `trunk` | `site-content/` | site-versioning-source | version wiring, alias rules, metadata | no |
| live site | `2026-03-24 snapshot` | `/doc/stable`, `/doc/latest`, `/doc/trunk` | observation-source | current-state verification | no |

## Manifest Format
Use this manifest shape whenever a source pack is documented or handed to an agent:

`repo,branch,path,class,allowed_use,excluded`

Example:

```text
apache/cassandra,trunk,doc/,product-doc-source,"inventory,diff,drafting",false
```

## Allowed Inputs
- Cassandra source repo docs and build files.
- Cassandra website repo build and publish files.
- Generated-doc scripts and generated outputs for the target branch.
- Release notes, accepted CEPs, and merged implementation artifacts when they are directly relevant and branch-aligned.
- Live site pages only for current-state verification, not as replacement for branch source.

## Excluded By Default
- Blog posts.
- Retired wiki content.
- Forum answers, random tutorials, or third-party guides.
- Unmerged design proposals.
- Old screenshots or copied prose without a current branch reference.
- Stale contributor instructions unless cross-checked against repo state.

## Citation Rules
- Every normative claim must include a source link or a source-pack entry reference.
- If a statement is an inference, label it as inference and cite the inputs that support it.
- If a claim cannot be cited from the approved source pack, it cannot be promoted into a draft as fact.
- Generated outputs may be cited only after regeneration for the target branch.

## Safety Rules
- Never let the model decide compatibility guarantees, upgrade semantics, or defaults without direct evidence.
- Never let the model invent version wiring or publishing behavior.
- Never use AI output as a substitute for running generation/build/preview steps.
- Use the narrowest source pack that answers the task.
- Keep ASF generative tooling guidance in scope: contributors remain responsible for provenance, licensing, and disclosure of AI-assisted material. Source: [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).

## ASF AI Governance Note
- AI-assisted documentation is allowed, but ASF guidance applies to docs as well as code.
- When AI materially contributes to a change, record that use in the review trail and prefer adding a `Generated-by:` style note in commit metadata when project practice allows.
- Do not merge AI-assisted content that cannot be defended for source provenance and licensing.

## Branch Transition
- Replace `trunk` with `cassandra-6.0` as the default source-pack branch once the public branch exists.
- Keep all other source-pack rules unchanged unless the upstream tooling changes.
