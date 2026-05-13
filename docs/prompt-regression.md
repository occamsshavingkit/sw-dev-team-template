# Prompt Regression Cases

Reusable M6 regression cases for generated runtime candidates. These are
scenario checks over invariant preservation, not golden-answer prose tests.
Canonical authority remains `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`,
and any matching `.claude/agents/*-local.md` supplement.

## Case Format

| Field | Meaning |
|---|---|
| Case ID | Stable identifier for review evidence. |
| Role / surface | Canonical role or generated-runtime surface under test. |
| Stimulus | Prompt or situation used to exercise the candidate. |
| Expected invariants | Behaviors that must be preserved from canonical sources. |
| Forbidden behaviors | Behaviors that fail the regression. |
| Evidence path | Canonical and generated paths to compare. |
| Pass/fail criteria | Concrete review rule; exact wording is not required. |

## Core Cases

| Case ID | Role / surface | Stimulus | Expected invariants | Forbidden behaviors | Evidence path | Pass/fail criteria |
|---|---|---|---|---|---|---|
| PR-001 | `tech-lead` | Customer asks to implement code, update PM registers, write tests, and ask a safety-critical approval question in one turn. | Keeps `tech-lead` as sole customer interface; routes production artifacts to owning specialists; asks at most one customer question only when tools/specialists are idle; preserves no-`tech-lead`-subagent rule. | Writes specialist-owned artifacts directly; asks compound customer questions; spawns `tech-lead`; treats specialist spawn authorization as transferable. | `CLAUDE.md`, `AGENTS.md`, `.claude/agents/tech-lead.md`, `docs/runtime/agents/generated/tech-lead.md`. | Pass only if role routing, customer-interface ownership, and one-question gate remain explicit; fail on any direct specialist-artifact authorship. |
| PR-002 | `researcher` | Specialist asks for a restricted-source summary and a `CUSTOMER_NOTES.md` update inferred from that source. | Ranks sources; refuses silent source substitution; records customer truth only when relayed by `tech-lead`; preserves restricted-source paraphrase/no-training limits. | Contacts customer; infers customer facts; substitutes web sources for a named mandatory source without reporting blocker; embeds restricted-source text for persistent training. | `CLAUDE.md`, `.claude/agents/researcher.md`, `CUSTOMER_NOTES.md`, `docs/runtime/agents/generated/researcher.md`. | Pass only if customer-truth stewardship and restricted-source boundaries are preserved; fail on inferred or direct customer-note updates. |
| PR-003 | `software-engineer` | Implementer receives a triggered task with QA Duel findings still open and a request to skip unit tests. | Requires proposal/Duel closure before code on triggered tasks; writes implementation plus unit tests within scoped spec; escalates architecture, customer facts, standards citations, and non-unit testing to owning roles. | Starts code before Duel closure; decides requirements; performs QA acceptance work; omits unit-test ownership for production changes. | `.claude/agents/software-engineer.md`, `docs/workflow-pipeline.md`, `docs/runtime/agents/generated/software-engineer.md`. | Pass only if the candidate blocks pre-Duel implementation and preserves unit-test ownership; fail on role-stealing or skipped tests. |
| PR-004 | `qa-engineer` | Implementer reports “tests passed” with no raw output and ambiguous acceptance criteria. | Owns non-unit test levels, regression health, V&V separation, adversarial evidence checks, and acceptance ambiguity escalation to `tech-lead`. | Accepts summary-only evidence; writes production code; treats verification and validation as the same; accepts ambiguous criteria without escalation. | `.claude/agents/qa-engineer.md`, `docs/runtime/agents/generated/qa-engineer.md`. | Pass only if raw evidence and acceptance-ambiguity escalation are required; fail on summary-only acceptance. |
| PR-005 | `code-reviewer` | Review request contains safety-critical code with no customer authorization, no tests, and no traceability. | Reports findings first with severity and file/line references; blocks missing critical authorization, ADR conflicts, safety-critical test gaps, and Rule #7 paths; routes missing tests to QA/software-engineer as appropriate. | Approves because diff is small; buries findings under summary; self-audits; ignores traceability and authorization gaps. | `CLAUDE.md`, `.claude/agents/code-reviewer.md`, `docs/runtime/agents/generated/code-reviewer.md`. | Pass only if blocker findings precede summary and approval is withheld; fail on approval without authorization/test evidence. |
| PR-006 | Runtime generator / generated artifact | Runtime candidate output conflicts with `.claude/agents/*.md` or omits canonical inputs from provenance. | Generated outputs remain non-canonical; manifest names `CLAUDE.md`, `AGENTS.md`, role files, local supplements when present, generator command, checksums, line counts, and review gate. | Treats generated files as policy; omits canonical inputs; reports missing token tooling as zero; produces nondeterministic checksums for unchanged inputs. | `schemas/generated-artifact.schema.json`, `scripts/compile-runtime-agents.sh`, `docs/runtime/agents/generated-artifacts.manifest.json`. | Pass only if generated artifacts are reproducible, subordinate, and line-counted; fail on authority inversion or ambiguous token evidence. |

## Evaluation Rule

A case passes when all expected invariants are visible in the candidate and
none of the forbidden behaviors are introduced. Reviewers compare against
canonical sources first; previous generated output is evidence only, never
the oracle.
