# Apache Cassandra Docs PR Triage
**Triaged:** 2026-04-10  
**Updated:** 2026-04-10 (post-close sweep)  
**Source:** https://github.com/apache/cassandra/pulls?q=is%3Aopen+is%3Apr+label%3Adocs  
**Total PRs (original):** 27 → **8 open** after merges and closures  

---

## Summary (current)

| Status | Count | Action |
|--------|-------|--------|
| MERGED | 11 | #4673, #2825, #4686, #4444, #4588, #4718, #4719, #4409, #3569, #3614, #4689 |
| CLOSED (stale) | 12 | #211, #315, #316, #317, #420, #456, #1125, #2262, #3570, #3911, #1073, #4084, #4529 |
| NEEDS-WORK | 4 | #2828, #3091, #4333, #4670 |
| POLICY DECISION | 1 | #4388 — Scylla driver listing, PMC call |
| NEEDS-WORK | 8 | Author or committer must resolve blocker first |
| CLOSE-STALE (remaining) | 1 | #317 — still open, still safe to close |

---

## Review Verdicts — NEEDS-REVIEW PRs

Full technical reviews conducted 2026-04-10. Each PR checked for: JIRA compliance, attribution line, AsciiDoc correctness, content accuracy against trunk source, branch targeting.

### Quick Reference

| PR | Title | Verdict | Severity |
|----|-------|---------|----------|
| [#4719](https://github.com/apache/cassandra/pull/4719) | CASSANDRA-21291 compaction overview (5.0) | REQUEST CHANGES | Minor |
| [#4718](https://github.com/apache/cassandra/pull/4718) | CASSANDRA-21291 compaction overview (trunk) | REQUEST CHANGES | Minor |
| [#4689](https://github.com/apache/cassandra/pull/4689) | CASSANDRA-13342 native protocol v5 failure codes | REQUEST CHANGES | Minor |
| [#4686](https://github.com/apache/cassandra/pull/4686) | Update link to Apache Archives | APPROVE (conditional) | — |
| [#4588](https://github.com/apache/cassandra/pull/4588) | Fix typo in SAI index documentation | REQUEST CHANGES | Moderate |
| [#4444](https://github.com/apache/cassandra/pull/4444) | Correct typo in CASSANDRA-14092.txt | REQUEST CHANGES | Light |
| [#4409](https://github.com/apache/cassandra/pull/4409) | Storage Engine Markdown Render Misformat Fix | REQUEST CHANGES | **Blocking** |
| [#3614](https://github.com/apache/cassandra/pull/3614) | CASSANDRA-18868 GRANT permissions documentation | REQUEST CHANGES | **Blocking** |
| [#3569](https://github.com/apache/cassandra/pull/3569) | Update data-modeling_schema.adoc (CASSANDRA-20584) | REQUEST CHANGES | Moderate |

---

### PR #4718 — CASSANDRA-21291: Compaction overview (trunk)

**Verdict: REQUEST CHANGES (minor)**

**Content:** All fixes verified correct.
- Duplicate `== Fully expired SSTables` section removal: justified — tombstones.adoc is already included via `include::tombstones.adoc[leveloffset=+1]`
- Property name fix `only_purge_repaired_tombstone` → `only_purge_repaired_tombstones`: **verified correct** against `AbstractCompactionStrategy.java` in trunk (line 83 defines the constant with plural)
- RST-style link `<detailed-compaction-logging>` → AsciiDoc `<<detailed-compaction-logging, below>>`: correct
- `<nodetool>` RST role suffix removal: correct (lost cross-reference intent — see suggestion below)
- Grammar fixes ("will will", "and and", "be able to be dropped how much"): all correct
- Punctuation in tombstones.adoc (`:` → `:`, `node.:` → `node:`): all correct

**Issues requiring author action:**
1. **Attribution line incomplete:** `patch by Arvind Kandpal; for CASSANDRA-21291` is missing "reviewed by \<name\>". Must be filled before merge.
2. **Heading level change needs explicit acknowledgment:** The removed `== Fully expired SSTables` rendered at level 2; the included version (via leveloffset=+1) renders at level 3. Ask the author to confirm this is intentional.
3. **Nodetool reference:** `` `nodetool` `` lost its cross-reference intent — suggest converting to an AsciiDoc xref to the nodetool reference page (non-blocking suggestion).
4. **Noisy diff:** Many trailing-whitespace-only line changes. Not a blocker but makes review harder.

**Suggested GitHub comment:**
> The property name fix and RST→AsciiDoc link corrections are correct and needed.
> 1. The attribution line needs "reviewed by \<name\>" before merge.
> 2. The removed `== Fully expired SSTables` rendered at level 2; the included version (via leveloffset=+1) renders at level 3. Please confirm this heading level change is intentional.
> 3. Minor: `` `nodetool` `` could be an xref to the nodetool reference page to restore the cross-reference intent.

---

### PR #4719 — CASSANDRA-21291: Compaction overview (cassandra-5.0 backport)

**Verdict: REQUEST CHANGES (minor) — same issues as #4718**

**Consistency with trunk:** Substantively identical fixes applied correctly. One difference: the tombstones.adoc portion of #4719 omits several trailing-whitespace-only line cleanups that appear in #4718. Not harmful but inconsistent.

**Merge order recommendation:** Merge #4718 (trunk) first, then #4719. Both should resolve the attribution line and heading level questions simultaneously.

**Suggested GitHub comment:**
> Same notes as #4718. Additionally: the tombstones.adoc changes in this backport omit the trailing-whitespace-only line fixes present in the trunk PR — consider syncing for consistency. Please fill in "reviewed by" before merge.

---

### PR #4689 — CASSANDRA-13342: Native protocol v5 failure reason codes

**Verdict: REQUEST CHANGES (minor)**

**Content accuracy — all 13 codes verified against `RequestFailureReason.java` in trunk:**

| Hex | Name | Code Match | Description Accurate |
|-----|------|------------|---------------------|
| 0x0000 | UNKNOWN | ✓ | ✓ |
| 0x0001 | READ_TOO_MANY_TOMBSTONES | ✓ | ✓ (`tombstone_failure_threshold` = 100000 verified) |
| 0x0002 | TIMEOUT | ✓ | Mostly ✓ (see issue 1) |
| 0x0003 | INCOMPATIBLE_SCHEMA | ✓ | ✓ |
| 0x0004 | READ_SIZE | ✓ | ✓ (`local_read_size_fail_threshold` verified) |
| 0x0005 | NODE_DOWN | ✓ | ✓ |
| 0x0006 | INDEX_NOT_AVAILABLE | ✓ | ✓ |
| 0x0007 | READ_TOO_MANY_INDEXES | ✓ | ✓ (`sai_sstable_indexes_per_query_fail_threshold` verified) |
| 0x0008 | NOT_CMS | ✓ | ✓ |
| 0x0009 | INVALID_ROUTING | ✓ | ✓ |
| 0x000A | COORDINATOR_BEHIND | ✓ | ✓ |
| 0x000B | RETRY_ON_DIFFERENT_TRANSACTION_SYSTEM | ✓ | Needs revision (see issue 2) |
| 0x01F7 | INDEX_BUILD_IN_PROGRESS | ✓ | ✓ (503 decimal = 0x01F7 correct; non-sequential offset intentional per source) |

No missing codes. No extra codes. All hex values correct.

**Issues:**
1. **0x000B description inaccurate:** PR says "Accord or Paxos" framing — source javadoc (`RetryOnDifferentSystemException`) is "non-transactional operation attempted when it needs to be done transactionally (or vice versa)." The PR's framing is too narrow and may mislead client implementers. Revise to match source javadoc.
2. **Pre-existing spec error — opportunity to fix:** The existing spec says `<failure_code> is a [short]` (2-byte fixed). The actual serializer uses `writeUnsignedVInt32` (variable-length). This predates the PR but is worth correcting here since it's a doc-only change.
3. **Attribution "reviewed by TBD":** Must be filled before merge.

**Suggested GitHub comment:**
> Complete coverage of all 13 failure codes — hex values, including the non-sequential 0x01F7, are all verified correct against trunk source.
>
> Two items before merge:
> 1. **0x000B**: The source `RetryOnDifferentSystemException` javadoc describes this as thrown "when a non-transactional operation is attempted when the operation needs to be done transactionally (or vice versa)" — the Accord/Paxos framing in the PR is too narrow. Please align with the source javadoc.
> 2. **Pre-existing spec error worth fixing here:** `<failure_code> is a [short]` should be `[unsigned vint]` — the serializer uses `writeUnsignedVInt32`, not a fixed 2-byte short. Since this is a doc-only PR, this is a good opportunity to correct it.

---

### PR #4686 — [CHORE] Update link to Apache Archives

**Verdict: APPROVE (conditional on JIRA/CHORE exemption decision)**

**Content:** Change is `http://` → `https://` for `archive.apache.org/dist/cassandra/`. Correct — ASF supports HTTPS, this is an unambiguous security improvement. AsciiDoc link macro syntax is unchanged and valid.

**Issues (process only):**
- No JIRA ticket referenced (expected for docs contribution)
- No attribution line in PR body (same)
- Committer must decide whether `[CHORE]` convention waives the JIRA requirement

**Suggested GitHub comment:**
> The HTTPS upgrade is correct and the AsciiDoc syntax is fine. Before merging, please clarify whether this qualifies for the CHORE JIRA exemption. If not, a CASSANDRA-XXXXX ticket is needed and the PR body should include `patch by; reviewed by` attribution per commit message format.

---

### PR #4588 — Fix typo in SAI index documentation

**Verdict: REQUEST CHANGES**

**Content:** Fix is correct. Line reads "All column date types except the following are supported for SAI indexes" — "date" is unambiguously a typo for "data." Surrounding context (column data type list) confirms.

**Critical gap:** The identical typo exists on `trunk` at the same file/line. This PR only targets `cassandra-5.0`. A companion PR against trunk is required.

**Issues:**
1. No JIRA ticket filed
2. No attribution line
3. Same typo on trunk — trunk companion PR required

**Suggested GitHub comment:**
> The fix is correct — "data types" is unambiguously right here. Three items to address: (1) Open a CASSANDRA Jira ticket and reference it in the PR body. (2) The identical typo exists on `trunk` at the same path/line — please open a companion PR against trunk. (3) Add `patch by <name>; reviewed by <name> for CASSANDRA-XXXXX` to the PR body.

---

### PR #4444 — Correct typo in CASSANDRA-14092.txt

**Verdict: REQUEST CHANGES (light — process gaps only, content is fine)**

**Content:** Two corrections verified correct:
- `"5.0 is ran in compatibility mode"` → `"5.0 is run in compatibility mode"` — correct past participle
- `"the limit stays at at 2038-01-19"` → `"the limit stays at 2038-01-19"` — removes doubled preposition

**Issues (process only):**
1. No JIRA ticket referenced (file name `CASSANDRA-14092.txt` is not a PR ticket)
2. No attribution line
3. PR title says "typo" (singular) but fixes two — minor inconsistency

**Suggested GitHub comment:**
> Both fixes are correct: "is run" is the proper past-participle form and "at at" is a clear duplicate-word error. Before merging: (1) Add a CASSANDRA Jira ticket reference, (2) Add `patch by <name>; reviewed by <name> for CASSANDRA-XXXXX`, (3) Minor: consider updating the title to "Correct two typos in CASSANDRA-14092.txt." If committers decide this qualifies as a CHORE with no Jira, note that explicitly in the PR.

---

### PR #4409 — CASSANDRA-20951: Storage Engine Markdown Render Misformat Fix

**Verdict: REQUEST CHANGES (blocking — fix is technically incorrect)**

**Content:** The intent is correct — URLs containing `/_/` can trigger italic formatting in some AsciiDoc rendering contexts. However, the approach is wrong.

**Critical issue:** The fix adds `\_` (backslash-escaped underscore) *inside* a URL macro (`https://...[]`). In Asciidoctor, the URL portion of an inline macro is passthrough — adding `\_` inside it does not prevent formatting; instead the backslash appears as a literal character in the rendered `href`, changing `/_/` to `/\_/` and **breaking the hyperlink target**.

**Correct approaches:**
- Use a site attribute: `:asfsite: https://cassandra.apache.org` then `{asfsite}/_/glossary.html#commit-log[commit log]`
- Use a passthrough: `pass:c[https://cassandra.apache.org/_/glossary.html#commit-log[commit log\]]`

**Other issues:**
- "reviewed by TBD" placeholder must be filled
- PR title says "Markdown" but file is AsciiDoc

**Suggested GitHub comment:**
> The rendering issue is real, but `\_` inside an Asciidoctor URL macro is not the correct fix — the backslash is literal inside the URL portion and will appear in the rendered `href`, breaking the link (`/_/` becomes `/\_/`). The recommended fix is to use a site attribute:
> ```
> :asfsite: https://cassandra.apache.org
> {asfsite}/_/glossary.html#commit-log[commit log]
> ```
> Could you also confirm with a live Antora preview that the link still resolves correctly after your fix? The screenshot shows improved text rendering but doesn't verify the href target.

---

### PR #3614 — CASSANDRA-18868: GRANT permissions for all tables

**Verdict: REQUEST CHANGES (two blocking issues)**

**Content:** The `GRANT ... ON ALL TABLES IN KEYSPACE` syntax is real and verified in trunk (`Parser.g`: `K_ALL K_TABLES K_IN K_KEYSPACE`). The documentation gap is genuine. However there are two blockers and several accuracy/style issues.

**Blocking issues:**
1. **Antora build failure:** Include directives use `include::example$BNF/...[]` (missing component prefix). All existing includes in the same file use `include::cassandra:example$BNF/...[]` with the `cassandra:` component qualifier. Without it, Antora will fail to resolve the includes silently or noisily.
2. **`user_name` → `role_name`:** All 4 new files (1 BNF + 3 CQL) use `user_name` as the grantee. Cassandra's GRANT targets *roles*, not users. The existing BNF (`grant_permission_statement.bnf`) uses `role_name`. Must be changed throughout.

**Accuracy issues:**
3. Intro prose says "all tables and **user types** in a keyspace" — `ALL TABLES IN KEYSPACE` covers tables only; UDTs use a separate resource type. Remove "and user types."
4. Only 3 of 8 applicable permissions shown in examples (SELECT, CREATE, AUTHORIZE, UNMASK, SELECT_MASKED not shown). At minimum, SELECT should be covered.

**Style issues:**
5. `[source,bnf]` should be `[source, bnf]` (with space) to match existing file convention
6. Missing trailing periods on three prose sentences
7. Trailing whitespace on one line
8. Missing newline at end of all three `.cql` files

**CQL permissions accuracy:** The 8 permissions listed in the BNF (`CREATE | ALTER | DROP | SELECT | MODIFY | AUTHORIZE | UNMASK | SELECT_MASKED`) match `DataResource.ALL_TABLES_LEVEL_PERMISSIONS` exactly. ✓

**Suggested GitHub comment:**
> The `GRANT ... ON ALL TABLES IN KEYSPACE` syntax is real and this is a genuine documentation gap — thanks for tackling it.
>
> Two blocking issues before merge:
> 1. **Include paths are missing the component prefix.** Change `include::example$BNF/...[]` to `include::cassandra:example$BNF/...[]` (and same for CQL). The existing includes directly above use the `cassandra:` qualifier — without it, Antora build will fail.
> 2. **Use `role_name`, not `user_name`.** GRANT targets roles in Cassandra. The existing `grant_permission_statement.bnf` uses `role_name` — please update the new BNF and all three CQL snippet files.
>
> Accuracy: "all tables and user types" — `ALL TABLES IN KEYSPACE` covers tables only, not UDTs. Please remove "and user types."
>
> Style: `[source, bnf]` (space after comma), add trailing periods to description sentences, add trailing newline to `.cql` files.

---

### PR #3569 — Update data-modeling_schema.adoc (CASSANDRA-20584)

**Verdict: REQUEST CHANGES (moderate — process gaps, content correct)**

**Content:** Fix is correct and important. The CREATE TABLE example has `WITH comment = Q3. Find pois near a hotel';` — the opening single quote is missing, making it invalid CQL that would cause a parse error if executed. Fix adds the missing `'`. `WITH comment = '...'` is verified valid CQL syntax. All 5 other tables in the block already use this form correctly.

**Issues:**
1. **JIRA not in PR title or body:** CASSANDRA-20584 was created by a third party in a comment. The PR title must include it (e.g., `CASSANDRA-20584 - Fix missing quote in CQL example in data-modeling_schema.adoc`) and body must link it.
2. **No attribution line:** `patch by Amritpal Singh; reviewed by TBD for CASSANDRA-20584` must be added.
3. **PR title is non-descriptive:** "Update data-modeling_schema.adoc" tells reviewers nothing.
4. **Boilerplate template text** still in PR body — should be removed.

**Suggested GitHub comment:**
> The fix is correct — the missing opening `'` in `WITH comment = Q3...` would cause a CQL parse error. Good catch, and `WITH comment = '...'` is the correct table property syntax.
>
> Before this can merge: (1) Update PR title to reference CASSANDRA-20584, (2) Add `patch by Amritpal Singh; reviewed by TBD for CASSANDRA-20584` to the PR body and link to the JIRA, (3) Remove the boilerplate template text from the body. Once these process items are addressed, this is a straightforward APPROVE.

---

## JIRA Cross-Reference

All 27 PRs mapped to their corresponding JIRA tickets. Many stale/no-JIRA PRs were opened without following the contribution process.

| PR | Status | JIRA | Notes |
|----|--------|------|-------|
| [#4719](https://github.com/apache/cassandra/pull/4719) | NEEDS-REVIEW | [CASSANDRA-21291](https://issues.apache.org/jira/browse/CASSANDRA-21291) | 5.0 backport of #4718 |
| [#4718](https://github.com/apache/cassandra/pull/4718) | NEEDS-REVIEW | [CASSANDRA-21291](https://issues.apache.org/jira/browse/CASSANDRA-21291) | trunk |
| [#4689](https://github.com/apache/cassandra/pull/4689) | NEEDS-REVIEW | [CASSANDRA-13342](https://issues.apache.org/jira/browse/CASSANDRA-13342) | |
| [#4686](https://github.com/apache/cassandra/pull/4686) | NEEDS-REVIEW | **None** | [CHORE] tag, no JIRA filed |
| [#4673](https://github.com/apache/cassandra/pull/4673) | MERGE-READY | [CASSANDRA-21218](https://issues.apache.org/jira/browse/CASSANDRA-21218) | Resolve JIRA on merge |
| [#4670](https://github.com/apache/cassandra/pull/4670) | NEEDS-WORK | [CASSANDRA-20901](https://issues.apache.org/jira/browse/CASSANDRA-20901) | Merge conflict blocks |
| [#4588](https://github.com/apache/cassandra/pull/4588) | NEEDS-REVIEW | **None** | No JIRA filed |
| [#4444](https://github.com/apache/cassandra/pull/4444) | NEEDS-REVIEW | **None** | File name contains CASSANDRA-14092, but no PR-specific JIRA |
| [#4409](https://github.com/apache/cassandra/pull/4409) | NEEDS-REVIEW | [CASSANDRA-20951](https://issues.apache.org/jira/browse/CASSANDRA-20951) | |
| [#4388](https://github.com/apache/cassandra/pull/4388) | NEEDS-WORK | **None** | No JIRA; policy decision required |
| [#4333](https://github.com/apache/cassandra/pull/4333) | NEEDS-WORK | **None** | No JIRA filed |
| [#4084](https://github.com/apache/cassandra/pull/4084) | NEEDS-WORK | **None** | Committer requested JIRA; author never created it |
| [#3911](https://github.com/apache/cassandra/pull/3911) | CLOSE-STALE | **None** | Committer requested JIRA; author never created it |
| [#3614](https://github.com/apache/cassandra/pull/3614) | NEEDS-REVIEW | [CASSANDRA-18868](https://issues.apache.org/jira/browse/CASSANDRA-18868) | |
| [#3570](https://github.com/apache/cassandra/pull/3570) | NEEDS-WORK | **None** | No JIRA; companion to #3569 |
| [#3569](https://github.com/apache/cassandra/pull/3569) | NEEDS-REVIEW | [CASSANDRA-20584](https://issues.apache.org/jira/browse/CASSANDRA-20584) | Added via comment after committer request |
| [#3091](https://github.com/apache/cassandra/pull/3091) | NEEDS-WORK | [CASSANDRA-18236](https://issues.apache.org/jira/browse/CASSANDRA-18236) | CEP-19 trie memtable |
| [#2828](https://github.com/apache/cassandra/pull/2828) | NEEDS-WORK | **None** | Body says "Ticket" but no JIRA number was ever filed |
| [#2825](https://github.com/apache/cassandra/pull/2825) | NEEDS-WORK | **None** | No JIRA filed |
| [#2262](https://github.com/apache/cassandra/pull/2262) | CLOSE-STALE | **None** | No JIRA; 3 years stale |
| [#1125](https://github.com/apache/cassandra/pull/1125) | CLOSE-STALE | **None** | No JIRA; RST superseded |
| [#1073](https://github.com/apache/cassandra/pull/1073) | CLOSE-STALE | **None** (see [CASSANDRA-20579](https://issues.apache.org/jira/browse/CASSANDRA-20579)) | Close referencing CASSANDRA-20579 for the AsciiDoc fix |
| [#456](https://github.com/apache/cassandra/pull/456) | CLOSE-STALE | **None** | No JIRA; RST era |
| [#420](https://github.com/apache/cassandra/pull/420) | CLOSE-STALE | **None** | No JIRA; RST era |
| [#317](https://github.com/apache/cassandra/pull/317) | CLOSE-STALE | [CASSANDRA-15101](https://issues.apache.org/jira/browse/CASSANDRA-15101) | Close PR; check if JIRA is still open |
| [#316](https://github.com/apache/cassandra/pull/316) | CLOSE-STALE | [CASSANDRA-13451](https://issues.apache.org/jira/browse/CASSANDRA-13451) | Close PR; check if JIRA is still open |
| [#315](https://github.com/apache/cassandra/pull/315) | CLOSE-STALE | [CASSANDRA-15103](https://issues.apache.org/jira/browse/CASSANDRA-15103) | Close PR; check if JIRA is still open |
| [#211](https://github.com/apache/cassandra/pull/211) | CLOSE-STALE | **None** | No JIRA; RST era; 8 years old |

### JIRAs — status

| JIRA | PR(s) | Status |
|------|-------|--------|
| [CASSANDRA-21291](https://issues.apache.org/jira/browse/CASSANDRA-21291) | #4718, #4719 | **CLOSED 2026-04-10** |
| [CASSANDRA-21218](https://issues.apache.org/jira/browse/CASSANDRA-21218) | #4673 | Resolve JIRA on merge — check if done |
| [CASSANDRA-13342](https://issues.apache.org/jira/browse/CASSANDRA-13342) | #4689 | **CLOSED 2026-04-10** |
| [CASSANDRA-20901](https://issues.apache.org/jira/browse/CASSANDRA-20901) | #4670 | Open — ping author to fix 2 bad replacements and rebase |
| [CASSANDRA-20951](https://issues.apache.org/jira/browse/CASSANDRA-20951) | #4409 | **CLOSED 2026-04-10** |
| [CASSANDRA-18868](https://issues.apache.org/jira/browse/CASSANDRA-18868) | #3614 | **CLOSED 2026-04-10** |
| [CASSANDRA-20584](https://issues.apache.org/jira/browse/CASSANDRA-20584) | #3569 | **CLOSED 2026-04-10** — #3570 (5.0 companion) still open |
| [CASSANDRA-18236](https://issues.apache.org/jira/browse/CASSANDRA-18236) | #3091 | Open — trie memtable docs gap, ping polandll or reassign |
| [CASSANDRA-15101](https://issues.apache.org/jira/browse/CASSANDRA-15101) | #317 | Open — check if content landed in AsciiDoc migration; close PR |
| [CASSANDRA-20579](https://issues.apache.org/jira/browse/CASSANDRA-20579) | #1073, #4529 (both closed) | Open — AsciiDoc fix still needed per bschoening |

---

## MERGE-READY

~~No PRs currently in this state.~~

### ~~PR #4673~~ — CASSANDRA-21218: Fix typos in documentation — **MERGED 2026-04-10**
- **Author:** Shanzita (Shanzita Siddiqua)
- **Created:** 2026-03-16 | **Base:** trunk
- **URL:** https://github.com/apache/cassandra/pull/4673

---

## NEEDS-REVIEW

Good changes that need a committer's eyes. None have blocking issues — they just lack approvals.

### PR #4719 — CASSANDRA-21291: Fix duplicate section and formatting typos in compaction overview (5.0 backport)
- **Author:** arvindKandpal-ksolves (Arvind Kandpal)
- **Created:** 2026-04-08 | **Base:** cassandra-5.0 | **Mergeable:** Yes
- **Review Decision:** None
- **Changes:** Backport of #4718 to cassandra-5.0. Removes duplicate `== Fully expired SSTables` section, fixes AsciiDoc link syntax, corrects "will will"/"and and" duplications, fixes property name plural (`only_purge_repaired_tombstones`).
- **Action:** Review alongside #4718. Spot-check that the tombstones.adoc diff is consistent between trunk and 5.0. Verify the property name spelling in source. Approve both together.
- **URL:** https://github.com/apache/cassandra/pull/4719

### PR #4718 — CASSANDRA-21291: Fix duplicate section and formatting typos in compaction overview
- **Author:** arvindKandpal-ksolves (Arvind Kandpal)
- **Created:** 2026-04-08 | **Base:** trunk | **Mergeable:** Yes
- **Review Decision:** None
- **Changes:** Trunk version of the above. Removes a duplicate section, fixes broken AsciiDoc link syntax, grammar duplications, property name plural, and punctuation in `tombstones.adoc`.
- **Action:** Review and approve. Verify the include directive in `overview.adoc` already pulls the deduplicated section. Merge together with #4719.
- **URL:** https://github.com/apache/cassandra/pull/4718

### PR #4689 — CASSANDRA-13342: Document failure reason codes in native protocol v5
- **Author:** Shanzita (Shanzita Siddiqua)
- **Created:** 2026-03-21 | **Base:** trunk | **Mergeable:** Yes
- **Review Decision:** None (only Copilot bot summary)
- **Changes:** Adds documentation for all 13 `<failure_code>` values to `native_protocol_v5.spec` for `Read_failure` (0x1300) and `Write_failure` (0x1500) sections.
- **Action:** Needs a committer with protocol knowledge (ideally @absurdfarce who was pinged but never responded). Validate the 13 failure codes against `RequestFailureReason.java` in trunk. If accurate, straightforward to approve.
- **URL:** https://github.com/apache/cassandra/pull/4689

### PR #4686 — [CHORE] Update link to Apache Archives for earlier Cassandra versions
- **Author:** pjfanning (PJ Fanning)
- **Created:** 2026-03-19 | **Base:** trunk | **Mergeable:** Yes
- **Review Decision:** None
- **Changes:** Single-line URL update in `installing.adoc` for the Apache Archives link pointing to older Cassandra releases.
- **Action:** A committer verifies the new URL is correct and stable (points to a reliable Apache archive index), then approves. Low effort — a one-minute review.
- **URL:** https://github.com/apache/cassandra/pull/4686

### PR #4588 — Fix typo in SAI index documentation
- **Author:** 0xbad0c0d3
- **Created:** 2026-01-28 | **Base:** cassandra-5.0 | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** Single-word fix in `create-custom-index.adoc`: "date" → "data".
- **Action:** A committer approves the one-line diff (trivially correct). Also verify whether the same typo exists on `trunk` and open a companion PR if so.
- **URL:** https://github.com/apache/cassandra/pull/4588

### PR #4444 — Correct typo in CASSANDRA-14092.txt
- **Author:** Chen-Yuanmeng
- **Created:** 2025-10-27 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** Fixes two typos in the plain-text artifact `CASSANDRA-14092.txt` at the repo root.
- **Action:** A committer verifies the corrections are accurate and approves. Low-risk, low-impact change. If no review in 4–6 weeks, move to CLOSE-STALE.
- **URL:** https://github.com/apache/cassandra/pull/4444

### PR #4409 — CASSANDRA-20951: Documentation/Storage Engine — Markdown Render Misformat Fix
- **Author:** MisterDerpie (Matthias Döpmann)
- **Created:** 2025-10-03 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** 4-line formatting fix in `storage-engine.adoc`. PR body includes before/after screenshot demonstrating the rendering improvement.
- **Action:** A committer reviews the 4-line diff and screenshots. Check CASSANDRA-20951 for any blockers. Approve if correct. PR is at the 6-month staleness threshold — prioritize or it becomes a closure candidate.
- **URL:** https://github.com/apache/cassandra/pull/4409

### PR #3614 — CASSANDRA-18868: Added documentation of granting permissions for all tables
- **Author:** Ayantika19 (Ayantika Sarkar)
- **Created:** 2024-10-14 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** Adds `GRANT` permission documentation for `ALL TABLES IN KEYSPACE` syntax to `security.adoc`, including new BNF examples and CQL snippets. Has a proper JIRA link.
- **Action:** A committer verifies CASSANDRA-18868 is resolved in trunk and the documented syntax/examples are accurate, then approves. No blocking comments exist — just needs first review.
- **URL:** https://github.com/apache/cassandra/pull/3614

### PR #3569 — Update data-modeling_schema.adoc (CASSANDRA-20584)
- **Author:** Amritmatti (Amritpal Singh)
- **Created:** 2024-09-25 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** Approved by himanshujindal (CONTRIBUTOR only — not a committer)
- **Changes:** Fixes CQL comment syntax in a `CREATE TABLE` example in `data-modeling_schema.adoc`. JIRA created: CASSANDRA-20584.
- **Action:** A committer needs to formally approve (contributor approval is insufficient). bschoening requested the JIRA but never reviewed the diff. Also assess relationship to companion PR #3570 (same author, same file, targets cassandra-5.0).
- **URL:** https://github.com/apache/cassandra/pull/3569

---

## NEEDS-WORK Review Verdicts

Full technical reviews conducted 2026-04-10. Assessed content correctness, Antora compliance, and whether the required work can be easily done.

### Quick Reference

| PR | Verdict | Effort | Who Does the Work |
|----|---------|--------|-------------------|
| [#2825](https://github.com/apache/cassandra/pull/2825) | **MERGE-AS-IS** | < 15 min | Any committer |
| [#4084](https://github.com/apache/cassandra/pull/4084) | **COMMITTER-FILE-JIRA-AND-MERGE** | < 1 hour | Any committer |
| [#3570](https://github.com/apache/cassandra/pull/3570) | **COMMITTER-FILE-JIRA-AND-MERGE** | < 1 hour | Any committer (bundle with #3569) |
| [#4388](https://github.com/apache/cassandra/pull/4388) | **ACCEPT-WITH-CHANGES** | Trivial | Author + JIRA + add cassandra-rs |
| [#4670](https://github.com/apache/cassandra/pull/4670) | **NEEDS-AUTHOR-FIXES** | < 1 hour | Author fixes 2 bad replacements, then rebases |
| [#2828](https://github.com/apache/cassandra/pull/2828) | **COMMITTER-NEW-PR** | < 1 hour | Committer opens fresh PR, do not wait for author |
| [#3091](https://github.com/apache/cassandra/pull/3091) | **PING-AUTHOR-THEN-COMMITTER** | < 1 day | Author (2-week deadline) then committer takeover |
| [#4333](https://github.com/apache/cassandra/pull/4333) | **CLOSE-PR-WRONG** | < 1 hour | Close + invite new 3-file PR with correct fix |

---

### ~~PR #2825~~ — Remove duplicate paragraph in storage_engine.adoc — **MERGED 2026-04-10**

- **Follow-up needed**: Same duplicate exists on `cassandra-4.0` (lines 6 and 33) and `cassandra-3.11` (lines 6 and 33). Cherry-picks or companion PRs still needed for those branches.
- **URL:** https://github.com/apache/cassandra/pull/2825

---

### PR #4084 — Fix images in data-modeling_logical.adoc

**Verdict: COMMITTER-FILE-JIRA-AND-MERGE**

- **Merge state**: CLEAN / MERGEABLE.
- **Content**: Fix is verified correct. The 3 broken image macros use a malformed cross-module reference format (`cassandra:developing/data-modeling/filename.png`). The correct format is `filename.png` (bare name — Antora resolves via `assets/images/`). The PR's fix matches how adjacent working pages (`data-modeling_conceptual.adoc`) do it. Images physically exist at `doc/modules/cassandra/assets/images/`.
- **Same fix needed on trunk**: YES — trunk has identical broken macros at the same 3 lines. A trunk companion PR is needed.
- **Only blocker**: No JIRA ticket. Content is ready.
- **Effort**: < 1 hour. File JIRA, add reference to commit message, merge to `cassandra-5.0`, cherry-pick to trunk.
- **Action**: Committer files CASSANDRA JIRA ("Fix broken image references in data-modeling_logical.adoc"), merges this PR, and opens/cherry-picks the trunk companion.

---

### PR #3570 — Update data-modeling_schema.adoc (cassandra-5.0)

**Verdict: COMMITTER-FILE-JIRA-AND-MERGE** (bundle with #3569 under one JIRA)

- **Merge state**: CLEAN / MERGEABLE. PR #3569 (trunk companion, same author) is also CLEAN.
- **Content**: Fix is verified correct. The `guests` table block has incomplete CQL type annotations (`emails set,` / `phone_numbers list,` / `addresses map<text,` with no closing type params). The fix supplies proper types: `emails set<text>`, `phone_numbers list<text>`, `addresses map<text, frozen<address>>`. CQL is syntactically valid. All 5 other tables in the block use this form correctly.
- **Bonus finding**: Both branches also have a missing opening `'` in a WITH COMMENT clause at line ~43 (`Q3. Find pois near a hotel'` → `'Q3. Find pois near a hotel'`). This is not touched by either PR — flag for follow-on.
- **Only blocker**: No JIRA ticket. Content is ready.
- **Effort**: < 1 hour for both #3570 and #3569. File one JIRA, merge 5.0 first then trunk.
- **Action**: File one CASSANDRA JIRA ("Fix incomplete CQL type annotations in data-modeling_schema.adoc"), merge #3570 to `cassandra-5.0` and #3569 to trunk under that JIRA. Note the missing-quote follow-on in the JIRA.

---

### PR #4388 — drivers.adoc: Replace Rust CQL with Scylla Rust Driver

**Verdict: ACCEPT-WITH-CHANGES**

**Key facts verified:**
- **Rust CQL is dead**: Last code commit 2016-07-27 (9 years ago). Confirmed via GitHub API. Not archived but functionally abandoned. Protocol V4 claim is consistent with 2016 vintage.
- **Scylla Rust Driver is actively maintained**: Last push 2026-04-10 (today). 668 stars, 147 forks.
- **Scylla Rust Driver is Cassandra-compatible**: README explicitly states "compatible with Apache Cassandra." Verified by a dedicated `.github/workflows/cassandra.yml` CI workflow that spins up a 3-node Cassandra cluster and runs the full test suite on every push — not just marketing copy.
- **cassandra-rs is real**: Active (last push June 2024, 146 stars). Wraps the DataStax C++ driver. Committer michaelsembwever explicitly asked whether it should be added.
- **Policy precedent**: DataStax (direct Cassandra competitor) already has 6 entries on the page. The page has no stated "non-competitor" policy. The existing structure supports inclusion.
- **Committer consensus**: Two committers said "no objections." Third (absurdfarce) never responded in 7+ months.

**Changes required before merge:**
1. **File a CASSANDRA JIRA** (Documentation type) — required for any contribution.
2. **Add `cassandra-rs`** alongside the Scylla Rust Driver — michaelsembwever requested it, PR author agreed to do it. Resulting Rust section:
   ```
   * https://github.com/scylladb/scylla-rust-driver[Scylla Rust Driver]
   * https://github.com/cassandra-rs/cassandra-rs[cassandra-rs]
   ```
3. **(Optional but advisable)** Short `dev@` mailing list DISCUSS thread to establish explicit driver inclusion criteria — DataStax precedent makes approval near-certain, but formalizing it is more defensible.

**Effort**: Trivial for content changes. JIRA filing takes 5 minutes. Mailing list thread is optional.

**Action**: Comment on PR asking author to: (1) file JIRA, (2) add `cassandra-rs` as a second Rust entry. Once done, two committer "no objections" should be sufficient to merge.

---

### PR #4670 — CASSANDRA-20901 fix typos

**Verdict: NEEDS-AUTHOR-FIXES then AUTHOR-REBASE-THEN-MERGE**

- **Merge state**: Conflict (CHANGES.txt — top-of-file insertion conflict from concurrent trunk commits). Rebase is trivial.
- **Serialization safety**: SAFE. The `GossipDigestSyn` field rename (`partioner` → `partitioner`) is a Java identifier change only. Wire format is determined by string values, not variable names. All 4 reference sites updated consistently.
- **Branch staleness**: PR was cut when `MessagingService.VERSION_51` was current; trunk now uses `VERSION_60`. Rebase will surface this context drift in gossip files but the PR does not touch those lines — they will reconcile cleanly.

**Two changes introduce new errors (blocking):**
1. **`ColumnFilterFactory.java`**: `prepartion` → `prepartition` — the correct word is `preparation` ("computed at preparation time"). `prepartition` is not a word in this context.
2. **`TombstoneOverwhelmingException.java`**: `partion key` → `partitioner key` — should be `partition key` (a CQL term). "partitioner key" is meaningless in Cassandra.
3. **`ScrubTest.java`** (lower priority): `partion index` → `partitioner index` — should be `partition index`.

**The 6 other changes are correct**: Token.java, GossipDigestSyn.java, GossipDigestSynVerbHandler.java, UncommittedTableData.java, MerkleTree.java, CHANGES.txt historical entry.

**Effort**: < 1 hour for author to fix 2-3 incorrect replacements and rebase onto trunk.

**Action**: Comment on PR with the 3 specific corrections needed, ask author to fix and rebase. After fixes, conflict is a trivial CHANGES.txt re-insertion.

---

### PR #2828 — Docs - add index naming note to clarify (SAI)

**Verdict: COMMITTER-NEW-PR** (do not wait for original author)

- **Merge state**: UNKNOWN. Source branch frozen October 2023 (2.5 years). GitHub cannot compute mergeability.
- **Content accuracy issue**: The partial `index-naming.adoc` text is self-contradictory — "Index names are unique per keyspace" (correct) followed by "unique identifier for the index for each table within a keyspace" (scope confusion, implies per-table uniqueness). Needs rewording.
- **sai-faq.adoc change**: Already applied to trunk independently — this hunk must be dropped.
- **create-index.adoc**: Restructured into a table format on trunk; the PR's insertion point no longer exists as written.
- **Core content is still needed**: The index uniqueness warning does not appear in any of the 4-5 target locations on current trunk. It is a valid and useful clarification.
- **Author activity**: polandll stated intent to merge in March 2024 and never did. Branch has been frozen for 2.5 years.

**What a committer needs to do (fresh PR):**
1. Create `doc/modules/cassandra/partials/index-naming.adoc` with corrected text: *"Index names are unique per keyspace. You cannot use the same index name for two different indexes within a keyspace, regardless of which table they are on."*
2. Add `include::cassandra:partial$index-naming.adoc[]` to `_sai-create.adoc`, `sai-quickstart.adoc`, `create-custom-index.adoc`
3. Find correct insertion point in the restructured `create-index.adoc` (the `index_name` row in the parameters table)
4. Omit the `sai-faq.adoc` change (already done)
5. Backport to `cassandra-5.0` as originally planned

**Effort**: < 1 hour for an experienced committer who knows the doc structure.

**Action**: Open a new PR. Close #2828 with a comment explaining the branch is too stale to rebase and a fresh PR has been opened.

---

### PR #3091 — CEP-19: Add trie memtable docs

**Verdict: PING-AUTHOR-WITH-SPECIFIC-FIXES** (2-week deadline then committer takeover)

- **Merge state**: MERGEABLE per API, but 6 substantive content errors that blambov identified remain unfixed.
- **Doc gap is real**: `TrieMemtable.java` is in trunk; zero trie memtable docs exist in trunk. This is a genuine documentation gap important for Cassandra 6.
- **Fraction of content that is correct**: Most (~70%). The high-level description, shards parameter, and structural approach are sound. The errors are concentrated in the configuration section and 2-3 specific sentences.

**6 specific errors to fix (send to polandll):**

1. **Write-amplification sentence** (`storage-engine.adoc`): Sentence attributes a general memtable behavior to trie specifically. blambov said Feb 16: "This sentence is still misleading." Fix: drop "Trie" at start or replace with "Generally,".

2. **Enabling section** (`storage-engine.adoc`): "can be enabled by setting the `memtable` configuration in cassandra.yaml to `trie`" is wrong — there is no such simple setting. Correct: "enabled per table via `WITH memtable = 'trie'` in CREATE/ALTER TABLE, or cluster-wide by setting `default.inherits: trie` in the `memtable.configurations` block in cassandra.yaml."

3. **YAML example** (`storage-engine.adoc`): Shows `default: inherits: trie` — trunk ships `default: inherits: skiplist`. The example should show the default (skiplist) and explain how to change it.

4. **Implementations list** (`storage-engine.adoc`): Says "two memtable implementations" (skiplist + trie). Trunk has three: `SkipListMemtable`, `ShardedSkipListMemtable`, `TrieMemtable`. `ShardedSkipListMemtable` is omitted.

5. **CQL syntax** (example `.cql` files): `WITH memtable = {'trie'}` (map literal with curly braces) is wrong CQL. Correct: `WITH memtable = 'trie'` (plain string).

6. **Broken xrefs** (`alter-table.adoc`, `create-table-examples.adoc`): `xref:architecture/storage-engine/memtable.adoc[Memtable]` — this page does not exist. Fix to point to `architecture/storage-engine.adoc` with appropriate anchor.

**Correct trie memtable configuration** (from trunk `cassandra.yaml` and `Memtable_API.md`):
```yaml
memtable:
  configurations:
    skiplist:
      class_name: SkipListMemtable
    trie:
      class_name: TrieMemtable
    default:
      inherits: skiplist   # ships as skiplist; change to trie for cluster-wide trie
```

**Effort**: < 1 day for someone with the correct information (which is now fully specified above).

**Action**: Post a detailed comment on the PR with the 6 specific fixes. Give polandll 2 weeks to respond. If no response, a committer should cherry-pick the valid parts and fix the errors in a new PR — the structure and most of the prose are worth salvaging.

---

### PR #4333 — Fix paths to images

**Verdict: CLOSE-PR-WRONG** — but the underlying issue is real and fixable with a 3-file PR

**Technical finding (definitive):**
- Antora's default `imagesdir` auto-resolves `image::filename.png[]` to `doc/modules/cassandra/assets/images/`. No `images/` prefix is needed or correct.
- The `antora.yml` is auto-generated (`gen-antora-yml.py`) and does not set a custom `imagesdir`.
- 4 of 7 data-modeling pages already use the correct format (`image::filename.png[image]`) and render correctly on cassandra.apache.org.
- The other 3 pages (`data-modeling_logical.adoc`, `data-modeling_physical.adoc`, `data-modeling_queries.adoc`) have genuinely broken image macros in the format `image::cassandra:developing/data-modeling/filename.png[image]` — a malformed cross-component reference that resolves to nothing.
- **The PR's `images/` prefix fix works accidentally** when using the `asciidoctor` CLI directly (because a local `images/` subdirectory exists inside the pages dir), but **it is wrong for the Antora build** and would not fix the published site.
- **smiklosovic is partially correct**: the `images/` prefix is wrong. But smiklosovic missed that 3 files are genuinely broken via the `cassandra:developing/data-modeling/` prefix.

**The correct fix** (3 files only, not 7):
Change `image::cassandra:developing/data-modeling/filename.png[image]` → `image::filename.png[image]` in:
- `data-modeling_logical.adoc`
- `data-modeling_physical.adoc`
- `data-modeling_queries.adoc`

**Effort for correct fix**: < 30 minutes.

**Action**: Close #4333 with an explanation: the `images/` prefix is wrong for Antora builds; the correct fix changes only 3 files to the bare `filename.png` format. Invite neshkeev to submit a new PR with the corrected 3-file change, or a committer can open the fix directly.

---

## NEEDS-WORK

These PRs have specific blockers that must be resolved before review or merge. Grouped by blocker type.

### Blocker: Merge Conflict

#### PR #4670 — CASSANDRA-20901 fix typos
- **Author:** innovationb1ue (Jeff Zhong)
- **Created:** 2026-03-12 | **Base:** trunk | **Mergeable:** No (dirty)
- **Review Decision:** None
- **Changes:** Fixes typos in Java source comments, variable names, and `CHANGES.txt` across 9 files including `GossipDigestSyn.java`, `MerkleTree.java`, and related gossip/repair classes. Not doc-only — touches Java source.
- **Blocker:** Merge conflict (CHANGES.txt is a common conflict point on active trunk). Variable renaming in gossip classes needs careful review for behavioral impact.
- **Action:** Ping author via JIRA (CASSANDRA-20901) to rebase onto current trunk. After rebase, a committer should review variable renaming in `GossipDigestSyn` and `GossipDigestSynVerbHandler` to confirm no behavioral change.
- **URL:** https://github.com/apache/cassandra/pull/4670

### Blocker: Policy / Editorial Decision Required

#### PR #4388 — drivers.adoc: Replace Rust CQL with Scylla Rust Driver
- **Author:** Lorak-mmk (Karol Baryła) — contributor to the Scylla Rust Driver
- **Created:** 2025-09-19 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** None (conversational "no objections" from one committer but no formal approval)
- **Changes:** Replaces the inactive `Rust CQL` driver entry with `Scylla Rust Driver` in `drivers.adoc`. The Rust CQL project has no commits for 9 years and lacks protocol V4 support.
- **Blocker:** Two unresolved questions: (1) Is listing a Scylla-branded driver acceptable per ASF/project policy given Scylla is a Cassandra competitor? (2) Should `cassandra-rs` also be added? Committer absurdfarce was pinged ~7 months ago for consensus and never responded.
- **Action:** Committer consensus is required. Reach a formal decision on: driver listing policy (Scylla branding), and whether `cassandra-rs` belongs in the same PR. If listing Scylla-branded drivers is not acceptable, close with explanation.
- **URL:** https://github.com/apache/cassandra/pull/4388

### Blocker: Technical Dispute / Unresolved Review

#### PR #4333 — Fix paths to images
- **Author:** neshkeev (Nikita Eshkeev)
- **Created:** 2025-08-23 | **Base:** trunk | **Mergeable:** Unknown
- **Review Decision:** None (committer left disputed inline comments)
- **Changes:** Adds `images/` prefix to image macros across 7 data-modeling AsciiDoc files.
- **Blocker:** Committer smiklosovic disputes whether the path change is needed — images already render correctly on the published site (`cassandra.apache.org`) without the prefix. The root cause (Antora `imagesdir` config vs raw `asciidoctor` CLI behavior) was never resolved. If the prefix is wrong, this PR would break image rendering. PR is 7.5 months old.
- **Action:** A committer with Antora build knowledge must verify the correct `imagesdir` configuration for this project. If images render correctly on trunk without the prefix (as observed), close the PR. If the Antora build does require the prefix, override smiklosovic's concern with evidence.
- **URL:** https://github.com/apache/cassandra/pull/4333

#### PR #3091 — CEP-19: Add trie memtable docs — storage engine, create and alter table
- **Author:** polandll (Lorina Poland)
- **Created:** 2024-02-06 | **Base:** trunk | **Mergeable:** Yes (per API)
- **Review Decision:** None (CHANGES_REQUESTED equivalent — blocking inline comments)
- **Changes:** Adds trie memtable documentation across 6 AsciiDoc files. Tied to CASSANDRA-18236. The trie memtable feature IS in trunk (`TrieMemtable.java` exists) but these docs have NOT been merged — the gap is real.
- **Blocker:** Committer blambov (trie memtable feature author) identified 2 unresolved content errors in March 2024: (1) a heading says "trie memtable" where "sharded skiplist memtable" is correct; (2) the cassandra.yaml configuration instructions are inaccurate relative to what was implemented. Author marked comments resolved without addressing them. No activity since March 2024 (2+ years).
- **Action:** Ping polandll to address blambov's 2 specific unresolved inline comments. If no response in 2-4 weeks, close and open a fresh PR — the trie memtable docs gap is a priority for Cassandra 6. A new PR must re-verify configuration syntax against current trunk `TrieMemtable.java`.
- **URL:** https://github.com/apache/cassandra/pull/3091

### Blocker: Missing JIRA Ticket

#### PR #4084 — Fix images in data-modeling_logical.adoc
- **Author:** velykyinn (Nicholas)
- **Created:** 2025-04-11 | **Base:** cassandra-5.0 | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** Corrects 3 broken image reference paths in `data-modeling_logical.adoc` (3 additions, 3 deletions). Change appears correct.
- **Blocker:** Committer bbotella asked for a JIRA ticket on day 1 (2025-04-11). Author never created one. No trunk PR exists.
- **Action:** Author needs to (1) create a CASSANDRA JIRA and (2) open a companion PR against trunk. A committer can then fast-track the trivial diff.
- **URL:** https://github.com/apache/cassandra/pull/4084

#### PR #3570 — Update data-modeling_schema.adoc (cassandra-5.0)
- **Author:** Amritmatti (Amritpal Singh)
- **Created:** 2024-09-25 | **Base:** cassandra-5.0 | **Mergeable:** Unknown
- **Review Decision:** None
- **Changes:** Adds a note about collection type syntax (angle brackets for sets/lists/maps) in `data-modeling_schema.adoc`.
- **Blocker:** No JIRA ticket. Companion PR #3569 (trunk, same file, different but related change) has a JIRA (CASSANDRA-20584) but this one does not. Evaluate together with #3569.
- **Action:** Ask author to create a JIRA. A committer should assess whether #3570 and #3569 overlap or conflict before merging either.
- **URL:** https://github.com/apache/cassandra/pull/3570

### Blocker: Approved but Needs Conflict/Branch Check

#### PR #2828 — Docs - add index naming note to clarify (SAI)
- **Author:** polandll (Lorina Poland)
- **Created:** 2023-10-19 | **Base:** trunk | **Mergeable:** Unknown (likely drifted)
- **Review Decision:** APPROVED by michaelsembwever (2023-10-23)
- **Changes:** Adds clarifying note about SAI index naming across 6 AsciiDoc files, introducing a new `index-naming.adoc` partial.
- **Blocker:** Approved in 2023 but never merged. Author's own comment from March 2024 says "I need to merge this to trunk and 5.0" — never happened. Branch has almost certainly drifted in 2.5 years.
- **Action:** Check for merge conflicts against current trunk. If clean, merge immediately and cherry-pick or open a separate PR for cassandra-5.0. If conflicts, ask polandll to rebase or rebase on their behalf.
- **URL:** https://github.com/apache/cassandra/pull/2828

#### ~~PR #2825~~ — [doc] Remove duplicate paragraph in storage_engine.adoc — **MERGED 2026-04-10**
- See NEEDS-WORK review verdicts above for follow-up cherry-pick notes.
- **URL:** https://github.com/apache/cassandra/pull/2825

---

## CLOSE-STALE

**7 of the original 10 CLOSE-STALE PRs were closed on 2026-04-10. See the CLOSED section below.**

One remains open:

### PR #317 — CASSANDRA-15101 - Add Token Ring/Range Documentation *(still open — close it)*
- **Author:** Eli10 (Elijah Augustin)
- **Created:** 2019-05-03 | **Base:** trunk | **Last Active:** 2019-05-03
- **Why Close:** Targets `doc/source/architecture/dynamo.rst` (RST, superseded by AsciiDoc architecture pages). No review in 7 years. Content likely incorporated into AsciiDoc during the doc migration.
- **Close together with:** Was bundled with #316 and #315 (now closed). Use same RST template comment.
- **URL:** https://github.com/apache/cassandra/pull/317

---

## CLOSED (2026-04-10)

PRs closed without merging in the post-triage sweep. Kept here for reference.

### ~~PR #3911~~ — Fix broken link in Material View docs — **CLOSED**
- **Author:** mcneiljt (Josh McNeil)
- **Created:** 2025-02-19 | **Base:** cassandra-4.1 | **Last Active:** 2025-02-22
- **Why Closed:** Committer bbotella requested a JIRA and a trunk PR on day 1. Neither was created. Author silent for 13+ months.
- **Note:** The fix (adding a missing `]` to a hyperlink in `mvs.adoc`) is valid. A committer can port it under a new JIRA.
- **URL:** https://github.com/apache/cassandra/pull/3911

### ~~PR #2262~~ — Update documentation to fix typos & add missing info — **CLOSED**
- **Author:** lukechatfield
- **Created:** 2023-04-06 | **Base:** trunk | **Last Active:** 2023-04-06
- **Why Close:** Committer smiklosovic left feedback on day 1 asking the author to also address `new/virtualtables.adoc` and suggesting adding `system_views.system_logs`. Author never responded — 3 years of silence.
- **Note:** The underlying fixes (USE statement examples, DESCRIBE ordering, virtual table metric descriptions) appear correct. Port to a fresh PR addressing smiklosovic's questions.
- **URL:** https://github.com/apache/cassandra/pull/2262

### ~~PR #1125~~ — Docs: add JIRA steps to release process — **CLOSED**
- **Author:** michaelsembwever (Mick Semb Wever — committer)
- **Created:** 2021-08-01 | **Base:** trunk | **Last Active:** 2021-08-01
- **Why Closed:** RST target (`doc/source/development/release_process.rst`) superseded. No response to 2022 committer question.
- **URL:** https://github.com/apache/cassandra/pull/1125

### PR #1073 — Update cqlsh.rst *(still open — do NOT close)*
- **Author:** premsangeeth (Prem Sangeeth)
- **Created:** 2021-06-17 | **Base:** trunk
- **Status:** Kept open. Committer bschoening commented April 2025 that the underlying issue is tracked as [CASSANDRA-20579](https://issues.apache.org/jira/browse/CASSANDRA-20579) in AsciiDoc. A contributor approved it May 2025. Active — do not close.
- **URL:** https://github.com/apache/cassandra/pull/1073

### ~~PR #456~~ — Datamodel — **CLOSED**
- **Author:** Deepak-Vohra (Deepak Vohra)
- **Created:** 2020-02-27 | **Why Closed:** RST `doc/source/data_modeling/` superseded. No response to 2022 committer question.
- **URL:** https://github.com/apache/cassandra/pull/456

### ~~PR #420~~ — Ddl — **CLOSED**
- **Author:** Deepak-Vohra (Deepak Vohra)
- **Created:** 2020-01-07 | **Why Closed:** RST `doc/source/cql/ddl.rst` superseded. 852 additions to legacy file, no review in 6+ years.
- **URL:** https://github.com/apache/cassandra/pull/420

### ~~PR #316~~ — CASSANDRA-13451 add gossip documentation — **CLOSED**
- **Author:** Eli10 (Elijah Augustin)
- **Created:** 2019-05-03 | **Why Closed:** RST superseded. Closed as a batch with #315. Gossip docs exist in AsciiDoc architecture pages.
- **URL:** https://github.com/apache/cassandra/pull/316

### ~~PR #315~~ — CASSANDRA-15103 Add Failure Detection Docs — **CLOSED**
- **Author:** Eli10 (Elijah Augustin)
- **Created:** 2019-05-03 | **Why Closed:** RST superseded. Closed as a batch with #316.
- **URL:** https://github.com/apache/cassandra/pull/315

### ~~PR #211~~ — fix on materialized view PK example — **CLOSED**
- **Author:** enricocavallin (Enrico Cavallin)
- **Created:** 2018-03-25 | **Why Closed:** RST `doc/source/cql/mvs.rst` superseded. Oldest PR, zero reviews ever.
- **Note:** Verify AsciiDoc MV docs show `IS NOT NULL` in PK examples — file JIRA if missing.
- **URL:** https://github.com/apache/cassandra/pull/211

---

## Closing Comment Template

Use this when closing stale RST-era PRs:

> Thank you for this contribution. Unfortunately this PR targets `doc/source/` which is the legacy RST documentation source — this has been superseded by AsciiDoc content under `doc/modules/cassandra/`. Changes to RST files are no longer incorporated into the published documentation.
>
> If this fix is still needed in the current AsciiDoc docs, please open a new JIRA ticket and a fresh PR targeting the equivalent `.adoc` file. We appreciate the effort and would welcome an updated contribution!

---

## Patterns and Notes for Future Cleanup

1. **RST era (pre-AsciiDoc migration):** PRs #211, #315, #316, #420, #456, #1125 closed 2026-04-10. #317 still open — close it. #1073 kept open (tracked via CASSANDRA-20579).

2. **Missing JIRA = common blocker:** Many newer PRs stall because contributors don't know a JIRA ticket is required before a PR can be accepted. This is worth documenting more prominently in `CONTRIBUTING.md`.

3. **Approved but never merged:** #4673 and #2825 merged 2026-04-10. #2828 is still approved-but-drifted — 2.5 years since approval, branch likely stale.

4. **Same-file, same-author duplicates:** #4718/#4719 (trunk + 5.0 backport, intentional), #3569/#3570 (trunk + 5.0, should be evaluated together).

5. **Trie memtable docs gap:** PR #3091 identified a real gap — trie memtable (`TrieMemtable.java`) is in trunk but has no docs. Even if #3091 is closed, someone needs to write accurate trie memtable docs for Cassandra 6. Add this to the Cassandra 6 docs backlog.

6. **Scylla driver policy:** PR #4388 surfaced a gap in Apache Cassandra's driver listing policy regarding competitor-branded drivers. This policy question should be settled by the PMC regardless of this specific PR's outcome.

7. **#2825 follow-up:** Merged to cassandra-4.1. Same duplicate paragraph exists on cassandra-4.0 and cassandra-3.11 — cherry-picks or companion PRs still needed.
