# Audience-Based Information Architecture For Cassandra Docs

Capture date: **2026-03-24**

## Goal
Define a concrete docs information architecture for Apache Cassandra that serves the primary user groups directly:
- `Operators`
- `Developers`
- `Contributors`
- `Reference`

This document is intended as the next step after `future/proposals.md`. It turns the audience model into a sitemap, content map, and migration guide grounded in the current Cassandra docs inventory.

## Why This Matters
The current Cassandra docs structure mixes product areas, source-tree history, and doc types:
- `architecture`
- `developing`
- `getting-started`
- `installing`
- `integrating`
- `managing`
- `reference`
- `tooling`
- `troubleshooting`
- `vector-search`

That layout is workable for maintainers, but it is not an ideal front door for users. A person arriving at the docs usually knows who they are and what they need to do before they know which internal content bucket Cassandra uses.

Local evidence:
- current page areas are captured in `inventory/docs-map.csv`
- the live workflow and governance burden are captured in `research/current-state.md` and `runbooks/build-preview-publish.md`

## Design Principles
1. Organize the front door around user role and user task.
2. Keep generated reference content separate from narrative guidance.
3. Make `Reference` supportive, not primary.
4. Let one page belong to one primary audience, even if it is linked from several places.
5. Split mixed-purpose pages instead of forcing users through shared catch-all hubs.
6. Preserve ASF publication and versioning constraints without exposing them in the information architecture.

## Top-Level Navigation

### 1. Operators
For people running Cassandra clusters in development, staging, or production.

Suggested sections:
- Overview
- Quickstart
- Install
- Configure
- Operate
- Secure
- Upgrade
- Tune
- Backup and recovery
- Observe and troubleshoot

### 2. Developers
For people building applications on Cassandra.

Suggested sections:
- Overview
- Quickstart
- Data modeling
- CQL and querying
- Drivers and client integration
- Application patterns
- Vector search
- Developer troubleshooting

### 3. Contributors
For people contributing code, docs, tests, build logic, and releases.

Suggested sections:
- Project overview
- Architecture
- Build and test
- Patch and review process
- Documentation contributions
- Release and website publishing
- Generated-doc tooling

### 4. Reference
For machine-derived or lookup-style content.

Suggested sections:
- Configuration reference
- Nodetool reference
- Native protocol reference
- Data types and syntax reference
- Version and compatibility data

## Recommended Front Page
The docs landing page should ask one question first: "What are you trying to do?"

Primary entry cards:
- Run Cassandra
- Build with Cassandra
- Contribute to Cassandra
- Browse reference

Secondary entry points:
- What is new in Cassandra 6
- Upgrade to Cassandra 6
- Troubleshoot a cluster
- Learn data modeling

This is a significant change from the current source-bucket navigation model and should be treated as a user-experience improvement, not just a menu rewrite.

## Audience Journeys

## Operators
Primary jobs:
- evaluate Cassandra
- install a cluster
- configure nodes
- secure a deployment
- upgrade safely
- operate and repair the cluster
- tune performance
- investigate failures

Recommended operator path:
1. `Operators Overview`
2. `Install`
3. `Configure`
4. `Operate`
5. `Upgrade`
6. `Observe and troubleshoot`
7. `Reference` links as needed

## Developers
Primary jobs:
- understand when Cassandra fits
- model data correctly
- write queries
- connect an application
- adopt new features such as vector search
- avoid common anti-patterns

Recommended developer path:
1. `Developers Overview`
2. `Quickstart`
3. `Data modeling`
4. `CQL and querying`
5. `Drivers and integration`
6. `Patterns and anti-patterns`
7. `Reference` links as needed

## Contributors
Primary jobs:
- understand the project architecture
- build Cassandra locally
- run tests
- submit patches through JIRA and review
- contribute docs
- understand release and website publication workflow

Recommended contributor path:
1. `Contributors Overview`
2. `Architecture`
3. `Build and test`
4. `Patch and review process`
5. `Documentation contributions`
6. `Release and publish workflow`

## Proposed Sitemap

## Operators
- `/operators/`
- `/operators/quickstart/`
- `/operators/install/`
- `/operators/configure/`
- `/operators/operate/`
- `/operators/upgrade/`
- `/operators/security/`
- `/operators/performance/`
- `/operators/backup-recovery/`
- `/operators/troubleshooting/`

## Developers
- `/developers/`
- `/developers/quickstart/`
- `/developers/data-modeling/`
- `/developers/cql/`
- `/developers/drivers/`
- `/developers/integration-patterns/`
- `/developers/vector-search/`
- `/developers/troubleshooting/`

## Contributors
- `/contributors/`
- `/contributors/architecture/`
- `/contributors/build-test/`
- `/contributors/patch-review/`
- `/contributors/documentation/`
- `/contributors/release-publish/`
- `/contributors/generated-docs/`

## Reference
- `/reference/`
- `/reference/configuration/`
- `/reference/nodetool/`
- `/reference/native-protocol/`
- `/reference/data-types/`
- `/reference/version-compatibility/`

## What Moves Where
This section maps current Cassandra docs areas to the proposed audience-based structure.

| Current area | Proposed home | Notes |
| --- | --- | --- |
| `overview` | split across `Operators`, `Developers`, and landing pages | Overview is currently too broad and should be decomposed by user job. |
| `getting-started` | primarily `Operators` and `Developers` | Split infra setup from app-first onboarding. |
| `installing` | `Operators` | Installation is an operator task. |
| `managing/configuration` | `Operators` plus `Reference` | Keep guidance in Operators; keep raw config material in Reference. |
| `managing/operating` | `Operators` | Core operator lane. |
| `managing/tools` | `Operators` plus `Reference` | Explanatory guides in Operators; full nodetool command pages in Reference. |
| `troubleshooting` | split into `Operators` and `Developers` | Cluster failures and application issues should not share the same landing page. |
| `developing/cql` | `Developers` plus `Reference` | Learning and patterns in Developers; syntax lookup can cross-link to Reference. |
| `developing/data-modeling` | `Developers` | Core application-builder path. |
| `integrating` | `Developers` | Plugin and client integration belongs in the developer lane unless it is an operator extension point. |
| `vector-search` | `Developers` with operator cross-links | Feature adoption guidance is developer-facing first, but deployment considerations should link from Operators. |
| `reference` | `Reference` | Keep as lookup-oriented content only. |
| `architecture` | `Contributors` with selective developer-facing summaries | Deep internal architecture is contributor-facing; public conceptual summaries can be linked elsewhere. |
| `tooling` | `Contributors` | Build and project tooling is contributor-facing by default. |
| `new` | top-level release hub or audience-specific "what's new" pages | Should not remain a generic standalone area. |
| `ROOT/index` | docs landing page | Replace with audience-first landing experience. |

## Current-To-Future Mapping By Known Pages
This mapping is based on the current local inventory and is intentionally high level. It is enough to drive a first restructuring pass.

| Current page | Primary future home | Action |
| --- | --- | --- |
| `ROOT/pages/index.adoc` | `/` | rewrite |
| `overview/index.adoc` | `/` or split audience overview pages | split |
| `overview/faq/index.adoc` | audience-specific FAQs or shared support page | split |
| `getting-started/index.adoc` | `/operators/quickstart/` and `/developers/quickstart/` | split |
| `getting-started/configuring.adoc` | `/operators/configure/` | move |
| `installing/installing.adoc` | `/operators/install/` | move |
| `developing/index.adoc` | `/developers/` | rewrite |
| `developing/cql/index.adoc` | `/developers/cql/` | move |
| `developing/cql/constraints.adoc` | `/developers/cql/` or `/reference/data-types/` | review |
| `developing/data-modeling/index.adoc` | `/developers/data-modeling/` | move |
| `managing/index.adoc` | `/operators/` | rewrite |
| `managing/configuration/index.adoc` | `/operators/configure/` | move |
| `managing/configuration/cass_yaml_file.adoc` | `/reference/configuration/` | keep generated |
| `managing/operating/index.adoc` | `/operators/operate/` | move |
| `managing/operating/async-profiler.adoc` | `/operators/performance/` | move |
| `managing/operating/auto_repair.adoc` | `/operators/operate/` | move |
| `managing/operating/onboarding-to-accord.adoc` | `/operators/upgrade/` or feature rollout guidance | review |
| `managing/operating/password_validation.adoc` | `/operators/security/` | move |
| `managing/operating/role_name_generation.adoc` | `/operators/security/` | move |
| `managing/tools/index.adoc` | `/operators/operate/` with links to reference | split |
| `managing/tools/nodetool/*.adoc` | `/reference/nodetool/` | keep generated |
| `reference/index.adoc` | `/reference/` | rewrite |
| `reference/native-protocol.adoc` | `/reference/native-protocol/` | keep generated |
| `reference/vector-data-type.adoc` | `/reference/data-types/` and developer links | move |
| `architecture/index.adoc` | `/contributors/architecture/` | move |
| `architecture/overview.adoc` | `/contributors/architecture/` | move |
| `architecture/accord.adoc` | `/contributors/architecture/` with operator or developer summaries as needed | review |
| `architecture/accord-architecture.adoc` | `/contributors/architecture/` | move |
| `architecture/cql-on-accord.adoc` | `/contributors/architecture/` and `/developers/cql/` cross-link | split or cross-link |
| `integrating/plugins/index.adoc` | `/developers/drivers/` or `/developers/integration-patterns/` | review |
| `tooling/index.adoc` | `/contributors/build-test/` or `/contributors/generated-docs/` | split |
| `troubleshooting/index.adoc` | `/operators/troubleshooting/` plus `/developers/troubleshooting/` | split |
| `vector-search/overview.adoc` | `/developers/vector-search/` | move |
| `vector-search/quickstarts.adoc` | `/developers/vector-search/` | move |
| `vector-search/vector-search-working-with.adoc` | `/developers/vector-search/` | move |
| `new/index.adoc` | release hub | rewrite |

## Content Splits That Should Happen Early
These are the highest-value structural fixes because they remove ambiguity fast.

1. Split `getting-started` into an operator quickstart and a developer quickstart.
2. Split `troubleshooting` into cluster troubleshooting and application troubleshooting.
3. Split `managing/tools` into operator guidance plus generated reference pages.
4. Split broad `overview` content into audience landing pages.
5. Move deep internal architecture under `Contributors`, then add short conceptual summaries for external audiences where needed.

## Reference Model
`Reference` should contain:
- generated pages
- syntax and schema reference
- protocol and configuration reference
- concise lookup pages

`Reference` should not contain:
- onboarding
- best-practice guides
- narrative troubleshooting
- deployment decision guidance

This distinction matters for both humans and LLM agents. Narrative content should answer "what should I do?" Reference should answer "what is the exact behavior or syntax?"

## Navigation Rules
1. Every page gets one primary audience.
2. Cross-link freely, but do not put the same page into several top-level homes.
3. Generated pages always live under `Reference`, even when operator or developer guides link to them.
4. Pages that mix explanation and raw reference should be split if they become hard to scan.
5. "What's new" content should be release-scoped and linked from the relevant audience areas, not left as an orphan content island.

## Search And LLM Implications
An audience-based architecture will help both users and agents:
- better landing-page routing
- cleaner metadata on page purpose
- easier machine understanding of whether a page is guide, task, concept, or reference
- better opportunity to emit machine-readable manifests for audience and doc type

Recommended metadata per page:
- `audience: operator | developer | contributor | reference`
- `doc_type: overview | tutorial | how-to | concept | reference | generated`
- `version`
- `source_of_truth`
- `generated: true|false`

## Phased Adoption

### Phase 1
- keep the current tooling
- add audience landing pages
- remap navigation
- move or alias existing content into the new top-level structure

### Phase 2
- split mixed pages
- move generated material into a cleaner reference lane
- add audience metadata and review ownership

### Phase 3
- align the chosen docs platform with the audience-first structure
- add machine-readable manifests and agent-facing outputs

## Recommendation
This audience model should be treated as independent of the tooling decision.

Even if Cassandra keeps Antora, the docs should still be reorganized around:
- `Operators`
- `Developers`
- `Contributors`
- `Reference`

If Cassandra adopts the hybrid future platform, this information architecture should become the backbone of the new docs site and the docs-centric website makeover.

## Sources
- `inventory/docs-map.csv`
- `future/proposals.md`
- `research/current-state.md`
- `runbooks/build-preview-publish.md`
