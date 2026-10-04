# Contributor Journeys: the end-user lens

2026-08-16. The organizing requirement for all pipeline work, stated plainly:
**a contributor with only a browser must be able to improve the docs.** The
build belongs to CI, review belongs to CI plus one committer click, publish
belongs to automation. The site is static today not because nobody cares but
because the cost of a one-line change is hours — so nobody does it.

**North-star metric: minutes from "typo spotted" to "live on
cassandra.apache.org," for a person with only a browser.**
Today: effectively infinite (the funnel loses them at JIRA-account-request or
Docker). Target: under an hour, one committer click as the only human step.

## Journey 1 — typo / improved wording (versioned docs)

| | Today | Target |
|---|---|---|
| Entry | find the repo, request a JIRA account via Slack/ML | click "Edit this page" pencil on the docs page |
| Edit | clone, branch, local Docker build to verify | GitHub web UI; auto-fork on propose |
| Verify | contributor builds (minutes–hours) or ships blind | CI: build + xref gate + smoke + screenshot + preview, ~3 min |
| Review | JIRA + reviewer round-trips | committer merges under existing CTR policy; `MINOR:` no-issue convention |
| Publish | Jenkins ~80 min + manual `reset --hard` ritual by a committer | automatic on green |
| Contributor time | hours; most abandon | ~3 minutes |

## Journey 2 — time-sensitive site content (event date, news)

The journey that makes the site feel dead. The blocker is not build speed —
it is that publish requires a human to remember a ritual. An event added
after the last manual promotion goes stale on `asf-staging`.

Fix: **merge = published** for site content. Auto-promote (or short-cycle
scheduled promote) once checks are green. The manual staging gate is project
convention, not ASF policy; for site content under CTR it is pure latency.

## Journey 3 — substantial docs work (new page, restructure)

Same web-first entry; local preview is optional, not required, and is
Node-only (`npx antora`, ~5 s — proven here). JIRA enters only where the
work is genuinely major, matching the tiering the official docs already
describe. CI must validate without rebuilding all of history — which is what
decoupled generation (generate once per release, persist, assemble) provides.

## Priority stack (by user impact, not engineering interest)

1. **"Edit this page" links everywhere** (`edit_url` is native Antora) plus a
   one-paragraph contributor page: click, edit, propose. The front door.
2. **Kill the JIRA wall for docs fixes** — socialize existing CTR +
   Arrow-style `MINOR:`. Publicity, not policy change.
3. **CI replaces the contributor's build** — build/gate/smoke/screenshot/
   preview on every PR (prototyped and green in this repo, PR #1).
4. **Merge = published** for website content — auto-promotion on green.
   The piece that makes the site alive.
5. **Decoupled generation** — frozen releases generated once and persisted;
   website assembles Node-only. Serves 1–4 by keeping CI fast and removing
   Docker/Java from every path a contributor could touch.

Every proposal gets judged by one question: does it reduce the minutes-to-live
number for the browser-only contributor?
