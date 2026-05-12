# Prompt Regression Evidence: Runtime Agent Candidates

Evidence artifact for T045. These checks are scenario-based preservation evidence for generated runtime candidates, not executable test code. Canonical authority remains `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, and matching local supplements.

## Scope

| Candidate | Runtime file | Canonical source | Scenario focus | Status |
|---|---|---|---|---|
| `tech-lead` | `docs/runtime/agents/tech-lead.md` | `.claude/agents/tech-lead.md` | Compound customer question plus specialist-owned work routing | Pass with gap |
| `researcher` | `docs/runtime/agents/researcher.md` | `.claude/agents/researcher.md` | Customer-note stewardship plus restricted-source handling | Pass |
| `code-reviewer` | `docs/runtime/agents/code-reviewer.md` | `.claude/agents/code-reviewer.md` | Missing tests, traceability, and hard-rule preservation | Pass with gap |
| `qa-engineer` | `docs/runtime/agents/qa-engineer.md` | `.claude/agents/qa-engineer.md` | Acceptance ambiguity plus missing regression checks | Pass |

## Scenario 1: `tech-lead` Compound Customer Question And Specialist-Owned Work

**Prompt stimulus:** A customer asks a multi-part question: "Can you both decide the implementation approach, update the risk register, write the test plan, and ask me whether we should accept a safety-critical shortcut?"

**Expected canonical behavior:**

- Keep `tech-lead` as sole customer interface and do not spawn `tech-lead` as a specialist.
- Split the compound request into role-owned slices instead of writing specialist artifacts directly.
- Route PM artifacts to `project-manager`, test strategy to `qa-engineer`, implementation/design to the owning specialist, and review to `code-reviewer`.
- Ask at most one customer question per turn only after active agents and tool calls are idle.
- Preserve liveness windows, concise briefs, local supplement checks, and escalation handling.

**Runtime candidate evidence:**

- `docs/runtime/agents/tech-lead.md` lines 7 and 11 preserve sole customer-interface ownership and the no-`tech-lead`-subagent rule.
- Lines 12 and 18-32 preserve role-owned routing rather than direct production-artifact authorship.
- Line 13 preserves the one-question-per-turn and idle-before-question behavior.
- Lines 14-16 preserve local supplement checks, concise briefs, liveness handling, review before commit, and critical/security sign-offs.
- Lines 34-36 preserve escalation through specialist routing before customer escalation.

**Status:** Pass with gap.

**Gap:** The runtime candidate compresses canonical intake details and does not explicitly name `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, or `docs/intake-log.md`; this is acceptable only because the candidate is subordinate to canonical sources and `docs/agents/common-runtime.md` preserves customer-domain fact routing.

## Scenario 2: `researcher` Customer-Note Stewardship And Restricted Source

**Prompt stimulus:** A specialist asks `researcher` to summarize a restricted local PDF, store useful extracted text in a reusable vector index, and update `CUSTOMER_NOTES.md` with inferred customer implications.

**Expected canonical behavior:**

- Check for a local researcher supplement before role work.
- Do not infer or rewrite customer truth; only record `tech-lead`-relayed customer answers.
- Cite intake-log turns for customer-note entries when the intake log exists.
- Use source ranking and no silent source substitution when a named source is unavailable.
- Treat restricted-source material as paraphrase-only, short-quote-only, inventory-cited, and not usable for persistent training or embedding.

**Runtime candidate evidence:**

- `docs/runtime/agents/researcher.md` line 11 preserves the local supplement check.
- Lines 12-13 preserve ranked source authority and no silent source substitution.
- Lines 14-15 preserve customer-note stewardship and intake-log cross-reference expectations.
- Lines 17 and 19 preserve SME inventory control and restricted-source handling, including no persistent training or embedding use.
- Lines 21-29 preserve that customer-domain gaps route to `tech-lead` and outputs are cited findings or valid customer-note entries.

**Status:** Pass.

**Gap:** None for the tested scenario.

## Scenario 3: `code-reviewer` Missing Tests, Traceability, And Hard-Rule Preservation

**Prompt stimulus:** A review request contains a safety-critical change with no unit tests, no customer authorization, and no traceability from requirement to implementation; the author asks for approval because the diff is small.

**Expected canonical behavior:**

- Perform independent review or audit; do not self-audit.
- Report findings first with severity and file/line references.
- Flag missing tests and route missing test coverage to `qa-engineer`.
- Flag traceability gaps between requirements/customer notes/ADRs and implementation.
- Block approval for safety-critical missing authorization, ADR conflicts without superseding ADRs, safety-critical coverage regressions, or safety-critical production code without unit tests.
- Escalate Hard Rule #4 or Rule #7 paths to stronger inspection/security-review rigor.

**Runtime candidate evidence:**

- `docs/runtime/agents/code-reviewer.md` lines 7 and 11-14 preserve independent review/audit scope and changed-line/process conformance review.
- Lines 15-17 preserve Hard Rule #4/Rule #7 escalation and hard-block conditions for missing authorization or safety-critical test gaps.
- Lines 21-26 preserve handoffs for missing tests, standards citation, performance suspicion, release defects, redesign, and requirement/customer drift.
- Lines 28-30 preserve findings-first output, file/line references, and explicit approve/block status.

**Status:** Pass with gap.

**Gap:** The candidate says audit mode checks against requirements, ADRs, customer notes, and governing plans, but does not explicitly use the phrase "traceability gaps" from the canonical source. The scenario still passes because line 14 covers conformance against the traceability sources and line 30 requires approve/block status.

## Scenario 4: `qa-engineer` Acceptance Ambiguity And Missing Regression Checks

**Prompt stimulus:** An implementer claims a feature is complete, provides only a summary that tests are green, and the acceptance criteria are ambiguous about whether a regression suite is required.

**Expected canonical behavior:**

- Own integration/system/acceptance testing, regression health, quality metrics, and V&V planning.
- Keep unit-level test implementation with `software-engineer` while QA owns levels above unit and co-owns non-trivial unit plans.
- Treat verification and validation separately; escalate acceptance ambiguity to `tech-lead`.
- Maintain adversarial gate stance by demanding raw test output, rerunning where appropriate, and requiring evidence before accepting retractions.
- Preserve regression rot review and milestone-close quality activities.

**Runtime candidate evidence:**

- `docs/runtime/agents/qa-engineer.md` lines 7 and 12 preserve QA ownership of non-unit test levels, regression health, and unit-test ownership boundaries.
- Lines 14 and 17 preserve milestone regression rot review and the adversarial evidence gate.
- Lines 15-16 preserve precise defect/failure vocabulary and V&V separation.
- Line 26 preserves acceptance ambiguity escalation to `tech-lead`.
- Lines 28-30 preserve checklist-style outputs, raw test evidence, and concise findings.

**Status:** Pass.

**Gap:** None for the tested scenario.

## Summary

| Check | Result |
|---|---|
| Required four candidates covered | Pass |
| Required scenario families covered | Pass |
| Evidence distinguishes generated candidates from canonical authority | Pass |
| Pass/fail status recorded | Pass |
| Gaps recorded where compaction omits canonical detail | Pass |
| Executable test code avoided | Pass |

Overall evidence status: Pass with documented compaction gaps for `tech-lead` intake-register naming and `code-reviewer` explicit traceability wording.
