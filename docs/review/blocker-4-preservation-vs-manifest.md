# Code-reviewer report — Blocker #4 (FW-ADR-0014: preservation vs manifest)

**Branch:** `fix/blocker-4-preservation-vs-manifest`
**Commits:** `ec96465` (ADR), `ae9e9d8` (gate + two-phase tail), `b5768cb` (migrations)
**Reviewer:** code-reviewer (IEEE 1028 § 5 technical review against ADR)
**Date:** 2026-05-15
**Net judgment:** **APPROVED-WITH-CHANGES** — 1 blocking, 5 non-blocking

---

## Scope verified

- `git diff main...b5768cb --stat`: 5 files touched (ADR, `scripts/upgrade.sh`,
  `scripts/lib/manifest.sh`, `migrations/v0.15.0.sh`, `migrations/v1.0.0-rc14.sh`).
  No framework-managed boundary files (`VERSION`, `CHANGELOG.md`,
  `scripts/scaffold.sh`, `TEMPLATE_VERSION`) touched. **Hard Rule #8 / #10
  boundary: clean.**
- `scripts/lint-routing.sh --files "ec96465 ae9e9d8 b5768cb" --summary`:
  `0 warnings, 0 errors`. Trailers (`Routed-Through: architect` for the
  ADR commit; `Routed-Through: software-engineer` for the two impl
  commits) match the lint rule table.
- ADR text against the eight `§ Implementation notes for software-engineer`
  change points: all eight addressed (see correctness walk below).

---

## Correctness walk against FW-ADR-0014 implementation notes

| # | ADR change point | Implementation site | Status |
|---|------------------|---------------------|--------|
| 1 | `should_preserve()` returns `preserve`/`drop-inert`/`refuse-conflict` | `scripts/upgrade.sh:1004-1054` | OK |
| 2 | `manifest_declares_fresh_write()` helper | `scripts/lib/manifest.sh:79-138` | OK, but see D1 below |
| 3 | `write_preservation_block_artefact()` writes `.template-preservation-blocked.json` | `scripts/upgrade.sh:1070-1106` | OK; deterministic sort, mktemp+mv atomic |
| 4 | `SWDT_PRESERVATION_FORCE=1` + audit row with `Gate=preservation` | `scripts/upgrade.sh:1417-1463` | OK; row format matches FW-ADR-0010 prior art at `:627` exactly |
| 5 | Two-phase tail (phase A literal + phase B verify) | `scripts/upgrade.sh:1728-1771` | OK, but see B-1 and D2 below |
| 6 | `migrations/v0.15.0.sh` divergence pre-check (WARN-only) | `migrations/v0.15.0.sh:35-62` | OK; no refuse, no edit |
| 7 | `migrations/v1.0.0-rc14.sh` opt-in pruning, atomic, idempotent | `migrations/v1.0.0-rc14.sh` (full file) | OK |
| 8 | Repo-wide `Done\.` audit | commit body `b5768cb` documents zero remaining consumers | OK |

---

## Blocking findings

### B-1 — FORCE path leaves a stray empty element in `preserved[]` when the array becomes empty

`scripts/upgrade.sh:1451`:
```
preserved=("${new_preserved[@]:-}")
```

Bash idiom footgun: when `new_preserved` is empty, `"${new_preserved[@]:-}"`
expands to a single empty string (NOT zero arguments), so `preserved`
becomes a one-element array containing `""`. Downstream the empty
element is consumed by:

- `:1722  if [[ ${#preserved[@]} -gt 0 ]]; then` — fires for the empty array, printing the section header.
- `:1724  for f in "${preserved[@]}"; do echo "  = $f"; done` — prints `  = ` (visible blank entry, no path).
- `:1784  for pf in "${preserved[@]:-}"; do` — iterates once with empty `pf`; harmless because the `case` arms don't match.

This is the FORCE-on-all-refusals edge case: every refused path is force-promoted to `upgraded`, and if `preserved` started with only the refused paths, the final `preserved` is the spurious one-element-empty array.

**Required change:** rebuild without the `:-}` fallback, e.g.:
```
if [[ ${#new_preserved[@]} -gt 0 ]]; then
  preserved=("${new_preserved[@]}")
else
  preserved=()
fi
```
Or use `mapfile`-style rebuild. The same pattern at `:1447` is benign (it's a read-only iteration where the guard `[[ "$q" == "$f_p" ]]` filters the empty), but the assignment at `:1451` is the contaminating write.

Customer's standing frame is "upgrade is always buggy"; this is exactly the class of bash-array footgun the frame targets. **Block** so it lands before any operator hits a FORCE run on a customer-visible artefact.

---

## Non-blocking findings

### NB-1 — D1 (`manifest_declares_fresh_write` conservatism): bounds are tight, but failure-mode worth a release-notes line

The SE-documented deviation (D1) is sound. The function returns
fresh-write=TRUE when `paths_repo_old` is empty or unreadable. The
spurious-refusal concern is **bounded by the AND-gate in
`should_preserve()`**: a path is only refused when divergence is ALSO
asserted, and divergence under a missing baseline is computed against
`paths_repo_new` (so a path matching upstream-new is `drop-inert`,
not refuse).

Residual failure mode: a project carries a genuine customisation on
a path that upstream-old shipped identically to upstream-new, AND the
baseline tree is unreachable. Without baseline, `should_preserve` flips
divergence to "diverged" (project vs new differs) AND
`manifest_declares_fresh_write` returns true (no baseline) → refuse.

Workaround: `SWDT_PRESERVATION_FORCE=1` with explicit reason. But the
operator may not realise the refusal was driven by an unreachable
baseline, not by a real fresh-write declaration. **Recommend** a single
release-notes line documenting this, and consider adding a `(baseline
unreachable)` annotation to the `refuse-conflict` ERROR text at
`scripts/upgrade.sh:1471`.

### NB-2 — D2 (verify rc=2 → exit 1): unreachable today but documentation drift risk

The SE-documented deviation (D2) is sound under the current control
flow: `manifest_verify` returns rc=2 only when the manifest file is
missing or unreadable, and at this point in the script the upgrade
has already written `TEMPLATE_MANIFEST.lock`. So `verify_rc=2`
genuinely cannot fire here.

**Observation:** the inline comment at `:1769` ("rc 2 means 'manifest
missing/unreadable' — surface as drift") is correct as documentation,
but it doesn't say *why* this is unreachable in this code path. If a
future refactor moves manifest writing or pulls the verify call
earlier, the rc=2 path becomes reachable and exit 1 silently swallows
a real defect class.

**Recommend** strengthening the comment to: `# rc 2 = manifest absent
(unreachable here because the upgrade just wrote it; defensive)`. Pure
documentation; not blocking.

### NB-3 — `should_preserve` does not stat divergence per-file when baseline available but path absent in baseline

`scripts/upgrade.sh:1024-1030`: when `b_avail=1` but `$wold/$path`
doesn't exist (path was added by upstream after the baseline), the
function falls through to the baseline-unreachable branch (`else`
arm). That's correct behaviour but the comment at `:1031` ("Baseline
unreachable for this path") conflates two semantically distinct
cases: (a) baseline tree entirely missing, (b) baseline tree present
but this specific path was not in it. The classification result is
the same, but the comment is misleading for future readers.

**Recommend** comment refinement: "Baseline unreachable OR this
path is new since baseline."

### NB-4 — `v0.15.0.sh` divergence pre-check uses `echo | sed` instead of bash trim

`migrations/v0.15.0.sh:46-48`:
```
line="${line%%#*}"
line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
```

`echo` here is fine because `line` is always a single-line preserve-list
entry, but `printf '%s' "$line"` is the safer idiom (some `echo`
implementations interpret backslash escapes). The rc14 prune migration
at `:62` already uses the safer `printf '%s' "$trimmed"` form. **Recommend**
aligning v0.15.0.sh on the same idiom. Cosmetic only.

### NB-5 — ADR's "Verification" section references a dogfood evidence file not present on the branch

`docs/adr/fw-adr-0014-preservation-vs-manifest.md` cites
`docs/pm/dogfood-2026-05-15-results.md` in the Verification section
and in Links. That file is not on `fix/blocker-4-preservation-vs-manifest`,
not on `main`, and not committed on any visible branch. Likely held
separately as the SE's local dogfood evidence.

**Observation only.** The ADR is auditable on its own merits, and the
SE's 7/7 PASS smoke summary in the customer prompt serves the same
"verification ran" purpose. **Recommend** committing the dogfood
evidence (or removing the citation) before the rc14 tag, so the
audit trail is reconstructible from git alone.

---

## Conformance statement (IEEE 730 § 5.4)

- **5.4.2 Plans for conformance** — implementation honours all three
  ADRs the change inherits from (FW-ADR-0002 customisation-wins on
  divergence; FW-ADR-0010 force env-var + audit-row + exit-2 shape;
  FW-ADR-0004 migration immutability via rc14 file). Conforming.
- **5.4.3 Product for conformance** — eight ADR change points map
  to eight implementation sites; all addressed. Two documented
  deviations (D1, D2) reviewed and bounded above. Conforming with
  one defect (B-1) requiring rework.
- **5.4.4 Product acceptability** — SE-reported 7/7 PASS dogfood
  smoke against the four customer-visible scenarios (inert healing,
  refuse-on-uncertain, FORCE override, two-phase tail clean/drift
  paths) and the rc14 migration (dry-run + apply paths). Conforming
  pending B-1.
- **5.4.5 Life-cycle support** — runbook-style ERROR text at
  `scripts/upgrade.sh:1469-1486` gives operators the diff-and-decide
  path plus the FORCE bypass syntax. Conforming.

---

## Net judgment

**APPROVED-WITH-CHANGES.**

- **1 blocker** (B-1, FORCE-path `preserved[]` rebuild).
- **5 non-blocking** observations (NB-1 release-notes; NB-2 comment
  hardening; NB-3 comment refinement; NB-4 echo→printf idiom alignment;
  NB-5 dogfood-evidence file commit).

Once B-1 lands as an SE follow-up commit, the ADR's status flip
`proposed` → `accepted` is unblocked. The status-flip commit itself
is `architect`-owned and trailered, per the same pattern used for
blocker-1 / FW-ADR-0013.

---

## Re-verify pass 2026-05-15

**Fixup commit:** `746e6ef` — "fix(upgrade): empty-array rebuild on FORCE path (CR blocker B-1)"
**Reviewer:** code-reviewer (IEEE 1028 § 5 technical review, re-verify pass)
**Scope:** B-1 resolution + no-drift check.

### B-1 — RESOLVED

- `grep -n '\[@\]:-' scripts/upgrade.sh scripts/lib/manifest.sh`: 0 live-code hits. Two remaining matches are comments at `:1446` and `:1615` that cite the unsafe idiom and the CR blocker for next-reader provenance. `scripts/lib/manifest.sh`: clean.
- SE audited the file and converted **five** sites, not just the originally-flagged one (`:1444-1463`, `:1612-1626`, `:1660-1666`, `:1804-1818`, plus the read-only iteration the original B-1 finding called out as benign at `:1453`). The five replacements all use Option A from the CR brief: `if [ "${#arr[@]}" -gt 0 ]; then ... fi` length guard with an explicit `else preserved=()` reset on the assignment site. Comments at each site cite "CR blocker B-1" for traceability.
- `upgraded[]` confirmed safe (append-only via `+=`, no rebuild).
- Dry-run smoke against a fresh scaffold: "Preserved per .template-customizations (8):" section prints 8 clean `=`-prefixed entries; no blank lines, no phantom empty rows. (FORCE-path with `preservation_refused_paths` non-empty is exercised by the dogfood-downstream harness; the code-path inspection plus the dry-run confirm the fix shape.)

### Hard Rule #8 / #10 boundary — clean

- `git show 746e6ef --stat`: `scripts/upgrade.sh` only (50 +, 25 -). No `scripts/lib/manifest.sh` change (SE audit found no matching occurrences there). No ADR mutation. No `VERSION` / `CHANGELOG.md` / `TEMPLATE_VERSION` drift. No `scripts/scaffold.sh` touch.

### Routing trailer — clean

- `scripts/lint-routing.sh --files 746e6ef --summary`: `0 warnings, 0 errors`. Commit body has `Routed-Through: software-engineer` per the lint table.

### Non-blocking findings from the original review

- NB-1 through NB-5 unchanged. None addressed by this fixup; none required for B-1 resolution. Should be filed as deferred-decision issues per the project's standing blocking/non-blocking split pattern; not in scope for this commit.

### Net judgment (revised)

**APPROVED.** No longer "with changes". B-1 resolved cleanly; no new blockers surfaced by the fixup commit; no boundary violations.

**ADR-0014 status flip is UNBLOCKED.** The architect-owned edit (`status: proposed` → `status: accepted` + `Accepted: 2026-05-15` line on `docs/adr/fw-adr-0014-preservation-vs-manifest.md`) routes back through tech-lead, who dispatches the trailered commit (`Routed-Through: architect`) — same pattern as blocker-1 / FW-ADR-0013.
