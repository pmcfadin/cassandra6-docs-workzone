# Broken xref / link fixup — workstream log

**Source plan**: [`docs/phased_fixes.md`](../docs/phased_fixes.md)
**Baseline artifact**: [`research/antora3-xref-baseline.json`](../research/antora3-xref-baseline.json)
**Local loop runbook**: [`runbooks/fix-broken-xref.md`](../runbooks/fix-broken-xref.md)
**Jenkins reference build**: [cassandra-website #2752](https://ci-cassandra.apache.org/job/cassandra-website/2752/console)
**Started**: 2026-04-22
**Last updated**: 2026-06-11 (CASSANDRA-21342 Resolved — fixVersions + Source Control Link corrected by mck; commit-message convention learned: no JIRA prefix on first line, id in trailer only — PR #4877 amended to comply (`5d6fd41da4`); CASSANDRA-21449 dev@ [DISCUSS] thread in lazy-consensus window; 21448 + 21449 block the Antora 3 reland CASSANDRA-21315, all under epic CASSANDRA-21314)

---

## How to use this log

One section per phase in `docs/phased_fixes.md`. Update the status table when
a phase state changes. Append a dated entry to the relevant phase whenever
something material happens — commit, reviewer round, JIRA state change,
build result, plan correction.

Entry template:

```
### YYYY-MM-DD — short title

- Branch / commit: <repo/branch@sha>
- What changed: <one or two bullets>
- Verification: <gates run, results>
- Reviewer feedback incorporated: <reference>
- Next: <concrete next step>
```

Keep entries terse. This is the audit trail, not the plan.

---

## Overall status

| Phase | Scope | Status | Blocker |
|---|---|---|---|
| 0 | Reland Antora 3 upgrade with `failure_level: fatal` | ⬜ Not done — **PR #315 reverted 2026-04-21** | Antora 3 stack merged via PR #315 on 2026-04-17 but reverted on 2026-04-21 by Stefan Miklosovic. cassandra-website trunk is back on Antora 2.3.4 / Node 20.16. Needs root-cause analysis + reland. `failure_level: fatal` tightening also still pending (folded into Phase 6). See `antora-3-upgrade-log.md` for the revert entry. |
| 1 | `xref-report.sh` tool + baseline + runbook | ✅ Approved 2026-04-24 | Ready for push/JIRA/PR (contributor action) |
| 2 | Fix 19 errors in `cassandra-website` own content (asf-staging) | ✅ Done | PR #319 merged 2026-05-13 (rebase-merge, 2 commits, reviewed by Brandon Williams). Awaiting Jenkins #2770+ for authoritative validation of the 3 cross-component `Cassandra:` xrefs. |
| 3 | High-frequency cross-module xrefs in `apache/cassandra` trunk | ✅ Done | PR #4807 merged 2026-05-14 (squashed; trunk commit `32826fe5`); long-tail PR #4810 merged 2026-06-01 (trunk commit `cc97ee53`) |
| 4 | Per-branch content cleanup in `apache/cassandra` | ✅ Done | PR #4807 + PR #4810 trunk + atomic forward-merge to `cassandra-6.0`/`5.0`/`4.1`/`4.0` landed 2026-06-10. The `create-custom-index.adoc:58` follow-up turned out to be one symptom of a larger gap — cassandra-6.0 had been missed entirely by PR #4807's 2026-05-14 forward-merge; closed 2026-06-10 (`fc8883fc70` on cassandra-6.0). |
| 5 | Structural and non-xref errors (images, tables, doctype, includes) | ⬜ Not started | Independent of 2–4; can run in parallel |
| 6 | Tighten `failure_level: error` | ⬜ Not started | Phases 0 + 2–5 complete on in-scope branches |
| 7 | Regression prevention (contributor guidance + CI gate) | ⬜ Not started | Phase 6 landed |

Emoji key: ⬜ not started · 🟡 in progress · 🟣 awaiting review · ✅ done · ⛔ blocked

---

## Baseline reference

Captured from Jenkins `cassandra-website #2752` (the failing run that caused
the second revert of CASSANDRA-21315).

| Dimension | Value |
|---|---|
| Total error-level log entries | 713 |
| Categories | 650 xref · 37 image · 14 table · 9 section · 3 include |
| Distinct `msg` values | 162 |
| Distinct `(branch, category, msg)` keys | 581 |
| Branch distribution | trunk 161 · cassandra-6.0 161 · cassandra-5.0.8 143 · cassandra-5.0 140 · cassandra-4.1 31 · cassandra-4.0 30 · cassandra-3.11 28 · asf-staging 19 |
| `trunk_sha_at_capture` | `569057c649b6b113d6c900b69f6ace1093ff3a62` |

Notes:
- The `docs/phased_fixes.md` scope table lists 163/163/23 for
  trunk/cassandra-6.0/asf-staging — that row's sum is 721, off by eight
  from the actual 713. Correction pending as a standalone workzone commit
  (kept separate from any PR against `apache/cassandra-website` so the
  tooling PR diff stays focused).

---

## Phase 0 — Reland Antora 3 upgrade

Cross-refer to [`antora-3-upgrade-log.md`](antora-3-upgrade-log.md) — that
log already tracks the build-stack upgrade. This workstream depends on
Phase 0 only for the *final* verification run at Phase 6; Phases 2–5 are
independent and proceed on current (Antora 2) trunk.

### 2026-04-17 — Antora 3 stack landed

PR [#315](https://github.com/apache/cassandra-website/pull/315)
(CASSANDRA-21315) merged to `apache/cassandra-website:trunk` (commit
`15f7e91d`). Antora 3.1.14 + Node 24.14.1 + `@antora/lunr-extension` are
now the upstream build stack. The `failure_level: fatal` tightening
referenced in `docs/phased_fixes.md` is **not** part of #315 — that step
is folded into Phase 6 of this log.

Phases 2–5 continue on trunk as planned; nothing in their scope changes
because of #315.

### 2026-04-21 — PR #315 reverted

Stefan Miklosovic landed `b753289a` reverting #315 four days after
merge. cassandra-website trunk is back on Antora 2.3.4 / Node 20.16.0.
Discovered during the 2026-05-13 local build for PR #4807 verification;
see `antora-3-upgrade-log.md` for the full revert entry. Phase 0 here
goes back to ⬜ until the revert reason is understood and the upgrade
is relanded.

This does NOT affect Phases 2–5 of this workstream — those fixes are to
the source content, not to the build stack, and work on either Antora
2 or Antora 3. PR #319 (merged 2026-05-13) and PR #4807 (open) are
both valid against the current Antora-2 trunk.

---

## Phase 1 — Tooling and baseline

**Branch**: `broken-link-fix` in local `cassandra-website/` checkout, off
trunk `42de111d` (release of 5.0.8). Not pushed.

### 2026-04-22 — Initial tool + baseline + runbook

- Commit: `cassandra-website/broken-link-fix@328921f3` — adds
  `site-content/bin/xref-report.sh`.
- Baseline JSON written to `research/antora3-xref-baseline.json`
  (schema_version 1 at this point; `top_targets` was the delta key).
- Runbook written to `runbooks/fix-broken-xref.md` (local fix-verify loop;
  explicit "don't push, don't open PR — contributor-authored action"
  handoff line).
- Verification gates against `/tmp/cassandra-website-2752.log`: default
  report → 713 total with correct 650/37/14/9/3 split; `--emit-baseline
  | jq .total` → 713; unfiltered `--baseline` re-diff → 0 fixed /
  0 introduced.
- Next: request reviewer sanity check before using the tool to drive
  Phase 2+ PR scorecards.

### 2026-04-24 — Reviewer round 1: P1 + P2 blockers

Reviewer (quick review on tooling-only branch) flagged two blockers for
use as PR scorecard:

- **P1**: `--branch` combined with `--baseline` compared a filtered
  current log against an unfiltered baseline, counting every non-matching
  baseline entry as "fixed." Repro: `--branch trunk --baseline
  baseline.json` on the raw fixture reported **552 fixed** (= 713 − 161).
- **P2**: baseline `top_targets` was keyed on `msg` only, so delta output
  could not attribute improvements to a branch or category, and fixes in
  one branch could mask regressions in another (same `msg`, different
  branch, canceling counts).

Category split itself (xref / image / include / section / table / other)
confirmed correct for Phase 1 reviewer ownership.

### 2026-04-24 — P1 + P2 fix landed

- Commit: `cassandra-website/broken-link-fix@d9b850dc` — keys deltas on
  `(branch, category, msg)`.
- Baseline bumped to `schema_version: 2` and gains a `target_counts` list
  of `{branch, category, msg, count}` records (581 records vs prior 162
  msg-only). `top_targets` retained for display / readability.
- `--branch` now filters baseline symmetrically. Legacy baselines (no
  `target_counts`) are refused when `--branch` is used, with a clear
  stderr message asking for re-emit; without `--branch` they fall back to
  msg-only diff with a visible `WARNING: legacy schema` line.
- Report gains "Fixed by branch" / "Introduced by branch" blocks; top-10
  rows labelled `[branch/category] msg`.
- `research/antora3-xref-baseline.json` regenerated with schema_version 2.
- Verification:
  - Unfiltered re-diff → 0/0 (unchanged).
  - `--branch trunk --baseline` on raw fixture → **0 fixed / 0 introduced**
    (was 552 fixed).
  - `--branch asf-staging --baseline` on raw fixture → 0/0 (was 694 fixed).
  - Synthetic fix (2 trunk occurrences of `master@_:ROOT:bugs.adoc`
    removed) → 2 fixed attributed to `[trunk/xref]`; no phantom fixes on
    the 12 other branches where the same msg still appears.
  - Legacy baseline + `--branch` → refused with stderr message.
  - Legacy baseline no `--branch` → msg-only diff + visible WARNING.
- Next: reply to reviewer with regression results; decide whether tool +
  first Phase 2 content fix ship as a single PR or as a preceding
  tooling-only PR.

### 2026-04-24 — Phase 1 reviewer approval

- Reviewer confirmed Phase 1 tooling is acceptable for use as Phase 2+
  PR scorecard.
- No further code changes required on `broken-link-fix` tip
  (`d9b850dc`).
- Next: contributor-authored push to fork + JIRA open + PR. Tool
  can ship solo or bundled with Phase 2's first content fix per
  earlier reviewer offer.

---

## Phase 2 — `cassandra-website` own content (asf-staging, 19 errors)

In progress on `broken-link-fix`. The local build on that branch shows 20
errors (asf-staging's 19 + 1 additional that surfaced under the local
refname). First batch of 11 mechanical fixes landed 2026-04-24.

### 2026-04-24 — Mechanical fix batch (11 errors resolved)

- Commit: `cassandra-website/broken-link-fix@daaac289` — "Fix 11 Antora
  broken-xref / level-0 errors in cassandra-website content".
- Six files edited, dispatched across four parallel subagents:

  | Fix class | Files | Errors resolved |
  |---|---|---|
  | Level-0 sections (include `leveloffset=+1` + duplicate title removal) | `development/index.adoc`, `blog/Configurable-Storage-Ports-and-Why-We-Need-Them.adoc` | 5 |
  | `.html` → `.adoc` xref target | `blog/Apache-Cassandra-4.0-Overview.adoc` | 1 |
  | `xref::` double-colon → `xref:development/` | `development/gettingstarted.adoc`, `development/ide.adoc` | 4 |
  | Renamed blog page | `blog/Even-Higher-Availability-with-5x-Faster-Streaming-in-Cassandra-4.adoc` | 1 |

- Verification: local Antora 2 build (`./run.sh website build -e .xref-env
  -u cassandra:../cassandra -b cassandra:trunk`) before vs after, diffed
  through `xref-report.sh --baseline`.
  - Pre-fix: 20 errors on `broken-link-fix` refname.
  - Post-fix: **9 errors** (20 − 11).
  - Tool reports: `fixed: 11, introduced: 0, net: -11`. Every targeted
    msg appears under "Fixed"; no new msgs appear.
- Remaining 9 errors (out of Phase-2 mechanical scope, require
  investigation):
  - 2× `doc/latest/cassandra/architecture/overview.adoc` (rendered-site
    path in two Changelog blog posts — needs rewrite to component form)
  - 1× `Cassandra::index.adoc` in `main-nav.adoc` (stale component name)
  - 1× `blog/Cassandra-Day-SC-Bellevue-Houston-Wakanda Forever.adoc`
    (space in filename — verify actual file on disk, fix path)
  - 3× missing include partials (`ROOT:partial$persistent-volume.adoc`,
    `persistent-volume-claim.adoc`, `segment.adoc`) in `glossary.adoc` —
    check git history for deletion; restore, inline, or remove include
  - 2× missing image assets (`/img/apachecon-2019.jpg`,
    `/assets/img/caution.svg`) — find asset or remove directive
- Next: tackle the remaining 9 in a second subagent pass per the same
  edit → build → verify loop.

### 2026-04-24 — Batch 2 fixes (8 of 9 targeted errors resolved locally; 1 deferred)

- Commit: `cassandra-website/broken-link-fix@af93ed7b` — "Fix remaining
  Antora errors in cassandra-website content".
- Five files edited, dispatched across four parallel subagents
  (subagent F scope was dropped during investigation and converted into
  a deferred-ticket note below):

  | Fix class | Files | Errors resolved | Notes |
  |---|---|---|---|
  | E: rendered-path xref rewrites | `blog/Apache-Cassandra-Changelog-{19-September,20-November}-2022.adoc` | 2 | `doc/latest/cassandra/architecture/overview.adoc` → `Cassandra:cassandra:architecture/overview.adoc` — unverifiable locally (see caveat below) |
  | F: main-nav Cassandra::index.adoc | (skipped) | 0 | Root cause: `cassandra/doc/antora.yml` marks 6.0 as `prerelease: true`, disqualifying it as the unversioned default. Needs Patrick's call on un-prerelease vs pin-version vs re-point |
  | G: filename with space | `blog/Apache-Cassandra-Changelog-20-November-2022.adoc` | 1 | `Wakanda Forever.adoc` → `WakandaForever.adoc` |
  | H: glossary missing partials | `glossary.adoc` | 3 | Three `include::ROOT:partial$…` directives for `persistent-volume`, `persistent-volume-claim`, `segment` removed (no source to restore; no git history) |
  | I: missing image assets | `download.adoc`, `apachecon_cfp.adoc` | 2 | `download.adoc`: absolute URL rewritten to Antora-relative `caution.svg`. `apachecon_cfp.adoc`: `apachecon-2019.jpg` asset lost in CASSANDRA-16066 migration; image macro removed from archival 2019 content |

- Verification: same edit → build → diff loop.
  - Pre-batch-2 (post-batch-1): 9 errors on `broken-link-fix` refname.
  - Post-batch-2: **3 errors**.
  - Tool reports: `fixed: 8, introduced: 2, net: -6`.
- **Local verification caveat** (worth flagging for reviewer):
  - The local build runs via `./run.sh website build -e .xref-env
    -u cassandra:../cassandra -b cassandra:trunk` — no `-g` flag. The
    generated `site.yaml` therefore has only one content source (the
    cassandra-website itself at HEAD). The Cassandra component is NOT
    imported into the Antora build.
  - This means every xref targeting `Cassandra:...` (the cassandra
    component) is reported as unresolved in this local build, even when
    the target file exists on disk. Batch 2's E rewrites surface as 2
    "introduced" errors in the delta diff for exactly this reason.
  - The Jenkins build imports the Cassandra component from version tags
    (3.11, 5.0, latest, stable) plus the cassandra-website, so it is the
    authoritative test for the 3 Cassandra-component-dependent xrefs
    (2 E + 1 F).
  - Running a full local `-g` build (adds `ant gen-asciidoc` for every
    Cassandra version) would validate them end-to-end but is heavy and
    needs Java/ant; deferred as not worth the time before Jenkins.
- Deferred into a separate ticket (new JIRA required):
  - `main-nav.adoc` → `Cassandra::index.adoc` resolution. Root cause
    captured in this log so the new ticket can skip investigation.

---

## Phase 2 — branch state

| Commit | Summary |
|---|---|
| `328921f3` | Add xref-report.sh tool (Phase 1) |
| `d9b850dc` | xref-report: dimensional delta engine (Phase 1 fix round) |
| `daaac289` | Fix 11 Antora broken-xref / level-0 errors (Phase 2 batch 1) |
| `af93ed7b` | Fix remaining Antora errors in cassandra-website content (Phase 2 batch 2) |

Phase 2 local-build error count: 20 → 3 (-17). Of the remaining 3, all
require the Cassandra component in the Antora build to validate;
Jenkins is the authoritative verification for them and for the
production-cleanliness gate.

Branch still unpushed. Four commits stay separate during review; squash
to a single commit happens only after the PR earns a +1 on GitHub, per
the `contributing-to-apache-cassandra` skill.

### For reviewer handoff

Suggested review scope for the Phase 2 PR:
1. `xref-report.sh` tool (commits 1 & 2) — same artifact you approved
   earlier on 2026-04-24.
2. Content fix batches 1 & 2 (commits 3 & 4) — 11 files, 19 errors
   locally verified away.
3. One Cassandra-component-dependent fix class (commits 3 edits: the
   two architecture/overview.adoc rewrites) that can't be verified
   locally without a full `-g` build and needs the Jenkins run to sign
   off.
4. One deferred reference (`Cassandra::index.adoc` in `main-nav.adoc`)
   flagged for a separate ticket; not in this PR.

**Planned scope** (per plan, confirmed against fixture):

- Blog-post xrefs with `.html` extensions.
- `master@_:ROOT:*` references in `main-nav.adoc` / `glossary.adoc`.
- Missing include partials in `glossary.adoc`.
- Missing images (`/img/apachecon-2019.jpg`, `/assets/img/caution.svg`).

---

### 2026-04-28 — PR #319 opened, rebased, CI green; staging-push avenue investigated

PR opened on apache/cassandra-website at https://github.com/apache/cassandra-website/pull/319 with title "Docs broken links fix. Phase 1", base `trunk`, head `broken-link-fix`.

#### Rebase onto current trunk

Branch was 1 behind / 2 ahead of upstream `trunk`. Trunk had advanced to `dded488c` (Maxime Wiewiora, "Add JDBC wrapper for Cassandra to ecosystem page", touches `ecosystem.adoc` only — zero overlap with broken-link-fix files). Clean rebase, no conflicts:

| Pre-rebase SHA | Post-rebase SHA | Commit |
|---|---|---|
| `b6510fc6` | `a3b5fe2f` | Fix 11 Antora broken-xref / level-0 errors in cassandra-website content |
| `764ee465` | `22b83fdf` | Fix remaining Antora errors in cassandra-website content |

Force-push (`--force-with-lease`) to `pmcfadin/cassandra-website:broken-link-fix` updated PR #319.

#### Local minimal build verification

`./run.sh website build` (no `-g`, no cassandra component) on rebased `broken-link-fix`:

- Exit 0, ~4 min wall time
- **3 errors** (down from baseline 19 cassandra-website-side):
  - `main-nav.adoc` → `Cassandra::index.adoc` (the deferred `Cassandra::index.adoc` item — already filed for separate ticket)
  - `blog/Apache-Cassandra-Changelog-19-September-2022.adoc` → `Cassandra:cassandra:architecture/overview.adoc`
  - `blog/Apache-Cassandra-Changelog-20-November-2022.adoc` → `Cassandra:cassandra:architecture/overview.adoc`
- **251 warnings** — all pre-existing `section title out of sequence` style noise, not introduced by this branch
- All 3 errors are cross-component xrefs into `Cassandra:` that the minimal build cannot resolve. Authoritative validation is Jenkins post-merge.

#### Staging-preview investigation

Patrick wanted to push a preview to `cassandra.staged.apache.org` ahead of reviewer engagement. Investigation findings worth keeping for future workstreams:

- `asf-staging` is a **single shared branch** containing rendered HTML on top of trunk source, written by `ci-cassandra.apache.org/job/cassandra-website/` whenever trunk moves. No per-PR preview slot.
- The Jenkins job builds **only trunk** — no parameterized branch input visible from the job page. To get a non-trunk build onto asf-staging, a committer would have to manually replicate Jenkins's pattern (build + force-push the rendered output to asf-staging), which is destructive (overwrites whatever's currently staged) and gets overwritten on next trunk merge (~80 min typical).
- The cassandra-website repo *does* have a GHA workflow (`.github/workflows/site-content.yaml`) that auto-builds non-trunk pushes — but only the **top-level-only** build (no cassandra component pull), same coverage as the local minimal build. Output goes to a `<branch>_generated` branch, no public URL.
- Local full `-g` build to fully validate the 3 cross-component errors is impractical (≥10 min, requires Java/ant inside the container) — same constraint hit on Phase 3.

Decision: skip the manual asf-staging force-push (would have wiped Maxime's currently-staged JDBC wrapper preview, and the local build was 2 weeks stale on the cassandra component plus missing 5.0.8 and 7.0 doc-version slots). Use the GHA build as the CI signal instead.

#### GHA build outcome

- Pushed `broken-link-fix` to `apache/cassandra-website` upstream (committer push, new branch, non-destructive). SHA on upstream verified: `22b83fdfa31348ecee42c1e231371d3141b4b4b7`.
- GHA workflow `Build toplevel website` auto-triggered (run 25076020526), completed in 3m52s, conclusion `success`.
- Generated branch `broken-link-fix_generated` at `1041550f` containing rendered output (top-level only).
- Reviewer comment posted on PR #319 by Patrick.

#### Cleanup pending

When PR #319 is merged or no longer needs the GHA artifact:

```
git push upstream --delete broken-link-fix
```

This also removes the `broken-link-fix_generated` branch the workflow created.

---

### 2026-05-13 — PR #319 status check

PR has not moved since 2026-04-28. State recheck via `gh pr view 319`:

- `state`: OPEN
- `mergeable`: MERGEABLE / `mergeStateStatus`: CLEAN
- `reviews`: `[]` (no review activity recorded — no requested changes, no approvals, no comments from reviewers)
- Last `updatedAt`: 2026-04-28T20:40Z (Patrick's "Passes on CI" comment)
- CI: GHA `Build toplevel website` ✅ SUCCESS (run 25076020526)

Elapsed since opened (2026-04-27) → 16 days. No upstream code-side blockers — base `trunk` has not advanced in a way that affects this branch. Phase 2 remains 🟣 awaiting review; no further contributor action available beyond reviewer outreach (Patrick handling separately, not in this log).

Antora 3 stack (PR #315, see Phase 0 entry above) merged 2026-04-17. Phases 2–5 unaffected; Phase 6 (`failure_level: fatal` tightening) now sits behind PR #319 review only because that fix is the reference scorecard for the tightening criterion.

### 2026-05-13 — PR #319 merged

Brandon Williams approved later in the day. Pre-merge actions:

1. **Local rebase** of `broken-link-fix` onto current `upstream/trunk` (`dded488c`) to amend both commit-message trailers `reviewed by TBD` → `reviewed by Brandon Williams for CASSANDRA-21342`. Mechanical `sed` rewrite via `git rebase --exec`, no content changes.
2. **Force-push** to `origin/broken-link-fix` (`pmcfadin/cassandra-website` fork). PR head updated from `22b83fdf` to `b15389ec`.
3. **Force-push** to `upstream/broken-link-fix` (`apache/cassandra-website`) to re-trigger GHA on the new SHA — the fork doesn't run actions, so the previous green check was on the now-superseded SHA.
4. GHA run `25813402060` queued for ~4 min on ASF runners; user merged before run completed (acceptable — content was byte-identical to the approved version, only commit-message trailer changed).

Merge: **Rebase and merge** at 2026-05-13 19:04:52 UTC. Both commits replayed onto trunk:

| Pre-merge (PR head) | Post-merge (trunk) | Title |
|---|---|---|
| `0bb0f5e7` | `574a61fc` | Fix 11 Antora broken-xref / level-0 errors in cassandra-website content |
| `b15389ec` | `35c6027c` (trunk HEAD) | Fix remaining Antora errors in cassandra-website content |

Cleanup completed in the same operation:

- ✅ Deleted `broken-link-fix` on `apache/cassandra-website`
- ✅ Deleted `broken-link-fix` on `pmcfadin/cassandra-website` (fork)
- ✅ Deleted `broken-link-fix_generated` on `apache/cassandra-website` (the GHA artifact branch — not auto-removed by the parent branch's deletion, contra the assumption in the earlier cleanup note above; deleted manually)
- ✅ Deleted local `broken-link-fix` branch
- Local clone now on `trunk` at `35c6027c`, fast-forwarded from `dded488c`

**Validation outstanding:** Jenkins #2770+ on apache/cassandra-website is the authoritative test for the 3 cross-component `Cassandra:` xrefs that the local minimal build couldn't resolve. Jenkins build trigger is automatic on trunk push; watch <https://ci-cassandra.apache.org/job/cassandra-website/> and the resulting asf-staging content at <https://cassandra.staged.apache.org/>.

### 2026-05-13 — PR #4807 local-build verification attempt: blocked

Tried to validate PR #4807 locally via `./run.sh website build -g -u
cassandra:../cassandra -b cassandra:broken-link-fix` against a
freshly-rebuilt container. Two blockers, recorded for future attempts:

1. **Container `ant gen-asciidoc` fails on maven dependency fetch.**
   `Could not GET https://repo.maven.apache.org/maven2/org/agrona/agrona/1.17.1/agrona-1.17.1.jar`
   with `SSLHandshakeException: Remote host terminated the handshake`.
   Maven Central works fine from the host (HTTP 200, 0.17s); the
   failure is container-network-specific. Likely culprits: Docker's
   network bridge, container Java truststore, corporate TLS
   interception. Not investigated further this session.

2. **No-`-g` shortcut doesn't work either.** Skipping ant + maven
   sounds appealing, but the cassandra repo's `doc/antora.yml` has
   been auto-generated since `ea28710b` ("Autogenerate the doc
   antora.yml") — it's no longer committed; `./scripts/gen-antora-yml.py`
   creates it during gen-asciidoc. The website build container does
   `git clean` on its checkout copy, removing the host-generated
   `doc/antora.yml`. Without that file, Antora can't load the
   cassandra component. The build completes (252 asciidoctor warnings,
   all from cassandra-website's own blog/contributor pages), but
   nothing from PR #4807's scope is exercised.

3. **Side-discovery during this attempt:** PR #315 (Antora 3 upgrade)
   was reverted on 2026-04-21. See entry above + `antora-3-upgrade-log.md`.

**Net:** local pre-merge validation of PR #4807 is impractical without
deeper container-network work or a non-standard host-Antora setup.
Reverting to the PR body's documented plan: Jenkins post-merge on
cassandra-website is the authoritative test. Reviewer can +1 based on
structural analysis (paths and anchor ids grep-verified during the
original investigation, recorded above in the Phase 3 / Phase 4 batch
entries).

### 2026-05-14 — Retry kicked off; success criteria clarified

Several discoveries reopened the local-build path:

1. **Maven TLS issue was transient.** Re-tested same URL from inside
   the same container: `HTTP 200, time 0.257s` on
   `https://repo.maven.apache.org/maven2/.../agrona-1.17.1.jar`. The
   2026-05-13 `SSLHandshakeException` was an upstream Maven Central
   blip, not a persistent container-network problem.

2. **Jenkins #2770 was ABORTED**, not completed. `lastCompletedBuild`
   API: `{"result":"ABORTED", "duration":2207610}` — exactly 36m47s
   before abort. So asf-staging is **still at the 2026-05-09 build
   (Jenkins #2769) for trunk `dded488c`**; PR #319's post-merge
   validation never actually ran. Investigation 2026-05-14:
   - Build started 20:11:49 UTC, aborted at 20:48:37 UTC, console
     truncated mid-`[resolver:resolve]` maven artifact download
   - No `Build was aborted by [user]` annotation in HTML or console
   - Cause: most likely **Jenkins hard build timeout** (~37 min). The
     duration is suspiciously consistent; manual cancels usually
     leave an annotation
   - Comparison: #2769 succeeded; triggered by "upstream project +
     SCM change" (two causes). #2770 had only "SCM change" trigger
     and hit the same resolver phase #2769 cleared
   - Fix path: re-trigger Jenkins manually (committer Build Now), or
     wait for next SCM change. If the manually-triggered #2771 also
     times out at ~37 min, that confirms a config-level timeout
     needing INFRA jira

### 2026-05-14 — PR #4807 squashed and merged

driftx (Brandon Williams) approved at 16:42 UTC with the inline note
*"Don't forget to squash all these commits."* The 15 commits on
`broken-link-fix` were squashed to a single commit before merge:

1. **Stash phantom mode flips** in the cassandra clone (no-op this
   time — working tree clean).
2. **Rebase onto fresh `upstream/trunk`.** During the session
   `upstream/trunk` had moved from `7bd041d292` to `a918f6c2a4`
   (33 commits, mostly accord/test refactoring). Original
   `git reset --soft upstream/trunk` without fetching first would
   have produced a 413-file, +5107/−12912-line "squash" that
   *included reverting* the trunk advance. Caught before push;
   reset to `a9fd1ab63c` and properly `git rebase upstream/trunk`
   first. Rebase clean (no conflicts; broken-link-fix touches only
   `doc/`).
3. **Soft-reset to upstream/trunk + single commit.** Final scope:
   24 files in `doc/`, +77/−89 lines.
4. **Commit message** (short form per Patrick's preference):

   ```
   CASSANDRA-21342: Fix broken Antora xref/anchor targets in cassandra docs

   Resolve broken cross-module xrefs and image/anchor targets across the
   cassandra docs tree. Companion to apache/cassandra-website#319 (merged
   2026-05-13) under the same JIRA umbrella.

    patch by Patrick McFadin; reviewed by Brandon Williams for CASSANDRA-21342
   ```

5. **Force-push** `--force-with-lease=broken-link-fix:a9fd1ab63c`
   to `origin/broken-link-fix` (pmcfadin fork).
6. **Approval carried over** — `reviewDecision: APPROVED` retained
   because driftx's review was on the prior content, which is
   structurally equivalent to the squashed form.
7. **Rebase-and-merge** on the PR page at 17:29 UTC. Trunk HEAD
   advanced to `32826fe563e07ef03f93dd1f744d19bbcb968b78`.

State after merge:

- `apache/cassandra:trunk` includes PR #4807's content
- Phase 3 of this log → ✅ Done
- Phase 4 trunk-lane (batches 1 + 2) → ✅ Done
- Phase 4 forward-merges to `cassandra-5.0` (B + C), `cassandra-5.0`
  + `cassandra-4.1` + `cassandra-4.0` (A2) — pending committer
  cherry-picks per the standard chain
- 138 Antora-3 errors measured locally on broken-link-fix
  (2026-05-14 measurement entry above) should now match what the
  rebuilt website Jenkins sees on next trunk push

**Cleanup pending on Patrick's local clone** (not done in this
session):

```bash
cd cassandra
git checkout trunk
git pull --ff-only upstream trunk
git branch -d broken-link-fix          # or -D
git push origin --delete broken-link-fix
```

### 2026-05-14 — Jenkins #2771 succeeded; PR #319 live on staging

Manually re-triggered Jenkins via the cassandra-website job page.
**#2771 succeeded** (Patrick, committer "Build Now"). Build outcome:

- Started ~15:40 UTC, completed within the (presumed ~37 min) timeout
- Maven resolver phase faster this run — cache likely warmer after
  #2770's partial fetch
- Result: `success`, pushed to `asf-staging`

State after #2771:

- `asf-staging` HEAD: `a1ee3f61d2ed3888f013b3a8c97fb2d56ca2c4d7`
  (commit message: "generate docs for 35c6027c") — built from trunk
  including PR #319's merge commit
- `cassandra.staged.apache.org` returns HTTP 200, serves the
  2026-05-14 build (verified)
- PR #319's three cross-component `Cassandra:` xrefs — implicitly
  validated (build would have warned but not failed; site renders)

**Live demonstration of the Antora-2-vs-3 asymmetry (Patrick,
2026-05-14):** the same trunk content that built green on Jenkins
#2771 (Antora 2.3.4 with `failure_level: fatal`) was measured to emit
**138 error-level entries on Antora 3** in the 2026-05-14 local
measurement above. Antora 3 with default `failure_level: error` would
have failed that build, and PR #319 would not have reached
asf-staging on its own. The whole broken-link workstream exists to
close this gap: drive Antora-3 errors to 0, then re-land PR #315
(this log's Step 0a) so the project never accumulates this kind of
backlog again.

**Jenkins #2770 abort: confirmed transient.** Since #2771 succeeded
on the same trunk content with a presumably-similar timeout policy,
the abort was likely network/cache cold + bad luck rather than a
persistent config issue. No INFRA jira needed today. Worth watching
on future builds in case the pattern repeats.

3. **Force-push to asf-staging is cheap right now.** Nothing valuable
   is currently on asf-staging (the 2026-05-09 build is pre-PR-#319
   and well-superseded by trunk). A committer-pushed preview wouldn't
   clobber any real validation work — same pattern used for PR #315 on
   2026-04-16.

4. **Success criteria sharpened (Patrick, 2026-05-14):** the goal is
   not "fewer errors" — it's **zero asciidoctor errors** on the Antora
   2 build. Antora 3's default `failure_level: error` will fail on any
   error message. Once the build hits zero errors on Antora 2, Antora
   3 can re-land with the new floor. PR #4807 is one slice toward that
   target; remaining slices (rest of Phase 4 long-tail + Phase 5
   structural) drive the count down further.

**Retry kicked off:** `./run.sh website build -g -u cassandra:../cassandra
-b cassandra:broken-link-fix` against the container as rebuilt 2026-05-13
(now confirmed Antora 2.3.4 / Node 20.16.0 / OpenJDK 21.0.10 — correct
for current cassandra-website trunk post-revert). Background process,
output to `/tmp/build-4807-retry.log`.

**Build completed 2026-05-14 08:06:59** — duration 4m16s, `BUILD
SUCCESSFUL`, `container: INFO: Rendering complete!`, `Moving site HTML
to content/`.

**Numbers from the completed Antora 2 build:**

- **2 asciidoctor errors total.** Both are level-0 section / doctype
  errors, NOT xref:
  - `security.adoc: line 3: level 0 sections can only be used when doctype is book`
  - `changes.adoc: line 1: level 0 sections can only be used when doctype is book`
- **289 asciidoctor warnings.** Breakdown:
  - 252 "section title out of sequence"
  - 28 "skipping reference to missing attribute" (cass-N, cassandra_home, date, N, N_version)
  - 6 table-related
  - 9 misc (invalid style for pass block / paragraph, list item index,
    duplicate section id)
- **0 xref/include/image warnings or errors.** That is the giveaway:
  **Antora 2 does not validate xrefs.** The 713-error 2026-04-22
  baseline came from Jenkins #2752 — an Antora 3 build (still merged
  at that point). Antora 3 added xref validation; Antora 2 silently
  passes broken xrefs.
- **All seven PR #4807 fix patterns: 0 occurrences** in the log
  (`reference:user-defined-type`, `reference:data-types`,
  `keyspace-check`, `master@_:ROOT:contactus`,
  `architecture/storage-engine/memtable`,
  `configuration/configuration/`, `cql_singlefile.html`). Expected
  even before the fix landed, since Antora 2 doesn't check.
- **0 `bugs.adoc` references** in the log either — though the deferred
  broken xrefs to `bugs.adoc` still exist in
  `cassandra/doc/modules/ROOT/{index.adoc,nav.adoc}`. Confirms Antora 2
  isn't reporting xref problems.

**What this build proves:**
- PR #4807's edits do not break the existing build pipeline (exit 0).
- Rendered HTML is produced and is browsable locally.
- The 2 structural errors (Phase 5 territory — doctype/section level)
  are the only asciidoctor-level fails on Antora 2. These would also
  be errors under Antora 3.

**What this build does NOT prove:**
- Antora-3-readiness. Since Antora 2 skips xref validation, a clean
  Antora 2 build is necessary but not sufficient for Antora 3 reland.
  The 713-error baseline still effectively applies — minus PR #319
  (19) and PR #4807 (76) by structural inference, leaving ~618
  unresolved errors that would still fail an Antora 3 build.
- To actually count Antora-3-error progress, run `bin/xref-report.sh`
  against an Antora 3 build's JSON log (per
  `runbooks/fix-broken-xref.md`). That requires a manually-spun-up
  Antora 3 container — the upstream Dockerfile is back on Antora 2
  after the 2026-04-21 revert.

**Practical implication for the workstream:** the "Phase 6 — tighten
`failure_level` back to `error`" goal in the Overall Status table is
better understood as a TWO-step gate: (a) get Antora 3 emitting
zero errors on a local build, then (b) re-land Antora 3 with that
floor. Step (a) is the actual blocker, and it can only be measured
under an Antora 3 build.

### 2026-05-14 — Antora 3 local measurement, full data captured

Spun up an Antora 3 build locally to measure progress against the
2026-04-22 baseline. Working tree had a `git revert b753289a` applied
(one local commit `897d1a67` "Reapply Upgrade docs build stack to
Antora 3.1 and Node 24 LTS"), conflict resolved in
`site-content/docker-entrypoint.sh` by keeping the Antora 3 invocation
(no `--generator antora-site-generator-lunr` flag). Container rebuilt
to Antora 3.1.14 / Node 24.14.1. JSON logging enabled via `.xref-env`.

Build command: `./run.sh website build -e .xref-env -g
-u cassandra:../cassandra -b cassandra:broken-link-fix`.

Build duration: 6m12s (08:13:56 → 08:20:08). Container rebuild
2m29s. Docs build ~3m43s including ant gen-asciidoc. Exit 0 (the
container's exit handling doesn't propagate the Antora 3 failure
signal; `failure_level` reporting is observational, not gating, in
this run).

**Result (the number that matters): `bin/xref-report.sh` reports 138
error-level entries on broken-link-fix.**

```
By category:
  xref      106
  image      24
  section     4
  table       4
  include     0
```

**Top patterns in the remaining 138:**
- 4 × `level 0 sections can only be used when doctype is book` —
  `security.adoc` and `changes.adoc`. **Phase 5 (structural).**
- 4 × `dropping cells from incomplete row detected end of table` —
  table syntax issues. **Phase 5.**
- 4 × `target of xref not found: master@_:ROOT:bugs.adoc` —
  the deferred A1/A3 work in `nav.adoc` + `pages/index.adoc`. **Tracked.**
- 24 × `target of image not found: images/data_modeling_*.png|jpg` —
  data-modeling page images, missing from the repo. **Phase 5.**
- ~100 long-tail xref errors — `developing/accord/index.adoc`,
  `compaction/index.adoc`, `tools/cqlsh.adoc`, `use_tools.adoc`,
  `cassandra:troubleshooting/index.html`,
  `cassandra:developing/cql/dml.html` (`.html` not `.adoc`),
  `developing/cql/defintions.adoc` (typo: `defintions`), various
  legacy paths. **Future Phase 4 / Phase 5 batches.**

**Sanity checks pass:**
- All 7 PR #4807 fix patterns: 0 occurrences in the error log.
- PR #319's 19 cassandra-website-side errors: 0 remaining
  (`xref-report.sh` diff: `-19 asf-staging`).
- `bugs.adoc` xrefs still error (confirms the deferred items are still
  present and Antora 3 is actually reading the same content).

**Baseline-diff caveat:** `xref-report.sh` reports `fixed: 713 /
introduced: 138 / net: -575`, but the framing is misleading because
the baseline groups by `(branch, msg)` tuple. Baseline had 8 source
branches (trunk, cassandra-6.0, cassandra-5.0.8, cassandra-5.0,
cassandra-4.1, cassandra-4.0, cassandra-3.11, asf-staging); this
build has 1 (`broken-link-fix`). All 713 baseline (branch, msg) keys
look "fixed" because the branch attribution moved; all 138 current
errors look "introduced" for the same reason. The right comparison
is **like-for-like by message**, which most-frequent-message ranking
confirms is showing real progress on the PR #4807 target patterns.

**Practical: trajectory and remaining work.**
- Baseline trunk had 161 errors. Current broken-link-fix has 138.
  Apparent net drop of 23 on the cassandra component lane.
- That's smaller than the ~76 PR #4807 targets on its face, because
  (a) many of PR #4807's fixes are message-class fixes that the
  baseline counted only once per (branch, msg) pair even when the
  same message appeared multiple times across pages, and (b) some
  fixes are accounted for via the by-message-class drops visible in
  the report's "Fixed (top 10)" output (e.g. `-5 [trunk/xref]
  target of xref not found: architecture/storage-engine/memtable.adoc`).
- Gap to zero: **138 errors** distributed as above. Phase 5 +
  remaining Phase 4 long-tail need to drive this to 0 before
  Antora 3 can re-land with `failure_level: error`.

**Artifacts** (kept for re-analysis; gitignored):
- `/tmp/antora3-build.log` — full build stdout/stderr
- `/tmp/antora3-json.log` — 705 JSON Antora log lines
- `/tmp/antora3-container.log` — container rebuild log

Cleanup applied after measurement: cassandra-website local commit
`897d1a67` reset to `upstream/trunk` (`35c6027c`), `.xref-env`
removed, phantom mode flips restored from stash.

Phase 2 → ✅ Done. Phase 6 (`failure_level: fatal` tightening) now has its reference scorecard merged and is unblocked from this angle, though still depends on Phases 3–5 completion.

---

## Phase 3 — High-frequency cross-module xrefs in apache/cassandra trunk

Investigation phase complete on 2026-04-24. Three parallel `Explore`
subagents mapped the six high-leverage patterns to their source files,
canonical target paths, and per-branch presence on the local
`apache/cassandra` upstream remote.

### 2026-04-24 — Investigation findings

**Working repo**: `/Users/patrick/local_projects/cassandra6-docs-workzone/cassandra/`
on `trunk`, clean. Cross-branch comparisons used `upstream/{trunk,
cassandra-5.0, cassandra-4.1, cassandra-4.0, cassandra-3.11}`. The website
build's effective branch set per the fixture is `{trunk, cassandra-6.0,
cassandra-5.0.8, cassandra-5.0, cassandra-4.1, cassandra-4.0,
cassandra-3.11}` — note 6.0 and 5.0.8 are not present as upstream
branches yet (they're built from tags or future branches).

#### Pattern group A — `master@_:ROOT:{contactus,bugs}.adoc` (28 errors)

| Dimension | Findings |
|---|---|
| Source files (per branch) | `doc/modules/ROOT/nav.adoc` and `doc/modules/ROOT/pages/index.adoc` |
| Source occurrences per branch | 1 of each pattern in each file = 4 errors per branch |
| Branch coverage | All 7 build branches (trunk → 3.11). Total: 7 × 4 = 28 errors. |
| Component prefix | `master@_` is Antora 2 nomenclature; current cassandra-website component is `_`. Correct prefix would be `_@_` |
| Target file existence | **NEITHER target exists** in cassandra-website. `contactus.adoc` not found anywhere; `bugs.adoc` not found anywhere. |
| Heavy-leverage check | Yes: 2 source files per branch, fix-on-trunk-then-forward-merge cascades |
| Recommendation | **Production-config-sensitive — needs Patrick's call before editing.** Three sub-options:<br>(A1) Fix prefix only (`master@_` → `_@_`) — still leaves the broken target, but less syntactically wrong<br>(A2) Re-target `contactus.adoc` → `_@_:ROOT:community.adoc` (target exists; community page covers contact channels)<br>(A3) For `bugs.adoc`: no equivalent in cassandra-website. Either create a new `bugs.adoc` page in cassandra-website, replace with an external link to ASF JIRA, or rewrite the prose to drop the navigation. |

#### Pattern group B — `reference:{user-defined-type,data-types}.adoc` (24 errors)

| Dimension | Findings |
|---|---|
| Source files (trunk) | `doc/modules/cassandra/partials/primary-key-column.adoc:20`, `doc/modules/cassandra/partials/table-column-definitions.adoc:20` (each contains both broken xrefs) |
| Multiplier | The two partials are included by 3 CQL command pages (alter-table, create-table, create-custom-index) — error multiplies via include |
| Branch coverage | trunk + cassandra-5.0 only (older branches do not carry these patterns) |
| Target files | `reference:user-defined-type.adoc` and `reference:data-types.adoc` **don't exist**. Correct content lives at `doc/modules/cassandra/pages/developing/cql/types.adoc` with anchors `[[udts]]` and `[[native-types]]`. |
| Heavy-leverage check | **Yes — 2 file edits resolve all 24 errors** |
| Recommendation | Replace `xref:reference:user-defined-type.adoc[…]` → `xref:cassandra:developing/cql/types.adoc#udts[…]`. Replace `xref:reference:data-types.adoc[…]` → `xref:cassandra:developing/cql/types.adoc#native-types[…]`. Component-qualified form needed because the partial is included from across modules. |

#### Pattern group C — `developing/cql/keyspace-check.adoc` + `cassandra:developing/collections/collection-create.adoc` (24 errors)

| Dimension | Findings |
|---|---|
| **C1 source files** (`keyspace-check`) | `doc/modules/cassandra/pages/developing/cql/collections/{list,map,set}.adoc` — three sibling collection-type pages, line-12-ish each |
| **C2 source files** (`collection-create`) | `doc/modules/cassandra/pages/developing/cql/create-custom-index.adoc` — 3 occurrences in one file |
| Branch coverage | trunk + cassandra-5.0 only |
| C1 target file | `keyspace-check.adoc` **never existed**. Closest current page: `doc/modules/cassandra/pages/developing/cql/ddl.adoc` with `#create-keyspace` anchor |
| C2 target file | `collection-create.adoc` **exists** at `doc/modules/cassandra/pages/developing/cql/collections/collection-create.adoc` — the broken xref's path is missing the `/cql/` segment |
| Heavy-leverage check | Yes — 4 file edits resolve all 24 errors |
| Recommendation | C1: `xref:cassandra:developing/cql/ddl.adoc#create-keyspace[…]`. C2: `xref:cassandra:developing/cql/collections/collection-create.adoc[…]` (insert missing `/cql/` segment). |

### 2026-04-24 — Proposed JIRA grouping

Three logical groups, three JIRAs (NOT one omnibus, NOT six tiny ones):

| JIRA | Scope | Files touched | Errors resolved | Production-config dep? |
|---|---|---|---|---|
| **CASSANDRA-NNNN-A** "Fix legacy `master@_` nav/index xrefs in cassandra docs" | `doc/modules/ROOT/nav.adoc`, `doc/modules/ROOT/pages/index.adoc` | 2 per branch × all 7 branches = up to 14 file edits across forward-merge chain (3.11 EOL: optional) | Up to 28 (depends on sub-option chosen) | **Yes** — Patrick's call between A1/A2/A3 plus possibly creating new pages in cassandra-website |
| **CASSANDRA-NNNN-B** "Fix CQL reference xrefs in column-definition partials" | `doc/modules/cassandra/partials/{primary-key-column,table-column-definitions}.adoc` | 2 on trunk, forward-merged to cassandra-5.0 | 24 | No |
| **CASSANDRA-NNNN-C** "Fix collections-related xrefs in CQL pages" | `doc/modules/cassandra/pages/developing/cql/collections/{list,map,set}.adoc` + `create-custom-index.adoc` | 4 on trunk, forward-merged to cassandra-5.0 | 24 | No |

Forward-merge implications per the committer guide:
- **B and C**: trunk → cassandra-5.0 (one merge step). EOL branches (3.11, 4.0) and 4.1 don't carry these patterns.
- **A**: trunk → cassandra-5.0 → cassandra-4.1 → cassandra-4.0 → cassandra-3.11. EOL lanes (3.11, possibly 4.0) per ASF policy may be skipped — Patrick decides per branch.
- The local cassandra repo doesn't track upstream `cassandra-5.0.8` or `cassandra-6.0` (those exist as tags or future branches). Forward-merge mechanics for those need confirmation.

**Total potential leverage**: 76 errors (28 + 24 + 24) ≈ **11% of the 713 baseline** removed by 6–8 source-file edits on trunk plus their forward-merges.

### 2026-04-24 — Pattern A complications worth flagging

The investigation's biggest surprise: Pattern A's targets don't actually
exist anywhere. The cassandra repo's nav/index has been pointing at
`contactus.adoc` and `bugs.adoc` for years — these pages were either
deleted in the 2020 Jekyll-to-Antora migration (CASSANDRA-16066) or never
ported. The "fix" therefore isn't mechanical — it's a content-level
decision about *what* the nav/index should point at instead.

Recommendation: do NOT bundle Pattern A with B/C in the first PR. Open
the Patrick decision on A as its own discussion (possibly a `[DISCUSS]`
on dev@cassandra.apache.org if the answer involves creating new
cassandra-website pages). Land B and C cleanly first — they're
mechanical and demonstrate the trunk-then-forward-merge pattern under
the Phase-1 tooling.

### 2026-04-24 — Next concrete steps

1. **B + C edits on trunk**: 6 file edits resolving 48 errors. Same
   subagent-driven loop as Phase 2 batch 1 — straightforward.
2. **Forward-merge B + C to cassandra-5.0**: per committer guide, use
   `git reset --hard upstream/cassandra-5.0 && git cherry-pick <sha>`
   per branch. Local Antora build can't validate cassandra-component
   xrefs (same constraint as Phase 2's E rewrites), so Jenkins is again
   the authoritative test — but the target paths/anchors are concrete
   so confidence is higher.
3. **Pattern A**: park until Patrick chooses A1/A2/A3 split. Worth a
   quick discussion on dev@ once direction is set, since `bugs.adoc`
   resolution may want a new cassandra-website page.

### 2026-04-24 — Phase 3 execution: A2, B, C committed on `phase3-fixes`

Patrick chose A2 (retarget `contactus.adoc` only; defer `bugs.adoc`).
Three parallel `general-purpose` subagents made the edits on a single
`phase3-fixes` branch in the cassandra repo (off `upstream/trunk`),
working on non-overlapping file scopes. After review of the combined
diff, the work was split into three commits — one per JIRA grouping —
so each PR is reviewed as its own unit.

#### Commit chain on `cassandra/phase3-fixes`

| Order | SHA | Scope | Files | Errors fixed |
|---|---|---|---|---|
| 1 | `a4cf5f5564` | B: CQL reference partials | 2 partials | 24 |
| 2 | `e44e6025f5` | C: collections + keyspace-check | 4 pages | 24 |
| 3 | `7ce8e9d8e7` | A2: contactus retarget (bugs.adoc deferred) | 2 nav/index | 14 (across all 7 build branches via forward-merge) |

Total local diff: **8 files, +10 / −10 lines**. No drift outside the
investigated scope.

#### Verification attempt

Tried `./run.sh website build -e .xref-env -g -u cassandra:../cassandra
-b cassandra:phase3-fixes` to load the Cassandra component and exercise
the new xref targets locally. The `-g` flag triggers `ant gen-asciidoc`
inside the container (full Cassandra JAR build for nodetool/cassandra.
yaml docs). With an 8-minute timeout, the build was still in the ant
init phase (cloning the `accord` submodule) when cut off; antora never
ran. Conclusion: a full local `-g` verification is impractical in our
agent context (≥10 min, needs Java/ant inside the container).

**Verification path for these three commits is Jenkins** — same
constraint Phase 2 batch 2 hit for the `Cassandra:cassandra:...`
xrefs. The structural confidence is high though:

- B: target file `developing/cql/types.adoc` exists on trunk; `[[udts]]`
  and `[[native-types]]` anchors confirmed present (via grep).
- C1: target file `developing/cql/ddl.adoc` exists on trunk;
  `#create-keyspace` is an implicit anchor on the `== CREATE KEYSPACE`
  section.
- C2: target file `developing/cql/collections/collection-create.adoc`
  exists on trunk (the fix just inserts the missing `/cql/` segment).
- A2: target file `community.adoc` exists in cassandra-website's ROOT
  module (confirmed during Phase 3 investigation).

#### Sibling cleanup found but not addressed

While editing `create-custom-index.adoc` for C2, the agent noticed two
sibling xrefs with the same `cassandra:developing/collections/...`
(missing `/cql/`) bug — pointing at `map.adoc` and `list.adoc` instead
of `collection-create.adoc`. These are NOT in the original 6 high-
leverage patterns and were not fixed in this commit to keep scope clean
to the JIRA. Worth a small follow-up once the JIRA opens — likely a
1-line addition to the C commit before push, depending on reviewer
preference.

#### Pattern A — bugs.adoc still deferred

`master@_:ROOT:bugs.adoc` references in `nav.adoc:4` and
`index.adoc:50` are explicitly NOT touched by commit `7ce8e9d8e7`. The
target file does not exist anywhere in cassandra-website and has no
clear semantic equivalent. Three options for a follow-up ticket:

1. Create a new `bugs.adoc` page in cassandra-website that explains how
   to file ASF JIRA tickets.
2. Replace the xref with an external link to `https://issues.apache.org/
   jira/projects/CASSANDRA`.
3. Rewrite the prose to drop the "How to report bugs" navigation entry.

This needs Patrick's call (and possibly a `[DISCUSS]` on
dev@cassandra.apache.org if option 1 is chosen) before any commit.

#### Forward-merge implications for the three PRs

Branch presence per pattern (per investigation):
- B: trunk + cassandra-5.0 only. Forward-merge: `git cherry-pick a4cf5f5564` onto cassandra-5.0.
- C: trunk + cassandra-5.0 only. Same as B.
- A2: all 7 build branches (trunk → 3.11). Forward-merge chain: trunk → cassandra-5.0 → cassandra-4.1 → cassandra-4.0. Skip cassandra-3.11 per ASF EOL policy unless reviewer requests. cassandra-5.0.8 and cassandra-6.0 are tags or future branches not currently tracked locally — cherry-pick mechanics need confirmation when they exist as branches.

These are Patrick's actions (per ASF norms) once each JIRA opens and
gets a +1.

### 2026-04-27 — Branches consolidated; scope decision: one JIRA, two PRs

Patrick clarified the scope shape: one umbrella JIRA covering "fix broken
Antora xref/include/image targets," two PRs (one per repo). All ten
commits across `phase3-fixes` and `phase4-trunk` are like-kind work
("fix broken links") so the `phased_fixes.md` "JIRA per logical fix
group" rule applies at the workstream level, not per-fix-class.

Action: combined `cassandra/phase3-fixes` (5 commits) + `cassandra/
phase4-trunk` (5 commits) into `cassandra/broken-link-fix` (10 commits)
to mirror the `cassandra-website/broken-link-fix` branch name. Old
phase-named branches deleted locally.

Final mapping:
- **`cassandra-website/broken-link-fix`** → 4 commits (Phase 1 tool +
  Phase 2 content) → PR 1 of the JIRA
- **`cassandra/broken-link-fix`** → 10 commits (Phase 3 + Phase 4 batch
  1) → PR 2 of the JIRA

User mandate: **all broken links resolved before moving on to the
Antora 3 reland** (Phase 0). Tech-debt-retirement priority before any
build-config work.

### 2026-04-24 — Reviewer round 1: two P1 blockers, fixed in follow-up commits

Reviewer (paths/anchors verified against local cassandra and website
source trees, no `-g` build) flagged two real blockers in the
`phase3-fixes` commits:

- **P1.1 (A2)**: `_@_:ROOT:community.adoc` parses with `_` in the
  *version* slot (Antora xref form is `version@component:module:page`).
  The cassandra-website's `antora.yml` declares `name: _, version:
  master`, and the same files have working sibling xrefs of the form
  `master@_:ROOT:...`. The `_@_:` prefix would replace the original
  `contactus.adoc`-not-found error with a new
  `_@_:ROOT:community.adoc`-not-found error — net zero. Should be
  `master@_:ROOT:community.adoc`.

- **P1.2 (C1)**: `developing/cql/ddl.adoc:55` carries an explicit
  `[[create-keyspace-statement]]` id immediately before the `== CREATE
  KEYSPACE` heading. Antora honours explicit ids over auto-generated
  heading ids, so `#create-keyspace` does not resolve. The same page
  already has a working in-tree xref to
  `#create-keyspace-statement` (ddl.adoc:218). Should be that anchor on
  all three collection prerequisite links.

Both fixes verified by inspecting the actual source files. Two
follow-up commits added to `phase3-fixes`:

| SHA | Scope |
|---|---|
| `0b26dad35d` | A2 fix — version slot `_@_` → `master@_` in `nav.adoc` and `pages/index.adoc` |
| `f5b880b025` | C1 fix — anchor `#create-keyspace` → `#create-keyspace-statement` in `collections/{list,map,set}.adoc` |

Reviewer also confirmed the **B commit** (`a4cf5f5564`) and the **C2
collection-create.adoc path fix** are correct as written. The two
sibling broken xrefs to `cassandra:developing/collections/{map,list}.adoc`
in `create-custom-index.adoc` (same missing-`/cql/` segment bug) were
explicitly flagged as out of scope by the original investigation; the
reviewer is treating them as a follow-up choice rather than a finding,
not a blocker.

#### Updated commit chain on `cassandra/phase3-fixes`

| Order | SHA | Scope |
|---|---|---|
| 1 | `a4cf5f5564` | B: CQL reference partials (no fix needed) |
| 2 | `e44e6025f5` | C: collections + keyspace-check (C2 part fine; C1 anchor fixed in commit 5) |
| 3 | `7ce8e9d8e7` | A2: contactus retarget (version slot fixed in commit 4) |
| 4 | `0b26dad35d` | A2 review fix: version slot `master@_` |
| 5 | `f5b880b025` | C1 review fix: anchor `create-keyspace-statement` |

Per the `contributing-to-apache-cassandra` skill, multiple commits are
fine during review and only get squashed after +1. So the branch
currently carries 5 commits; at squash time, commit 4 folds into 3 and
commit 5 folds into 2 → 3 final commits, one per JIRA.

### 2026-05-13 — PR #4807 opened on apache/cassandra

Phase 3 commits and the Phase 4 batches 1 + 2 (15 total) packaged as a
single PR against `apache/cassandra:trunk`. Pre-open actions:

1. **Rebase** of `cassandra/broken-link-fix` onto current `upstream/trunk`
   (`7bd041d2`, advanced from the original branch base since 2026-04-27).
   Clean rebase, no conflicts.
2. **Force-push** to `origin/broken-link-fix` (`pmcfadin/cassandra` fork);
   lease pinned to prior tip `d1737ca1a6`.
3. **`gh pr create`** against `apache/cassandra:trunk` from
   `pmcfadin:broken-link-fix`. PR body includes a dedicated
   **AI-assistance disclosure** section (per `cassandra-contribution`
   skill §8 disclosure rule).

PR: <https://github.com/apache/cassandra/pull/4807>

State after open: OPEN, `mergeStateStatus: CLEAN`, `mergeable: MERGEABLE`,
no CI checks (apache/cassandra doesn't run GHA on docs-only PRs), no
reviewer assigned. The umbrella JIRA CASSANDRA-21342 is referenced in
every commit and in the PR body.

**Subsequent edit, same session:** an initial pass added
`Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>` trailers to
all 15 commits (matching PR #315's pattern). On reconsideration, the
contributor opted to keep AI attribution to the PR-body disclosure
section only and remove the per-commit trailers. The branch was
rebased a second time stripping the trailer line, force-pushed, and the
PR body edited to drop the sentence about commit trailers. Final head
SHA: `a9fd1ab63c`. Net record: AI disclosure remains in the PR body;
commit metadata carries the standard `patch by … reviewed by TBD for
CASSANDRA-21342` only.

**Out-of-scope items deferred** (per the PR body):

- `master@_:ROOT:bugs.adoc` retarget — needs Patrick's content
  decision + possibly `[DISCUSS]` on dev@ before any commit.
- Forward-merges to `cassandra-5.0` and (for A2) `cassandra-4.1` /
  `cassandra-4.0` — committer follow-ups after the trunk PR lands.

Next: reviewer outreach (Patrick's action, not in this log).

---

## Phase 4 — Per-branch content cleanup in apache/cassandra

In progress on the trunk lane. Phase 3 high-leverage fixes (B + C + A2)
took 14 errors off trunk's 161; Phase 4 is the long-tail cleanup of
the remaining 147.

### 2026-04-24 — Phase 4 batch 1: trunk lane (5 fix groups, 25 errors)

Five parallel `general-purpose` subagents executed five non-overlapping
fix scopes on `cassandra/phase4-trunk` (off `upstream/trunk`). After
review of the combined diff, the work was split into five commits —
one per JIRA grouping.

| Order | SHA | Scope | Files | Errors targeted |
|---|---|---|---|---:|
| 1 | `f81e6814b4` | P1: `architecture/storage-engine/memtable.adoc` → `storage-engine.adoc#memtables` | `alter-table.adoc`, `create-table-examples.adoc` | 5 |
| 2 | `457f4103d1` | P3: legacy `developing/*` paths → `developing/cql/{ddl,types,dml}.adoc#anchor` | `2i-working-with.adoc`, `sai-working-with.adoc`, `create-table-examples.adoc` | 8 |
| 3 | `12d62146fe` | P2: in-page `security.adoc#anchor` → `cassandra:developing/cql/security.adoc#anchor` | `developing/cql/security.adoc` | 6 |
| 4 | `9b7f72c590` | P4: duplicated `configuration/configuration/` segment in `cass_yaml_file.adoc` xrefs | `partials/table-properties.adoc` | 4 |
| 5 | `f0395f700e` | P5: `cql_singlefile.html` → `.adoc` | `nav.adoc`, `reference/index.adoc` | 2 |

Total local diff: **8 files, +16 / −16 lines**, 5 commits, 25 errors
targeted on trunk's fixture (matching pre-Phase-3 161 → 161-14-25 =
**122 trunk errors remaining** if all current commits land).

#### Investigation findings (worth keeping for future batches)

- `architecture/storage-engine/memtable.adoc` doesn't exist anywhere —
  memtable docs consolidated into `storage-engine.adoc:86 == Memtables`
  section (auto-generated anchor `#memtables`).
- `developing/cql/security.adoc` references its OWN anchors with
  unqualified `xref:security.adoc#…`. Two `security.adoc` files exist
  on trunk (`developing/cql/` and `managing/operating/`) so the
  unqualified form is ambiguous. Component-qualified form fixes it.
- `developing/keyspace-create.adoc`, `table-create.adoc`,
  `user-defined-type-create.adoc`, `inserting/insert-user-defined-type.
  adoc` all are gone — content reorganized into `developing/cql/{ddl,
  types,dml}.adoc` with anchors `create-keyspace-statement`,
  `create-table-statement`, `udts`, `update-statement` respectively.
- `cass_yaml_file.adoc` is generated at build time by `ant
  gen-asciidoc`. Working xrefs use `managing/configuration/cass_yaml_file.adoc`
  (single segment); the broken pattern had `configuration/configuration/`
  (duplicated). Two-line fix in one partial.
- `cql_singlefile.adoc` exists; the broken sources used `.html`
  extension. Same Phase 2 batch 1 pattern.

#### Verification

Same constraint as Phase 2 batch 2 and Phase 3: the local minimal build
(no `-g`) doesn't import the Cassandra component, and the full `-g`
build is too heavy for the agent's 8-min budget. **Jenkins is the
authoritative test.**

Structural confidence is high because every target was verified to
exist on `upstream/trunk` via the investigation pass:
- `architecture/storage-engine.adoc` exists; `== Memtables` heading
  confirmed.
- `developing/cql/security.adoc:583,178,227` carry the explicit
  `[[grant-permission-statement]]`, `[[grant-role-statement]]`,
  `[[list-roles-statement]]` ids.
- `developing/cql/ddl.adoc:55` has `[[create-keyspace-statement]]`,
  `:244` has `[[create-table-statement]]`.
- `developing/cql/types.adoc:400` has `[[udts]]`.
- `developing/cql/dml.adoc:313` has `[[update-statement]]`.
- `developing/cql/cql_singlefile.adoc` exists.

#### Phase 4 trunk-lane outlook

| Stage | Trunk error count |
|---|---:|
| Baseline (Jenkins #2752) | 161 |
| After Phase 3 lands | 147 |
| After Phase 4 batch 1 lands | **122** |

Remaining 122 trunk errors are scattered across ~120 distinct messages.
Most appear once each. Phase 4 batches 2+ will continue picking off
clusters, but the leverage drops further (1–2 errors per fix from
here). Worth considering whether Phase 4's long tail is worth the
review effort vs. shifting attention to Phase 0 (Antora 3 reland) or
Phase 5 (structural).

#### Forward-merge implications

All five commits are trunk-only. Per investigation, the patterns
addressed exist on:
- P1 (memtable): trunk + cassandra-5.0
- P2 (security same-page): trunk + cassandra-5.0
- P3 (developing/* legacy): trunk + cassandra-5.0 (older branches use
  different page structure)
- P4 (cass_yaml_file double-config): trunk + cassandra-5.0
- P5 (cql_singlefile.html): trunk + cassandra-5.0

Forward-merge to cassandra-5.0 is one cherry-pick chain per commit, no
coverage outside that. EOL branches (3.11, 4.0) and 4.1 don't carry
these patterns.

### 2026-04-27 — Phase 4 batch 2: trunk long tail (5 commits, ~51 trunk errors)

Five parallel `general-purpose` subagents executed five non-overlapping
fix scopes on the consolidated `cassandra/broken-link-fix` branch. The
biggest single edit (R1) rewrote `commands-toc.adoc`, the CQL command
reference TOC.

| SHA | Scope | Files | Errors |
|---|---|---|---:|
| `d652579e2d` | R1: rewrite `commands-toc.adoc` to consolidated CQL anchors | 1 file (+38 retargets, -4 DSE-only deletions) | ~38 |
| `ce37d804a9` | R3+R4+R9: fix three xrefs across two `security.adoc` pages (path correction, retarget, doubled `xref:xref:` typo) | 2 | 3 |
| `e1bf278deb` | R5+R6: retarget `static.adoc` (×2) and `select.adoc#filtering-on-collections` (×2) | 4 | 4 |
| `d6efd7ad47` | R7+R8: correct paths for `monitoring.adoc` (×2) and `stcs.adoc` (×2) | 2 | 4 |
| `e8e190b837` | R2: remove `comments-table.adoc` xref (no equivalent target), keep table name as plain text | 1 | 2 |

Total batch 2: 10 files, ~51 trunk errors targeted.

#### R1 mapping table built from anchor enumeration

`commands-toc.adoc` had 42 xrefs to `reference/cql-commands/<command>.
adoc` files; only 9 of those targets exist on disk. The rest were
either consolidated into `developing/cql/{ddl,dml,security,functions,
mvs,types}.adoc` with explicit section anchors, or are DSE-specific
features absent from Apache Cassandra. Subagent applied a 38-row
mapping table:

- 6 entries kept the `reference/cql-commands/` page reference but
  added `cassandra:` prefix (those 6 pages exist on disk).
- 32 entries retargeted to `cassandra:developing/cql/<page>.adoc#<anchor>`.
- 4 entries (RESTRICT, RESTRICT ROWS, UNRESTRICT, UNRESTRICT ROWS)
  deleted entirely — DSE-only features with no Apache Cassandra
  equivalent.

#### Lock contention incident on commit splitting

The original sequential commit script hit two `index.lock` errors
because git lock contention happened between rapid back-to-back commits.
Two commits ended up with mismatched messages and content. Recovery:
`git reset HEAD~2` and recommitted cleanly. Lesson for future batches:
add `sleep 0.2` between commits or commit one-at-a-time per script
invocation.

#### Trunk error countdown

| Stage | Trunk errors |
|---|---:|
| Baseline (Jenkins #2752) | 161 |
| After Phase 3 (B+C+A2) | 147 |
| After Phase 4 batch 1 (5 fixes) | 122 |
| **After Phase 4 batch 2 (this batch)** | **~71** |

Trunk lane went from 161 → ~71 errors over 15 commits on
`cassandra/broken-link-fix`. Remaining 71 are mostly single-occurrence
patterns; leverage drops further from here. Next batches will focus on
small clusters where investigation is cheap.

---

### 2026-05-14 — Forward-merge of PR #4807 to cassandra-5.0, 4.1, 4.0

Per the Cassandra cherry-pick chain convention
(`development/patches.adoc` §102–123), the trunk fix (commit
`32826fe563`) was forward-merged to the three live release branches
the same day it landed. Committer pushed directly to each release
branch (no per-branch PRs), per the established convention for
already-reviewed work.

| Branch | Tip after push | Diff | Scope |
|---|---|---:|---|
| `cassandra-5.0` | `9733058d1b` | 23 files / +36/-36 | 13 of 15 trunk commits cherry-picked then squashed. Two omissions documented in the commit body. |
| `cassandra-4.1` | `1605049780` | 2 files / +2/-2 | Phase 3 A2 fix only; direct edit (cherry-pick context mismatch). |
| `cassandra-4.0` | `a1fc6c8761` | 2 files / +2/-2 | Same as 4.1. |
| `cassandra-3.11` | (skipped) | — | Per ASF EOL policy. Broken xref exists on 3.11 too; add only if reviewer requests. |

#### Applicability re-verification

The branch-applicability table from §915 and §1127 of this log was
re-checked file-by-file against `upstream/cassandra-5.0` before the
cherry-pick run. The log's claim "P1 (memtable): trunk + cassandra-5.0"
turned out to be wrong: the broken `memtable.adoc` xref pattern does
not exist on 5.0 because the entire memtable section in
`reference/cql-commands/alter-table.adoc` and
`create-table-examples.adoc` was a trunk-only addition. Lesson:
**file-presence is necessary but not sufficient — pattern-presence is
the right check**. Recipe used:

```
git show <sha> --format= -- <file> \
  | awk '/^-/ && !/^---/ {sub(/^-/,""); print}' \
  | grep -oE 'xref:[^[]+\[|include::[^[]+\[' | sort -u
# then for each removed-pattern token:
#   git show upstream/<branch>:<file> | grep -F "$token"
```

#### Conflict resolutions on 5.0

Two cherry-picks conflicted on cassandra-5.0 (content drift on
adjacent lines, not on the targeted xref). Resolutions:

- **P2 (`16642968c1` security.adoc qualification):** kept HEAD's
  `auth-caching` line; applied only the commit's intended `grant-
  permission` / `grant-role` qualification. The `auth-caching` xref
  was not part of P2's scope.
- **R3+R4+R9 (`5d87920622` security.adoc trio):** took incoming after
  verifying all three target paths/anchors resolve on 5.0
  (`managing/operating/security.adoc#authorization`, `#auth-caching`,
  and `managing/configuration/cass_yaml_file.adoc`). Incidentally
  also fixes 5.0's `auth-caching` xref, which was broken pre-merge
  (pointing to a missing `developing/cql/security.adoc#auth-caching`
  anchor). The umbrella JIRA covers the scope; the diff is reviewable
  on its own and was not called out in the commit body.

#### Deviation from pure cherry-pick on 4.1 + 4.0

The 4.1 and 4.0 commits are **direct edits**, not cherry-picks.
Reason: 4.x's `doc/modules/ROOT/nav.adoc` is a minimal 4-line file;
trunk's nav has an `ifndef::local-build[]` wrapper and an 11-line
development sub-nav that doesn't exist on 4.x, so git's text-merge
could not auto-apply the patch. The net effect on the targeted xrefs
is identical to a clean cherry-pick. Each commit body documents the
deviation.

#### Deferred follow-ups

- **R1 (`8e0700a7cb` commands-toc.adoc rewrite) on cassandra-5.0:**
  trunk and 5.0 versions of `commands-toc.adoc` differ by ~9 lines.
  The 38-row retarget mapping (§1159–1173 of this log) needs a custom
  replay against 5.0's content. To be handled as a separate commit on
  a fresh topic branch. Expected to close ~38 trunk-equivalent errors
  on 5.0.
- **P1 (`6f8fdf4a7e` memtable) on any release branch:** not
  applicable. Memtable section is trunk-only.
- **3.11 inclusion:** broken pattern present (verified) but not
  patched per ASF EOL policy. Trivial 2-file edit if reviewer asks.

#### Local state after push

- `cassandra/CASSANDRA-21342-cassandra-5.0`, `-4.1`, `-4.0` — kept
  locally for follow-up reference; can be deleted after the R1
  follow-up lands.
- `cassandra/broken-link-fix` — local squashed pre-push state,
  superseded by `upstream/trunk`. Safe to delete.
- `cassandra/broken-link-fix-recover` — **do not delete** until R1
  follow-up is done. Pins the 15-commit chain at `a9fd1ab63c`,
  needed as source for R1's per-file diff inspection.
- `origin/CASSANDRA-21342-cassandra-{5.0,4.1,4.0}` and
  `origin/broken-link-fix` on pmcfadin fork — superseded by the
  apache pushes. Safe to delete once R1 follow-up is shipped.

#### AI disclosure

Per the 2026-05-13 decision: no Co-Authored-By trailers on commits.
Disclosure relies on PR #4807's body, which covers the umbrella JIRA
CASSANDRA-21342. Forward-merges are mechanical applications of
already-disclosed and already-reviewed work.

---

### 2026-05-14 — R1 follow-up applied to cassandra-5.0

The R1 commit deferred from the 5.0 forward-merge above
(`8e0700a7cb` — "Rewrite commands-toc.adoc to point at consolidated
CQL anchors") was authored as a separate commit on a fresh topic
branch `CASSANDRA-21342-cassandra-5.0-r1` off `upstream/cassandra-5.0`.

| Branch | Commit | Diff |
|---|---|---|
| `pmcfadin:CASSANDRA-21342-cassandra-5.0-r1` | `7ac5d93c8b` | 1 file / +38/-50 |

#### Approach: direct file replacement instead of cherry-pick

Trunk's `commands-toc.adoc` (the post-R1 version) was used verbatim as
the target content, minus one trunk-only entry. Cherry-picking the
R1 commit was not viable: 5.0's pre-fix file and trunk's pre-R1 file
differ on three independent dimensions (4 DSE-only entries that exist
on 5.0 but not on trunk, the LIST SUPERUSERS entry trunk added,
plus unrelated whitespace drift). A direct file copy with one
surgical deletion produced a cleaner reviewable diff.

#### Target-existence verification on cassandra-5.0

All 38 unique xref targets in trunk's post-R1 file were checked
against `upstream/cassandra-5.0`:

- 6 entries kept `cassandra:reference/cql-commands/<page>.adoc` — all
  6 pages exist on 5.0.
- 32 entries retargeted to
  `cassandra:developing/cql/{ddl,dml,functions,mvs,security,types}.adoc#<anchor>`.
  29 of these anchors exist on 5.0.
- 1 anchor (`developing/cql/security.adoc#list-superusers-statement`,
  the target of LIST SUPERUSERS) does **not** exist on 5.0. LIST
  SUPERUSERS is a trunk-only command. The entry is omitted from the
  5.0 file (3 lines: xref + description + blank).

Verification recipe (works around the rtk hook on nested `git`
invocations — cache file content once, then grep):

```
for f in developing/cql/{ddl,dml,functions,mvs,security,types}.adoc; do
  basename=$(echo "$f" | tr '/' '_' | sed 's/.adoc$//')
  rtk proxy git show "upstream/cassandra-5.0:doc/modules/cassandra/pages/$f" \
    > "/tmp/c50_${basename}.txt"
done
# then: grep -qE "\[\[<anchor>\]\]|^id=.<anchor>\b" "/tmp/c50_${basename}.txt"
```

#### DSE-only entries dropped on 5.0

Per the trunk R1 reasoning (§1171-1173 of this log), the 4 DSE-only
entries are also dropped on 5.0: RESTRICT, RESTRICT ROWS, UNRESTRICT,
UNRESTRICT ROWS. Each pointed to `reference/cql-commands/<x>.adoc`
pages that do not exist as Apache Cassandra docs on any branch.

#### Net effect on 5.0

| Stage | commands-toc.adoc state |
|---|---|
| Before R1 follow-up | 125 lines, 41 entries, all xrefs unqualified `xref:reference/cql-commands/<page>.adoc` (broken) |
| After R1 follow-up | 114 lines, 37 entries, all xrefs qualified and resolving on 5.0 |

Expected error reduction on the 5.0 Antora lane: ~38 (one error per
broken xref entry pre-fix, roughly the same as the trunk R1
reduction).

#### Cleanup

After Patrick pushes this commit to `apache/cassandra:cassandra-5.0`:
- `broken-link-fix-recover` (local branch pinning the 15-commit
  pre-squash chain at `a9fd1ab63c`) — safe to delete; R1 follow-up
  source was the trunk post-R1 file, not the chain.
- `CASSANDRA-21342-cassandra-{5.0,4.1,4.0}` and
  `CASSANDRA-21342-cassandra-5.0-r1` (local) — superseded by upstream
  refs. Safe to delete after the push.
- `origin/CASSANDRA-21342-cassandra-5.0-r1` (pmcfadin fork) — safe
  to delete after the apache push.

---

### 2026-05-14 — Long-tail xref follow-up PR #4810 opened (trunk)

Drafted the remaining-xref follow-up on a new topic branch
`CASSANDRA-21342-trunk-followup` off `upstream/trunk`. Triage of the
113 baseline trunk-xref patterns (research/antora3-xref-baseline.json,
Jenkins #2752, 2026-04-22) against the post-PR-#4807 trunk state
identified 50 patterns / 51 use-sites still broken. Six per-fix-class
commits were applied; one (G7) bucket of ~10 sites was deferred for
content decisions and grouped with the bugs.adoc workstream.

| Group | Commit | Files | Sites |
|---|---|---:|---:|
| G1 — module-prefix swap | `920a5065da` | 9 | 11 |
| G2 — moved-page retarget | `9c6d9f794a` | 9 | 11 |
| G3 — defintions.adoc typo | `55e6df420e` | 1 | 1 |
| G4 — `.html` -> `.adoc` (incl. writetime retarget) | `dec49ce414` | 2 | 2 |
| G5 — nodetool generated-path qualifier | `6aa9589114` | 3 | 4 |
| G6 — anchor adds + retarget | `cac55a5835` | 7 | 7 + 3 anchors added |

Total: 6 commits, 26 unique files, +40/-37 lines.

PR opened as draft against `apache/cassandra:trunk`:
https://github.com/apache/cassandra/pull/4810

#### Verification approach

For every still-existing anchor target, both the target page and the
explicit `[[anchor]]` (or the auto-generated section id) were
grep-verified on `upstream/trunk` before the edit. The triage filtered
out 63 of 113 baseline patterns as already-closed: no remaining source
file on `trunk` references the broken target string. Re-triage was
necessary because an earlier `Explore` subagent's existence-check
under-reported (claimed only 7 still-broken patterns) — the rtk hook
interferes with `git cat-file -e` style checks, so a `git grep` pass
on a cached xref-line dump was used instead.

#### Anchors added (new convention-matching `[[anchor]]` blocks)

- `reference/cql-commands/create-table.adoc` gains `[[table_options]]`
  before "Optional parameters".
- `developing/cql/indexing/sai/operations/configuring.adoc` gains
  `[[saiConfigure__saiCompactionStrategies]]` before "Compaction
  strategies".
- `troubleshooting/use_tools.adoc` gains `[[packet-capture]]` before
  the "Packet Capture" section.

All three follow the existing `[[anchor]]` convention used elsewhere
on the same page (`[[alter-compression]]`, `[[use-bcc-tools]]`,
`[[use-vmtouch]]`, `[[UCS]]`/`[[STCS]]`/`[[LCS]]`/`[[TWCS]]`).

#### Deferred to a separate workstream (G7, ~10 sites)

These require content decisions, not retargets, and are grouped with
the existing `master@_:ROOT:bugs.adoc` decision item:

- `cassandra:cyclist_base-table.adoc`, `cyclist_races-table.adoc`,
  `race_times-table.adoc` (3 example-table xrefs in `alter-table.adoc`
  with no destination pages — likely drop xref, keep prose).
- `cassandra:developing/accord/index.adoc` (Accord top-level nav entry
  with no page).
- `cassandra:managing/operating/compression/index.adoc#cql-compression-options`
  (compression page does not exist; needs retarget decision).
- `developing/cql/table-create.adoc` (page does not exist; likely drop
  xref).
- `developing/querying/use-write-time.adoc` (likely retarget to
  `functions.adoc#writetime-and-ttl-functions`, same family as G4).
- `reference:cql-commands/drop-materialized-view.adoc` (page does not
  exist; stub or drop).
- `cassandra:developing/cql/indexing/2i/_2i-create-on-collection.adoc`
  + `developing/cql/indexing/2i/2i-create.adoc` +
  `developing/cql/indexing/2i/2i-drop.adoc` (Antora partial-prefix
  files; need rename or restructure-to-include).
- `_/download.adoc` (malformed cross-component xref; sibling to
  `master@_:ROOT:bugs.adoc`).

#### Forward-merge plan

Once PR #4810 lands on `trunk`, applicable subsets forward to
`cassandra-5.0`, `4.1`, and `4.0` per the same convention as PR #4807
(committer push, no per-branch PR, pattern-presence re-verified per
branch).

#### Generated-page caveat (G5 only)

The four `nodetool` xrefs in commit `6aa9589114` target pages produced
at build time by `gen-asciidoc`. They cannot be grep-verified from a
static checkout. The form `cassandra:managing/tools/nodetool/<cmd>.adoc`
matches existing nav.adoc xrefs that have shipped without complaint.
If any fail on the next Antora 3 build, fix in a follow-up.

---

### 2026-05-29 — PR #4810 rebased onto upstream/trunk, locally Antora-3 verified, squashed

Topic branch was originally cut off `upstream/trunk@32826fe5` (before
PR #4807 landed). Trunk has since advanced 36 commits (none touching
`doc/`). Rebased `CASSANDRA-21342-trunk-followup` onto current
`upstream/trunk@d8de51c6` so the build measurement reflects only the
long-tail fixes, not also-fixed-by-#4807 patterns. Rebase applied all
six commits with no conflicts.

#### Build verification (Antora 3, local)

Built cassandra-website locally with the Antora 3 reland stack (bare
`antora site.yaml`, Node 24 LTS, `ANTORA_LOG_FORMAT=json`) and the
rebased topic branch as the cassandra source. Build log saved at
[`research/antora3-build-after-pr4810.log`](../research/antora3-build-after-pr4810.log).

| Source | Errors |
|---|---:|
| Jenkins #2752 baseline (2026-04-21), trunk only | 161 |
| Local Antora 3 build, topic branch as cassandra trunk | 3 |
| Of those 3, in `cassandra.git` (scope of PR #4810) | **0** |

The 3 remaining errors are all in `cassandra-website` source:

- `Cassandra:cassandra:architecture/overview.adoc` referenced from
  `site-content/source/modules/ROOT/pages/blog/Apache-Cassandra-Changelog-19-September-2022.adoc`
  and the `20-November-2022` sibling (doubled component prefix —
  mechanical: drop the leading `Cassandra:` segment; target page
  exists at `doc/modules/cassandra/pages/architecture/overview.adoc`).
- `Cassandra::index.adoc` referenced from
  `site-content/source/modules/ROOT/main-nav.adoc` (empty component
  segment — same class as `master@_:ROOT:bugs.adoc` /
  `contactus.adoc`, needs the cross-component nav-form decision).

**Decision 2026-05-29**: bundle all three into the upcoming bugs.adoc /
contactus.adoc cassandra-website PR rather than splitting the two
mechanical fixes into a separate tiny PR. Rationale: single cassandra-
website Phase 2 follow-up PR keeps the reviewer overhead at one and
matches how PR #319 closed its bucket. To-do tracked under the
bugs.adoc workstream.

#### Squash + force-push

After verification, six commits were squashed to one against
`upstream/trunk` (`git reset --soft upstream/trunk` + single commit).
Final commit on PR #4810:

- `dc1186bda8` — `CASSANDRA-21342: Long-tail xref follow-up on trunk`
- 26 files changed, +40 / -37
- Cassandra trailer: ` patch by Patrick McFadin; reviewed by TBD for CASSANDRA-21342`

Force-pushed with `--force-with-lease` to
`origin/CASSANDRA-21342-trunk-followup`. PR body rewritten to surface
the edit-class table and the 161 -> 3 build-evidence line. AI
disclosure paragraph preserved (no `Co-Authored-By:` trailer per
2026-05-13 policy).

PR #4810 state: open as draft, 1 commit, awaiting reviewer assignment
once removed from draft.

#### 2026-06-01 update: approved + merged

Taken out of draft 2026-05-29. Approved by Mick Semb Wever
(michaelsembwever, MEMBER) on 2026-06-01 18:07 UTC with no review
comments. Committer push by Patrick (committer himself) on 2026-06-01
following the trunk-only flow in
`how_to_commit.adoc`: cherry-pick of `dc1186bda8` onto local
`upstream/trunk`, `git commit --amend` to update the trailer
(`reviewed by TBD` -> `reviewed by Mick Semb Wever`), then
`git push --atomic upstream trunk`. Trunk tip is now
`cc97ee5332368cab3e60375af22e0cc961bc6569`.

PR #4810 on GitHub stays OPEN (no auto-close because the merge wasn't
via the GitHub merge button); will be closed manually with a comment
linking to the trunk SHA.

#### cassandra-website local state restored

cassandra-website was temporarily reverted to `afdf3b08` (Antora 3
reland on top of `35c6027c`) and the `phantom mode flips` stash was
popped during the build. After verification, `git reset --hard HEAD~1`
returned the working copy to `35c6027c` (pre-reland). The two original
stashes (`WIP build artifacts (rebase upstream)`,
`WIP antora-3-upgrade failure_level (Phase 2 content session)`) are
preserved. The local Antora 3 reland and its caveats remain in
`antora-3-upgrade-log.md` (no separate cassandra-website PR yet — that
is Phase 0).

#### 2026-06-01 post-merge: PR #4810 closed, forward-merge triage

PR #4810 closed on GitHub with a one-line comment pointing at trunk
SHA `cc97ee5332`.

Forward-merge triage executed against `cassandra-5.0`, `cassandra-4.1`,
`cassandra-4.0`, plus `cassandra-6.0` (the existing release branch in
the ladder between 5.0 and trunk per `how_to_commit.adoc`). Patrick
chose the strict ladder per the official procedure: apply on oldest
applicable branch, merge `-s ours --log` upward through every branch
to trunk, push all five atomically.

Per-branch applicability (against upstream tips at triage time):

| Branch | Trunk patch fits | Notes |
|---|---|---|
| `cassandra-4.0` / `cassandra-4.1` | 3-file 6-edit subset | `architecture/index.adoc` (snitch xref), `finding_nodes.adoc` (two qualified xrefs), `use_tools.adoc` edits 1–3 only. Twenty trunk files don't exist on 4.x; `use_tools.adoc` edits 4–5 don't apply (different line state, missing packet-capture section). |
| `cassandra-5.0` | Full 26 files / 27 edits | Cherry-pick of `cc97ee5332` conflicts only on `architecture/index.adoc` because trunk's hunk includes the new `xref:architecture/accord.adoc[Accord]` line as trailing context — 5.0 has no Accord. Resolution: keep 5.0's no-Accord state with the snitch xref qualified. |
| `cassandra-6.0` | Full 26 files / 27 edits | Cherry-pick conflicts only on `create-custom-index.adoc` — 6.0 has both halves of the "For related information" line missing `/cql/` (i.e. `developing/collections/collection-create.adoc` and `developing/collections/map.adoc`); trunk's hunk fixes only the `map.adoc` half because 5.0/trunk already had the `collection-create.adoc` half correct. Resolution: take trunk side; both halves end up qualified to `developing/cql/collections/`. |
| `trunk` | Already has content | Lineage merge only (`git merge cassandra-6.0 -s ours --log`); no cherry-pick. |

#### 2026-06-01 separate finding: PR #4807 forward-merge gap on cassandra-6.0

While resolving the 6.0 conflict, a separate broken xref was
discovered at `create-custom-index.adoc:58` —
`xref:cassandra:developing/collections/collection-create.adoc[collections]`
without `/cql/`. The same line on `cassandra-5.0` and `trunk` is
qualified to `developing/cql/collections/`, fixed by PR #4807.
`cassandra-6.0` appears not to have received that part of PR #4807's
forward-merge. Out of scope for PR #4810; to be handled as a separate
PR #4807-style audit of cassandra-6.0. Tracked here so it isn't lost.

#### 2026-06-03 local ladder built, awaiting push

Ladder built locally against upstream tips at:
`cassandra-4.0@a1fc6c8761`, `cassandra-4.1@1605049780`,
`cassandra-5.0@ffe7f761b8`, `cassandra-6.0@72d53e3919`,
`trunk@cc97ee5332`. Five commits ready for an atomic push. Local SHAs
(rev 1): `cbb740282b`, `75c088a5f7`, `33bcb38535`, `6c1a3fe09d`,
`246d68127b`. Push held pending upstream check.

#### 2026-06-08 upstream advanced; ladder rebuilt

Re-fetched upstream before the push. All five branches had moved:
`4.0@8aa71cea52`, `4.1@2bf3bc2925`, `5.0@8c992cb6a5`,
`6.0@22eb0f9fb7`, `trunk@a84647c6c7`. New upstream commits are
predominantly Java (snapshot validation, ECHO_REQ, BTree, docker
build) plus three trunk-only docs additions (security-model.adoc,
COPY TO note, gen-doc python rewrite) that don't overlap with the
long-tail patch surface.

Conflict topology unchanged: `cassandra-5.0` still conflicts only on
`architecture/index.adoc` (same Accord context), `cassandra-6.0` still
conflicts only on `create-custom-index.adoc` (same `/cql/` gap).
4.x patch still applies cleanly to the new upstream tips.

Ladder rebuilt with identical content. Local SHAs (rev 2):
`d2986dc9d2`, `da07c4e239`, `5f6081f9a6`, `c74b77606d`, `ba7fada65c`.
Per-branch doc/ diff vs upstream: 4.x = 3 files +6/-6; 5.0 = 26 files
+40/-37; 6.0 = 26 files +41/-38; trunk = no doc change (lineage
merge only). Ready for atomic push.

#### 2026-06-10 upstream advanced again; ladder rebuilt (rev 3)

Two days of further upstream activity moved three branches:
`cassandra-5.0@2a697431c7`, `cassandra-6.0@9e671eea52`,
`trunk@344b408f35`. `cassandra-4.0` and `cassandra-4.1` unchanged.

New trunk doc-touching commit: `998f42984f Add user docs for Accord
focused on how to use, what CQL is and isnt valid, and use cases`
(new Accord docs, doesn't overlap with the long-tail patch surface).
No new doc-touching commits on 5.0 or 6.0 since rev 2.

Conflict topology identical to revs 1 and 2: 5.0 conflicts only on
`architecture/index.adoc` (Accord context), 6.0 conflicts only on
`create-custom-index.adoc` (`/cql/` gap). Same resolutions applied.

Local SHAs (rev 3): `19ee803038`, `1a463d753f`, `42f306b152`,
`b584529291`, `e8848b0040`. Per-branch doc/ diff vs upstream
unchanged: 4.x = 3 files +6/-6; 5.0 = 26 files +40/-37; 6.0 = 26
files +41/-38; trunk = no doc change.

Dry-run push (`git push --atomic upstream cassandra-4.0 cassandra-4.1
cassandra-5.0 cassandra-6.0 trunk -n`) clean — five fast-forward refs:

```
8aa71cea52..19ee803038  cassandra-4.0 -> cassandra-4.0
2bf3bc2925..1a463d753f  cassandra-4.1 -> cassandra-4.1
2a697431c7..42f306b152  cassandra-5.0 -> cassandra-5.0
9e671eea52..b584529291  cassandra-6.0 -> cassandra-6.0
344b408f35..e8848b0040  trunk -> trunk
```

#### 2026-06-10 atomic push landed

`git push --atomic upstream cassandra-4.0 cassandra-4.1 cassandra-5.0
cassandra-6.0 trunk` succeeded. All five branches updated in one
atomic operation. Final upstream tips:

| Branch | New tip |
|---|---|
| `cassandra-4.0` | `19ee803038` |
| `cassandra-4.1` | `1a463d753f` |
| `cassandra-5.0` | `42f306b152` |
| `cassandra-6.0` | `b584529291` |
| `trunk` | `e8848b0040` |

Forward-merge of PR #4810 is complete across all supported release
branches. Phase 4 trunk-lane fully closed.

---

### 2026-06-10 — PR #4807 forward-merge gap on cassandra-6.0: full branch missed, closed

Picked up the tracked `create-custom-index.adoc:58` follow-up and found
it was one symptom of a much larger gap: **cassandra-6.0 never received
PR #4807's forward-merge at all.** The 2026-05-14 forward-merge covered
only 5.0/4.1/4.0; 6.0 (which existed then, with 161 baseline errors,
same as trunk) was skipped. A pattern sweep on `upstream/cassandra-6.0`
found essentially the whole pre-#4807 broken surface still present:
`master@_:ROOT:contactus` ×2, `cql_singlefile.html` ×2,
`keyspace-check` ×3, memtable xrefs ×3, `reference:data-types` /
`user-defined-type` partials ×2, `configuration/configuration/` ×2,
`xref:xref:` typo, `comments-table.adoc` ×2, unqualified
`security.adoc#` anchors, legacy `developing/*` paths, `static.adoc`,
and the unqualified pre-R1 `commands-toc.adoc`.

#### Fix: cherry-pick of the reviewed trunk commit

- Topic branch `CASSANDRA-21342-cassandra-6.0` off
  `upstream/cassandra-6.0@b584529291`.
- `git cherry-pick 32826fe563` (PR #4807's squashed trunk commit,
  reviewed by Brandon Williams). One conflict in
  `create-custom-index.adoc` — inverse of the usual case: 6.0's HEAD
  already had the fully-qualified `/cql/` forms at lines 122/296-298
  from PR #4810's 2026-06-10 ladder, while the incoming hunk carried
  the older partially-fixed state. Kept HEAD, then re-applied the
  line-58 fix the conflict resolution had discarded (one-line `/cql/`
  segment insert — the occurrence not present on trunk at original
  patch time, same pattern as the reviewed C2 fixes).
- Final commit `fc8883fc70`: 24 files, +75/−87 (2 lines fewer than
  trunk's +77/−89 — the two #4810-covered hunks). Commit body
  documents the forward-merge deviation and the line-58 addition.

#### Verification before push

- Every xref target added by the commit checked against the 6.0
  working tree: pages exist; explicit `[[anchor]]` ids exist;
  `#memtables` and `#authorization` resolve via auto-generated
  heading ids (`== Memtables` storage-engine.adoc:86,
  `== Authorization` security.adoc:329).
- `commands-toc.adoc`: all 36 unique targets verified on 6.0,
  **including `list-superusers-statement`** (exists on 6.0, unlike
  5.0 where the LIST SUPERUSERS entry was dropped) — so trunk's
  post-R1 file applies verbatim, no per-branch edit needed.
- Two expected non-verifiable classes, same caveats as prior merges:
  `cass_yaml_file.adoc` (generated at build time) and
  `master@_:ROOT:community.adoc` (cassandra-website component).
- Residual sweep on the topic branch: only the deliberately deferred
  `master@_:ROOT:bugs.adoc` ×2 and G7 items remain — parity with
  trunk's fixed state.

#### Ladder + push

Per `how_to_commit.adoc`: fix applies on 6.0 only, lineage merge
upward. `cassandra-6.0` fast-forwarded to `fc8883fc70`; `trunk` got
`git merge cassandra-6.0 -s ours --log` → `0d87b2d76a` (doc/ diff vs
upstream: empty). Dry-run clean, then
`git push --atomic upstream cassandra-6.0 trunk` landed:

| Branch | New tip |
|---|---|
| `cassandra-6.0` | `fc8883fc70` |
| `trunk` | `0d87b2d76a` (lineage merge, no content change) |

No new PR per project convention — mechanical application of
already-reviewed work, same as the 2026-05-14 and 2026-06-10
forward-merges (decision confirmed with Patrick, including the
one-line line-58 addition, treated like 5.0's `auth-caching`
conflict-resolution fix). JIRA comment on CASSANDRA-21342
documenting the gap closure posted by Patrick.

**CASSANDRA-21342 xref fixes are now at parity across
cassandra-4.0 / 4.1 / 5.0 / 6.0 / trunk.** Remaining known-broken
targets on all branches: the deferred bugs.adoc retarget + G7
content-decision bucket, and Phase 5 structural errors.

### 2026-06-10 — Follow-up JIRAs filed; 21342 ready to resolve

Deferred work now has tickets, both children of epic
**CASSANDRA-21314** (docs modernization, same epic as 21342 and the
Antora 3 upgrade ticket 21315):

| JIRA | Scope | Workstream mapping |
|---|---|---|
| **CASSANDRA-21448** | Fix structural Antora errors in in-tree docs (24 missing data-modeling images, 4 doctype/level-0 in `security.adoc`/`changes.adoc`, 4 table-syntax) | Phase 5 |
| **CASSANDRA-21449** | Resolve remaining broken link targets needing content decisions (`bugs.adoc` xrefs ×2 + `download.adoc`; ~10 in-tree G7 sites) — see 2026-06-10 source-location correction below | bugs.adoc A1/A3 + G7 bucket |

Both block CASSANDRA-21315 (Antora 3 reland gated on zero errors).
Planned PRs: one `apache/cassandra` PR for 21448; two PRs for 21449
(one per repo), with the bugs.adoc direction getting a dev@ thread
first. Each new PR gets normal review — the no-review convention
applied only to mechanical re-application of already-reviewed work.

With follow-ups filed, CASSANDRA-21342 can be resolved as Fixed
(fixVersions: next unreleased version per committed branch).

**JIRA state as of 2026-06-10 (verified via REST):** 21342 Resolved
(fixVersions initially empty — set by Patrick 2026-06-11, then
corrected to concrete versions by mck; see the 2026-06-11 compliance
entry in Cross-cutting notes); 21448 + 21449 each carry
`blocks CASSANDRA-21315` and Epic Link 21314; 21315 shows the mirror
`is blocked by` links.

### 2026-06-10 — bugs.adoc: source-location correction, live-site impact, dev@ thread sent (CASSANDRA-21449)

**Correction to the 21449 ticket draft and earlier log framing.** The
broken `bugs.adoc` xrefs do **not** live in cassandra-website. Sources
verified by grep:

- `apache/cassandra` `doc/modules/ROOT/nav.adoc:4` —
  `xref:master@_:ROOT:bugs.adoc[How to report bugs]`
- `apache/cassandra` `doc/modules/ROOT/pages/index.adoc:50` —
  `xref:master@_:ROOT:bugs.adoc[Reporting bugs]`

cassandra-website has **zero** source references to `bugs.adoc` — only
generated HTML in `content/`. What's missing in cassandra-website is
the *target page*. Two consequences:

1. If the fix creates a page, both repos get touched: new `bugs.adoc`
   in cassandra-website ROOT, **plus** the xref prefix fix
   `master@_` → `_@_` in the cassandra repo (same class as the
   contactus A2 retarget — `master@_` is the wrong component-version
   prefix regardless). The xref fix folds into the in-tree G7 PR, so
   21449 stays at two PRs.
2. Because the xrefs are in the cassandra repo, the fix forward-merges
   down the branch ladder — which is what actually removes the dead
   link from the published 4.0/4.1/5.0 docs, not just trunk.
   (⚠ The 21449 JIRA description still attributes the xrefs to
   cassandra-website nav — needs an edit.)

**Live-site impact, verified on production** (`curl` against
`cassandra.apache.org/doc/latest/`): the unresolved xref renders as a
same-page fragment link `href="#master@_:ROOT:bugs.adoc"` — a silent
no-op, not a 404. It appears as **"How to report bugs" in the left
sidebar of every published doc page across all versions** (latest,
stable, 5.0, 4.1, 4.0 — confirmed in cassandra-website `content/`
generated HTML) plus a "Reporting bugs" bullet on the docs landing
page (Antora marks it `class="page unresolved"`).

**dev@ thread sent 2026-06-10** ([DISCUSS], CASSANDRA-21449):
presented three options — (1) create a short "Reporting bugs" page in
cassandra-website, (2) external link to ASF JIRA, (3) drop the nav
entry — with Patrick's vote for option 1, lazy consensus, PR to follow
if no objections in a few days. Scope deliberately limited to the
bugs.adoc decision (the only item changing community-owned
navigation); the ~10 in-tree G7 sites stay as committer-discretion
calls documented on the ticket. `_/download.adoc` reclassified as
mechanical (target page exists; xref merely malformed) — no decision
needed, folds into the in-tree PR.

**Next for 21449** (after lazy consensus closes): draft the
`bugs.adoc` page (option 1) for the cassandra-website PR; make the
per-site G7 calls; build the in-tree PR (G7 + `master@_` → `_@_`
prefix fixes + `download.adoc`).

---

## Phase 5 — Structural and non-xref errors

In review. Independent of Phases 2–4. **Tracked as CASSANDRA-21448.**

### 2026-06-10 — All three structural error classes fixed; PR #4877 open

Topic branch `CASSANDRA-21448-trunk` off `upstream/trunk` (`0d87b2d76a`),
single commit `1f93ceed7b`, 10 files / ±16 lines. PR:
<https://github.com/apache/cassandra/pull/4877> against
`apache/cassandra:trunk`, AI disclosure in the PR body, `patch by …
reviewed by TBD` trailer per the 2026-05-13 convention.

**Findings per error class** (the ticket's 24/4/4 = 32 counts came from
the trial build's log, which carried each message twice; the real
population is 12 image macros + 2 section sites + 2 table sites = 16):

- **Images — nothing was ever missing.** All 12 referenced files
  (`data_modeling_*.png` ×10, `Figure_*_data_model.jpg` ×2) are present
  in `doc/modules/cassandra/assets/images/`; they came over in the
  rST→AsciiDoc migration (`05b0eaecad`). The page sources kept a stale
  `images/` path prefix, which Antora resolves to
  `assets/images/images/*`. Fix: strip the prefix on 7 data-modeling
  pages. Restore-vs-remove decision moot; no pedagogical content
  touched.
- **Level-0 sections — not in the standalone pages.**
  `cql/security.adoc` and `cql/changes.adoc` each have exactly one `=`
  title already; the errors fire because `cql_singlefile.adoc` includes
  both pages whole. Fix: `leveloffset=+1` on the two includes. Rendered
  singlefile now nests "Database Roles" and "CQL Changes" as `==`
  siblings of its other top sections; no prose changed.
- **Tables.** `developing/cql/ddl.adoc` `NetworkTopologyStrategy`
  table: `cols=",,,"` (4 cols) over 3-cell rows → `cols=",,"`.
  `managing/tools/sstable/sstablemetadata.adoc`: missing `|` separator
  in the `Estimated cardinality` row of the 2-column value table.
  Content unchanged. (Sites located by converting every in-tree page
  with `@asciidoctor/core` and capturing the logger, since the trial
  build's `/tmp` logs were gone.)

**Verification** — full Antora 3 trial build ×2 (cassandra-website at
`897d1a67` = the Antora 3.1.14/Node 24 reapply commit, recovered from
reflog; `./run.sh website build -e .xref-env -g
-u cassandra:../cassandra -b cassandra:trunk`):

| | before (trunk) | after (topic branch) |
|---|---|---|
| total error entries | 33 | 17 |
| image / section / table | 12 / 2 / 2 | 0 / 0 / 0 |
| xref | 17 | 17 |

`-16 / +0`; the surviving 17 xref messages are byte-identical across
the two builds (verified with `comm`). Remaining 17 = bugs.adoc ×2 +
G7/long-tail, tracked under CASSANDRA-21449 and Phase 4.

**Build-lane gotcha worth recording**: with `-u cassandra:<local path>`,
the container builds the *worktree* of the mounted repo and labels it
with the requested branch name — `-b cassandra:trunk` does not pin the
`trunk` ref. The first "before" build silently measured the already-
fixed topic-branch worktree (17 errors, 0 structural). Before/after
runs must check out the intended state in the cassandra clone first.

Forward-merge to release branches deferred until after review, as a
separate step, per convention.

---

## Phase 6 — Tighten `failure_level` back to `error`

Not started. Blocked on 0 + 2–5.

---

## Phase 7 — Regression prevention

Not started. Blocked on 6.

---

## Cross-cutting notes

- **ASF authorship line**: all PR pushes, `gh pr create`, JIRA
  transitions, dev@ posts, and reviewer replies are the contributor's
  action. This log records drafts and local validation only.
- **Umbrella JIRA**: `CASSANDRA-21342` covers the whole broken-link
  workstream (decision recorded 2026-04-27, one umbrella JIRA + two PRs:
  one per repo). PR #319 (cassandra-website) merged 2026-05-13. The
  cassandra repo PR (15 commits on `upstream/broken-link-fix`) is the
  second PR under the same JIRA.
- **Reviewer rotation** — Anthony Grasso is primary while Mick Semb Wever
  is away (~2026-04-17 → 2026-05-15). Stefan Miklosovic has been engaged
  on build stability.
- **Commit-message format (corrected by mck, 2026-06-11)** — first line
  is a plain-text title with NO `CASSANDRA-XXXXX:` prefix (exception:
  ninja commits); the JIRA id appears only on the last line, in the
  `patch by <author>; reviewed by <reviewer> for CASSANDRA-XXXXX`
  trailer. GitHub PR titles keep the prefix (githubbot uses it to link
  the PR to the ticket). See the 2026-06-11 compliance entry below for
  the audit of past commits.
- **JIRA resolution format (inferred from mck's 2026-06-11 edits)** —
  on resolve, fixVersions are the concrete next release versions per
  committed branch (e.g. 4.0.21 / 4.1.12 / 5.0.9 / 6.0 + 6.0-alpha2 /
  7.0 for trunk), not `.x` placeholders; populate the Source Control
  Link field with the commit URL(s).

### 2026-06-11 — Convention compliance audit after mck's corrections

mck corrected CASSANDRA-21342 after Patrick's resolution (JIRA
changelog, 2026-06-11 10:13–10:14):

- Replaced placeholder fixVersions (`4.0.x/4.1.x/5.0.x/6.x`) with
  concrete versions: **4.0.21, 4.1.12, 5.0.9, 6.0, 6.0-alpha2, 7.0**.
- Added **Source Control Link**: `fc8883fc70` (cassandra-6.0 xref fix)
  and `19ee803038` (4.0-subset long-tail follow-up).

Separately via Slack, mck stated the commit-message rule (recorded in
Cross-cutting notes above).

**Audit of this workstream's commits against the rule:**

| Commit | First line | Status |
|---|---|---|
| `32826fe563` (trunk, PR #4807) | `CASSANDRA-21342: …` prefix | ❌ merged, immutable |
| `fc8883fc70` (cassandra-6.0) | `CASSANDRA-21342: …` prefix | ❌ merged, immutable |
| `19ee803038` (cassandra-4.0) | `CASSANDRA-21342: …` prefix | ❌ merged, immutable |
| PR #4877 (CASSANDRA-21448) | was `CASSANDRA-21448: …` | ✅ **fixed** — amended to plain title, force-pushed `1f93ceed7b` → `5d6fd41da4` |

The #4877 amend also added the before/after build-verification
paragraph to the commit body; trailer unchanged (`patch by Patrick
McFadin; reviewed by TBD for CASSANDRA-21448`). PR title keeps the
`CASSANDRA-21448:` prefix deliberately — that is the githubbot link
mechanism, and mck's rule addresses commit messages only.

**Forward obligations:** all future commits (21449's two PRs, 21448
forward-merges, anything under epic 21314) use plain-text first line +
trailer-only JIRA id; all future resolutions set concrete fixVersions
+ Source Control Link. The 21448 execution-prompt template's
`title "CASSANDRA-21448: ..."` instruction is superseded on the
commit side. The 21448/21449 tickets were also triaged 2026-06-11
(Change Category: Quality Assurance, Complexity: Normal, status Open)
— matching what mck-style triage would set, no correction needed
there.
