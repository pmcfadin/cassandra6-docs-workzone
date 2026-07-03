# Operator Integrations Plan

**Date:** 2026-04-02  
**Scope:** Review document only. No Operator IA or content changes are implemented by this document.  
**Status:** Draft for review

---

## Summary

The current Operator section in this workzone has strong coverage for core Cassandra deployment, security, repair, backup, upgrade, and Kubernetes decision-making, but it has almost no explicit guidance for two official Cassandra subprojects that are operator-relevant: Apache Cassandra Sidecar and Apache Cassandra Analytics.

This is a documentation gap in the Operator section, not evidence that Cassandra itself is missing these capabilities.
The planning question is how Cassandra Operator docs should acknowledge these official integrations without duplicating the subproject manuals or making unsupported compatibility claims.

This brief recommends a **boundary-first** approach:

- Cassandra Operator docs should explain **when** an operator would use Sidecar or Analytics
- Cassandra Operator docs should explain **prerequisites, cluster impact, risks, and decision points**
- Sidecar and Analytics docs should continue to own **installation steps, full API/config reference, and detailed execution workflows**

The current-state evidence supports planning for both projects together because Analytics explicitly depends on Sidecar for key workflows.

---

## Purpose And Scope

This document is intended to:

- capture the current documentation gap in the Operator section
- summarize verified current-state findings for Sidecar and Analytics
- define the documentation boundary between Cassandra Operator docs and the subproject docs
- propose information architecture options for future implementation
- recommend a first-pass content set that can be reviewed before any docs implementation begins

Out of scope for this document:

- editing any file under `content/operators/`
- changing Antora navigation
- drafting final operator pages
- asserting Cassandra 6 compatibility for either subproject unless explicitly proven upstream

---

## Current Gap In The Operator Section

The current Operator IA includes strong coverage for core Cassandra operations and one explicit ecosystem boundary page for Kubernetes/K8ssandra, but it does not provide comparable entry-point guidance for Cassandra Sidecar or Cassandra Analytics.

Current local evidence:

- `content/operators/modules/ROOT/nav.adoc` has no Sidecar or Analytics entry in `Get Started`, `Day 2`, `Backup and Recovery`, or `Automate`
- `content/operators/modules/ROOT/pages/index.adoc` does not surface either project in the operator landing page or recommended reading path
- `content/operators/modules/ROOT/pages/automate/kubernetes-considerations.adoc` explicitly defines a documentation boundary for K8ssandra, which is a useful precedent for handling adjacent official or ecosystem tooling

This omission matters because operators encountering:

- API-driven cluster lifecycle management
- externalized CDC pipelines
- snapshot-backed bulk reads
- Sidecar-mediated SSTable import and restore flows
- Spark bulk analytics and multi-cluster coordinated writes

currently have no clear Cassandra Operator doc entry point that explains when these workflows are appropriate, what they require, or where the official boundary lies.

Inference:
The Operator section currently treats K8ssandra as a documented external operating model, but it does not yet treat Sidecar and Analytics as first-class operator integration topics.

---

## Verified Current-State Findings: Cassandra Sidecar

### What is clearly supported by the official project materials

- Sidecar is an official Apache Cassandra subproject with its own repository and JIRA project.
- Sidecar exposes an HTTP API surface and publishes OpenAPI specifications and Swagger UI at runtime.
- Sidecar includes operator-relevant capabilities beyond simple health checks, including lifecycle APIs, CDC-related APIs/configuration, snapshots, restore jobs, live migration, and node operations.
- Sidecar includes authentication, authorization, TLS, RBAC, and mTLS-related configuration surfaces.
- Sidecar is explicitly designed to abstract Cassandra-version differences behind adapters rather than exposing version-specific APIs to clients.

Official evidence:

- Sidecar README: <https://github.com/apache/cassandra-sidecar/blob/trunk/README.md>
- Sidecar OpenAPI notes: <https://github.com/apache/cassandra-sidecar/blob/trunk/OPENAPI.md>
- Sidecar CONTRIBUTING adapter/API design guidance: <https://github.com/apache/cassandra-sidecar/blob/trunk/CONTRIBUTING.md>

### Operator-relevant capability summary

Based on the official docs and project files, the operator-relevant capabilities worth documenting at the Cassandra level are:

- health and readiness endpoints
- OpenAPI and discoverable runtime API surface
- lifecycle APIs for starting and stopping Cassandra
- CDC enablement and Kafka-oriented CDC configuration
- snapshot and restore-related surfaces
- live migration and file movement surfaces
- RBAC, JWT, mTLS, and TLS server/client configuration

### Compatibility posture

The Sidecar public materials show mixed signals that should be documented carefully:

- The README still states a requirement of Apache Cassandra 4.0 and says Sidecar depends on 4.0 virtual tables.
- The same README also says the default test framework runs `4.1` and `5.1 (Trunk)` tests.
- The contributor docs say the base adapter supports Cassandra `4.0 and greater, including trunk`.
- `gradle.properties` says trunk is currently `5.1`.

Implication:
Sidecar appears actively maintained and intended to span multiple Cassandra versions, but the public project docs are not yet aligned enough to justify a direct Cassandra 6 support statement in Cassandra Operator docs.

Recommended wording for later operator docs:

- describe Sidecar as an official Cassandra subproject with active multi-version design intent
- link to Sidecar’s official compatibility/project docs
- avoid claiming Cassandra 6 support unless verified in upstream release or test documentation

---

## Verified Current-State Findings: Cassandra Analytics

### What is clearly supported by the official project materials

- Cassandra Analytics is an official Apache Cassandra subproject with its own repository.
- The public user documentation says Analytics uses Cassandra Sidecar to interact with the target cluster.
- Analytics provides bulk reader and bulk writer workflows.
- The bulk reader uses Sidecar contact points and supports snapshot-based reads.
- The bulk writer supports both direct Sidecar-mediated transport and `S3_COMPAT` transport with coordinated multi-cluster write.
- Analytics also includes CDC-related modules and recent change log entries for Cassandra 5.0 CDC support.

Official evidence:

- Analytics user doc: <https://github.com/apache/cassandra-analytics/blob/trunk/docs/src/user.adoc>
- Analytics change log: <https://github.com/apache/cassandra-analytics/blob/trunk/CHANGES.txt>
- Analytics repository settings/modules: <https://github.com/apache/cassandra-analytics/blob/trunk/settings.gradle>

### Operator-relevant capability summary

The operator-relevant Analytics topics that Cassandra docs could reasonably introduce are:

- why Analytics exists versus core Cassandra operational tools
- requirement for reachable Sidecar contact points
- bulk reader snapshot behavior and snapshot cleanup strategy
- bulk writer modes:
  - direct Sidecar upload
  - S3-compatible transport
  - coordinated multi-cluster write
- cluster prerequisites for Spark-based bulk jobs
- TLS, truststore, keystore, and authorization role implications when jobs call Sidecar

### Compatibility posture

The public repository signals a narrower version story than Sidecar:

- the repo includes `cassandra-four-zero-*` and `cassandra-five-zero-*` bridge modules
- the integration test version supplier defaults to `5.0`
- recent change log entries call out Cassandra 5.0 CDC support specifically
- the public materials reviewed do not explicitly claim Cassandra 6 support

Implication:
Analytics is clearly active and Sidecar-dependent, but the public signals currently support a cautious posture: operator docs should acknowledge the project and its workflows without implying verified Cassandra 6 support.

---

## Sidecar / Analytics Dependency Relationship

This relationship is the main reason to plan the two topics together rather than separately.

Verified evidence:

- the Analytics user documentation says the library uses Apache Cassandra Sidecar to interact with the target cluster
- the documented reader and writer properties begin with Sidecar connectivity and Sidecar security settings
- the example usage and transport model assume Sidecar endpoints are available to the job

Practical documentation consequence:

- Cassandra Operator docs should not present Analytics as an isolated Spark integration
- any future Operator guidance for Analytics should first establish the Sidecar dependency
- Sidecar should be treated as the lower-level integration surface and Analytics as a workload/tooling layer that builds on it

Inference:
For operator readers, the correct mental model is likely:

`Cassandra cluster -> Sidecar operational/API layer -> Analytics bulk data workflows`

---

## Compatibility And Support Caveats

This section should be preserved almost verbatim in any later implementation work.

### Verified statements

- Sidecar is actively developed and explicitly designed around multi-version Cassandra support.
- Sidecar public docs currently show both older requirement statements and newer multi-version testing/design statements.
- Analytics currently documents Sidecar-based read/write workflows and includes 4.0/5.0-era bridge signals.
- The reviewed public Analytics materials do not explicitly prove Cassandra 6 support.

### Required documentation caution

The Cassandra Operator docs should **not**:

- imply that Sidecar is fully documented as part of core Cassandra
- imply that Analytics is a built-in Cassandra operator workflow
- claim Cassandra 6 support for either project without upstream proof
- duplicate detailed Sidecar or Analytics configuration catalogs

### Recommended documentation stance

- present both projects as official Apache Cassandra subprojects that operators may adopt
- describe the verified operator-relevant workflows and prerequisites
- link to the official project docs for version-specific setup and full reference
- explicitly mark any cross-version or Cassandra 6 statements as pending verification when necessary

---

## Recommended Documentation Boundary

### Boundary Principle

Cassandra Operator docs should function as the **decision and orientation layer**.
The Sidecar and Analytics docs should function as the **execution and reference layer**.

### Boundary Table

| Topic | Cassandra Operator docs should own | Sidecar / Analytics docs should own |
|---|---|---|
| Project framing | What the project is, when operators should care, why it exists | Full product overview and internal architecture |
| Compatibility posture | Verified support caveats, version uncertainty, entry-point guidance | Definitive compatibility matrix and release-specific support statements |
| Adoption decision | When to use it instead of core Cassandra tools, risks, prerequisites | Detailed installation and environment setup |
| Security | High-level impact on TLS, RBAC, credentials, truststores, and network exposure | Exact security configuration fields, auth handlers, certificate formats, and API usage |
| Cluster impact | Snapshot creation, staging directories, CDC requirements, Sidecar endpoint exposure, Spark job implications | Full operational procedure and troubleshooting details |
| API/config reference | Entry-point links to the relevant API or config surface | Full API reference, OpenAPI, config catalogs, request/response details |
| Workflow detail | Which workflow class exists: CDC, lifecycle, restore, bulk read, bulk write | End-to-end commands, manifests, JSON payloads, job arguments, API calls |
| Troubleshooting | When a failure belongs to Cassandra vs the subproject | Detailed subproject-specific diagnostics and remediation |

### Practical consequence

Later operator pages should explain:

- when an operator is leaving core Cassandra-only workflows
- what new prerequisites and risks are introduced
- where the reader should go next for detailed execution

They should not try to replace the official subproject manuals.

---

## Information Architecture Options

These are planning options only. No IA changes are implemented by this document.

### Option A: New `Automate > Integrations` slice

Possible future shape:

- `Automate > Integrations Overview`
- `Automate > Cassandra Sidecar`
- `Automate > Cassandra Analytics`

Pros:

- creates a clear, discoverable home for official operator integrations
- keeps the K8ssandra boundary pattern under the same broad automation/integration area
- lets Sidecar and Analytics be introduced together, with their dependency relationship explained once
- avoids overloading `bulk_loading.adoc` with non-core workflow framing

Cons:

- adds a new slice to an already large Operator nav
- may require extra curation to distinguish “automation” from “operations” topics

### Option B: Fold into existing `Automate` and `Bulk Loading` pages

Possible future shape:

- add a section to `automate/config-as-code.adoc` or `automate/kubernetes-considerations.adoc`
- add Sidecar/Analytics framing into `operate/bulk_loading.adoc`
- add restore-related references into backup/restore pages

Pros:

- fewer new nav entries
- lower documentation footprint
- easier first implementation pass

Cons:

- makes the integration story harder to discover
- risks burying Sidecar under unrelated topics
- risks making Analytics look like only a bulk-loading variation rather than a separate Spark-oriented integration layer
- does not give operators a clean boundary page comparable to the existing K8ssandra boundary treatment

### Recommended Option

**Recommend Option A: a dedicated `Automate > Integrations` slice.**

Reasoning:

- the current gap is primarily discoverability and orientation
- Sidecar and Analytics are broad enough to justify explicit entry points
- the workzone already has a precedent for documenting external/operator-adjacent boundaries under `Automate`
- this structure is better for review because it keeps the boundary-first approach visible and avoids accidental sprawl into unrelated pages

Inference:
If implementation needs to start smaller, Option A can still begin as a single overview page plus cross-links, then expand into separate pages later.

---

## Recommended First-Pass Content Set

This is the smallest content set that would close the gap without duplicating the subproject docs.

### 1. Integrations Overview

Purpose:

- explain why this topic exists in Operator docs
- distinguish core Cassandra workflows from official subproject integrations
- introduce the Sidecar -> Analytics relationship
- set the compatibility and ownership boundary up front

Should include:

- short definitions of Sidecar and Analytics
- “use this when” decision table
- compatibility caveat box
- link-outs to official project docs

### 2. Cassandra Sidecar operator page

Purpose:

- explain when operators should adopt Sidecar
- summarize the Sidecar capabilities that matter to cluster operations
- explain prerequisites and risks before readers go to the Sidecar docs

Should include:

- health/API/OpenAPI surface
- lifecycle APIs
- CDC requirements and implications
- snapshot/restore and staging implications
- TLS/RBAC/mTLS considerations
- documentation boundary and official links

### 3. Cassandra Analytics operator page

Purpose:

- explain when operators should use Analytics rather than core bulk-loading or export/import approaches
- make the Sidecar dependency explicit

Should include:

- bulk reader overview and snapshot behavior
- bulk writer overview
- direct vs `S3_COMPAT` transport
- coordinated multi-cluster write concept
- Spark, Sidecar, and security prerequisites
- documentation boundary and official links

### 4. Minimal cross-links from existing operator pages

Only after the above pages exist, later implementation should add targeted links from:

- `operate/bulk_loading.adoc`
- `backup-recovery/strategy.adoc`
- `automate/kubernetes-considerations.adoc`
- operator landing page

This cross-linking should be intentionally light.
The integration overview pages should remain the main orientation surface.

---

## Open Questions

These are the questions that still need technical or governance confirmation before implementation.

1. What is the official Cassandra 6 support position for Sidecar releases today?
2. What is the official Cassandra 6 support position for Analytics releases today?
3. Is the Cassandra docs project comfortable documenting official subprojects with the same boundary-first model already used for K8ssandra?
4. Should Sidecar restore and lifecycle workflows be presented primarily under `Automate`, `Backup and Recovery`, or both?
5. How much of the Sidecar and Analytics compatibility story should Cassandra docs repeat versus link out?

---

## Risks

### 1. Compatibility overstatement

The biggest risk is implying Cassandra 6 support where the reviewed public materials do not prove it.
This should be treated as a release-accuracy risk, not just an editorial nuance.

### 2. Boundary collapse

If Cassandra docs try to become the main manual for Sidecar or Analytics, the content will drift quickly and create maintenance burden across repos.

### 3. Discoverability without discipline

If the work is folded into existing pages instead of given an explicit entry point, the same omission is likely to persist even after content is added.

### 4. Release cadence mismatch

Sidecar and Analytics have their own release cadence and documentation evolution.
A Cassandra Operator page that copies low-level details will age faster than a boundary-first page that links to official references.

### 5. Mixed operator audiences

Some operators want only core Cassandra workflows.
Others want API-driven, Spark-driven, or automated external workflows.
The docs need to help readers choose without making the Operator section feel fragmented.

---

## Source List

### Local workzone context

- `content/operators/modules/ROOT/nav.adoc`
- `content/operators/modules/ROOT/pages/index.adoc`
- `content/operators/modules/ROOT/pages/automate/kubernetes-considerations.adoc`

### Official Sidecar sources

- Sidecar README: <https://github.com/apache/cassandra-sidecar/blob/trunk/README.md>
- Sidecar OpenAPI notes: <https://github.com/apache/cassandra-sidecar/blob/trunk/OPENAPI.md>
- Sidecar contributor guidance: <https://github.com/apache/cassandra-sidecar/blob/trunk/CONTRIBUTING.md>

### Official Analytics sources

- Analytics user guide: <https://github.com/apache/cassandra-analytics/blob/trunk/docs/src/user.adoc>
- Analytics change log: <https://github.com/apache/cassandra-analytics/blob/trunk/CHANGES.txt>
- Analytics module layout: <https://github.com/apache/cassandra-analytics/blob/trunk/settings.gradle>

---

## Recommendation

Approve a future implementation pass that adds **operator-facing integration guidance for both Sidecar and Analytics**, but keep that implementation strictly bounded:

- orientation and decision support in Cassandra Operator docs
- detailed execution and reference in the subproject docs
- no Cassandra 6 compatibility claims unless upstream sources prove them

That approach closes the current operator-doc omission without creating a second source of truth.
