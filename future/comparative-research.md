# Comparative Research For A Future Cassandra Docs System

Capture date: **2026-03-24**

## What The Current Cassandra System Optimizes For
The current Cassandra process optimizes for release safety, staging control, and ASF publish discipline. It does not optimize for low-friction contribution.

Current local evidence from this workspace:
- docs source lives in `apache/cassandra/doc/`
- render and publish tooling live in `apache/cassandra-website`
- supported local preview flows go through Dockerized website tooling
- branch lists, aliases, and major-version metadata are partly hardcoded
- generated docs require separate regeneration and review

Sources:
- `../research/current-state.md`
- `../research/publishing-model.md`
- `../runbooks/build-preview-publish.md`
- `../runbooks/governance-review-and-staging.md`

## What Other Projects Do Better

## 1. Small changes are possible in the browser
Strong projects make the first documentation contribution feel cheap.

Examples:
- Kubernetes explicitly supports docs contributions through GitHub and has a dedicated contributor flow for opening pull requests and choosing the right branch. Source: <https://kubernetes.io/docs/contribute/new-content/>
- MDN supports direct content contribution in its content repo. Source: <https://github.com/mdn/content/blob/main/CONTRIBUTING.md>
- Astro docs treat single-page edits as a first-class contribution path. Source: <https://contribute.docs.astro.build/first-time/edit-single-page/>

Transferable idea for Cassandra:
- every rendered page should expose `Edit this page`
- typo and small-doc fixes should not require a contributor to understand the full website publish system

## 2. Large changes get a fast preview loop
The best systems reduce the gap between "I changed text" and "I saw the result."

Examples:
- Airflow supports docs autobuild flows from the package that owns the docs. Source: <https://raw.githubusercontent.com/apache/airflow/main/contributing-docs/11_documentation_building.rst>
- Kubernetes documents both local preview and segmented faster builds. Sources: <https://kubernetes.io/docs/contribute/new-content/preview-locally/>, <https://raw.githubusercontent.com/kubernetes/website/main/README.md>
- Python docs support live HTML preview for local work. Source: <https://devguide.python.org/documentation/start-documenting/>
- VitePress positions itself around fast dev-server feedback. Source: <https://vitepress.dev/guide/what-is-vitepress>

Transferable idea for Cassandra:
- local preview should be one command from the docs-owning repo
- the default preview path should not require contributors to understand the publish wrapper

## 3. Generated reference content is kept separate from hand-authored guides
Projects at scale do not pretend that hand-authored guidance and machine-derived reference pages are the same kind of asset.

Examples:
- Kubernetes generates some reference documentation from scripts and upstream API inputs. Source: <https://github.com/kubernetes/website>
- Superset uses Docusaurus plus generation scripts for derived docs surfaces. Sources: <https://raw.githubusercontent.com/apache/superset/master/docs/README.md>, <https://raw.githubusercontent.com/apache/superset/master/docs/package.json>
- MDN separates authored content, renderer/platform code, compatibility data, and translation infrastructure across repositories. Sources: <https://developer.mozilla.org/en-US/docs/MDN/Community/Our_repositories>, <https://github.com/mdn/yari>
- GitLab documents automated pages and generated documentation flows as part of the docs architecture. Source: <https://docs.gitlab.com/development/documentation/site_architecture/automation/>

Transferable idea for Cassandra:
- keep generated config, nodetool, and protocol docs in a clearly automated lane
- keep narrative guides in an editorial lane
- make CI fail if generated artifacts are stale relative to their sources

## 4. Versioning is useful, but it is also a tax
The best projects treat versioning as an explicit product decision, not a default.

Examples:
- Docusaurus warns that versioning increases contributor complexity and should be used only when justified. Source: <https://docusaurus.io/docs/versioning>
- Kubernetes uses a clear branch policy for current and release-specific docs. Source: <https://kubernetes.io/docs/contribute/new-content/>
- Superset scripts parts of its docs versioning rather than handling them ad hoc. Sources: <https://raw.githubusercontent.com/apache/superset/master/docs/README.md>, <https://superset.apache.org/developer-docs/contributing/release-process/>
- Rust publishes stable, beta, and nightly docs as release channels rather than forcing a general website versioning model onto all content. Sources: <https://github.com/rust-lang/book>, <https://doc.rust-lang.org/stable/book/>

Transferable idea for Cassandra:
- Cassandra should stop hand-maintaining version routing rules in multiple places
- current, prerelease, and supported releases should be declared from one machine-readable manifest

## 5. Governance is encoded in workflow, not left to folklore
Healthy doc systems make review ownership visible.

Examples:
- Kubernetes localization requires named teams, `OWNERS`, minimum publishable content, and approvers before a language goes live. Source: <https://kubernetes.io/docs/contribute/localization/>
- Airflow keeps authoring in the main project while separating publish/archive responsibilities in dedicated site repos. Sources: <https://github.com/apache/airflow-site>, <https://github.com/apache/airflow-site-archive>
- Cassandra itself already requires JIRA, review, staging, and committer approval for substantial work. Local source: `../runbooks/governance-review-and-staging.md`

Transferable idea for Cassandra:
- adopt `OWNERS`-style review routing for docs areas
- keep ASF staging and committer signoff, but remove unnecessary tool friction before that gate

## 6. AI-assisted contributions are becoming normal, but merge authority stays human
The strongest pattern is not "ban AI" or "trust AI". It is "allow assistance, require disclosure, ground output in project sources, and keep humans accountable."

Examples:
- ASF generative tooling guidance applies the same licensing and disclosure expectations to documentation and recommends `Generated-by:` provenance. Source: <https://www.apache.org/legal/generative-tooling.html>
- OpenInfra and Pulp add `Generated-By:` or `Assisted-By:` style disclosure and extra reviewer scrutiny. Sources: <https://openinfra.org/legal/ai-policy/>, <https://pulpproject.org/help/more/governance/ai_policy/>
- Python allows generative AI assistance but keeps contributors responsible for reviewing the result. Source: <https://devguide.python.org/getting-started/generative-ai/>
- GitLab explicitly documents AI use in docs workflows while keeping human review mandatory and using generated pages for structured truth. Sources: <https://docs.gitlab.com/development/documentation/ai_guide/>, <https://docs.gitlab.com/development/documentation/testing/>, <https://docs.gitlab.com/development/documentation/site_architecture/automation/>
- Next.js publishes `llms.txt` and related machine-oriented indexes, which is a useful example of docs that are readable by both humans and agents. Source: <https://nextjs.org/llms.txt>

Transferable idea for Cassandra:
- formalize an AI-assisted docs contribution policy instead of relying on implied behavior
- require source packs, citations, and reviewer-visible provenance
- publish a machine-oriented docs index for agents once the content model is stable

## Tooling Benchmarks

| Tool or project | Why it matters |
| --- | --- |
| Antora | Already close to Cassandra's current model and good at versioned multi-repo docs. Source: <https://docs.antora.org/antora/latest/playbook/> |
| Docusaurus | Strong versioning, search ecosystem, and contributor-friendly Markdown/MDX workflow. Source: <https://docusaurus.io/docs/versioning> |
| VitePress | Very fast local feedback for Markdown-first docs. Source: <https://vitepress.dev/guide/what-is-vitepress> |
| Astro Starlight | Low-friction docs UX with strong editing and navigation ergonomics. Source: <https://starlight.astro.build/> |
| mdBook | Extremely lightweight for book-like or tutorial-heavy docs. Source: <https://rust-lang.github.io/mdBook/> |
| Sphinx | Still excellent for API/reference-heavy and conservative documentation programs. Source: <https://devguide.python.org/documentation/start-documenting/> |

## Distilled Principles
If Apache Cassandra were being designed today as an ASF docs system, the strongest reusable principles would be:

1. Keep static-site output and ASF staging/publish controls.
2. Organize the docs around user intent and audience, not around repo layout.
3. Move day-to-day authoring into a one-command workflow from the docs-owning repo.
4. Separate authored guides from generated reference assets.
5. Put version routing in one declarative manifest.
6. Make browser-based edits and previewable pull requests normal.
7. Encode reviewer ownership in-repo.
8. Accept LLM-assisted contributions, but only when grounded in authoritative project inputs and reviewed by humans.

## Implication For Cassandra
The future state should not be "replace one site generator with another and hope the problem goes away."

The real target is:
- a role-based entry point for Operators, Developers, and Contributors
- lower contributor setup cost
- fewer hidden version/publish touchpoints
- clearer ownership for generated versus authored content
- explicit AI-era governance
- no conflict with ASF staging, committer review, or permanent static hosting
