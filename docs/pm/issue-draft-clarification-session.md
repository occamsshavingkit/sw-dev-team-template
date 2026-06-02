## Template version

v1.1.1
SHA 2984c6890046c48c577b7cd3ba3b4d344622b526

## Where

- `CLAUDE.md` Hard Rule #11 — "one queued customer question per
  turn, only when all agents and tools are idle, as the FINAL line
  of the turn"
- `.claude/agents/tech-lead.md` § "Customer Question Gate" (FR-011)
- `docs/FIRST_ACTIONS.md` — scoping question guidance
- `docs/templates/scoping-questions-template.md` — "ask them one per
  turn with all agents idle"
- `docs/OPEN_QUESTIONS.md` — queue guidance

## What happened

A project had a queue of N scoping questions that all required
customer input before design could proceed. Following the "one per
turn, only when idle" framing literally meant N separate sessions,
each requiring the customer to reload context from scratch. When
`tech-lead` instead asked questions back-to-back in one sitting —
each atomic, each the final line of its turn, agents idle — the
customer confirmed this was the correct and preferred behavior. The
framework had no name for this mode and no documentation blessing
it, so the team had treated it as a rule violation and avoided it.

Customer ruling (2026-06-02): atomicity governs *shape* (one
decision axis per prompt), not *cadence* (one question per session).
A clarification session that drains the queue turn-by-turn while the
customer is engaged is fully compliant, provided each question is
single-axis and is the final line of its turn.

Provenance: surfaced in a Gemini external review of the team design
(2026-06-02); customer ruling confirmed same session.

## Why it is a gap

Hard Rule #11 was authored to prevent bundled-axis violations (the
actual problem). Its phrasing — "one per turn, only when idle" — is
necessary but does not distinguish session-level cadence from
prompt-level shape. Without a named and blessed "clarification-
session" mode, teams over-apply the rule and fragment intake across
sessions unnecessarily, degrading both throughput and customer
context continuity.

## Suggested fix

Name and bless a "clarification-session" mode in:
- `CLAUDE.md` Hard Rule #11 — add a sentence explicitly
  distinguishing shape (one axis per prompt, binding) from cadence
  (back-to-back turns in one sitting are permitted and preferred
  when a queue requires it).
- `.claude/agents/tech-lead.md` § Customer Question Gate — when a
  queue of open questions exists and the customer is engaged, drain
  it one-atomic-question-per-turn in the same session; do not defer
  to a future session.
- `docs/OPEN_QUESTIONS.md` header guidance — note that a
  clarification session is the preferred drain mechanism.
- `docs/templates/scoping-questions-template.md` — update "one per
  turn" annotation to clarify it means one per prompt, not one per
  session.

The fix is documentation-only; no enforcement-script change is
needed because `scripts/lint-questions.sh` already lints prompt
shape (axis count), not session cadence.
