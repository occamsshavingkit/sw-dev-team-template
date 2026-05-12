# Prior-art scan — <task-id>

Owned by `researcher`. Produced at workflow-pipeline stage 1 for
tasks whose trigger annotation fires any of the six clauses in
`docs/proposals/workflow-redesign-v0.12.md` §2. Consumed by
`architect` (stage 2) and `software-engineer` (stages 3, 5).

Keep it tight. One page is ideal. The point is to *prevent
hallucinated library usage* by grounding the downstream stages
in cited documentation, not to produce a literature review.

---

## 1. Task reference

- **Task ID:** T-NNNN
- **One-line task statement:** copy from `docs/tasks/T-NNNN.md`.
- **Trigger clauses that fire:** `<list from task annotation>`.

## 2. Search scope

What sources were consulted. Cite each; do not paraphrase a source
you did not read.

- **Tier-1 (standards / official vendor docs):** <cited URLs,
  retrieval date>
- **Tier-2 (well-sourced secondary, e.g., SRE book, framework
  maintainer blogs, Wikipedia with cross-refs):** <cited URLs,
  retrieval date>
- **Tier-3 (stack overflow / vendor marketing / anonymous
  forums):** used only for ambiguity characterization; never
  as sole authority.

Source-authority tiers per `.claude/agents/researcher.md` §Job 1.

## 3. Canonical solution

- **Canonical pattern found:** <yes / no>
- If yes: named pattern, source citation, brief one-paragraph
  summary of how the canonical solution frames the problem.
- If no: state so explicitly. "No canonical solution; this task
  is novel" is a valid finding.

## 4. Candidate libraries / frameworks / APIs

One row per candidate. Rejected candidates still listed with a
reason — this is the audit trail for "why not X?".

| Candidate | Version | Licence | Maintenance signal | Fit / Rejection reason |
|---|---|---|---|---|
| | | | | |

Maintenance signal = last release date / issue-count trend /
funded or volunteer / named maintainer.

## 5. Known pitfalls

What canonical implementations commonly get wrong. Pull these
from the cited sources' own errata sections, vendor advisories,
or CVE lists — not from anecdotal forum posts.

- <pitfall>: <mitigation if any>
- ...

## 6. Recommendation to `architect` / `software-engineer`

One short paragraph. What the downstream stages should treat as
given, and what's still open for design / implementation judgment.

## 7. Metadata

- **Last verified:** YYYY-MM-DD (bump on major-version library
  bumps and at milestone close per `researcher.md` §6 cadence).
- **Library versions cited:** list with exact versions.
- **Retention:** durable. Archived only when the covered feature
  is removed from the project.
