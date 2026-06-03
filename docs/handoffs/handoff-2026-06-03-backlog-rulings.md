# Session Handoff — 2026-06-03 — backlog burndown + PR salvage + ruling session

## TL;DR
A very long autonomous session under the customer directive *"keep working the
backlog until it is empty; merge PRs when the bots say they're green."*
Outcome: **~31 issues closed across 13 merged PRs**, the three stale 2026-05-28
PRs triaged (two merged, one pending a meta-branching decision), and a
**14-ruling clarification session** drained the framework-gap decision queue.
State is clean; next major work is **implementing the 14 rulings** (task #17).

## Working model (unchanged — read if new)
Sessions start in the **meta-project** `/home/quackdcs/SWEProj` (PLAN: ADRs,
registers, CUSTOMER_NOTES, OPEN_QUESTIONS, specs) and do product work in the
**scaffold** `./sw-dev-team-template` (DO: code, tests, contracts, templates).
Scaffold + meta share one GitHub remote `occamsshavingkit/sw-dev-team-template`;
the remote's `main` is the **scaffold's** line. Meta uses feature branches
(`016-…`, `012-…`). See `CLAUDE.md` and memory `[[all-work-in-scaffold-submodule]]`.

## Repo state at handoff
- **Scaffold** `main` @ `459c2ff` — clean. 23 open issues. One open PR: **#280**.
- **Meta** on `016-token-economy-design` @ `3723ad5`, **~16 commits ahead of
  origin (UNPUSHED)** — carries the whole session's meta planning (reverts,
  P-registers, CLAUDE fix `bafddb8`, ADRs fw-adr-0021..0024, the 14 rulings).
  Uncommitted: `docs/handoffs/fw-012-…json` (pre-existing M), the
  `sw-dev-team-template` gitlink (stale — points behind current scaffold main),
  `.worktrees/`, and the prior `handoff-2026-06-02-bug-wave.md` (untracked).

## What landed this session (13 merged PRs)
- **Bug-wave** #304: #222 #276 #288 #254 · **#314** runtime-mirror drift hotfix
- **#307**: #213 #218 #219 #269 #271 · **#309**: #306 #216 (test-gate hermeticity)
- **#310**: #211 #227 #230 #236 #208 · **#311**: #285 #250 #289 #247 #277
- **Template-quality** #313: #240 #241 (AI/ML + ISO 29148) · #315: #243 (IEEE 1016
  + 42010) · #316: #238 (IEEE 1044/730/1012) · #317: #242 (author markers)
- **#318**: #305 #308 (mktemp-harden + fixture-07) · **#278** release plan +
  Q-0020/0021/0022 (salvaged) · **#279** token-economy #239 #245 (salvaged+reconciled)
- Filed: #305 #306 #308 #319. Closed-stale: #268, #302.

## The 14 rulings (2026-06-03) — recorded in meta CUSTOMER_NOTES + OPEN_QUESTIONS Q-0019..Q-0032
| Ref | Ruling |
|---|---|
| fw-adr-0024 (#212) | **Hybrid** worktree isolation (readers→worktrees, writers serialized). ADR Accepted. |
| fw-adr-0023 (#276) | **Sidecar** `.activity.jsonl`, MINOR bump + migration, remove normalizer. ADR Accepted. |
| #301 | **Add ui-ux-designer** role (UX + WCAG; wrap accesslint) |
| #290 | **Add mcp-liaison** role (delegated external-model MCP sessions) |
| #291 | **Split researcher → researcher + librarian** (records custodian) |
| #302 | **Keep uniform** ceremony — declined; **closed won't-fix** |
| #303 | **Document clarification-session mode** (cadence relaxes, shape stays atomic) |
| #287 | **Bounded + harness** poll-loop policy (cap+escalate, bg auto-re-invoke; +#265) |
| #293 | **Delegated-specialist mode — ALL providers** (AGENTS.md/GEMINI.md/opencode) |
| #300 | **Build Gemini full harness now, standalone** (GEMINI.md + .gemini/agents) |
| #294 | **Both** — ID auto-allocate (reserve-number.sh) + CI duplicate-ID gate |
| #297 | **Dispatch-template mechanism** only (no gate; dispatch is ephemeral) |
| #292 | **Both** — CUSTOMER_NOTES entry template + content-aware guard |
| #299 | **Authoring checklist (non-binding)** — no new binding rule (Q-0018 concern) |

## NEXT MAJOR WORK — implement the rulings (task #17)
Coherent chunks (customer offered these as the menu; paused before choosing):
1. **Roster bundle** (#301/#290/#291) — 3 new/changed roles; each = contract +
   manual + runtime mirrors + roster table / AGENT_NAMES / INDEX updates. Do
   together (they interact). **Mirror discipline applies** (see hazards).
2. **fw-adr-0024** worktree isolation — the 11 enumerated contract/helper changes
   in the ADR. High leverage: unblocks parallel reader agents for everything after.
3. **fw-adr-0023** activity sidecar — schema bump + migration + remove the #276 normalizer.
4. **#300 Gemini harness** (standalone, BIG) + **#293** delegated-specialist parity (all providers).
5. **Enforcement quick wins** — #294 (auto-allocate + CI gate), #297 (dispatch template),
   #292 (entry template + guard), #299 (authoring checklist), #303 (clarification-mode doc).
Each impl closes its issue AND should get a ruling-comment on the GitHub issue
for traceability (rulings currently live only in meta CUSTOMER_NOTES/OPEN_QUESTIONS).

## #280 — needs a customer META-BRANCHING decision (do NOT force autonomously)
#280 (016→012) is the meta-side spec-016 token-economy design + a now-stale
submodule bump. The session's meta work is committed on local `016` (unpushed).
Pushing `016` would reshape #280 far beyond its token-economy scope and force an
ambiguous 016→012 merge. Options the customer can pick: (a) push `016` to refresh
#280 as-is; (b) split the spec-016 commits onto a clean branch retargeted to the
real integration base; (c) re-bump submodule + customer merges; (d) leave #280 and
land the meta work however the workspace is organized. **fw-adr-0023/0024 + the 14
rulings are safely committed on local 016 regardless.**

## Open issues remaining (23) — categorized
- **Ruling-implementation** (the 13 above) — most of the remaining count.
- **Large/multi-day:** #262 (rc9→rc14 upgrade reliability, 7 conflicts), #261
  (rc14 schema backfill), #274 (taxonomy refresh), #296/#298 (fw-adr-0021
  handoffs / multi-model briefs).
- **Small leftover:** #275 (SE model→sonnet — was v1.1.1 in the release plan),
  #319 (remaining PID-temps), #265 (bg-dispatch default — ties to #287).

## HAZARDS / lessons (saved as memories — READ before related work)
1. `[[hazard-agent-contract-runtime-mirror-drift]]` — editing `.claude/agents/*.md`
   requires regenerating + **committing** the `docs/runtime/agents/*` + `.opencode/agents/*`
   mirrors in the same commit; local `--verify` lies (compares working-tree to
   itself). "Green" must include the `agent-contract` check passing. Bit us 2×.
2. `[[hazard-release-gate-fixtures-mutate-live-repo]]` — `test-gate-fail-each.sh`
   git-reset the live branch (#306, now fixed). Don't run release-gate tests that
   mutate git on a work branch; sandbox in a /tmp clone.
3. `[[feedback-pre-specify-routed-through-class]]` — on multi-file SE batches,
   state the `Routed-Through` class per file up front (ci→release-engineer,
   docs→tech-writer) or FW-ADR-0011 R3 fails review.
4. Merge discipline: verify `agent-contract` + `template-contract-smoke` +
   `question-lint` are PASS (not just "no required checks") — AccessLint is
   advisory/inapplicable for non-UI PRs.

## Loose ends (low priority)
- Stale local scaffold branches (`fix/backlog-batch-*`, `feat/016`,
  `chore/release-plan-v1.x`, `fix/gate-hermeticity`, `fix/runtime-mirror-drift`,
  `fix/backlog-batch-11` unused) and their remote counterparts (merged PRs used
  `--merge` without `--delete-branch`) can be pruned.
- **Meta vs scaffold OPEN_QUESTIONS Q-number divergence** (meta Q-0019..Q-0032
  vs scaffold's own Q-0019..Q-0022) — flagged by researcher; this is #294's
  collision problem made real. Reconcile when #294 is implemented.
- Meta `016` is unpushed (~16 commits) — back it up / integrate per the #280 decision.
