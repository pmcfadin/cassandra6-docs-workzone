# Plan Review: Existing Documentation Gap

**Reviewer:** Patrick McFadin
**Date:** 2026-03-27
**Document under review:** `backlog/implementation-tasklist.md`
**Status:** Gap identified — plan amendment recommended before Phase 4 begins

---

## Summary

The implementation plan treats Cassandra 6 documentation as a largely greenfield effort. While it correctly identifies *what* has changed between Cassandra 5.0 and trunk, it does not account for how existing documentation should flow into the drafting process. This creates risk of unnecessary rework, lost context, and inconsistency with the broader doc set.

## The Gap

Phases 4 and 5 define drafting tasks that list research files and trunk source code as inputs, but never reference the existing `.adoc` pages on trunk as a starting point. For example:

- **P4-T4 (JMX and security):** Instructs drafting security documentation, but `security.adoc` already exists on trunk. The delta catalog confirms it *gained* 204 lines and *lost* 90 — this is an update to a living document, not a new page.
- **P4-T3 (snitch/topology):** Instructs drafting snitch documentation, but `snitch.adoc` exists on trunk with significant content. The delta catalog notes 82 lines of cloud snitch content were removed — the page needs targeted surgery, not a rewrite.
- **P5-T2 (CQL syntax):** Multiple CQL pages exist with established structure and examples. New syntax (BETWEEN, NOT, LIKE, CREATE TABLE LIKE) should be additions to those pages, not replacements.
- **P5-T3 (SAI frozen collections):** SAI documentation already has 6+ pages. The update is additive.
- **P5-T4 (compaction):** Compaction docs exist. Two new settings need to be added.

Of the 13 drafting tasks across Phases 4 and 5, roughly 9 are updates to pages that already exist on trunk. Only 4 are genuinely new pages (TCM, guardrails reference, startup checks SPI, Accord CQL reference).

## Risks If Unaddressed

1. **Content loss:** Existing explanations, examples, caveats, and cross-references built up over multiple Cassandra releases could be dropped if drafters start from blank pages.
2. **Unnecessary effort:** Rewriting content that already works wastes authoring and review cycles.
3. **Inconsistent voice:** New pages written in isolation will not match the tone and conventions of surrounding documentation that readers will see in the same site.
4. **Preview disconnect:** The workzone preview site currently renders only the skeleton content in `content/modules/`. Reviewers cannot see how draft pages fit within the full documentation set. Without the surrounding context, it is difficult to judge whether a draft is an adequate update or an incomplete replacement.

## Recommended Amendments

### 1. Add trunk docs as a content source in the Antora playbook

Configure `antora-playbook.yml` to pull in the existing `apache/cassandra` doc tree (from a local clone or git URL) as a second content source alongside the workzone `content/` directory. This gives the preview site the full documentation context. Workzone draft pages override trunk pages at the same path, so reviewers see the complete picture: existing pages plus proposed changes.

### 2. Amend Phase 4-5 task descriptions to distinguish "update" from "new"

Each drafting task should explicitly state whether the deliverable is:

- **New page** — no equivalent exists on trunk; draft from scratch using research as input
- **Updated page** — an equivalent exists on trunk; start from the trunk version, apply research-driven changes

For updated pages, the task's Sources section should include the trunk `.adoc` file as the primary input, with research files providing the delta to apply.

### 3. Consider adding a "baseline import" task before Phase 4

A small task (perhaps P3.5-T1) that copies the current trunk doc pages into the workzone's `content/` structure, preserving paths so Antora's page override mechanism works correctly. This gives drafters a concrete starting point and makes diffs between "before" and "after" reviewable.

## Impact on Timeline

These amendments are low-effort and should not delay Phase 4. Amendment 1 is a playbook configuration change. Amendment 2 is editorial clarification of existing tasks. Amendment 3 is a scripted file copy. All three reduce total effort by avoiding rework downstream.

---

*This review does not address visual design (theming, branding, CSS customization), which is also absent from the plan but is a separate concern.*
