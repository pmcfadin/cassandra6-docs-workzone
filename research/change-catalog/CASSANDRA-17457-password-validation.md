# CASSANDRA-17457: Password Validation and Generation (CEP-24) + Role Name Generation (CEP-55)

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary

CEP-24 (CASSANDRA-17457) introduces a guardrail-based password validation and generation framework. Passwords are validated against configurable strength policies on `CREATE ROLE` and `ALTER ROLE`, and can be auto-generated via the `GENERATED PASSWORD` CQL clause. CEP-55 (CASSANDRA-20897) extends this pattern to role name generation with `CREATE GENERATED ROLE`. CASSANDRA-19762 adds dictionary lookup support for the password validator.

Both features have **comprehensive dedicated documentation pages** already committed to trunk, integrated into the site navigation, cross-referenced from the security page, and consistent with the YAML configuration. This is one of the best-documented new features in Cassandra 6.

## JIRA Details

| Field         | Value |
|---------------|-------|
| Primary JIRA  | CASSANDRA-17457 |
| Related JIRAs | CASSANDRA-20897 (CEP-55, role name generation), CASSANDRA-19762 (dictionary lookup) |
| CEPs          | CEP-24 (password validation/generation), CEP-55 (role name generation) |
| Branch        | trunk |

## Documentation Evidence

### Dedicated Doc Pages (Both Exist on Trunk)

1. **`doc/modules/cassandra/pages/managing/operating/password_validation.adoc`**
   - Comprehensive page covering CEP-24 goals, configuration, validation examples, generation examples, runtime JMX reconfiguration, diagnostic events
   - Includes full `password_policy` YAML configuration reference with all parameters
   - Shows `GENERATED PASSWORD` clause usage in `CREATE ROLE` and `ALTER ROLE`
   - Documents dictionary-based password checking (CASSANDRA-19762)
   - Documents `detailed_messages` configuration option
   - Documents `password_policy_reconfiguration_enabled` setting
   - Mentions credentials file and cqlshrc configuration for storing generated passwords

2. **`doc/modules/cassandra/pages/managing/operating/role_name_generation.adoc`**
   - Comprehensive page covering CEP-55 configuration and usage
   - Documents `role_name_policy` YAML configuration with `UUIDRoleNameGenerator`
   - Shows all CQL variations: `CREATE GENERATED ROLE`, with PASSWORD, with GENERATED PASSWORD, with OPTIONS (prefix, suffix, name_size)
   - Documents `min_generated_name_size` parameter
   - Documents JMX runtime reconfiguration via `GuardrailsMBean`
   - Documents `role_name_policy_reconfiguration_enabled` setting
   - Explains extensibility via custom `IRoleManager` implementations

### Navigation and Cross-References

- **`doc/modules/cassandra/nav.adoc`**: Both pages listed under Operating section
- **`doc/modules/cassandra/pages/managing/operating/index.adoc`**: Both pages referenced
- **`doc/modules/cassandra/pages/managing/operating/security.adoc`**: Cross-references both pages with links to their respective CEP wiki pages

### CQL Grammar (BNF)

- **`doc/modules/cassandra/examples/BNF/create_role_statement.bnf`**: Includes `GENERATED PASSWORD` as a `role_option`
- **`doc/modules/cassandra/examples/BNF/alter_role_statement.bnf`**: Includes `GENERATED PASSWORD` as an option
- **`doc/modules/cassandra/pages/developing/cql/changes.adoc`**: Documents "Add support for GENERATED PASSWORD clause (17457)"

### YAML Configuration (cassandra.yaml)

Both `password_policy` and `role_name_policy` sections are fully documented in `conf/cassandra.yaml` (commented out by default):

**password_policy parameters:**
- `validator_class_name` (default: CassandraPasswordValidator)
- `generator_class_name` (default: CassandraPasswordGenerator)
- `characteristic_warn` / `characteristic_fail` (thresholds for character class requirements)
- `max_length` (default: 1000)
- `length_warn` / `length_fail`
- `upper_case_warn` / `upper_case_fail`
- `lower_case_warn` / `lower_case_fail`
- `digit_warn` / `digit_fail`
- `special_warn` / `special_fail`
- `illegal_sequence_length` (default: 5, minimum: 3)
- `dictionary` (path to dictionary file for CASSANDRA-19762)
- `detailed_messages` (default: true)
- `password_policy_reconfiguration_enabled` (default: true, separate top-level key)

**role_name_policy parameters:**
- `validator_class_name` (no built-in implementation)
- `generator_class_name` (UUIDRoleNameGenerator)
- `min_generated_name_size` (range: 10-32)
- `role_name_policy_reconfiguration_enabled` (default: true, separate top-level key)

### Character Set Support

The `CassandraPasswordValidator` (via the Passay library) supports illegal sequence detection for:
- English
- Cyrillic (classic and modern)
- German
- Polish
- Czech

This matches the NEWS.txt description.

### NEWS.txt Entry

```
- CEP-24 - Password validation / generation. When built-in 'password_policy' guardrail is enabled, it will
  generate a password of configured password strength policy upon role creation or alteration
  when 'GENERATED PASSWORD' clause is used. Character sets supported are: English, Cyrillic, modern Cyrillic,
  German, Polish and Czech.
- CEP-55 - Role name generation and validation. When built-in 'role_name_policy' guardrail is enabled, it will
  generate a role name automatically, without operators intervention. It is possible to configure
  this policy for both generation and as well as validation of role names.
```

## Key Source Files

| File | Purpose |
|------|---------|
| `src/java/org/apache/cassandra/db/guardrails/PasswordPolicyGuardrail.java` | Password policy guardrail implementation |
| `src/java/org/apache/cassandra/db/guardrails/CassandraPasswordValidator.java` | Default password validator (Passay-based) |
| `src/java/org/apache/cassandra/db/guardrails/CassandraPasswordGenerator.java` | Default password generator |
| `src/java/org/apache/cassandra/db/guardrails/RoleNamePolicyGuardrail.java` | Role name policy guardrail |
| `src/java/org/apache/cassandra/cql3/statements/CreateRoleStatement.java` | CQL CREATE ROLE with GENERATED PASSWORD/ROLE support |
| `src/java/org/apache/cassandra/cql3/statements/AlterRoleStatement.java` | CQL ALTER ROLE with GENERATED PASSWORD support |
| `src/java/org/apache/cassandra/config/GuardrailsOptions.java` | Configuration binding |
| `src/java/org/apache/cassandra/tools/nodetool/GuardrailsConfigCommand.java` | Nodetool guardrails command |

## Docs Coverage Assessment

### What Is Well Covered
- Full explanation of CEP-24 goals and motivation
- Complete YAML configuration reference for both password_policy and role_name_policy
- CQL syntax with practical examples (validation failures, warnings, generation)
- Runtime JMX reconfiguration documentation
- Dictionary-based password checking (CASSANDRA-19762)
- Role name generation with prefix/suffix/size options (CEP-55)
- Cross-references from security.adoc
- Navigation integration
- BNF grammar updated for both CREATE ROLE and ALTER ROLE

### Potential Minor Gaps (Low Priority)
1. The password_validation.adoc uses `class_name` in its example YAML block but the actual cassandra.yaml uses `validator_class_name`. This is a minor inconsistency that could confuse users.
2. Character set support (Cyrillic, German, Polish, Czech) is mentioned in NEWS.txt but not documented in the password_validation.adoc page -- users would not know that illegal sequence detection works across multiple character sets.
3. The `max_length` parameter (default 1000) is present in cassandra.yaml but not mentioned in password_validation.adoc.
4. No documentation of the `CREATE GENERATED ROLE` BNF in a dedicated BNF file (the create_role_statement.bnf only shows `CREATE ROLE`, not `CREATE GENERATED ROLE`). The syntax is documented in the role_name_generation.adoc prose but not in formal BNF.

## Recommendation

**Status: DOCS-PRESENT -- No major documentation work needed.**

Both features have thorough, dedicated documentation pages that are well-integrated into the doc site. The pages cover configuration, CQL usage, examples, runtime management, and extensibility. The minor gaps identified above (class_name vs validator_class_name inconsistency, missing character set documentation, missing max_length) could be addressed as minor editorial fixes but do not represent significant documentation gaps.

This is a model example of how new Cassandra features should be documented -- the CEP authors clearly invested in documentation alongside the implementation.

## Proposed Disposition
- Inventory classification: review-only
- Affected docs: password_validation.adoc; role_name_generation.adoc; security.adoc
- Owner role: docs-lead
- Publish blocker: no
