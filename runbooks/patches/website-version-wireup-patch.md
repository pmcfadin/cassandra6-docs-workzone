# Website Version Wire-Up Patch: Cassandra 6.0

Prepared: 2026-03-27
Source files fetched from: `apache/cassandra-website` branch `trunk`
Runbook reference: `runbooks/cassandra6-version-wireup.md` items 4–6

This document shows the exact changes required in three `apache/cassandra-website` files to wire Cassandra 6.0 into the versioned docs system. All three changes must be applied in a single coordinated commit to the website repo — applying them partially will leave the build in an inconsistent state.

---

## 1. `site-content/Dockerfile`

### What changes

Add `cassandra-6.0` to the `ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES` environment variable so that Antora pulls the 6.0 branch as a content source during the site build.

The comment on this line also notes that changes here require matching updates to `move_intree_document_directories` calls in `docker-entrypoint.sh` (see section 2 below).

### Current state

```
ENV ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES="trunk cassandra-5.0 cassandra-4.1 cassandra-4.0 cassandra-3.11"
```

Source: https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile

### Required change

```diff
-ENV ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES="trunk cassandra-5.0 cassandra-4.1 cassandra-4.0 cassandra-3.11"
+ENV ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES="trunk cassandra-6.0 cassandra-5.0 cassandra-4.1 cassandra-4.0 cassandra-3.11"
```

**Placement note:** `cassandra-6.0` is inserted immediately after `trunk` (the prerelease branch) so branch order reflects version recency, descending.

**Prerequisite:** The `cassandra-6.0` branch must exist and be publicly accessible in `apache/cassandra` before this change is applied. Until then, `trunk` continues to serve as the Cassandra 6 docs source.

---

## 2. `site-content/docker-entrypoint.sh`

### What changes

The `prepare_site_html_for_publication` function contains hardcoded `move_intree_document_directories` calls that copy versioned HTML into `content/doc/` and create symlink-equivalent aliases (`stable`, `latest`, and prerelease short names). Two lines must change:

1. The `5.0` line currently assigns `stable` and `latest` to version 5.0. It must be updated to assign those aliases to `6.0` instead, and a new 6.0 line added.
2. The `trunk` line currently maps the `trunk` prerelease build to `5.1`. When 6.0 ships, the next unreleased development cycle targets `6.x` (likely `6.1` or `7.0` depending on project cadence). The exact next prerelease version is **not yet determined** — see the trunk alias note at the end of this section.

### Current state

```bash
    move_intree_document_directories "3.11" "3.11.11" "3.11.12" "3.11.13" "3.11.14" "3.11.15" "3.11.16" "3.11.17" "3.11.18" "3.11.19"
    move_intree_document_directories "4.0" "4.0.0" "4.0.1" "4.0.2" "4.0.3" "4.0.4" "4.0.5" "4.0.6" "4.0.7" "4.0.8" "4.0.9" "4.0.10" "4.0.11" "4.0.12" "4.0.13" "4.0.14" "4.0.15" "4.0.16" "4.0.17"
    move_intree_document_directories "4.1" "4.1.0" "4.1.1" "4.1.2" "4.1.3" "4.1.4" "4.1.5" "4.1.6" "4.1.7" "4.1.8"
    move_intree_document_directories "5.0" "5.0.1" "5.0.2" "5.0.3" "5.0.4" "stable" "latest"
    move_intree_document_directories "trunk" "5.1"
```

Source: https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh (function `prepare_site_html_for_publication`)

### Required change

```diff
     move_intree_document_directories "3.11" "3.11.11" "3.11.12" "3.11.13" "3.11.14" "3.11.15" "3.11.16" "3.11.17" "3.11.18" "3.11.19"
     move_intree_document_directories "4.0" "4.0.0" "4.0.1" "4.0.2" "4.0.3" "4.0.4" "4.0.5" "4.0.6" "4.0.7" "4.0.8" "4.0.9" "4.0.10" "4.0.11" "4.0.12" "4.0.13" "4.0.14" "4.0.15" "4.0.16" "4.0.17"
     move_intree_document_directories "4.1" "4.1.0" "4.1.1" "4.1.2" "4.1.3" "4.1.4" "4.1.5" "4.1.6" "4.1.7" "4.1.8"
-    move_intree_document_directories "5.0" "5.0.1" "5.0.2" "5.0.3" "5.0.4" "stable" "latest"
-    move_intree_document_directories "trunk" "5.1"
+    move_intree_document_directories "5.0" "5.0.1" "5.0.2" "5.0.3" "5.0.4"
+    move_intree_document_directories "6.0" "6.0.0" "stable" "latest"
+    move_intree_document_directories "trunk" "<NEXT_PRERELEASE>"
```

**Point-release list note:** The `6.0` line above shows only `6.0.0` as a placeholder. As 6.0.x point releases ship, they must be appended to this list following the same pattern used for 4.x and 5.0. The person applying this patch should add all released 6.0.x versions at the time of application.

**Alias behavior after this change:**

| URL path | Resolves to |
|---|---|
| `/doc/stable/` | 6.0 content |
| `/doc/latest/` | 6.0 content |
| `/doc/6.0/` | 6.0 content |
| `/doc/6.0.0/` | 6.0.0 point release content |
| `/doc/5.0/` | 5.0 content (no longer `stable` or `latest`) |
| `/doc/trunk/` | next prerelease content |

### Trunk alias note

The `trunk` line currently maps `trunk` to `5.1`. After Cassandra 6.0 ships, `trunk` represents the next development cycle. The correct target alias for `trunk` depends on what the project determines as the next release label. **This value must be confirmed against `apache/cassandra` trunk's `doc/antora.yml` `version` field at the time of application.** The placeholder `<NEXT_PRERELEASE>` above must be replaced with that confirmed value (e.g., `6.1`, `7.0`, or whatever `trunk` declares).

Do not apply the trunk line with a placeholder — confirm the version first.

---

## 3. `site-content/site.template.yaml`

### What changes

Three AsciiDoc attributes in the `asciidoc.attributes` block encode the current major-version relationships used by the UI and in-page metadata. All three must be updated to reflect 6.0 as the new current release.

### Current state

```yaml
asciidoc:
  attributes:
    ...
    current-version: 4.1
    latest-version: 5.0
    previous-version: 4.0
    ...
```

Source: https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml

### Required change

```diff
-    current-version: 4.1
-    latest-version: 5.0
-    previous-version: 4.0
+    current-version: 6.0
+    latest-version: 6.0
+    previous-version: 5.0
```

**Attribute semantics:**

| Attribute | Before | After | Meaning |
|---|---|---|---|
| `latest-version` | `5.0` | `6.0` | The version shown as "latest" in the UI version picker and used in download links |
| `current-version` | `4.1` | `6.0` | The version shown as "current" in page metadata and used by doc cross-references |
| `previous-version` | `4.0` | `5.0` | The immediately preceding stable release, used for upgrade path references |

**Note on `current-version` vs `latest-version` divergence:** In the current file these two attributes hold different values (`4.1` and `5.0` respectively), reflecting a period where `4.1` was still documented as the current LTS target but `5.0` was the newest release. After the 6.0 wire-up both should be set to `6.0` since 6.0 becomes both the newest and the current recommended version. If the project maintainers want to distinguish these again in the future (e.g., for LTS designation), that is a separate decision and out of scope for this patch.

**`40_version` and `3x_version` are unchanged.** These attributes encode the 4.0 and 3.11 version strings used in legacy cross-references and do not need to change for a 6.0 release.

---

## Coordinated Application Timing

These three changes are interdependent and must ship together in a single website commit:

1. **Dockerfile** — adds `cassandra-6.0` to the Antora build input so content is fetched.
2. **docker-entrypoint.sh** — moves 6.0 content into the correct output paths and assigns `stable`/`latest` aliases.
3. **site.template.yaml** — aligns UI metadata with the new version reality.

Applying only (1) without (2) and (3) will fetch 6.0 content but serve it without aliases and with stale metadata. Applying only (2) without (1) will cause the alias copy to fail because there is no 6.0 content directory to copy from.

**Recommended apply sequence (per `cassandra6-version-wireup.md` rollout steps 4–7):**

1. Confirm `cassandra-6.0` branch exists and is publicly accessible in `apache/cassandra`.
2. Confirm the trunk prerelease alias target by checking `trunk`'s `doc/antora.yml`.
3. Apply all three changes in a single website PR.
4. Run a local Docker build (`./run.sh website build-site`) to verify no copy errors.
5. Render against `cassandra.staged.apache.org` and confirm `stable` and `latest` resolve to 6.0.
6. Obtain maintainer sign-off before promoting to production.

**Do not apply to the production website until the staged render is verified.** Rolling back a live alias change is disruptive to users who have bookmarked `/doc/stable/` or `/doc/latest/`.
