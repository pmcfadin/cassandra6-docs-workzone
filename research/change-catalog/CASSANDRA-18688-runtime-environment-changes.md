# CASSANDRA-18688 + CASSANDRA-16565 Runtime environment changes

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
This file consolidates two related changes to Cassandra's startup and runtime environment behavior:

**CASSANDRA-18688** adds an explicit JDK version check at startup. Cassandra will now refuse to start if the detected JDK version is not in the supported set (`11`, `17`, `21` on trunk). Operators who need to run on an unsupported (newer) JDK can bypass this check by setting the environment variable `CASSANDRA_JDK_UNSUPPORTED` to any non-empty value, which triggers a startup warning instead of a hard failure.

**CASSANDRA-16565** removes the long-standing dependency on the Sigar native library and replaces it with OSHI (Operating System and Hardware Information), a pure-Java library. Sigar required a native shared library (`sigar-bin`) and was configured via a JVM system property (`-Djava.library.path=$CASSANDRA_HOME/lib/sigar-bin`). That JVM option has been removed from `cassandra-env.sh`. System information (open file limits, process limits, address space) is now gathered by the new `SystemInfo` class using OSHI's cross-platform API.

## Discovery Source
- `CHANGES.txt` reference (18688): "Limit cassandra startup to supported JDKs (CASSANDRA-18688)"
- `CHANGES.txt` reference (16565): "Remove dependency on Sigar in favor of OSHI (CASSANDRA-16565)"
- Related JIRAs: CASSANDRA-18688, CASSANDRA-16565

## Why It Matters
- User-visible effect (18688): Cassandra will fail at startup on unsupported JDK versions (any version other than 11, 17, or 21 on trunk). This is a breaking change for operators running on JDK 8 or a JDK version newer than 21 without the override. The error message tells operators what to do: set `CASSANDRA_JDK_UNSUPPORTED=true` to override.
- User-visible effect (16565): The `lib/sigar-bin/` directory and native library files (`libsigar-*.so`, `sigar-*.dll`, etc.) are no longer included in or required by the Cassandra distribution. The JVM option `-Djava.library.path=.../sigar-bin` has been removed from `cassandra-env.sh`. Scripts or automation that referenced sigar-bin paths will need to be updated.
- Operational effect (18688): Predictable and early failure on unsupported JDKs prevents subtle runtime issues that could arise from running on a JDK with unexpected behavior.
- Operational effect (16565): OS resource checks (open file limits, process limits, address space) at startup are now performed using OSHI, a maintained pure-Java library, eliminating native library loading complexity and Sigar's maintenance debt.
- Upgrade or compatibility effect (18688): Operators currently running Cassandra on JDK 8 must upgrade to 11, 17, or 21. Operators running on a pre-release JDK (e.g., JDK 22+) who previously saw no barrier will now receive a startup error unless `CASSANDRA_JDK_UNSUPPORTED` is set.
- Upgrade or compatibility effect (16565): Any custom startup scripts, Ansible/Puppet/Chef roles, or container images that configure `java.library.path` for Sigar should remove that configuration. The `lib/sigar-bin/` path no longer exists in the distribution.
- Configuration or tooling effect (18688): New environment variable `CASSANDRA_JDK_UNSUPPORTED`. No YAML changes.
- Configuration or tooling effect (16565): Line removed from `cassandra-env.sh`: `JVM_OPTS="$JVM_OPTS -Djava.library.path=$CASSANDRA_HOME/lib/sigar-bin"`.

## Source Evidence

### CASSANDRA-18688 — JDK version enforcement
- Relevant config paths:
  - `bin/cassandra.in.sh` — contains the version check logic. Supported versions defined as: `java_versions_supported="11 17 21"`.
  - Also updated in `debian/patches/cassandra_in.sh_dirs.diff`, `redhat/cassandra.in.sh`, `tools/bin/cassandra.in.sh`.
- Relevant code paths (shell):
  - `bin/cassandra.in.sh`:
    - Detects `JAVA_VERSION` by parsing `java -version` output.
    - Iterates `java_versions_supported` ("11 17 21") to set `supported` flag.
    - If `supported=0` and `CASSANDRA_JDK_UNSUPPORTED` is unset: prints error and calls `exit 1`.
    - If `supported=0` and `CASSANDRA_JDK_UNSUPPORTED` is set: prints a warning block ("Warning! You are using JDK...") and continues.
  - Error message text: `"Unsupported Java $JAVA_VERSION. Supported are $java_version_string"` followed by `"If you would like to test with newer Java versions set CASSANDRA_JDK_UNSUPPORTED to any value (for example, CASSANDRA_JDK_UNSUPPORTED=true). Unset the parameter for default behavior"`
- Relevant test paths: No dedicated test file identified; shell-script behavior is not typically unit-tested.

### CASSANDRA-16565 — Sigar to OSHI migration
- Relevant config paths:
  - `conf/cassandra-env.sh` — removes the line: `JVM_OPTS="$JVM_OPTS -Djava.library.path=$CASSANDRA_HOME/lib/sigar-bin"`.
- Relevant code paths:
  - `src/java/org/apache/cassandra/utils/SystemInfo.java` — **new class** that wraps OSHI (`oshi.SystemInfo`, `oshi.PlatformEnum`) to provide `isDegraded()`, `getMaxProcess()`, `getMaxOpenFiles()`, `getAddressSpace()`, `platform()`, `getKernelVersion()`, etc.
  - `src/java/org/apache/cassandra/utils/SigarLibrary.java` — **deleted** in this commit (previously `src/java/org/apache/cassandra/utils/SigarLibrary.java`, no longer present on trunk).
  - `src/java/org/apache/cassandra/utils/FBUtilities.java` — `getSystemInfo()` now returns a `SystemInfo` instance (backed by OSHI) instead of calling `SigarLibrary`.
  - `src/java/org/apache/cassandra/service/StartupChecks.java` — `checkMaxMapCount`, `checkOpenFiles`, etc. call `FBUtilities.getSystemInfo().isDegraded()`.
  - `src/java/org/apache/cassandra/config/CassandraRelevantProperties.java` — Sigar-related system property removed.
- Relevant test paths:
  - `test/unit/org/apache/cassandra/utils/SystemInfoTest.java` — new unit tests for the `SystemInfo` class
  - `test/unit/org/apache/cassandra/utils/FBUtilitiesTest.java`
  - `test/unit/org/apache/cassandra/service/StartupChecksTest.java`
  - `test/distributed/org/apache/cassandra/distributed/test/ResourceLeakTest.java`

## What Changed

### CASSANDRA-18688
1. `bin/cassandra.in.sh` (and its platform-specific copies) adds a JDK version enforcement block:
   - Parses `java -version` output to extract the major version.
   - Compares against `java_versions_supported="11 17 21"` (mirrors `java.supported` in `build.xml`).
   - Exits with a non-zero code if unsupported and `CASSANDRA_JDK_UNSUPPORTED` is unset.
   - Prints a warning banner and continues if `CASSANDRA_JDK_UNSUPPORTED` is set to any value.
2. No changes to `cassandra.yaml` or Java code.

### CASSANDRA-16565
1. `SigarLibrary.java` deleted; Sigar native library (`lib/sigar-bin/`) removed from the distribution.
2. `SystemInfo.java` added as a pure-Java replacement using the OSHI library (`com.github.oshi:oshi-core`).
3. `cassandra-env.sh` removes the Sigar `java.library.path` JVM option.
4. All startup resource checks (`isDegraded()`, etc.) now use OSHI via `FBUtilities.getSystemInfo()`.

## Docs Impact
- Existing pages likely affected:
  - Any Cassandra installation or requirements page that mentions supported JDK versions needs to document the hard-stop behavior and the `CASSANDRA_JDK_UNSUPPORTED` override. Currently the "Getting Started" / installation docs list supported JDKs; this is now enforced at startup.
  - Any page that previously mentioned Sigar or `sigar-bin` (installation, troubleshooting, OS configuration) should be updated to remove those references.
  - `doc/modules/cassandra/pages/getting-started/` — likely has JDK prerequisites documentation.
  - `doc/modules/cassandra/pages/managing/operating/` — any OS tuning or startup configuration page that mentioned the native library path.
- New pages likely needed: None.
- Audience home: Operators
- Authored or generated: Likely authored content in the getting-started and operating sections.
- Technical review needed from: Infra / packaging team for Sigar removal impact assessment.

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead
- Publish blocker: no

## Open Questions
- Which existing docs pages (if any) mention Sigar or `sigar-bin` explicitly? A delta-catalog search for the term "sigar" in the `cassandra-5.0` docs vs trunk should confirm.
- Are there any installation docs that list JDK prerequisites? If so, they should be updated to note that startup now enforces these requirements automatically.
- Is `CASSANDRA_JDK_UNSUPPORTED` intended only for testing/development, or is it a supported operator escape hatch? The error message says "test with newer Java versions" suggesting testing intent — the docs should reflect this.
- With trunk supporting JDK 11, 17, and 21, what does the cassandra-6.0 release target? This may change the documented supported JDK list before GA.

## Next Research Steps
- Run a Grep for "sigar" across the existing `cassandra-5.0` branch docs to identify pages requiring cleanup.
- Confirm the supported JDK list for the cassandra-6.0 release target (may shift from the trunk `"11 17 21"` list).
- Find and update (or create) the JDK requirements / installation prerequisites page.

## Notes
- CASSANDRA-18688 commit: `89e33a16ea` (trunk). Author: Shylaja Kokoori (Intel). Reviewers: Berenguer Blasi, Ekaterina Dimitrova, Michael Semb Wever, Stefan Miklosovic. Date: August 9 2023.
- CASSANDRA-16565 commit: `5d46ff2796` (trunk). Author: Claude Warren (Aiven), co-author Stefan Miklosovic. Reviewers: Stefan Miklosovic, Jacek Lewandowski, Michael Semb Wever. Date: October 25 2023.
- The supported JDK list in `cassandra.in.sh` reads: `java_versions_supported="11 17 21"` and mirrors the `java.supported` variable in `build.xml`.
- OSHI (`oshi-core`) is a well-maintained open-source library that replaced Sigar (which had not been actively maintained). OSHI provides cross-platform system information via a pure-Java API, removing the need for native shared libraries.
- `SystemInfo` uses `oshi.PlatformEnum` to conditionally execute Linux-specific checks (e.g., reading `/proc/<pid>/limits` for process and file-descriptor limits).
