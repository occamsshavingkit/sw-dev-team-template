# Work log — 2026-04-20 session

Running budget: $15 starting credit on Opus 4.7 (1M). Single session.
Writing down state so a later session can pick up without archaeology.

## Goal of this session

Land the `v0.10.0` track reset cleanly, then work the `v0.10.1` PATCH
bundle from `V0_10_RELEASE_PLAN.md` § "Consolidated release queue"
until credit runs out.

## State snapshot

- `sw-dev-team-template/VERSION` → `v0.10.0` (uncommitted).
- `sw-dev-team-template/CHANGELOG.md` → new `v0.10.0` entry at top
  (uncommitted).
- `sw-dev-team-template/docs/versioning.md` → new file, policy +
  return-to-rc criteria (uncommitted).
- `/home/quackdcs/SWEProj/TEMPLATE_VERSION` → restamped to `v0.10.0`
  with explanatory footer (in-place, no git here).
- `V1_RELEASE_PLAN.md` → renamed to `V0_10_RELEASE_PLAN.md` and
  fully re-triaged (issues #4–#29 + advisor §5.1–§5.5) under 0.y
  buckets. Consolidated release queue at the bottom.
- `V2_ROADMAP.md` § 5 added (advisor items from issue #24).

## Done in this session (most recent last)

- [x] Triaged upstream issues #12–#29 (skipping #24) and recommended
      bucket changes.
- [x] Consulted `architect`, `qa-engineer`, `researcher` on the
      advisor content of issue #24; four of ten points validated.
      Added them to `V2_ROADMAP.md` § 5.
- [x] Demoted `v1.0.0-rc2` → `v0.10.0`. Edited `VERSION`, CHANGELOG,
      created `docs/versioning.md`, restamped project `TEMPLATE_VERSION`,
      renamed `V1_RELEASE_PLAN.md` → `V0_10_RELEASE_PLAN.md` and
      rewrote body to match the new scheme.
- [x] Reclassified: breaking v2 items (#15 rename, #21 GH workflow,
      #25 disruptor) moved to `v0.11.0`; the memory cluster
      (#16/#17/#26/#27 + advisor §5.5) stays v2 behind a memory-
      architecture memo.
- [x] **B-1 README rewrite** (v0.10.0 commit blocker). Rewrote
      `sw-dev-team-template/README.md` with explicit
      "unzip is not enough" callout, four-step Quickstart
      (scaffold → env var → cd → claude), upgrade flow,
      status/version paragraph pointing at `docs/versioning.md`,
      full roster (incl. `project-manager`), and new scripts list.
- [x] **B-2 smoke test** — blocked. `Bash` permission denied for
      running scaffold.sh into /tmp. **User must run this before
      committing v0.10.0.** Suggested command in the NEXT section.
- [x] #4 ToB install command fixed in `CLAUDE.md` Step 1 menu.
      Marketplace framing + common-picks list.
- [x] #22 "detect already-installed skills" rule added to
      `CLAUDE.md` Step 1 rules block.
- [x] #8 `docs/ISSUE_FILING.md` now has mandatory **pre-flight
      redaction scan** at item 0 with four banned identifier
      categories + "no exceptions" rule.
- [x] #7 FIRST ACTIONS preamble now has an "atomic gate" paragraph
      calling out Steps 3 and 4 explicitly; Step 2 DoD gained a
      **"Step 4 answered"** row.
- [x] #9 New Step 3a section added to `CLAUDE.md` — category scope
      pin (one-sentence boundary, actor-vs-character, in/out
      edge cases, living/deceased, tone-sensitive) before
      dispatching `researcher`.
- [x] #10 + #12 + #18 + #28 **combined edit** landed in
      `tech-lead.md`:
        * New § "Parallelism default" — fan-out at project start,
          Step 3 never blocks.
        * New § "Customer-facing output discipline" with R-1
          pre-send idleness check, R-2 Turn Ledger footer +
          DECISIONS.md append-log, R-3 dispatch briefs must
          reference AGENT_NAMES.md.
      New file `docs/DECISIONS.md` seeded as append-only black-box
      recorder (referenced by R-2).
- [x] #11 + #14 roster `tools:` audit pass 1:
        * `architect` gained `Write, Edit`.
        * All ten role agents + `sme-template` gained `SendMessage`.
      Pre-flight check script still TBD (v0.11.0 MINOR).
- [x] Advisor §5.1 — ADR trigger list added to `architect.md`
      (major refactor, new dep, data-model change, auth change,
      cross-cutting pattern change, safety-critical path, lock-in).
- [x] Advisor §5.2 — design-intent tie-break `architect` >
      `software-engineer` in both `architect.md` and `tech-lead.md`.
      `tech-lead` arbitrates; customer is final authority.
- [x] Advisor §5.3 — test-pass DoD row added to
      `docs/templates/task-template.md`: raw runner output
      (exit code + counts + timestamp) must attach to the task
      before closure; `qa-engineer` re-runs rather than trusts
      summary; failing suite reverts to `software-engineer`.
- [x] #23 — new `tech-lead.md` § "Prompt concision when
      dispatching": one-sentence goal, deliverable shape, cite
      don't paste, cap at one screen.
- [x] #20 — new "file-creation handoff" rule in `researcher.md`
      Job #4: any agent creating files under `docs/sme/<domain>/`
      updates INVENTORY in-turn or `SendMessage`s researcher; a
      drifted INVENTORY is a routing gap, not a silent fix.
- [x] Queued Q-0013 (#19 PM respawn contradiction), Q-0014
      (#15 rename confirmation), Q-0015 (B-2 smoke test) in
      `/home/quackdcs/SWEProj/docs/OPEN_QUESTIONS.md` for
      customer to answer next session.

## Blocker for committing `v0.10.0`

**B-1 — README rewrite.** Current `README.md` still says "unzip into
empty directory, run claude" — the exact failure mode of issue #5.
Cannot cut a `v0.10.0` tag with dishonest onboarding docs.

**B-2 — Scaffold smoke test.** ✓ DONE 2026-04-20. Customer ran
`scripts/scaffold.sh /tmp/smoke-test-v010 "Smoke Test"` and it
emitted the expected version stamp + FIRST ACTIONS banner with
no errors. Q-0015 closed.

## Queue status (updated 2026-04-20)

### Done this session
#4, #7, #8, #9, #10, #11 (partial — no pre-flight script yet),
#12, #14, #18, #19 (Fix B), #20, #22, #23, #28, advisor §5.1,
§5.2, §5.3.

#19 implementation: `project-manager.md` no longer contacts
customer at respawn; `agent-health-contract.md` § 5.4 rewritten
with the "First-turn customer message" discipline;
`tech-lead.md` § "Agent health + respawn" updated;
`docs/templates/handover-template.md` gained § 9 "First-turn
customer message" section. Q-0013 closed.

#15 resolution: **no rename**. Customer ruling 2026-04-20:
keep `customer` as umbrella term, but make the glossary define
all four related roles explicitly. Executed in
`sw-dev-team-template/docs/glossary/ENGINEERING.md` §
"Roles and parties": rewrote with binding definitions of
**customer** (umbrella), **product owner**, **end customer /
end user**, **sponsor**, and **SME**, plus a "role-stacking"
paragraph. Upstream issue #15 can be closed with
"no-rename, glossary clarified" as resolution. Removes
`v0.11.0` rename scope; Gate 5 breaking-themes list shrinks
to just #27 (memory architecture). Q-0014 closed.

### Open v0.10.1 items — pick up next session

1. **#19 PM respawn contradiction** — waiting on Q-0013 customer
   ruling (A/B/C). Do NOT implement until answered.
2. **#5 part B** — version-check unzip-in-place detector. Extend
   `scripts/version-check.sh` to detect `VERSION present &&
   TEMPLATE_VERSION absent && .git absent` and print a loud
   banner. Then add a test.
3. **#11 pre-flight check** — `scripts/agent-health.sh` addition
   that flags description-vs-tools mismatches. (Actually v0.11.0
   MINOR per plan; can wait.)

### Open v0.11.0 items — not in scope for v0.10.x

- #6 SME contract decision (Gate 5)
- #13 subagent heartbeat / watchdog
- #15 rename customer → product owner (Q-0014 pending)
- #21 GitHub contributor workflow
- #25 zero-context / disruptor agent
- Advisor §5.4 adversarial QA stance
- #5 part C repair-in-place script
- #29 skill-pack menu additions (conditional on #27)

### v2 memo-gated (Gate 5)

Memory-architecture memo covering #16, #17, #26, #27, advisor §5.5.
Do not start piecemeal implementation — the memo governs shape.

## Known deferrals

- **Upstream git commit + tag.** I am NOT committing `v0.10.0` or
  pushing to GitHub. User has explicitly staged the edits; the
  commit + `git tag v0.10.0` is a user action per Hard Rule 4
  (release = customer-critical).
- **Issue bodies on GitHub.** Not retroactively edited. The rc2
  stamp they cite is a point-in-time reference.
- **#15 rename (customer → product owner).** Gate 5 blocker. Needs
  customer ruling (the `PO` framing may or may not be what the
  customer wants). Do NOT start the rename until asked — it's a
  breaking `v0.11.0` MINOR and the migration script shape depends
  on the ruling.
- **Memory-architecture memo.** v2-gated. Design work, not
  implementation. Out of scope for this session.

## Convention for this log

- Append progress as you go; do not rewrite history.
- At session end, move "done" items into a dated heading and leave
  the queue + blocker sections for the next session.
- If credit runs out mid-edit, leave a TODO breadcrumb at the top
  of the affected file and note the file path here.
