# GitHub Pages Publishing Strategy

Capture date: **2026-03-27**

## Decision

Use **GitHub Actions** (not the `gh-pages` branch) for publishing to GitHub Pages.

### Rationale
- GitHub Actions is the recommended approach for static site generators
- It avoids polluting the git history with build artifacts on a `gh-pages` branch
- It integrates naturally with the PR validation workflow (Phase 3)
- The Antora build output is an artifact that can be inspected before deployment

## Preview Banner

Every page must display this banner text:

> **Preview | Unofficial | For review only**

This is enforced via:
1. An AsciiDoc `[IMPORTANT]` admonition block on each page's index
2. The `draft-banner` attribute in `content/antora.yml` (available as `{draft-banner}` in AsciiDoc)
3. The Antora UI could be customized to inject a site-wide banner, but the default UI with per-page admonitions is sufficient for the initial preview

## .nojekyll

The `build.sh build` command creates a `.nojekyll` file in the build output directory (`build/site/.nojekyll`) after every successful build. This ensures GitHub Pages serves the static site directly without Jekyll processing.

## Publishing Flow

1. Push to `main` triggers the GitHub Actions workflow (Phase 3)
2. The workflow runs `./build.sh build`
3. Build artifacts are uploaded via `actions/upload-pages-artifact`
4. Deployment uses `actions/deploy-pages`
5. The site becomes available at `https://<owner>.github.io/cassandra6-docs-workzone/`

## What This Does NOT Do

- This does not replace the official Apache Cassandra documentation
- This does not publish to `cassandra.apache.org`
- This is a review environment only
