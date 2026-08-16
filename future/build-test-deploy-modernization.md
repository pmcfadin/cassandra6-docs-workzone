# Cassandra Docs Build/Test/Deploy Modernization Plan

Status: research synthesis, 2026-07-31. Produced from six parallel research workstreams:
current pipeline map (cassandra-website + runbooks), in-tree docs and generation
(apache/cassandra), governance/JIRA/release-train rules, workzone prior art, peer-project
survey (7 ASF projects + K8s/Rust/React + Antora ecosystem), and CI/preview tooling.
Every normative claim below carries a source; items marked **needs-INFRA-confirmation**
or **unverified** are exactly that.

Companion prior art: `future/proposals.md` (Proposal 1 "Keep Antora, Remove The Friction"
is the fixed default path per `backlog/execution-readiness.md`), `docs/website-qa-automation.md`,
`backlog/build-stack-upgrade-plan.md`, `backlog/antora-3-upgrade-log.md`.

---

## 1. Executive summary

The current docs pipeline is heavyweight almost entirely by **convention, not requirement**.
The immovable ASF layer is small: source in ASF git, publish via `.asf.yaml`
(`asf-site`/`asf-staging` branches), committer-only merge, privacy/CSP rules, contributor
licensing. Everything a new contributor actually trips over — JIRA-for-everything,
Docker-only builds, an ~80-minute Jenkins cycle with no PR preview, a tribal-knowledge
force-push promotion ritual, hand-edited version wiring — is project convention or
implementation artifact, changeable by dev-list lazy consensus or a plain PR.

Three findings make the case unusually strong:

1. **Cassandra's own governance already authorizes a lighter path.** The Project Governance
   wiki says "Correcting typos, docs, website, and comments etc operate a 'Commit Then
   Review' (CTR) policy," and the official contributor docs already bless a GitHub-only
   flow (no JIRA) for minor docs changes. The heavyweight process exceeds the project's
   own written rules. (cwiki Cassandra Project Governance; `development/documentation.adoc`)
2. **The missing safety net is nearly free.** No CI anywhere renders the docs — broken
   xrefs ship silently (713 error-level events at the Jenkins #2752 baseline). Antora 3
   validates xrefs natively (`--log-failure-level`), and the workzone's `bin/xref-report.sh`
   already does baseline-diff classification. A ratchet gate ("fail only on newly
   introduced errors") is small effort and avoids blocking on the backlog.
3. **ASF-native per-branch previews exist.** `.asf.yaml` `staging.autostage: site/*` serves
   any matching branch at `cassandra-<name>.staged.apache.org` — the INFRA-blessed answer
   to deploy previews, no Netlify required. (infrastructure-asfyaml README;
   asf-pelican-branches.html)

The workzone prototype is the existence proof for the light stack: `npx antora` + a
70-line `build.sh` + one small GitHub Pages workflow runs the entire authored-docs loop
with Node only — no Docker, no Java, no Python.

### Driving requirements (maintainer-stated)

1. **Kill the Docker requirement for contribution.** Docker is only genuinely needed for
   one thing: regenerating the three generated reference surfaces across multiple release
   branches (which needs per-branch `ant jar`). Every *authored* change — blog posts,
   website pages, product-docs prose — builds with Node + `npx antora` alone. The default
   contributor path must be the Node path; the Docker flow becomes a maintainer/publish
   concern.
2. **Machine feedback on every PR, before any human looks.** Today a human is the build
   verifier and the rendering verifier. Target: on PR open, CI proves (a) the site builds,
   (b) no new broken xrefs/links, (c) rendered HTML passes smoke checks (Playwright, per
   the existing `docs/website-qa-automation.md` spec: nav, version switcher, search, TOC,
   404 — <5 min, no SaaS), and (d) a viewable preview exists — so human review is about
   content, not mechanics.

### Benchmark journey: adding a blog post

Blog posts are website-owned content (`apache/cassandra-website` ROOT component) — no
Java, no generated docs, no multi-version build involved. Today the practiced path is
still: JIRA (by convention), Docker container build to preview, PR, committer merge,
~80-min Jenkins cycle, human staging check, manual force-push promotion.
Target path: write the page (GitHub web UI or local `npx`-based preview in seconds),
PR triggers build + xref/link gate + Playwright smoke + preview URL/artifact, committer
merges under the existing CTR policy, publish via scripted/automated promotion. One
human gate instead of two, and that human reviews prose, not plumbing. This journey is
the acceptance test for Phases 1–2.

---

## 2. How it works today (condensed map)

### Content model (two repos)
- **Product docs** (versioned): `apache/cassandra`, per release branch, `doc/modules/cassandra/pages/`.
- **Website content** (landing, blog, dev guides): `apache/cassandra-website`, `site-content/source/`.
- The website build pulls cassandra branches from a **hardcoded list**
  (`site-content/Dockerfile:130`: `trunk cassandra-6.0 cassandra-5.0 cassandra-4.1 cassandra-4.0 cassandra-3.11`)
  plus auto-detected release tags ≥ 5.0.

### The publish chain (a docs change, end to end)
1. Contributor edits; only supported local validation is the Docker flow
   (`./run.sh website container|build|preview`) — multi-GB image, 4 JDKs, ant, python,
   Node 20, Antora **2.3** (the Antora 3.1.14 upgrade was merged 2026-04-17 and
   **reverted** 2026-04-21; reland CASSANDRA-21315 is gated on the xref backlog).
2. PR to `cassandra-website` trunk (or `cassandra` release branch for product docs).
3. **Committer gate #1**: review + rebase-merge. In practice routed through JIRA + review
   even for small docs changes, despite the CTR carve-out.
4. **Jenkins** (`ci-cassandra.apache.org/job/cassandra-website/`) rebuilds everything
   (~80 min observed; per-branch `ant realclean && ant gen-asciidoc` inside the container)
   and **force-pushes rendered output to `asf-staging`** → cassandra.staged.apache.org.
5. Human eyeballs staging (no checklist in-repo, no automated verification).
6. **Committer gate #2**: promotion is a ritual, not a merge:
   `git switch asf-site && git reset --hard origin/asf-staging && git push -f origin asf-site`
   (README.md:358–361). Tribal knowledge; a normal merge would be wrong.
7. ASF serves `asf-site` at cassandra.apache.org (`.asf.yaml` `publish.whoami: asf-site`).

### What's automated / validated today
- `ant check` (GitHub Actions `code-check.yaml` + Jenkins lint stage) **does** run the
  asciidoc generators — a broken generator fails pre-commit CI.
- **Nothing renders the site pre-commit.** No Antora build in any cassandra-repo CI
  (CircleCI explicitly sets `-Dant.gen-doc.skip=true`). Broken xrefs, dangling nav
  entries, bad includes surface only in the full website build. Baseline: 713 errors
  (650 xref) at Jenkins #2752; 138 Antora-3-level errors remained as of 2026-05-14.
- The one website GH workflow (`site-content.yaml`) builds top-level content on committer
  branch pushes to a `<branch>_generated` branch — no PR trigger, no fork coverage, no URL.
- No link check, no lint, no per-PR preview, no promotion automation.

### Known friction (ranked, first-time contributor)
1. Docker + full Java toolchain for any validated build; generated pages
   (`cass_yaml_file.adoc`, nodetool, native-protocol) require `ant jar` first.
2. No per-PR preview anywhere; contributors ship blind or run the Docker flow.
3. Two committer-only manual gates with undocumented rituals.
4. Antora 2.3 (production) vs Antora 3 (runbooks/local clones) split-brain.
5. Stale official contributor pages (`doc/source/modules` wrong path, dead links, 4.0-era
   freeze text) and stale workzone runbooks (see §6 hygiene items).
6. Build-time network dependencies: scrapes downloads.apache.org for release metadata;
   UI bundle via raw GitHub URL; offline builds fail obscurely.
7. Version wire-up hand-edited across three files in two repos
   (Dockerfile branch list, `docker-entrypoint.sh` alias rules, `site.template.yaml`).
8. JIRA accounts are request-only (Slack/ML) — a real barrier for drive-by docs fixes.

### Current state of the 6.0 wire-up (verified against clones, 2026-07-31)
- `upstream/cassandra-6.0` **exists** (base.version 6.0-alpha2); trunk is 7.0.
- `doc/antora.yml` is **auto-generated** since 2026-04-03 (`gen-antora-yml.py`, from
  build.xml `base.version`; prerelease flag flips automatically on release tags).
- Website Dockerfile branch list **already includes cassandra-6.0**; outstanding:
  alias flip (`docker-entrypoint.sh:260` still `5.0 → stable/latest`) and
  `site.template.yaml` version metadata (still `current: 4.1 / latest: 5.0 / previous: 4.0`,
  which is internally inconsistent today).

---

## 3. Hard requirement vs. convention

| Element | Status | Changeable how |
|---|---|---|
| Source in ASF git, ALv2; site on ASF infra or approved alt (GitHub Pages named) | HARD (Infra policy) | Infra consultation only |
| Publish/staging via `.asf.yaml` branches | HARD mechanism; profiles/patterns project-editable | Project edits own `.asf.yaml` |
| No third-party trackers; DPA for embeds (CSP policy, eff. 2025-03-01) | HARD | No |
| Committer-only merge | HARD | PMC controls who is a committer |
| Netlify/Vercel/Cloudflare previews for official site | Not pre-approved | INFRA ticket (Superset got Netlify, Jan 2026 — precedent exists) |
| JIRA for docs changes | CONVENTION — official docs already say GitHub-only for minor | Socialization + doc fix |
| 2×+1 pre-commit review for docs | Exceeds written policy — governance wiki says docs/website are **CTR** | Socialization; PMC vote only if formalizing further |
| Jenkins as site builder | CONVENTION — GH Actions policy explicitly allows website/docs automation | Project choice |
| Manual staging→production ritual | CONVENTION | Script/automate; lazy consensus |
| Hardcoded branch list / alias rules / manual wire-up | Implementation artifact | Plain PR |
| Workzone 7 gates / 4 reviewer roles / source-pack policy | Self-imposed | Unilateral |

Peer precedent for loosening: Arrow/Lucene/Parquet/Beam migrated JIRA→GitHub Issues by
dev-list vote; Arrow exempts ≤2-file docs PRs from issues entirely (`MINOR:` prefix);
Airflow and Pulsar are GitHub-native with no issue requirement; Flink is the only surveyed
peer still requiring JIRA for docs (except typos).

---

## 4. Peer evidence worth stealing (ranked for transferability)

1. **Core-Antora xref gate** (`--log-failure-level`, `--log-format=json` — must be passed
   explicitly; `CI=true` flips the default to pretty). Couchbase, the largest Antora user,
   logs validation but never fails on it — warnings rot. Cassandra can leapfrog with a
   ratchet on `bin/xref-report.sh --baseline`.
2. **`.asf.yaml` autostage** (`staging: {profile: ~, autostage: site/*}`) →
   `cassandra-<name>.staged.apache.org` per branch. INFRA-blessed; used by OpenDAL for RC
   staging. Caveat: branch-based — fork PRs need a bot/`workflow_run` push path
   (needs-INFRA-confirmation for the bot pattern).
3. **Multiple simultaneous staging profiles** — e.g. a long-lived `cassandra-6docs.staged.apache.org`
   preview of the 6.0 docs alongside production staging.
4. **Two-playbook pattern (Debezium)** — production playbook fetches from GitHub;
   author playbook builds against a local clone for instant preview. The workzone
   playbook already is the author variant.
5. **Per-repo `build.sh`/`preview.sh` (Fedora)** — single-component preview from inside
   the content repo; maps to Proposal 1's `./doc/tools/preview` in apache/cassandra.
6. **Flink's `docs-check.yml`** — build + link check on every PR touching `docs/**`;
   exactly the missing gate, proven in an ASF repo with JIRA-era governance.
7. **Antora Atlas / Spring partial-build extension** (alpha) — build only the changed
   component per PR, resolve cross-refs from a published `site-manifest.json`. Spike
   before committing; matters for the ASF Actions budget (250k min/week project cap).
8. **Kubernetes' reviewer contract** — "preview checked" as an explicit review item, with
   CI posting the staged URL as a PR comment. Social mechanism, zero infra.

Anti-patterns to avoid: validation-as-log-noise (Couchbase); vendor-tied previews decaying
silently (Couchbase's Netlify era); full multi-repo rebuild per PR (budget burn);
unparseable CI logs.

---

## 5. Options

### Option A — Safety net + fast local loop (no policy change, no consensus needed)
Plain PRs to the two repos. Effort: mostly S, one M.

| Item | Effort | Notes |
|---|---|---|
| `docs-check` GH workflow on cassandra-website PRs: `npm ci` → generate `antora.yml` for the cassandra source → `npx antora --fetch --log-format=json --log-failure-level=error` → `xref-report.sh --baseline` ratchet → upload site artifact | S | `xref-report.sh` needs a `--fail-on-introduced` mode (currently always exits 0); commit the baseline |
| Same-shape scoped check on apache/cassandra PRs touching `doc/**` (single-version build via `site-local.yml` or a lite playbook) | M | Closes the gap where most xref errors originate |
| htmltest/linkinator on build output, `CheckExternal: false` (deterministic, offline) | S | |
| lychee external-link check, weekly cron, cache + auto-file issue, non-blocking | S | Superset's exact pattern; SHA-pin per ASF policy |
| `typos` spell check | S | Blocking-ready almost immediately |
| PR preview as artifact + sticky comment (`workflow_run`, works for forks, no secrets) | S–M | Download-a-zip; parity with Airflow |
| Playwright rendered-HTML smoke suite on the PR build output (nav, version switcher, search, TOC, 404) | M | Already specced in `docs/website-qa-automation.md`; ASF-compatible (no SaaS, no secrets); the workzone site-audit Playwright scripts are the seed |
| Enable GitHub Copilot PR review on cassandra-website as an advisory reviewer | S | GitHub-native so no external-service concern expected, but ASF org-level availability **needs confirmation**; advisory only — never a merge gate |
| One-command local preview: `doc/tools/preview` + `doc/tools/check` in apache/cassandra, `npx antora` on a lite playbook, prose-only path needs no Java (skip generated pages or point at prebuilt) | M | Upstreams the workzone `build.sh` proof; Proposal 1's MVP item |
| Fix the stale contributor pages (`documentation.adoc` paths/links, freeze text, README promotion steps → script) | S | High leverage per newbie review |

### Option B — Modern pipeline (dev-list lazy consensus / socialization)
| Item | Effort | Notes |
|---|---|---|
| Socialize the existing CTR carve-out + adopt Arrow-style `MINOR:` no-JIRA docs PRs; update patches.adoc/documentation.adoc to say so plainly | S (writing) + ML thread | Policy already exists; this is publicity, not change |
| `.asf.yaml` autostage (`site/*`) + workflow that builds committer-pushed `site/<topic>` branches → `cassandra-<topic>.staged.apache.org` previews | M | Committer branches first; fork-PR bot path is a separate L item pending INFRA |
| Scripted promotion: `promote-site.sh` (or a manually-triggered workflow) replacing the reset-hard ritual; add the 6-point staging checklist in-repo | S | Automation of an existing committer action — policy-compatible |
| `doc/versions.yaml` manifest generating Dockerfile branch list, entrypoint aliases, site metadata (design doc `future/version-manifest-design.md` — currently unwritten) | M | Kills the three-file hand-edit; makes 6.0-style wire-ups a one-line change |
| Move PR validation to GH Actions while Jenkins keeps the publish build (or migrate publish too, later) | M | Within GH Actions policy ("automated services may work on website content, documentation") |
| Generated-docs drift check: `ant gen-asciidoc` + `git diff --exit-code -- doc/` | M | Requires generator-determinism verification + JDK matrix; decide committed-vs-generated posture first |
| Vale prose lint, advisory-only (`filter_mode: added`, `fail_on_error: false`), Google or MS pack + Cassandra vocab | M | Never block on legacy prose |

### Option C — Structural (PMC / INFRA decisions)
| Item | Effort | Notes |
|---|---|---|
| Antora 3 reland with `failure_level: error` as a permanent gate | Gated | Prereq: xref backlog → 0 (phased_fixes plan; 138 remaining as of 2026-05-14) |
| Audience-first IA restructure upstream (Operators/Developers/Contributors/Reference) | L | Needs dev@ consensus track; content PRs map 1:1 into existing layout meanwhile (upstream-migration-plan) |
| Long-lived 6.0 staging profile (`cassandra-6docs.staged.apache.org`) during the 6.0 docs push | S config, M coordination | |
| Ask INFRA about Netlify-style previews (Superset precedent) and/or bot-pushed per-PR autostage branches | Ticket | May be moot if autostage + artifacts suffice |
| Platform migration (Docusaurus etc.) | Deferred | Explicitly out per fixed decision in `backlog/execution-readiness.md` |

---

## 6. Recommended path

**Phase 0 — Workzone hygiene + missing design docs (now, unilateral)**
1. Refresh stale runbooks: `cassandra6-version-wireup.md` (antora.yml is now generated;
   branch list already wired; remaining work = alias flip + site metadata),
   branch-transition trigger (cassandra-6.0 exists → default comparison target moves).
2. Write the two unwritten keystone designs: `future/version-manifest-design.md` and the
   `doc/tools/preview` spec (`future/prototype-antora-lite.md`), reusing the workzone
   `build.sh` as the reference implementation.
3. Add `--fail-on-introduced` to `bin/xref-report.sh`; commit a refreshed baseline.
4. Continue the xref backlog burn-down (CASSANDRA-21342/-21448/-21449) — it gates Antora 3.

**Upstream alignment (Slack, mck, 2026-08-16).** mck independently confirmed the
Phase 1 direction and assigned the first concrete PR: a GitHub Actions workflow on
`apache/cassandra` that triggers on docs paths, runs `.build/docker/build-docs.sh`
(the reliable in-tree build; `ant gen-doc` is "already docker free… it just likely
won't work for most people"), tars `build/html` to `build/cassandra-html-docs.tar`,
and uploads it as a downloadable artifact — plus optionally GitHub Pages on the
HTML. Draft: `future/docs-check/cassandra-docs-artifact.yml`. mck also endorsed
Playwright tests against the built HTML, noted Jenkins pre-ci now runs `ant
gen-doc` in its artifacts stage (packaging profile), flagged that the artifacts
stage doesn't yet archive the tarball, and set scope expectations: "we are not
dreaming big… moving fast == quick feedback. we can get there without 'big'."
Sequencing consequence: the cassandra-repo artifact workflow now precedes the
cassandra-website docs-check port as Phase 1's first upstream PR.

**Phase 1 — Safety net upstream (plain PRs, no consensus)**
Option A in order: website `docs-check` workflow → cassandra `doc/**` scoped check →
htmltest + typos → lychee cron → artifact previews → stale contributor-page fixes →
`doc/tools/preview`. Each is an independent, individually-mergeable PR with JIRA per
current convention.

**Phase 2 — Process + preview (one dev@ thread, lazy consensus)**
A single well-prepared thread proposing: (a) socialize CTR/`MINOR:` for docs with doc
updates, (b) autostage previews for committer branches, (c) scripted promotion,
(d) version manifest, (e) PR validation on GH Actions. Bundle as "docs contributor
experience" with the Phase 1 CI results as evidence. Convert `future/proposals.md` +
this doc into `future/recommendation-for-pmc.md` first.

**Phase 3 — Strict gates + structure (after backlog zero / with PMC)**
Antora 3 reland with error-level gate → Vale advisory → generated-drift check →
6.0 staging profile → audience IA consensus track → fork-PR preview path per INFRA answer.

**Success criteria for "easy for a new user":** a first-time contributor can
(1) fix a typo or add a blog post via GitHub web UI with no JIRA account and no Docker,
(2) preview locally with Node alone (`npx antora`, under 2 minutes, no Java/Python/Docker),
(3) get CI proof their change renders — build + xref gate + Playwright smoke +
artifact/staged preview — without a human in the loop, (4) see it live after one
committer action, not two; and a maintainer can wire a new major version by editing one
manifest file.

---

## 7. Open questions (owners: INFRA ticket / dev@ / local verification)

1. INFRA: bot-pushed `site/pr-N` autostage branches for fork PRs — acceptable pattern and
   stale-branch cleanup story? Rate/size limits on staged.apache.org syncs?
2. INFRA (optional): Netlify-style previews for cassandra-website, citing Superset.
3. dev@: does the Jenkins website job also trigger on cassandra-repo doc commits, or only
   website-trunk pushes? (Determines real out-of-band docs latency.) Who currently owns
   the asf-staging→asf-site promotion duty?
4. Local: measure the lite-playbook build time (blocked this session; needs generated
   `antora.yml` for the cassandra source first) — determines whether changed-component-only
   PR builds are nice-to-have or necessity.
5. Local: is `ant gen-asciidoc` output byte-deterministic across runs/JDKs? Gates the
   drift check.
6. Verify whether `cassandra-6.0` + trunk both carrying `prerelease: true` render cleanly
   through the Antora 2.3 website pipeline (two simultaneous prerelease components).
7. ASF AI policy: generative-tooling page is 2023-era guidance and self-describes as
   evolving — re-check before formalizing disclosure requirements in contributor docs.
