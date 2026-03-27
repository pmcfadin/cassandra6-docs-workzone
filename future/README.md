# Future Docs Proposals

This directory contains a forward-looking redesign package for Apache Cassandra documentation.

## Files
- `comparative-research.md`: what other open source projects do well and which ideas transfer to Cassandra.
- `website/README.md`: research on community-first open source websites and the supporting source list.
- `proposals.md`: three future-state documentation system proposals, each designed to fit Apache Software Foundation constraints.
- `researcher-subtasks.md`: agent-ready research and prototyping tasks to validate or de-risk the proposals.
- `website/community-first-websites.md`: open source website examples that optimize for community use rather than marketing.

## Suggested Reading Order
1. `comparative-research.md`
2. `website/README.md`
3. `proposals.md`
4. `researcher-subtasks.md`

## Working Position
The current Cassandra docs system is operationally correct but unnecessarily heavy for contributors:
- product docs live in `apache/cassandra`
- render and publish orchestration live in `apache/cassandra-website`
- local preview depends on website repo tooling and Docker
- major-version rollout is still partly hardcoded
- generated docs and hand-authored docs follow different provenance rules

The proposals in this directory assume those current-state findings remain true until the upstream project changes them.
