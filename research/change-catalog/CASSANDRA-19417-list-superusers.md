# CASSANDRA-19417 LIST SUPERUSERS CQL statement

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | major-update |

## Summary
CASSANDRA-19417 introduces a new `LIST SUPERUSERS` CQL statement that returns the set of all roles with superuser privilege, including roles that have superuser status transitively (i.e., via role inheritance). This complements the existing `LIST ROLES` statement, which shows all roles with a superuser column but requires the caller to interpret the results. `LIST SUPERUSERS` returns only the roles that currently have effective superuser access, resolving the hierarchy automatically. The statement requires `DESCRIBE` permission on all database roles.

## Discovery Source
- `CHANGES.txt` reference: "Add LIST SUPERUSERS CQL statement (CASSANDRA-19417)"
- `NEWS.txt` reference: "Add LIST SUPERUSERS CQL statement (CASSANDRA-19417)"
- Related JIRA: none listed
- Related CEP or design doc: none

## Why It Matters
- User-visible effect: Operators can run `LIST SUPERUSERS;` to get an immediate list of all roles with effective superuser access, including those that have acquired superuser status transitively through role grants. This is useful for security auditing without needing to manually traverse the role hierarchy from `LIST ROLES`.
- Operational effect: Requires `DESCRIBE` permission on the root roles resource (`RoleResource.root()`). Will throw `UnauthorizedException` for callers without that permission. Returns a single-column result set with column name `role`.
- Upgrade or compatibility effect: New statement only. No schema changes. Clients on pre-6.0 nodes will see a syntax error for `LIST SUPERUSERS`.
- Configuration or tooling effect: cqlsh tab-completion updated to recognize `SUPERUSERS` (added to `pylib/cqlshlib/cql3handling.py`). `K_SUPERUSERS` added to `src/antlr/Lexer.g`. Audit logging emits `AuditLogEntryType.LIST_SUPERUSERS` (category `DCL`).

## Source Evidence
- Relevant docs paths:
  - `doc/modules/cassandra/pages/developing/cql/security.adoc` -- `[[list-superusers-statement]]` section added (lines 264-274) with BNF include and one-sentence description: "This command requires `DESCRIBE` permission on all roles of the database." (added by commit `b35ad427c5`)
  - `doc/modules/cassandra/examples/BNF/list_superusers_statement.bnf` -- one-line BNF file: `list_superusers_statement ::= LIST SUPERUSERS` (added by commit `b35ad427c5`)
  - `doc/modules/cassandra/pages/reference/cql-commands/commands-toc.adoc` -- `xref:reference:cql-commands/list-superusers.adoc[LIST SUPERUSERS]` entry added (commit `b35ad427c5`)
  - `doc/cql3/CQL.textile` -- legacy CQL3 textile doc updated with LIST SUPERUSERS syntax (commit `b35ad427c5`)
  - **GAP**: The `commands-toc.adoc` references `reference/cql-commands/list-superusers.adoc` but this file does not exist in the trunk tree (`git ls-tree -r origin/trunk -- doc/modules/cassandra/` shows no `list-superusers.adoc` under `reference/cql-commands/`). The reference page is linked but not created.
- Relevant code paths:
  - `src/antlr/Lexer.g` -- `K_SUPERUSERS: S U P E R U S E R S;` token definition
  - `src/antlr/Parser.g` -- `listSuperUsersStatement` grammar rule: `K_LIST K_SUPERUSERS { $stmt = new ListSuperUsersStatement(); }` added to `cqlStatement` dispatch and `basic_unreserved_keyword` (commit `b35ad427c5`)
  - `src/java/org/apache/cassandra/cql3/statements/ListSuperUsersStatement.java` -- 102-line implementation: `AuthorizationStatement` subclass; `authorize()` checks `DESCRIBE` on `RoleResource.root()`; `execute()` calls `Roles.getAllRoles(Roles::hasSuperuserStatus)` and returns a `ResultMessage.Rows` with a single `role` column (commit `b35ad427c5`)
  - `src/java/org/apache/cassandra/auth/Roles.java` -- `getAllRoles(Predicate<RoleResource> predicate)` method added: filters the full role set by the given predicate; used to return only superuser-enabled roles (commit `b35ad427c5`)
  - `src/java/org/apache/cassandra/audit/AuditLogEntryType.java` -- `LIST_SUPERUSERS(AuditLogEntryCategory.DCL)` enum value added (commit `b35ad427c5`)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/cql3/statements/ListSuperUsersStatementTest.java` -- 131-line test: permissions enforcement, result validation, mock-based role hierarchy tests (commit `b35ad427c5`)
  - `test/unit/org/apache/cassandra/auth/RolesTest.java` -- `superuserStatusIsCached` test and `getAllRoles(Roles::hasSuperuserStatus)` usage (line 139)
  - `test/unit/org/apache/cassandra/audit/AuditLoggerAuthTest.java` -- `LIST_SUPERUSERS` audit log entry test (commit `b35ad427c5`)

## What Changed

### New CQL statement

```cql
LIST SUPERUSERS;
```

Returns a single-column result set:

| role |
|---|
| cassandra |
| admin_role |
| ... |

The result includes all roles that have superuser privilege, whether directly (`WITH SUPERUSER = true`) or transitively (via a role grant chain that leads to a superuser role).

### BNF

```
list_superusers_statement ::= LIST SUPERUSERS
```

### Permissions required
- `DESCRIBE` on all roles (`RoleResource.root()`)
- Any role without this permission receives `UnauthorizedException: "You are not authorized to view superuser details"`

### Audit logging
- Emits `LIST_SUPERUSERS` entry in the `DCL` (Data Control Language) category
- Consistent with `LIST_ROLES` which is also a DCL audit event

### Transitive superuser resolution
- Uses `Roles.getAllRoles(Roles::hasSuperuserStatus)` which fetches all roles and filters by `hasSuperuserStatus`
- `hasSuperuserStatus` follows the role hierarchy — a role granted to another superuser role also returns true

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/developing/cql/security.adoc` -- already updated with LIST SUPERUSERS section (no prose gap, but the section is minimal — one sentence). Adequate for initial release; could be expanded with examples.
  - `doc/modules/cassandra/pages/reference/cql-commands/commands-toc.adoc` -- already updated with a link to `list-superusers.adoc`.
- New pages likely needed:
  - `doc/modules/cassandra/pages/reference/cql-commands/list-superusers.adoc` -- **MISSING**: The commands-toc.adoc links to this file but it does not exist in trunk. A dedicated reference command page (similar to other pages in that directory) needs to be created. This is the primary documentation gap.
- Audience home: Operators (security/administration)
- Authored or generated: authored
- Technical review needed from: Shailaja Koppu (implementer), Stefan Miklosovic, Benjamin Lerer (reviewers)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `new-page` (for `list-superusers.adoc`) + `minor-update` (for `security.adoc`)
- Recommended owner role: docs-lead or docs-contributor
- Publish blocker: yes — the reference page linked from commands-toc.adoc does not exist; a broken xref will cause build failures or navigation errors

## Open Questions
1. Does the missing `reference/cql-commands/list-superusers.adoc` file cause a build error in the Antora docs build? If yes, this should be treated as a critical gap.
2. What output columns does `LIST SUPERUSERS` return exactly? The implementation (`ListSuperUsersStatement.java`) returns a single column named `role` of type `text`. Should the reference page document the result set schema?
3. Is there a difference in behavior between `LIST SUPERUSERS` and `LIST ROLES` filtered manually — specifically, are service accounts or system roles included?
4. Should the `security.adoc` LIST SUPERUSERS section include a concrete example showing the output?

## Next Research Steps
- Create `doc/modules/cassandra/pages/reference/cql-commands/list-superusers.adoc` following the pattern of other command reference pages
- Expand the `security.adoc` LIST SUPERUSERS section with an example
- Confirm whether the missing `list-superusers.adoc` page causes an Antora build warning or error
- Verify the relationship between LIST SUPERUSERS and LIST ROLES output for the same cluster state

## Notes
- Commit `b35ad427c5` (CASSANDRA-19417, March 2024): 15 files changed, 330 insertions
- `K_SUPERUSERS` is in `basic_unreserved_keyword` — `superusers` can still be used as a column/table name without quoting
- The result column name is `role` (singular), same as the role column returned by `LIST ROLES`
- `Roles.getAllRoles(Predicate)` is a new general-purpose method that could be used by future statements filtering roles by other predicates
- The `security.adoc` section anchor is `[[list-superusers-statement]]` — xrefs should use this anchor
- Audit log category `DCL` covers all role/permission management statements: GRANT, REVOKE, LIST ROLES, LIST PERMISSIONS, LIST SUPERUSERS
