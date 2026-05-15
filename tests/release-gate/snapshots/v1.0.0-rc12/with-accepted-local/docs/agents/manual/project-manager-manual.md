# project-manager — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/project-manager.md](../../../.claude/agents/project-manager.md)
**Classification**: canonical (manual; rationale companion)

This manual will carry rationale, formats, examples, and history for
the `project-manager` canonical contract.

## TODO — rationale split deferred (M2 follow-up)

The full rationale split for `project-manager` is deferred to a future
M2 follow-up; this file exists as a placeholder so that the canonical
contract can cite a stable manual path (e.g., from the "PM delta pass"
section added in T031 / FR-008). Until the split lands, the canonical
contract is self-contained and the rationale lives implicitly in the
specs that introduced each rule:

- PM delta-pass procedure — `specs/006-template-improvement-program/`
  (FR-008, M2.2 task T031). Implements rolling-wave planning on the
  session-anchored cadence defined in `CLAUDE.md` "Time-based cadences".

When the rationale split is performed, move elaboration, worked
examples, and historical context out of `.claude/agents/project-manager.md`
into this manual, mirroring the form used in `researcher-manual.md`,
`tech-lead-manual.md`, `qa-engineer-manual.md`, and
`code-reviewer-manual.md`.
