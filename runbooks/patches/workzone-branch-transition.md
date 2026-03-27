# Workzone Branch Transition Patch

Capture date: **2026-03-27**

## Purpose

This document is a pre-planned coordinated patch to execute when the `cassandra-6.0` branch becomes publicly available in `apache/cassandra`. It lists every workzone file that references `trunk` as the Cassandra 6 discovery source and specifies the exact text substitutions required.

**No workflow redesign is introduced.** Only branch name references change.

## Trigger Condition

Execute this patch when `cassandra-6.0` is publicly available in `apache/cassandra` and is confirmed as the intended release-doc source for the Cassandra 6.0 release. Do not execute speculatively.

Verification step before executing: `git ls-remote https://github.com/apache/cassandra refs/heads/cassandra-6.0` must return a SHA.

## Scope Boundaries

This patch targets `trunk` references that mean **the Cassandra 6 source branch in `apache/cassandra`**. It does not touch:

- References to `apache/cassandra-website` trunk — that repo's default branch name is independent and does not change with this patch.
- Generic git/development concepts (e.g., "merge to trunk", "trunk-based development") — these do not change.
- Historical observation records (e.g., `research/current-state.md` records of the live site at capture date, `research/publishing-model.md` descriptions of the current alias mapping including `trunk → 5.1`) — these document what existed at a point in time and should remain accurate to that moment.
- Change-catalog `Source branch` metadata fields — these record what branch was used during the research phase and are historically correct as-is.
- Delta-catalog `Branches compared` metadata — these record the actual branches diffed and should not be retroactively changed.

## Execution: Single Coordinated Commit

All substitutions below are to be applied in a single commit with the message:

```
chore: switch default Cassandra 6 discovery branch from trunk to cassandra-6.0

Triggered by public availability of cassandra-6.0 in apache/cassandra.
No workflow changes. Branch name substitution only.
```

---

## Files Requiring Substitution

### 1. `CLAUDE.md`

**Line 11** — Authoritative Sources, product truth entry:

| | Text |
|---|---|
| Current | `- **Product truth**: \`apache/cassandra\` repo, branch \`trunk\` (switch to \`cassandra-6.0\` once it exists publicly)` |
| New | `- **Product truth**: \`apache/cassandra\` repo, branch \`cassandra-6.0\`` |

**Line 21** — Workspace Structure table, delta-catalog row:

| | Text |
|---|---|
| Current | `\| \`research/delta-catalog/\` \| Docs-to-docs diff reports between \`cassandra-5.0\` and \`trunk\` \|` |
| New | `\| \`research/delta-catalog/\` \| Docs-to-docs diff reports between \`cassandra-5.0\` and \`cassandra-6.0\` \|` |

**Line 39** — Skills table, cassandra-delta-catalog row:

| | Text |
|---|---|
| Current | `\| Compare docs between cassandra-5.0 and trunk branches \| \`cassandra-delta-catalog\` \|` |
| New | `\| Compare docs between cassandra-5.0 and cassandra-6.0 branches \| \`cassandra-delta-catalog\` \|` |

**Lines 68, 71, 74** — Useful Research Commands code block:

| | Text |
|---|---|
| Current (line 68) | `git diff --name-status origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/ test/` |
| New | `git diff --name-status origin/cassandra-5.0..origin/cassandra-6.0 -- doc/ conf/ src/ test/` |
| Current (line 71) | `git ls-tree -r --name-only origin/trunk -- doc/modules/cassandra/pages` |
| New | `git ls-tree -r --name-only origin/cassandra-6.0 -- doc/modules/cassandra/pages` |
| Current (line 74) | `git show origin/trunk:path/to/file` |
| New | `git show origin/cassandra-6.0:path/to/file` |

---

### 2. `README.md`

**Line 6** — Defaults section, discovery source:

| | Text |
|---|---|
| Current | `- Authoritative Cassandra 6 discovery source: [\`apache/cassandra\` \`trunk\`](https://github.com/apache/cassandra/tree/trunk) until a public \`cassandra-6.0\` branch exists.` |
| New | `- Authoritative Cassandra 6 discovery source: [\`apache/cassandra\` \`cassandra-6.0\`](https://github.com/apache/cassandra/tree/cassandra-6.0).` |

**Line 33** — Operating Rules, rule 5:

| | Text |
|---|---|
| Current | `5. Replace \`trunk\` with \`cassandra-6.0\` as the default discovery branch once that branch exists, without changing the rest of the process.` |
| New | `5. Use \`cassandra-6.0\` as the default discovery branch, without changing the rest of the process.` |

---

### 3. `researcher.md`

**Line 8** — Default branch instruction:

| | Text |
|---|---|
| Current | `- Default branch: \`trunk\`, unless told to use \`cassandra-6.0\`` |
| New | `- Default branch: \`cassandra-6.0\`` |

---

### 4. `llm/source-pack-policy.md`

**Lines 9–16** — Default Source Pack section header and `apache/cassandra` rows:

| | Text |
|---|---|
| Current (line 9) | `Until \`cassandra-6.0\` exists publicly, the default source pack is:` |
| New | `The default source pack is:` |
| Current (lines 13–16) | Four rows with `\| \`apache/cassandra\` \| \`trunk\` \|` |
| New | Replace `trunk` with `cassandra-6.0` in those four rows only. The three `apache/cassandra-website` rows on lines 17–19 do not change. |

Specific row substitutions (lines 13–16):

```
| `apache/cassandra` | `cassandra-6.0` | `doc/` | product-doc-source | inventory, diff, drafting, citation | no |
| `apache/cassandra` | `cassandra-6.0` | `conf/cassandra.yaml` | config-source | generated-doc validation, factual lookup | no |
| `apache/cassandra` | `cassandra-6.0` | `doc/scripts/` | generation-source | provenance, workflow, review | no |
| `apache/cassandra` | `cassandra-6.0` | `build.xml` | build-source | generation prerequisites, JDK assumptions | no |
```

**Line 67** — Branch Transition section:

| | Text |
|---|---|
| Current | `- Replace \`trunk\` with \`cassandra-6.0\` as the default source-pack branch once the public branch exists.` |
| New | `- Default source-pack branch is now \`cassandra-6.0\`. This transition was executed when \`cassandra-6.0\` became publicly available.` |

---

### 5. `runbooks/cassandra6-version-wireup.md`

**Line 46** — Branch-Transition Rule:

| | Text |
|---|---|
| Current | `- Until \`cassandra-6.0\` exists publicly, use \`trunk\` as the Cassandra 6 discovery source for research and drafting.` |
| New | `- \`cassandra-6.0\` is now the default Cassandra 6 discovery source for research and drafting.` |

**Line 47** — Branch-Transition Rule, second bullet:

| | Text |
|---|---|
| Current | `- Once \`cassandra-6.0\` exists, update this workspace's default source pack and inventory comparison target from \`trunk\` to \`cassandra-6.0\`.` |
| New | `- This workspace's default source pack and inventory comparison target have been updated from \`trunk\` to \`cassandra-6.0\`.` |

Note: Lines 14–15 (`Dockerfile`, `docker-entrypoint.sh` source links) reference `apache/cassandra-website` trunk URLs — those do not change. Line 29 (`trunk becomes the next prerelease alias`) and line 35 (`Stabilize Cassandra 6 source docs on trunk`) describe upstream `apache/cassandra-website` behavior and the original Cassandra 6 trunk stabilization step — these are factual descriptions of the release timeline and do not change. Line 52 (`Live trunk remains prerelease`) is an acceptance check about the live website routing state and does not change.

---

### 6. `backlog/execution-readiness.md`

**Lines 35–36** — Section heading "Use `trunk` as the default Cassandra 6 discovery branch":

| | Text |
|---|---|
| Current (line 35) | `### 2. Use \`trunk\` as the default Cassandra 6 discovery branch until \`cassandra-6.0\` exists` |
| New | `### 2. Use \`cassandra-6.0\` as the default Cassandra 6 discovery branch` |
| Current (line 36) | `- Do research, inventory, and early drafting against \`trunk\`.` |
| New | `- Do research, inventory, and early drafting against \`cassandra-6.0\`.` |

Note: Line 131 (`Identify Cassandra 6 trunk-only pages`) describes a completed or in-progress inventory task using "trunk" as shorthand for the historical discovery context — this is a task description, not a branch pointer to update. Lines 211 and 234 refer to the live website's `trunk` URL alias (the prerelease docs URL), not the `apache/cassandra` branch name — these do not change.

---

### 7. `backlog/subtasks.md`

**Lines 31, 37–38** — Subtask input descriptions referencing the `trunk` docs tree as the Cassandra 6 source:

| | Text |
|---|---|
| Current (line 31) | `  Inputs: \`trunk\` docs tree, \`cassandra-5.0\` docs tree.` |
| New | `  Inputs: \`cassandra-6.0\` docs tree, \`cassandra-5.0\` docs tree.` |
| Current (line 37) | `- Objective: identify new \`trunk\` pages likely to be Cassandra 6 additions.` |
| New | `- Objective: identify new \`cassandra-6.0\` pages that are Cassandra 6 additions.` |
| Current (line 38) | `  Inputs: \`trunk\` and \`cassandra-5.0\` trees.` |
| New | `  Inputs: \`cassandra-6.0\` and \`cassandra-5.0\` trees.` |

Note: Line 16 (`live stable, latest, trunk URLs`) refers to the live website's URL paths — not a branch name. Line 117 (`the workspace can swap from trunk to cassandra-6.0`) is a now-satisfied acceptance criterion for this very transition task — leave it as historical record or remove it; do not change the wording to make it false.

---

### 8. `backlog/implementation-tasklist.md`

Lines with `apache/cassandra` repo, `trunk` source references that describe the Cassandra 6 discovery source (lines 46–47, 53, 69, 128, 178, 199, 361, 394, 419–420, 443, 468, 492, 513, 539–540, 564, 586, 608, 649, 697–698, 718, 739, 767):

All occurrences of the pattern `` `apache/cassandra` repo, branch `trunk` `` and `` `apache/cassandra` repo, `trunk` `` (where `apache/cassandra` is the product repo, not cassandra-website) should be updated to use `cassandra-6.0`.

The pattern to replace: `` `apache/cassandra` repo, `trunk` `` → `` `apache/cassandra` repo, `cassandra-6.0` ``
The pattern to replace: `` `apache/cassandra` repo, branch `trunk` `` → `` `apache/cassandra` repo, branch `cassandra-6.0` ``

Lines 788–790 reference `apache/cassandra-website` repo, `trunk` — these do not change.

Line 797 (`Patch includes a note about what trunk alias should become`) describes an upstream publish alias concern, not a branch name reference in this workzone — leave as-is.

Line 828 (`Multiple workzone files reference trunk as the default branch`) is the problem statement for this very task — leave as historical record.

---

### 9. `llm/prompt-pack.md`

**Line 32** — Delta comparison task description:

| | Text |
|---|---|
| Current | `You are comparing Cassandra 5.0 docs to Cassandra 6 source material on trunk.` |
| New | `You are comparing Cassandra 5.0 docs to Cassandra 6 source material on cassandra-6.0.` |

---

### 10. `docs/workzone-spec.md`

**Line 174** — Research Inputs list:

| | Text |
|---|---|
| Current | `- \`apache/cassandra\` \`origin/trunk\`` |
| New | `- \`apache/cassandra\` \`origin/cassandra-6.0\`` |

**Lines 420, 424** — Git command examples in the delta research section:

| | Text |
|---|---|
| Current (line 420) | `git diff --name-status origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/ test/` |
| New | `git diff --name-status origin/cassandra-5.0..origin/cassandra-6.0 -- doc/ conf/ src/ test/` |
| Current (line 424) | `git log --oneline origin/cassandra-5.0..origin/trunk -- doc/ conf/ src/` |
| New | `git log --oneline origin/cassandra-5.0..origin/cassandra-6.0 -- doc/ conf/ src/` |

**Lines 432, 436** — Git command examples for listing and viewing files:

| | Text |
|---|---|
| Current (line 432) | `git ls-tree -r --name-only origin/trunk -- doc/modules/cassandra/pages` |
| New | `git ls-tree -r --name-only origin/cassandra-6.0 -- doc/modules/cassandra/pages` |
| Current (line 436) | `git show origin/trunk:path/to/file` |
| New | `git show origin/cassandra-6.0:path/to/file` |

**Line 496** — Reference to `origin/trunk` as a research source:

| | Text |
|---|---|
| Current | `- \`origin/trunk\`` |
| New | `- \`origin/cassandra-6.0\`` |

**Line 543** — Delta research step:

| | Text |
|---|---|
| Current | `1. Compare \`origin/cassandra-5.0\` vs \`origin/trunk\` under \`doc/\`.` |
| New | `1. Compare \`origin/cassandra-5.0\` vs \`origin/cassandra-6.0\` under \`doc/\`.` |

Note: Line 183 (`Use cassandra-6.0 instead of trunk once that branch exists`) is a transition instruction that will be satisfied by this patch — remove or reword it to record that the transition has been made.

---

### 11. `inventory/docs-map.csv`

The `current_version` and `comparison_target` columns currently set `trunk` as the version value on every row.

- `current_version` column: replace all occurrences of `trunk` with `cassandra-6.0`.
- `comparison_target` column: these values are `cassandra-5.0` — no change needed.

This is a bulk substitution. The CSV has approximately 130+ rows. Use a single sed or scripted replacement:

```bash
sed -i 's/,trunk,/,cassandra-6.0,/g' inventory/docs-map.csv
```

Verify after: `grep -c 'cassandra-6.0' inventory/docs-map.csv` should match the row count; `grep -c ',trunk,' inventory/docs-map.csv` should return 0.

---

### 12. `content/IMPORT-MANIFEST.md`

**Line 4** — Source declaration:

| | Text |
|---|---|
| Current | `**Source:** \`apache/cassandra\` repo, branch \`trunk\`` |
| New | `**Source:** \`apache/cassandra\` repo, branch \`cassandra-6.0\`` |

Note: Line 5 records the specific commit SHA (`bf755d0ade706904d7b35bf41b04f64c7e0afe17`) that was actually used for the page import. This SHA is a historical fact about what was imported and should be preserved. If the import is re-run against `cassandra-6.0`, update the SHA to match that run's HEAD.

---

### 13. `research_promp.md`

**Line 6** — Default branch for discovery:

| | Text |
|---|---|
| Current | `- Default branch for Cassandra 6 discovery: \`trunk\`, unless a public \`cassandra-6.0\` branch exists.` |
| New | `- Default branch for Cassandra 6 discovery: \`cassandra-6.0\`.` |

---

## Files Confirmed Out of Scope

The following files contain `trunk` references that do not change with this patch:

| File | Reason not changed |
|---|---|
| `llm/review-gates.md` line 15 | "New pages discovered only on `trunk`" is a historical statement about the discovery phase; it describes what was observed, not a current branch pointer |
| `runbooks/governance-review-and-staging.md` lines 59, 64 | References to `apache/cassandra-website` trunk and to `trunk` as the live prerelease URL alias |
| `runbooks/build-preview-publish.md` | Any `trunk` references there describe website publish chain behavior, not the `apache/cassandra` source branch |
| `research/current-state.md` | Dated observation pack captured at a specific point in time; changing these would make the record false |
| `research/publishing-model.md` | Describes live site state at capture date, including `trunk → 5.1` alias and live `trunk` URL |
| `research/asf-governance.md` | `trunk` references are GitHub URLs citing `CONTRIBUTING.md` on the actual trunk branch for historical reference |
| `research/delta-catalog/*.md` | `Branches compared` metadata records what was actually diffed; historically accurate |
| `research/change-catalog/*/` | `Source branch: trunk` records what branch was used during the research phase; historically accurate |
| `backlog/epics.md` lines 12, 40 | Line 12 describes a completed phase task. Line 40 is the decision point for this transition — leave as executed record |
| `backlog/execution-readiness.md` lines 211, 234 | Refer to the live website `trunk` URL path, not the `apache/cassandra` branch |

---

## Post-Execution Verification

After applying the patch:

1. Search for remaining `origin/trunk` references in non-historical files: `grep -r "origin/trunk" --include="*.md" --include="*.csv" .`
2. Confirm `inventory/docs-map.csv` has no remaining `trunk` values in `current_version`.
3. Confirm `llm/source-pack-policy.md` table shows `cassandra-6.0` for all four `apache/cassandra` rows.
4. Confirm `CLAUDE.md` Authoritative Sources section no longer contains the parenthetical switch instruction.
5. Run Antora build if `content/` was re-imported: `npx antora antora-playbook.yml`.
