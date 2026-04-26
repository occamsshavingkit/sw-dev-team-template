# Roadmap — sw-dev-team-template

<!-- TOC -->

- [What shipped in v0.13.0 → v0.17.0](#what-shipped-in-v0130-v0170)
- [Path to v1.0.0-rc3](#path-to-v100-rc3)
  - [Credit-free vs credit-gated](#credit-free-vs-credit-gated)
  - [Final binding step — IEEE 1028 readiness audit](#final-binding-step-ieee-1028-readiness-audit)
- [Post-rc3](#post-rc3)
  - [v1.0.0-rc4 (only if rc3 fails sign-off)](#v100-rc4-only-if-rc3-fails-sign-off)
  - [v1.0.0 final](#v100-final)
  - [v2 work](#v2-work)
- [Cross-release dependencies](#cross-release-dependencies)
- [Out-of-band items](#out-of-band-items)
- [Revision log](#revision-log)

<!-- /TOC -->

Forward-looking release plan. Authoritative source for what is
scheduled into the path to v1.0.0-rc3 and beyond.

This file is a **living document**, amended whenever a customer
ruling changes scope. It is not a contract — the `CHANGELOG.md`
of a tagged release is the contract for what actually shipped.

SemVer rules (see `CHANGELOG.md` header for the binding wording):

- **MAJOR** — breaking change to the template contract.
- **MINOR** — additive, backward-compatible (0.y convention still
  permits breaking changes inside MINOR while we are pre-1.0).
- **PATCH** — non-structural clarifications.

Tag currently shipping: **v0.17.0** (local tag; public GitHub
Release latest is v0.16.0 — see `docs/audits/v1.0.0-rc3-status-2026-04-25.md`
for credit-policy hold #779).

---

## What shipped in v0.13.0 → v0.17.0

The original v0.13/v0.14/v0.15 forward-plan sections of this file
are now history. `CHANGELOG.md` is the authoritative record. Brief
inventory:

- **v0.13.0** — retrofit playbook + Three-Path Rule landed.
- **v0.14.0–v0.14.4** — atomic-install / self-bootstrap / agent-name
  splice / `.template-customizations` stub-fill (issues #63–#67
  surfaced and closed).
- **v0.15.0–v0.15.1** — `docs/v1.0-rc3-checklist.md` drafted as a
  binding artefact, INDEX split (`INDEX-FRAMEWORK.md` /
  `INDEX-PROJECT.md`), `FW-ADR-NNNN` namespace separation,
  `upgrade.sh` clean-exit fix.
- **v0.16.0** — `scripts/stepwise-smoke.sh` + `SWDT_UPSTREAM_URL`
  override (rc3 C-7 deliverable), 16-issue retrofit-playbook
  revision pass, `docs/v2/triage-repair-agent.md` and
  `docs/v2/claude-mem-hybrid-ledger.md` placeholders.
- **v0.17.0** — `scripts/upgrade.sh --target <version>`, SPDX
  headers across `scripts/*.sh`, `docs/templates/github-actions-ci.yml`
  reference workflow.

The customer→product-owner rename (`#15`) forecast in the prior
roadmap **did not ship**. It is not scheduled for the v1.0 line;
re-evaluate post-1.0 if downstream evidence demands it.

---

## Path to v1.0.0-rc3

Binding criteria live in `docs/v1.0-rc3-checklist.md` (C-1 through
C-7). Current standing per
`docs/audits/v1.0.0-rc3-status-2026-04-25.md` (this session):
**all seven criteria evidence-pass.** Remaining work is
attestation, push, and a formal IEEE 1028 audit — not new
substance.

| # | Criterion | Standing | Remaining work |
|---|---|---|---|
| C-1 | Contract stability | green | label sweep at rc cut |
| C-2 | Migration infra (two major hops) | green | hold open through v0.14.x escalation window |
| C-3 | Retrofit playbook field-tested | green (substantively) | upstream attestation issue (credit-gated) |
| C-4 | Workflow-pipeline empirical usage | green (this session) | none — bar met |
| C-5 | Audit agents exercised | green | none — 18 findings logged, 0 major |
| C-6 | `v2-proposal` queue cleared | green (locally) | push placeholders + close issues (credit-gated) |
| C-7 | Stepwise upgrade smoke (v0.14.4 → rc3) | green | re-capture log at rc3 cut |

### Credit-free vs credit-gated

Credit-free items are local-only and unblocked. Credit-gated items
wait on the GitHub-credit policy decision recorded in the status
audit (#779: hold until 2026-05-01 or next milestone cut).

- **Credit-gated:** C-3 upstream attestation issue, C-6 v2-placeholder
  push + GitHub-side issue close, the v0.15.x..v0.17.x tag and
  Release push.
- **Credit-free:** all in-tree work — script runs, doc drafts,
  re-capture of the C-7 log at the rc cut.

### Final binding step — IEEE 1028 readiness audit

Per `docs/v1.0-rc3-checklist.md` § Audit + sign-off, after every
row is green `code-reviewer` runs an IEEE 1028-style audit pass
producing `docs/audits/v1.0.0-rc3-readiness-audit.md`. `tech-lead`
presents the audit summary; the customer ratifies (or returns
specific rows). Only on ratification does `release-engineer` cut
v1.0.0-rc3. The status snapshot is **not** that audit.

---

## Post-rc3

### v1.0.0-rc4 (only if rc3 fails sign-off)

Reserved as the integrated-feedback rc. Cut only if the rc3
ratification returns specific rows for more work, or if downstream
use of rc3 surfaces a contract-break before GA. If rc3 ratifies
clean and downstream use is clean through the rc3 → GA window, the
project skips rc4 and goes direct to v1.0.0 final.

### v1.0.0 final

Cut after rc3 (and rc4, if needed) has been used downstream long
enough to demonstrate contract stability. Freezes the binding-rule
surface: any post-1.0 change to `CLAUDE.md` § Hard rules or the
canonical-role roster requires an ADR and customer sign-off. The
v0.y MINOR-as-breaking convention ends; from 1.0.0 onward, MAJOR
is reserved for actual breaking changes.

### v2 work

The v2 line is reserved for items that require a contract break
beyond what `migrations/*.sh` can automate. Current placeholders:

- `docs/v2/triage-repair-agent.md` — project triage + repair agent
  for retrofit adoption (issue #3).
- `docs/v2/claude-mem-hybrid-ledger.md` — claude-mem / SQLite
  hybrid ledger (issue #27).

Both are deferred-with-rationale, not scheduled. v2.0 picks them up
when (a) v1.0 has shipped and (b) a customer ruling promotes one
or both into a v2 milestone.

---

## Cross-release dependencies

```
v0.17.0 (local tag; public Release at v0.16.0)
   │
   │  depends on: rc3 checklist all green + IEEE 1028 audit
   ▼
v1.0.0-rc3 ◄── re-entry checklist signed off, contract frozen
   │
   │  depends on: rc3 downstream-clean OR returned-rows worked off
   ▼
[v1.0.0-rc4 — only if rc3 fails sign-off]
   │
   │  depends on: rc-track downstream-clean window
   ▼
v1.0.0 (GA)
```

The dependency chain is one-way: each release's exit criteria
must pass before the next is cut. v1.0.0-rc3 is gated on the
checklist + audit, not on the calendar.

---

## Out-of-band items

Things that may interrupt the linear plan:

- **Upstream Claude Code harness issues.** A breaking harness
  behavioural change that affects template contracts can force a
  PATCH or MINOR ahead of the rc cut.
- **Customer-initiated scope additions.** A new binding requirement
  (new hard rule, new role, regulatory constraint) is triaged by
  `tech-lead`; reshuffles are recorded in `docs/pm/CHANGES.md` +
  this file.
- **Real downstream incidents.** A downstream production incident
  traceable to a template rule failure takes priority over planned
  scope; ships as a PATCH between MINOR bumps. Precedent: issue
  #63 (atomic-install) surfaced from QuackS7 and shipped in
  v0.14.3.

---

## Revision log

| Date | Change | Who |
|---|---|---|
| 2026-04-23 | Roadmap created after v0.12.0 tag; customer ruled path to v1.0.0-rc3 via v0.13.0 / v0.14.0 / v0.15.0. | `tech-lead` |
| 2026-04-26 | Rewrite for the rc3 era. Current shipping tag updated to v0.17.0. Stale v0.13/v0.14/v0.15 forward-plan sections collapsed into a one-paragraph history pointing at `CHANGELOG.md`. v0.14.0 customer→product-owner rename noted as not-shipped and unscheduled. New "Path to v1.0.0-rc3" section cites `docs/v1.0-rc3-checklist.md` and `docs/audits/v1.0.0-rc3-status-2026-04-25.md` (7/7 criteria evidence-pass after C-4 flip this session). New "Post-rc3" section sketches rc4-conditional / v1.0 final / v2 placeholders. Cross-release dependency diagram redrawn for current state. | `tech-writer` |
