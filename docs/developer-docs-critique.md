# Developer Docs Critique

Capture date: **2026-03-31**

## Purpose

This document critiques the current developer-focused content and information architecture in the Cassandra 6 docs workzone.

The goal is not to review every individual page. The goal is to answer a narrower question:

**If an application developer arrives here, can they quickly find what they need, succeed with Cassandra, and make sound design decisions?**

## Executive Summary

The current developer information architecture is directionally correct but not yet gold-standard.

What is working:
- Developers have a clear front door.
- The top-level path is understandable: quickstart, data modeling, CQL, drivers, vector search, application patterns, troubleshooting.
- The workzone already does a better job than the current source-bucket layout at centering the application developer persona.
- Cassandra-6-specific topics such as Accord transactions, constraints, and vector search are surfaced early.

What is not yet working:
- The developer experience is still too reference-heavy.
- The quickstart is not stack-specific.
- Drivers are treated as a list of links instead of a first-class part of the developer journey.
- There are not enough task-oriented guides between "quickstart" and "raw CQL reference."
- Production application concerns are underrepresented.

The current state is best described as:

**a good developer-facing shell with incomplete developer workflow content inside it**

## What Gold-Standard OSS Developer Docs Usually Do

There is no single perfect comparison project, but strong open source developer docs tend to share the same traits.

### 1. They provide a fast path to first success

Gold-standard developer docs get a user from zero to a working app quickly.

Examples:
- Astro gives developers a clear getting-started flow, then separates guides from reference.
- React Native gives a recommended default setup path before offering alternatives.
- Supabase organizes getting-started material around real developer stacks and frameworks.

Implication for Cassandra:
- A developer should be able to choose a language or stack early.
- "Run Cassandra in Docker and open cqlsh" is useful, but it is not the same as "build your first app."

### 2. They separate concepts, tasks, tutorials, and reference

Projects such as Kubernetes and MDN make sharp distinctions between:
- concepts
- tutorials
- tasks / how-to guides
- reference

This matters because developers do not always need the same kind of help:
- Sometimes they need a mental model.
- Sometimes they need a recipe.
- Sometimes they need syntax.

Implication for Cassandra:
- Data modeling and architectural tradeoffs belong in concept/guidance pages.
- Pages like "How do I paginate results?" or "How do I model time-series data?" belong in task/cookbook pages.
- Raw CQL syntax belongs in reference.

### 3. They treat integrations as first-class documentation

Strong developer docs do not stop at "here are some client libraries."

They typically provide:
- recommended entry points by language
- support expectations
- compatibility guidance
- example code
- links to deeper driver-specific docs

Implication for Cassandra:
- A driver page should not just be a directory of repositories.
- It should help a developer decide what to use and what to read next.

### 4. They help developers make design decisions, not just learn syntax

The best developer docs do not only teach API shape.
They teach when to use a feature, when not to use it, and what tradeoffs it creates.

For Cassandra, this includes decisions such as:
- when to denormalize
- when to use SAI
- when to use Accord transactions
- when to avoid `ALLOW FILTERING`
- how to choose consistency levels
- how to avoid hot partitions and tombstone-heavy workloads

### 5. They include production-minded application guidance

Gold-standard developer docs include the application-side realities that cause incidents in production:
- retries
- idempotence
- pagination
- timeouts
- driver tuning
- backpressure
- schema migration discipline
- observability from the client side

This kind of material is often more useful to real developers than another syntax page.

## What The Current Developer IA Gets Right

## 1. The persona framing is much better than the current Cassandra docs model

The current developer landing page clearly addresses application developers and tells them what lives in this section:
- data modeling
- CQL
- drivers
- vector search
- application patterns
- troubleshooting

This is the right framing.

It is a substantial improvement over making developers infer their path from top-level buckets such as:
- `developing`
- `integrating`
- `vector-search`
- `reference`

## 2. The recommended reading path is sensible

The current sequence:
1. quickstart
2. data modeling
3. CQL
4. drivers
5. vector search
6. troubleshooting

is coherent and reflects a real developer journey.

## 3. The data modeling page is one of the strongest parts of the lane

The data modeling landing page does real work.
It explains query-driven design, highlights Cassandra-6-specific modeling consequences, and points into upstream modeling material in a useful order.

This is closer to what good developer docs should do:
- explain how Cassandra thinking differs from relational thinking
- explain what Cassandra 6 changes in practice
- connect mental model to implementation guidance

## 4. Vector search is treated as a proper developer feature area

The vector search section is not buried as a novelty.
It is placed where application developers can find it, and it includes practical use cases such as:
- RAG
- semantic search
- recommendations

That is the right call for a modern developer persona.

## 5. Troubleshooting exists as a first-class developer concern

This is important.
Developer docs should not force application teams to jump straight into operator docs every time they hit an issue.

The current troubleshooting page is still thin, but its existence in the developer lane is structurally correct.

## What Is Missing Compared With Gold Standard

## 1. No language-specific or framework-specific onboarding

The biggest gap is that Cassandra still does not really take a developer from "I use language X" to "I have a working application."

The current quickstart:
- starts Cassandra in Docker
- opens `cqlsh`
- runs raw CQL
- points to a generic driver list

That is a product quickstart.
It is not yet an application developer quickstart.

What is missing:
- Java quickstart
- Python quickstart
- Go quickstart
- Node.js quickstart
- a clear recommended first driver per ecosystem
- minimal end-to-end code samples

## 2. The driver page is not doing enough

Right now the driver page is mostly a repository index.

That is not enough for a developer persona.

It should answer questions like:
- Which drivers are official or community-maintained?
- Which drivers are actively maintained?
- Which drivers support Cassandra 6 features well?
- Where should a new developer start?
- Which drivers support transactions, paging, tracing, retries, async APIs, and prepared statements?

Without this, developers still have to do too much outside the docs.

## 3. Not enough task-oriented guides

The current lane has concepts and reference, but there is a missing middle layer:

- How to model a time-series workload
- How to design for high write throughput
- How to pick consistency levels for common app patterns
- How to paginate safely
- How to use SAI without papering over bad data models
- How to adopt Accord transactions without overusing them
- How to handle schema changes in an application release
- How to debug latency from the app side

This is the largest content gap after driver onboarding.

## 4. Too much dependence on upstream reference pages

Some current pages work mainly as bridges into upstream Cassandra docs.
That is reasonable in a workzone, but it weakens the developer journey when overused.

The risk is that the developer lane becomes:
- a nicer menu
- with the same old reference-heavy experience underneath

The workzone should not only re-route developers to existing pages.
It should add the guidance layer that those pages do not currently provide.

## 5. The lane does not yet distinguish beginner, intermediate, and advanced developer needs

Different developer audiences are being handled as though they are one persona:
- a new app developer evaluating Cassandra
- an experienced Cassandra user upgrading to 6.0
- a staff engineer designing query models at scale
- an AI/search engineer exploring vector features

These users do not need the same content in the same order.

The lane needs clearer sub-journeys.

## 6. Production application guidance is still thin

A strong developer docs lane for Cassandra should include application-facing guidance on:
- retries and idempotence
- consistency tradeoffs
- paging and query limits
- driver timeout behavior
- prepared statements
- backpressure and concurrency patterns
- hot partition avoidance
- tombstone-sensitive query design
- rollout and migration concerns

Today, this material is either absent, lightly implied, or pushed into external driver docs.

## 7. "What changed for developers in Cassandra 6" needs to be deeper

The developer landing page does a good job surfacing major features.
But developers upgrading existing applications need a more deliberate upgrade-oriented path.

That path should answer:
- What new capabilities change application design?
- What new syntax or behavior should we adopt?
- What old habits are now suboptimal?
- What requires driver verification?
- What should we test before rolling out?

At present, these answers are distributed across multiple pages instead of being turned into a compact upgrade guide.

## 8. Some important application semantics remain insufficiently documented

There are still places where developer-facing behavior needs more confidence before publication.

A good example is transaction and driver interaction semantics.
If prepared statements, driver APIs, or operational preconditions are not documented clearly, developers will discover those details experimentally, which is exactly what good docs should prevent.

## The Core IA Judgment

The current developer information architecture is **good enough as a top-level structure**.
It is not the main problem.

The main problem is that the content inside the structure is still missing a mature developer-experience layer.

In practical terms:
- The IA already helps developers orient themselves.
- The content does not yet consistently help them build, decide, and operate application integrations with confidence.

So the right critique is not:

**"The developer IA is wrong."**

It is:

**"The developer IA is right, but the page types inside it are still too biased toward bridge pages and reference pages."**

## Recommended Content Model For The Developer Lane

If this work moves upstream, the developer lane should intentionally include four page types.

### 1. Start Pages

Examples:
- Developer Quickstart
- Choose a Driver
- Upgrading an Application to Cassandra 6

Goal:
- get to first success
- choose a path
- understand what changed

### 2. Concept Pages

Examples:
- Query-Driven Data Modeling
- Consistency for Application Architects
- When to Use Accord Transactions
- When to Use SAI

Goal:
- explain the mental model
- prevent bad design decisions

### 3. Task / Cookbook Pages

Examples:
- Build a Java app with Cassandra
- Build a Python app with Cassandra
- Paginate results safely
- Model a time-series table
- Add vector search to an application
- Debug request timeouts

Goal:
- solve real developer jobs
- reduce guesswork

### 4. Reference Pages

Examples:
- CQL syntax
- data types
- functions
- command reference

Goal:
- support the other pages
- not replace them

## Priority Gaps To Fix First

If only a few developer-doc improvements can be made in the next phase, these should come first:

1. Replace the current driver-list page with a proper "Choose a Driver" page.
2. Add 2-4 language-specific quickstarts with minimal working application code.
3. Add task-oriented pages for:
   - consistency choices
   - time-series modeling
   - pagination
   - retries and idempotence
   - SAI usage patterns
4. Add a short "Upgrading Application Teams to Cassandra 6" guide.
5. Tighten developer-facing documentation for transaction semantics and driver behavior.

## Bottom Line

For developers, this workzone is already a better front door than the current Cassandra docs.

But it is not yet a gold-standard developer documentation experience.

The missing ingredient is not primarily navigation.
The missing ingredient is a stronger application-developer guidance layer:
- stack-aware onboarding
- task-oriented guides
- driver decision support
- production application advice
- upgrade-specific guidance

That is the gap between a reorganized docs site and a truly excellent developer lane.

## Reference Sources

Local workzone sources:
- `content/developers/modules/ROOT/pages/index.adoc`
- `content/developers/modules/ROOT/pages/quickstart.adoc`
- `content/developers/modules/ROOT/pages/drivers.adoc`
- `content/developers/modules/ROOT/pages/data-modeling/index.adoc`
- `content/developers/modules/ROOT/pages/integration-patterns.adoc`
- `content/developers/modules/ROOT/pages/troubleshooting.adoc`
- `content/developers/modules/ROOT/pages/vector-search/index.adoc`

External OSS reference points:
- Astro Docs: <https://docs.astro.build/en/getting-started/>
- React Native Docs: <https://reactnative.dev/docs/environment-setup>
- Kubernetes Docs: <https://kubernetes.io/docs/home/>
- MDN Learn Web Development: <https://developer.mozilla.org/en-US/docs/Learn_web_development>
- Supabase Getting Started: <https://supabase.com/docs/guides/getting-started>
- Qdrant Documentation: <https://qdrant.tech/documentation/>
