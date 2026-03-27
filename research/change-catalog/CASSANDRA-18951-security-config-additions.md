# CASSANDRA-18951 + CASSANDRA-13428 + CASSANDRA-18857 Security configuration additions

## Status
| Field | Value |
|---|---|
| Research state | validated |
| Source branch | trunk |
| Primary audience | Operators |
| Docs impact | minor-update |

## Summary
This file consolidates three related security configuration improvements in Cassandra 6:

**CASSANDRA-18951** adds optional certificate validity period enforcement to `MutualTlsAuthenticator` and `MutualTlsInternodeAuthenticator`. Two new per-encryption-options settings — `max_certificate_validity_period` and `certificate_validity_warn_threshold` — let operators reject (or warn about) client certificates that are valid for longer than a specified duration, reducing the risk from long-lived certificates.

**CASSANDRA-13428** adds `keystore_password_file` and `truststore_password_file` options (and their outbound keystore counterpart `outbound_keystore_password_file`) to the SSL encryption options in `cassandra.yaml`. These allow operators to provide keystore and truststore passwords via a file (first line of the file), instead of inline plaintext in the YAML, which is important for secrets management in containerized and secrets-manager-backed environments.

**CASSANDRA-18857** changes the TLS client certificate authentication handshake so that Cassandra does not send an `AUTHENTICATE` request to the CQL client when `MutualTlsAuthenticator` is in use. Previously, after a TLS handshake, Cassandra sent an `AUTHENTICATE` message, which confused some CQL drivers into attempting password authentication even though certificate authentication was already complete. The new mechanism uses "early authentication" — the identity is extracted from the certificate during the `STARTUP` message handling, and no `AUTHENTICATE` message is sent.

## Discovery Source
- `CHANGES.txt` reference (18951): "Add option for MutualTlsAuthenticator to restrict the certificate validity period (CASSANDRA-18951)"
- `CHANGES.txt` reference (13428): "Provide keystore_password_file and truststore_password_file options to read credentials from a file (CASSANDRA-13428)"
- `CHANGES.txt` reference (18857): "Allow CQL client certificate authentication to work without sending an AUTHENTICATE request (CASSANDRA-18857)"
- Related JIRAs: CASSANDRA-18951, CASSANDRA-13428, CASSANDRA-18857

## Why It Matters
- User-visible effect (18951): Connections using certificates with a validity period longer than `max_certificate_validity_period` are rejected at authentication time. Certificates approaching the warn threshold generate log warnings visible to operators.
- User-visible effect (13428): Keystore and truststore passwords can be read from files, removing the need to place plaintext passwords in `cassandra.yaml`. This is a prerequisite for secure secrets rotation and Kubernetes-style secrets management.
- User-visible effect (18857): CQL drivers connecting to a `MutualTlsAuthenticator`-protected cluster will no longer receive an `AUTHENTICATE` message after TLS handshake, eliminating driver confusion that previously caused authentication failures or warnings.
- Operational effect: Together these changes bring mTLS deployments closer to production-ready — cert validity gating, secrets-file support, and clean driver compatibility.
- Upgrade or compatibility effect:
  - 18951: New settings are optional; no behavior change unless configured.
  - 13428: New settings are optional; `keystore_password` remains supported and takes precedence if both are specified.
  - 18857: Breaking change for any custom `IAuthenticator` implementations that assumed an `AUTHENTICATE` message would always follow `STARTUP`. Custom authenticators should review the new `supportsEarlyAuthentication()` and `shouldSendAuthenticateMessage()` interface methods.
- Configuration or tooling effect: New YAML fields in `server_encryption_options` and `client_encryption_options`.

## Source Evidence

### CASSANDRA-18951 — Certificate validity period restriction
- Relevant config paths:
  - `conf/cassandra.yaml` — in both `server_encryption_options` and `client_encryption_options`:
    ```yaml
    # max_certificate_validity_period: 365d
    # certificate_validity_warn_threshold: 10d
    ```
  - Duration format follows `DurationSpec` (CASSANDRA-15234); resolution is minutes.
- Relevant code paths:
  - `src/java/org/apache/cassandra/config/EncryptionOptions.java` — adds the two new fields
  - `src/java/org/apache/cassandra/auth/MutualTlsCertificateValidityPeriodValidator.java` — new class implementing certificate validity period enforcement
  - `src/java/org/apache/cassandra/auth/MutualTlsAuthenticator.java` — wires in the validity validator
  - `src/java/org/apache/cassandra/auth/MutualTlsInternodeAuthenticator.java` — same for internode
  - `src/java/org/apache/cassandra/auth/MutualTlsUtil.java` — utility methods for cert validation
  - `src/java/org/apache/cassandra/metrics/MutualTlsMetrics.java` — metrics for cert validity failures
- Relevant test paths:
  - `test/distributed/org/apache/cassandra/distributed/test/auth/MutualTlsCertificateValidityPeriodTest.java`
  - `test/unit/org/apache/cassandra/auth/MutualTlsCertificateValidityPeriodValidatorTest.java`

### CASSANDRA-13428 — Password file options
- Relevant config paths:
  - `conf/cassandra.yaml` — new commented-out options in `server_encryption_options`:
    ```yaml
    #keystore_password_file: conf/keystore_passwordfile.txt
    #outbound_keystore_password_file: conf/outbound_keystore_passwordfile.txt
    #truststore_password_file: conf/truststore_passwordfile.txt
    ```
  - Same options also available in `client_encryption_options`.
  - YAML comment: "When keystore_password and keystore_password_file both are specified, the keystore_password will take precedence. The password in the file should be on the first line."
  - Also applies to `jmx_encryption_options` (via `JMXServerOptions`).
- Relevant code paths:
  - `src/java/org/apache/cassandra/config/EncryptionOptions.java` — adds `keystore_password_file`, `outbound_keystore_password_file`, `truststore_password_file` fields
  - `src/java/org/apache/cassandra/config/JMXServerOptions.java` — same for JMX SSL
  - `src/java/org/apache/cassandra/security/FileBasedSslContextFactory.java` — reads password from file path when the `_file` variant is configured
  - `doc/modules/cassandra/pages/managing/operating/security.adoc` — updated in this commit to document the new file-based password options (lines ~647, ~650, ~657)
- Relevant test paths:
  - `test/unit/org/apache/cassandra/config/EncryptionOptionsTest.java`
  - `test/unit/org/apache/cassandra/security/FileBasedSslContextFactoryTest.java`
  - `test/unit/org/apache/cassandra/utils/jmx/JMXSslConfiguredWithYamlFileOptionsAndPasswordFileTest.java`

### CASSANDRA-18857 — CQL cert auth without AUTHENTICATE request
- Relevant code paths:
  - `src/java/org/apache/cassandra/auth/IAuthenticator.java` — two new interface methods:
    - `supportsEarlyAuthentication()` (default `false`): return `true` to signal that authentication can be completed from connection-level data (e.g., a TLS certificate) without an `AUTHENTICATE` challenge.
    - `NegotiatedAuthenticator.shouldSendAuthenticateMessage()` (default `true`): return `false` to suppress the `AUTHENTICATE` message after `STARTUP`.
  - `src/java/org/apache/cassandra/auth/MutualTlsAuthenticator.java` — overrides `supportsEarlyAuthentication()` to return `true`; negotiator overrides `shouldSendAuthenticateMessage()` to return `false`.
  - `src/java/org/apache/cassandra/transport/messages/StartupMessage.java` — checks `supportsEarlyAuthentication()` and calls `evaluateResponse(byte[])` with an empty byte array instead of sending `AUTHENTICATE`.
  - `src/java/org/apache/cassandra/transport/messages/AuthUtil.java` — new utility class for the early-auth flow
  - `src/java/org/apache/cassandra/auth/MutualTlsWithPasswordFallbackAuthenticator.java` — updated to support early auth path for cert-authenticated connections
- Relevant test paths:
  - `test/unit/org/apache/cassandra/transport/EarlyAuthenticationTest.java` — new test for the early auth flow
  - `test/unit/org/apache/cassandra/transport/AuthenticationTest.java`
  - `test/unit/org/apache/cassandra/transport/MutualTlsWithPasswordFallbackAuthenticatorEarlyAuthenticationTest.java`

## What Changed

### CASSANDRA-18951
1. Two new optional fields in both `server_encryption_options` and `client_encryption_options`:
   - `max_certificate_validity_period` (DurationSpec, optional): certificates with a validity period exceeding this are rejected.
   - `certificate_validity_warn_threshold` (DurationSpec, optional): certificates exceeding this threshold generate WARN log entries.
2. Duration values use the standard Cassandra duration format (e.g., `365d`, `10d`).
3. Validation is performed by the new `MutualTlsCertificateValidityPeriodValidator` class.

### CASSANDRA-13428
1. New file-based password options in `server_encryption_options`, `client_encryption_options`, and `jmx_encryption_options`:
   - `keystore_password_file`: path to a file whose first line contains the keystore password.
   - `outbound_keystore_password_file`: same for the outbound keystore (internode mTLS).
   - `truststore_password_file`: same for the truststore.
2. Precedence: `keystore_password` takes priority over `keystore_password_file` when both are set.
3. `security.adoc` was updated in the same commit to document these options.

### CASSANDRA-18857
1. New `IAuthenticator` interface method `supportsEarlyAuthentication()` (default `false`).
2. New `NegotiatedAuthenticator` inner-interface method `shouldSendAuthenticateMessage()` (default `true`).
3. `MutualTlsAuthenticator` returns `supportsEarlyAuthentication() = true` and `shouldSendAuthenticateMessage() = false`.
4. When early authentication is supported, Cassandra authenticates the client during `STARTUP` processing using certificate information and does not send `AUTHENTICATE` to the driver.

## Docs Impact
- Existing pages likely affected:
  - `doc/modules/cassandra/pages/managing/operating/security.adoc`:
    - Already updated in the CASSANDRA-13428 commit to document `keystore_password_file` and `truststore_password_file`.
    - Still needs documentation for `max_certificate_validity_period` and `certificate_validity_warn_threshold` (CASSANDRA-18951).
    - Should document the new handshake behavior for `MutualTlsAuthenticator` (no `AUTHENTICATE` message) as a driver compatibility note (CASSANDRA-18857).
  - `doc/modules/cassandra/pages/managing/configuration/cass_yaml_file.adoc` — generated; will reflect all new YAML fields.
- New pages likely needed: None. The mTLS section of `security.adoc` should grow to cover all three changes.
- Audience home: Operators
- Authored or generated: `security.adoc` is authored content.
- Technical review needed from: Security / mTLS domain expert (Francisco Guerrero, Andy Tolbert, Abe Ratnofsky)

## Proposed Disposition
- `inventory/docs-map.csv` classification: `minor-update`
- Recommended owner role: docs-lead (security focus)
- Publish blocker: no

## Open Questions
- Is `MutualTlsWithPasswordFallbackAuthenticator` (the hybrid mode) fully documented in `security.adoc`? The CASSANDRA-18857 early-auth behavior applies to it as well.
- For CASSANDRA-18951, what happens with `certificate_validity_warn_threshold` if `max_certificate_validity_period` is not set — does the threshold still generate warnings, or does it require both to be set?
- Are the new cert validity fields applicable to internode (`server_encryption_options`) mTLS only, or also to standard (non-mTLS) client TLS? (From the commit message: both `server_encryption_options` and `client_encryption_options` received the fields, but the validator is only invoked by `MutualTls*Authenticator` classes — confirming mTLS-only applicability.)

## Next Research Steps
- Verify whether `certificate_validity_warn_threshold` can function independently of `max_certificate_validity_period`.
- Confirm that `security.adoc` has already been updated for the password-file options (CASSANDRA-13428) and identify gaps for 18951 and 18857.
- Draft the cert validity and early-auth subsections for `security.adoc`.

## Notes
- CASSANDRA-18951 commits: `a0af41f666` (trunk, main), `c2a78639de` (CHANGES.txt ninja fix). Author: Francisco Guerrero. Reviewers: Andy Tolbert, Abe Ratnofsky, Dinesh Joshi. Date: February 15 2024.
- CASSANDRA-13428 commit: `37fe4b679c` (trunk). Author: Maulin Vasavada. Reviewers: Stefan Miklosovic, Maxwell Guo. Date: February 17 2025.
- CASSANDRA-18857 commit: `c09d0d929b` (trunk). Author: Andy Tolbert. Reviewers: Abe Ratnofsky, Dinesh Joshi, Francisco Guerrero, Jyothsna Konisa. Date: January 30 2024.
- The `security.adoc` update for CASSANDRA-13428 at lines ~647 and ~650 shows the new password file options in a YAML example block for `DefaultSslContextFactory`.
