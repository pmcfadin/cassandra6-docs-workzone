# Publishing Model

Capture date: **2026-03-24**

## Live Version Behavior
- The public docs live at [`https://cassandra.apache.org/doc/`](https://cassandra.apache.org/doc/).
- On capture date, the version switcher exposes `website`, `trunk`, `5.0`, `4.1`, `4.0`, and `3.11`. Sources: [stable](https://cassandra.apache.org/doc/stable/), [trunk](https://cassandra.apache.org/doc/trunk/).
- On capture date, `stable` and `latest` both point to `5.0`; `trunk` is prerelease. Sources: [stable](https://cassandra.apache.org/doc/stable/), [latest](https://cassandra.apache.org/doc/latest/), [trunk](https://cassandra.apache.org/doc/trunk/).

## Build Inputs
- The website build container currently defaults Cassandra content sources to `trunk cassandra-5.0 cassandra-4.1 cassandra-4.0 cassandra-3.11`. Source: [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile).
- The same Dockerfile comment warns that changing the branch list also requires edits in `prepare_site_html_for_publication`, which means major-version rollout is partly manual. Source: [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile).
- The site template hardcodes major-version attributes such as `latest-version: 5.0`, `current-version: 4.1`, and `previous-version: 4.0`. Source: [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml).

## How Rendered Output Becomes Public URLs
- `site-content/docker-entrypoint.sh` copies rendered HTML from `site-content/build/html` into `content/` and creates `content/doc/` for public documentation URLs. Source: [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).
- The publish-prep step explicitly remaps version directories:
  - `3.11` to point-release aliases
  - `4.0` to point-release aliases
  - `4.1` to point-release aliases
  - `5.0` to point-release aliases plus `stable` and `latest`
  - `trunk` to `5.1`
  Source: [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).
- This means public `/doc/*` URLs are materialized during publish preparation rather than dynamically resolved at request time. Source: [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).

## Current Release Metadata Feed
- `site_yaml_generator.py` reads the Apache downloads index and populates release names and dates in the generated `site.yaml`. Sources: [`site-content/bin/site_yaml_generator.py`](https://github.com/apache/cassandra-website/blob/trunk/site-content/bin/site_yaml_generator.py), [downloads index](https://downloads.apache.org/cassandra/).
- This updates point-release metadata, but it does not replace the hardcoded major-version source list or alias rules. Sources: [`site-content/bin/site_yaml_generator.py`](https://github.com/apache/cassandra-website/blob/trunk/site-content/bin/site_yaml_generator.py), [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).

## Cassandra 6 Implication
- Adding Cassandra 6 will require coordinated updates in both repos:
  - a Cassandra branch with `doc/antora.yml` set to `6.0`
  - website build inputs updated to include `cassandra-6.0`
  - publish alias rules updated so `6.0` becomes `stable` and `latest`
  - site template metadata updated so the major-version labels match reality
  Sources: [`trunk/doc/antora.yml`](https://github.com/apache/cassandra/blob/trunk/doc/antora.yml), [`cassandra-5.0/doc/antora.yml`](https://github.com/apache/cassandra/blob/cassandra-5.0/doc/antora.yml), [`site-content/Dockerfile`](https://github.com/apache/cassandra-website/blob/trunk/site-content/Dockerfile), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh), [`site-content/site.template.yaml`](https://github.com/apache/cassandra-website/blob/trunk/site-content/site.template.yaml).

## Working Rule For This Workspace
- Until a public `cassandra-6.0` branch exists, use `trunk` as the discovery target for Cassandra 6 docs research.
- Once `cassandra-6.0` exists, switch default discovery and comparison work from `trunk` to `cassandra-6.0` without changing the rest of the process.
