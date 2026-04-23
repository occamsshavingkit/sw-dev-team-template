# Roadmap — sw-dev-team-template

Forward-looking release plan. Authoritative source for what is
scheduled into v0.13.0 / v0.14.0 / v0.15.0 and the criteria for
re-entering the v1.0.0 release-candidate track.

This file is a **living document**, amended whenever a customer
ruling changes scope. It is not a contract — the `CHANGELOG.md`
of a tagged release is the contract for what actually shipped.

SemVer rules (see `CHANGELOG.md` header for the binding version):

- **MAJOR** — breaking change to the template contract.
- **MINOR** — additive, backward-compatible (but 0.y convention
  allows breaking changes in MINOR; we are still 0.y).
- **PATCH** — non-structural clarifications.

Tag currently shipping: **v0.12.0** (2026-04-23).

---

## v0.13.0 — "Pipeline maturity + retrofit"

**Target:** ~1–2 weeks after v0.12.0, gated by `/ultraplan` retry
producing a reviewable retrofit-playbook draft.

### Scope (pinned)

- **Retrofit playbook (upstream #3).** Agent workflow — not a
  script — for migrating an existing project into a freshly-
  scaffolded target. Scope pinned by customer ruling 2026-04-23
  (`CUSTOMER_NOTES.md`). Deliverable:
  `docs/templates/retrofit-playbook-template.md`. Blocked on
  `/ultraplan` output → review → iterate.
- **#33 Three-Path Rule (Phase 3 of workflow redesign).** Expand
  `docs/templates/architecture-template.md` Alternatives-considered
  guidance to require three named alternatives (Minimalist /
  Scalable / Creative). Small surface; mostly template content.

### Scope (data-driven; lands if v0.12.0 usage reveals it)

- **Pipeline empirical tuning.** After v0.12.0 has real use, the
  `docs/pm/TOKEN_LEDGER.md` data tells us whether the OR-set
  trigger (workflow-redesign-v0.12.md §2) is correctly calibrated.
  Likely adjustments: clause (3) "cross-module boundary" firing
  too often on small-touch tasks → raise bar; or conversely,
  silent-skip patterns surfacing → add clauses.
- **Auditor cadence tuning.** First real runs of
  `onboarding-auditor` and `process-auditor` generate lessons on
  dispatch frequency, friction-report format friction, and whether
  `process-auditor`'s 2–3-milestone cadence is right.
- **Solution Duel round-limit tuning.** If real duels show stalemates
  are common, re-examine the one-round rule.

### Out of scope for v0.13.0

- #15 customer→product-owner rename — belongs in its own release
  (v0.14.0).
- #21 GitHub contributor workflow — v2-scoped per the issue.
- #27 claude-mem / SQLite hybrid ledger — v2-scoped per the issue.

### Exit criteria (ready to tag)

- Retrofit playbook reviewed by `code-reviewer` and `architect`;
  customer has ratified the agent-workflow shape.
- Three-Path Rule landed in ADR template with a worked example.
- Token-ledger-driven trigger tuning applied, or explicitly
  deferred with reason in `LESSONS.md`.
- One exercise of each of the four new v0.12.0 stages
  (prior-art, proposal, Duel, process-auditor) with lessons
  captured.

---

## v0.14.0 — "Breaking: customer → product-owner rename (#15)"

**Target:** ~1 month after v0.13.0. Single-release for the
breaking change so its migration surface is isolated.

### Scope

- **Rename** `customer` → `product owner` throughout:
  - `CLAUDE.md` FIRST ACTIONS, escalation protocol, hard rules.
  - Every `.claude/agents/*.md` "customer interface" language.
  - `SW_DEV_ROLE_TAXONOMY.md` references.
  - `docs/glossary/ENGINEERING.md` and `PROJECT.md`.
  - `docs/templates/scoping-questions-template.md`.
- **File rename** `CUSTOMER_NOTES.md` → either
  `PRODUCT_OWNER_NOTES.md` or the more generic `DECISIONS.md`
  (open choice; decide at memo time). Files carry history via
  `git mv`.
- **New `migrations/0.14.0.sh`** — idempotent migration that
  renames files, rewrites internal links, and flags
  heavily-customized versions for manual review. Must pass
  smoke-test against:
  - `examples/brewday-log-annotator/` (in-repo example).
  - A freshly-scaffolded throwaway (synthetic baseline).
- **Glossary entries** in `PROJECT.md` distinguishing product
  owner / customer / sponsor per PMBOK Stakeholder definition
  and Scrum Guide Product Owner definition.
- **Documentation sweep** for every `CUSTOMER_NOTES.md` reference
  in the repo, including README and CONTRIBUTING.

### Exit criteria

- Migration script passes against both smoke-test targets with
  no conflict surface left behind.
- Every active downstream project upgraded (via
  `scripts/upgrade.sh`) lands cleanly.
- A full `onboarding-auditor` pass against a fresh scaffold
  surfaces no documentation debt caused by the rename.
- Customer has ratified the final name choice
  (`PRODUCT_OWNER_NOTES.md` vs `DECISIONS.md`) and any edge-case
  handling.

### Out of scope for v0.14.0

- Any non-rename change. If it's not part of the terminology
  migration, it waits for v0.15.0. This release's job is to take
  the rename cost and land it cleanly, then return to feature
  work.

---

## v0.15.0 — "v1.0-rc re-entry prep"

**Target:** when v0.14.0 has been used downstream for long enough
to reveal the inevitable migration-rough-edges (~1 month post-
v0.14.0).

### Theme

**Get the template back to a v1.0.0-rc3 tag.** The rc track was
withdrawn when the v1.0.0-rc2 contract proved unstable under
downstream use. Returning requires demonstrated contract stability
+ real validation.

### Scope

- **#21 GitHub contributor workflow.** If "others can contribute"
  is an v1.0 criterion, this lands here. Expand `CONTRIBUTING.md`,
  add PR template, add milestone labels convention, document the
  review + release flow. Likely includes issue-template polish
  (the existing `framework-gap.yml` has seen real use; tune).
- **#27 claude-mem / SQLite hybrid ledger — design memo.** Not
  implementation. `architect` writes a memo on whether the
  hybrid-ledger pattern (SQLite for transient, markdown for
  canonical) is worth adopting in v1.0 or should stay v2-scoped.
  Customer decides after reading.
- **v1.0-rc3 re-entry checklist.** A written, binding criteria
  list that must pass before the template is re-tagged on the
  rc track. Draft:
  1. No open contract-breaking themes for at least one full
     MINOR cycle.
  2. Migration infrastructure proven across two major hops
     (v0.11 → v0.12 and the #15 rename v0.13 → v0.14 both pass).
  3. Retrofit playbook used against at least one real existing
     project; retrofit DoD met.
  4. All four workflow-redesign pipeline stages (prior-art,
     three-path, proposal, Duel) have empirical usage data and
     have been tuned at least once.
  5. `onboarding-auditor` + `process-auditor` each run at least
     twice against the template's own examples; no outstanding
     major findings.
  6. Every open `v2-proposal`-labelled issue either landed,
     formally deferred to v2.0, or explicitly rejected with
     reason in `DECISIONS.md`.
  7. `scripts/upgrade.sh` upgrades a synthetic v0.10.0 project
     through every intermediate release to v1.0.0-rc3 cleanly.

### Exit criteria

- Re-entry checklist (above) ratified by customer.
- Contributor workflow documented, tested against one synthetic
  external-contributor simulation (customer or `tech-lead`
  scaffolds a fresh identity, files a framework-gap issue,
  opens a PR per `CONTRIBUTING.md`).
- claude-mem memo written and a v2-or-v1.0 decision made.
- No P0/P1 open gaps in the health-check sense
  (`docs/agent-health-contract.md`).

---

## v1.0.0-rc3 — Contract stabilisation

**Target:** when v0.15.0's re-entry checklist passes.

### Scope

- Re-tag the template on the `v1.0.0-rc` track.
- Freeze the binding-rule surface: any post-rc3 change to
  `CLAUDE.md` § Hard rules or the canonical-role roster requires
  an ADR and customer sign-off.
- Begin a structured rc → GA path: rc3 → rc4 (integrated
  downstream feedback) → 1.0.0 GA.

### Explicitly deferred to post-1.0

- #27 claude-mem implementation (if the design memo in v0.15.0
  recommends it, target becomes 1.1 or 2.0 depending on scope).
- Any v2-proposal-labelled issue without explicit v1.0 ruling.

---

## Cross-release dependencies

```
v0.12.0 (shipped 2026-04-23)
   │
   │  depends on: v0.12.0 real use producing lessons
   ▼
v0.13.0 ◄── /ultraplan retry (scheduled 2026-04-24)
   │
   │  depends on: v0.13.0 retrofit exercised against one real project
   ▼
v0.14.0 ◄── #15 customer→PO rename (isolated release)
   │
   │  depends on: v0.14.0 migration downstream-validated
   ▼
v0.15.0 ◄── re-entry checklist + v1.0 prep
   │
   │  depends on: re-entry checklist passes
   ▼
v1.0.0-rc3 ◄── contract freeze, rc track re-entered
```

The dependency chain is one-way: each release's exit criteria
must pass before the next is cut. Slippage compounds — if
v0.13.0's retrofit exercise reveals a major gap, v0.14.0 waits
until the retrofit gap is absorbed into scope or formally
deferred.

---

## Out-of-band items

Things that may interrupt the linear plan:

- **Upstream Claude Code harness issues.** The architect-spawn
  tool-grant anomaly (v0.12.0 CHANGELOG) is upstream-scoped; if
  the harness introduces a breaking behavioural change that
  affects the template, a PATCH or MINOR may need to jump the
  queue.
- **Customer-initiated scope additions.** If the customer surfaces
  a new binding requirement (new hard rule, new role, domain
  regulatory constraint), `tech-lead` must triage whether it
  slots into the current plan or reshuffles. Record the
  reshuffle in `docs/pm/CHANGES.md` + this file.
- **Real downstream incidents.** A downstream project's production
  incident that traces back to a template rule failure takes
  priority over planned scope; becomes a PATCH release between
  MINOR bumps.

---

## Revision log

| Date | Change | Who |
|---|---|---|
| 2026-04-23 | Roadmap created after v0.12.0 tag; customer ruled path to v1.0.0-rc3 via v0.13.0 / v0.14.0 / v0.15.0 | `tech-lead` |
