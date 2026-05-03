# Decisions log — append-only

This file is the black-box recorder for decisions `tech-lead` (or
any other agent) made on behalf of the customer without live
customer input. Purpose: the terminal Turn Ledger (see
`.claude/agents/tech-lead.md` § "Customer-facing output discipline",
R-2) can scroll away, but this file survives.

**Rules:**

- Append only. Never edit or delete past rows.
- One row per decision. Newest at the bottom.
- If a later decision overrides an earlier one, add a new row and
  write `Supersedes: <earlier ID>` in the `Notes` column.

**Row template:**

```
## D-NNNN — <date> — <one-line decision>

**Who decided:** <agent name or role>
**Options considered:** <A / B / C — short>
**Chose:** <X>
**Why:** <one line>
**Files touched:** <paths, optional>
**Customer visibility:** <shown in turn ledger on YYYY-MM-DD / not yet surfaced>
**Supersedes:** <D-NNNN or —>
**Notes:** <anything else>
```

---

<!-- Append decisions below this line. First entry is D-0001. -->

## D-0001 — 2026-05-03 — Schedule GitHub Projects coordination as v1.1.0

**Who decided:** `tech-lead`
**Options considered:** v1.0.0 final blocker / v1.1.0 additive feature / v2 contract-break placeholder
**Chose:** v1.1.0 additive feature
**Why:** The customer requested this for post-v1.0.0 work, and the feature can coordinate multi-machine operators without changing the binding agent roster or customer-escalation rules.
**Files touched:** `ROADMAP.md`
**Customer visibility:** shown in turn ledger on 2026-05-03
**Supersedes:** —
**Notes:** Keep GitHub Projects opt-in; in-repo registers remain authoritative unless a future ADR changes that.

## D-0002 — 2026-05-03 — Draft provider-neutral agent model-routing guidelines

**Who decided:** `tech-lead`
**Options considered:** hard-pin exact model IDs / leave model choice to each operator / define provider-neutral tiers with current provider mappings
**Chose:** define provider-neutral tiers with current provider mappings
**Why:** The customer needs guidelines that work across ChatGPT / OpenAI and Claude / Claude Code, while exact model catalogs and aliases change over time.
**Files touched:** `docs/model-routing-guidelines.md`, `docs/INDEX-FRAMEWORK.md`, `ROADMAP.md`
**Customer visibility:** shown in turn ledger on 2026-05-03
**Supersedes:** —
**Notes:** Re-verify provider mappings before tagged releases; pin exact IDs only when a downstream project needs reproducibility.

## D-0003 — 2026-05-03 — Require v1.0.0-rc4 before v1.0.0 final

**Who decided:** `tech-lead`
**Options considered:** proceed rc3 directly to final / patch selected issues without a new rc / cut an integrated rc4 stabilization candidate
**Chose:** cut an integrated rc4 stabilization candidate
**Why:** Downstream rc3 use surfaced multiple P0 process, scoping, upgrade, and retrofit gaps in issues #71-#83; final needs a clean downstream window after those fixes.
**Files touched:** `docs/v1.0-rc4-stabilization.md`, `ROADMAP.md`, `docs/INDEX-FRAMEWORK.md`
**Customer visibility:** shown in turn ledger on 2026-05-03
**Supersedes:** —
**Notes:** `v1.0.0` final is blocked until every P0 in the rc4 stabilization plan is closed or explicitly downgraded by customer ruling.

## D-0004 — 2026-05-03 — Keep first rc4 fixes template-local

**Who decided:** `tech-lead`
**Options considered:** require harness changes / add new canonical roles / ship template-local mitigations first
**Chose:** ship template-local mitigations first
**Why:** The rc4 issues need stabilization before GA; template-local warnings, routing rules, scoping gates, retrofit gates, and upgrade diagnostics can reduce the observed failures without waiting on Claude Code harness changes or expanding the canonical roster.
**Files touched:** `.claude/agents/*.md`, `CLAUDE.md`, `docs/templates/*`, `scripts/*`
**Customer visibility:** shown in turn ledger on 2026-05-03
**Supersedes:** —
**Notes:** Harness-level `SendMessage` / budget sentinels and new AI-deliverable specialist role remain candidates for post-GA design unless the customer promotes them explicitly.

## D-0005 — 2026-05-03 — Promote project-local agent supplements into rc4

**Who decided:** customer, implemented by `tech-lead`
**Options considered:** defer #75 to v1.1.0 / section-aware merge in `upgrade.sh` / convention-based `<role>-local.md` supplements
**Chose:** convention-based `<role>-local.md` supplements in rc4
**Why:** The customer asked to bring #71/#75 into rc4; local supplements solve the immediate upgrade-fork trap without requiring harness include support or complex merge markers.
**Files touched:** `.claude/agents/*.md`, `CLAUDE.md`, `scripts/upgrade.sh`, `scripts/lib/manifest.sh`, `scripts/scaffold.sh`, `scripts/smoke-test.sh`, `CHANGELOG.md`, `docs/v1.0-rc4-stabilization.md`
**Customer visibility:** shown in turn ledger on 2026-05-03
**Supersedes:** —
**Notes:** Exact harness-level concatenation remains a future enhancement; rc4 uses explicit self-read convention inside each agent contract.
