# CASSANDRA-14227: TTL Expiration Extended to 2106 / storage_compatibility_mode Upgrade Guidance

## Status

| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary

CASSANDRA-14227 extends the maximum TTL expiration date from 2038-01-19T03:14:06+00:00 (Unix epoch 32-bit signed int overflow) to 2106-02-07T06:28:13+00:00 (32-bit unsigned int) by changing internal deletion time storage from signed to unsigned 32-bit integers. This was a Cassandra 5.0 feature. In Cassandra 6.0 (trunk), the default `storage_compatibility_mode` is set to `NONE`, meaning the 2106 limit is active by default. The feature itself requires no new documentation for Cassandra 6.0, but upgrade guidance from 4.x/5.x to 6.0 must clearly document the `storage_compatibility_mode` transition process, and a few existing doc pages contain stale 2038 references.

## Discovery Source

- NEWS.txt lines 10-32: "MAXIMUM TTL EXPIRATION DATE NOTICE (CASSANDRA-14092 & CASSANDRA-14227)"
- CHANGES.txt: "Extend maximum expiration date (CASSANDRA-14227)"
- CASSANDRA-14092.txt: detailed overflow policy and recovery guidance

## Why It Matters

For Cassandra 6 users:
1. **New installs**: The 2106 limit is the default. No special action needed, but users should know the new maximum.
2. **Upgrades from 4.x or 5.x**: The `storage_compatibility_mode` property controls when the 2106 limit activates. Incorrect configuration during rolling upgrades can lead to mixed-mode clusters where some nodes reject TTLs that others accept, causing write failures or inconsistencies.
3. **The maximum TTL value itself is still 20 years** (630,720,000 seconds, hardcoded in `Attributes.MAX_TTL`). What changed is the maximum *calendar date* at which that TTL-based expiration can land.

## Source Evidence

### cassandra.yaml (trunk) -- lines 2708-2735

The `storage_compatibility_mode` property is documented in-line and defaults to `NONE` on trunk:

```yaml
storage_compatibility_mode: NONE
```

Possible values:
- `CASSANDRA_4`: Stays compatible with 4.x; deletion times limited to 2038; enables rollback to 4.x.
- `CASSANDRA_5`: Stays compatible with 5.x; introduced for 6.0 to gate new 6.0-only features (e.g., ZSTD dictionary compression).
- `UPGRADING`: Interim mode that monitors cluster node versions and enables new features only when all nodes are upgraded.
- `NONE`: Full current-version features enabled; no backward compatibility overhead.

### StorageCompatibilityMode.java

Enum with four values: `CASSANDRA_4(4)`, `CASSANDRA_5(5)`, `UPGRADING(MAX_VALUE-1)`, `NONE(MAX_VALUE)`. The `CASSANDRA_5` value is new in trunk (6.0) and gates 6.0-specific features like ZSTD dictionary-based compression.

### Cell.java -- getVersionedMaxDeletiontionTime()

The runtime max deletion time depends on the compatibility mode:
- If `storage_compatibility_mode` is `NONE`, returns `MAX_DELETION_TIME` (2106 limit).
- Otherwise, checks `MessagingService.minClusterVersion`: if all nodes are >= 5.0, returns 2106 limit; otherwise returns `MAX_DELETION_TIME_2038_LEGACY_CAP`.

### ExpirationDateOverflowHandling.java

Overflow policy (`-Dcassandra.expiration_date_overflow_policy`) controls behavior when a TTL would exceed the max date:
- `REJECT` (default): Rejects the write.
- `CAP`: Caps to max date, warns client.
- `CAP_NOWARN`: Caps silently.

### Attributes.java

`MAX_TTL = 20 * 365 * 24 * 60 * 60` (20 years in seconds = 630,720,000). This has NOT changed.

### Existing doc references

- `doc/modules/cassandra/pages/new/index.adoc` line 29: Lists the feature under Cassandra 5.0 new features, linking to NEWS.txt and the JIRA.
- `doc/modules/cassandra/pages/managing/tools/sstable/sstablescrub.adoc` lines 28-33: `--reinsert-overflowed-ttl` flag references "maximum supported expiration date of 2038-01-19T03:14:06+00:00" -- this is **stale** for C6 (should note both dates depending on compatibility mode).

## What Changed

| Aspect                          | Before (C4.x and earlier)              | After (C5.0+, C6.0 default)           |
|---------------------------------|----------------------------------------|----------------------------------------|
| Max expiration date             | 2038-01-19T03:14:06 UTC                | 2106-02-07T06:28:13 UTC                |
| Internal deletion time storage  | Signed 32-bit int                      | Unsigned 32-bit int                    |
| Max TTL value                   | 630,720,000 sec (20 years)             | 630,720,000 sec (20 years) -- unchanged |
| storage_compatibility_mode      | N/A                                    | CASSANDRA_4 / CASSANDRA_5 / UPGRADING / NONE |
| Default mode (trunk/6.0)        | N/A                                    | NONE (2106 active by default)          |
| Overflow policy                 | REJECT / CAP / CAP_NOWARN              | Same -- unchanged                      |

### Cassandra 6.0-specific changes

- **New enum value `CASSANDRA_5`** added to `StorageCompatibilityMode`. This gates C6-only features (ZSTD dictionary compression) during upgrades from 5.x to 6.0.
- The cassandra.yaml comments now describe a generic upgrade pattern (`CASSANDRA_X -> UPGRADING -> NONE`) rather than the 5.0-specific `CASSANDRA_4` path.
- The default `storage_compatibility_mode` in trunk is `NONE`, meaning fresh C6 installs get 2106 TTL limits immediately.

## Docs Impact

### Pages requiring updates

1. **Upgrade guide (to be written for C6)**: Must document the three-step `storage_compatibility_mode` transition for upgrades from both 4.x and 5.x to 6.0. The `CASSANDRA_5` intermediate mode needs documentation.

2. **Configuration reference** (`conf/cassandra.yaml` docs / `managing/configuration/configuration.adoc`): The `storage_compatibility_mode` property and its four values need a proper entry. Currently only in-line yaml comments exist.

3. **sstablescrub tool page** (`managing/tools/sstable/sstablescrub.adoc`): The `--reinsert-overflowed-ttl` description hardcodes "2038-01-19T03:14:06+00:00". Should be updated to note that the cap date depends on storage compatibility mode (2038 or 2106).

4. **DML page** (`developing/cql/dml.adoc`): The TTL section at lines 351-359 does not mention maximum expiration date or overflow policy. Consider adding a note about the 2106 limit and the overflow policy.

5. **New features page** (`new/index.adoc`): Already lists CASSANDRA-14227 under C5.0. No update needed for C6 since this is not a new C6 feature.

### New documentation needed

- A dedicated section in the C6 upgrade guide covering `storage_compatibility_mode` transition, including the new `CASSANDRA_5` value for 5.x-to-6.0 upgrades.
- Consider a short "TTL and Expiration" reference page or section covering the max date, overflow policies, and `storage_compatibility_mode` interaction.

## Proposed Disposition
- Inventory classification: update-existing
- Affected docs: sstablescrub.adoc; dml.adoc; configuration.adoc
- Owner role: docs-lead
- Publish blocker: no

## Open Questions

1. **Is the `CASSANDRA_5` mode documented anywhere yet?** The cassandra.yaml comments on trunk do not explicitly list `CASSANDRA_5` -- they use `CASSANDRA_X` as a generic placeholder. The enum in code does define it. Is this intentional or an omission?
2. **Will `CASSANDRA_4` mode still be supported in 6.0?** The code still contains it, but should the upgrade docs recommend going 4.x -> 5.x -> 6.0, or is direct 4.x -> 6.0 supported?
3. **Should the sstablescrub `--reinsert-overflowed-ttl` reference both dates?** The scrub tool may need awareness of which cap applies.
4. **Is the overflow policy (`-Dcassandra.expiration_date_overflow_policy`) planned to become a cassandra.yaml property?** It is currently a JVM system property only.

## Next Research Steps

1. Check the JIRA ticket CASSANDRA-14227 comments for any unresolved documentation TODOs.
2. Review the C6 upgrade guide draft (if one exists) for `storage_compatibility_mode` coverage.
3. Verify whether direct 4.x -> 6.0 upgrades are supported or if 5.x is a required intermediate step.
4. Cross-reference with CASSANDRA-14092 for any additional doc overlap.

## Notes

- The NEWS.txt header for this feature says "default is CASSANDRA_4" -- this was accurate for 5.0 but is **not** accurate for trunk (6.0), where the default is `NONE`. The NEWS.txt content appears to be carried forward from 5.0 without update. This inconsistency should be flagged.
- The `CASSANDRA_5` enum value in `StorageCompatibilityMode.java` includes javadoc mentioning "ZSTD dictionary-based compression" as the gated feature. This is a 6.0-specific addition not mentioned in NEWS.txt.
- The max TTL of 20 years is enforced at the CQL layer (`Attributes.MAX_TTL`), independent of the storage layer's max expiration date. These are separate limits that could confuse users.
