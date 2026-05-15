# Intake Log — gate-fixture-v1.0.0-rc12

<!-- TOC -->

- [Format](#format)
- [Hard rules (binding)](#hard-rules-binding)
- [Rendering](#rendering)
- [Example entries](#example-entries)

<!-- /TOC -->

Structured chronological record of the **intake conversation**
between `tech-lead` and the customer (product owner). One entry per
question-answer round. Complements — does not replace —
`CUSTOMER_NOTES.md` (authoritative verbatim answers),
`docs/OPEN_QUESTIONS.md` (register of asks), and `docs/pm/CHARTER.md`
(rolled-up summary).

Owned by `tech-lead`; appends one entry per atomic customer question
per the question-asking protocol in `CLAUDE.md` § "FIRST ACTIONS"
Step 2. `qa-engineer` reads the log to audit intake-flow conformance
against `docs/qa/intake-conformance.md`.

Canonical question-batching rule (binding, identical wording in
`CLAUDE.md`, `docs/FIRST_ACTIONS.md`, `.claude/agents/tech-lead.md`, and
`docs/OPEN_QUESTIONS.md`):

> Batch questions internally in docs/OPEN_QUESTIONS.md.
> Do not batch customer-facing questions.
> Ask one queued customer question per turn, only when all agents and tools are idle, with the question as the final line.

The `agents-running-at-ask: []` invariant in Hard rule #3 below is the
intake-log audit surface for that rule; the Customer Question Gate in
`.claude/agents/tech-lead.md` (FR-011) and `scripts/lint-questions.sh`
(FR-012) are the runtime enforcement.

## Format

Each turn is a YAML block, separated by `---`. Fields marked
**required**; other fields optional.

```
---
turn: 42                                    # required, monotonic
timestamp: 2026-04-23T19:47Z                # required, UTC ISO-8601
asked-by: tech-lead                         # required; agent name
framing: |                                  # required; full question
  <the question exactly as sent to the customer, preserving
  framing, options offered, and any defaults recommended>
options-presented: [a, b, c, d]             # optional; labels only
recommended-default: a                      # optional
agents-running-at-ask: []                   # required; invariant MUST be []
                                            #  (enforced by atomic-
                                            #  question + all-agents-
                                            #  idle rule)
customer-answer: |                          # required; verbatim
  <verbatim customer reply>
decision: <one-line outcome>                # required
cross-refs:                                 # required if applicable
  - CUSTOMER_NOTES.md#entry-2026-04-23-ai-training-scope
  - docs/OPEN_QUESTIONS.md#Q-0012
  - docs/pm/CHARTER.md§8
notes: <optional context that did not fit above>
```

## Hard rules (binding)

1. **Append-only.** Never edit a prior entry. Corrections are a new
   entry with `cross-refs:` back to the superseded entry and a
   `notes:` field explaining the correction.
2. **Monotonic `turn:`.** No gaps, no reuse.
3. **`agents-running-at-ask:` invariant.** The field MUST be `[]`
   for every entry. If it is not empty, the atomic-question rule
   was violated; `qa-engineer` flags the conformance failure.
4. **Verbatim `customer-answer`.** No paraphrase in this field.
   Paraphrases belong in `decision:` or `notes:`.
5. **Cross-ref completeness.** Every entry that landed a decision
   in `CUSTOMER_NOTES.md`, `docs/pm/CHARTER.md`, or
   `docs/OPEN_QUESTIONS.md` MUST cite it. `researcher` mirrors
   back — every `CUSTOMER_NOTES.md` entry added after the intake
   log begins cites an intake-log `turn:`.

## Rendering

Run `scripts/intake-show.sh [--from N] [--to M] [--since DATE]` to
print the log as a readable transcript. Output is suitable for
customer review and for `qa-engineer` conformance-audit input.

## Example entries

```
---
turn: 1
timestamp: 2026-04-23T19:02Z
asked-by: tech-lead
framing: |
  Do you want this project to participate in upstream issue
  feedback? When the team hits a gap in this framework … Issues
  include the template version, a short description, and (if the
  project is sensitive) a redacted excerpt. Yes / No.
options-presented: [yes, no]
recommended-default: (none — atomic yes/no)
agents-running-at-ask: []
customer-answer: |
  yes
decision: issue-feedback opt-in enabled; tech-lead follows
  docs/ISSUE_FILING.md for every gap encountered
cross-refs:
  - CUSTOMER_NOTES.md#2026-04-23-issue-feedback-opt-in
---
turn: 2
timestamp: 2026-04-23T19:04Z
asked-by: tech-lead
framing: |
  Pick a naming category for the team (examples: Muppets, famous
  singers, classical composers, historical scientists, fictional
  detectives, chess world champions, mountaineers, poets, Nobel
  laureates). I'll propose names balanced across genders…
options-presented: []
recommended-default: canonical role names
agents-running-at-ask: []
customer-answer: |
  stick with canonical names for now
decision: no Step-3 naming; agents referenced by canonical role
cross-refs:
  - docs/AGENT_NAMES.md  (documents the "canonical" decision)
```

---

Roll entries into `docs/intake-log-ARCHIVE.md` at project close per
`researcher.md` § "Archival + size budgets" — append-only archive
with the live file truncated to the last milestone's worth of
entries. Soft cap: 200 live entries.
