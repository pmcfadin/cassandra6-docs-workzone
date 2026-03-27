# Version Wire-Up Validation Checklist: Cassandra 6.0

Prepared: **2026-03-27**

This checklist provides a step-by-step test procedure for validating that `stable`, `latest`, and `trunk` resolve correctly after the Cassandra 6.0 version wire-up. It operationalizes the acceptance checks from `cassandra6-version-wireup.md` and the review gates from `llm/review-gates.md` (Gates 5, 6, and 7).

**Prerequisites before starting this checklist:**
- The `cassandra-6.0` branch exists in `apache/cassandra`.
- The antora.yml patch has been applied (see `runbooks/patches/cassandra-antora-yml-patch.md`).
- The website wire-up patch has been applied (see `runbooks/patches/website-version-wireup-patch.md`).
- Docker is available locally.
- A local clone of `apache/cassandra-website` is available.

**Related documents:**
- `runbooks/cassandra6-version-wireup.md` — wire-up sequence and acceptance checks
- `runbooks/patches/cassandra-antora-yml-patch.md` — Cassandra-side `doc/antora.yml` change
- `runbooks/patches/website-version-wireup-patch.md` — website-side `Dockerfile`, `docker-entrypoint.sh`, and `site.template.yaml` changes
- `runbooks/build-preview-publish.md` — build commands and publish path
- `llm/review-gates.md` — Gates 5 (render), 6 (staging), 7 (post-publish)

---

## Section 1: Pre-Apply Checks

These checks verify that all prerequisites are in place before running any build. Complete all of them before proceeding to Section 2.

**Step 1.1 — Confirm `cassandra-6.0` branch exists**

- **What to check:** The `cassandra-6.0` branch is publicly accessible in `apache/cassandra`.
- **Expected result:** Branch is listed and HEAD commit is visible.
- **How to check:**
  ```bash
  git ls-remote https://github.com/apache/cassandra.git refs/heads/cassandra-6.0
  ```
  A non-empty line with the branch ref is success. An empty response means the branch does not exist — stop and do not proceed.

**Step 1.2 — Confirm `doc/antora.yml` on `cassandra-6.0` is correct**

- **What to check:** `version`, `display_version`, and absence of `prerelease` key.
- **Expected result:** `version: '6.0'`, `display_version: '6.0'`, no `prerelease` line.
- **How to check:**
  ```bash
  git show origin/cassandra-6.0:doc/antora.yml
  ```
  Run from a local clone of `apache/cassandra`. Compare against the target state in `runbooks/patches/cassandra-antora-yml-patch.md`.

**Step 1.3 — Confirm `trunk` `doc/antora.yml` is still marked prerelease**

- **What to check:** `trunk` retains `prerelease: true` and has not been modified by the 6.0 branch cut.
- **Expected result:** `prerelease: true` is present; `version` is not `'6.0'`.
- **How to check:**
  ```bash
  git show origin/trunk:doc/antora.yml
  ```

**Step 1.4 — Confirm next prerelease alias target is resolved**

- **What to check:** The `trunk` alias target in `docker-entrypoint.sh` is set to a confirmed value (not the placeholder `<NEXT_PRERELEASE>`).
- **Expected result:** The trunk `move_intree_document_directories` line references a real version string that matches `trunk`'s `doc/antora.yml` `version` field.
- **How to check:** Read the `version` field from trunk's `doc/antora.yml` (Step 1.3 output) and compare it to the trunk line in `site-content/docker-entrypoint.sh` in the website repo. They must agree.

**Step 1.5 — Confirm `cassandra-6.0` is in `Dockerfile` branch list**

- **What to check:** `ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES` in `site-content/Dockerfile` includes `cassandra-6.0`.
- **Expected result:** `cassandra-6.0` appears immediately after `trunk` in the space-separated list.
- **How to check:**
  ```bash
  grep ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES site-content/Dockerfile
  ```
  Run from the `apache/cassandra-website` root.

**Step 1.6 — Confirm `docker-entrypoint.sh` alias rules are updated**

- **What to check:** The `move_intree_document_directories` calls assign `stable` and `latest` to `6.0`, and `5.0` no longer carries those aliases.
- **Expected result:** A `6.0` line with `stable` and `latest`, and the `5.0` line without them.
- **How to check:**
  ```bash
  grep -A2 "move_intree_document_directories" site-content/docker-entrypoint.sh | grep -E "5\.0|6\.0|stable|latest|trunk"
  ```

**Step 1.7 — Confirm `site.template.yaml` major-version attributes**

- **What to check:** `latest-version`, `current-version`, and `previous-version` in `site-content/site.template.yaml`.
- **Expected result:** `latest-version: 6.0`, `current-version: 6.0`, `previous-version: 5.0`.
- **How to check:**
  ```bash
  grep -E "latest-version|current-version|previous-version" site-content/site.template.yaml
  ```

---

## Section 2: Local Render Validation

Run the full site build locally using the `cassandra-6.0` branch as the Cassandra docs source. This validates Gate 5 (render approval).

**Step 2.1 — Build the website container**

- **What to check:** The Docker container builds without errors.
- **Expected result:** Container build exits with code 0 and the container image is available.
- **How to check:**
  ```bash
  cd /path/to/cassandra-website
  ./run.sh website container
  ```

**Step 2.2 — Run the full site build with `cassandra-6.0`**

- **What to check:** Antora fetches `cassandra-6.0` content, runs `ant gen-asciidoc`, and renders the site without errors.
- **Expected result:** Build exits with code 0. No `ERROR` or `FAILED` lines in output. The message `Antora build complete` (or equivalent) appears.
- **How to check:**
  ```bash
  ./run.sh website build -g -u cassandra:/path/to/cassandra -b cassandra:cassandra-6.0
  ```
  Substitute `/path/to/cassandra` with your local `apache/cassandra` clone path.

**Step 2.3 — Confirm output directory exists and contains 6.0 content**

- **What to check:** The rendered output directory contains a `6.0` subdirectory under the doc component path.
- **Expected result:** `site-content/build/html/doc/cassandra/6.0/` exists and contains HTML files.
- **How to check:**
  ```bash
  ls site-content/build/html/doc/cassandra/6.0/ | head -20
  ```

**Step 2.4 — Confirm `stable` and `latest` directories exist in build output**

- **What to check:** The alias directories `stable` and `latest` are present under `doc/` in the build output.
- **Expected result:** `site-content/build/html/doc/stable/` and `site-content/build/html/doc/latest/` exist and are not empty.
- **How to check:**
  ```bash
  ls site-content/build/html/doc/stable/ | head -5
  ls site-content/build/html/doc/latest/ | head -5
  ```

**Step 2.5 — Confirm `stable` and `latest` resolve to 6.0 content**

- **What to check:** The content in `stable/` and `latest/` is 6.0 content, not 5.0 content.
- **Expected result:** An index or landing page under `stable/` references version 6.0 (check page title or version attribute in the HTML).
- **How to check:**
  ```bash
  grep -r "6\.0" site-content/build/html/doc/stable/ --include="*.html" -l | head -5
  grep -r "5\.0.*stable\|stable.*5\.0" site-content/build/html/doc/stable/ --include="*.html" | head -5
  ```
  The first command should return matches; the second should return none (no references tying stable to 5.0 in a way that implies 5.0 is stable).

**Step 2.6 — Confirm `trunk` directory exists and is marked prerelease**

- **What to check:** The `trunk` build output exists and the version selector or page metadata indicates it is a prerelease.
- **Expected result:** `site-content/build/html/doc/trunk/` exists. HTML in that directory includes a prerelease indicator (e.g., a CSS class or label applied by the Antora UI for prerelease versions).
- **How to check:**
  ```bash
  ls site-content/build/html/doc/trunk/ | head -5
  grep -r "prerelease\|pre-release" site-content/build/html/doc/trunk/ --include="*.html" -l | head -5
  ```

**Step 2.7 — Confirm `5.0` directory still exists**

- **What to check:** The `5.0` docs are still present in the build output (no legacy version was dropped unintentionally).
- **Expected result:** `site-content/build/html/doc/cassandra/5.0/` exists and contains HTML files.
- **How to check:**
  ```bash
  ls site-content/build/html/doc/cassandra/5.0/ | head -5
  ```

**Step 2.8 — Confirm generated pages are present for 6.0**

- **What to check:** Machine-generated pages (e.g., nodetool reference, `cassandra.yaml` reference) exist under the 6.0 output.
- **Expected result:** At least one generated page path is present (e.g., `doc/cassandra/6.0/tools/nodetool/` or equivalent).
- **How to check:**
  ```bash
  ls site-content/build/html/doc/cassandra/6.0/tools/ 2>/dev/null || \
  ls site-content/build/html/doc/cassandra/6.0/ | grep -i "nodetool\|yaml\|native"
  ```
  Adjust the path to match the actual generated page structure from the project.

---

## Section 3: Version Selector Validation

Check the version selector rendered in local build output. This is part of Gate 5.

**Step 3.1 — Confirm 6.0 appears in the version selector**

- **What to check:** The version selector HTML lists `6.0` as a selectable version.
- **Expected result:** A link or list item for `6.0` appears in the navigation component.
- **How to check:**
  Launch a local preview and open in a browser:
  ```bash
  ./run.sh website preview
  ```
  Navigate to `http://localhost:5151/doc/cassandra/6.0/` and inspect the version selector dropdown or list in the page navigation.

**Step 3.2 — Confirm 6.0 is not marked as prerelease in the selector**

- **What to check:** The version selector entry for `6.0` does not have a prerelease label or indicator.
- **Expected result:** No `(prerelease)` label, no prerelease CSS class, no asterisk or other indicator next to `6.0`.
- **How to check:** In the preview at `http://localhost:5151`, visually inspect the version selector on any 6.0 page. Alternatively:
  ```bash
  grep -A5 "6\.0" site-content/build/html/doc/cassandra/6.0/index.html | grep -i "prerelease"
  ```
  Should return no output.

**Step 3.3 — Confirm `trunk` is marked as prerelease in the selector**

- **What to check:** The version selector entry for `trunk` carries a prerelease indicator.
- **Expected result:** `trunk` has a visual prerelease indicator in the version selector.
- **How to check:** In the preview, navigate to any `trunk` page and inspect the version selector. The `trunk` entry should be visually distinct from released versions.

**Step 3.4 — Confirm version ordering is correct**

- **What to check:** The version selector lists versions in descending order: trunk (prerelease), 6.0, 5.0, 4.1, 4.0, 3.11.
- **Expected result:** 6.0 appears immediately after trunk and before 5.0 in the selector.
- **How to check:** Visually confirm in the preview at `http://localhost:5151`. No exact version of this ordering is enforced by Antora spec, but the project convention follows descending version order.

---

## Section 4: Alias Resolution Validation

Verify that the URL alias paths resolve to the correct versioned content. This is a prerequisite for Gate 6 (staging approval).

**Step 4.1 — `/doc/stable/` resolves to 6.0**

- **What to check:** The `stable` alias path serves 6.0 content.
- **Expected result:** Visiting `/doc/stable/` (or the equivalent local path) shows 6.0 pages, not 5.0 pages.
- **How to check (local):**
  In the preview at `http://localhost:5151`, navigate to `http://localhost:5151/doc/stable/` and confirm the version indicator in the page header or footer shows `6.0`.

**Step 4.2 — `/doc/latest/` resolves to 6.0**

- **What to check:** The `latest` alias path serves 6.0 content.
- **Expected result:** Visiting `/doc/latest/` shows 6.0 pages.
- **How to check (local):**
  Navigate to `http://localhost:5151/doc/latest/` and confirm the version shown is `6.0`.

**Step 4.3 — `/doc/trunk/` resolves to prerelease content, not 6.0**

- **What to check:** `trunk` does not masquerade as a released version.
- **Expected result:** `/doc/trunk/` shows prerelease content with the trunk version label, not the `6.0` label.
- **How to check (local):**
  Navigate to `http://localhost:5151/doc/trunk/` and confirm the version shown is `trunk` (or the next prerelease string), not `6.0`.

**Step 4.4 — `/doc/5.0/` still resolves (no regression)**

- **What to check:** The 5.0 docs remain accessible at their direct path.
- **Expected result:** `/doc/5.0/` or `/doc/cassandra/5.0/` returns 5.0 pages without errors.
- **How to check (local):**
  Navigate to `http://localhost:5151/doc/cassandra/5.0/` and confirm pages load.

**Step 4.5 — `/doc/5.0/` does not carry `stable` or `latest` labels**

- **What to check:** After the wire-up, 5.0 is no longer the `stable` or `latest` version.
- **Expected result:** The version selector on 5.0 pages does not mark 5.0 as stable or latest.
- **How to check (local):**
  On any 5.0 page in the preview, inspect the version selector. `5.0` should not carry a `(stable)` or `(latest)` label.

---

## Section 5: Staging Validation

Run these checks on `cassandra.staged.apache.org` after the changes have been merged and the staged deployment has completed. This satisfies Gate 6 (stage approval).

**Step 5.1 — Staged deployment is complete**

- **What to check:** The staged site has been rebuilt with the wire-up changes.
- **Expected result:** The staged site shows content dated after your merge, or a build completion indicator is present.
- **How to check:**
  Open `https://cassandra.staged.apache.org/` and confirm the site loads. Check the version selector or a 6.0-specific page to confirm the deployment is current.

**Step 5.2 — `/doc/stable/` on staging resolves to 6.0**

- **What to check:** The `stable` alias on the staged site points to 6.0.
- **Expected result:** `https://cassandra.staged.apache.org/doc/stable/` shows 6.0 content.
- **How to check:**
  Navigate to `https://cassandra.staged.apache.org/doc/stable/` and confirm the version indicator shows `6.0`.

**Step 5.3 — `/doc/latest/` on staging resolves to 6.0**

- **What to check:** The `latest` alias on the staged site points to 6.0.
- **Expected result:** `https://cassandra.staged.apache.org/doc/latest/` shows 6.0 content.
- **How to check:**
  Navigate to `https://cassandra.staged.apache.org/doc/latest/` and confirm the version indicator shows `6.0`.

**Step 5.4 — `/doc/trunk/` on staging remains prerelease**

- **What to check:** `trunk` on staging is not aliased to `stable` or `latest`.
- **Expected result:** `https://cassandra.staged.apache.org/doc/trunk/` serves prerelease content and is not the same content as `stable`.
- **How to check:**
  Navigate to both URLs and confirm they show different version labels.

**Step 5.5 — Version selector on staging shows correct ordering**

- **What to check:** The version selector on staged pages lists 6.0 before 5.0 and trunk is marked prerelease.
- **Expected result:** Selector order is trunk (prerelease), 6.0, 5.0, 4.1, 4.0, 3.11.
- **How to check:**
  Open any doc page on `cassandra.staged.apache.org` and inspect the version selector.

**Step 5.6 — Generated pages exist under 6.0 on staging**

- **What to check:** Machine-generated doc pages are present in the staged 6.0 section.
- **Expected result:** At least one generated page (nodetool reference, cassandra.yaml reference, or native protocol page) is accessible.
- **How to check:**
  Navigate to a known generated page path under `https://cassandra.staged.apache.org/doc/cassandra/6.0/` (e.g., the nodetool subcommand pages or configuration reference). Confirm the page loads and shows 6.0 content.

**Step 5.7 — No legacy version aliases were dropped**

- **What to check:** Older supported versions (4.1, 4.0, 3.11) remain accessible on staging.
- **Expected result:** Direct version paths for all supported versions return pages.
- **How to check:**
  ```
  https://cassandra.staged.apache.org/doc/cassandra/5.0/
  https://cassandra.staged.apache.org/doc/cassandra/4.1/
  https://cassandra.staged.apache.org/doc/cassandra/4.0/
  https://cassandra.staged.apache.org/doc/cassandra/3.11/
  ```
  All four should return pages, not 404s.

**Step 5.8 — Record staging sign-off**

- **What to check:** A maintainer has reviewed and signed off on the staged result before promotion.
- **Expected result:** Sign-off is recorded in the related JIRA or review record.
- **How to check:**
  Confirm that the JIRA ticket (or PR) for this wire-up has a comment from a maintainer confirming staging validation. Do not proceed to Section 6 without this sign-off.

---

## Section 6: Production Validation

Run these checks on `cassandra.apache.org` after promoting `asf-staging` to `asf-site`. This satisfies Gate 7 (post-publish check). Do not run these checks until Section 5 is fully complete and sign-off is recorded.

**Step 6.1 — Production deployment is live**

- **What to check:** The production site has been updated after the `asf-staging` to `asf-site` merge.
- **Expected result:** The production site reflects the 6.0 wire-up changes.
- **How to check:**
  Navigate to `https://cassandra.apache.org/` and confirm the site loads. Open a 6.0-specific page to confirm deployment currency.

**Step 6.2 — `/doc/stable/` on production resolves to 6.0**

- **What to check:** The `stable` alias on the production site points to 6.0.
- **Expected result:** `https://cassandra.apache.org/doc/stable/` shows 6.0 content.
- **How to check:**
  Navigate to `https://cassandra.apache.org/doc/stable/` and confirm the version indicator shows `6.0`.

**Step 6.3 — `/doc/latest/` on production resolves to 6.0**

- **What to check:** The `latest` alias on the production site points to 6.0.
- **Expected result:** `https://cassandra.apache.org/doc/latest/` shows 6.0 content.
- **How to check:**
  Navigate to `https://cassandra.apache.org/doc/latest/` and confirm the version indicator shows `6.0`.

**Step 6.4 — `/doc/trunk/` on production remains prerelease**

- **What to check:** `trunk` is not serving as `stable` or `latest`.
- **Expected result:** `https://cassandra.apache.org/doc/trunk/` shows prerelease content distinct from `stable`.
- **How to check:**
  Navigate to both `https://cassandra.apache.org/doc/stable/` and `https://cassandra.apache.org/doc/trunk/` and confirm different version labels.

**Step 6.5 — Version selector on production shows correct state**

- **What to check:** The version selector reflects the intended release state across all version paths.
- **Expected result:** 6.0 is the current released version; trunk is prerelease; older versions remain accessible.
- **How to check:**
  Open `https://cassandra.apache.org/doc/cassandra/6.0/` and inspect the version selector.

**Step 6.6 — No regressions in older version paths**

- **What to check:** Direct version paths for all supported versions still resolve on production.
- **Expected result:** All four older paths return pages, not 404s.
- **How to check:**
  ```
  https://cassandra.apache.org/doc/cassandra/5.0/
  https://cassandra.apache.org/doc/cassandra/4.1/
  https://cassandra.apache.org/doc/cassandra/4.0/
  https://cassandra.apache.org/doc/cassandra/3.11/
  ```

**Step 6.7 — Record production sign-off**

- **What to check:** Post-publish validation results are recorded.
- **Expected result:** The JIRA or review record for this wire-up has a production sign-off comment.
- **How to check:**
  Add a comment to the relevant JIRA or PR confirming that all production checks passed, listing the date and the person who performed the checks.

---

## Section 7: Rollback Guidance

If any validation step fails, use the guidance below to decide whether to roll back and at which stage.

### Pre-Apply Failures (Section 1)

Stop immediately. Do not proceed with any build or deployment. Fix the failing prerequisite and re-run Section 1 from the beginning.

- Step 1.1 fails (branch missing): Wait for the `cassandra-6.0` branch to be cut. Do not proceed.
- Step 1.2 fails (wrong antora.yml): Re-apply the patch from `runbooks/patches/cassandra-antora-yml-patch.md` and verify again.
- Step 1.3 fails (trunk modified): Investigate unexpected changes to trunk's `doc/antora.yml` before proceeding.
- Step 1.4 fails (placeholder in entrypoint): Resolve the trunk alias target by inspecting trunk's `doc/antora.yml` and update `docker-entrypoint.sh` before building.
- Steps 1.5–1.7 fail (website files not updated): Apply or re-check the patch from `runbooks/patches/website-version-wireup-patch.md`.

### Local Build Failures (Section 2)

Do not submit a PR or push to staging. Fix the local build before proceeding.

- Antora build fails with content errors: Check that `cassandra-6.0` is reachable and that the branch list in `Dockerfile` is correct.
- `ant gen-asciidoc` fails: Check the JDK version required by `cassandra-6.0` and whether the container selects it correctly. Refer to `runbooks/build-preview-publish.md` for generation command details.
- `stable`/`latest` directories missing: Verify the `docker-entrypoint.sh` changes (Section 1.6) and re-run the build.

### Staging Failures (Section 5)

Do not promote to production. Identify the root cause, fix in a new PR against the website, and wait for a new staged deployment.

- Aliases resolve to wrong version: Re-check `docker-entrypoint.sh` alias rules. The `move_intree_document_directories` call for `6.0` must include `stable` and `latest`; the `5.0` call must not.
- Version selector incorrect: Re-check `site.template.yaml` attributes and `doc/antora.yml` on `cassandra-6.0`.
- Generated pages missing: Re-check that `cassandra-6.0` is listed in `ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES` and that `gen-asciidoc` ran successfully.
- Older versions missing (404): A `move_intree_document_directories` call for an older version may have been accidentally removed. Compare `docker-entrypoint.sh` against the previous committed state.

To revert a bad staging deployment:

1. Revert the wire-up PR in `apache/cassandra-website`.
2. Confirm the revert triggers a new staged build.
3. Validate that staging returns to the pre-wire-up state (5.0 as stable/latest).
4. Investigate the root cause before re-attempting the wire-up.

### Production Failures (Section 6)

A production regression requires immediate response.

1. If `/doc/stable/` or `/doc/latest/` resolves to the wrong version: revert the `asf-staging` to `asf-site` promotion by reverting the merge commit and force-triggering a production rebuild.
2. If older version paths return 404: same revert procedure as above.
3. Document the failure in the JIRA, noting which step failed and what the observed behavior was.
4. Do not re-attempt production promotion until the root cause is identified and a corrected staging validation is complete.

**Rolling back a live alias change disrupts users who have bookmarked `/doc/stable/` or `/doc/latest/`.** Minimize the window of a bad production state by acting immediately upon detecting a failure in Section 6.
