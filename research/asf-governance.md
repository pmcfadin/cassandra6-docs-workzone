# ASF Governance And Documentation Rules

Capture date: **2026-03-24**

## Summary
For Apache Cassandra docs work, there are two layers of governance:
- **ASF-wide rules** governing public decision-making, legal provenance, official websites, branding, and AI-assisted contributions.
- **Cassandra-specific process** governing how this project chooses to track and review substantial changes, including JIRA-heavy workflow and current staging/publish practice.

ASF does not require a specific docs generator or a universal “all doc changes must use JIRA” rule. It does require that official project work happen within ASF governance and infrastructure constraints.

## ASF-Wide Rules That Apply To Docs
### Public decision-making
- ASF communities use public archived mailing lists as the primary place for important technical discussion and decisions. Source: [ASF mailing list guidance](https://community.apache.org/contributors/mailing-lists.html).
- Important decisions should be taken back to the mailing list so the whole community can participate; the ASF shorthand is effectively “if it didn’t happen on the mailing list, it didn’t happen.” Source: [ASF mailing list guidance](https://community.apache.org/contributors/mailing-lists.html).
- ASF decision-making uses consensus and, when needed, formal voting. Lazy consensus is an accepted default for low-risk routine actions. Source: [ASF voting process](https://www.apache.org/foundation/voting.html).

### Contributions and legal provenance
- ASF contributor agreements explicitly cover both software code and documentation. Source: [ASF contributor agreements](https://www.apache.org/licenses/contributor-agreements.html).
- Small contributions may be made under Apache License 2.0 clause 5, while large contributions and committer-level access require ICLA handling. Source: [ASF contributor agreements](https://www.apache.org/licenses/contributor-agreements.html).
- Contributors are responsible for having the rights to what they submit, including documentation text and any third-party material incorporated into it. Source: [ASF contributor agreements](https://www.apache.org/licenses/contributor-agreements.html).

### AI-generated documentation
- ASF generative tooling guidance applies to documentation as well as code. Source: [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).
- Contributors remain responsible for ensuring any third-party material in AI-assisted output is used with permission and under compatible terms. Source: [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).
- ASF recommends disclosing the use of generative tooling in commit metadata, for example with a `Generated-by:` token. Source: [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).

### Official website and publishing constraints
- Official project websites must be owned by the ASF, hosted on ASF-controlled infrastructure, licensed under Apache License 2.0, and published from ASF git or svn. Source: [Infra website guidelines](https://infra.apache.org/website-guidelines.html).
- Project sites must not redirect their front page away from `project.apache.org` to another domain. Source: [Infra website guidelines](https://infra.apache.org/website-guidelines.html).
- Project websites should not directly host downloads and should use ASF mirror/download mechanisms instead. Source: [Infra website guidelines](https://infra.apache.org/website-guidelines.html).
- The current ASF project website CSP policy forbids third-party trackers and restricts embedding external resources without the proper privacy/legal basis. Source: [ASF website CSP policy](https://infra.apache.org/csp.html).

### Branding and metadata
- ASF project websites must comply with Apache project branding requirements. Source: [ASF project branding policy](https://www.apache.org/foundation/marks/pmcs).
- ASF projects must provide DOAP or equivalent structured project metadata discoverable by ASF systems. Source: [ASF project branding policy](https://www.apache.org/foundation/marks/pmcs).

## What ASF Does Not Strictly Mandate
- ASF does not mandate Antora, Sphinx, MkDocs, or any specific doc toolchain.
- ASF does not impose a universal “docs changes must use JIRA” rule across all projects.
- ASF does not impose Cassandra’s exact `asf-staging` to `asf-site` promotion mechanics as a Foundation-wide docs rule; that is an implementation choice layered on ASF infrastructure and project practice.

## Cassandra-Specific Overlay
- Cassandra’s own docs contributor page recommends GitHub-only flow for small edits and JIRA-based workflow for major documentation changes. Source: [`development/documentation.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/documentation.adoc).
- Cassandra’s contribution docs recommend finding or creating a CASSANDRA JIRA before significant work and using reviewable branches, PRs, or patches. Source: [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md).
- Cassandra’s current site publication path uses staged deployment before production promotion. Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

## Practical Rules For This Workspace
1. Treat all substantial Cassandra 6 docs decisions as public-project decisions that should be reflected on public ASF channels.
2. Keep official docs content and publication on ASF-controlled repos and infrastructure.
3. Treat AI-generated doc text as contributable material that still requires provenance, licensing review, and human accountability.
4. Apply Cassandra’s JIRA-heavy workflow for major docs work even though JIRA itself is project-specific rather than ASF-universal.
5. Validate that any website changes also comply with ASF website, privacy, and branding requirements.
