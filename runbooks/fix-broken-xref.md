# Fix a broken xref: local iterate-and-verify loop

Companion to [`docs/phased_fixes.md`](../docs/phased_fixes.md).
Capture date: **2026-04-22**.

## When to use this

You have a broken target reported in `research/antora3-xref-baseline.json` or surfaced by
`xref-report.sh` (the workzone tool at `bin/xref-report.sh`)
and want to fix one content file and prove the error is gone before widening the work.

This runbook covers a **single content fix** in either `apache/cassandra-website`
or `apache/cassandra`. Multi-branch forward-merge mechanics live in
[`governance-review-and-staging.md`](governance-review-and-staging.md) and the
`contributing-to-apache-cassandra` skill.

## Prerequisites

- Local clone of `apache/cassandra-website` at the workzone path
  `cassandra-website/` with a working tree on the target branch
  (e.g. `broken-link-fix` off trunk).
- For fixes in Cassandra docs: a local clone of `apache/cassandra` at
  `cassandra/` on the relevant release branch.
- Docker or Podman running.
- Website container image built once:
  ```bash
  cd cassandra-website
  ./run.sh website container
  ```
- `xref-report.sh` on `$PATH` or invoked from the workzone root via
  `bin/xref-report.sh`.

## Step 1 — Capture a pre-fix log

The goal is to have a baseline snapshot to diff against after the edit. If you are
working against the shared baseline, skip this step and use
`research/antora3-xref-baseline.json`.

Antora 3 emits structured logs when `runtime.log.format: json` is set in the
playbook, or when the `ANTORA_LOG_FORMAT=json` env var is set. For the local
loop, the simplest path is a transient env file:

```bash
cd cassandra-website
cat > .xref-env <<'EOF'
ANTORA_LOG_FORMAT=json
EOF
```

Do not commit `.xref-env`. Add it to your local `.git/info/exclude` if you want
it permanently ignored.

Run a scoped build (single Cassandra branch, no tag auto-generation; website from
the local checkout) and tee the stdout to a log file:

```bash
./run.sh website build \
  -e .xref-env \
  -u cassandra:$PWD/../cassandra \
  -b cassandra:trunk \
  2>&1 | tee /tmp/xref-before.log
```

Notes:

- `-u cassandra:$PWD/../cassandra` mounts the sibling Cassandra checkout. If you
  only need to verify `asf-staging` (cassandra-website own content) and do not
  touch cross-refs into Cassandra, you can omit `-u`/`-b cassandra:*` —
  the container will auto-fetch the configured Cassandra tags, which is slower.
- `-b cassandra:trunk` auto-disables `ANTORA_CONTENT_SOURCES_CASSANDRA_TAGS`,
  so only trunk is built (see `run.sh` lines 463–469). Swap for the branch you
  are targeting.
- `-g` (generate Cassandra docs) is required only if your broken target is a
  generated page (e.g. `nodetool/*`, configuration reference).

Confirm the pre-fix state:

```bash
bin/xref-report.sh < /tmp/xref-before.log
```

You should see the broken `msg` you plan to fix in the "Top 20" section. If you
do not, the build did not include the branch that carries the broken xref —
add the relevant `-b` or `-u` args and rerun.

## Step 2 — Edit one file

Pick one broken target. For the four common patterns (stale `.html` extension,
missing component qualifier, moved page, `master@` component) see
`docs/phased_fixes.md` appendix.

- Edit the content file in the correct repo (website: under
  `cassandra-website/site-content/source/modules/**/pages/`, cassandra: under
  `cassandra/doc/modules/cassandra/pages/`).
- Do not delete the `xref:` macro. If the target is genuinely gone, rewrite the
  sentence so the navigation intent is preserved or removed explicitly.

## Step 3 — Rebuild and verify the message disappeared

Rerun the same build command:

```bash
./run.sh website build \
  -e .xref-env \
  -u cassandra:$PWD/../cassandra \
  -b cassandra:trunk \
  2>&1 | tee /tmp/xref-after.log
```

Compare against the pre-fix log:

```bash
bin/xref-report.sh --baseline /tmp/xref-before.baseline.json \
  < /tmp/xref-after.log
```

To use `--baseline`, the pre-fix state must be emitted as a JSON baseline:

```bash
bin/xref-report.sh --emit-baseline --source-build local-prefix \
  < /tmp/xref-before.log > /tmp/xref-before.baseline.json
```

Expected output of the diff:

- `fixed: N` where N equals the number of occurrences you removed.
- `introduced: 0`
- `net: -N`
- A "Fixed by branch" block attributing the fixes to the branch(es) you
  touched — a fix to trunk should not appear as fixes in 5.0.8 or 6.0.
- The specific `[branch/category] msg` row you targeted is listed under
  "Fixed (top 10)".

If `introduced > 0`, you broke something else. Investigate before proceeding.

When using `--branch <name>`, the tool scopes the baseline to the same
branch before diffing (schema_version 2 baselines only; a legacy baseline
without `target_counts` will exit with a message asking you to re-emit).

## Step 4 — Full multi-branch build before opening a PR

The scoped build covers a single Cassandra branch. The website build that
Jenkins runs includes trunk, active release branches, and asf-staging. Before
you consider the fix PR-ready, run the full build once:

```bash
./run.sh website build -e .xref-env 2>&1 | tee /tmp/xref-full.log
bin/xref-report.sh \
  --baseline /Users/patrick/local_projects/cassandra6-docs-workzone/research/antora3-xref-baseline.json \
  < /tmp/xref-full.log
```

Expected: `fixed >= 1`, `introduced == 0`. A non-zero `introduced` count is a
regression — do not open the PR until it is back to zero.

## Step 5 — Hand off to Patrick

This runbook stops here.

- **Do not `git push`** to any `apache/cassandra*` remote.
- **Do not run `gh pr create`** on `apache/*`.
- **Do not comment on, review, or merge any PR** on `apache/cassandra*`.

Commit locally on the topic branch (e.g. `broken-link-fix` for website work, or a
scoped topic branch for Cassandra-side fixes). Report back with:

- The broken `msg` you fixed
- The file(s) edited
- The `xref-report.sh --baseline` delta output (fixed/introduced/net)
- The branch name of your local commit

Patrick handles the ASF-visible actions (push, PR, JIRA transition, reviewer
coordination) per the `contributing-to-apache-cassandra` skill.

## Troubleshooting

- `xref-report.sh` shows `Total error-level entries: 0` but the build logged
  errors. Cause: Antora emitted pretty logs, not JSON. Confirm
  `ANTORA_LOG_FORMAT=json` is in your env file and `-e .xref-env` is on the
  command line.
- Build completes but your targeted branch is not in the by-branch breakdown.
  Cause: `-b cassandra:<other>` or tag auto-generation picked a different
  branch. Explicitly name the branch you care about.
- `fixed == 0` but `introduced == N`. Cause: the msg key changed (e.g. you
  changed the target to a new broken path). Read the "Introduced" list —
  whatever is there is your new bug.
- Diff totals look right but the rendered HTML still has `[xref unresolved]`
  markup on the page. Cause: the page is served from a cached build output;
  remove `cassandra-website/content/` and rebuild, or run
  `./run.sh website preview` which rebuilds on content change.
