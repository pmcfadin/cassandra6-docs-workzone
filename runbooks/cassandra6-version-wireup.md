# Cassandra 6 Version Wire-Up

Capture date: **2026-03-24**

## Goal
Introduce Cassandra 6 into the existing versioned docs system without breaking current `stable`, `latest`, point-release aliases, or the prerelease flow.

## Current Major-Version Touchpoints
### In `apache/cassandra`
- `doc/antora.yml` controls the component name, version, display version, and prerelease flag. Sources: [`trunk/doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml), [`cassandra-5.0/doc/antora.yml`](https://github.com/apache/cassandra/blob/cassandra-5.0/doc/antora.yml).
- Generated docs are produced by `ant gen-asciidoc` / `make gen-asciidoc` and must be considered before any full website render. Sources: [`doc/README.md`](https://github.com/apache/cassandra/blob/trunk/doc/README.md), [`doc/Makefile`](https://github.com/apache/cassandra/blob/trunk/doc/Makefile), [`build.xml`](https://github.com/apache/cassandra/blob/trunk/build.xml).

### In `apache/cassandra-website`
- `site-content/Dockerfile` hardcodes the Cassandra branch list for Antora content sources. Source: [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile).
- `site-content/docker-entrypoint.sh` hardcodes version directory copy and alias rules, including `5.0 -> stable/latest` and `trunk -> 5.1`. Source: [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).
- `site-content/site.template.yaml` hardcodes major-version attributes such as `latest-version`, `current-version`, and `previous-version`. Source: [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml).

## Required Cassandra 6 Changes
1. Create or adopt a public `cassandra-6.0` branch in `apache/cassandra`.
2. Update `doc/antora.yml` in that branch to:
   - `version: '6.0'`
   - `display_version: '6.0'`
   - remove `prerelease: true` when the release branch becomes the public released-doc source
3. Ensure generated-doc workflows succeed on that branch with the expected JDK and build assumptions.
4. Add `cassandra-6.0` to `ANTORA_CONTENT_SOURCES_CASSANDRA_BRANCHES`.
5. Update publish alias rules so:
   - `6.0` becomes `stable`
   - `6.0` becomes `latest`
   - `trunk` becomes the next prerelease alias instead of `5.1`
6. Update `site.template.yaml` major-version attributes so the UI and page metadata match the new release reality.

Sources: [`cassandra-5.0/doc/antora.yml`](https://github.com/apache/cassandra/blob/cassandra-5.0/doc/antora.yml), [`trunk/doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml), [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh), [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml).

## Recommended Rollout Sequence
1. Stabilize Cassandra 6 source docs on `trunk`.
2. Cut or identify the `cassandra-6.0` branch.
3. Re-run generated-doc workflows on `cassandra-6.0`.
4. Update website branch inputs and alias logic in a coordinated website change.
5. Render locally against the Cassandra 6 branch and verify version selector output.
6. Validate on `cassandra.staged.apache.org`.
7. Promote staged to production only after maintainers confirm that `stable` and `latest` now reflect `6.0`.

Sources: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).

## Branch-Transition Rule
- Until `cassandra-6.0` exists publicly, use `trunk` as the Cassandra 6 discovery source for research and drafting.
- Once `cassandra-6.0` exists, update this workspace’s default source pack and inventory comparison target from `trunk` to `cassandra-6.0`.
- Do not redesign the workflow when that happens; only swap the default branch reference.

## Acceptance Checks
- Live `stable` and `latest` show `6.0`.
- Live `trunk` remains prerelease and does not masquerade as the released branch.
- `site.yaml` generation includes `6.0` content and correct major-version metadata.
- Generated Cassandra 6 pages are available in the rendered output before staging.
- No legacy version aliases are dropped unintentionally.
