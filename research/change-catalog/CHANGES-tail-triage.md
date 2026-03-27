# CHANGES.txt Tail Triage

Triage date: **2026-03-24**

## Purpose
Audit trail for all 6.0-alpha1 CHANGES.txt JIRAs not covered by the primary NEWS.txt research pass. Each JIRA is classified as likely-doc-worthy, not-doc-worthy, or uncertain with a one-line reason.

## Counts
- Already covered by research files: 81 unique JIRAs across 39 research files
- Likely-doc-worthy (this file): 90 JIRAs
- Not-doc-worthy (this file): 143 JIRAs
- Uncertain (this file): 2 JIRAs
- **Total triaged in this file**: 235 JIRAs
- **Total 6.0-alpha1 JIRAs accounted for**: 316 (81 researched + 235 triaged)

Note: The 81 researched JIRAs and 235 triaged JIRAs have minimal overlap. The "Already Covered by Primary Research" subsection in not-doc-worthy lists 9 JIRAs that appeared in CHANGES.txt and are related to primary-researched features but were not in the original exclusion list.

---

## Likely-Doc-Worthy (High Priority — New Features / CQL / Config Changes)

These items introduce new user-visible capabilities, CQL syntax, or configuration and should be added to the tracker for potential research:

### New CQL Syntax / Query Capabilities
- CASSANDRA-19604: BETWEEN operator in WHERE clauses
- CASSANDRA-19688: SAI support for BETWEEN operator
- CASSANDRA-18584: NOT operators in WHERE clauses (three-valued logic)
- CASSANDRA-17198: LIKE expressions in filtering queries
- CASSANDRA-20477: CAS support for -= on numeric types
- CASSANDRA-19417: LIST SUPERUSERS CQL statement
- CASSANDRA-20857: BEGIN TRANSACTION multi-partition mutations (covered partially by Accord research)
- CASSANDRA-20883: Binary protocol multiple conditions for transactions (covered partially by Accord research)

### New Virtual Tables / Observability
- CASSANDRA-13001: system_views.slow_queries table
- CASSANDRA-20858: system_views.uncaught_exceptions table
- CASSANDRA-20161: system_views.partition_key_statistics table
- CASSANDRA-14572: All dropwizard metrics exposed in virtual tables
- CASSANDRA-20466: min/max/mean/percentiles in timer metrics vtable
- CASSANDRA-19486: Enriched system_views.pending_hints with sizes
- CASSANDRA-20499: Additional metrics around hints
- CASSANDRA-20132: PurgeableTombstoneScannedHistogram metric + tracing event
- CASSANDRA-20502: SSTableIntervalTree latency metric
- CASSANDRA-20864: Prepared Statement Cache Size metric (bytes)
- CASSANDRA-13890: Current compaction throughput in nodetool
- CASSANDRA-17062: Auth cache metrics via JMX
- CASSANDRA-20870: StorageService.dropPreparedStatements via JMX
- CASSANDRA-19447: Bootstrap process Dropwizard metrics

### New Nodetool / Tool Options
- CASSANDRA-19581: nodetool command to unregister LEFT nodes
- CASSANDRA-20525: nodetool command to dump cluster_metadata_log/directory
- CASSANDRA-20482: nodetool command to abort failed cms initialize
- CASSANDRA-20151: Snapshot filtering on keyspace/table/name in listsnapshots
- CASSANDRA-20104: Sorting of nodetool status output
- CASSANDRA-19022: nodetool gcstats human-readable units + formats
- CASSANDRA-19771: JSON/YAML output for nodetool gcstats
- CASSANDRA-19721: JVM version + build date in nodetool version -v
- CASSANDRA-19671: Total keyspace space in nodetool tablestats
- CASSANDRA-20820: UCS Level info in nodetool tablestats
- CASSANDRA-20940: Dictionary memory usage in nodetool tablestats
- CASSANDRA-20015: -H option in nodetool compactionhistory (already in compactionhistory research)
- CASSANDRA-19104: Standardized nodetool tablestats data unit formatting
- CASSANDRA-19015: Consistent significant digits in nodetool tablestats
- CASSANDRA-19939: sstabledump tombstones-only option
- CASSANDRA-19216: nodetool reconfigurecms sync by default + --cancel
- CASSANDRA-19393: nodetool cms commands grouped into single command group

### Configuration / Security / Operations
- CASSANDRA-20749: Override arbitrary settings via environment variables
- CASSANDRA-19532: TriggersPolicy to allow operators to disable triggers
- CASSANDRA-20980: Separate GCInspector thresholds for concurrent GC events
- CASSANDRA-19792: Configurable log format for Audit Logs
- CASSANDRA-20128: Audit logging for JMX operations
- CASSANDRA-18951: MutualTlsAuthenticator certificate validity period restriction
- CASSANDRA-13428: keystore_password_file and truststore_password_file options
- CASSANDRA-20071: Optionally prevent tombstone purging during repair
- CASSANDRA-20457: Limit held heap dumps
- CASSANDRA-20978: Additional JVM shutdown parameter for log shutdown
- CASSANDRA-19385: Periodically disconnect revoked/LOGIN=FALSE roles
- CASSANDRA-18857: CQL cert auth without AUTHENTICATE request
- CASSANDRA-20614: Fail startup when custom disk error handler fails
- CASSANDRA-20452: Don't fail startup with disabled materialized views
- CASSANDRA-18688: Limit startup to supported JDKs (CASSANDRA_JDK_UNSUPPORTED)
- CASSANDRA-16565: Remove Sigar dependency in favor of OSHI
- CASSANDRA-19787: CentOS 7 noboolean RPM packages removed

### CQLSH Improvements
- CASSANDRA-18861: ELAPSED command in cqlsh
- CASSANDRA-19631: Autocompletion for built-in functions
- CASSANDRA-20021: Autocompletion for identity mapping
- CASSANDRA-19956: Ignore repeated semicolons
- CASSANDRA-18879: Modernized datetime conversions
- CASSANDRA-18787: Cleaned up cql_version handling

### Upgrade / Behavior Changes
- CASSANDRA-21174: Forbid upgrading to version that can't read existing log entries
- CASSANDRA-20145: Support downgrading after CMS initialized
- CASSANDRA-20154: BETWEEN where token(Y) > token(Z) correctness fix
- CASSANDRA-20570: LCS sstable_size_in_mb default fix
- CASSANDRA-18509: single_sstable_uplevel enabled by default for LCS
- CASSANDRA-20586: Increased default auto_repair.sstable_upper_threshold
- CASSANDRA-20171: Grant permission on system_views now possible
- CASSANDRA-20402: IndexBuildInProgressException instead of IndexNotAvailableException
- CASSANDRA-21061: Accord write rejections now INVALID, not server error
- CASSANDRA-20318: Prepared statements invalidated on TableMetadata changes
- CASSANDRA-20328: sstableloader moved to own artifact
- CASSANDRA-20429: Logback 1.5.18 / SLF4J 2.0.17 upgrade

### ZSTD Dictionary (supplements primary research)
- CASSANDRA-21147: compaction_read_disk_access_mode for cursor-based compaction
- CASSANDRA-21194: Hardened max dictionary/sample size values
- CASSANDRA-21192: Guardrail for minimum training frequency
- CASSANDRA-21179: Minimum time check for dictionary train/import
- CASSANDRA-21178: created_at column in compression_dictionaries
- CASSANDRA-21169: Override compaction strategy parameters at startup
- CASSANDRA-21157: Detect and remove orphaned compression dictionaries

### Miscellaneous
- CASSANDRA-17258: Client warnings when writing to large partitions
- CASSANDRA-20581: Improved AutoRepair observability (expected vs actual bytes)
- CASSANDRA-20363: Pluggable DiskErrorsHandler
- CASSANDRA-19812: Clearer commitlog_disk_access_mode error messages
- CASSANDRA-21048: Log queries scanning too many SSTables
- CASSANDRA-19669: Audit log identity for mTLS connections fix
- CASSANDRA-20744: Accord uses txn timestamp for regular CQL mutations
- CASSANDRA-20131/19728: Improved debug for paused/disabled compaction
- CASSANDRA-19904: Deprecate gossip state for paxos electorate verification

---

## Not-Doc-Worthy (~120 items)

Internal refactors, performance micro-optimizations, test fixes, and bug fixes with no user-visible behavior change. Key categories:

### Internal Performance Optimizations (~30)
CASSANDRA-21144, 21142, 21088, 21083, 21080, 21075, 21074, 21040, 21039, 21038, 20816, 20804, 20760, 20526, 20465, 20360, 20267, 20250, 20226, 20190, 20173, 20166, 20129, 20092, 20034, 19679, 19567, 19514

### Internal Bug Fixes (~40)
CASSANDRA-21143, 21150, 21141, 21115, 21055, 21047, 21035, 21033, 21006, 21005, 21004, 21003, 21002, 21001, 20992, 20983, 20869, 20844, 20842, 20788, 20715, 20686, 20667, 20624, 20622, 20620, 20538, 20527, 20524, 20489, 20481, 20469, 20467, 20483, 20396, 20346, 20345, 20344, 20343, 20320, 20237, 20209, 20218, 20126, 19950, 19938, 19921, 19916, 19905, 19890, 19878, 19872, 19848, 19846, 19845, 19782, 19768, 19712, 19711, 19710, 19709, 19714, 19705, 19692, 19645, 19538, 19255

### Internal Refactors (~15)
CASSANDRA-21043, 20677, 20513, 20480, 20287, 20116, 19620, 19592, 19516, 19482, 19341, 19346, 19271, 19189, 18961, 18813, 19632

### Test / Build / Dependency (~15)
CASSANDRA-21149, 17925, 17401, 20805, 20200, 20198, 19997, 19993, 19954, 19943, 19953, 19502, 19239, 19783, 19693, 18875, 18275, 19201, 20928, 20925, 20150, 20149

### Already Covered by Primary Research
CASSANDRA-20888 (index hints), 20563 (constraints), 20330 (constraints), 20266 (constraints), 20341 (constraints), 19966 (CREATE TABLE LIKE), 20887 (TCM upgrade), 20048 (auto-repair), 21046 (schema annotations)

---

## Uncertain (2 items)
- CASSANDRA-20217: Abort all kinds of multi-step operations — may expose new nodetool capability
- CASSANDRA-20335: Don't leak non-Java exceptions via JMX snapshots — may affect JMX client behavior
