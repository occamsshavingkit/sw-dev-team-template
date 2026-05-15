# v2-proposal — Project triage + repair agent for retrofit adoption

**Source issue:** [#3](https://github.com/occamsshavingkit/sw-dev-team-template/issues/3)
**Status:** Deferred to v2.0.
**Drafted:** 2026-04-25 (v0.15.x triage for v1.0.0-rc3 entry).

## What

A new agent role — `triage-repair` (or similar) — that scans an
existing codebase being retrofitted into a scaffolded template and
emits a structured plan: what's salvageable as-is, what needs
mechanical migration, what conflicts with the template's hard rules,
and what should be deferred or dropped. Specifically targets the
retrofit playbook entry path where current onboarding-auditor +
researcher coordination is iterative and slow.

## Why not now

- The current retrofit playbook (`docs/templates/retrofit-playbook-template.md`)
  has not yet been field-tested against a real existing codebase
  (criterion C-3 of the v1.0.0-rc3 re-entry checklist). Adding a new
  agent role before the playbook itself has empirical use would
  bake assumptions into the agent that may not survive contact.
- The canonical-role roster in `SW_DEV_ROLE_TAXONOMY.md` is part of
  the template's binding contract; adding a role mid-v0.x churn
  pulls the contract surface around again. v2.0 is the right MAJOR
  for roster revision.

## What blocks adoption

- At least one real-world retrofit completed via the existing
  playbook (per C-3), with friction-points logged.
- A `process-auditor` pass over the retrofit-playbook artefacts to
  surface where a triage-repair agent would actually add value vs.
  duplicate existing roster work.
- An ADR through the v0.x Three-Path Rule (Minimalist / Scalable /
  Creative) capturing the role's scope, ownership boundary, and
  hand-off contract — likely a v2.0-target FW-ADR.

## Reservation status

This file reserves the slot. v2.0 work picks it up; v0.15.x and
v1.0.0-rc track do not block on it.
