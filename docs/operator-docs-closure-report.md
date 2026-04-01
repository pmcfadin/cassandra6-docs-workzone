# Operator Docs Closure Report

Date: 2026-04-01
Source critique: `docs/operator-docs-critique.md`
Implementation repo: `/Users/patrick/local_projects/cassandra6-docs-workzone`
Implementation branch: `main` (working tree only)

## Summary

This pass implemented the operator-doc changes in the workzone only, under
`content/operators/modules/ROOT/pages/`.

Status labels:

- `fixed`: updated in the workzone and rechecked locally
- `still open`: not included in this implementation pass, or critique-adjacent residue remains outside the edited slice

## Fixed

| Critique item | Status | Evidence |
|---|---|---|
| `configure.adoc` is the wrong page entirely | fixed | [configure.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure.adoc) is now the landing page |
| Parameter-renaming reference belongs on a sub-page | fixed | moved to [cassandra_yaml_parameter_units.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cassandra_yaml_parameter_units.adoc) |
| `operate/ucs.adoc` editorial comments visible | fixed | reviewer comments removed from [ucs.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/ucs.adoc) |
| `operate/snitch.adoc` open review block | fixed | review artifact removed from [snitch.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/snitch.adoc) |
| `configure/cass_jvm_options_file.adoc` unresolved draft text | fixed | draft questions removed from [cass_jvm_options_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_jvm_options_file.adoc) |
| `tcm-overview.adoc` does not explain why TCM exists | fixed | [tcm-overview.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-overview.adoc) now opens with the motivation and barrier rationale |
| `upgrade/onboarding-to-accord.adoc` never explains Accord | fixed | [onboarding-to-accord.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/upgrade/onboarding-to-accord.adoc) now introduces Accord before configuration |
| `secure/mtlsauthenticators.adoc` lacks certificate generation instructions | fixed | [mtlsauthenticators.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/mtlsauthenticators.adoc) now includes CA/server/client prerequisites |
| `secure/security.adoc` password-auth procedure can leave cluster inconsistent | fixed | [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc) now sequences `system_auth` replication before the auth rollout |
| `observe/audit_logging.adoc` is a duplicate page | fixed | duplicate [audit_logging.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/observe/audit_logging.adoc) deleted in favor of [auditlogging.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/observe/auditlogging.adoc) |
| `tcm-troubleshooting.adoc` unresolved questions section | fixed | unresolved-question content removed from [tcm-troubleshooting.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-troubleshooting.adoc) and replaced with decision criteria |
| `install.adoc` unresolved include directives | fixed | [install.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/install.adoc) now uses inline workzone content instead of broken external includes |
| `operate/repair.adoc` does not explain consequences of skipping repair | fixed | [repair.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/repair.adoc) now states the concrete failure modes |
| No configuration guide entry point | fixed | [configure.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure.adoc) now lists config files, purpose, and edit order |
| Repair pages lack reading order guidance | fixed | [repair.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/repair.adoc) now points readers to [auto_repair.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/auto_repair.adoc) and [repair-orchestration.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/repair-orchestration.adoc) |
| No security checklist | fixed | [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc) now has a new-cluster checklist |
| `production.adoc` encryption warning lacks failure mode | fixed | encryption failure-mode explanation added in [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc), the active security landing page for this workzone |
| `cass_env_sh_file.adoc` lacks consequence guidance | fixed | [cass_env_sh_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_env_sh_file.adoc) now explains why the startup flags matter |
| `cass_rackdc_file.adoc` lacks mismatch consequences | fixed | [cass_rackdc_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_rackdc_file.adoc) now explains placement consequences |
| `cass_topo_file.adoc` lacks identical-file warning | fixed | [cass_topo_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_topo_file.adoc) now explains why mismatches are dangerous |
| `operate/tombstones.adoc` lacks resurrection timeline guidance | fixed | [tombstones.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/tombstones.adoc) now explains the `gc_grace_seconds` deadline |
| `operate/hints.adoc` lacks hints-vs-repair guidance | fixed | [hints.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/hints.adoc) now explains where hints stop helping |
| `upgrade/upgrade-runbook.adoc` lacks `upgradesstables` consequence | fixed | consequence and diagnostics added to [upgrade-runbook.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/upgrade/upgrade-runbook.adoc) |
| `tcm-operations.adoc` says not to add waits but does not explain why | fixed | [tcm-operations.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-operations.adoc) now explains the old wait vs barrier model |
| `cass_rackdc_file.adoc` lacks snitch decision table | fixed | decision table added to [cass_rackdc_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_rackdc_file.adoc) |
| `secure/role_name_generation.adoc` lacks operational workflow | fixed | workflow added to [role_name_generation.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/role_name_generation.adoc) |
| `secure/mtlsauthenticators.adoc` lacks end-to-end verification | fixed | verification path added to [mtlsauthenticators.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/mtlsauthenticators.adoc) |
| `operate/compaction-overview.adoc` lacks compaction matrix | fixed | strategy matrix added to [compaction-overview.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/compaction-overview.adoc) |
| `operate/auto_repair.adoc` lacks large-cluster incremental-repair example | fixed | guidance added to [auto_repair.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/auto_repair.adoc) |
| `upgrade/upgrade-runbook.adoc` lacks wait-for-rejoin timeout/diagnostics | fixed | added to [upgrade-runbook.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/upgrade/upgrade-runbook.adoc) |
| `tcm-upgrade-procedure.adoc` lacks failed CMS init example | fixed | example added to [tcm-upgrade-procedure.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-upgrade-procedure.adoc) |
| `operate/bulk_loading.adoc` lacks prerequisite checklist and verification | fixed | both added to [bulk_loading.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/bulk_loading.adoc) |
| `guardrails-reference.adoc` lacks `setguardrailsconfig` runtime example | fixed | example added to [guardrails-reference.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/guardrails-reference.adoc) |
| `restore-runbook.adoc` lacks acceptable row-count variance guidance | fixed | guidance added to [restore-runbook.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/backup-recovery/restore-runbook.adoc) |
| `operate/compaction-overview.adoc` lacks memtable→SSTable→merge diagram | fixed | text flow diagram added to [compaction-overview.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/compaction-overview.adoc) |
| `operate/ucs.adoc` needs tiered vs leveled layout guidance | fixed | expanded in [ucs.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/ucs.adoc) |
| `secure/security.adoc` needs JMX auth decision tree | fixed | added to [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc) |
| `secure/mtlsauthenticators.adoc` needs mTLS flow diagram | fixed | flow described as an operator verification sequence in [mtlsauthenticators.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/mtlsauthenticators.adoc) |
| `tcm-overview.adoc` needs node lifecycle state machine | fixed | lifecycle sequence added in [tcm-overview.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-overview.adoc) |
| `tcm-operations.adoc` needs barrier timeline | fixed | barrier explanation added in [tcm-operations.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-operations.adoc) |
| `operate/node-replacement-runbook.adoc` lacks expected logs and thresholds | fixed | added to [node-replacement-runbook.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/node-replacement-runbook.adoc) |
| `operate/disk-pressure-runbook.adoc` lacks example outputs and has guardrails misplaced | fixed | guardrails moved to the top and examples added in [disk-pressure-runbook.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/disk-pressure-runbook.adoc) |
| `tcm-troubleshooting.adoc` lacks wait-vs-recovery criteria | fixed | explicit criteria added in [tcm-troubleshooting.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-troubleshooting.adoc) |
| `anticompaction` vs `anti-compaction` inconsistency in edited runbooks | fixed | standardized in the updated repair slice |
| `role` vs `user` vs `principal` vs `identity` not introduced | fixed | defined in [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc) |
| `cass_rackdc_file.adoc` uses `replicates` instead of `replicas` | fixed | corrected in [cass_rackdc_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_rackdc_file.adoc) |
| `quickstart.adoc` lacks cleanup instructions | fixed | added to [quickstart.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/quickstart.adoc) |
| `quickstart.adoc` lacks `nodetool status` example | fixed | added to [quickstart.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/quickstart.adoc) |
| `secure/security.adoc` typo `useeCassandra's` | fixed | corrected in [security.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/secure/security.adoc) |
| `configure/cass_logback_xml_file.adoc` typo `configration` | fixed | corrected in [cass_logback_xml_file.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/configure/cass_logback_xml_file.adoc) |
| `observe/auditlogging.adoc` typo `troobleshooting` | fixed | corrected in [auditlogging.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/observe/auditlogging.adoc) |
| `observe/golden-signals.adoc` wrong `humanizeDuration` formatter | fixed | corrected in [golden-signals.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/observe/golden-signals.adoc) |
| `backup-recovery/backups.adoc` does not explain ephemeral snapshots | fixed | clarified in [backups.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/backup-recovery/backups.adoc) |
| `operate/snitch.adoc` bridge class unexplained | fixed | clarified in [snitch.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/operate/snitch.adoc) |
| `automate/config-as-code.adoc` `reloadlocalschema` placement is confusing | fixed | clarified in [config-as-code.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/automate/config-as-code.adoc) |
| `install.adoc` still referenced `apache-cassandra-4.0.0/` | fixed | corrected in [install.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/install.adoc) |

## Still Open

These remain outside the edited slice or still exist elsewhere in the workzone:

- [tcm-pre-upgrade.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/tcm-pre-upgrade.adoc) still contains an `Unresolved Questions` section
- [diagnosing-compaction.adoc](/Users/patrick/local_projects/cassandra6-docs-workzone/content/operators/modules/ROOT/pages/observe/diagnosing-compaction.adoc) still uses `anti-compaction`
- I did not run a full Antora preview because `node` is not installed in this workspace

## Validation Performed

- `git diff --check` passed in `/Users/patrick/local_projects/cassandra6-docs-workzone`
- repo search confirmed removal of the targeted critique markers in the edited slice:
  - `LLP` reviewer comments in `operate/ucs.adoc`
  - `Open questions for technical review`
  - `Confirm whether CASSANDRA-18831 is the sole JIRA`
  - `++_++` artifacts in `upgrade/onboarding-to-accord.adoc`
  - duplicate `observe/audit_logging.adoc` references
  - `troobleshooting`
  - `useeCassandra`
  - `configration`
  - `humanizeDuration` in the alert example
- `node --version` failed because `node` is not installed in this workspace, so Antora render validation could not be run here

## Conclusion

The workzone operator-doc pass now covers the critique items that were explicitly planned for implementation here, including the TCM and upgrade pages that were missing from the Cassandra source checkout.

The remaining follow-up items are narrow and explicit: clean the unresolved-question section in `tcm-pre-upgrade.adoc`, standardize `anticompaction` in `diagnosing-compaction.adoc`, and run a full Antora preview once a Node/Antora runtime is available.
