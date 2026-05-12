# Tech-lead handover — 2026-04-25

**Reason:** customer flagged context decay / confusion late in a long
session. Next session starts fresh; this brief is the load-bearing
state.

## Customer constraint (binding)

- Claude Code (Anthropic) usage credits are paid-for and reset
  May 1, 2026. **Every action burns paid usage** until reset.
- Push policy: only push GitHub when there is a release reason. No
  WIP, no comment-churn.
- gh CLI + git push themselves are free; **subagent dispatches and
  long main-session conversation are the cost.** I muddled this
  late in the prior session — main-session-tech-lead must keep them
  separate.

## What shipped today (10 releases)

| Tag | One-liner |
|---|---|
| v0.13.1 | Issue #61 doc (ADR-0002 design), #57 security-engineer frontmatter |
| v0.14.0 | TEMPLATE_MANIFEST.lock infra (ADR-0002), bare/per-item templates, MADR split |
| v0.14.1 | Manifest path/SHA decoupling fix |
| v0.14.2 | Predictive post-sync state in migration |
| v0.14.3 | Atomic install via tmp+mv (#63) |
| v0.14.4 | Self-bootstrap in upgrade.sh (#63 root) + agent-name compare (#64) + scaffold stub-fills (#65) |
| v0.15.0 | INDEX split (#66) + framework-ADR namespace `FW-ADR-NNNN` (#67) + rc3 checklist drafted |
| v0.15.1 | upgrade.sh exit-code fix |
| v0.16.0 | Retrofit-playbook revision pass (16 issues #40-56), stepwise-smoke (C-7), v2 placeholders |
| v0.17.0 | upgrade.sh `--target` (#68), SPDX headers (#69), CI ref template (#70) |

Issue tracker: 3 open, all aggregate trackers (#3 v2-proposal,
#27 v2-proposal, #59 RC backlog meta). **No bug-class issues remain.**

## v1.0.0-rc3 re-entry checklist state

Source: `/home/quackdcs/sw-dev-team-template/docs/v1.0-rc3-checklist.md`.

| Criterion | State | Blocking on |
|---|---|---|
| C-1 contract stability | ✓ | nothing |
| C-2 migration infra proven | ✓ | nothing |
| C-3 retrofit field-tested | **pending ratification** | QuackS7 next milestone close (customer ran the retrofit; it surfaced #40-56; v0.16.0 fixed all 16). Customer hasn't ratified DoD-met yet. |
| C-4 workflow-pipeline empirical | partial | three-path ✓; prior-art/proposal/duel need ≥3-5 real-task evidence each. QuackPLC M1 close + QuackS7 future tasks should accumulate. |
| C-5 audit agents exercised | **pending** | onboarding-auditor + process-auditor each run ≥2× against template. **DO NOT run before May 1** — costs Anthropic credits. |
| C-6 v2-proposal queue | ✓ | nothing |
| C-7 stepwise smoke | ✓ | nothing (green from v0.14.4 forward) |

## In flight (customer projects)

- **QuackS7**: scaffolded earlier; ran the retrofit; produced #40-56. v0.16.0 fixed all those. **Not yet at next milestone.** When that milestone closes, customer can ratify C-3.
- **QuackPLC**: scaffolded fresh + has been upgrading. Approaching a 72h soak that gates M1. M1 close is candidate evidence for C-4.

## Carry-overs (not rc3-blocking, but tracked)

- **FW-ADR-0005 implementation** — paraphrase-cards extraction
  from agent files into `docs/standards/paraphrase-cards.md`.
  Ratified for v0.15.x but not yet shipped. Substantial refactor
  (5 agent files + 3 templates touch standards). Out of scope for
  rc3 cut per checklist.
- **#21 contributor workflow polish** — PR templates, milestone
  labels, release-flow doc. Out of scope for rc3.
- **autoMode subagent denial pattern** — filed at
  `anthropics/claude-code#53279` (upstream Claude Code repo). Not
  template-side.
- **SWEProj's nested `sw-dev-team-template/` clone** — known
  development convenience, no `.git` in SWEProj root, gitignored
  through `wg0.conf` only. Not a template bug; project-side
  hygiene.

## What NOT to do next session

1. Don't dispatch C-5 audit agents until May 1.
2. Don't push between releases. Bundle into v0.x.y release commits.
3. Don't try to "do everything" — bias to short, single-stream work.
   Prior session sprawl was the trigger for this respawn.
4. Don't ratify C-3 yourself — that's a customer ruling. Wait for
   QuackS7 milestone close + customer's explicit OK.

## First-turn customer message (per agent-health-contract § 5.4)

The next tech-lead's first message to the customer should be
something like:

> Picking up after a context-decay reset. Today's work shipped
> v0.13.1 through v0.17.0; rc3 gates are C-3 (waiting on QuackS7
> milestone), C-4 (waiting on real-task evidence), and C-5
> (waiting on May 1 reset to dispatch audit agents). What would
> you like to drive at?

## Locations

- Template repo: `/home/quackdcs/sw-dev-team-template/` (clean,
  v0.17.0 stamped, all today's work pushed).
- This project (SWEProj): `/home/quackdcs/SWEProj/` (at v0.14.3
  per its `TEMPLATE_VERSION`; has not been bumped to v0.15+ to
  avoid burning credits during prior session).
- QuackS7: customer-side, separate.
- QuackPLC: customer-side, separate.
- v1.0-rc3 checklist: `/home/quackdcs/sw-dev-team-template/docs/v1.0-rc3-checklist.md`.
