# Review Gates

Capture date: **2026-03-24**

## Gate 1: Source Pack Approval
- Confirm the exact branch, paths, and generated outputs allowed for the task.
- Reject any task using blogs, stale wiki pages, or uncross-checked community content.

## Gate 2: Inventory Approval
- Confirm that every relevant page area is present in `inventory/docs-map.csv`.
- Confirm generated surfaces are tracked separately from authored pages.

## Gate 3: Diff Approval
- Human reviewer confirms the page disposition for the target slice before drafting starts.
- New pages discovered only on `trunk` must be called out explicitly.

## Gate 4: Draft Approval
- Every normative statement has a citation.
- Every inference is labeled as inference.
- Upgrade, compatibility, security, and operational claims receive technical-owner review.

## Gate 5: Render Approval
- Local Antora build succeeds.
- Nav, xrefs, tabs, admonitions, and version selector render correctly.
- Generated pages exist where expected in rendered output.

## Gate 6: Stage Approval
- Staged site matches expected version aliases.
- `stable` and `latest` do not point to the wrong major version.
- A maintainer signs off before any `asf-staging` to `asf-site` promotion.
- The related JIRA or review record is updated with staging validation results.

## Gate 7: Post-Publish Check
- Production URLs resolve correctly.
- Version selector reflects the intended release state.
- No obvious regressions in older supported version paths.
