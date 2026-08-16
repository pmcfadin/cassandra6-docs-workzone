# docs-check: automated PR validation for Cassandra docs

Status: **working reference implementation in this repo** + port drafts for
`apache/cassandra-website`. 2026-07-31.

The goal, from `future/build-test-deploy-modernization.md`: when a PR opens,
machines prove the mechanics — builds, renders, no new broken links — so the
human reviewer reads prose, not build logs. Nothing here needs a policy
change; it's plain PRs.

## What runs where

| Piece | Workzone (live now) | cassandra-website (draft) |
|---|---|---|
| Antora build, JSON logs | `.github/workflows/build-preview.yml` `build` job | `docs-check.yml` `build` job |
| Xref ratchet gate | `bin/xref-report.sh --fail-on-introduced` vs `tests/xref-baseline.json` | same script + `baselines/xref-baseline.json` (needs Antora 3 reland) |
| Rendered smoke suite | `tests/playwright/smoke.spec.ts` (10 tests) | same suite + website-only tests (version switcher, Lunr search, code-copy, mobile nav) per `docs/website-qa-automation.md` |
| Internal link check | covered by smoke suite link-audit tests | `links-internal` job (lychee `--offline`) |
| Spell check | — (add if noise appears) | `typos` job |
| Preview for reviewers | site artifact + run summary; Pages deploy on merge | `docs-preview-comment.yml` sticky PR comment; autostage URL in Phase 2 |
| External link rot | — | `links-external.yml` weekly cron, auto-files issue |
| Deploy gating | Pages deploy runs **only after** gate + smoke pass | staging promotion script (Phase 2) |

## Measured timings (local, 2026-07-31, M-series laptop)

- Full six-component Antora build (five workzone components + upstream
  cassandra trunk `doc/`): **5.5 s**
- Xref gate: **<1 s** (72 baselined pre-existing errors, 0 introduced → pass)
- Playwright smoke suite, 10 tests, Chromium: **3.6 s**
- End-to-end locally: **~10 s** after one-time setup
  (`npm ci && npx playwright install chromium`)

CI adds checkout/clone/setup overhead; expect ~2–3 min per PR run, dominated
by the cassandra clone and Chromium install (both cacheable). This settles
the modernization plan's open question #4: changed-component-only PR builds
are a nice-to-have, not a necessity, at current content scale.

## The contributor experience, end to end

1. Contributor edits a page (GitHub web UI or local `npm run build && npm run preview`).
2. PR opens. Within minutes, checks report:
   - **build** — the site renders; the xref gate confirms zero *newly
     introduced* broken xrefs/includes/images (the pre-existing backlog is
     baselined and never blocks anyone).
   - **smoke** — nav, landing pages, TOC, images, 404 page, and the
     link-audit all pass in a real browser.
   - A run-summary/PR comment links the rendered site for eyeball review.
3. Red check → the failure names the exact xref or page; the contributor
   fixes and pushes; checks re-run automatically.
4. Green check → reviewer reads content, merges. On merge, the same gates run
   again and only a green build deploys.

What stays manual, deliberately: content review and the committer merge
(ASF requirement). What Phase 2 automates next: staged preview URLs via
`.asf.yaml` autostage and a scripted `asf-staging` → `asf-site` promotion.

## The ratchet pattern (why PRs aren't blocked by old errors)

`bin/xref-report.sh --emit-baseline` snapshots current error-level events as
`(branch, category, message) → count`. In CI, `--fail-on-introduced` diffs
the fresh build log against that snapshot and fails only on new entries
(exit 2) or a missing baseline (exit 3 — fail-closed). Burning down the
backlog = a PR that fixes errors **and** shrinks the baseline file, which is
reviewable and monotonic. When the baseline hits zero, flip to plain
`--log-failure-level=error` and delete the ratchet.

## Test suite design notes

- Selectors: default Antora UI roles/landmarks here; `data-testid` on
  site-ui Handlebars partials at port time (spec's selector policy).
- Chromium-only, `retries: 1`, hard fail on second attempt — flake control
  per the QA spec.
- The suite already caught a real defect on first run: the playbook's
  missing `site.url` meant Antora emitted no `404.html`/`sitemap.xml`
  (fixed in `antora-playbook.yml` the same day).
- Console errors, failed requests, and broken images are asserted on every
  navigated page — regressions in UI JS fail loudly, not silently.

## Rollout to apache/cassandra-website

1. JIRA under the Documentation component; pre-align per the QA spec
   (tests-only PR, touches zero content).
2. Land `docs-check.yml` + suite + lychee config + typos config, with the
   xref gate **commented out** until the Antora 3 reland (CASSANDRA-21315)
   provides JSON logs.
3. Ask repo admins to mark `build`, `links-internal`, `playwright` required
   on trunk after the first green week.
4. Land `docs-preview-comment.yml` (needs only default-token permissions).
5. Phase 2 (dev@ thread): autostage previews + promotion script — see
   `future/build-test-deploy-modernization.md` §6.

SHA-pin all non-`actions/*` actions before upstream submission (ASF GitHub
Actions policy); the `PIN-SHA` placeholders mark every spot.
