# Tighter plan: eliminate error-level docs build events and restore `failure_level: error`

Tracks the path from today's state to a clean Antora 3 build with strict error gating on `apache/cassandra-website`, while avoiding contradictory branch logic and unnecessary coordination overhead.

Owner: Patrick McFadin (CASSANDRA-21315 and follow-ups).
Last updated: 2026-04-22.

---

## Scope and factual baseline

From Jenkins build `cassandra-website #2752` (the failing run that caused the second revert):

| Error type | Count | Notes |
|---|---:|---|
| target of xref not found | 650 | 13 end in `.html` (bulk-fixable); 637 end in `.adoc` (real work) |
| target of image not found | 37 | Missing asset files |
| dropping cells from incomplete row | 14 | Malformed AsciiDoc table structure |
| level 0 sections can only be used when doctype is book | 9 | `=` used instead of `==` for subsections |
| target of include not found | 3 | Broken `include::` directives |
| **Total error-level** | **713** | |

Distribution by source ref in that failing build:

| Source ref | Errors | % |
|---|---:|---:|
| trunk | 163 | 23% |
| cassandra-6.0 | 163 | 23% |
| cassandra-5.0.8 | 143 | 20% |
| cassandra-5.0 | 140 | 20% |
| cassandra-4.1 | 31 | 4% |
| cassandra-4.0 | 30 | 4% |
| cassandra-3.11 | 28 | 4% |
| asf-staging (cassandra-website itself) | 23 | 3% |

High-frequency repeated errors:

- `master@_:ROOT:contactus.adoc` — 14 occurrences
- `master@_:ROOT:bugs.adoc` — 14 occurrences
- `reference:user-defined-type.adoc` — 12 occurrences
- `reference:data-types.adoc` — 12 occurrences
- `developing/cql/keyspace-check.adoc` — 12 occurrences
- `cassandra:developing/collections/collection-create.adoc` — 12 occurrences

The leverage is still real, but the execution model needs to be simpler:

- Fix shared website-owned targets once instead of rediscovering them per branch.
- Fix repeated canonical path mistakes once per maintained source branch, then merge according to ASF branch policy.
- Reduce the active gating set early instead of spending time cleaning refs that are intentionally out of scope.

---

## Constraints and decisions

1. **Trunk is currently on Antora 2.** Stefan reverted `b753289ae8` and `083a72470a` on 2026-04-21. Trunk today (`8d3668a2a1`, "ninja: prevent ooms") is Antora 2 + Node 20 + the OOM memory bump salvaged from Mick's follow-up.
2. **Two repos are in scope:** `apache/cassandra-website` and `apache/cassandra`. They have different reviewers and CI.
3. **Content fixes are valid under both Antora 2 and Antora 3.** Broken xrefs remain broken; Antora 3 simply promotes them to build-blocking errors.
4. **The supported local build entrypoint is `./run.sh`, not ad hoc `docker run` commands.** Use `./run.sh website build` and `./run.sh website docs/build` as the plan's standard loop so contributors use the same contract documented in the repo.
5. **Do not assume every source ref in the failing build is a PR target.** `cassandra-6.0` and `cassandra-5.0.8` were present as build refs in the baseline, but the fix lanes must follow actual maintained branches and supported release policy, not whatever happened to be included in one failing build.
6. **Make the gating set explicit before doing long-tail cleanup.** `cassandra-3.11` is out of scope by default. `cassandra-4.0` requires an explicit go/no-go decision. If an older branch or release tag is not meant to block `failure_level: error`, remove it from the active error budget first.
7. **Use one merge policy throughout the plan.** For `apache/cassandra`, apply fixes to the oldest maintained affected branch, then merge up. Do not alternate between "trunk first", "branch first", and "branch-specific no merge-up" depending on the phase.
8. **Ticketing should be sparse.** Use one umbrella JIRA plus a small number of child tickets grouped by leverage and reviewer ownership. Do not create a JIRA per branch-per-module unless a branch has truly diverged.

---

## Active execution model

This work is organized into four workstreams that can overlap where practical.

### Workstream 0 — Define the active gating set and reland Antora 3 safely

**Goal:** get back to Antora 3 without reintroducing premature strict failure gating, and define exactly which sources must be clean before `failure_level: error` returns.

**Tasks:**
1. Reland the Antora 3.1 / Node 24 LTS build changes onto current website trunk, keeping:
   - Antora 3.1.14 / Node 24 LTS container changes.
   - `@antora/lunr-extension` registration and matching UI behavior.
   - `NODE_OPTIONS="--max-old-space-size=4096"`.
   - The `grep -rl ... || true` guards and preview metadata updates from the prior follow-up work.
2. Set `runtime.log.failure_level: fatal` during the cleanup window, with a short code comment pointing at this plan.
3. Before opening long-tail fix tickets, decide the **active gating set**:
   - Include: the maintained source refs that are intended to block the website build.
   - Exclude by default: `cassandra-3.11`.
   - Decide explicitly whether `cassandra-4.0` remains in scope.
   - Do not treat `cassandra-6.0` or `cassandra-5.0.8` as independent PR lanes unless they correspond to actual maintained source branches in the target repos.
4. Record that decision in this document and in the reland PR description so reviewers know which refs are expected to be clean before strict gating returns.

**Acceptance:**

- Website trunk is back on Antora 3 and Jenkins is green with `failure_level: fatal`.
- The active gating set is explicit.
- No one is still assuming that every source ref from build `#2752` must become its own PR lane.

**Risk to avoid:** another self-merge before reviewer signoff on the reland branch.

---

### Workstream 1 — Build a repeatable measurement loop around the existing tooling

**Goal:** make progress measurable without creating a second build workflow.

**Tasks:**
1. Add `site-content/bin/xref-report.sh` in `apache/cassandra-website`.
   - Input: captured build log from `./run.sh website build ...`.
   - Output:
     - total error count by category
     - per-source-ref breakdown
     - top repeated missing targets
     - optional diff against a saved baseline
2. Save the baseline from build `#2752` as `research/antora3-xref-baseline.json` with:
   - date
   - source commit SHA(s)
   - gating-set note
   - counts by category and source ref
3. Document one supported local loop in `runbooks/fix-broken-xref.md`:
   - build the website container if needed
   - run `./run.sh website build` for website-only fixes
   - run `./run.sh website build -g -u cassandra:/path/to/cassandra -b cassandra:<branch>` for Cassandra doc fixes
   - capture the build log
   - run `xref-report.sh`
   - confirm the target error disappeared
   - run a wider regression pass only before PR or before tightening the gate

**Acceptance:**

- A contributor can run one documented loop and report a numeric delta without hand-parsing Antora output.
- The plan no longer depends on raw `docker run ... build-site` examples that bypass repo tooling.

**Rule:** keep this lightweight. Shell + `jq` is enough.

---

### Workstream 2 — Remove the highest-leverage shared failures first

**Goal:** eliminate the errors that multiply across large parts of the site before touching branch-specific long-tail cleanup.

This workstream is deliberately split by leverage, not by seven separate phases.

#### 2A. Fix website-owned compatibility targets in `apache/cassandra-website`

The `master@_:ROOT:*` failures are not primarily a component-name problem. In the current website source, the website component still exists as `name: _` / `version: master`; the repeated failures come from shared targets that were removed or relocated.

**Tasks:**
1. Restore or redirect website-owned compatibility targets that Cassandra docs still link to:
   - `bugs.adoc`
   - `contactus.adoc`
   - any similar website-owned targets found by `xref-report.sh`
2. Prefer thin compatibility pages or explicit redirects to the new `community.adoc` anchors over mass-rewriting every inbound reference immediately.
3. Fix the remaining website-only issues in the same PR where sensible:
   - blog xrefs ending in `.html`
   - missing images
   - missing include partials in website-owned content

**Acceptance:**

- `asf-staging`-owned errors are at zero or near-zero in one PR.
- The repeated `master@_:ROOT:bugs.adoc` and `master@_:ROOT:contactus.adoc` misses disappear without branch-by-branch archaeology.

#### 2B. Fix canonical target-path mistakes in `apache/cassandra`

These are repeated path-shape errors, not independent mysteries.

Build a short canonical remap table and apply it to the oldest maintained affected branch first:

| Broken target | Canonical target or disposition |
|---|---|
| `reference:data-types.adoc` | `cassandra:developing/cql/types.adoc` or anchor within that page |
| `reference:user-defined-type.adoc` | anchor within `cassandra:developing/cql/types.adoc` |
| `developing/cql/keyspace-check.adoc` | correct prerequisite/anchor target in current CQL docs |
| `cassandra:developing/collections/collection-create.adoc` | `cassandra:developing/cql/collections/collection-create.adoc` |

**Tasks:**
1. Confirm the exact target map once on the oldest maintained affected branch.
2. Apply the fix there.
3. Merge up through the maintained branch ladder.
4. Only split into a separate child ticket when branch drift makes the same fix materially different.

**Acceptance:**

- The top repeated path-shape errors are gone from the maintained branch ladder.
- Ticket count stays low because repeated fixes are handled as repeated fixes, not as separate archaeology exercises.

---

### Workstream 3 — Clean the residual branch-specific errors and restore strict gating

**Goal:** finish the smaller branch-specific misses, then flip back to `failure_level: error`.

#### 3A. Residual cleanup

Once Workstream 2 removes the high-multiplier failures, clean the remaining branch-specific issues in the active gating set:

- remaining xref-not-found messages
- missing images
- missing include partials
- incomplete table rows
- level-0 heading misuse outside `doctype: book`

**Execution rules:**

1. Work from the oldest maintained affected branch and merge up wherever the branch policy allows.
2. Batch by reviewer-relevant scope, not by every single source module.
3. Only open branch-specific PRs where the content has genuinely diverged.
4. Re-run the numeric report after each batch so the long tail is visibly shrinking.

**Practical order:**

1. Maintained Cassandra docs branches in the active gating set.
2. Website-owned residual content.
3. Optional cleanup for refs outside the gate, only if there is still reviewer appetite.

#### 3B. Restore strict failure gating

**Prerequisites:**

- Zero error-level messages across the active gating set under Antora 3.
- Reviewer agreement on any intentionally excluded refs.
- One final full verification pass using the relanded Antora 3 build.

**Tasks:**
1. Open one child JIRA: "Restore Antora failure_level=error".
2. Change `site-content/site.template.yaml` back to:
   ```yaml
   runtime:
     log:
       level: warn
       failure_level: error
   ```
3. Remove the temporary plan comment.
4. Verify Jenkins remains green.

**Acceptance:**

- Website trunk is green on Antora 3 with `failure_level: error`.
- New error-level docs regressions fail immediately.
- Warn-level output is explicitly not part of the success criteria.

---

## Contributor guidance after the gate is restored

Add a short prevention section once the cleanup is complete:

- xref targets are source `.adoc` pages or anchors, not rendered `.html` pages
- cross-component links should use full Antora coordinates when needed
- use `./run.sh website build` locally before opening docs-heavy PRs
- if a page is removed from `cassandra-website`, preserve inbound compatibility for Cassandra docs or update those links in the same change

If CI follow-up is pursued later, it should reuse the same `./run.sh`-based build contract and report only error-level regressions, not warning churn.

---

## Tracking and coordination

Use one umbrella JIRA plus a small set of child tickets:

1. Reland Antora 3 safely and define the active gating set.
2. Add xref-report tooling and local runbook.
3. Restore website-owned compatibility targets and website-only fixes.
4. Apply canonical Cassandra xref remaps across maintained branches.
5. Residual cleanup if needed.
6. Restore `failure_level: error`.

Reviewer ownership:

- Website reland and gating change: website committers.
- Website compatibility fixes: website committers.
- Cassandra path remaps and residual branch fixes: Cassandra committers.

Announce intent on `dev@cassandra.apache.org` when a change affects multiple maintained branches or changes the active gating set.

---

## Avoid

- Do not "fix" an unresolved xref by stripping the macro and leaving plain text.
- Do not combine build-stack changes and content cleanup in the same PR.
- Do not invent separate PR lanes just because a failing build listed a source ref.
- Do not maintain two local build workflows when `./run.sh` already provides the supported one.

---

## Appendix: quick fix recipes

### Pattern 1 — `.html` in xref target

```adoc
xref:blog/Testing-Apache-Cassandra-4.html[tools]   // wrong
xref:blog/Testing-Apache-Cassandra-4.adoc[tools]   // right
```

Antora resolves xrefs against AsciiDoc sources, not rendered HTML.

### Pattern 2 — outdated or removed shared website target

```adoc
xref:master@_:ROOT:bugs.adoc[How to report bugs]
```

If the website-owned target was removed, restore a compatibility page or redirect instead of rewriting every inbound reference first.

### Pattern 3 — canonical path drift inside Cassandra docs

```adoc
xref:reference:data-types.adoc[CQL data type]                     // wrong
xref:cassandra:developing/cql/types.adoc[CQL data type]          // right

xref:cassandra:developing/collections/collection-create.adoc[]   // wrong
xref:cassandra:developing/cql/collections/collection-create.adoc[] // right
```

Confirm the canonical target once, then merge that fix through the maintained branch ladder.
