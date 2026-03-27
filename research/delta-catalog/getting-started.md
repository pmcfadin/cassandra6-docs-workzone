# Delta Report: getting-started

## Scope
`doc/modules/cassandra/pages/getting-started/`

## Page Inventory
- **5.0 pages:** 9
- **trunk pages:** 9 (no additions or removals)

## Changed Files

### 1. drivers.adoc
- **Delta type:** Content update
- **Summary:** Modernizes the driver list by removing defunct/abandoned third-party drivers and adding current ones.
- **Removals (Java):** Achilles, Astyanax, Casser, Kundera, PlayORM — replaced by single entry: "Java Driver for Apache Cassandra" (apache/cassandra-java-driver).
- **Removals (C#/.NET):** Cassandra Sharp, Fluent Cassandra removed; only Datastax C# driver remains.
- **Removals (PHP):** CQL|PHP, PHP-Cassandra, PHP Library for Cassandra removed; only Datastax PHP driver remains.
- **Removals (C++):** libQTCassandra removed.
- **Removals (Go):** CQLc, Gocassa removed; only GoCQL remains.
- **Additions:** Async Python Cassandra Client (Python), Cassandra JDBC Wrapper (new JDBC section), Swift Driver for Apache Cassandra (new Swift section).
- **Link update:** Java driver URL changed from datastax/java-driver to apache/cassandra-java-driver.

### 2. mtlsauthenticators.adoc
- **Delta type:** Content addition
- **Summary:** Adds a new section "Configuring mTLS with password fallback authenticator for client connections" (~53 lines). Documents `MutualTlsWithPasswordFallbackAuthenticator` for transitioning clusters from password-based auth to mTLS without breaking existing clients. Includes 3-step instructions (add identities, configure yaml with `optional` mode, bounce cluster). Existing content unchanged.

## Unchanged Files (7)
- configCassandra_yaml.adoc
- index.adoc
- installing.adoc
- production.adoc
- querying.adoc
- securing.adoc
- startCassandra.adoc

## Assessment
- **drivers.adoc:** Straightforward content update — cleanup of dead links and addition of current drivers. No structural changes. Ready to carry forward.
- **mtlsauthenticators.adoc:** New feature documentation for password fallback authenticator (available since Cassandra 5.0). Pure additive change with no modifications to existing content.
