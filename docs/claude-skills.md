# Claude skills for this workzone

What exists, what each one is for, and when to reach for it. Three skills are
installed at `~/.claude/skills/`. They are user-level, not checked into this
repo, so they travel with the machine rather than the project.

Last verified: 2026-10-03.

---

## The three installed skills

### `cassandra-contribution` — governance and process

The rulebook for getting a change *landed*. Covers the two governance layers
that every Cassandra contribution sits inside:

- **ASF-wide**: public mailing-list decision-making, lazy consensus, ICLA,
  AI-assisted contribution provenance, official-website constraints (ASF-hosted,
  Apache-2.0, no third-party trackers, no direct downloads).
- **Cassandra-specific**: JIRA-first for substantial work, patch flow, reviewer
  and committer requirements, and the seven-step staging-to-production publish
  chain.

It also carries the repo-selection table (does this change belong in
`apache/cassandra` or `apache/cassandra-website`?), the local build commands,
and the review gates to apply before calling work done.

**Reach for it when**: opening a PR, deciding whether something needs a JIRA,
working out who must review, building or previewing locally, or promoting
`asf-staging` → `asf-site`.

### `cassandra-docs-authoring` — the words on the page

The other half of the pair. Where `cassandra-contribution` governs *how work
lands*, this governs *what the page says*. Covers audience-first IA (Operators /
Developers / Contributors / Reference), the page-type system (start / concept /
task / reference / bridge), per-shape templates, voice rules, AsciiDoc and Antora
syntax including the cross-component three-part xref form, and the recurring
failure modes pulled from this project's own docs critiques.

**Reach for it when**: drafting a new page, rewriting an existing one, or
reviewing prose against the project's editorial standards.

### `cassandra-pr-labeller` — triage automation

Proposes GitHub labels for open `apache/cassandra` PRs from changed paths,
titles, and linked JIRA status. Ships a `propose_labels.py` helper.

Deliberately constrained: the proposer is read-only, labels are applied only
after per-group approval, and it never removes labels, touches JIRA, comments,
commits, or pushes.

**Reach for it when**: doing PR triage sweeps.

---

## CLAUDE.md is out of date

`CLAUDE.md` advertises seven project skills:

> `cassandra-doc`, `cassandra-changelog-triage`, `cassandra-researcher`,
> `cassandra-delta-catalog`, `cassandra-inventory-reconciliation`,
> `cassandra-asciidoc-authoring`, `cassandra-antora-preview`

**None of these exist on disk.** There is no `.claude/skills/` directory in this
repo, and `~/.claude/skills/` contains only the three above. The research
workflow section of `CLAUDE.md` references the same non-existent skills.

Treat that table as a roadmap, not an inventory. Either build the skills or trim
the table — otherwise it sends every new session looking for tooling that is not
there.

---

## Skills this workzone uses but does not own

General-purpose skills that have earned their place in this work:

| Skill | Use |
|---|---|
| `writing-clearly-and-concisely` | Prose humans read — docs, commit messages, PR bodies |
| `humanizer` | Stripping AI tells from drafted copy |
| `playwright-cli` | Driving a browser for rendered-output verification and screenshots |
| `fastmod` | Bulk literal rewrites across many files without reading them all |
| `code-review` | Reviewing a diff before it becomes a PR |

---

## Hard-won gotchas that are not in any skill

Recorded here because they cost real time and are invisible from the docs.

**`-g` is mandatory, not optional, when building Cassandra docs.**
`runbooks/fix-broken-xref.md` says `-g` is needed "only if your broken target is
a generated page". That is wrong and it fails silently. In
`site-content/docker-entrypoint.sh`, `ANTORA_CONTENT_SOURCE_REPOSITORIES`
initialises to `(CASSANDRA_WEBSITE)` and `CASSANDRA` is appended *only* inside
`generate_cassandra_versioned_docs()`, which runs only under `-g`. Without it the
entire Cassandra corpus is excluded and the build reports a near-clean handful of
errors. A build that looks almost finished is the symptom.

**The container builds the branch ref, not your worktree.**
With `-u cassandra:<path>`, the entrypoint copies the repo and checks out the
requested branch. Pointing your worktree at the state you want to measure is not
enough — move the local branch ref, or you will measure something else entirely.

**`ant gen-doc` exits 0 while emitting error-level messages.**
`doc/site-local.yml` sets no `runtime.log.failure_level`, so the in-tree build
reports `BUILD SUCCESSFUL` with dozens of error-level entries. Count the errors;
do not trust the exit code.

**Antora 2 vs 3 error gating is the whole reason this workstream exists.**
Antora 2 fails only on `fatal`; Antora 3 promotes `error` to build-blocking. The
broken links were always broken — Antora 3 just stopped hiding them.

**The ui-bundle is coupled to the Antora major version.**
Building site-content on Antora 3 against an Antora-2-built `ui-bundle.zip`
produces a site that looks perfect and has silently dead search: the bundled
partials still carry `{{#if env.DOCSEARCH_ENABLED}}` guards that Antora 3's
`@antora/lunr-extension` never sets. The index is generated and then never
loaded. No error, no warning.

---

## Commit and JIRA conventions

Enforced by reviewers, learned by correction:

- Commit title is plain text with **no** `CASSANDRA-XXXXX:` prefix. The JIRA id
  goes only in the trailer: `patch by <author>; reviewed by <reviewer> for
  CASSANDRA-XXXXX`. GitHub **PR titles** keep the prefix — githubbot uses it to
  link the PR to the ticket.
- Keep commit bodies short: a title and about three one-line bullets. Verification
  detail belongs in the PR comment, not the commit.
- Do not hard-wrap commit message lines. It makes the text painful for reviewers
  to edit.
- Disclose AI assistance with an `Assisted-By:` trailer, per the Linux generative
  AI guidelines the project is building precedence on.
- On resolve: concrete fixVersions per committed branch (`4.0.21`, not `4.0.x`)
  and populate the Source Control Link field.
