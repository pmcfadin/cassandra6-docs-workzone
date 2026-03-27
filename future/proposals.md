# Future-State Proposals For Apache Cassandra Docs

Capture date: **2026-03-24**

## Decision Frame
Any redesign has to satisfy four constraints at the same time:

1. It must reduce contributor friction materially.
2. It must fit ASF static-site publishing and review norms.
3. It must preserve or improve generated-doc provenance.
4. It must acknowledge that contributors will use LLM-based agents.

The current pain is not that Cassandra chose Antora or AsciiDoc. The pain is that authoring, preview, versioning, and publish promotion are split across too many hidden steps.

## Audience-Based Information Architecture
The future docs system should be organized around the primary user jobs, not around the repository layout.

The three top-level audiences should be:
- `Operators`: people deploying, upgrading, securing, tuning, backing up, and troubleshooting Cassandra clusters
- `Developers`: people designing schemas, connecting applications, querying Cassandra, and integrating drivers or APIs
- `Contributors`: people changing Cassandra itself, including code, docs, tests, builds, release process, and project governance

This matters because the current docs model is closer to a source-tree model than a user-intent model. A modern docs experience should let a user identify themselves quickly and then move through a purpose-built path.

### Proposed top-level structure
- `Operators`
  - quickstart and deployment choices
  - install and upgrade
  - cluster operations
  - performance and tuning
  - backup, restore, repair, and disaster recovery
  - security
  - observability and troubleshooting
- `Developers`
  - getting started with Cassandra as an application database
  - data modeling
  - CQL and querying
  - drivers and client integration
  - application patterns and anti-patterns
  - vector search and new feature adoption
- `Contributors`
  - project overview and architecture
  - build, test, and local development
  - patch process, JIRA, and review
  - documentation contribution guide
  - release and website publishing workflow
  - generated-doc provenance and tooling
- `Reference`
  - configuration reference
  - nodetool reference
  - protocol and API reference
  - version compatibility and support data

The important design choice is that `Reference` should not be the front door. It should support Operators and Developers, not replace their journeys.

## Proposal 1: Keep Antora, Remove The Friction

### Summary
This is the lowest-risk redesign. Keep AsciiDoc and Antora, but collapse the authoring experience into one docs workflow owned by the Cassandra repo. Treat `cassandra-website` as a thin ASF publish wrapper, not the place contributors have to learn first.

### What changes
- Keep docs in `apache/cassandra/doc/`
- Keep Antora as the versioned docs engine
- Restructure navigation around `Operators`, `Developers`, `Contributors`, and `Reference`
- Add a first-class local preview command in the Cassandra repo:
  - `./doc/tools/preview`
  - `./doc/tools/check`
- Replace hardcoded branch and alias logic with one machine-readable manifest, for example `doc/versions.yaml`
- Generate the website playbook and alias map from that manifest
- Add PR preview artifacts for docs changes
- Add `Edit this page` links everywhere
- Add docs-area ownership files for review routing

### Modernized tooling
- Antora stays, but the build entrypoint moves closer to the content
- Docker becomes optional, not the default
- Local preview should render from the Cassandra checkout directly
- CI runs link checks, nav checks, generated-doc freshness checks, and render validation

Relevant examples:
- Antora playbooks are designed to control content sources and publishing centrally. Source: <https://docs.antora.org/antora/latest/playbook/>
- Airflow keeps docs near the code and supports dedicated docs autobuild flows. Source: <https://raw.githubusercontent.com/apache/airflow/main/contributing-docs/11_documentation_building.rst>
- Kubernetes makes preview a documented contributor path rather than maintainer tribal knowledge. Source: <https://kubernetes.io/docs/contribute/new-content/preview-locally/>

### ASF alignment
- No dependence on non-ASF production hosting
- Final publication still flows through staged static output and committer promotion
- Existing JIRA, review, and staging controls remain valid
- `cassandra-website` can continue to own the final Apache site branches

### User participation impact
- Existing contributors do not need to relearn the markup language
- New contributors get a one-repo, one-command start
- Small fixes become realistic for non-experts
- Users get clearer entry points based on what they are trying to do instead of how Cassandra's source docs are currently grouped

### LLM-aware policy
- Add a docs PR template with:
  - `Sources used`
  - `Generated docs refreshed`
  - `AI assistance used`
  - `Human verification performed`
- Require `Generated-by:` or `Assisted-by:` provenance for substantive AI-shaped changes
- Publish a Cassandra docs source-pack policy for agent-assisted authoring

### Tradeoffs
- Lowest migration risk
- Lowest retraining cost
- Does not deliver the lowest possible authoring friction because AsciiDoc plus Antora is still more specialized than Markdown-first systems

### Best fit
- Best if Cassandra wants a practical improvement in one or two release cycles without a full content migration

## Proposal 2: Move Authored Docs To Docusaurus, Keep Generated Reference Automated

### Summary
This is the strongest contributor-experience option for a large versioned OSS docs program. Move hand-authored guides to Markdown or MDX in a dedicated docs site based on Docusaurus. Keep generated reference surfaces scripted and imported from source artifacts rather than hand-maintained.

### What changes
- Create a dedicated docs repo or docs directory with Docusaurus 3
- Migrate narrative guides from AsciiDoc to Markdown/MDX
- Restructure the site around audience landing pages for Operators, Developers, and Contributors
- Keep generated config, nodetool, and protocol outputs in an automated import path
- Version releases with scripted snapshots instead of manually wired aliases
- Publish static output into the ASF website flow

### Modernized tooling
- Markdown-first authoring
- Hot reload for docs development
- Conventional Node-based docs tooling with straightforward local setup
- Built-in versioning model for release documentation
- Easy edit links, sidebars, search integrations, and content reuse

Relevant examples:
- Apache Superset uses Docusaurus 3 and scripts docs versioning beyond the defaults. Sources: <https://raw.githubusercontent.com/apache/superset/master/docs/README.md>, <https://superset.apache.org/developer-docs/contributing/release-process/>
- Docusaurus supports versioned documentation but warns teams to use it deliberately. Source: <https://docusaurus.io/docs/versioning>
- React Native shows the general viability of Docusaurus for release-versioned product docs. Source: <https://github.com/facebook/react-native-website>

### ASF alignment
- Static HTML output fits ASF hosting cleanly
- The build can run in GitHub Actions or a local container without changing the ASF publish model
- Staging and `asf-site` promotion remain the final release gates

### User participation impact
- Much lower barrier for community contributors because Markdown is the default docs language most contributors already know
- Easier in-browser edits
- Easier contributor onboarding docs
- Better long-term chance of organic community docs participation
- Cleaner separation between operator tasks, application-development guidance, and contributor workflows

### LLM-aware policy
- Docusaurus content is especially well suited to retrieval-grounded drafting because pages are simple text assets with frontmatter
- Add `llms.txt` and version-scoped machine-readable indexes once the content model stabilizes
- Keep generated reference pages outside freeform AI editing and require regeneration checks

Example:
- Next.js publishes an `llms.txt` index and version-scoped machine-readable docs outputs. Source: <https://nextjs.org/llms.txt>

### Tradeoffs
- Higher migration cost
- Requires format conversion from AsciiDoc to Markdown/MDX
- Existing Antora semantics and cross-references will need translation
- Generated-doc integration needs deliberate design so the reference layer does not rot

### Best fit
- Best if Cassandra wants a major reset in contributor experience and is willing to invest in migration work

## Proposal 3: Hybrid Docs Platform For Humans And Agents

### Summary
If building today with fresh eyes, this is the most future-facing design. Use a fast narrative-docs framework such as Astro Starlight or VitePress for hand-authored guides, and publish generated reference docs from a separate structured pipeline. The site becomes intentionally dual-purpose: good for humans, readable for agents.

### What changes
- Narrative docs move to Markdown-based Starlight or VitePress
- Narrative docs are organized first by audience:
  - `Operators`
  - `Developers`
  - `Contributors`
- Generated reference content stays script-driven and lands in a dedicated reference section
- Version declarations, support windows, and aliases are driven from one manifest
- The published site emits:
  - `sitemap.xml`
  - `llms.txt`
  - version manifest
  - source provenance metadata for generated pages
- Add a `docs-source-pack.json` or equivalent manifest for agent tooling

### Modernized tooling
- Very fast local preview and low setup cost
- Excellent navigation and search UX for narrative docs
- Clear separation between editorial content and generated reference
- Easier experimentation with machine-readable outputs for LLM retrieval

Relevant examples:
- VitePress emphasizes fast no-reload local updates. Source: <https://vitepress.dev/guide/what-is-vitepress>
- Astro Starlight is optimized for documentation sites with strong contributor ergonomics. Source: <https://starlight.astro.build/>
- mdBook shows how lightweight Markdown-first systems can stay maintainable at scale for book-like docs. Source: <https://rust-lang.github.io/mdBook/>
- GitLab documents automated pages and structured generation in its docs architecture. Source: <https://docs.gitlab.com/development/documentation/site_architecture/automation/>

### ASF alignment
- Production output is still static HTML
- ASF staging and committer review still govern promotion
- The hybrid split affects authoring and build design, not Apache governance

### User participation impact
- Best chance of attracting casual and first-time docs contributors
- Strongest fit for community-written tutorials, how-to guides, and troubleshooting pages
- Lets domain experts contribute narrative guidance without touching generated reference pipelines
- Gives Cassandra a clearer information architecture that serves deployers, application developers, and project contributors as distinct users

### LLM-aware policy
- This proposal treats machine consumption as a first-class requirement
- Add AI contribution disclosure in PR templates
- Require source-grounded drafting from approved source packs
- Publish machine-readable discovery artifacts for agent retrieval
- Make AI-assisted bulk changes fail CI if they lack citations or generated-doc freshness

Relevant governance examples:
- ASF generative tooling guidance. Source: <https://www.apache.org/legal/generative-tooling.html>
- OpenInfra AI policy. Source: <https://openinfra.org/legal/ai-policy/>
- Python generative AI contributor guidance. Source: <https://devguide.python.org/getting-started/generative-ai/>

### Tradeoffs
- Highest design effort
- Introduces a hybrid architecture that must be kept conceptually clean
- Needs careful information architecture so users do not feel like they are visiting two different sites

### Best fit
- Best if Cassandra wants to design a docs platform for the next five years, not just simplify the next release cycle

## Proposal Comparison

| Proposal | Migration risk | Contributor UX | Generated-doc fit | ASF fit | LLM readiness |
| --- | --- | --- | --- | --- | --- |
| 1. Keep Antora, remove the friction | Low | Medium | Strong | Strong | Strong |
| 2. Move authored docs to Docusaurus | Medium | Strong | Medium to strong | Strong | Strong |
| 3. Hybrid docs platform for humans and agents | Medium to high | Very strong | Very strong | Strong | Very strong |

## Recommended Direction
If the question is "what should Cassandra do next with the least risk," choose **Proposal 1**.

If the question is "what would I build today for an ASF project with fresh eyes," choose **Proposal 3**.

If the question is "what structural change matters regardless of tooling choice," adopt the **audience-based information architecture** immediately:
- `Operators`
- `Developers`
- `Contributors`
- `Reference`

That recommendation is based on one core judgment:
- Cassandra's real complexity comes from versioning, generation, and publish wiring
- a modern docs system should simplify those concerns for contributors
- users should enter the docs based on their role and task, not internal documentation ownership boundaries
- it should also assume that future users and contributors will read, search, summarize, and draft through LLM-based agents

## Minimum Viable Future State
Even if Cassandra does not adopt a full migration, these changes should happen:

1. Single declarative version manifest.
2. One-command local preview from the docs-owning repo.
3. PR preview artifacts for docs changes.
4. Separate authored versus generated content lanes.
5. Review ownership encoded in-repo.
6. AI-assisted contribution policy with provenance and source-pack rules.
7. Machine-readable docs index for agents after the information model is stable.
8. Top-level information architecture organized around Operators, Developers, Contributors, and Reference.
