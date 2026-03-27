# Current State

Capture date: **2026-03-24**

## Summary
- Apache Cassandra product documentation lives in the main Cassandra source tree under `doc/`, not in the website repo. Sources: [`apache/cassandra/doc`](https://github.com/apache/cassandra/tree/trunk/doc), [`doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml).
- The public website and publication tooling live in a separate repo, `apache/cassandra-website`. Source: [`apache/cassandra-website`](https://github.com/apache/cassandra-website).
- Cassandra docs use AsciiDoc plus Antora, but the practical local HTML build path is driven by the website repo tooling, not by a self-contained build inside `apache/cassandra`. Sources: [`doc/README.md`](https://github.com/apache/cassandra/blob/trunk/doc/README.md), [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

## Source Layout
- The Cassandra docs component is declared in [`doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml). On `trunk` it reports `version: 'trunk'` and `display_version: 'trunk'`; on the current release branch it reports `version: '5.0'` and `display_version: '5.0'`. Sources: [`trunk/doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml), [`cassandra-5.0/doc/antora.yml`](https://github.com/apache/cassandra/blob/cassandra-5.0/doc/antora.yml).
- Shared/root docs live under `doc/modules/ROOT`; product docs live under `doc/modules/cassandra`. Sources: [`doc/modules/ROOT`](https://github.com/apache/cassandra/tree/trunk/doc/modules/ROOT), [`doc/modules/cassandra`](https://github.com/apache/cassandra/tree/trunk/doc/modules/cassandra).
- Current product-doc page areas on `trunk` include `architecture`, `developing`, `getting-started`, `installing`, `integrating`, `managing`, `new`, `overview`, `reference`, `tooling`, `troubleshooting`, and `vector-search`. Source: [`doc/modules/cassandra/pages`](https://github.com/apache/cassandra/tree/trunk/doc/modules/cassandra/pages).

## Authoring And Generation Flow
- The Cassandra repo describes the documentation as in-tree official docs written in AsciiDoc and states that local HTML build instructions currently live in the website repo. Source: [`doc/README.md`](https://github.com/apache/cassandra/blob/trunk/doc/README.md).
- Dynamic AsciiDoc generation is wired through `make gen-asciidoc` and `ant gen-asciidoc`. The `doc/Makefile` calls:
  - `doc/scripts/gen-nodetool-docs.py`
  - `doc/scripts/convert_yaml_to_adoc.py`
  - `doc/scripts/process-native-protocol-specs-in-docker.sh`
  Sources: [`doc/Makefile`](https://github.com/apache/cassandra/blob/trunk/doc/Makefile), [`doc/scripts/gen-nodetool-docs.py`](https://github.com/apache/cassandra/blob/trunk/doc/scripts/gen-nodetool-docs.py), [`doc/scripts/convert_yaml_to_adoc.py`](https://github.com/apache/cassandra/blob/trunk/doc/scripts/convert_yaml_to_adoc.py), [`doc/scripts/process-native-protocol-specs-in-docker.sh`](https://github.com/apache/cassandra/blob/trunk/doc/scripts/process-native-protocol-specs-in-docker.sh).
- `build.xml` shows `base.version` is currently `6.0-alpha1`, `java.default` is `11`, and the `gen-doc` target depends on `gen-asciidoc`. Source: [`build.xml`](https://github.com/apache/cassandra/blob/trunk/build.xml).

## Website Build And Preview Flow
- The supported local workflow today is in `cassandra-website`: build the container, then use `./run.sh website build`, `./run.sh website build -g`, `./run.sh website preview`, or `./run.sh website docs ...`. Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).
- `run.sh` wraps Dockerized workflows for:
  - `website container`
  - `website docs`
  - `website build`
  - `website preview`
  Sources: [`run.sh`](https://github.com/apache/cassandra-website/blob/trunk/run.sh), [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).
- The site template is generated from `site-content/site.template.yaml` via `site-content/bin/site_yaml_generator.py`, which populates release attributes from the Apache downloads index. Sources: [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml), [`site-content/bin/site_yaml_generator.py`](https://github.com/apache/cassandra-website/blob/trunk/site-content/bin/site_yaml_generator.py), [downloads index](https://downloads.apache.org/cassandra/).

## Publish Model Today
- The live docs are served from [`/doc/`](https://cassandra.apache.org/doc/). On **2026-03-24**, both [`/doc/stable/`](https://cassandra.apache.org/doc/stable/) and [`/doc/latest/`](https://cassandra.apache.org/doc/latest/) resolve to Cassandra `5.0`, while [`/doc/trunk/`](https://cassandra.apache.org/doc/trunk/) is explicitly marked prerelease. Sources: [stable](https://cassandra.apache.org/doc/stable/), [latest](https://cassandra.apache.org/doc/latest/), [trunk](https://cassandra.apache.org/doc/trunk/).
- The website README describes the publish chain as: local build, PR to `trunk`, staged deploy to `cassandra.staged.apache.org`, merge `asf-staging` to `asf-site`, then production on `cassandra.apache.org`. Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).
- Publication is not fully auto-discovered for new major versions. The current branch list, alias-copy rules, and major-version metadata are hardcoded in multiple places. Sources: [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh), [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml).

## Governance And Review Today
- Cassandra’s current contribution guidance recommends starting from a CASSANDRA JIRA issue, working on a personal branch, self-reviewing, and then submitting either a PR, patch, or branch for review. Source: [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md).
- The contribution guide says major changes should be discussed early, tracked in JIRA, and moved through review with explicit reviewer feedback and final committer action. Source: [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc).
- The docs-specific contributor page recommends GitHub-only flow for short edits but JIRA-based workflow for major documentation changes. Source: [`development/documentation.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/documentation.adoc).
- The workspace implication is straightforward: Cassandra 6 docs should be governed as a tracked JIRA program with slice-level review and explicit staging signoff, not as an informal batch of content edits.
- ASF-wide governance also applies above the Cassandra-specific workflow: important decisions belong on public archived channels, official sites must comply with ASF website rules, and AI-assisted docs still carry contributor provenance obligations. Sources: [ASF mailing list guidance](https://community.apache.org/contributors/mailing-lists.html), [ASF voting process](https://www.apache.org/foundation/voting.html), [Infra website guidelines](https://infra.apache.org/website-guidelines.html), [ASF generative tooling guidance](https://www.apache.org/legal/generative-tooling.html).

## Risks And Observations
- The contributor guide for docs still points users to `doc/source/modules`, but the actual tree is `doc/modules`. This is evidence that contributor-facing docs should be verified against repo state before being reused in planning. Source: [`development/documentation.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/documentation.adoc), [`apache/cassandra/doc`](https://github.com/apache/cassandra/tree/trunk/doc).
- Generated outputs are intentionally ignored from the Cassandra repo in several places, including `cass_yaml_file.adoc`, `reference/native-protocol.adoc`, and the generated `managing/tools/nodetool/` directory. That means planning must distinguish committed source pages from build-generated docs. Source: [`trunk/.gitignore`](https://github.com/apache/cassandra/blob/trunk/.gitignore).
- New `trunk` pages that do not exist on `cassandra-5.0` already point to likely Cassandra 6 scope, including Accord architecture and several new operations/security topics. Source comparison: [`trunk` tree](https://github.com/apache/cassandra/tree/trunk/doc/modules/cassandra/pages), [`cassandra-5.0` tree](https://github.com/apache/cassandra/tree/cassandra-5.0/doc/modules/cassandra/pages).
