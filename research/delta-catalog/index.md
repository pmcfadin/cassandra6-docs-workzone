# Delta Catalog: Cassandra 5.0 → trunk

Comparison of `origin/cassandra-5.0` vs `origin/trunk` doc pages.

Generated: 2026-03-25

## Tracker

| Area | Output file | 5.0 pages | trunk pages | Major delta | Generated surfaces | Status | Follow-up | Notes |
|------|------------|-----------|-------------|-------------|-------------------|--------|-----------|-------|
| architecture | architecture.md | 8 | 11 | 3 new Accord pages + index update | none | complete | review-only | Accord docs developer-focused; possible gaps in user-facing overview |
| developing/cql | developing-cql.md | 65 | 66 | 1 new (constraints); 4 major-update; 5 minor-update; 1 refactor | none | complete | update-existing | Gaps: BETWEEN, NOT operators, GENERATED PASSWORD lack per-topic docs |
| developing/data-modeling | developing-data-modeling.md | 14 | 14 | none | none | complete | needs-change-catalog-check | No diff; may need Accord/new-type updates |
| getting-started | getting-started.md | 9 | 9 | 2 modified | none | complete | update-existing | drivers.adoc updated driver list; mtls adds password fallback auth |
| installing | installing.md | 1 | 1 | none | none | complete | needs-change-catalog-check | No diff; verify Java/OS reqs for C6 |
| integrating | integrating.md | 1 | 1 | 1 modified | none | complete | review-only | Removes CAPI-Rowcache; Lucene index marked retired |
| managing/configuration | managing-configuration.md | 8 | 8 | 2 modified (logback major, jvm minor) | cass_yaml_file (not committed; pipeline) | complete | regen-validate | Slow-query logging added; cass_yaml needs gen validation; typo: "virual" |
| managing/operating | managing-operating.md | 28 | 33 | 5 new, 7 major-update, 6 minor-update | none | complete | update-existing | +2305/-304 lines; gaps: crypto providers removed, cloud snitches removed, WIP Accord onboarding |
| managing/tools | managing-tools.md | 16 | 16 | 3 modified (cqlsh, sstabledump, sstableloader) | nodetool (not committed; gen script) | complete | regen-validate | ELAPSED cmd, tombstone-only flag, SSL rewrite; nodetool needs regen; typos found |
| new | new.md | 1 | 1 | 1 modified | none | complete | draft-new-page | Placeholder C6 section with 3 bullets (Accord, TCM, Constraints); needs expansion |
| overview | overview.md | 3 | 3 | none | none | complete | needs-change-catalog-check | No diff; terminology may need Accord terms |
| reference | reference.md | 10 | 10 | 2 modified | native-protocol specs (not committed; regen-validate) | complete | update-existing + regen-validate | SAI vtables renamed; LIST SUPERUSERS added; native-protocol specs modified on trunk; list-superusers.adoc may be dangling |
| tooling | tooling.md | 4 | 4 | none | none | complete | needs-change-catalog-check | No diff; minor area |
| troubleshooting | troubleshooting.md | 5 | 5 | none | none | complete | needs-change-catalog-check | No diff |
| vector-search | vector-search.md | 11 | 11 | none | none | complete | needs-change-catalog-check | No diff; new in 5.0, check for C6 enhancements |
| ROOT | root.md | 1 | 1 | none | none | complete | review-only | No diff; landing page |
| nav + partials | nav-partials.md | — | — | nav.adoc + 3 partials modified | — | complete | review-only | Nav adds 8 entries; partials update pkg versions + SAI table names |
