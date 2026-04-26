# Session handover — 2026-04-25 PM

For the next session of `tech-lead` (the main session) on
`~/sw-dev-team-template` and adjacent QuackPLC / QuackS7 work.
Replaces the need to re-derive context from the prior conversation.

<!-- TOC -->

- [State of the repo](#state-of-the-repo)
- [What landed this session (3 commits)](#what-landed-this-session-3-commits)
- [v1.0.0-rc3 readiness — corrected status](#v100-rc3-readiness-corrected-status)
- [Token / context economy — this session's work](#token-context-economy-this-sessions-work)
- [Skill catalog state](#skill-catalog-state)
- [Open / pending](#open-pending)
- [Gotchas to remember](#gotchas-to-remember)
- [Next concrete actions](#next-concrete-actions)

<!-- /TOC -->

## State of the repo

`~/sw-dev-team-template`, branch `main`, working tree **clean**.

Most recent local commits (not pushed — credit-gated per #779,
release at next milestone or 2026-05-01, whichever comes first):

```
ffd8c3e feat(toc): scripts/gen-toc.sh + apply to all binding docs ≥100 lines
89a8339 docs(rc3): GitHub Releases policy + status snapshot + C-5 audit report
71799ac fix(stepwise-smoke): use git insteadOf to redirect upstream URL
a6b0738 v0.17.0  ← last pushed tag
```

Public template version: **v0.16.0** (GitHub Release).
Local wrapper tag: **v0.17.0** (held; not pushed).

## What landed this session (3 commits)

1. **`fix(stepwise-smoke)` — root-cause C-7 fix.**
   Replaced the pre-install + `SWDT_BOOTSTRAPPED=1` workaround with a
   git `insteadOf` redirect (via `GIT_CONFIG_COUNT/KEY/VALUE` env).
   Each hop now runs its OWN historical `upgrade.sh` naturally —
   bootstrap, re-exec, and all — while clones still hit the pinned
   local repo. C-7 row re-baselined "v0.10.0 → rc3" → "v0.14.4 → rc3"
   (pre-v0.14.4 has the documented self-mutating-cp regression no
   harness can paper over). Smoke re-captured: **4/4 hops green**.
   Log: `docs/audits/v1.0.0-rc3-stepwise-smoke.log`.
   `.gitignore` got a `!docs/audits/*.log` exception so audit logs
   are tracked.

2. **`docs(rc3)` — Releases policy + snapshot updates.**
   `CONTRIBUTING.md` adds the Releases policy: tags every release;
   GitHub Release objects at MINOR boundaries only; PATCH notes fold
   into next MINOR; backfill not required. Status snapshot updated
   to reflect the C-7 root-cause fix. C-5 process-audit report against
   the template repo committed (`docs/pm/process-audit-2026-04-25-template.md`).
   `c4-evidence-tracker.md` for ongoing C-4 accumulation.

3. **`feat(toc)` — scripts/gen-toc.sh + applied to 31 binding docs.**
   Idempotent Markdown TOC generator. Marker form
   `<!-- TOC --> ... <!-- /TOC -->`. Modes: `--insert` (add markers),
   `--check` (CI exit-1 on stale or missing), `--min-lines N`. Skips
   fenced code blocks. Applied to CLAUDE.md, SW_DEV_ROLE_TAXONOMY.md,
   ROADMAP.md, the rc3 checklist, both glossaries, all framework
   ADRs ≥100 lines, all agent contracts ≥100 lines, all
   `docs/templates/*.md` ≥100 lines.

## v1.0.0-rc3 readiness — corrected status

The checklist's "at v0.15.0 close" gates are now **past** (we are
at v0.17.0). Source of truth: `docs/v1.0-rc3-checklist.md`. Snapshot:
`docs/audits/v1.0.0-rc3-status-2026-04-25.md`.

| # | State | Note |
|---|---|---|
| C-1 | 🟢 pass | 3 open issues, none `contract-break`. |
| C-2 | 🟢 likely-pass | v0.13→v0.14.x window closed clean; no `migration-defect` issues. |
| C-3 | 🟢 substantive | QuackS7 retrofit complete with DoD; **upstream attestation issue not yet filed (credit-gated).** |
| C-4 | 🟡 partial | Three-path 7/5; prior-art 0/5; proposal 1/3; Solution Duel 0/3. **Only yellow row.** Accumulates organically as QuackPLC/QuackS7 tasks fire the trigger. |
| C-5 | 🟢 pass | `onboarding-auditor` 2× on QuackPLC; `process-auditor` against template (this session) and QuackPLC. 18 findings total, none major. |
| C-6 | 🟢 pass | Both `docs/v2/*.md` placeholders in place (`triage-repair-agent.md`, `claude-mem-hybrid-ledger.md`). GitHub-side issue close credit-gated. |
| C-7 | 🟢 pass | 4/4 hops via root-cause `insteadOf` fix. Re-capture log at the rc3 cut so it spans v0.14.4 → rc3 inclusive. |

## Token / context economy — this session's work

Strategic layer (claude-mem) is doing the work — session recap
counter shows ~95% savings on summarized prior work.

Tactical layer added this session:

- **TOCs at top of all binding docs ≥100 lines.** Read TOC region
  (~30 lines), then `Read offset/limit` only the section needed.
- **`scripts/gen-toc.sh --check`** is CI-ready; can be added to a
  pre-commit hook later if drift becomes a problem.
- **Skill catalog pruned 1,472 → 507** (~66% reduction). Permanent
  per-session prompt savings.

## Skill catalog state

- Live: `~/.claude/skills/` — **507** skills.
- Archived: `~/.claude/skills.archive/` — 965 skills (recoverable
  with one `mv`).
- What was kept beyond expected baseline:
  - **UX/frontend** (full stack — react, angular, sveltekit, astro,
    tailwind, shadcn, radix, zod, zustand, tanstack, convex, nestjs,
    hono, trpc, the `ui-*` StyleSeed family, ux-flow/audit/copy/feedback,
    fixing-accessibility/metadata/motion, mobile-design,
    industrial-brutalist-ui, minimalist-ui, high-end-visual-design,
    core-components, theme-factory, iconsax) — **for HMI + web status pages**.
  - **Embedded/PLC-adjacent**: arm-cortex-expert, firmware-analyst,
    dwarf-expert, gdb-cli, address-sanitizer, protocol-reverse-engineering,
    reverse-engineer, memory-safety-patterns, c-pro, cpp-pro.
  - **Industrial/control**: production-scheduling, quality-nonconformance,
    monte-carlo-*, mathematical-optimization, data-engineering-*,
    network-engineer (DCS networking), distributed-debugging,
    microservices-patterns, event-sourcing-architect, saga-orchestration,
    projection-patterns, event-store-design.
  - **DCS-local infra (NOT cloud)**: grafana-dashboards, prometheus-configuration,
    docker-expert, secrets-management.
- What was pruned: cloud (azure/aws/gcp/cloudflare), terraform-*, k8s-*,
  cloud-architect, marketing/SEO/sales/copywriting, SaaS-bot integrations
  (slack/jira/notion/etc.), mobile (ios/android/expo/flutter), Apple HIG,
  game dev, crypto/web3, Apify/HF/n8n/langchain/scraping, ERP (odoo),
  Brazilian legal, health/diet analyzers, celebrity-personality skills,
  industry-specific (logistics/billing/customs), trailmark/bdistill,
  startup analyst suite, stripe-*, web-pentest tools.

## Open / pending

**Credit-gated (waits for next milestone or 2026-05-01):**

- File QuackS7 retrofit-summary attestation issue upstream (closes C-3).
- Push `v0.15.x..v0.17.x` tags + Releases at MINOR boundaries.
- Close GitHub `v2-proposal` issues (#3, #27).
- Push the 3 local commits from this session.

**Anthropic-credit-only / generative (do anytime):**

- Apply the workflow pipeline to qualifying QuackPLC/QuackS7 tasks
  to accumulate C-4 evidence (prior-art ×5 across ≥2 projects,
  proposals ×3, Solution Duels ×3).
- Run `code-reviewer` IEEE-1028 readiness audit when C-4 is green;
  produces `docs/audits/v1.0.0-rc3-readiness-audit.md`.

**Carried forward, not on the rc3 path:**

- F-001 from QuackPLC process-audit: `ROADMAP.md` and the rc3
  checklist leaked into QuackPLC verbatim through upgrade. Worth
  filing upstream as a scaffold/upgrade ship-list issue. (See
  `/home/quackdcs/QuackPLC/docs/pm/process-audit-2026-04-25.md`.)

## Gotchas to remember

- **Main session IS `tech-lead`** (binding from v0.12.1; supersedes
  the prior spawn-`tech-lead` rule). Do not spawn `subagent_type: tech-lead`.
- **Memory is a lookup, not source of truth** — always verify against
  current files / `git log` before acting on a recalled fact.
- **One question per turn, agents idle.** No multi-MC bundles to
  the customer.
- **GitHub Releases at MINOR only** — don't propose backfilling
  PATCH releases.
- **The rc3 checklist's calendar gates ("at v0.15.0 close") are
  past** — evaluate criteria against current state, not as future windows.
- **Anthropic credits preferred over GitHub credits** for v1.0.0-rc3
  work (per S162 / decision #779).
- **C-7 supports v0.14.4 → rc3 only.** Pre-v0.14.4 has the
  self-mutating-cp regression; row was re-baselined this session.
- **Template version stamp:** local wrapper at v0.17.0; public Release
  at v0.16.0; tags through v0.17.0 are pushed; Releases lag.

## Next concrete actions

1. Resume C-4 accumulation in QuackPLC's M-1 milestone (target
   2026-06-26) and QuackS7's current M1 corpus work — apply
   workflow-pipeline trigger to qualifying tasks.
2. When 2026-05-01 / next milestone arrives:
   - File QuackS7 retrofit attestation issue upstream.
   - Push the 3 local commits + `v0.15.x..v0.17.x` tags.
   - Cut MINOR Release(s) on GitHub.
3. When all rows green: dispatch `code-reviewer` for the IEEE-1028
   readiness audit; on customer ratification, `release-engineer`
   cuts v1.0.0-rc3.

---

*Written by `tech-lead` at session close, 2026-04-25 PM,
post-stepwise-smoke fix and skill-catalog prune.*
