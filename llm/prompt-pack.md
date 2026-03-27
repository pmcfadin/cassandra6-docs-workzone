# Prompt Pack

Capture date: **2026-03-24**

## Usage Rules
- Always provide the source pack with the prompt.
- Require citations in the output.
- Require an explicit unresolved-questions section.
- Keep tasks slice-sized by module or behavior area.

## 1. Inventory Prompt
```text
You are reviewing Apache Cassandra documentation sources.

Use only the provided source pack.
Task: inventory the supplied page set and classify each page as one of:
unchanged, minor-update, major-rewrite, new, merge-split, remove, needs-review.

For each page return:
- page_path
- classification
- short rationale
- evidence_refs
- unresolved_questions

Do not invent behavior or content not present in the sources.
Flag any generated-doc surface separately.
```

## 2. Diff Prompt
```text
You are comparing Cassandra 5.0 docs to Cassandra 6 source material on trunk.

Use only the provided source pack.
Task: identify what changed for the target area.

Return:
- change summary
- affected pages
- proposed disposition per page
- evidence_refs
- missing evidence

Mark every inference explicitly as inference.
```

## 3. Draft Prompt
```text
You are drafting a Cassandra documentation update from approved sources.

Use only the provided source pack.
Task: produce a first draft for the specified page.

Output:
- proposed title
- proposed body
- source citations inline or in a source block
- unresolved questions
- reviewer warnings

Rules:
- do not state uncited facts
- do not invent defaults, compatibility guarantees, or command behavior
- preserve Cassandra terminology from the sources
- if evidence is weak, say so instead of filling gaps
```

## 4. Review Prompt
```text
You are reviewing an AI-generated Cassandra documentation draft.

Use only the provided source pack and the draft text.
Task: identify factual risk, version risk, generated-doc drift, and missing citations.

Return:
- blocking issues
- non-blocking issues
- unsupported claims
- suggested fixes
- signoff recommendation: reject / revise / ready-for-human-review
```

## 5. Wire-Up Prompt
```text
You are reviewing how a new major Cassandra documentation version should be added.

Use only the provided source pack.
Task: identify all repo touchpoints needed to add Cassandra 6.

Return:
- Cassandra repo touchpoints
- cassandra-website touchpoints
- alias changes
- metadata changes
- validation steps
- open risks
```

## Prompting Anti-Patterns
- “Write the Cassandra 6 docs from scratch.”
- “Summarize Cassandra 6 from what you know.”
- “Fill in any missing config defaults.”
- “Assume behavior if the source does not mention it.”
