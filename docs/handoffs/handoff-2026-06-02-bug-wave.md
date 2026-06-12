# Session Handoff — 2026-06-02 — framework-gap analysis + bug wave

## ⚠️ READ FIRST — the working model (this cost the session)

**The meta-project (`/home/quackdcs/SWEProj`) is the TEAM that improves the
scaffold. There is a strict PLAN / DO split:**

- **PLAN → meta-project (here):** ADRs (`docs/adr/`), problem registers /
  analysis (`docs/pm/`), `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`,
  specs, the team apparatus (`.claude/agents/`, `CLAUDE.md`).
- **DO → scaffold (`./sw-dev-team-template/`):** all implementation — code,
  scripts, migrations, tests, framework manuals. `gh`/PR/commit of product
  work targets the scaffold.
- **The scaffold stays CLEAN of planning artifacts.** Never put ADRs /
  registers / coordination docs in it.

This is now in `CLAUDE.md` § "Project Identity / Working Tree" and in
persistent memory (`plan-in-meta-do-in-scaffold`). It was misunderstood
twice this session (first inverted, then over-corrected). Do not re-derive.

The customer also wants this generalized: *a reusable "detached team"
operating mode* so the team can be pointed at ANY target repo and improve it
without injecting team scaffolding into that repo. **TODO: capture as a
planning ADR in the meta-project** (not yet done).

---

## Where things stand

### Meta-project (`/home/quackdcs/SWEProj`, branch `016-token-economy-design`) — CLEAN
- Planning docs are correctly committed here (KEEP): `638ec79` CUSTOMER_NOTES
  rulings · `08df6fb` ADRs fw-adr-0021/0022 · `e5e1f0b` register+findings+drafts
  · `4975171` P13–P15.
- `45f9cc3` reverted the 5 framework code commits that were committed here by
  mistake. `bafddb8` corrected the backwards `CLAUDE.md`.
- **Uncommitted leftovers to clean up:** `tests/release-gate/upgrade-paths-allowlist.txt`
  (the #254 allowlist edit — belongs in the scaffold, discard here); `VERSION`
  (empty test detritus — `rm`); `docs/handoffs/fw-012-…json` + `sw-dev-team-template`
  gitlink + `.worktrees/` are pre-existing, leave them.

### Scaffold (`./sw-dev-team-template/`, branch `main` @ `2984c68` = v1.1.1)
- Uncommitted (KEEP — this is correct): `migrations/v1.0.0-rc13.sh` (the #254
  real fix) + generated snapshots under `tests/release-gate/snapshots/` (gitignored).

---

## Remaining work: re-do the bug fixes IN THE SCAFFOLD

The fixes below were implemented, reviewed (code-reviewer + security-engineer),
and committed **to the meta-project by mistake**, then reverted. They are
vetted — **port them onto the scaffold's v1.1.1 files and re-verify**, don't
re-implement from scratch. The exact diffs live in the reverted meta-project
commits — `git show <sha>` from the meta-root.

Suggested first step: in `sw-dev-team-template/`, branch off `main` (e.g.
`fix/bug-wave-2026-06-02`), then apply each fix and commit there with the
scaffold's own `Routed-Through:` trailer discipline.

| Issue | What | Reverted-commit ref (meta) | Files (in scaffold) |
|---|---|---|---|
| **#222** | Parser fail-open on malformed `.template-conflicts.json` → marker-gated **`exit 1`** (not WARN) + atomic tmp+rename write + regression test. Keep the 3-condition gate (non-empty + `"classified": "conflict"` present + zero `prior_conflict_sha` keys) so legit all-`accepted_local` files still pass. | `a73f2aa` | `scripts/upgrade.sh` + new `tests/upgrade/test-conflicts-parser-sanity-issue-222.sh` |
| **#276** | Manifest drift: `manifest_file_sha_normalized` strips the `activity` array from `docs/handoffs/*.json` before sha256, symmetric in `manifest_write`+`manifest_verify`; one-time lock migration. Fail-closed on bad JSON. | `d13ba4a` | `scripts/lib/manifest.sh`, `TEMPLATE_MANIFEST.lock`, new `tests/upgrade/test-manifest-handoff-activity-issue-276.sh` |
| **#288** | `gate_subgate_upgrade-matrix-fresh` early pre-flight: fast-fail with actionable message when `tests/release-gate/snapshots/<VERSION>/clean/` is absent (no-op if VERSION absent/empty). Plus regen step in the release manual + tests. | `b5e6b7a` (gate), `c687d5d` (manual), `90704d5` (tests) | `scripts/lib/gate-tags.sh`, `docs/agents/manual/release-engineer-manual.md`, `tests/release-gate/test-gate-fail-each.sh`, `tests/release-gate/generator-tests/test-matrix-fresh-preflight.sh` |
| **#254** | Dead-code fix: move the marker-writing block from `migrations/v0.14.0.sh` to `migrations/v1.0.0-rc13.sh` (first migration past the v0.16.0 boundary) so it fires on v0.16.0→candidate; then remove `v0.16.0` from `tests/release-gate/upgrade-paths-allowlist.txt`. | migration fix already in scaffold (uncommitted); allowlist edit stranded in meta | `migrations/v1.0.0-rc13.sh` (done), `tests/release-gate/upgrade-paths-allowlist.txt` |

### #268 — already done
Closed as stale (`gh issue close 268`). Branch-guard was already implemented at
HEAD; `tests/upgrade/test-branch-guard.sh` passes 12/12. No work.

---

## Carry-forward follow-ups (non-blocking)
- **#276:** add `# Requires: python3` to `manifest.sh` header; consider
  `set -o pipefail`/explicit length-check before writing the normalized hash
  (R2); **architect** — `activity` array grows unbounded in a git-tracked file
  → gitignore/sidecar, and document the activity-from-hash exclusion in an ADR
  (R1).
- **#288:** the pre-flight test mutates `VERSION` in the live tree and leaves an
  empty file when none existed (cause of the `VERSION` detritus) — fix the test
  restore to remove-if-originally-absent / sandbox it. (Task #6.) Also: relative-path
  message + a comment on `revert_actions=()`.
- **Capture the "detached team operating mode"** as a planning ADR (meta-project).

---

## GitHub issues (all on `occamsshavingkit/sw-dev-team-template`)
Filed this session: **#292** (CUSTOMER_NOTES scope), **#293** (AGENTS.md
delegated-specialist), **#294**–**#303** (P1–P15 framework gaps incl. the
Gemini-review items P13–P15). All open. **#268 closed** (stale). Bug-wave
issues #222/#276/#288/#254 remain open until the scaffold commits land.

## Big-picture session output (context, all in the meta-project)
- Problem register `docs/pm/problem-register-2026-06-02-framework-gaps.md`
  (P1–P15) + findings + 5 issue drafts in `docs/pm/`.
- ADRs `docs/adr/fw-adr-0021` (harness-agnostic leaf-task dispatch) and
  `docs/adr/fw-adr-0022` (Gemini full-team harness adapter), both accepted with
  customer rulings recorded in `CUSTOMER_NOTES.md`.
- A Gemini external review of the team produced P13 (ui-ux-designer role),
  P14 (project-tailoring artifact), P15 (clarification-session cadence mode).

## Task list (TaskList) state
#1–#4 (#222/#268/#276/#288) marked completed — but #222/#276/#288 work was
reverted from the meta-project and must be **redone in the scaffold** (treat as
not-done). #5 (#254) in progress (migration fix in scaffold, allowlist pending).
#6 (#288 test VERSION-pollution) pending.
