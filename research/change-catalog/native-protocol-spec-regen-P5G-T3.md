# Native Protocol Spec Regeneration — P5G-T3

**Task**: P5G-T3 — Regenerate and validate native protocol spec
**Date**: 2026-03-27
**Status**: COMPLETE — generation succeeded, output placed in workzone

---

## Generation Summary

### Environment

- Host: macOS (darwin/arm64)
- Docker/container: Podman Engine 5.7.0 (server), 5.8.1 (client) — available but NOT used by this script
- Go: 1.26.1 (script requires >= 1.23.1) — satisfied
- Cassandra repo: `/Users/patrick/local_projects/cassandra`, branch `trunk`

### Script Used

`/Users/patrick/local_projects/cassandra/doc/scripts/process-native-protocol-specs-in-docker.sh`

Despite its name, this script does NOT use Docker. It:
1. Checks that Go >= 1.23.1 is installed
2. Sparse-clones `apache/cassandra-website` to `$TMPDIR` to extract the `cqlprotodoc` Go tool
3. Builds `cqlprotodoc` using local Go
4. Runs `cqlprotodoc` against the three `.spec` files in `doc/`
5. Writes HTML attachments to `modules/cassandra/attachments/`
6. Generates the AsciiDoc summary page at `modules/cassandra/pages/reference/native-protocol.adoc`
7. Cleans up the temp clone and binary

### Run Result

Script exited with status 0 (success).

Parser warnings observed (not errors):
```
section "" exists in sections, but not in TOC
section "5.1" exists in sections, but not in TOC
... (etc. for sections 5.1–5.25 in v5, 6.1–6.23 in v4, 6.1–6.19 in v3)
```
These warnings are benign — they reflect sections defined in the spec body that are not in the TOC headers. The HTML files were generated successfully.

---

## Generated Output

### Files Produced (trunk)

| File | Size | Location |
|---|---|---|
| `native-protocol.adoc` | 1,959 bytes | `modules/cassandra/pages/reference/native-protocol.adoc` |
| `native_protocol_v3.html` | 58,704 bytes | `modules/cassandra/attachments/` |
| `native_protocol_v4.html` | 69,647 bytes | `modules/cassandra/attachments/` |
| `native_protocol_v5.html` | 86,880 bytes | `modules/cassandra/attachments/` |

### Workzone Copies

All four files copied to:
- `/Users/patrick/local_projects/cassandra6-docs-workzone/content/modules/cassandra/pages/reference/native-protocol.adoc`
- `/Users/patrick/local_projects/cassandra6-docs-workzone/content/modules/cassandra/attachments/native_protocol_v3.html`
- `/Users/patrick/local_projects/cassandra6-docs-workzone/content/modules/cassandra/attachments/native_protocol_v4.html`
- `/Users/patrick/local_projects/cassandra6-docs-workzone/content/modules/cassandra/attachments/native_protocol_v5.html`

### AsciiDoc Validity

The generated `native-protocol.adoc` is valid AsciiDoc. Structure:
- Title: `= Native Protocol Versions`
- Page attribute: `:page-layout: default`
- Three `== Native Protocol Version N` sections (v5, v4, v3, in reverse order)
- Each section uses a `++++` passthrough block with `include::cassandra:attachment$native_protocol_vN.html[...]`
- A closing `++++` passthrough block injects a `<script>` for in-page navigation

---

## Diff vs 5.0

The generated `.adoc` page does not exist on the `cassandra-5.0` branch (it is generated, not committed, on both branches). The diff below is based on the underlying `.spec` source files.

### Source: `git diff origin/cassandra-5.0..origin/trunk -- doc/native_protocol_v*.spec`

#### Nature of Changes

All three spec files (v3, v4, v5) received the same category of changes between 5.0 and trunk. **None of the changes are protocol-semantic additions.** They are entirely editorial/typo fixes:

**Typo and grammar corrections (all three specs):**
- `correspondance` → `correspondence` (v3, v4, v5)
- `consitency` → consistency phrasing revised (v3, v4, v5)
- `boostrapped` → `bootstrapped` (v3, v5)
- `avaivable` → `available` (v3, v4)
- `arithemtic` → `arithmetic` (v5)
- `represting` → `representing` (v5)
- `supercedes` → `supersedes` (v5)
- `occured`/`occured` → `occurred` (v3, v4, v5, multiple instances)
- `acqiure` → `acquire` (v4, v5)
- `reprepared` → `re-prepared` (v3, v4, v5)
- `REGISTERed` → `REGISTER-ed` (v4, v5)
- `timeouted` → `timed out` (v3)
- `reprensenting` → `representing` (v3)

**Identifier/naming normalizations (v4, v5):**
- `numfailures` → `num_failures` (v4, v5)
- `reasonmap` → `reason_map` (v4, v5)
- `failurecode` → `failure_code` (v4, v5)
- `ksname`/`tablename` → `ks_name`/`table_name` (v3, v5)
- `resultset metadata` → `result set metadata` (v5, multiple)
- `roundtrip` → `round trip` (v5)

**v5 vector section (new in v5, present on both branches, single fix):**
- `preced` → `precede`

#### Assessment: No Protocol-Semantic Changes

There are **no new message types, opcodes, flags, or error codes** between 5.0 and trunk in the native protocol specs. The changes are documentation quality improvements only.

**Accord-related additions**: Not present in the spec files on trunk as of this generation run. The Accord consensus protocol operates at a higher level and has not introduced a new native protocol version or protocol-level opcodes in the committed spec files.

---

## Validity Notes

- The generated `native-protocol.adoc` is not hand-editable — it must be regenerated from the script.
- The `.html` attachments are not source files — they are generated from the `.spec` files via `cqlprotodoc`.
- The spec files themselves (`native_protocol_v3.spec`, `native_protocol_v4.spec`, `native_protocol_v5.spec`) are the authoritative source of truth.
- These files are in `.gitignore` for the Cassandra repo and should not be committed there.

---

## Classification

| Surface | Classification | Disposition |
|---|---|---|
| `reference/native-protocol.adoc` | generated | `generated-review` |
| `attachments/native_protocol_v3.html` | generated | `generated-review` |
| `attachments/native_protocol_v4.html` | generated | `generated-review` |
| `attachments/native_protocol_v5.html` | generated | `generated-review` |

No new authored prose is required for this surface as a result of spec changes between 5.0 and trunk. The delta is editorial only.
