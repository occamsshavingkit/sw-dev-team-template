# v2-proposal — claude-mem / SQLite hybrid ledger

**Source issue:** [#27](https://github.com/occamsshavingkit/sw-dev-team-template/issues/27)
**Status:** Deferred to v2.0; v0.15.0 design memo only.
**Drafted:** 2026-04-25 (v0.15.x triage for v1.0.0-rc3 entry).

## What

A hybrid persistence shape for cross-session agent memory:

- **SQLite** for structured, transient state (open-task ledger,
  agent-dispatch history, token-budget telemetry, dispatch trees) —
  query-friendly, append-mostly, machine-consumable.
- **Markdown** for canonical decisions and customer-facing artefacts
  (CUSTOMER_NOTES.md, ADRs, OPEN_QUESTIONS.md, audit reports) —
  human-readable, git-tracked, append-only.

The two stores cross-reference: SQLite rows cite markdown anchors;
markdown decisions reference SQLite event IDs for audit traceability.

`claude-mem` (the existing third-party plugin per FW-ADR-0001) sits
on the SQLite side; the markdown side stays the canonical source for
binding rulings.

## Why not now

- v0.15.0 ships a **design memo only** (per ROADMAP.md § v0.15.0);
  the implementation is post-1.0 unless the memo argues otherwise.
  The implementation surface area is large (schema design, query
  patterns, agent-side adapter, retention/GC policy, customer-data
  privacy boundary) and would balloon v0.x scope.
- The current single-source-markdown shape has known limits but is
  working — agents successfully use `claude-mem` as a lookup, citing
  markdown for ground-truth verification (per CLAUDE.md
  § Memory-first lookup). No urgent failure forces a v0.x landing.
- A binding-rule shift to "structured query is part of the audit
  trail" needs MAJOR-level customer ratification.

## What blocks adoption

- The v0.15.x design memo (architect-authored, per ROADMAP) lands
  with the customer's ratification of one of M / S / C alternatives.
- A real-world dispatch-volume threshold where pure markdown stops
  scaling — currently unmet, and the threshold should be observed in
  downstream-project telemetry, not assumed.
- Privacy / retention rule for SQLite contents: project-confidential
  task content lives in markdown today (which is git-tracked +
  reviewable); SQLite backing introduces a parallel data location
  that needs an explicit retention contract before v2.0 entry.

## Reservation status

This file reserves the slot. v2.0 work picks it up; v0.15.x ships
the design memo; v1.0.0-rc track does not block on the
implementation.
