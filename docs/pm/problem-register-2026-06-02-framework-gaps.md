# Problem register — framework gaps 2026-06-02

## Context

This register captures framework gaps surfaced in a multi-turn
investigation on branch `016-token-economy-design` (2026-06-02).
All evidence items are verified this session; none are hypothetical.

Cross-references:
- Issue #292 — filed upstream; covers P3–P6.
- `fw-adr-0021` (`docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`)
  — architect ADR covering P7, P8, and P9 (leaf-task handoff and
  dispatch-granularity discipline).

## Standing decision

**Flat files are the canonical source of truth.** A database is only
ever a derived, disposable index or cache layer — the same boundary
that `claude-mem` occupies: when repo and memory disagree, the repo
wins. This is not a problem to solve; it is a constraint that informs
solutions to P2, P5, and the P11 enforcement layer.

## Problem index

| ID | One-line statement | Status | Owner |
|---|---|---|---|
| P1 | ID number collisions across parallel branches | open | architect |
| P2 | Monolithic append files grow unbounded | open | architect |
| P3 | `CUSTOMER_NOTES.md` used as a decision-journal | filed #292 | framework |
| P4 | `DECISIONS.md` abandoned; decision content homeless and triplicated | filed #292 | framework |
| P5 | `OPEN_QUESTIONS.md` never drained; no queue lifecycle | filed #292 | framework |
| P6 | No machine enforcement of `CUSTOMER_NOTES.md` entry scope or size | filed #292 | framework |
| P7 | Handoffs scoped at feature altitude, not leaf T### | open, ADR fw-adr-0021 | architect |
| P8 | `AGENTS.md` has no delegated-specialist mode | open, new issue | architect |
| P9 | Claude-to-Claude dispatch granularity is folklore, not gated | open, ADR fw-adr-0021 | architect |
| P10 | Multi-model audits lack equivalent briefs and a divergence-reconciliation rule | open, lower priority | architect |
| P11 | Through-line: prose-only discipline without enforcement gates | systemic finding | architect |
| P12 | Gemini has no co-equal full-team harness adapter | DESIGNED, fw-adr-0022, impl open | architect + release-engineer |

---

## P1 — ID number collisions

**Statement.** ADR, spec, and Q IDs drawn from a shared monotonic
counter are claimed in parallel branches and sessions without
coordination, producing collisions.

**Evidence.** `scripts/reserve-number.sh` exists in the framework
repo but is not enforced; no CI gate or pre-commit hook prevents
a second author from claiming the same ID independently on a
concurrent branch.

**Root cause.** Enforcement gap: the reservation script is advisory.
No lock or authoritative registry is checked before an ID is used.

**Status.** Open.

**Owner / next step.** `architect` — evaluate whether a
server-side authoritative counter (e.g., GitHub issue number as
ID source) or a pre-commit hook on ID-bearing files closes the
gap without adding heavy infrastructure.

---

## P2 — Monolithic append files

**Statement.** Key registers grow as single, unbounded append files;
they become too large to load in agent context.

**Evidence.** In a downstream project on comparable template
lineage: `CUSTOMER_NOTES.md` 531 KB, `OPEN_QUESTIONS.md` 232 KB,
`docs/intake-log.md` 221 KB. Soft-cap warnings (researcher role,
500-line cap for `CUSTOMER_NOTES.md`) were not sufficient to arrest
growth.

**Root cause.** Append-only design with no structural sharding or
archival gate. Soft caps are advisory prose; archival is a manual
cadence step.

**Status.** Open.

**Owner / next step.** `architect` — evaluate two fix directions:
(a) directory-of-small-files with a generated index, or (b)
date/quarter sharding with a rolling active file. Either direction
must remain compatible with the flat-files-are-canonical standing
decision above.

---

## P3 — CUSTOMER_NOTES used as a decision-journal

**Statement.** `CUSTOMER_NOTES.md` has drifted from its specified
role (verbatim customer rulings) into a general-purpose
decision-and-context journal.

**Evidence.** Downstream project: 531 KB, 108 entries, median
entry 68 lines, maximum 690 lines, zero entries at or under 10
lines, 73 entries over 50 lines. Invented template sections not
defined anywhere: `Context` (×75), `Cross-refs` (×60),
`Downstream effects` (×16), `Process notes` (×9). Only 76 of 108
entries (~70%) contain a `Customer answer` field; approximately
30% are not customer rulings at all.

**Root cause.** See P6 (no machine enforcement). The template
defines the entry shape in prose; no lint or gate verifies
conformance at write time.

**Status.** Filed as issue #292.

**Owner / next step.** Framework — addressed in #292.

---

## P4 — DECISIONS.md abandoned, decision content homeless and triplicated

**Statement.** `DECISIONS.md` is effectively abandoned as a
decision register; decision content has migrated into
`CUSTOMER_NOTES.md`, `intake-log.md`, and `OPEN_QUESTIONS.md`,
producing triplication with no single authoritative record.

**Evidence.** `DECISIONS.md` at 47 lines (stub level). One
tracked question (Q-0065) appears 44 times in `CUSTOMER_NOTES.md`,
13 times in `intake-log.md`, and 2 times in `OPEN_QUESTIONS.md`.

**Root cause.** `DECISIONS.md` purpose and lifecycle are
underspecified; agents default to whichever file they are already
editing, so content scatters.

**Status.** Filed as issue #292.

**Owner / next step.** Framework — addressed in #292.

---

## P5 — OPEN_QUESTIONS never drained

**Statement.** `OPEN_QUESTIONS.md` accumulates questions without a
lifecycle for closing or archiving resolved ones; it grows until it
is no longer useful as a working queue.

**Evidence.** Downstream project: `OPEN_QUESTIONS.md` at 232 KB;
single entries reaching 16 KB; resolved questions present with no
move or deletion.

**Root cause.** Queue lifecycle (resolved → archive) is defined in
the researcher role contract (soft budget + archival mechanic) but
has no machine enforcement or exit-criteria gate.

**Status.** Filed as issue #292.

**Owner / next step.** Framework — addressed in #292.

---

## P6 — No machine enforcement of CUSTOMER_NOTES entry scope and size

**Statement.** `customer-notes-guard.py` is a content-blind
approval gate; it does not enforce entry shape, section vocabulary,
or size limits defined in the governing prose rules.

**Evidence.** Script verified identical in content at rc8, rc9,
rc13, rc14, and v1.1.1 — no structural evolution toward lint
capability. Governing rules are advisory prose in the researcher
agent contract and researcher manual only.

**Root cause.** Guard script was designed as an approval gate
(human-in-the-loop confirmation), not as a content linter. The
lint layer was never built.

**Status.** Filed as issue #292.

**Owner / next step.** Framework — addressed in #292. Lint
direction: schema-validate required fields (`Customer answer`
present, section headings from allowed set, entry line-count
within cap) as a pre-commit or CI step.

---

## P7 — Handoffs scoped at feature altitude, not leaf T###

**Statement.** `fw-012` handoff objectives cover a whole feature;
the dispatch unit is not the leaf task, so a handoff agent
receives more context than it needs and the token budget is poorly
bounded.

**Evidence.** `fw-012-v1-1-handoff-contracts.json` handoff
objective covers a full feature. Generated `tasks.md` files and
`docs/templates/task-template.md` both carry JIT-file-list and
token-budget fields at the T### level, but the handoff schema does
not reference them; the leaf task is not the dispatch unit on
either the Claude or Codex path.

**Root cause.** Handoff contract schema was designed before the
leaf-task decomposition was articulated as a dispatch principle;
the two layers were never connected.

**Status.** Open; architect ADR `fw-adr-0021` drafted this session.

**Owner / next step.** `architect` — ADR defines leaf T### as
the canonical dispatch unit, connects task-template JIT-file-list
and token-budget fields to the handoff schema, and specifies the
per-task context assembly rule.

---

## P8 — AGENTS.md has no delegated-specialist mode

**Statement.** `AGENTS.md` documents only the main-session
orchestrator mode; a tool-invoked (delegated) Codex instance has
no documented role-binding path, so it defaults to orchestrator
behavior and attempts to spawn agents.

**Evidence.** `AGENTS.md` contains no section or field directing a
delegated Codex invocation to assume the handoff role, execute a
single task directly, and suppress agent spawning. The schema
fields `codex_allowed` and `bounded_codex_exception` exist in the
handoff contract but the connection from those fields to an
`AGENTS.md` behavioral mode is absent.

**Root cause.** The delegated-specialist invocation pattern was not
anticipated when `AGENTS.md` was written; only the main-session
(orchestrator) and bounded-Codex-exception paths are documented.

**Status.** Open; new upstream issue filed this session. Pairs with
ADR `fw-adr-0021`.

**Owner / next step.** `architect` — add a delegated-specialist
mode section to `AGENTS.md` specifying: detect invocation via
handoff contract, assume the handoff-designated role, execute the
single leaf task directly, and suppress spawning unless the task
explicitly authorizes it. Wire to `codex_allowed` /
`bounded_codex_exception` schema fields.

---

## P9 — Claude-to-Claude dispatch granularity is folklore, not gated

**Statement.** The rule that Claude subagents dispatch one task at
a time (JIT, single-T###) is stated in spec 016 as binding prose
but has no hook or gate enforcement.

**Evidence.** No pre-close hook, CI check, or harness-level
constraint prevents a Claude subagent dispatch from bundling
multiple T### items. Spec 016 codifies the rule in prose only.

**Root cause.** Same through-line as P3–P6 (P11): enforcement
layer was not built alongside the rule.

**Status.** Open; architect ADR `fw-adr-0021` drafted this session.

**Owner / next step.** `architect` — ADR specifies the
enforcement mechanism (pre-close checklist item, harness hook, or
task-schema constraint) that makes single-task dispatch a gate,
not a guideline.

---

## P10 — Multi-model audits lack equivalent briefs and a divergence-reconciliation rule

**Statement.** When Gemini, Codex, and Claude each run a milestone
audit, each agent receives a different implicit context (they are
conversation-blind); there is no rule requiring equivalent briefs
or specifying how `tech-lead` reconciles divergent findings.

**Evidence.** No brief template for multi-model audits exists in
`docs/templates/`. No reconciliation rule is recorded in
`CLAUDE.md`, `AGENTS.md`, or any agent contract.

**Root cause.** Multi-model audit pattern emerged operationally;
framework documentation has not caught up.

**Status.** Open, lower priority than P7–P9.

**Owner / next step.** `architect` — propose a brief template
(self-contained context bundle for conversation-blind agents) and
a reconciliation rule (tech-lead arbitrates divergence;
customer-ruling required when findings conflict on a binding
decision axis).

---

## P11 — Through-line: prose-only discipline without enforcement gates

**Statement.** The framework repeatedly encodes discipline as
advisory or binding prose but does not enforce it with gates;
outcomes therefore track operator discipline rather than structural
constraint. This is the common root cause of P3, P4, P5, P6, and P9.

**Evidence — control comparison.** Two downstream projects on
comparable template lineage were measured:
- Project A: `CUSTOMER_NOTES.md` at 531 KB / 108 entries / median
  68 lines / 73 entries over 50 lines — approximately 30% of
  entries are not customer rulings.
- Project B: comparable lineage, healthy by the same metrics
  (median 24-line entries, near-zero invented sections,
  `DECISIONS.md` in active use).

The ~3× to ~30× divergence on `CUSTOMER_NOTES.md` health between
projects isolates operator discipline as the dominant variable.
The framework provided the same prose rules to both projects; only
one followed them. This is structural evidence that prose rules
alone are insufficient.

**Root cause.** The enforcement layer — lint scripts, CI gates,
pre-commit hooks, schema validation — was systematically deferred
or not built. Each individual rule is correct; the gap is that
no rule has a machine-checkable exit criterion.

**Status.** Systemic finding. Not a single-issue fix; ADR
`fw-adr-0021` and issue #292 together begin addressing it.

**Owner / next step.** `architect` — establish a framework policy
that every new binding prose rule names its enforcement mechanism
at authorship time (lint target, hook, schema field, or explicit
"manual-only with rationale"). Retrofit enforcement to P3–P6 and
P9 as the highest-priority instances. Log as a standing
architectural concern.

---

## P12 — Gemini has no co-equal full-team harness adapter

**Statement.** Gemini has no `GEMINI.md` team adapter and no
`.gemini/agents/` role roster, making it a second-class harness.
Claude (`.claude/agents/`), Codex (`AGENTS.md`), and OpenCode
(`.opencode/agents/`) each have a full-team adapter; Gemini has
only `.gemini/commands/` (Spec-Kit TOMLs).

**Evidence.** Template ships no `GEMINI.md`; `.gemini/agents/` is
absent while `.opencode/agents/` carries all 13 roles. A live
Gemini session confabulated a non-existent `invoke_agent` tool by
reading the repo's `AGENTS.md` — a concrete instance of P10. Tier-1
lookup confirmed gemini-cli has native named subagents since
v0.38.1 (stable v0.44.0); definitions live in `.gemini/agents/*.md`
and the context file is `GEMINI.md`, so a full-team Gemini adapter
is mechanically possible.

**Root cause.** The Gemini harness adapter was never built when
multi-harness support was added. Codex and OpenCode received
adapters; Gemini received only slash-commands.

**Status.** DESIGNED — `fw-adr-0022` accepted 2026-06-02;
implementation open.

**Owner / next step.** `architect` + `release-engineer` — implement
`fw-adr-0022`: author `GEMINI.md` adapter; generate
`.gemini/agents/` roster via `compile-runtime-agents.sh` with
descriptions copied from canonical `.claude/agents/`; lint via
existing `lint-agent-contracts.sh` / canonical SHA; require
gemini-cli >= v0.38.1. Pairs with #293 (shared delegated-specialist
mode).
