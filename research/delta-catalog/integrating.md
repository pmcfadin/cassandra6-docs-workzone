# Delta Report: integrating

## Scope
`doc/modules/cassandra/pages/integrating/`

## Page Inventory
- **5.0 pages:** 1
- **trunk pages:** 1 (no additions or removals)

## Changed Files

### 1. plugins/index.adoc
- **Delta type:** Content update
- **Summary:** Removes the CAPI-Rowcache plugin section entirely (IBM POWER8 specific, no longer maintained). Renames "Stratio's Cassandra Lucene Index" to "Cassandra Lucene Index" reflecting transfer to Instaclustr. Adds a NOTE that support was retired after Cassandra 5.0 with SAI replacing it; remains supported for 4.x only. Changes verb tense from present to past ("extends" -> "extended"). Updates GitHub URL from stratio to instaclustr org, and fixes http to https.

## Assessment
- Straightforward content update reflecting ecosystem changes. The Lucene Index plugin is now marked as legacy/retired, consistent with SAI being the recommended indexing approach in 5.0+.
