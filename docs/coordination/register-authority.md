# Register-authority table

<!-- TOC -->

- [Purpose](#purpose)
- [Non-goals](#non-goals)
- [Authority table](#authority-table)
- [Conflict rule](#conflict-rule)

<!-- /TOC -->

This document is the binding register-authority table (FR-010) for the
issues-based multi-operator coordination interface. It defines which
artifact holds authoritative state for each kind of record, and how
GitHub Issues relate to those authoritative records.

---

## Purpose

The coordination layer adds GitHub Issues as a shared, at-a-glance
work queue. It does not replace any in-repo register. Each kind of
state has exactly one authoritative home. This table makes that
mapping explicit so operators do not duplicate, override, or confuse
the two surfaces.

---

## Non-goals

The following statements are binding constraints on the coordination
interface.

- **In-repo registers are not replaced.** `CUSTOMER_NOTES.md`,
  `docs/OPEN_QUESTIONS.md`, `docs/DECISIONS.md`, and the `docs/pm/`
  PMBOK artifacts remain the authoritative records for the state they
  hold. GitHub Issues is a coordination surface only.

- **No issue comment records or substitutes for customer truth.** An
  issue comment is visible to operators, not a customer inbox.
  Customer truth flows through `tech-lead` to `researcher` to
  `CUSTOMER_NOTES.md` (Hard Rule #1). No issue, label, milestone, or
  comment creates an alternative escalation path to the customer.

- **The interface is opt-in.** A downstream project that does not
  adopt it runs the normal single-operator workflow without any
  required changes. No label, no issue template, and no script is
  required for offline use.

---

## Authority table

| State kind | Authoritative record | GitHub Issues role |
|---|---|---|
| Customer truth | `CUSTOMER_NOTES.md` (steward: `researcher`) | Issues are never authoritative; no issue comment may record or paraphrase customer truth |
| Open questions (unresolved) | `docs/OPEN_QUESTIONS.md` | May be referenced in an issue body; not duplicated; Hard Rule #11 still governs batching |
| Decisions made | `docs/DECISIONS.md` | A decision entry may reference a triggering issue number; the issue is not the record |
| Schedule, risk log, lessons, change log | `docs/pm/*.md` | Not mirrored to Issues |
| Task scope, file paths, role ownership | `docs/handoffs/<task_id>.json` | Issue body carries a `task_id` reference to the binding handoff |
| Evidence gates and completion state | `docs/handoffs/<task_id>.json` | `status:done` label mirrors completion; the label is not binding |
| Task claim / status / work-queue visibility | GitHub Issues labels (`status:*`) | Authoritative for coordination-visible state; handoff wins on any conflict |
| Role routing (triage) | GitHub Issues `role:` labels | Authoritative for routing visibility; canonical role definition remains `SW_DEV_ROLE_TAXONOMY.md` |
| Milestone grouping (release) | GitHub Issues milestones | Mirrors ROADMAP release lines; ROADMAP is authoritative |
| Claim and comment audit trail | GitHub Issues comment stream | Authoritative for the coordination timeline (CLAIM / YIELD / PROGRESS / HANDBACK / GATE-PASSED / BLOCKED comments); not a substitute for hook-captured evidence |

---

## Conflict rule

When a GitHub Issues label, milestone, or comment conflicts with the
corresponding in-repo record, the in-repo record wins. The operator
who detects the conflict corrects the Issues state to match the
in-repo record. No in-repo file is modified to match Issues.

The one exception is the comment audit trail: it is append-only and
cannot be retroactively corrected. A follow-up comment noting the
discrepancy is the correct response in that case.

See `multi-operator-model.md` for the full authority-split rationale
and the gate-safety invariant. See `claim-protocol.md` for the
advisory checkout sequence and invariants I1–I5.
