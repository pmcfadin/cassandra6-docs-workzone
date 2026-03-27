# Build, Preview, Publish Runbook

Capture date: **2026-03-24**

## Purpose
This runbook records the current documented path for building and previewing Cassandra docs locally and the current publish path for landing changes on `cassandra.apache.org`.

## Local Build Prerequisites
- Docker is required for the supported local website/doc build flow. Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).
- Git is required if you are working from local clones. Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

## Local Commands
### Build the website container
```bash
git clone https://github.com/apache/cassandra-website.git
cd cassandra-website
./run.sh website container
```
Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

### Build website-only content
```bash
./run.sh website build
```
- Output goes to `site-content/build/html/`.
- Use this when editing website-owned content only.
Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

### Build website plus Cassandra docs from a local Cassandra checkout
```bash
git clone https://github.com/apache/cassandra.git
cd cassandra
# make or switch your branch here
cd ../cassandra-website
./run.sh website build -g -u cassandra:/path/to/cassandra -b cassandra:<branch>
```
- `-g` generates Cassandra AsciiDoc before the site render.
- Use a local Cassandra checkout when you want access to generated files and branch-local changes.
Sources: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md), [`run.sh`](https://github.com/apache/cassandra-website/blob/trunk/run.sh).

### Preview locally with a watcher
```bash
./run.sh website preview
```
- Preview serves content at `http://localhost:5151`.
- The preview command supports the same source-selection options as `build`.
Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

### Generate Cassandra docs without rendering the website
```bash
./run.sh website docs -u cassandra:/path/to/cassandra -b cassandra:trunk
```
- This is the right entrypoint when validating generated AsciiDoc outputs before a full site render.
Source: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md).

## Cassandra-Side Generation Commands
Run these from the Cassandra repo when validating machine-derived content:
```bash
ant gen-asciidoc
```
or
```bash
cd doc
make gen-asciidoc
```
- `gen-asciidoc` drives nodetool docs, `cassandra.yaml` conversion, and native protocol processing.
Sources: [`doc/README.md`](https://github.com/apache/cassandra/blob/trunk/doc/README.md), [`doc/Makefile`](https://github.com/apache/cassandra/blob/trunk/doc/Makefile), [`build.xml`](https://github.com/apache/cassandra/blob/trunk/build.xml).

## What The Container Actually Does
- It clones or copies a Cassandra repo to a working directory.
- It checks out each requested version branch.
- It selects the needed JDK based on branch metadata.
- It runs `ant gen-asciidoc`.
- When multiple branches are requested, it can commit generated outputs into the working copy so Antora can render versioned docs from each branch.
Source: [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh).

## Publish Path Today
1. Make and validate changes locally.
2. Link the work to the relevant JIRA or review record before requesting merge for any substantial change.
3. Commit to a fork/branch and open a PR against `apache/cassandra-website` or `apache/cassandra`, depending on where the change lives.
4. Wait for staged deployment at [`https://cassandra.staged.apache.org/`](https://cassandra.staged.apache.org/).
5. Perform staging validation and record signoff.
6. Merge `asf-staging` to `asf-site`.
7. Verify production at [`https://cassandra.apache.org/`](https://cassandra.apache.org/).

Sources: [`cassandra-website/README.md`](https://github.com/apache/cassandra-website/blob/trunk/README.md), [`CONTRIBUTING.md`](https://github.com/apache/cassandra/blob/trunk/CONTRIBUTING.md), [`development/patches.adoc`](https://github.com/apache/cassandra-website/blob/trunk/site-content/source/modules/ROOT/pages/development/patches.adoc).

## Governance Hooks
- Use JIRA for all substantial Cassandra 6 docs work, especially multi-page rewrites, generated-doc workflow changes, and version-wire changes.
- Keep PR review, JIRA review state, and staging approval aligned before publish promotion.
- See [`runbooks/governance-review-and-staging.md`](governance-review-and-staging.md) for the required review model.

## Checks Before Calling A Build Good
- Generated docs run completed cleanly for the targeted branch.
- Antora render completed and output exists in `site-content/build/html/`.
- Version selector shows the expected versions.
- Nav, xrefs, and admonitions render correctly in the built output.
- No website alias logic is accidentally pointing a prerelease branch at `stable` or `latest`.
- Required JIRA/reviewer/staging approvals are recorded for major changes.

Sources: [`run.sh`](https://github.com/apache/cassandra-website/blob/trunk/run.sh), [`site-content/docker-entrypoint.sh`](https://github.com/apache/cassandra-website/blob/trunk/site-content/docker-entrypoint.sh), [stable](https://cassandra.apache.org/doc/stable/), [trunk](https://cassandra.apache.org/doc/trunk/).
