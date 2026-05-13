# Token-economy baseline (M0)

**Captured at**: 2026-05-13T18:19:26Z
**Template SHA**: 7e93bb5d0841aa0310c825cf3b0c0c48bb317d3f
**Source plan**: sw_dev_template_implementation_plan-2.md

## Per-agent contract sizes

| Role | Lines | Words (token proxy) |
|---|---:|---:|
| architect | 157 | 844 |
| code-reviewer | 88 | 528 |
| onboarding-auditor | 155 | 944 |
| process-auditor | 225 | 1253 |
| project-manager | 184 | 1124 |
| qa-engineer | 191 | 1061 |
| release-engineer | 108 | 689 |
| researcher | 283 | 1996 |
| security-engineer | 148 | 865 |
| sme-template | 128 | 792 |
| software-engineer | 96 | 555 |
| sre | 101 | 595 |
| tech-lead | 565 | 3909 |
| tech-writer | 62 | 357 |

## Live register sizes

| File | Rows | Words |
|---|---:|---:|
| docs/OPEN_QUESTIONS.md | 13 | 721 |
| docs/intake-log.md | 0 | 0 |
| docs/pm/RISKS.md | 5 | 857 |
| docs/pm/LESSONS.md | 0 | 1526 |
| CUSTOMER_NOTES.md | 0 | 154 |
| docs/pm/SCHEDULE.md | 15 | 458 |

## OPEN_QUESTIONS answered-rows-still-live: 12

## PM schedule length: 60 lines

## Downstream repos

| Repo | docs/intake-log.md | TEMPLATE_VERSION |
|---|---|---|
| QuackDCS | missing | v1.0.0-rc8 |
| QuackPLC | missing | v1.0.0-rc8 |
| QuackS7 | present | v1.0.0-rc8 |
| QuackSim | present | v1.0.0-rc8 |

## Broken internal references (cap 25)

_None._

## M1.1 token-reduction evidence (post-T013)

Post-condition snapshot for milestone M1.1 (token quick wins). The M0
section above remains the canonical snapshot at SHA `eb4fdac` (HEAD
before branch `feat/m1-token-quick-wins`). The numbers below are taken
after the canonical/manual split (T010–T012) and the runtime-contract
compile pass (T013, `scripts/compile-runtime-agents.sh`).

**Source plan**: `specs/006-template-improvement-program/plan.md` §M1.1.
**Source spec**: `specs/006-template-improvement-program/spec.md`
§SC-001, §SC-002.
**Source research**: `specs/006-template-improvement-program/research.md`
R-4 (rationale-absorption pattern).

**Artifacts producing the numbers** (per agent `<role>`):

- Canonical contract (post-split): `.claude/agents/<role>.md`
- Manual (rationale absorption): `docs/agents/manual/<role>-manual.md`
- Generated runtime contract: `docs/runtime/agents/<role>.md`
  (produced by `scripts/compile-runtime-agents.sh`, T013)

| Agent | M0 baseline (canonical) | Post-M1.1 canonical | Generated runtime contract | Reduction (runtime vs M0) |
|---|---:|---:|---:|---|
| tech-lead | 3909 words | 2320 | 2251 | 42.4% — **passes SC-001 (≥30%)** |
| researcher | 1996 words | 1604 | 1590 | 20.3% — **passes SC-002 (≥20%)** (post-T024 archival-mechanic rule added +22 words; clears the floor by 0.3 points) |
| code-reviewer | 528 words | 535 | 520 | 1.5% — **SC-002 "where safe" clause invoked** (canonical was already lean; no rationale to extract; further reduction would require deleting normative content) |
| qa-engineer | 1061 words | 737 | 663 | 37.5% — **passes SC-002 (≥20%)**; +178 words added via T017 follow-up to create explicit `## Hard rules` section for schema completeness |

### Per-agent pass/fail

- **tech-lead — PASS (SC-001).** Runtime 2251 vs M0 3909 = 42.4%
  reduction, well above the SC-001 ≥30% floor. Reduction was achieved
  by absorbing rationale and routing examples into
  `docs/agents/manual/tech-lead-manual.md` and shrinking the canonical
  contract under `.claude/agents/tech-lead.md` to normative routing and
  hard-rule references only.
- **researcher — PASS (SC-002).** Runtime 1590 vs M0 1996 = 20.3%
  reduction, above the SC-002 ≥20% floor by 0.3 points. Rationale and
  Tier-1 source guidance moved to `docs/agents/manual/researcher-manual.md`.
  Post-T024 added a 5-line archive-mechanic rule (+22 runtime words);
  margin is intentionally close to the floor — future researcher edits
  must re-measure SC-002 at gate close.
- **code-reviewer — "WHERE SAFE" clause invoked (SC-002).** Runtime
  520 vs M0 528 = 1.5% reduction. The M0 canonical contract was
  already lean (528 words, the second-shortest in the roster after
  `tech-writer`); there was no extractable rationale to absorb into a
  manual without deleting normative review-gate content. SC-002's
  "where safe" clause applies. Non-blocking observation routed to
  `docs/pm/LESSONS.md` under the new `## M1.1 evidence (2026-05-13)`
  heading.
- **qa-engineer — PASS (SC-002).** Runtime 663 vs M0 1061 = 37.5%
  reduction, above the SC-002 ≥20% floor. The post-split canonical
  (737 words) is +178 words above what a pure rationale-absorption
  pass would have produced; the addition is the explicit `## Hard
  rules` section added in T017 to satisfy schema completeness across
  the roster. Even with that addition, the runtime contract still
  clears SC-002 comfortably.

### Aggregate status

SC-001 (tech-lead ≥30% reduction): **PASS** at 42.4%.
SC-002 (other targeted agents ≥20% where safe): **PASS** with one
documented "where safe" invocation (code-reviewer).

## M6 prompt-regression run (2026-05-13)

T063 ran `tests/prompt-regression/run.sh` against the full 13-fixture
set (5 agents: tech-lead, researcher, code-reviewer, qa-engineer,
project-manager) in stub mode. Compiler (`scripts/compile-runtime-agents.sh`)
exited 0; 9 compact runtime contracts current at HEAD.

- `--validate-only`: 13 / 13 fixtures PASS schema validation.
- `--canonical`: 13 / 13 STUB-execute against `.claude/agents/<agent>.md`;
  0 skipped.
- `--compiled`: 13 / 13 STUB-execute against
  `docs/runtime/agents/<agent>.md`; 0 skipped (project-manager runtime
  contract present post-T060-prework, so both `no-op-pm-pass` and
  `stale-schedule-delta` STUB rather than SKIP).
- SC-013 structural pass: both lint and regression complete against
  canonical and compiled sources with no skip gaps.
- Phase-3+ follow-up: real LLM-driven execution (not stub) deferred per
  T011 design; logged in `docs/pm/LESSONS.md`.
