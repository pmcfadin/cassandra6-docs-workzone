# Apache Cassandra Website QA Automation Spec

Capture date: **2026-04-21**

## Purpose

Define an automated quality-assurance layer for `apache/cassandra-website` that catches rendered-HTML regressions before they reach `asf-staging` or `asf-site`. This spec covers link validation, browser-level smoke tests with Playwright, and an optional accessibility/performance budget, together with the local developer workflow and GitHub Actions integration that make the suite sustainable for an Apache Software Foundation (ASF) project.

This spec is scoped to the **cassandra-website repository only**. It does not govern testing of the Cassandra source tree, nor the generated AsciiDoc produced from `apache/cassandra`.

## Working Position

The cassandra-website repo today has exactly one automated check: a single GitHub Actions workflow that verifies the Antora build does not crash. Nothing exercises the rendered HTML, the UI bundle JavaScript, or the cross-version navigation.

Cassandra 6 will add a large new `/6.0/` docs tree, a new row in the version switcher, and hundreds of new xrefs. That change volume is the forcing function: silent regressions that are inconvenient today will become genuinely expensive to fix post-publish. This spec proposes a layered automation stack that is:

- self-hosted, reproducible, and vendor-neutral (ASF-compatible)
- small enough that one or two maintainers can own it
- layered from cheapest to most expensive so signal comes back fast

## Goals

The automation exists to:

- fail PRs that introduce broken internal links, including cross-version xrefs
- fail PRs that regress core rendered-HTML behaviour (primary nav, version switcher, search, TOC, code-copy, mobile nav, 404 page)
- produce a durable accessibility and performance baseline for the homepage
- run end-to-end on a maintainer laptop in under five minutes
- run in CI on `ubuntu-latest` in under five minutes on top of the existing build
- require no third-party SaaS, no paid service, and no new secrets

## Non-Goals

This spec does **not** cover:

- visual (pixel) regression testing in phase 1 — deferred pending reviewer appetite
- load testing, stress testing, or CDN behaviour
- tests against the live production site (`cassandra.apache.org`) or staging (`cassandra.staged.apache.org`); tests run against locally built HTML only
- per-commit validation of generated AsciiDoc from the Cassandra source repo
- replacement of ASF Infra Jenkins jobs (`ci-cassandra.apache.org`) that publish from `asf-site`
- reviewer or committer sign-off policies; those remain governed by the ASF PR workflow

## Source Of Truth

The automation targets HTML output in `site-content/build/html/` produced by:

```bash
./run.sh website-ui bundle
./run.sh website build
```

That build step is already performed by `.github/workflows/site-content.yaml`. This spec adds verification of the output, not a new build pipeline.

Authoritative references for rendered behaviour remain:

- `site-ui/src/` — Handlebars partials, CSS, JS bundled into `site-ui/build/ui-bundle.zip`
- `site-content/source/` — Antora content pages (top-level website .adoc files)
- Antora content sources for versioned docs (configured per branch of `apache/cassandra`)

## Repository Layout

New artifacts land under a single top-level `tests/` directory, peer to `site-content/` and `site-ui/`:

```
cassandra-website/
  tests/
    playwright/
      smoke.spec.ts          # 8–12 smoke tests (phase 1)
      fixtures/
        static-server.ts     # serves site-content/build/html on 127.0.0.1
    lychee/
      lychee.toml            # link checker config
    lighthouse/
      lighthouserc.json      # Lighthouse CI budget (phase 3, optional)
    README.md                # contributor instructions
  .github/workflows/
    site-content.yaml        # existing, unchanged
    website-qa.yaml          # new, this spec
  package.json               # new, minimal devDependencies for Playwright
  playwright.config.ts       # new, Chromium-only, retries: 1
```

No changes to `run.sh`, `site-content/`, `site-ui/`, or `.asf.yaml`.

## Architecture

### Test layers, cheapest first

| Layer | Tool | What it catches | Runtime |
|---|---|---|---|
| 1. Link integrity | Lychee | Broken internal links and xrefs in built HTML | ~5 s |
| 2. Rendered smoke | Playwright (Chromium) | UI bundle JS regressions; nav, version switcher, search, TOC, copy, mobile nav, 404 | ~90–150 s |
| 3. A11y/perf floor (optional, phase 3) | Lighthouse CI | Accessibility score, Core Web Vitals floor on homepage | ~20 s |

Each layer is independent and runs in its own GHA job so a failure at layer N does not block signal from layer N+1.

### Rationale for Playwright (vs. Cypress, Puppeteer, TestCafe)

- first-party Microsoft project, active, permissive license (Apache-2.0)
- headless Chromium install cached by `microsoft/playwright-github-action`
- built-in waiting primitives that reduce flake vs. Puppeteer
- `codegen` workflow lowers the barrier for non-full-time contributors
- `toHaveScreenshot` available for optional future visual diffing, self-hosted

### Rationale for Lychee (vs. htmlproofer, linkinator)

- single static binary, no Ruby/Node dep
- faster than htmlproofer on a large Antora site
- first-class config file and CI matrix support

### Explicit exclusions

- **Percy, Chromatic**: third-party SaaS, incompatible with ASF reproducibility expectations; excluded.
- **htmlproofer**: acceptable but adds a Ruby toolchain the repo does not otherwise need.
- **Visual diffing in phase 1**: skipped; font-rendering differences on ubuntu runners produce flake that erodes trust.

## Test Inventory (Phase 1)

Exact tests to implement in `tests/playwright/smoke.spec.ts`. Each is a hard PR-blocker.

| # | Test | Assertion |
|---|---|---|
| 1 | Homepage loads | HTTP 200; `<title>` contains "Apache Cassandra"; primary nav renders N expected top-level items |
| 2 | Docs landing via nav | Click "Documentation" in primary nav; URL resolves to a valid docs landing page |
| 3 | Version switcher enumerates versions | Switcher exposes each expected version (`trunk`, `6.0`, `5.0`, `4.1`, `4.0`, `3.11`); selecting one updates URL and loads the corresponding version home |
| 4 | TOC renders and anchors work | On a known docs page, TOC sidebar contains expected section; clicking a TOC entry scrolls to the matching `<h2>/<h3>` anchor |
| 5 | Code block copy button | Copy button is present on any `<pre>` code block; clicking it copies rendered text (verified via `navigator.clipboard.readText()` in page context) |
| 6 | Search input accepts keystrokes | Search field is focusable; typing populates the input; Lunr (client-side) returns at least one hit for a known term |
| 7 | Mobile hamburger | At `viewport: 375x812`, primary nav is collapsed; tapping hamburger expands it; top-level nav items are visible |
| 8 | Internal link audit | Lychee reports 0 internal-link 404s across `site-content/build/html/` |
| 9 | 404 page | Navigating to `/this-page-does-not-exist/` returns the site's 404 template, not a server error page |
| 10 | Blog index | `/blog.html` (or `/blog/`) lists posts; the newest post link resolves to a 200 page |

**Selector policy:** all UI elements exercised by the suite must be addressable via `data-testid` on the Handlebars partial. Adding `data-testid` to the subset of `site-ui/src/partials/` required is a one-time cost done alongside introducing the suite. CSS-class selectors are not used because they churn with theme tweaks.

## CI Integration

### New workflow: `.github/workflows/website-qa.yaml`

Triggered on:

```yaml
on:
  pull_request:
    paths:
      - 'site-*/**'
      - 'tests/**'
      - 'package.json'
      - 'playwright.config.ts'
      - '.github/workflows/website-qa.yaml'
  push:
    branches-ignore:
      - 'trunk'
      - 'asf-staging'
      - 'asf-site'
    paths:
      - 'site-*/**'
      - 'tests/**'
```

Jobs:

1. `build` — invokes the same `./run.sh website-ui bundle` + `./run.sh website build` as `site-content.yaml`. Uploads `site-content/build/html` as an artifact.
2. `lychee` — downloads the artifact; runs `lycheeverse/lychee-action@v1` with `tests/lychee/lychee.toml`. Fails on any internal-link 404.
3. `playwright` — downloads the artifact; installs Chromium via `microsoft/playwright-github-action`; serves HTML via a lightweight static server on `127.0.0.1:5151`; runs `npx playwright test`. Retries once, fails on second attempt.
4. `lighthouse` (phase 3, optional) — runs Lighthouse CI against the homepage with a budget file. Initially reports only; enforcing in a later phase.

No new secrets. All actions sourced from verified publishers (GitHub, Microsoft, lycheeverse). The workflow mirrors the runner and permissions of `site-content.yaml`.

### Required checks

On `trunk`, branch protection should mark `build`, `lychee`, and `playwright` as required. This is a repo admin action, not a code change, and is deferred until after the first green run.

### Workflow interaction with existing `site-content.yaml`

`site-content.yaml` will continue to run unchanged, producing a `*_generated` branch with committed HTML. The new `website-qa.yaml` runs in parallel; its failure does not interfere with generated-content publication but **does** fail the PR check.

## Local Developer Workflow

From a clean checkout:

```bash
# one-time
npm install
npx playwright install chromium

# each dev cycle
./run.sh website-ui bundle
./run.sh website build
npx serve site-content/build/html -l 5151 &
npx playwright test
npx lychee --config tests/lychee/lychee.toml site-content/build/html
```

Interactive authoring of new tests:

```bash
npx playwright codegen http://localhost:5151
```

Debugging a failing test:

```bash
npx playwright test --ui          # UI mode
npx playwright test --debug       # step-through
npx playwright show-trace <path>  # post-mortem trace
```

Contributor documentation lives in `tests/README.md` and covers: how to run the full suite, how to add a test, the `data-testid` selector policy, how to regenerate selectors after a UI change, and how to read a failed CI run's trace artifact.

## Rollout

### Phase 1 — Link check + smoke suite (initial PR)

- `tests/playwright/smoke.spec.ts` with the 10 tests above
- `tests/lychee/lychee.toml`
- `playwright.config.ts` (Chromium only, `retries: 1`, `workers: 2`)
- `package.json` with `@playwright/test` dev dependency
- `.github/workflows/website-qa.yaml` with `build`, `lychee`, `playwright` jobs
- `data-testid` attributes added to the minimum set of `site-ui/src/partials/*.hbs`
- `tests/README.md`

Acceptance: suite is green on `trunk`, reproduces on a contributor fork, runs in under five minutes in CI.

### Phase 2 — Branch protection + observability

- add `build`, `lychee`, `playwright` as required status checks on `trunk`
- publish trace artifacts on failure (Playwright default output)
- dashboard or commits-list ping on `trunk` failures (not on every PR)

### Phase 3 — Optional accessibility and performance floor

- Lighthouse CI on homepage only, with a deliberately loose budget
- advisory only for at least two release cycles before any value is enforced

### Deferred

- visual regression via `toHaveScreenshot` (reviewer-driven)
- versioned-docs deep tests beyond the smoke set
- running against `cassandra.staged.apache.org` from CI (requires ASF Infra conversation)

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Flaky tests erode reviewer trust | Chromium only, `retries: 1`, fail hard on second attempt; no visual diff in phase 1 |
| Large introductory PR scares reviewers | File JIRA first, pre-align with Anthony Grasso, land tests in a PR that touches zero content |
| `data-testid` additions seen as UI churn | Scoped to the minimum set; documented policy in `tests/README.md` |
| Antora version bump breaks selectors | `data-testid` on structural partials insulates tests from class-name churn |
| ASF Infra changes GHA policy | Stack is portable to Jenkins; Playwright and Lychee are CLI-only |
| Full versioned docs build too slow for CI | Phase 1 tests run against top-level build only, matching existing `site-content.yaml` |
| Selector maintenance drifts | `tests/README.md` documents the add/update workflow; CI failure links to the trace to reproduce locally |

## Open Questions

1. JIRA component and reviewer assignment — Documentation component, Anthony Grasso reviewing in Mick Semb Wever's absence (confirmed through 2026-05-15).
2. Is Lychee's GHA action the accepted path, or does ASF Infra require the binary to be pinned/mirrored? Confirm with Infra before the first merge.
3. Should the `playwright` job also post a summary comment on the PR, or rely on the check mark only? Default: check mark only until the team asks for more.
4. Does `npx serve` meet ASF Infra's expectation for declared dependencies, or should we inline a 20-line static server in `tests/playwright/fixtures/`? Lean toward the inline server to avoid a runtime dep.
5. Who owns the suite long-term? Proposed: docs maintainers collectively; PRs touching `tests/` require a docs-team reviewer.

## Verification

End-to-end verification before the first merge:

1. **Local green run** — full command sequence in "Local Developer Workflow" completes in under five minutes, all tests green.
2. **Local negative run** — break a nav xref in `site-content/source/modules/ROOT/nav.adoc`, rebuild, rerun. Lychee fails; Playwright nav smoke fails.
3. **Fork CI run** — push `tests/` + `website-qa.yaml` to a personal fork; open a no-op PR; CI reports three green jobs in under five minutes.
4. **Secrets audit** — `website-qa.yaml` requests no secrets and uses only verified-publisher actions.
5. **Reviewer walkthrough** — live demo of local + CI with Anthony Grasso before opening the PR against `apache/cassandra-website`.

## References

| Path | Role |
|---|---|
| `cassandra-website/run.sh:382` | Existing preview port (5151) — reused by tests |
| `cassandra-website/.github/workflows/site-content.yaml` | Template for the new `website-qa.yaml` workflow |
| `cassandra-website/.asf.yaml:38-44` | ASF publish-branch semantics; must not be touched |
| `cassandra-website/site-ui/gulpfile.js:34-49` | Existing ESLint/Stylelint tasks; candidate for wiring into the workflow in a later phase |
| `cassandra-website/site-ui/src/partials/` | Where `data-testid` additions land |
| `cassandra-website/site-content/build/html/` | Output directory; test target |
| `cassandra-website/README.md` | Staging and publish flow; tests must not assume live preview in CI |

## Bottom Line

Feasibility is high and the community benefit is durable. Phase 1 alone — ten smoke tests and a link checker — closes the two largest uncovered risk classes in the website today: dead internal links and UI-bundle JavaScript regressions. Phase 1 requires no SaaS, no new secrets, and approximately one maintainer-week to introduce. Adoption risk, not technical risk, is the binding constraint; the spec is shaped to keep the initial surface small and reviewer-friendly.
