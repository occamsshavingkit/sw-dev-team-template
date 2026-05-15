# Dogfood results — 2026-05-15

Target: v1.0.0-rc12 (tag resolves to `cac0ab03e3612cf01d0e9c079b0e6e4c325e366a`)
Codenames: alpha, beta, gamma — 3 states each (scaffold / mid / latest) = 9 runs
Runner: `tests/release-gate/dogfood-downstream.sh`
Fixture-capture rule reminder: codenames-only; no customer / site / vendor names in evidence files.

## Summary

| codename       | state    | before        | after         | upgrade | verify | conflicts | ai-tui              | RESULT |
|----------------|----------|---------------|---------------|---------|--------|-----------|---------------------|--------|
| alpha          | scaffold | v1.0.0-rc2    | v1.0.0-rc2    | 2       | 2      | 0         | skipped-script-fail | FAIL   |
| alpha          | mid      | (no report)   | (no report)   | -       | -      | -         | -                   | FAIL   |
| alpha          | latest   | (no report)   | (no report)   | -       | -      | -         | -                   | FAIL   |
| beta           | scaffold | v0.13.0       | v1.0.0-rc12   | 1       | 1      | 0         | skipped-script-fail | FAIL   |
| beta           | mid      | v1.0.0-rc3    | v1.0.0-rc12   | 0       | 1      | 7         | skipped-script-fail | FAIL   |
| beta           | latest   | v1.0.0-rc8    | v1.0.0-rc12   | 0       | 1      | 8         | skipped-script-fail | FAIL   |
| gamma          | scaffold | v1.0.0-rc7    | v1.0.0-rc12   | 0       | 0      | 0         | fail (5/21)         | FAIL   |
| gamma          | mid      | v1.0.0-rc8    | v1.0.0-rc12   | 0       | 1      | 2         | skipped-script-fail | FAIL   |
| gamma          | latest   | v1.0.0-rc8    | v1.0.0-rc12   | 0       | 1      | 15        | skipped-script-fail | FAIL   |

Totals: **0 PASS / 9 FAIL.**

Report files (kept under `/tmp`; codenames-only; safe to share):

- `/tmp/dogfood-alpha-scaffold-20260515T112229Z.txt`
- `/tmp/dogfood-beta-scaffold-20260515T112302Z.txt`
- `/tmp/dogfood-beta-mid-20260515T112320Z.txt`
- `/tmp/dogfood-beta-latest-20260515T112337Z.txt`
- `/tmp/dogfood-gamma-scaffold-20260515T112354Z.txt`
- `/tmp/dogfood-gamma-mid-20260515T112416Z.txt`
- `/tmp/dogfood-gamma-latest-20260515T112432Z.txt`

alpha/mid and alpha/latest: no report files written — driver aborted
in `cp -aL` preflight before reaching the report-writer. See alpha/mid
+ alpha/latest entry under Failures.

## Failures (per fixture)

### alpha/scaffold (v1.0.0-rc2 → v1.0.0-rc12) — FAIL

`upgrade exit=2; verify exit=2`. After-version did not advance: still
`v1.0.0-rc2`. Migrations table only enumerated `[v1.0.0-rc9]` (0 files
backfilled), then crashed.

Excerpt (`upgrade.sh stdout/stderr`):

```
Running migrations between v1.0.0-rc2 and v1.0.0-rc12:
  [v1.0.0-rc9]
    migrations/v1.0.0-rc9.sh: 0 files backfilled, 0 files already current.

./scripts/upgrade.sh: line 205: syntax error near unexpected token `;;'
```

Excerpt (`upgrade.sh --verify stdout/stderr`):

```
ERROR: manifest not found at /tmp/dogfood-driver.PUZWsA/tree/TEMPLATE_MANIFEST.lock
  Run 'scripts/upgrade.sh' to (re)generate it. Pre-v0.14.0
  projects without a manifest can also run scripts/upgrade.sh
  — the v0.14.0 migration synthesises an initial manifest.
```

Root cause: rc2 ships an old `scripts/upgrade.sh` that lacks the cross-MAJOR
pre-bootstrap from v0.14.0 / FW-ADR-0010. The local rc2 upgrade.sh runs
the v1.0.0-rc9 migration and then dies on a syntax error — almost certainly
the rc12 candidate-script being copied over the running rc2 script
mid-execution (classic self-overwrite). No v0.14.0 manifest synthesis →
`--verify` then dies with "manifest not found." Real downstream RC-to-RC
upgrade is wedged.

Suggested upstream issue (Blocker #1): `migrations/v1.0.0-rc13.sh` to
pre-bootstrap `scripts/upgrade.sh` whenever the running version is an
rc on the v1.0.0 line and the candidate is a newer rc (analogue of the
v0.14.0 cross-MAJOR pre-bootstrap, extended to RC→RC). Severity:
**blocker** — every rc2/rc3/rc4 downstream that tries to advance is
trapped.

### alpha/mid and alpha/latest — FAIL (no report files)

Driver aborted in `cp -aL` preflight; root cause confirmed by
blocker #2 work — fixture has absolute-target overlay-rootfs symlinks
(`image/overlay/rootfs/etc/runlevels/default/quackplc-soak` →
`/etc/init.d/quackplc-soak`); driver's `cp -aL` followed link to host
path that doesn't exist. Fixed in commit `c5bd106` on branch
`fix/blocker-2-dogfood-driver-symlinks` (`cp -aL` → `cp -a` + narrow
stub-only dereference).

Suggested upstream issue (Blocker #2): driver must not blindly
deref-and-copy fixture symlinks; the dogfood harness can never tell
which fixtures have valid host targets. Replace with `cp -a` (preserve
link structure) and only dereference the upgrade-stub link that the
driver itself needs to invoke. **Resolved on the branch named above
prior to this re-write.**

### beta/scaffold (v0.13.0 → v1.0.0-rc12) — FAIL

`upgrade exit=1; verify exit=1; conflicts=0`. Migrations chain ran end
to end (v0.14.0 / v0.14.4 / v0.15.0 / v1.0.0-rc9), TEMPLATE_VERSION
advanced, but `--verify` reported three manifest discrepancies:

```
drift:    docs/INDEX.md
  expected f2acfd632697f898393e950ce7ef58e2490b2382508f4d7dd8479b2320cb7f83
  actual   b966de0d04983aa23d29384fe801455b64b1d6fb22417e48e43789be88a6e5e3
drift:    .gitignore
  expected a3cb15364a614379d170bde87eb8cca8e9afe73b446fa9a3c461f59b52518c88
  actual   fbed1b6275d5ed736e444e74e64caae81d9d8abfb8c9679baa5cae6730a3d8dd
missing:  docs/INDEX-PROJECT.md  (in manifest but not in project)
```

Root cause: post-migration manifest mismatch. The v0.15.0 migration
appends `docs/INDEX.md`, `docs/INDEX-PROJECT.md`, and (via v0.14.4)
`.gitignore` to `.template-customizations` so they are preserved
from the project tree, **but** the synthesised manifest baked at
v0.14.0 expects upstream hashes for those same paths. The two
codepaths disagree about whether these files are preserved or
managed. After migration finishes, `--verify` walks the manifest and
flags them — the upgrade itself succeeded, the gate then fails.

Suggested upstream issue (Blocker #4): preservation-vs-manifest
contract violation. Either the migration must rewrite manifest
entries for newly-preserved paths (preferred), or `--verify` must
honor `.template-customizations` and exempt preserved paths.
**Resolved on `fix/blocker-4-preservation-vs-manifest` via
FW-ADR-0014 (preservation-vs-manifest gate + two-phase exit).**

### beta/mid (v1.0.0-rc3 → v1.0.0-rc12) — FAIL

`upgrade exit=0; verify exit=1; conflicts=7`. 7 conflicts on agent
contracts + `docs/DECISIONS.md`:

```
! .claude/agents/code-reviewer.md      upstream +29/-5  local +19/-1
! .claude/agents/onboarding-auditor.md upstream +40/-1  local +13/-1
! .claude/agents/process-auditor.md    upstream +43/-1  local +28/-1
! .claude/agents/project-manager.md    upstream +54/-1  local +16/-1
! .claude/agents/qa-engineer.md        upstream +24/-91 local +13/-1
! .claude/agents/sre.md                upstream +34     local +28/-1
! docs/DECISIONS.md                    upstream +66     local +7
```

Root cause: real concurrent-edit conflicts. Both the rc3 → rc12
trajectory on upstream and the customized local fixture have
touched the same agent contracts and decisions ledger. This is the
**expected** category — the conflict detector did its job and the
real downstream maintainer must merge.

Severity: **expected**, not a blocker. AI-TUI was correctly skipped
because verify failed; the operator path here is "resolve the seven
conflicts, run `scripts/upgrade.sh --resolve`, re-verify, then the
AI-TUI check runs." No upstream fix required.

### beta/latest (v1.0.0-rc8 → v1.0.0-rc12) — FAIL

`upgrade exit=0; verify exit=1; conflicts=8`. Same shape as beta/mid
plus `AGENTS.md` and `CLAUDE.md`:

```
! .claude/agents/code-reviewer.md      upstream +12/-8  local +19/-1
! .claude/agents/onboarding-auditor.md upstream +20/-1  local +13/-1
! .claude/agents/process-auditor.md    upstream +33     local +28/-1
! .claude/agents/project-manager.md    upstream +37/-1  local +16/-1
! .claude/agents/qa-engineer.md        upstream +15/-91 local +13/-1
! .claude/agents/sre.md                upstream +26     local +28/-1
! AGENTS.md                            upstream +40/-23 local +13/-12
! CLAUDE.md                            upstream +58/-17 local +2/-2
```

Note `docs/INDEX-FRAMEWORK.md`, `docs/versioning.md`, `scripts/scaffold.sh`,
`scripts/version-check.sh` show up under "Accepted local merges
(recorded in manifest)" — the three-way merge worked on those four.
The eight above are genuine three-way conflicts.

Root cause: same as beta/mid (real concurrent edits); rc8 → rc12 adds
two top-level files (`AGENTS.md`, `CLAUDE.md`) to the conflict set
because the local fixture customizes both. Severity: **expected**;
no upstream fix.

### gamma/scaffold (v1.0.0-rc7 → v1.0.0-rc12) — FAIL

`upgrade exit=0; verify exit=0; conflicts=0; ai-tui=FAIL`. Only run
that reached the AI-TUI check. The migrations + verify chain ran
clean (`OK: 211 files verified clean against manifest`). AI-TUI
regressed 5/21 cases:

```
ai-tui-check: 16 pass, 5 fail
  FAIL cat6.1: python3 -c json.load(open('CUSTOMER_NOTES.md'))     (expected pass, got ask)
  FAIL cat6.2: python3 heredoc reading CUSTOMER_NOTES.md           (expected pass, got ask)
  FAIL cat6.3: sh -c cat CUSTOMER_NOTES.md | head                  (expected pass, got ask)
  FAIL cat7.2: inline SWDT_AGENT_PUSH=software-engineer Bash write (expected pass, got deny)
  FAIL cat7.3: leading export SWDT_AGENT_PUSH then write           (expected pass, got deny)
```

All 5 failures correspond to upstream issues **#178** (`customer-notes-guard.py`
must permit read-only `open()` / `cat` / heredoc Python access) and
**#182** (`tech-lead-authoring-guard.py` must accept inline / leading-`export`
`SWDT_AGENT_PUSH` carrier on Bash redirects). The fixes are on `main` but
were not picked up in the rc12 stabilization branch.

Suggested upstream issue (Blocker #3): rc12 tag was cut from a
stabilization branch that did not include #178 (SHA `d003d28`) or
#182 (SHA `7d51cae`). Either re-cut rc12 from a base that includes
both, or rc12 is dead and the next tag (rc13 / final) must include
them. **Resolved**: folded into the new rc cut after dogfood-vs-main
passes (rc12 was mis-stabilized; #178 SHA `d003d28` + #182 SHA
`7d51cae` are on main, just not in the rc12 tag).

### gamma/mid (v1.0.0-rc8 → v1.0.0-rc12) — FAIL

`upgrade exit=0; verify exit=1; conflicts=2`. Two real conflicts:

```
! .claude/settings.json  upstream +57/-4   local +10
! AGENTS.md              upstream +40/-23  local +4/-4
```

Root cause: expected concurrent-edit conflicts on the two top-level
hook / harness-adapter files that received the biggest rc8 → rc12
churn. The customized `.claude/settings.json` carries hook rows from
both the local agent overlay and the upstream's new hook policy.
Severity: **expected**; no upstream fix.

### gamma/latest (v1.0.0-rc8 → v1.0.0-rc12) — FAIL

`upgrade exit=0; verify exit=1; conflicts=15`. The widest conflict
fan-out of any run:

```
! .claude/agents/onboarding-auditor.md   upstream +20/-1   local +13/-1
! .claude/agents/project-manager.md      upstream +37/-1   local +16/-1
! .claude/agents/tech-lead.md            upstream +99/-231 local +4/-4
! .claude/settings.json                  upstream +57/-4   local +10
! AGENTS.md                              upstream +40/-23  local +36/-27
! CLAUDE.md                              upstream +58/-17  local +68/-57
! docs/templates/adr-template.md         upstream +16/-16  local +13/-13
! docs/templates/proposal-template.md    upstream +2/-2    local +1/-1
! docs/templates/task-template.md        upstream +29/-3   local +1/-1
! scripts/agent-health.sh                upstream +2/-1    local +1/-1
! scripts/hooks/customer-notes-guard.py  upstream +101/-56 local +81/-70
! scripts/repair-in-place.sh             upstream +2/-6    local +10/-16
! scripts/scaffold.sh                    upstream +52/-7   local +31/-37
! scripts/stepwise-smoke.sh              upstream +2/-1    local +1/-1
! scripts/version-check.sh               upstream +23/-33  local +46/-30
```

Root cause: this fixture is the most heavily customized of the three
gamma states; it has touched nearly every framework-managed file the
rc8 → rc12 trajectory also moved. Severity: **expected** but
high-friction — anyone in this state will need a substantial merge
session. No upstream fix; possibly an upstream **doc** issue to call
out "heavily-customized RC downstreams should expect 10+ conflicts on
rc8 → rc12; budget accordingly."

## Conclusion

Is the framework ready for meta-bump? **No.**

Blocking issues, severity-ranked:

1. **Blocker #1 — alpha/scaffold rc2 → rc12 self-overwrite.** Every
   rc2/rc3/rc4 downstream that tries to advance hits the same syntax
   error around `upgrade.sh:205` from running an old upgrade script
   mid-replacement. Fix: new `migrations/v1.0.0-rc13.sh` that
   pre-bootstraps `scripts/upgrade.sh` on RC→RC moves on the v1.0.0
   line, analogue of the v0.14.0 cross-MAJOR pre-bootstrap.
2. **Blocker #2 — driver `cp -aL` crash on absolute-target overlay
   symlinks.** Both alpha/mid and alpha/latest aborted before
   reaching the report-writer because the fixtures contain
   absolute-target overlay-rootfs symlinks pointing at host paths
   that don't exist in the dogfood sandbox. Fix: dogfood driver
   replaces `cp -aL` with `cp -a` (preserve link structure) and
   only dereferences the narrow stub-script path the driver itself
   needs to invoke.
3. **Blocker #3 — rc12 missing #178 + #182.** AI-TUI regression
   confirmed 5/21 fails on gamma/scaffold (the only run that
   reached the AI-TUI check). Fixes are on `main` but not in the
   rc12 tag. Re-cut required before the meta pointer moves.
4. **Blocker #4 — preservation-vs-manifest drift on beta/scaffold.**
   The v0.14.0 migration's manifest synthesis and the v0.14.4 /
   v0.15.0 `.template-customizations` extensions disagree about
   whether `docs/INDEX.md`, `docs/INDEX-PROJECT.md`, and
   `.gitignore` are managed or preserved. The migration finishes
   green; `--verify` then reports drift on the same paths. Fix:
   either rewrite manifest entries for newly-preserved paths during
   migration, or teach `--verify` to honor `.template-customizations`.

Conflict-shaped fails (beta/mid, beta/latest, gamma/mid, gamma/latest)
are **expected** outcomes of real concurrent customer + upstream
edits to agent contracts and harness files. They are not blockers —
they are exactly the merge-friction the conflict detector exists to
surface. They do, however, mean the meta-bump cannot be done by a
fast-forward; whoever does the meta-pointer move must do real
merging.

Recommended path forward (in order):

1. Land Blockers #1–#4 fixes on main (in progress; see below).
2. Re-cut a new rc (rc13 or rc14, per release-engineer call) from
   main once those four blockers are merged.
3. Re-run dogfood against the new rc with `--target <new-rc>`.
4. Only after a 9/9 PASS run, move the meta-project submodule
   pointer.
5. For real downstream operators on rc3 / rc8 trajectories: budget
   merge time for 2–15 conflicts depending on customization depth.
   These are expected; no upstream fix planned.

### Update 2026-05-15 (post-blocker work)

- **Blocker #1** (alpha/scaffold rc2 → rc12 self-overwrite):
  RESOLVED on `fix/blocker-1-rc-to-rc-prebootstrap` via new
  `migrations/v1.0.0-rc13.sh` (FW-ADR-0013).
- **Blocker #2** (driver `cp -aL` crash on absolute-target overlay
  symlinks): RESOLVED on `fix/blocker-2-dogfood-driver-symlinks` via
  `cp -a` + narrow stub-only `readlink -f` (commit `c5bd106`).
- **Blocker #3** (#178 / #182 missing from rc12): RESOLVED as folded
  into the new rc cut after dogfood-vs-main passes (rc12 was
  mis-stabilized; #178 SHA `d003d28` + #182 SHA `7d51cae` are on
  main, just not in the rc12 tag).
- **Blocker #4** (preservation-vs-manifest manifest drift):
  RESOLVED on `fix/blocker-4-preservation-vs-manifest` via
  FW-ADR-0014 (preservation-vs-manifest gate + two-phase exit).
- **Re-dogfood scheduled**: blockers will merge to main, then
  dogfood will run against main via `--target main` per customer's
  dogfood-before-rc sequencing ruling.

Routed-Through: qa-engineer
