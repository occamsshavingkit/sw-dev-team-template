# v0.10 Release Plan — private planning

**Scope.** Path from `v0.10.0` forward through `0.y.z` iteration
until the criteria in `sw-dev-team-template/docs/versioning.md`
are met and the template returns to a `v1.0.0-rc` track. Tracks
the Gate-3 engagement (one real downstream project, end to end)
and the issues that engagement is surfacing against the upstream
template. Not pushed to the public upstream.

Working copy of the template under improvement:
`/home/quackdcs/SWEProj/sw-dev-team-template/` (a.k.a. "upstream"
below).

**Track history:** the template was on a `v1.0.0-rc` track through
`v1.0.0-rc1` (2026-04-19) and `v1.0.0-rc2` (2026-04-19). That
track was withdrawn on 2026-04-20 because breaking-class issues
kept arriving (#15 rename, #27 memory architecture). Renumbered
to `v0.10.0`; the two `rc` tags remain in git history as markers.

Last updated: 2026-04-23.

---

## Release gates

| Gate | Status | Note |
|---|---|---|
| Gate 1 — taxonomy + agent roster complete | CLOSED (pre-rc1) | |
| Gate 2 — agent-file audit + cross-refs clean | CLOSED (pre-rc1) | |
| Gate 3 — two independent downstream engagements end-to-end | **OPEN** | First engagement live; issues #4–#29 came from it. Need a second independent engagement that surfaces no new rc-class issues before returning to `v1.0.0-rc`. |
| Gate 4 — all rc-cycle issues resolved or deferred with rationale | **OPEN** | See triage below. |
| Gate 5 — no open contract-breaking themes | **OPEN** | #15 terminology and #27 memory architecture must be decided before returning to `v1.0.0-rc`. |
| Gate 6 — agent roster stable, `tools:` frontmatter audited | **OPEN** | Rolls up #11, #14, and any other tool-grant drift. |
| Gate 7 — scaffold + upgrade + retrofit all shipped | **OPEN** | Retrofit (`V2_ROADMAP.md` §1) must land before returning to `v1.0.0-rc`. |
| Return to `v1.0.0-rc1` | blocked on Gates 3 – 7 | See `docs/versioning.md`. |

Rule for the 0.10.x cycle: breaking changes are **allowed** in minor
bumps (`0.10.0` → `0.11.0`) under SemVer's 0.y convention, provided
a migration script ships in `migrations/0.11.0.sh`. PATCH bumps
(`0.10.0` → `0.10.1`) remain non-breaking.

---

## Re-triage 2026-04-21 — v1-deceleration pull-forward

Returning to a `v1.0.0-rc` track is no longer time-boxed. The
Gate-5 "one-mega-memo" coupling that deferred four issues
(#16 intake log, #17 token budgets, #26 PM budgets, #27 SQLite
memory, advisor §5.5 archival) collapses when v1 is not the next
milestone. Items that were bundled only because they would all
have to land before `v1.0.0-rc1` can be decoupled.

Pull-forward decisions (supersede earlier buckets below):

- **#16, #17, #26, advisor §5.5** — pulled from `v2 memo-gated`
  to **`v0.11.0` MINOR** as **markdown-only** conventions. PM
  token ledger (`docs/pm/TOKEN_LEDGER.md`), intake-log file
  dump, archival-threshold rule for append-only `ARCHIVE.md`.
  No SQLite dependency.
- **#27 claude-mem SQLite** — reframed from "v2 architecture
  decision" to "**opt-in skill-pack integration**." Smaller
  design memo, lands in `v0.12.0` at earliest; does not gate
  anything.
- **#29** — **split**. `context-optimization` + `token-usage`
  menu entries land in `v0.10.1` PATCH (independent of #27).
  `claude-mem` entry waits on #27.
- **#30 (new)** — `v0.10.1` PATCH; semver-standard cite in
  `docs/versioning.md`.
- **`V2_ROADMAP.md` §2 QA outlines** — pull forward to
  `v0.11.0` (was `v1.x minor`, unscheduled). Seven outlines,
  `qa-engineer` owns.
- **`V2_ROADMAP.md` §3 style-guide seeds** — five-language
  seed set (py / ts / rust / go / bash) to `v0.11.0`. Step-2
  mandatory-languages question (the only v2-MAJOR-flavoured
  piece) slides to `v0.12.0` with a migration.
- **`V2_ROADMAP.md` §1 retrofit agent** — split. **Phase A
  (read-only triage) to `v0.12.0`**; Phase B+C (plan + execute)
  to `v0.13.0` or later. The "ship as bundle with §2+§3+§4"
  constraint no longer holds (§4 shipped; §2/§3 pulled to
  0.11.0).
- **Issue #6 SME contract Fix B/C** — removed from Gate-5
  critical path. Customer-decision memo lands in `v0.11.0`
  regardless of which Fix is chosen. Gate 5 becomes informational,
  not release-blocking.

Nothing is pulled backward. Nothing previously scheduled in
`v0.10.1` moves out.

---

## v0.10.0 commit blockers

The v0.10.0 VERSION + CHANGELOG + `docs/versioning.md` edits are
staged but **not yet committed**. Before cutting the `v0.10.0` tag
on the upstream, the following must land:

### B-1 — README rewrite (blocker)

Current `README.md` still carries the pre-scaffold-script Quickstart
("unzip into empty directory, run `claude`"). This is the exact
onboarding failure flagged in issue #5. Shipping a `v0.10.0` tag
with this README is dishonest — a new adopter who follows the
Quickstart literally gets the broken, un-stamped, no-`.git` state
that every downstream issue assumes doesn't exist.

Rewrite covers:

1. **Name the two entry points.** `scripts/scaffold.sh` for new
   projects. `scripts/upgrade.sh` for existing scaffolded projects.
   (Retrofit lands later — flag as v2.)
2. **Explicit "unzip is not enough" callout.** Loud, first-screen.
   If a user has already unzipped into a working directory, point
   at the repair path (or at re-scaffolding if repair doesn't
   exist yet).
3. **Quickstart rewrite.** From zip/clone → `scripts/scaffold.sh
   <target> <name>` → `cd <target>` → `claude`. Three commands,
   in order, with what each does.
4. **What to expect in the first session.** The FIRST ACTIONS flow
   (Steps 1–4) landed between rc1 and rc2 but the README still
   only mentions two steps. Update the Quickstart §2 wording.
5. **Agent-teams panel caveat.** `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
   is assumed but un-advertised to an adopter reading only the
   README; call it out.
6. **Where to file issues.** Point at `docs/ISSUE_FILING.md` and
   note the opt-in.
7. **Version + what 0.y means.** One paragraph pointing at
   `docs/versioning.md`: we are on 0.y because the public contract
   is not yet stable; breaking changes are allowed in minor bumps;
   here is what v1.0.0 will promise when it cuts.

**Owner.** `tech-writer` drafts, `researcher` verifies cited
files exist, `code-reviewer` gates, `tech-lead` merges.

**Effort.** ½ day including review.

### B-2 — Verify the scaffold path still works end-to-end

Before cutting `v0.10.0`, run `scripts/scaffold.sh` into a
throwaway `/tmp` directory and confirm the scaffolded project
opens cleanly with `claude` (FIRST ACTIONS fires, version-check
runs, no script errors). This is a sanity check, not new work.

**Owner.** `release-engineer`. **Effort.** 15 min.

---

## Incoming issues from Gate-3 engagement

Issues #4–#29 filed against `occamsshavingkit/sw-dev-team-template`
on 2026-04-19 / 2026-04-20, against `TEMPLATE_VERSION v1.0.0-rc2`
(SHA `f78ab30`). Under the reset `0.y.z` scheme, triage buckets are:

- **`v0.10.1` PATCH** — non-breaking doc / wording / routing fixes.
- **`v0.11.0` MINOR** — additive features or breaking changes
  (0.y allows breaking in MINOR); ships a migration script when
  breaking.
- **v2 design-memo-gated** — waits on the memory-architecture memo
  (folds #16, #17, #26, #27, `V2_ROADMAP.md` §5.5) or the retrofit
  contract (`V2_ROADMAP.md` §1).
- **Defer** — noted but not scheduled.

Full issue bodies for #4–#11 retained below; #12–#29 summarised in
the combined summary table at the end of this file.

### Issue #4 — CLAUDE.md Step 1 menu: wrong ToB install command

**Triage:** `v0.10.1` PATCH (doc bug).

**Problem.** Option [6] tells user to run
`/plugin install trailofbits-skills@trailofbits-skills`, which
doesn't exist. `trailofbits/skills` is a **marketplace** of ~30
plugins; install syntax is `<plugin-name>@trailofbits` (no `-skills`
suffix on the marketplace name).

**Fix.** Rewrite option [6] in `sw-dev-team-template/CLAUDE.md` and
the scaffolded copy to:
- Tell the user this is a marketplace, not a single bundle.
- Show `/plugin install <plugin-name>@trailofbits` syntax.
- List common picks (`semgrep`, `codeql`, `constant-time-analysis`,
  `trailmark`).

Verify options [1] Anthropic and [2] Superpowers resolve correctly
against the current Claude Code release while we're in there
(`researcher` task).

**Owner.** `tech-writer` (drafts), `researcher` (verifies current
install commands), `code-reviewer` (reviews), `tech-lead` (merges).

**Effort.** ≤ half a day.

---

### Issue #5 — README Quickstart implies unzipping is enough

**Triage:** **Part A (README rewrite) is v0.10.0 commit blocker — see B-1 above.** Parts B (detector) and C (repair script) are `v0.10.1` PATCH (detector) + `v0.11.0` MINOR (repair script is additive but changes onboarding contract).

**Problem.** Users download the release zip, unzip into their
intended project dir, run `claude`, and get a directory that
functionally starts but is missing scaffold invariants:
no `TEMPLATE_VERSION`, no stripped template-only files, no reset
registers, no `git init`. Drift is invisible until mid-session.

**Fix plan (do options 1 + 2 minimum; strongly consider 3):**

1. **README Quickstart rewrite.** State that the zip is the
   *template repo*, not a scaffolded project. First action is
   `scripts/scaffold.sh <target-dir> <project-name>` from the
   unzipped template, then `cd` into the target.
2. **SessionStart unzipped-in-place detector.** Extend
   `scripts/version-check.sh` (or sibling) to detect
   `VERSION present && TEMPLATE_VERSION absent && .git absent` and
   print a loud banner instructing the user to re-scaffold or run
   the in-place repair.
3. **`scripts/repair-in-place.sh`** (strongly recommended). Converts
   an unzipped-template directory into a scaffolded project in
   place: strip template-only files, stamp `TEMPLATE_VERSION`,
   reset registers, `git init`, seed `.template-customizations`.
   This is the path most users will actually want when they
   realize.
4. **Release artifact naming.** Consider renaming the zip to
   `sw-dev-team-template-SOURCE.zip` or dropping the zip release
   entirely and pointing at `git clone` only. **Defer to discussion
   with customer.**

**Owner.** `tech-writer` (README), `software-engineer` + `release-
engineer` (detector + repair script), `code-reviewer`, `tech-lead`.

**Effort.** 1–2 days if all of 1+2+3.

---

### Issue #6 — SME agent contract vs `researcher`: scope + feeding workflow

**Triage:** `v0.11.0` MINOR if Fix A, `v0.11.0` MINOR with breaking-rule carve-out if Fix B/C (0.y allows breaking). Gate 5 (no open contract-breaking themes) cannot close until this resolves.

**Problem.** Current rule restricts SMEs to
*customer-specific or externally-captured non-public* knowledge;
anything a Tier-1 source can answer is `researcher` territory. Two
failures observed on the engagement:

1. The rule cuts off the common mental model (SME = domain
   specialist that uses any source, including researcher output)
   without making clear *why*.
2. The external-SME → SME-agent **feeding workflow is
   undocumented**: who interviews, where the transcript goes, who
   paraphrases for the agent to consume, how the agent cites back.
   Result: even when the customer has a willing external expert,
   `tech-lead` doesn't know how to get that knowledge into the
   agent.

On a softPLC-in-Rust project with 5+ vendor domains, the rule
forced "no SMEs, route to researcher," collapsing vendor-specific
quirks / interop pitfalls / cert traps into one researcher.

**Open design decision (customer call required).**
Three candidate fixes — **Fix A** (tighten current model + add
feeding workflow), **Fix B** (broaden SME to
"domain specialist over curated sources"), **Fix C** (hybrid: ask
customer, but allow Fix-B-mode SMEs when domain is large enough
to pay for itself in `tech-lead` context savings).

Fix A is a MINOR. Fix B is a **MAJOR** (binding-rule reversal).
Fix C is MAJOR on the contract even if most projects stay on
current behavior.

**Action.** `tech-lead` → `architect` to draft a decision memo
with tradeoffs. Open question lands on the customer via
`tech-lead`, atomic, agents idle. Resolve before returning to a
`v1.0.0-rc` track — shipping `v1.0.0` with the SME contract still
this ambiguous would bake in the gap.

**Owner.** `architect` (memo), `tech-lead` (escalation), customer
(ruling), `tech-writer` (edits), `code-reviewer`, `researcher`.

**Effort.** 2–3 days including customer round-trip.

---

### Issue #7 — Step 4 (issue-feedback opt-in) not asked atomically

**Triage:** `v0.10.1` PATCH (process gap; wording + DoD fix).

**Problem.** Step 4 is described as "one atomic yes/no question,
when all agents are idle," but FIRST ACTIONS orders Steps 1 → 2
→ 3 → 4 with Step 2 being a multi-question block that naturally
absorbs attention. Steps 3 + 4 read as afterthoughts and get
deferred or resolved implicitly (exactly what the template
forbids). On the engagement, the customer had to *prompt*
`tech-lead` to ask Step 4 at all.

**Fix options (pick 1, consider combining with 3):**

1. **Atomic gates box** at the top of FIRST ACTIONS: Step 3 and
   Step 4 hoisted into a "these are atomic, ask them at first
   idleness, one per turn" section, with the Step-2 multi-question
   block *below*.
2. **Queue-it-first.** `tech-lead` writes Steps 3 + 4 into
   `docs/OPEN_QUESTIONS.md` at the very start of the session and
   asks at the first moment of idleness, not at the end of Step 2.
3. **DoD blocker.** Step 2 Definition of Done gains an explicit
   "Step 4 answered" row so scoping cannot close while opt-in is
   still open. (Currently DoD says "open questions each with
   answerer + status" — which is satisfied even if Step 4 is
   unanswered.)

Strongest: 1 + 3.

**Owner.** `tech-lead` (drafts), `code-reviewer`, `architect`
(sanity-checks the ordering), `researcher` (verifies no
cross-reference drift).

**Effort.** Half a day.

---

### Issue #8 — `ISSUE_FILING.md` should forbid downstream project name in upstream issues

**Triage:** `v0.10.1` PATCH (doc rule).

**Problem.** Current text says "redact customer-sensitive content"
but doesn't flag the downstream project name *itself* as
sensitive. Default ends up being "include it, might be useful
context." Project name can reveal commercial intent, market, or
codenames to anyone who can read the upstream repo.

**Fix.**

1. Explicit rule in `docs/ISSUE_FILING.md` § "What to include":
   *"Do NOT include the downstream project name, customer name,
   product codename, or any identifier that would let a third
   party attribute the issue to a specific downstream project.
   Describe the project only in enough abstract terms to make the
   bug pattern reproducible (e.g., 'a softPLC-in-Rust project',
   not the project's actual name)."*
2. Promote to checklist **item #0** (scan before filing).
3. Add `tech-lead` guidance to scan drafted issue body for
   project / customer identifiers before filing; default phrasing
   is "a downstream project."

**Retroactive action.** Downstream-project `tech-lead` will edit
the two already-filed issues on its side; also confirm none of
#4–#9 bodies contain downstream-project identifiers
(`researcher` quick verification pass).

**Owner.** `tech-writer`, `researcher` (scan for drift),
`code-reviewer`, `tech-lead`.

**Effort.** Half a day (template fix). Retroactive edit is
downstream's job, not ours.

---

### Issue #10 — `tech-lead` should default to parallelism

**Triage:** `v0.10.1` PATCH.

**Problem.** Nothing in `.claude/agents/tech-lead.md` or `CLAUDE.md`
§ "Routing defaults" tells `tech-lead` its default posture while
agents work is to keep dispatching independent parallel work.
Implicit default reads as "ask → wait → relay → ask again,"
serializing everything. On the engagement, `tech-lead` idled
waiting on `researcher`'s dog-name roster instead of firing off
the first-milestone spec, charter draft, and PLC landscape survey
in parallel. The rename-retroactively pattern (use canonical
role names until teammate names arrive) is also undocumented.

**Fix.**

1. Add "Parallelism default" section to
   `.claude/agents/tech-lead.md`: when the next step does not
   strictly depend on a running subagent's answer, kick it off in
   parallel. Subagent outputs are eventually-arriving artifacts to
   merge, not serial blockers.
2. Explicit corollary: Step 3 (agent naming) never blocks other
   workstreams. Agents are callable by canonical role name from
   project start; teammate names are a cosmetic remap applied on
   arrival.
3. Worked example in routing defaults showing a fan-out
   (first-milestone spec + researcher survey + charter in one
   dispatch turn).

**Owner.** `tech-lead` (drafts), `architect` (sanity), `code-reviewer`.

**Effort.** Half a day.

---

### Issue #11 — `architect` has no Write tool; cannot produce artifacts

**Triage:** `v0.10.1` PATCH for the architect fix; `v0.11.0` MINOR if the pre-flight check ships. Rolls into Gate 6 (agent roster stable).

**Problem.** `.claude/agents/architect.md` frontmatter grants
`tools: Read, Grep, Glob` only. The role's own `description` lists
producing structural decisions, ADRs, architecture descriptions —
all persistent artifacts. On the engagement, `architect` produced
a full first-milestone spec correctly but had to relay the content
back to `tech-lead` because it had no Write, burning a round-trip.

**Fix.**

1. `architect.md` frontmatter → `tools: Read, Grep, Glob, Write,
   Edit`. (Bash stays out by default.)
2. **Full roster audit.** Cross-reference each agent's
   `description` + role body against its `tools:` grant. Any agent
   the roster expects to produce persistent artifacts but which is
   read-only is mis-configured. Likely suspects:
   `tech-writer` (must have Write/Edit), `qa-engineer` (test
   plans), `release-engineer` (pipeline config), `researcher`
   (CUSTOMER_NOTES, SME inventories), `project-manager` (PM
   artifacts). Verify.
3. Pre-flight check in `scripts/agent-health.sh` that flags
   description-vs-tools mismatches so future role edits can't
   regress this silently.

**Owner.** `tech-lead` (triggers audit), `architect` (self-fix +
reviews roster), `code-reviewer` (verifies every agent), plus
whichever role owns each mis-configured file.

**Effort.** 1 day (audit + fix is fast; writing the pre-flight
check is most of the effort).

---

### Issue #9 — Step 3 naming: category scope not pinned before dispatch

**Triage:** `v0.10.1` PATCH.

**Problem.** `tech-lead` takes the customer's category answer
and dispatches `researcher` directly. No confirmation step of
what's IN vs OUT, whether actor names or character names are
wanted, living-vs-deceased, tone-sensitivity. `researcher`
guesses; guess errs toward inclusion; customer rejects names
post-hoc, awkwardly.

**Fix.** Insert **Step 3a — category scope pin** in `CLAUDE.md`
BEFORE the `researcher` dispatch. Single atomic message from
`tech-lead` that echoes back:
- one-sentence category boundary,
- actor-vs-character convention,
- obvious edge cases to rule in / out,
- living + deceased ok?, tone-sensitive exclusions?

Customer confirms / edits in one message. Only then does
`tech-lead` dispatch `researcher`.

Mirror rule in `sw-dev-team-template/docs/AGENT_NAMES.md` so
the convention travels with the template.

**Owner.** `tech-lead` (drafts), `architect` (sanity),
`tech-writer` (prose), `code-reviewer`.

**Effort.** Half a day.

---

## Issues #12–#29 (summarised)

Full issue bodies on GitHub. Detail re-triaged under the 0.y scheme.

| # | Title | Bucket | Note |
|---|---|---|---|
| 12 | tech-lead missed "all agents idle" pre-send check | `v0.10.1` PATCH | Pairs with #10 and #28; one edit to `tech-lead.md` covers the trio. |
| 13 | Subagent hang / no heartbeat convention | `v0.11.0` MINOR | Needs small design: heartbeat cadence + watchdog protocol. |
| 14 | `researcher` has no `SendMessage` | `v0.10.1` PATCH | Roll into the Gate-6 roster `tools:` audit (#11). |
| 15 | Rename `customer` → `product owner` | `v0.11.0` MINOR (breaking, allowed on 0.y) | Needs migration script `migrations/0.11.0.sh` for `CUSTOMER_NOTES.md` rename + glossary entries. Was v2-MAJOR before the track reset. Gate 5. |
| 16 | Debug-mode intake log | `v0.11.0` MINOR | Pulled forward 2026-04-21. File-dump only — no SQLite dependency. |
| 17 | Agent token-budget convention | `v0.11.0` MINOR | Pulled forward 2026-04-21. Markdown-only convention (`docs/pm/TOKEN_LEDGER.md`). |
| 18 | Dispatches must reference `AGENT_NAMES.md` | `v0.10.1` PATCH | Short rule added to `tech-lead.md`. |
| 19 | PM no-customer-contact vs respawn notification contradiction | `v0.10.1` PATCH | Pick Fix B (respawned `tech-lead` announces itself) or Fix A (explicit exception). Gate 5-adjacent. |
| 20 | INVENTORY.md not kept in sync | `v0.10.1` PATCH | Reinforcement in `researcher.md` + agent-handoff rule. Cross-refs advisor §5.5 archival. |
| 21 | Proper GitHub contributor workflow | `v0.11.0` MINOR | Not actually breaking; was v2 by scope. Land when contributor workflow is designed. |
| 22 | Detect already-installed skills in Step 1 menu | `v0.10.1` PATCH | Small UX fix. |
| 23 | tech-lead prompt concision guidance | `v0.10.1` PATCH | One section in `tech-lead.md`. |
| 25 | Zero-context / disruptor agent | `v0.11.0` MINOR | Additive new agent. Was v2 for scope; can land anytime after design. |
| 26 | PM owns token budgets | `v0.11.0` MINOR | Pulled forward 2026-04-21. PM aggregates task-level token usage into `docs/pm/TOKEN_LEDGER.md`; `task-template.md` DoD gains token + prompt rows. |
| 27 | SQLite hybrid-ledger memory (`claude-mem`) | `v0.12.0` MINOR | Reframed 2026-04-21 as opt-in skill-pack integration, not v2 architecture. Small memo, additive adapter. |
| 28 | Turn Ledger / final-word footer | `v0.10.1` PATCH | Pairs with #12 and #18 into one "customer-facing output discipline" section in `tech-lead.md`. |
| 29a | `context-optimization` + `token-usage` to Step 1 menu | `v0.10.1` PATCH | Split from #29 2026-04-21. Independent of #27. |
| 29b | `claude-mem` to Step 1 menu | `v0.12.0` MINOR | Lands with #27 adoption decision. |
| 30 | Explicit semver-standard reference | `v0.10.1` PATCH | One-line edit to `docs/versioning.md` citing https://semver.org/. |
| 31 | Time-based review cadences unspecified (wall-clock vs session-anchored) | `v0.10.1` PATCH (parts 1+2: wording fix across PM templates + `project-manager.md` + one-line `CLAUDE.md` note); `v0.11.0` MINOR (part 3: optional `scripts/pm-cadence-check.sh` SessionStart hook) | Session-anchored rule: "first session on/after the boundary, run-once; cadences are a floor, not a backlog." |

---

## Advisor items from issue #24 (V2_ROADMAP §5)

Already triaged — see `V2_ROADMAP.md` §5. Cross-reference:

| Advisor item | Bucket |
|---|---|
| §5.1 ADR trigger list | `v0.10.1` PATCH |
| §5.2 Role conflict-resolution tie-break | `v0.10.1` PATCH |
| §5.3 Test-pass gating in DoD | `v0.10.1` PATCH |
| §5.4 Adversarial QA stance | `v0.11.0` MINOR (new `qa-engineer.md` section is additive but substantive) |
| §5.5 Finished-work archival + size budgets | `v0.11.0` MINOR (pulled forward 2026-04-21; ship archival rule + soft caps standalone, without SQLite) |

---

## Consolidated release queue

### `v0.10.0` — commit blockers (above)

1. B-1 README rewrite (½ day).
2. B-2 scaffold end-to-end smoke test (15 min).

### `v0.10.1` — PATCH bundle (doc + process fixes)

Combined effort ≈ 3–4 days. Group the edits that touch the same
files into single commits so review is cheap.

- ~~#4 ToB install command~~ — landed
- ~~#5 part B (version-check unzip-in-place detector)~~ — landed 2026-04-23
- ~~#7 Step 4 atomicity~~ — landed (promoted to Step 0)
- ~~#8 ISSUE_FILING redact project name~~ — landed
- ~~#9 Step 3 category scope pin~~ — landed
- ~~#10 + #12 + #18 + #28 → one "tech-lead customer-facing output discipline" edit~~ — landed
- ~~#11 architect Write tool + #14 researcher SendMessage → roster `tools:` audit pass 1~~ — landed 2026-04-23 (audit added `Write, Edit` to `tech-lead`; rest already correct)
- ~~#19 PM respawn contradiction~~ — landed 2026-04-23 (Fix B verified consistent across `agent-health-contract.md` §5.4, `project-manager.md`, `tech-lead.md`)
- ~~#20 INVENTORY sync rule~~ — landed
- ~~#22 detect pre-installed skills~~ — landed (rule in Step 1 menu)
- ~~#23 tech-lead prompt concision~~ — landed
- ~~**#29a skill-pack menu: `context-optimization` + `token-usage`**~~ — landed
- ~~**#30 semver-standard cite in `docs/versioning.md`**~~ — landed
- ~~Advisor §5.1 / §5.2 / §5.3~~ — landed

### `v0.11.0` — MINOR bundle (features + breaking changes)

Reshuffled 2026-04-21 to absorb items previously deferred under
the v2 memo gate and from `V2_ROADMAP.md`. Combined effort now
≈ 3–4 weeks; ships with `migrations/0.11.0.sh`.

Carryover from earlier queue:
- #5 part C (`scripts/repair-in-place.sh`)
- ~~#6 SME contract decision memo + customer ruling~~ — landed 2026-04-23 (Fix-C hybrid: primary-source vs derivative modes; Gate 5 cleared)
- #11 pre-flight check in `scripts/agent-health.sh`
- #13 subagent heartbeat / watchdog
- #15 customer → product owner rename (breaking, migration required)
- #21 GitHub contributor workflow
- #25 zero-context / disruptor agent
- Advisor §5.4 adversarial QA stance

Pulled forward 2026-04-21 (markdown-only, additive):
- **#16 debug-mode intake log** — session-end file dump.
- ~~**#17 + #26 PM token-budget convention**~~ — **LANDED 2026-04-23.** `task-template.md` DoD row strengthened (v0.10.1) and now references `docs/templates/pm/TOKEN_LEDGER-template.md` (v0.11.0). First-use copy to `docs/pm/TOKEN_LEDGER.md`.
- **Advisor §5.5 archival** — closed-row rule + soft line / token caps on binding docs; append-only `ARCHIVE.md`. (`researcher.md` body landed in v0.10.1; `ARCHIVE.md` template still pending.)
- **`V2_ROADMAP.md` §2 QA outlines** — seven outlines under `docs/templates/qa/`.
- **`V2_ROADMAP.md` §3 style-guide seeds** — five languages (py / ts / rust / go / bash).

### `v0.12.0` — MINOR bundle (tooling + opt-in integrations)

Combined effort ≈ 2–3 weeks.

- **`V2_ROADMAP.md` §1 retrofit Phase A** — read-only triage (`scripts/retrofit.sh --plan-only`).
- **#5 part C repair-in-place** — if not already absorbed into retrofit Phase A.
- **#27 claude-mem SQLite** — opt-in skill-pack integration (short memo, adapter, not template default).
- **#29b claude-mem menu entry** — lands with #27.
- **`V2_ROADMAP.md` §3 Step-2 mandatory-languages question** — scoping-template update + migration.

### `v0.13.0` and beyond

- `V2_ROADMAP.md` §1 retrofit Phase B (plan writer) + Phase C (execute). Separate from Phase A to avoid write-risk on first ship.
- Any remaining v2 items not yet pulled forward.

### Return to `v1.0.0-rc`

No longer time-boxed. When Gates 3 / 4 / 6 / 7 close naturally
through the 0.y cycle and two independent downstream engagements
surface no new rc-class issues, cut `v1.0.0-rc1` fresh. Gate 5
is informational; #6 and #15 land in 0.11.0 regardless of track.

---

## Conventions

- Every issue gets a `docs/pm/LESSONS.md` entry in the template
  when its fix lands, citing the original upstream issue number.
- `CHANGELOG.md` in the template lists each fix under the version
  that shipped it.
- When an issue closes, strike it here and move a one-line summary
  to the `CHANGELOG.md` entry for the relevant version.
- Breaking changes in a `0.y → 0.(y+1)` MINOR bump **must** ship
  with `migrations/0.(y+1).0.sh`.
