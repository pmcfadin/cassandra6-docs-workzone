# Operator Docs Review — Gate Report

**Date:** 2026-04-01  
**Reviewer methodology:** 6 parallel newbie-operator agents, each reading a section of the docs as a first-time Cassandra operator with Linux/distributed-systems background but no Cassandra experience.  
**Total pages reviewed:** 58  
**Total issues found:** ~175

---

## 🚨 SHIP BLOCKERS — Fix Before Any External Review

These are either embarrassing artifacts, dangerous procedures, or foundational gaps that will damage trust immediately.

| # | File | Issue |
|---|---|---|
| 1 | `configure.adoc` | **Wrong page entirely.** File is a parameter-renaming reference (CASSANDRA-15234), not a configuration guide. New operators have zero roadmap into the config system. |
| 2 | `operate/ucs.adoc` | **Editorial comments in production docs.** `// LLP: I don't know what this means` and `// LLP: What does limit-many mean` are visible to readers. |
| 3 | `operate/snitch.adoc` | **"Open questions for technical review"** block embedded at line 329-336. Remove before publication. |
| 4 | `configure/cass_jvm_options_file.adoc` | **Draft content with unresolved questions** ("Confirm whether CASSANDRA-18831 is the sole JIRA...") visible in the body. Preview banner exists but the questions should not ship. |
| 5 | `tcm-overview.adoc` | **Never explains WHY TCM exists.** Operators new to Cassandra 6 have no context for why gossip was replaced. The "what" and "how" are there; the "why" is missing entirely. |
| 6 | `upgrade/onboarding-to-accord.adoc` | **Never explains what Accord is.** Jumps straight into configuration. First encounter with this Cassandra 6 feature will confuse anyone. |
| 7 | `secure/mtlsauthenticators.adoc` | **No certificate generation instructions.** Operators need to generate CA, server, and client certs before any of this is usable. This is the #1 barrier to entry for mTLS setup. |
| 8 | `secure/security.adoc` | **"Enable Password Authentication" procedure can leave cluster inconsistent.** Steps restart a single node before system_auth replication is distributed — classic race condition. |
| 9 | `observe/audit_logging.adoc` | **Duplicate file.** `auditlogging.adoc` (550 lines, comprehensive) and `audit_logging.adoc` (227 lines, older/shorter) cover the same feature. Kill `audit_logging.adoc`, update all xrefs. |
| 10 | `tcm-troubleshooting.adoc` | **"Unresolved Questions" section in production docs.** Whether `cms cancel_in_progress_sequences` is safe during FINISH phase is listed as "unresolved." This cannot ship. |
| 11 | `install.adoc` | **Antora include directives unresolved.** Lines like `include::Cassandra:cassandra:example$BASH/docker_pull.sh[]` will render as broken text in published docs. Verify the build or inline the commands. |
| 12 | `operate/repair.adoc` | **No consequence for skipping repair.** Mentions "data loss" obliquely but never states the mechanism: missed hints expire, deleted data resurrects, disk corruption spreads. The #1 operational imperative has no teeth. |

---

## ⚠️ MAJOR GAPS — Should Fix Before GA

### Documentation Structure

- **No configuration guide entry point** — `configure.adoc` needs to be a parent page listing all 5 config files, their purpose, and edit order. The parameter-renaming content belongs on a sub-page.
- **Three repair pages lack reading order guidance** — `repair.adoc`, `auto_repair.adoc`, and `repair-orchestration.adoc` overlap heavily. Need a "read in this order / quick answer" nav note at the top of `repair.adoc`.
- **No security checklist** — `security.adoc` should open with a "new cluster security checklist" (enable TLS, set system_auth RF, create non-default superuser, etc.) in priority order.

### Missing "Why" (consistently across sections)

- `production.adoc` — encryption section warns about downtime risk but doesn't explain the failure mode
- `cass_env_sh_file.adoc` — `consistent.rangemovement`, `ring_delay_ms`, vnodes: no consequence for wrong choices
- `cass_rackdc_file.adoc` — dc name must match keyspace replication; mismatch causes silent wrong replica placement
- `cass_topo_file.adoc` — topology file must be identical on every node; divergence causes incorrect replica placement
- `operate/tombstones.adoc` — no explanation of resurrection timeline; gc_grace_seconds deadline not quantified
- `operate/hints.adoc` — when to trust hints vs. rely on repair; no guidance
- `upgrade/upgrade-runbook.adoc` — `upgradesstables` step has no explanation of what breaks if skipped
- `tcm-operations.adoc` — "Do not add manual waits" but no explanation of why the old 30-second wait existed or why TCM eliminates it

### Missing Examples (highest-impact gaps)

- `cass_rackdc_file.adoc` — No snitch decision table (on-prem vs. single-AZ AWS vs. multi-region AWS vs. custom)
- `secure/role_name_generation.adoc` — No operational workflow showing how to use a generated credential end-to-end
- `secure/mtlsauthenticators.adoc` — No end-to-end verification (how to test mTLS is working with cqlsh/driver)
- `operate/compaction-overview.adoc` — No compaction strategy decision matrix (which to use when)
- `operate/auto_repair.adoc` — No worked example for enabling incremental repair on an existing large cluster
- `upgrade/upgrade-runbook.adoc` — Rolling upgrade Step 5 "Wait for rejoin" has no timeout or diagnostic steps
- `tcm-upgrade-procedure.adoc` — No example of what failed CMS initialization output looks like
- `operate/bulk_loading.adoc` — No verification step after `sstableloader`; no prerequisite checklist
- `observe/guardrails-reference.adoc` — No `nodetool setguardrailsconfig` runtime example
- `backup-recovery/restore-runbook.adoc` — No guidance on acceptable row count variance after restore

### Needs Diagrams (highest-value additions)

- `operate/compaction-overview.adoc` — Memtable → SSTable accumulation → merge sequence
- `operate/ucs.adoc` — Tiered vs. leveled SSTable layout with concrete sizes
- `operate/repair.adoc` — Merkle tree comparison between two nodes
- `secure/security.adoc` — JMX auth decision tree (local-only vs. standard vs. integrated)
- `secure/mtlsauthenticators.adoc` — mTLS handshake → identity extraction → identity_to_roles lookup → permissions flow
- `tcm-overview.adoc` — Node lifecycle state machine (REGISTERED → BOOTSTRAPPING → JOINING → JOINED)
- `tcm-operations.adoc` — Progress barrier timeline showing elimination of split-brain window

### Runbooks Under Stress

- `operate/node-replacement-runbook.adoc` — No expected log output for successful replacement; thresholds for "dropped messages" and "pending compactions" not defined
- `operate/disk-pressure-runbook.adoc` — No example output from `nodetool compactionstats` or `du`; guardrails section placement is wrong (should be first, not last)
- `tcm-troubleshooting.adoc` — CMS Quorum Lost playbook has no decision criteria for "wait" vs. "emergency recovery"

### Terminology / Consistency

- `anticompaction` vs `anti-compaction` — inconsistent hyphenation across repair pages; standardize on `anticompaction`
- `role` vs `user` vs `principal` vs `identity` — not introduced with distinctions in `security.adoc`
- `cass_rackdc_file.adoc` uses "replicates" where it means "replicas"
- `upgrade/onboarding-to-accord.adoc` uses `++_++` notation (AsciiDoc rendering artifact) in `transactional_mode`

---

## 📝 POLISH — Nice to Have

- `quickstart.adoc` — No cleanup instructions for the Docker evaluation container
- `quickstart.adoc` — `nodetool status` output example not shown (what does UN actually look like?)
- `secure/security.adoc` line 751 — typo: "useeCassandra's"
- `configure/cass_logback_xml_file.adoc` line 87 — typo: "configration"
- `observe/auditlogging.adoc` line 263 — typo: "troobleshooting"
- `observe/golden-signals.adoc` — Prometheus alert uses `humanizeDuration` on microseconds — wrong formatter, will display as ~0s
- `backup-recovery/backups.adoc` — Ephemeral snapshots not explained; operators will be confused by "you cannot manually remove" with no context
- `operate/snitch.adoc` — `SnitchAdapter bridge class` used without explaining what a bridge class is
- `automate/config-as-code.adoc` — `reloadlocalschema` listed alongside cache commands; inconsistent/confusing
- `install.adoc` — References `apache-cassandra-4.0.0/` as extract directory while file is about Cassandra 6

---

## By-the-Numbers Summary

| Section | Critical | Major | Minor | Total |
|---|---|---|---|---|
| Get Started | 0 | 17 | 3 | 20 |
| Configuration | 2 | 22 | 3 | 27 |
| Security | 2 | 20 | 13 | 35 |
| Day 2 Ops + Repair | 8 | 18 | 14 | 40 |
| Runbooks + Upgrade + TCM | 4 | 24 | 0 | 28 |
| Observe + Backup + Tune + Ref | 2 | 15 | 8 | 25 |
| **Total** | **18** | **116** | **41** | **175** |

---

## Recommended Triage Order

1. Fix all 12 ship blockers (editorial cleanup + procedure safety)
2. Write the `configure.adoc` entry point (biggest structural gap)
3. Add certificate generation to the mTLS page (biggest new-content gap)
4. Add "why TCM" and "what is Accord" context paragraphs (quick wins, high value)
5. Tackle the "missing why" and "missing examples" issues section by section
