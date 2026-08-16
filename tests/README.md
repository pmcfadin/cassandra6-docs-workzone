# Docs QA suite (workzone)

Reference implementation of the docs-check pipeline. See
`future/docs-check/README.md` for the full plan and the
`apache/cassandra-website` port drafts.

## Run everything locally (~10 s after one-time setup)

```bash
# one-time
npm ci
npx playwright install chromium

# each cycle
npm run build                                  # Antora → build/site (~5 s)
npm run test:smoke                             # 10 Playwright tests (~4 s)

# xref ratchet gate (what CI runs)
npx antora --log-format=json --log-level=warn antora-playbook.yml > antora-build.log
bin/xref-report.sh --baseline tests/xref-baseline.json --fail-on-introduced antora-build.log
```

## Files

- `playwright/smoke.spec.ts` — 10 rendered-HTML smoke tests (Chromium-only,
  `retries: 1`). Playwright starts/stops its own static server via the
  `webServer` block in `playwright.config.ts`; no manual server needed.
- `xref-baseline.json` — the ratchet baseline: pre-existing Antora
  error-level events. CI fails only on errors NOT in this file.

## Updating the baseline

Only shrink it (fixing errors) or consciously grow it (importing content
with known-broken xrefs — say why in the PR):

```bash
npx antora --log-format=json --log-level=warn antora-playbook.yml > antora-build.log
bin/xref-report.sh --emit-baseline \
  --source-build "workzone-local-$(date +%Y%m%d)" antora-build.log > tests/xref-baseline.json
```

## Adding a test

`npx playwright codegen http://127.0.0.1:5151` (with `npm run preview`
running) records interactions. Prefer role/text locators over CSS classes;
at cassandra-website port time, selectors move to `data-testid` per
`docs/website-qa-automation.md`.

Debugging: `npx playwright test --ui` (interactive) or
`npx playwright show-trace test-results/<test>/trace.zip` (post-mortem).
