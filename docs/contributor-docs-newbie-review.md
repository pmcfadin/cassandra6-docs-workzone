# Contributor Docs — Newbie Review: Compiled Issue List

Six agents read the contributor docs as genuine first-time contributors and reported back. This is the gatekeeper's compiled, prioritized issue list.

**Scope:** 44 AsciiDoc files across 10 sections  
**Reviewers:** 6 independent agents, each playing a role: no Cassandra experience, reading their section for the first time

---

## CRITICAL — Must Fix Before Publishing

These issues will cause new contributors to **give up, do it wrong, or lose trust in the docs**.

---

### C1. "Unresolved Questions" section is visible in `first-deep-contribution.adoc`

**File:** `orientation/first-deep-contribution.adoc` lines 219–224  
**Quote:** `"Does expert-discovery.adoc include a nodetool / tools subsystem entry? If not, the Step 6 guidance is incomplete. Confirm whether patch-classification.adoc exists at the xref path used above..."`  
**Issue:** A working draft section was left in the published page. Any newcomer who reaches it immediately distrusts everything they just read.  
**Fix:** Resolve all open questions and remove this section before the page goes live. Internal TODOs belong in a separate document, not in reader-facing prose.

---

### C2. No "before you start" prerequisites visible at the entry point

**Files:** `index.adoc`, `roadmap.adoc`, `contribution-ladder.adoc`  
**Issue:** Every path in the contributor docs (fix a bug, add a feature, learn the codebase) assumes you already have: a working local build, git, Java, and a signed Apache ICLA. None of this is called out before the newcomer picks a path. They can read for hours before discovering they're blocked.  
**Fix:** Add a prominent callout at the top of `index.adoc` — before "Find Your Path":

> **Do this first:**  
> 1. Clone the repo and build it locally → [Getting Started]  
> 2. Sign the Apache ICLA (takes 1–2 weeks to process) → [link]  
> 3. Join the dev mailing list → [link]  
> Then pick your path below.

Also: add ICLA timing guidance in `roadmap.adoc`: "Sign before you spend time on code — you can read and run tests while waiting, but you can't merge patches until it's processed."

---

### C3. JIRA is used everywhere but explained nowhere

**Files:** `roadmap.adoc`, `contribution-ladder.adoc`, `expert-discovery.adoc`, `first-deep-contribution.adoc`, `patch-review/patches.adoc`, `patch-review/index.adoc`  
**Issue:** Every orientation and patch doc references JIRA — "file a JIRA," "move to Patch Available," "assign yourself," "JIRA component" — without a single page explaining how to use it. Many newcomers have never used an ASF JIRA project.  
**Fix:** Create a short `orientation/jira-quickstart.adoc` page covering:
- How to create an account
- How to create a ticket (title format, components, labels)
- What "Patch Available" status means and how to set it
- How to assign yourself to a ticket
- How to link a GitHub PR to a ticket

Reference it from all orientation pages on first JIRA mention.

---

### C4. `dtest` (distributed tests) is used throughout but never defined

**Files:** `build-test/testing.adoc`, `build-test/debugging.adoc`, `patch-review/how_to_review.adoc`, `develop/feature-playbook.adoc`  
**Quote (feature-playbook):** `"Run dtests for any change that touches: Replication or coordinator logic..."`  
**Issue:** `dtest` appears in at minimum 4 separate pages as if the reader already knows it means "distributed test in a separate pytest-based repo." They don't.  
**Fix:** Define on first use in each section, and add a note to `build-test/testing.adoc`:

> Distributed tests (dtests) are integration tests that run against real multi-node clusters. They live in a **separate repository**: `apache/cassandra-dtest`. They use Python + pytest. See [setting up dtests] for clone/install instructions.

Also: add cassandra-dtest clone/setup instructions to `build-test/debugging.adoc` which references it in context (reproducing a dtest failure locally) without any setup path.

---

### C5. No example output or timing for any build/test command

**Files:** `build-test/gettingstarted.adoc`, `build-test/testing.adoc`, `build-test/debugging.adoc`, `build-test/profiling.adoc`  
**Issue:** Every major command (`ant`, `ant test -Dtest.name=...`, `.build/docker/run-tests.sh`) produces output that a newcomer has never seen. Without sample output they can't tell if the build is working, hung, or failed. No timing is given ("this takes ~5 minutes on a laptop"). Combined, this produces panic and abandonment.  
**Fix:** For each major command in Getting Started and Testing, show:
- Abbreviated sample success output
- Expected timing ("first build: ~5–10 min; subsequent: ~1–2 min")
- What "success" looks like at the end (`BUILD SUCCESSFUL` for ant)

---

### C6. `accord.adoc` is a stub with no explanation of why Accord exists

**File:** `architecture/accord.adoc`  
**Quote:** (entire file) `"Accord is one of the transaction protocols supported by Apache Cassandra... * xref:architecture/accord-architecture.adoc[] * xref:architecture/cql-on-accord.adoc[]"`  
**Issue:** The entry point page for Accord is 8 lines and two cross-references. A developer reading the architecture section hits this page and has no idea what problem Accord solves, how it differs from the eventual-consistency model in `dynamo.adoc`, or why Cassandra added it.  
**Fix:** Add at minimum a 3-paragraph overview to `accord.adoc`:
1. What problem Accord solves (multi-partition ACID transactions; Paxos LWT only supported single-partition conditional writes, not reads + multi-partition writes)
2. How it relates to Dynamo's model (Dynamo's LWW is not ACID; Accord adds a separate consensus layer)
3. What Cassandra 5/6 uses it for (explicit transaction blocks, LWT replacement)

---

## HIGH — Significant Barrier to Progress

These will slow down or confuse the majority of newcomers. Should be fixed in the same release as the critical items.

---

### H1. CHANGES.txt entry required but no example shown

**File:** `patch-review/patches.adoc`  
**Quote:** `"Include a CHANGES.txt entry at the top of the list"`  
**Issue:** Every patch that changes user-visible behavior needs a CHANGES.txt entry. No example of format, tone, or placement is shown. Contributors will open the file, stare at existing entries for 10 minutes, and still be unsure.  
**Fix:** Add a concrete example block:
```
# Good CHANGES.txt entry
- nodetool getlogginglevels output is now sorted alphabetically (CASSANDRA-12345)

# Too technical (don't)
- Replaced HashMap with TreeMap in LoggingTable.java (CASSANDRA-12345)
```
Clarify: entries go at the top of the file, in the current unreleased version section, one sentence, user-perspective, imperative tone.

---

### H2. "Patch Available" JIRA status is never explained

**Files:** `patch-review/index.adoc`, `patch-review/patches.adoc`  
**Issue:** Both files tell contributors to move a ticket to "Patch Available" but don't explain what this does, why reviewers need it, or how to set it. Contributors who skip this step will have patches sit unreviewed for weeks.  
**Fix:** Add inline explanation: "'Patch Available' signals reviewers that your code is ready. Without this status, your patch may be overlooked. To set it: open the JIRA ticket → click 'Submit Patch' → the status updates automatically."

---

### H3. SSTable architecture docs need byte-level diagrams throughout

**Files:** `sstable-architecture/data-format.adoc`, `sstable-architecture/read-path.adoc`, `sstable-architecture/write-path.adoc`, `sstable-architecture/fundamentals.adoc`  
**Issue:** These docs describe a spatial, byte-oriented format entirely in prose. Key missing visuals:
- `fundamentals.adoc`: SSTable file dependency graph (which files depend on which, write order)
- `data-format.adoc`: byte-level partition layout (header → static row → unfiltered sequence → EOP marker); non-frozen vs frozen collection cell layout
- `read-path.adoc`: BIG format read decision tree with concrete numbers; BTI trie node diagram
- `write-path.adoc`: Flush pipeline dependency diagram showing which steps are parallel

**Fix:** This is a high-effort item but high-impact. Five diagrams would transform these pages from academic to usable. Suggest using ASCII diagrams initially, replace with SVG for final publication.

---

### H4. Accord architecture assumes consensus protocol expertise

**File:** `architecture/accord-architecture.adoc`  
**Quote (line 1):** `"Readers should be closely familiar at very least with Single-Decree Paxos and fluent in Consensus terminology. Familiarity with... EPaxos, TAPIR, Janus, or Tempo, can be useful."`  
**Issue:** This is the primary technical reference for Cassandra 6's most significant new subsystem. The prerequisite bar (Paxos fluency) excludes most contributors. The document does not provide a path for those who don't meet it.  
**Fix:** Add: (1) a prerequisite reading list with links for Raft/Paxos concepts; (2) a sequence diagram showing the basic PreAccept → Accept → Commit round-trip with coordinator and replica messages labeled; (3) rewrite the CommandStore/SafeCommandStore section to explain the *problem being solved* before describing the abstraction.

---

### H5. `atomic push` failure recovery is missing from committer docs

**File:** `patch-review/how_to_commit.adoc`  
**Issue:** The commit workflow ends at `git push --atomic`. Nothing is said about what to do if it fails (it does fail, due to CI gates, upstream changes, or auth). Committers left hanging.  
**Fix:** Add a "If the push fails" section covering: (1) re-check CI status before retrying; (2) if upstream changed, rebase and re-run tests; (3) if it's an auth/permissions issue, contact the PMC.

---

### H6. CCM (Cassandra Cluster Manager) used without definition or installation steps

**Files:** `build-test/testing.adoc`, `build-test/debugging.adoc`  
**Issue:** `ccm list`, `ccm status`, `ccm node1 cqlsh` are used as if CCM is already installed. It is not part of the repo. A newcomer gets `command not found`.  
**Fix:** In `build-test/testing.adoc` on first use: "CCM (Cassandra Cluster Manager) manages local multi-node test clusters. Install: `pip install ccm`. Dtests use it automatically; you can also use it manually to inspect test clusters."

---

### H7. Live migration (Paxos → Accord) needs a state diagram

**File:** `architecture/cql-on-accord.adoc` lines 320–408  
**Issue:** The migration from Paxos to Accord is the most operationally significant aspect of Cassandra 6 upgrades. It's described in 90 lines of prose with no state diagram. Key barriers, phase transitions, and rollback behavior are impossible to follow without a visual.  
**Fix:** Add a state diagram showing: `[Paxos Only]` → `[Phase 1: dual writes, Paxos reads]` → `[Phase 2: Accord reads, key barrier active]` → `[Accord Only]`, with annotations on what triggers each transition.

---

### H8. async-profiler and cassandra-harry have no install/setup steps

**File:** `build-test/profiling.adoc`  
**Issue:** Both tools are used in code examples but neither has installation instructions. `profiler.sh` is called without saying where to get async-profiler.  
**Fix:** Add explicit install steps for async-profiler (clone + build from GitHub) and cassandra-harry (link to repo + basic usage). Show a sample flamegraph output description.

---

### H9. Test selection matrix uses internal package paths without explanation

**File:** `build-test/test-selection-matrix.adoc`  
**Quote:** `"All tests in org.apache.cassandra.io and org.apache.cassandra.db packages"`  
**Issue:** Newcomers don't know how to run "all tests in a package." The ant command isn't shown. The word "SSTable" in the matrix row has no explanation.  
**Fix:** Add below the matrix: "To run all tests in a package: `ant test -Dtest.name=org.apache.cassandra.io.*`. Test classes are in `test/unit/java/`." Also define SSTable inline: "SSTable = Sorted String Table, Cassandra's on-disk data format."

---

### H10. Generated-doc regeneration scripts are undocumented

**File:** `generated-docs/index.adoc`  
**Issue:** The page tells contributors to "regenerate generated docs when X" but never shows the actual commands. Newcomers who add a `cassandra.yaml` parameter will not know how to regenerate the reference page.  
**Fix:** Add a "How to Regenerate" section with actual command examples for each generator script, e.g.:
```bash
# Regenerate cassandra.yaml reference
doc/scripts/convert_yaml_to_adoc.py conf/cassandra.yaml > doc/modules/cassandra/pages/reference/cassandra-yaml.adoc

# Regenerate nodetool reference
doc/scripts/gen-nodetool-docs.py > doc/modules/cassandra/pages/reference/nodetool.adoc
```

---

## MEDIUM — Clarity and Completeness

These make the docs harder to use but won't stop a motivated contributor cold.

---

### M1. Contribution ladder lacks "where to find issues" guidance

**File:** `orientation/contribution-ladder.adoc` Rung 1  
**Issue:** Tells newcomers rung-1 work includes "fixing a typo" but doesn't say where to find typos to fix. Link to JIRA filters for `lhf` + `documentation` labels.

### M2. VInt table in `data-format.adoc` is incomplete ("and so on")

**Issue:** The VInt encoding table stops at 16,383 and says "and so on." Add the full range up to 9 bytes for a 64-bit value.

### M3. `how_to_review.adoc` checklist has no priority tiers

**Issue:** The review checklist is a flat wall of bullets. New reviewers don't know what's a showstopper vs. a suggestion. Add three tiers: Critical (must fix before +1), Important (should fix), Nice-to-have.

### M4. Token ring description in `dynamo.adoc` has a backwards explanation of vnodes

**File:** `architecture/dynamo.adoc` lines 94–103  
**Issue:** The explanation implies you need to insert 8 tokens to add a 9th node, which is the problem vnodes solve — not the solution. The causality is backwards.  
**Fix:** Rewrite the vnode introduction to first state the problem (single tokens → imbalance on adding nodes), then state the solution (multiple tokens per node → distributed load naturally).

### M5. `expert-discovery.adoc` conflates committer and PMC member roles

**Issue:** The definitions are too compressed; a newcomer will assume PMC members are the people they need to get a +1 from. Clarify: one committer +1 is sufficient for code to merge; PMC members make release and governance decisions.

### M6. `feature-playbook.adoc` doesn't explain who performs forward-merges

**Quote:** `"The merge order is always from older to newer: cassandra-4.1 -> cassandra-5.0 -> trunk"`  
**Issue:** Newcomers will try to manually merge their patch forward. They shouldn't — committers do this. Add: "Forward-merges are performed by the committer who merges your patch. You don't merge forward yourself."

### M7. `compatibility-checklist.adoc` uses "TCM version" and "guardrails" without definition

**Issue:** Both terms appear in checklist questions but are unexplained. A contributor can't answer a checklist question they don't understand. Add brief inline definitions (1 sentence each).

### M8. `operational-empathy.adoc` Quick Checklist asks to "estimate startup time" with no guidance on how

**Quote:** `"Startup time impact is estimated (new I/O, schema loading, etc.)"`  
**Issue:** "Estimated" is vague. Add: "Run startup with and without your change. Measure the difference. If startup time increases by more than 100ms, note it in the JIRA ticket."

### M9. SSTable version naming scheme is unexplained in `reference.adoc`

**Issue:** Format identifiers `mc`, `md`, `me`, `nb` are listed in the versioning matrix with no explanation of the naming convention. Add one sentence: "First letter = format family (m = BIG, n = BTI/NB). Second letter increments with each schema revision."

### M10. `release_process.adoc` omits release cadence

**Issue:** No mention of how often releases happen, who decides, or what criteria trigger a point release. Add a "Release Cadence" section.

### M11. `ci.adoc` doesn't distinguish Docker vs. non-Docker check-code.sh variants

**Issue:** Both scripts are listed without explaining when to use each. Add: Docker version = reproducible/isolated (use for final checks); non-Docker = faster iteration (use during development).

### M12. `architecture/index.adoc` is a link list with no orientation text

**Issue:** Newcomer arrives here with no sense of reading order. Add 2–3 sentences explaining Cassandra's core architectural pillars and which doc to read first.

### M13. Commit message format in `expert-discovery.adoc` is ambiguous about who fills in "reviewed by"

**Quote:** `"patch by <Author>; reviewed by <Reviewer> for CASSANDRA-#####"`  
**Issue:** Newcomers will leave "Reviewer" blank or write TBD. Clarify: the contributor writes their own name; the reviewer adds theirs when they approve, not before.

### M14. `how_to_commit.adoc` `git merge -s ours` is opaque

**Quote:** `"git merge cassandra-5.0 -s ours"`  
**Issue:** The `-s ours` strategy sounds like it discards the other branch's changes. Add: "This creates a merge commit but preserves trunk's tree entirely. The actual code from cassandra-5.0 comes from the `git apply` step — the merge commit is a history marker only."

### M15. Documentation index page doesn't explain local preview setup end-to-end

**File:** `documentation/index.adoc`  
**Issue:** Points to cassandra-website README without a walkthrough. Add 5-step instructions for hooking a local Cassandra fork into cassandra-website for local preview.

---

## QUICK WINS — Low Effort, High Value

These can be fixed in under 30 minutes each.

- **`build-test/gettingstarted.adoc`**: Add `java -version && javac -version` verification commands after prerequisites section.
- **`patch-review/code_style.adoc`**: Add good/bad import ordering example (shows correct grouping with blank lines).
- **`patch-review/code_style.adoc`**: Add the Apache License 2.0 header template for Java files (a newcomer needs to copy-paste something, not invent it).
- **`patch-review/patches.adoc`**: Clarify the "squash before merge" step — add `git rebase -i HEAD~N` instruction with when to use it.
- **`patch-review/patches.adoc`**: Resolve the ambiguity between GitHub PR and JIRA patch attachment — state which is preferred and when each is used.
- **`orientation/roadmap.adoc`**: Add ICLA timing note ("sign before coding; takes 1–2 weeks").
- **`build-test/test-selection-matrix.adoc`**: Resolve the "Preview | Unofficial | For review only" warning — either remove it or be specific about what's uncertain.
- **`build-test/profiling.adoc`**: Same — resolve the preview warning.
- **`build-test/debugging.adoc`**: Same — resolve the preview warning.
- **`internals/internals-map.adoc`**: Add a CQL transaction example near the Accord note (2-line `BEGIN TRANSACTION … COMMIT` snippet).

---

## Summary: Issue Counts by Section

| Section | Critical | High | Medium | Quick Win |
|---|---|---|---|---|
| Orientation | 3 (C1, C2, C3) | — | M1, M5, M13 | roadmap ICLA note |
| Build & Test | 2 (C4, C5) | H6, H8, H9 | — | 3 quick wins |
| Patch Review | 1 (C3 overlap) | H5 | M3, M13, M14 | 3 quick wins |
| Develop | — | — | M6, M7, M8 | — |
| Architecture | 2 (C6, H4) | H7 | M4, M5, M12 | internals example |
| SSTable/Release | — | H3, H10 | M9, M10, M11, M15 | — |
| Cross-cutting | C4, C5 | H1, H2 | — | — |

---

## Recommended Fix Order

1. **C1** — Remove the "Unresolved Questions" section from `first-deep-contribution.adoc`
2. **C2** — Add prerequisites/ICLA callout to `index.adoc`
3. **C3** — Create `orientation/jira-quickstart.adoc` and link from all orientation pages
4. **C4** — Define `dtest` on first use in every section + add cassandra-dtest setup steps
5. **C6** — Write `accord.adoc` overview (3 paragraphs)
6. **H1** — Add CHANGES.txt example to `patches.adoc`
7. **H2** — Explain "Patch Available" status in `index.adoc` + `patches.adoc`
8. **Quick wins** — batch these; one sitting, 10 files
9. **H3** — SSTable diagrams (high effort, plan as a separate authoring task)
10. **H4** — Accord architecture sequence diagram (separate authoring task)
11. **H7** — Live migration state diagram (separate authoring task)
