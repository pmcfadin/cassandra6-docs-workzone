Use the cassandra-doc skill

You are researching one Apache Cassandra JIRA for Cassandra 6 docs discovery.

Primary source of truth:
- The Apache Cassandra GitHub repo is authoritative.
- Default repo: https://github.com/apache/cassandra
- Default branch: `trunk`, unless told to use `cassandra-6.0`
- Use JIRA, `NEWS.txt`, and `CHANGES.txt` only as discovery context unless validated against the repo

Assignment:
- JIRA: <CASSANDRA-XXXX>
- Topic: <short topic>
- Branch: <trunk or cassandra-6.0>
- Output file: `/Users/patrick/local_projects/Cassandra 6 doc update/research/change-catalog/CASSANDRA-XXXX-<slug>.md`

Your task:
Determine whether this JIRA represents a meaningful docs-impacting change, and if so, produce a concise research artifact grounded in Cassandra repo evidence.

Required workflow:
1. Start from the assigned JIRA and any matching `NEWS.txt` or `CHANGES.txt` references.
2. Validate the change against the Apache Cassandra repo:
   - docs under `doc/`
   - config such as `conf/cassandra.yaml`
   - generated-doc inputs and scripts
   - implementation code
   - tests when useful
3. Decide:
   - what changed
   - who it affects
   - whether it is user-visible
   - whether it likely needs docs
   - whether it affects authored docs, generated docs, or both
4. Identify likely affected docs pages or docs areas.
5. Record uncertainty and open questions clearly.

Deliverable format:
Write or update the markdown file using this structure:

- Status
  - Research state
  - Source branch
  - Primary audience
  - Docs impact
- Summary
- Discovery Source
- Why It Matters
- Source Evidence
- What Changed
- Docs Impact
- Proposed Disposition
- Open Questions
- Next Research Steps
- Notes

Classification rules:
Primary audience must be one of:
- Operators
- Developers
- Contributors
- Reference
- Mixed

Docs impact must be one of:
- none
- minor-update
- major-update
- new-page
- generated-review
- unknown

Evidence rules:
- Prefer repo file paths, commits, tests, config, and existing docs.
- Do not treat the JIRA title or changelog line as sufficient evidence.
- If you cannot validate a claim from the repo, say so.
- If the change looks internal-only, mark it as likely `none` and explain why.

Output quality bar:
- Concise and source-grounded
- No invented behavior
- No final docs prose
- Clear statement on whether this is doc-worthy

Return to the master agent with:
1. the completed markdown content
2. a one-paragraph summary
3. a status recommendation for the tracker:
   - validated
   - blocked
   - not-doc-worthy
4. an evidence status recommendation:
   - repo-validated
   - needs-jira
   - needs-code
   - needs-tests
   - ready-for-doc-mapping
