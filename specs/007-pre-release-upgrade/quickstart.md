# Quickstart: Pre-release upgrade-regression gate

**Feature**: `007-pre-release-upgrade`
**Spec**: [spec.md](spec.md) · **Plan**: [plan.md](plan.md)

## For the template maintainer (release-engineer hat)

### Before tagging a release candidate

```sh
cd ./sw-dev-team-template
scripts/pre-release-gate.sh
```

Outcome:

- Exit 0 + stderr summary `PASS` → tag is safe to cut.
- Exit non-zero + stderr summary `FAIL — M/N green, K failed` → fix the named sub-gates, re-run.

Wall-clock budget: under 5 minutes on a typical Linux workstation with the prior-tag set pre-fetched.

### Iterating on one sub-gate

```sh
scripts/pre-release-gate.sh --only upgrade-paths
scripts/pre-release-gate.sh --skip migrations-standalone
```

`--only` runs the named sub-gate alone. `--skip` runs every sub-gate except the named one(s); pass `--skip` multiple times to exclude more than one.

**Note**: `--only` and `--skip` are IGNORED when the gate is invoked from the pre-push hook in strict mode (push of an annotated `v*` tag). Strict mode always runs every sub-gate.

### Installing the pre-push hook

Opt-in. Two options:

```sh
git config core.hooksPath .git-hooks
```

or:

```sh
ln -sf "$(pwd)/.git-hooks/pre-push" .git/hooks/pre-push
chmod +x .git/hooks/pre-push
```

After installation, every `git push` of an annotated `v*` tag triggers strict mode. Branches and non-tag pushes get advisory-mode WARN only.

### Bypass (when you must)

```sh
SKIP_PRE_RELEASE_GATE=1 git push origin v1.0.0-rc11
PRE_RELEASE_GATE_REASON="hot-fix; cross-MAJOR upgrade gap is preexisting" \
SKIP_PRE_RELEASE_GATE=1 \
  git push origin v1.0.0-rc11
```

Both bypass invocations append a row to `docs/pm/pre-release-gate-overrides.md`. Setting `PRE_RELEASE_GATE_REASON` is strongly encouraged; the audit row uses `unspecified` otherwise.

The bypass is REFUSED if the audit log is unwritable. Recovery: fix the log path / permissions, or commit and re-push.

### Reading the audit log

```sh
cat docs/pm/pre-release-gate-overrides.md
```

The file is an append-only Markdown table. To audit overrides for the last 30 days:

```sh
git log --since='30 days ago' -p docs/pm/pre-release-gate-overrides.md
```

Tamper-evidence is git history itself; any retroactive edit of an existing row surfaces in `git log -p`.

---

## For agents / specialists

### `release-engineer`

Owns the gate script, sub-gate registry, the pre-push hook, and the rc-tag checklist integration. Before tagging an rc:

1. Confirm gate run is green at HEAD.
2. If overridden, confirm the audit row is in `docs/pm/pre-release-gate-overrides.md` with a non-`unspecified` reason.
3. Tag and push per the existing rc-tag procedure.

### `qa-engineer`

Owns the positive + negative fixtures under `tests/release-gate/fixtures/`. When a new sub-gate is added:

1. Add positive fixture `0N-clean-tree-<sub-gate>/` matching the sub-gate's input shape.
2. Add negative fixture `0N-<sub-gate-broken>/` with a deliberate break.
3. Run `tests/release-gate/test-gate-fail-each.sh` to confirm the negative fixture surfaces the sub-gate in the failing list.

### `code-reviewer`

Reviews every gate-script change AND owns the advisory-pointer scanner rules. When a new operator-facing path pattern enters `scripts/upgrade.sh` or a migration, confirm the scanner's regex covers it.

### `tech-writer`

Owns:
- `docs/v1.0.0-final-checklist.md` reference to the gate as a numbered precondition.
- The README / user-facing docs that point operators at this quickstart.

---

## Failure-mode quick reference

| Symptom | Likely sub-gate | Recovery |
|---|---|---|
| `worktree-clean: FAIL` | `worktree-clean` | `git status`; commit / stash / discard uncommitted changes. |
| `upgrade-paths: FAIL ... v0.10.0 ...` | `upgrade-paths` | Cross-MAJOR upgrade is broken; either fix `scripts/upgrade.sh` to support the path or file as a known gap and override with audited reason. |
| `lint-contracts: FAIL` | `lint-contracts` | Run `scripts/lint-agent-contracts.sh --canonical-only` for the per-file detail; backfill missing sections. |
| `check-spdx: FAIL` | `check-spdx` | Add `SPDX-License-Identifier: MIT` + copyright lines to the named scripts. |
| `advisory-pointers: FAIL ... migrations/v1.0.0-rcN.sh ...` | `advisory-pointers` | Either create the named file or fix the advisory string to name a path that exists. |
| `migrations-standalone: FAIL ... placeholder ...` | `migrations-standalone` | The migration ran with mis-set `WORKDIR_NEW` or has a placeholder logic bug; re-run with valid env or fix the migration. |
| `readme-current: README.md neither mentions VERSION nor was modified since last v* tag` | `readme-current` | Update `README.md` to mention the candidate `VERSION` or modify it since the last `v*` tag. |

---

## Integration with existing tooling

| Existing | Used by | Purpose |
|---|---|---|
| `scripts/smoke-test.sh` | `upgrade-paths` sub-gate | Per-source-tag round-trip primitive (FR-003). |
| `scripts/lint-agent-contracts.sh` | `lint-contracts` sub-gate | Canonical-only schema check (FR-004). |
| `scripts/check-spdx.sh` | `check-spdx` sub-gate | SPDX header enforcement (FR-005). |
| `scripts/upgrade.sh` | `advisory-pointers` sub-gate | Scanned for dangling path references (FR-006). |
| `migrations/*.sh` | `migrations-standalone` sub-gate | Standalone run + placeholder scan (FR-007). |

The gate adds composition + audit + hook adapter; the underlying checks are existing canonical tooling.

---

## What the gate does NOT do

- Run on every commit. It's a release-readiness check, not a per-commit lint.
- Block non-`v*` tag pushes. Branch pushes get advisory mode only.
- Mirror to CI. The CI workflows already run a subset (template-contract-smoke, agent-contract, question-lint); the local gate is the maintainer's pre-tag check.
- Emit JSON output. Deferred per spec Assumptions until a CI consumer needs it.
- Fix anything automatically. The gate is read-only; recovery is the operator's job.
