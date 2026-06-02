# Findings — CUSTOMER_NOTES.md scope drift (2026-06-02)

## Summary

`CUSTOMER_NOTES.md` entry scope is governed only by advisory prose in
`researcher.md` and the soft-size-budget rule. Nothing in the framework
enforces entry size, required fields, or section vocabulary at write
time. A downstream project (referred to here as "Project A") shows the
consequences; a second project ("Project B"), comparable lineage, does
not — isolating operator discipline as the dominant variable.

## Measured evidence

**Project A** (`CUSTOMER_NOTES.md`):

- 531 KB, 108 entries.
- Median entry 68 lines; max 690 lines; zero entries at or under
  10 lines.
- 73 of 108 entries exceed 50 lines.
- Invented sections absent from the template: `Context` (75 entries),
  `Cross-refs` (60), `Downstream effects` (16), `Process notes` (9).
- Only 76 of 108 entries contain a "Customer answer" field — roughly
  30% carry no customer ruling (durable findings, ADR ratifications,
  operational authorizations).
- One question (Q-0065) appears 44 times in `CUSTOMER_NOTES.md`, 13
  times in `docs/intake-log.md`, and twice in `docs/OPEN_QUESTIONS.md`.
- `docs/DECISIONS.md` (the intended decision home) is abandoned at
  47 lines.
- `docs/OPEN_QUESTIONS.md` is 232 KB; a single entry reaches 16 KB;
  the queue was never drained.

**Project B** (control):

- `CUSTOMER_NOTES.md` median entry 24 lines.
- Invented sections near-zero (`Context` appears twice; all others zero).
- `docs/DECISIONS.md` in active use at 103 lines.

## Root-cause analysis

**Template version does not explain the divergence.** Both projects
carry `TEMPLATE_VERSION` v1.1.1 (post-upgrade stamp), but Project A's
bulk content was authored under v1.0.0-rc9 through rc14, and Project B
under rc8 through rc13. The lean entry-template spec has been present
since v0.1.0 (2026-04-19). `researcher.md` carried both the
"record customer answer verbatim" rule and the "soft size budgets
(binding)" rule at the rc8 and rc14 endpoints (the file was reworked
54+/125- lines across that span but both rules persisted).

**The guard script is content-blind.** `scripts/hooks/customer-notes-guard.py`
is wired PreToolUse on Write/Edit/MultiEdit/Bash. Its own header
describes it as "an approval gate rather than a role detector." It
gates whether a write happens; it performs no size, scope, or verbatim
inspection. This behavior was verified at rc8, rc9, rc13, rc14, and
v1.1.1.

**Conclusion:** all governing rules are advisory prose, never
machine-enforced. Operator discipline is the dominant variable.

**v1.1.1 status (as of 2026-06-02):** the gap is not closed. The guard
remains content-blind; the size-budget rule remains advisory;
`docs/DECISIONS.md` has no sharded-record convention. A project
starting on v1.1.1 relies entirely on operator habit.

## Caveats

- rc8 and rc14 endpoints were compared; not every intermediate rc was
  diffed line-by-line.
- "Operator discipline" may bundle orchestration habits not yet isolated
  from one another.
- The enforcement gap is verified by source-reading; operator causation
  is strongly supported but not formally proven.

## Recommended fixes

Listed in priority order; see the upstream issue draft at
`docs/pm/issue-draft-customer-notes-scope.md` for the full proposal.

1. Add machine enforcement: an entry-size/scope lint for
   `CUSTOMER_NOTES.md` — flag entries over a configurable line
   threshold, entries lacking a verbatim block, or entries carrying
   non-template sections. Same enforcement style as
   `scripts/lint-questions.sh`.
2. Revive decision records as a living, sharded convention
   (`docs/decisions/D-NNNN.md` + generated index) so decision-memo
   content has a home other than `CUSTOMER_NOTES.md`.
3. Add a drain rule for `OPEN_QUESTIONS.md`: resolve = move to
   decision record + delete from queue.
4. Relationship to spec 016 (token-economy): spec 016 trims agent
   CONTRACT files, not runtime registers. This register-growth axis is
   currently out of scope for 016 and should be folded in or filed
   beside it.
