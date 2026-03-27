# Patch: `doc/antora.yml` for `cassandra-6.0` branch

Prepared: **2026-03-27**
Target repo: `apache/cassandra`
Target branch (to be created): `cassandra-6.0`
Target file: `doc/antora.yml`

---

## When to Apply

Apply this patch **after** the `cassandra-6.0` branch is cut from `trunk` in
`apache/cassandra`. Do not apply to `trunk`; `trunk` must retain
`prerelease: true` and its own version string as it advances toward the next
unreleased cycle.

The patch should land in the same commit that cuts or formally names the branch
as the `6.0` release-doc source. It must precede any update to
`apache/cassandra-website` that adds `cassandra-6.0` to the Antora content
source list (see `runbooks/cassandra6-version-wireup.md`, item 4).

---

## Current State: `trunk` (fetched 2026-03-27)

Source: https://raw.githubusercontent.com/apache/cassandra/trunk/doc/antora.yml

```yaml
name: Cassandra
version: 'trunk'
display_version: 'trunk'
prerelease: true
asciidoc:
  attributes:
    cass_url: 'http://cassandra.apache.org/'
    cass-50: 'Cassandra 5.0'
    cassandra: 'Cassandra'
    product: 'Apache Cassandra'

nav:
- modules/ROOT/nav.adoc
- modules/cassandra/nav.adoc
```

---

## Reference State: `cassandra-5.0` (fetched 2026-03-27)

Source: https://raw.githubusercontent.com/apache/cassandra/cassandra-5.0/doc/antora.yml

```yaml
name: Cassandra
version: '5.0'
display_version: '5.0'
asciidoc:
  attributes:
    cass_url: 'http://cassandra.apache.org/'
    cass-50: 'Cassandra 5.0'
    cassandra: 'Cassandra'
    product: 'Apache Cassandra'

nav:
- modules/ROOT/nav.adoc
- modules/cassandra/nav.adoc
```

Key observations from `cassandra-5.0`:
- `version` and `display_version` are set to the numeric release string.
- `prerelease` key is absent entirely (not `false` — it is omitted).
- The `asciidoc.attributes` block is otherwise identical to `trunk`.

---

## Target State: `cassandra-6.0`

```yaml
name: Cassandra
version: '6.0'
display_version: '6.0'
asciidoc:
  attributes:
    cass_url: 'http://cassandra.apache.org/'
    cass-50: 'Cassandra 5.0'
    cassandra: 'Cassandra'
    product: 'Apache Cassandra'

nav:
- modules/ROOT/nav.adoc
- modules/cassandra/nav.adoc
```

---

## Exact Diff

Apply this unified diff to `doc/antora.yml` on the `cassandra-6.0` branch:

```diff
--- a/doc/antora.yml
+++ b/doc/antora.yml
@@ -1,6 +1,5 @@
 name: Cassandra
-version: 'trunk'
-display_version: 'trunk'
-prerelease: true
+version: '6.0'
+display_version: '6.0'
 asciidoc:
   attributes:
```

Three lines change; the rest of the file is untouched.

---

## Field-by-Field Rationale

### `version`

Antora component descriptor spec requires this to be the version string that
Antora uses to construct page URLs and the version selector. For a release
branch the value must be the numeric release string, e.g. `'6.0'`. Quoting is
required when the value could be parsed as a number (single digits, decimals).

Trunk currently uses `'trunk'` as a symbolic version identifier. The
`cassandra-6.0` branch must replace this with `'6.0'` so that Antora routes
pages under `/cassandra/6.0/...` rather than `/cassandra/trunk/...`.

### `display_version`

An optional Antora field that overrides the string shown in the version
selector UI. When absent, Antora falls back to `version`. Setting it explicitly
to `'6.0'` matches the `cassandra-5.0` pattern and ensures the UI label is
human-readable regardless of how the internal version key evolves.

### `prerelease`

The Antora component descriptor accepts a boolean or string value for
`prerelease`. When `true` (or any non-empty string), Antora marks the version
as a prerelease in the version selector and some UI themes apply a visual
indicator.

Policy (from `runbooks/cassandra6-version-wireup.md`, item 2):

> Remove `prerelease: true` when the release branch becomes the public
> released-doc source.

The correct action is to **omit** the key entirely, not set it to `false`.
This matches the `cassandra-5.0` pattern and avoids an explicit `false` value
that could be misread as an intentional override. If an early-access or
release-candidate phase is desired before the official release, the field can
be set to `'-rc1'` (or another prerelease suffix string) and removed when GA
ships.

---

## Antora Component Descriptor Spec Validation

| Field | Spec requirement | This patch |
|---|---|---|
| `name` | Required. ASCII word characters, hyphens, underscores. Must be consistent across all versions of the same component. | Unchanged: `Cassandra`. Valid. |
| `version` | Required (Antora 3+). String or `~` (versionless). Quoted strings recommended for numeric values. | Set to `'6.0'`. Quoted. Valid. |
| `display_version` | Optional. Arbitrary display string for UI. Defaults to `version` if absent. | Set to `'6.0'`. Consistent with `version`. Valid. |
| `prerelease` | Optional. Boolean `true`/`false` or string suffix. Omitting is equivalent to `false`. | Omitted (key removed). Matches released-branch convention. Valid. |
| `asciidoc.attributes` | Optional map. Arbitrary AsciiDoc attribute key-value pairs passed to the converter. | Unchanged. Valid. |
| `nav` | Optional list of nav file paths relative to the component root. | Unchanged. Valid. |

Spec reference: https://docs.antora.org/antora/latest/component-version-descriptor/

---

## AsciiDoc Attributes: No Changes Required at Branch Cut

The `asciidoc.attributes` block includes `cass-50: 'Cassandra 5.0'`. This
attribute is used in cross-reference prose pointing to 5.0 docs and does not
describe the current component version — it is a convenience attribute for
content that references the previous major. It should remain as-is at branch
cut.

If Cassandra 6.0 content needs an equivalent `cass-60` attribute for
self-referencing prose, that is a content-level change and is out of scope for
this metadata patch.

---

## Checklist Before Applying

- [ ] `cassandra-6.0` branch exists in `apache/cassandra`
- [ ] Generated-doc workflows (`ant gen-asciidoc`) succeed on `cassandra-6.0`
- [ ] This patch has been reviewed by a committer on the Cassandra docs list
- [ ] The `apache/cassandra-website` patch to add `cassandra-6.0` to content
      sources is staged and ready (see `runbooks/cassandra6-version-wireup.md`,
      item 4) — apply the website patch immediately after this one
- [ ] Local Antora build with `cassandra-6.0` as a content source produces
      pages under `/cassandra/6.0/...`
- [ ] Version selector shows `6.0` without a prerelease indicator

---

## Related Runbooks and Patches

- `runbooks/cassandra6-version-wireup.md` — full version wire-up sequence,
  items 1–3 are prerequisites for this patch; items 4–6 follow it
- Future: `runbooks/patches/cassandra-website-version-wireup-patch.md` —
  website-side changes (Dockerfile, docker-entrypoint.sh, site.template.yaml)
