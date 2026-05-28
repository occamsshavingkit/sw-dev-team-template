---
name: intake-conformance-template
description: QA-owned audit template for tech-lead's Step-2 intake handling against the binding scoping rules.
template_class: intake-conformance
---


# Intake Flow Conformance — <project name>

Owned by `qa-engineer`. Reads `docs/intake-log.md` (see
`docs/templates/intake-log-template.md`) and audits `tech-lead`'s
handling of the Step-2 scoping intake against the binding rules in
`CLAUDE.md` § "FIRST ACTIONS — EVERY NEW SESSION".

Run at every milestone close, or ad-hoc on request. Records the
result in `docs/pm/LESSONS.md` under "Intake conformance audit".

## How to audit

1. `scripts/intake-show.sh` to render the log.
2. `scripts/intake-show.sh --violations-only` — exits non-zero if
   any entry has `agents-running-at-ask:` other than `[]`. Use in
   CI or pre-commit as a fast-lane check.
3. Walk each entry and grade against the checklist below. Non-pass
   rows go into the findings section with a cite to the intake-log
   `turn:`.

## Checklist

Per-entry checks (for each `turn:` in the log):

| # | Rule | Source | Pass / Fail / N-A |
|---|---|---|---|
| C1 | Atomic question — exactly one question per turn; no multi-question or multiple-choice bundles. | `CLAUDE.md` Step 2 "Question-asking protocol (binding)" | |
| C2 | All agents idle at the moment of asking — `agents-running-at-ask` is `[]`. | `CLAUDE.md` Step 2 "all agents and tool calls idle" | |
| C3 | `framing:` preserves the full question; not a paraphrase. | `CLAUDE.md` Step 2 "one question per turn" | |
| C4 | Verbatim `customer-answer:`. Paraphrase belongs in `decision:` / `notes:`, not here. | `CLAUDE.md` Step 2 "Record verbatim answers" | |
| C5 | Customer-domain answers mirrored into `CUSTOMER_NOTES.md` with cross-ref back. | `CLAUDE.md` Step 2 "mirror customer-domain answers into `CUSTOMER_NOTES.md`" | |
| C6 | If asked at Step 0 (issue-feedback opt-in), answer is a yes/no recorded in `CUSTOMER_NOTES.md`. | `CLAUDE.md` Step 0 | |
| C7 | Step-3 category-scope pin confirmed atomically before `researcher` dispatch. | `CLAUDE.md` Step 3a | |
| C8 | Issue titles filed upstream carry the template version and redact project identity (Rule 0). | `docs/ISSUE_FILING.md` Rule 0 | |
| C9 | Questions for an `sme-<domain>` fallback that resolves to the customer are framed as such, not as open questions to any agent. | `CLAUDE.md` § "Escalation protocol" | |
| C10 | No customer contact from any agent other than `tech-lead`. | `CLAUDE.md` Hard Rule #1 | |

Session-scope checks (once per audit):

| # | Rule | Source | Pass / Fail / N-A |
|---|---|---|---|
| S1 | Step-2 DoD fully satisfied at first work dispatch — project summary, SMEs, first milestone, escalation paths, Step 3, Step 0, charter, open questions all true. | `CLAUDE.md` Step 2 DoD | |
| S2 | `docs/intake-log.md` exists and starts at `turn: 1`. No gaps in the monotonic series. | `docs/templates/intake-log-template.md` Hard Rule #2 | |
| S3 | Every customer-domain fact in `CUSTOMER_NOTES.md` cites an intake-log `turn:`. | `docs/templates/intake-log-template.md` Hard Rule #5 | |
| S4 | `docs/OPEN_QUESTIONS.md` row IDs are unique and every row has an answerer + status. | `CLAUDE.md` Step 2 | |

## Findings

One subsection per non-pass row. Format:

```
### F-NNNN — <one-line headline>

**Rule:** <C1 / … / S4>
**Turn:** <intake-log turn: ID if applicable, else "session-scope">
**Observation:** <what was non-conformant, with cite to file + line>
**Severity:** major / minor / observation
**Recommendation:** <what should change>
**Routed to:** tech-lead (if process change), researcher (if
CUSTOMER_NOTES update), project-manager (if lesson)
```

## Summary

| Total entries audited | Pass | Fail | N/A |
|---|---|---|---|

**Overall verdict:** clean / conditional / major-non-conformance.

Record in `docs/pm/LESSONS.md`.
