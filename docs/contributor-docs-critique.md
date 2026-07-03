# Contributor Docs Critique

Capture date: **2026-03-31**

## Purpose

This document critiques the current contributor-focused content and information architecture in the Cassandra 6 docs workzone.

The central question is:

**If a new or returning contributor wants to learn Cassandra internals, build and test changes, implement a feature safely, and navigate review without tribal knowledge, does this documentation give them what they need in 2026?**

This critique is focused on code contributors first:
- people learning the internals
- people fixing bugs
- people implementing new features
- people writing or updating tests
- people reviewing patches

It also considers adjacent contributors such as documentation, tooling, and release contributors where those workflows overlap with code changes.

## Executive Summary

The contributor lane has a good high-level shape, but it is not yet a gold-standard contributor experience.

What is working:
- The top-level sections are sensible: architecture, build/test, patch/review, docs, release/publish, generated docs.
- The contributor landing page is approachable and points new people to a reasonable first path.
- Build and test guidance is meaningfully better than what many legacy OSS projects provide.
- The generated-doc distinction is helpful and important.

What is missing:
- There is not yet a strong "learn the codebase" path.
- The testing guidance is broad, but it is not yet decision-oriented enough for feature work.
- The docs do not yet provide a clear feature-development playbook.
- There is no contributor-facing map of subsystem owners, experts, or review routing.
- The current lane still assumes too much project memory.
- 2026 contributor expectations such as AI-assisted development policy, deterministic dev environments, and performance/regression workflows are underdeveloped.

The short version:

**the contributor IA is reasonable, but the contributor workflow content is still too thin for a large distributed systems codebase**

## What Gold-Standard Contributor Docs Look Like In 2026

For Cassandra, the best comparisons are not generic web framework docs.
They are contributor docs for large, long-lived systems projects with complex internals and heavy quality constraints.

Three especially useful reference models are:
- the Rust compiler dev guide
- LLVM’s developer policy and testing guidance
- the Kubernetes contributor ecosystem

## 1. They help people enter a large codebase without pretending it is small

The Rust compiler dev guide is a strong example.
It assumes the codebase is large and complicated, and responds by giving contributors:
- a walkthrough
- places to ask questions publicly
- pointers to experts
- suggested starting places
- issue classes that do not require full-system expertise

This is important because the correct response to complexity is not "hide complexity."
It is "make the complexity legible."

For Cassandra, that means contributors should be able to answer:
- what are the major subsystems?
- where does code for each subsystem live?
- which changes are local and which are cross-cutting?
- who usually reviews work in each area?

## 2. They provide a fast, deterministic path to a working local environment

Strong contributor docs in 2026 do not stop at a clone command and a build tool name.
They provide:
- a recommended local setup path
- a quick path and a deep path
- guidance for editor integration
- guidance for CI-parity or containerized builds
- warnings about disk, RAM, or time costs

The Rust compiler guide is a useful example because it documents not just commands, but realistic contributor concerns:
- default setup
- selective builds
- avoiding unnecessary rebuilds
- targeted test execution
- when full local testing is not the best use of time

## 3. They teach contributors how to choose the right test, not just how to run all tests

LLVM is very strong here.
Its policy and testing guidance emphasize:
- targeted tests
- the right test harness for the right kind of change
- small in-tree tests for feature and regression coverage
- larger out-of-tree suites for broader integration and performance validation

This is a crucial distinction for Cassandra.

A contributor needs to know not only:
- how to run `ant test`
- how to run dtests

but also:
- which tests matter for storage changes
- which tests matter for CQL grammar changes
- which tests matter for protocol changes
- when upgrade tests are required
- when performance validation is required
- when a black-box distributed test is necessary versus overkill

## 4. They define the feature-development process clearly

In mature OSS systems, "just submit a PR" is not enough for major work.

Good contributor docs explain:
- when a bug fix can go straight to implementation
- when a design discussion is required
- when a proposal process is required
- how compatibility and release impact are evaluated
- what extra validation is expected for major features or breaking changes

LLVM’s RFC-style policy for larger changes is a good example.
Rust’s contribution procedures are another.
Kubernetes goes further by making design and ownership structures visible across SIGs and enhancement processes.

For Cassandra, a contributor implementing a new feature should be able to answer:
- Do I need JIRA only, or broader design discussion?
- Do I need CEP-level discussion?
- What branches should this target?
- What docs, NEWS, protocol, or compatibility artifacts must change?
- What performance or upgrade validation is expected before review?

## 5. They make review routing and expert discovery visible

One of the strongest patterns in modern contributor docs is explicit discoverability:
- maintainers files
- ownership maps
- working groups
- public channels for questions
- review role descriptions

Kubernetes is especially strong at this across SIGs and roles.
Rust is strong at telling contributors where to ask questions and how to find experts.

For a project like Cassandra, this matters a lot.
A contributor who changes gossip, storage, compaction, Accord, guardrails, or native protocol should not have to guess who to involve.

## 6. They include debugging, profiling, and performance workflows

In 2026, a contributor guide for a systems project is incomplete if it only covers build and test.

It also needs to cover:
- debugging techniques
- tracing and profiling
- performance regression tooling
- workload validation
- reproducing failures from CI or field reports

This is especially important for Cassandra because many changes are not meaningfully validated by correctness tests alone.

## 7. They acknowledge AI-assisted contribution without lowering standards

A contributor in 2026 is likely using AI for:
- code exploration
- summarization
- patch scaffolding
- test generation
- documentation drafting

Strong contributor docs should acknowledge this reality and define the rules:
- human accountability stays with the contributor
- claims must still be source-grounded
- generated code still needs tests and review
- reviewers need provenance and enough context to trust the patch

This should be normalized rather than left implicit.

## What The Current Contributor IA Gets Right

## 1. The section structure is sensible

The top-level split into:
- architecture
- build and test
- patches and review
- documentation
- release and publish
- generated docs

is a good starting model.

It matches the main kinds of contributor work without collapsing everything into one giant contribution page.

## 2. The landing page is readable and newcomer-friendly

The contributor landing page does a good job telling someone where to start:
- set up the environment
- learn the workflow

That is the right first move.

## 3. Build and test coverage is materially useful

The current build/test pages already provide better practical value than many legacy Apache project docs.

They cover:
- prerequisites
- cloning
- submodules
- Ant builds
- Docker-based test execution
- major test classes

This is real value.

## 4. The generated-docs page is a strong contributor aid

Generated documentation is a major source of confusion in Cassandra.
Making this a first-class contributor topic is the right decision.

It helps contributors understand:
- which surfaces are authored
- which are generated
- when regeneration is required
- where to make the actual source changes

## 5. The review checklist is useful

The review page includes concrete prompts on:
- testing
- documentation
- error handling
- logging

That is a good foundation for contributor quality culture.

## Where The Current Contributor Docs Fall Short

## 1. There is no real internals learning path yet

This is the single biggest gap.

The contributor lane includes an architecture section, but it does not yet offer a guided path for learning the codebase.

For a project like Cassandra, contributors need more than:
- an architecture overview
- a few topic pages

They need a practical map of the code:
- coordinator and replica path
- storage engine
- commitlog and memtables
- compaction
- messaging
- schema and metadata
- CQL parsing and execution
- accord / transactions
- security
- tools and nodetool
- config and startup lifecycle

Without that, contributors still have to reverse-engineer the code layout from package names and grep.

## 2. The docs do not yet explain how to approach a new feature systematically

The patch workflow is useful, but it is still too generic for large changes.

What is missing is a feature-development playbook:
- how to scope a change
- how to identify affected subsystems
- how to decide whether the change is local, cross-cutting, or release-significant
- when to involve the dev list
- when to involve CEP or design review
- what supporting artifacts must be updated
- how to think about upgrade, compatibility, and performance impact

This is one of the most important gaps for Cassandra 6-era work.

## 3. Testing guidance is broad but not yet decision-oriented enough

The current testing page explains test categories well.
What it does not yet do strongly enough is help contributors choose the minimum correct validation set for a specific change.

A stronger testing model would answer questions like:
- If I change a parser rule, what tests do I need?
- If I change compaction logic, which correctness, dtest, and performance checks matter?
- If I change a nodetool command, do I need generated docs regeneration, unit tests, and dtests?
- If I change TCM or topology behavior, do I need upgrade or failure-path testing?
- If I change protocol-visible behavior, what client and compatibility checks are required?

Contributors need a test selection matrix, not just a list of commands.

## 4. There is no explicit subsystem ownership or expert-discovery guide

This is a major contributor-experience problem.

The docs currently do not provide a first-class answer to:
- who reviews storage engine changes?
- who reviews Accord changes?
- who reviews protocol changes?
- who reviews docs generation scripts?
- who should be asked about test infrastructure?

Large projects increasingly document this on purpose.
Cassandra should too.

## 5. The contributor lane needs a better "good first deep contribution" model

A mature 2026 contributor guide should not just say "here is the workflow."
It should also provide stepped entry points:
- first issue
- first test-only contribution
- first docs-plus-code contribution
- first subsystem deep dive
- first feature with cross-cutting impact

Rust does this well by pointing people toward issue classes that teach the system gradually.

Cassandra should provide a similar progression.

## 6. Debugging and profiling guidance is too thin

For a distributed database, contributor docs should include:
- how to debug unit tests
- how to debug dtests
- how to trace a query path
- how to capture thread dumps
- how to inspect logs during development
- how to profile CPU and allocation behavior
- how to reproduce performance regressions

The current contributor lane gives some build/test help, but not yet enough debugging workflow help.

## 7. Performance and regression workflows are underdocumented

Correctness is not enough for Cassandra.
Contributors need clearer guidance for when and how to think about:
- read/write path regressions
- latency regressions
- memory regressions
- compaction and repair side effects
- benchmark or workload validation

For systems work, this should be a first-class part of the contribution model, not an implicit reviewer expectation.

## 8. The review process needs clearer expectations for new features and risky patches

The review checklist is useful, but the lane could do more to define patch classes.

Examples:
- bug fix
- refactor
- internal cleanup
- user-visible feature
- breaking or potentially disruptive change
- upgrade-sensitive change
- generated-surface change

Each class should imply:
- required tests
- required docs updates
- required review stakeholders
- release-note or NEWS expectations

LLVM is strong here.
It makes the expectations for disruptive or broad changes much more explicit.

## 9. The documentation does not yet acknowledge AI-assisted contribution policy

This is a visible omission for 2026.

The workzone is already thinking hard about AI for docs work, but the contributor lane should also say what applies to code contributions.

At minimum, contributors need guidance such as:
- you are responsible for all generated code you submit
- reviewers may ask for provenance or rationale
- tests are mandatory regardless of how code was produced
- generated patches must not bypass architectural discussion
- public design and review channels remain authoritative

This should be documented, not assumed.

## 10. The contributor lane needs more "operational empathy" for code contributors

One thing a strong Cassandra contributor guide should do is connect code changes to operator and user consequences.

A developer adding a feature should be prompted to ask:
- does this change startup behavior?
- does this affect repair, compaction, or disk usage?
- does this change nodetool or generated docs?
- does this alter upgrade safety?
- does this require operator documentation?
- does this create client-visible behavior changes?

That cross-persona awareness is critical in a database project.

## The Core IA Judgment

The contributor information architecture is **acceptable at the top level**.

The problem is not mostly the section names.
The problem is that the lane still behaves too much like:
- a build page
- a test page
- a workflow page
- and a handful of architecture links

when what contributors actually need is:
- a codebase map
- a feature-development playbook
- a test-selection model
- a review-routing model
- a debugging and performance workflow
- explicit expectations for modern contribution practice

So the central critique is:

**the contributor IA is reasonable, but the contributor content model is not yet deep enough for a large distributed systems project**

## Recommended Contributor Content Model

If this work moves upstream, the contributor lane should intentionally include these page types.

### 1. Learn-The-Codebase Pages

Examples:
- Cassandra internals map
- Query execution path
- Storage engine map
- Metadata and schema path
- Messaging and failure handling
- Accord and transaction internals

Goal:
- make the codebase legible
- reduce grep-only onboarding

### 2. Feature Development Pages

Examples:
- How to develop a new feature in Cassandra
- When to use JIRA, dev list, or CEP
- Compatibility and upgrade checklist
- User-visible change checklist

Goal:
- turn project norms into explicit process

### 3. Testing Decision Pages

Examples:
- Which tests to run for which kind of change
- Upgrade test guidance
- Performance regression guidance
- Generated-doc validation guidance

Goal:
- help contributors choose the right validation set

### 4. Review Routing and Ownership Pages

Examples:
- Who reviews what
- Expert map by subsystem
- Maintainer and committer expectations
- How to ask for help effectively

Goal:
- reduce social ambiguity
- improve review quality and speed

### 5. Debugging and Performance Pages

Examples:
- Debugging Cassandra locally
- Reproducing distributed failures
- Profiling read/write path changes
- Interpreting CI failures

Goal:
- help contributors solve nontrivial systems bugs

### 6. Modern Contribution Policy Pages

Examples:
- AI-assisted contribution policy
- WIP and draft PR guidance
- Branch and backport rules
- Release-note and doc-impact rules

Goal:
- align contributor expectations with 2026 reality

## Priority Gaps To Fix First

If only a few contributor-doc improvements can be made in the next phase, these should come first:

1. Add a "Learn Cassandra Internals" path with a subsystem map and code-location guide.
2. Add a feature-development playbook for new features and risky changes.
3. Add a test selection matrix mapping change types to required test categories.
4. Add a subsystem expert / reviewer discovery guide.
5. Add debugging and performance-regression guidance for contributors.
6. Add explicit AI-assisted contribution rules for code and docs changes.

## Bottom Line

The current contributor lane is a solid scaffold.

But for a project as complex as Cassandra, contributors in 2026 need more than a scaffold.
They need documentation that helps them:
- learn the internals
- choose the right tests
- understand process expectations
- find the right reviewers
- reason about performance and compatibility
- contribute effectively with modern tooling

That is the gap between "contribution information exists" and "the project is truly contributor-friendly."

## Reference Sources

Local workzone sources:
- `content/contributors/modules/ROOT/pages/index.adoc`
- `content/contributors/modules/ROOT/pages/architecture/index.adoc`
- `content/contributors/modules/ROOT/pages/build-test/index.adoc`
- `content/contributors/modules/ROOT/pages/build-test/gettingstarted.adoc`
- `content/contributors/modules/ROOT/pages/build-test/testing.adoc`
- `content/contributors/modules/ROOT/pages/patch-review/index.adoc`
- `content/contributors/modules/ROOT/pages/patch-review/patches.adoc`
- `content/contributors/modules/ROOT/pages/patch-review/how_to_review.adoc`
- `content/contributors/modules/ROOT/pages/documentation/index.adoc`
- `content/contributors/modules/ROOT/pages/generated-docs/index.adoc`
- `content/contributors/modules/ROOT/pages/release-publish/index.adoc`

External reference points:
- Rust compiler dev guide: <https://rustc-dev-guide.rust-lang.org/>
- Rust contribution procedures: <https://rustc-dev-guide.rust-lang.org/contributing.html>
- Rust build and run guide: <https://rustc-dev-guide.rust-lang.org/building/how-to-build-and-run>
- Rust compiletest guide: <https://rustc-dev-guide.rust-lang.org/tests/compiletest.html>
- LLVM developer policy: <https://llvm.org/docs/DeveloperPolicy.html>
- Kubernetes contributor portal: <https://kubernetes.io/docs/contribute/>
- PostgreSQL developer coding portal: <https://www.postgresql.org/developer/coding/>
