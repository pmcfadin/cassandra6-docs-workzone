# Governance, Review, And Staging

Capture date: **2026-03-24**

## Purpose
This runbook records how Cassandra documentation changes should be proposed, reviewed, staged, and approved for publication. It covers both product-doc changes in `apache/cassandra` and website/publish changes in `apache/cassandra-website`.

For ASF-wide policy constraints that sit above Cassandra’s local process, see [`research/asf-governance.md`](../research/asf-governance.md).

## Governance Model
- Documentation changes are governed by the same contribution model as other Cassandra changes: use JIRA to track work, submit reviewable patches or pull requests, and wait for reviewer plus committer approval before merge. Sources: [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md), [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc).
- The docs contributor page explicitly recommends GitHub-only flow for shorter edits and JIRA-based workflow for major changes. Cassandra 6 docs should be treated as major change work, not ad hoc typo-fix flow. Source: [`development/documentation.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/documentation.adoc).

## ASF Constraints That Also Apply
- Important technical decisions should be made, or at minimum reflected, on public archived ASF channels rather than remaining only in chat or private coordination. Source: [ASF mailing list guidance](https://community.apache.org/contributors/mailing-lists.html).
- Consensus and lazy consensus are valid ASF decision models for routine changes, but major or disputed changes should have explicit review and visible agreement. Source: [ASF voting process](https://www.apache.org/foundation/voting.html).
- Official project website changes must stay within ASF website, branding, and privacy rules. Sources: [Infra website guidelines](https://infra.apache.org/website-guidelines.html), [ASF website CSP policy](https://infra.apache.org/csp.html), [ASF branding policy](https://www.apache.org/foundation/marks/pmcs).
- AI-assisted docs contributions remain subject to ASF provenance and licensing responsibilities. Source: [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).

## JIRA Expectations
- Start from an existing CASSANDRA JIRA issue or create a new one before significant work begins. Source: [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md).
- Use JIRA to:
  - describe the intended docs change
  - scope which versions and branches are affected
  - link working branches or PRs
  - track review state and reviewer feedback
  - preserve the final review record for substantial work
  Source: [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc), [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md).
- For Cassandra 6 docs, do not bundle all work into one umbrella ticket only. Use an umbrella issue plus slice-level tickets for page groups, generated-doc workflows, and website version-wire changes.

## Review Paths
### Product docs in `apache/cassandra`
- Use a branch off the appropriate Cassandra base branch.
- Self-review, build, test the relevant slice, and then submit either:
  - a GitHub PR, or
  - a patch attached to JIRA, or
  - a GitHub branch linked from JIRA
  Sources: [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md), [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc).
- Major docs changes should carry reviewer attribution in the final commit message using the standard Cassandra format. Source: [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc).

### Website and publish logic in `apache/cassandra-website`
- Use a normal GitHub PR flow for website changes.
- Treat changes to branch lists, alias logic, staging behavior, or site metadata as maintainer-reviewed infrastructure changes, not just content changes.
- For Cassandra 6 rollout, require at least one reviewer who understands the current website publish flow.

## Required Reviews For Cassandra 6 Docs
- Docs owner review:
  - structure, clarity, navigation, consistency, style
- Technical owner review:
  - correctness of behavior, defaults, upgrade semantics, configuration, and operations guidance
- Tooling owner review:
  - generated-doc provenance and regeneration steps
- Website/publish owner review:
  - version wiring, aliases, staging validation, and release promotion

No Cassandra 6 slice should merge without both docs-owner and technical-owner approval when it changes user-facing product behavior documentation.

## Staging Controls
- The website README defines the current publish chain: merge to website `trunk`, verify on [`cassandra.staged.apache.org`](https://cassandra.staged.apache.org/), then merge `asf-staging` to `asf-site`, then verify production on [`cassandra.apache.org`](https://cassandra.apache.org/). Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).
- Treat staging as a mandatory approval gate, not as a passive mirror.

Before approving staging for Cassandra 6 version work, verify:
1. `stable` and `latest` resolve to the intended major version.
2. `trunk` remains clearly prerelease.
3. The version selector shows the expected set of versions.
4. Generated docs render and are reachable from nav/xrefs.
5. No older supported versions lost their aliases or broke their URLs.
6. The staged site still complies with ASF website/privacy constraints for external resources and trackers.

## Committer And Publish Approval
- Non-committers can propose changes, but a Cassandra committer is required to merge to the authoritative Apache repos. Source: [`development/documentation.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/documentation.adoc), [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md).
- For product docs:
  - wait for review feedback and `+1` style approval before commit
  - preserve the review record in JIRA and/or PR discussion
- For website publish changes:
  - do not promote from `asf-staging` to `asf-site` until staging checks are complete and a maintainer explicitly signs off

## Recommended Cassandra 6 Governance Structure
- One umbrella JIRA for Cassandra 6 docs program management.
- Separate JIRAs for:
  - content inventory and gap analysis
  - generated-doc validation
  - per-module content rewrites
  - Cassandra 6 website version wire-up
  - staging and publish cutover
- Require each subtask to name:
  - source branch
  - owners
  - reviewer roles
  - staging impact
  - publish blocker status

## Done Criteria
- Every material change is traceable to a JIRA or reviewable PR.
- Every major content slice has named reviewers.
- Every staging promotion has an explicit validation record.
- Every production promotion has an accountable approver.
- Any AI-assisted contribution has provenance and licensing accountability consistent with ASF guidance.
