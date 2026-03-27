# Ownership Map

Capture date: **2026-03-24**

## Purpose
Map Cassandra 6 documentation work to reviewer roles so execution can begin without inventing governance per ticket.

This is a role map, not a people map. Replace role labels with named maintainers when the program starts.

## Core Roles
- `Project owner`: program coordination, milestone tracking, dependency decisions
- `Docs lead`: information architecture, writing quality, consistency, navigation, editorial signoff
- `Technical owner`: factual review for product behavior, upgrade semantics, operational guidance, and configuration meaning
- `Generated-doc owner`: provenance, regeneration steps, and integrity of machine-derived surfaces
- `Website/publish owner`: version wiring, alias logic, staged validation, and publish cutover
- `Committer sponsor`: Apache merge authority and final merge accountability

## Required Reviewer Matrix

| Work item | Required roles |
| --- | --- |
| Inventory and disposition | project owner, docs lead |
| Operator guidance | docs lead, technical owner |
| Developer guidance | docs lead, technical owner |
| Contributor guidance | docs lead, committer sponsor |
| Generated config reference | generated-doc owner, technical owner |
| Generated nodetool reference | generated-doc owner, technical owner |
| Generated protocol reference | generated-doc owner, technical owner |
| Version wire-up in `apache/cassandra` | technical owner, committer sponsor |
| Version wire-up in `apache/cassandra-website` | website/publish owner, committer sponsor |
| Stage approval | website/publish owner, committer sponsor |
| AI-assisted drafting review | docs lead, technical owner |

## Recommended Area Ownership

| Area | Primary owner role | Secondary review role |
| --- | --- | --- |
| `Operators` | docs lead | technical owner |
| `Developers` | docs lead | technical owner |
| `Contributors` | docs lead | committer sponsor |
| `Reference` authored pages | docs lead | technical owner |
| `Reference` generated pages | generated-doc owner | technical owner |
| Version selector and aliases | website/publish owner | committer sponsor |
| Build and preview workflow docs | website/publish owner | generated-doc owner |

## Initial JIRA Structure
Use one umbrella issue plus these first child tickets:

1. Program tracking and readiness.
2. Full page inventory and disposition.
3. Generated-doc provenance and regeneration validation.
4. Operator content slices.
5. Developer content slices.
6. Contributor and process pages.
7. Cassandra 6 version wire-up in `apache/cassandra`.
8. Cassandra 6 version wire-up in `apache/cassandra-website`.
9. Staging validation and publish cutover.

## Ticket Template Requirements
Every slice-level ticket should name:
- source branch
- affected pages or page groups
- whether the slice is authored or generated
- primary owner role
- required reviewer roles
- staging impact
- publish blocker status

## Escalation Rules
- Route upgrade, compatibility, security, and operational claims to a technical owner.
- Route any generated content change to the generated-doc owner before editorial review.
- Route any branch, alias, or version selector change to the website/publish owner.
- Route any unresolved governance or review ambiguity to the committer sponsor before merge.

## Minimum Named Ownership Before Drafting
Do not begin broad Cassandra 6 drafting until these roles are filled by named people:
- docs lead
- at least one technical owner for operations and upgrade content
- generated-doc owner
- website/publish owner
- committer sponsor
