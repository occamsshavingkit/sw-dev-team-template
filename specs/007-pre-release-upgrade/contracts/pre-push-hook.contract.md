# Contract: `.git-hooks/pre-push` adapter

**Owner**: `release-engineer`
**Status**: design
**Spec**: [../spec.md](../spec.md) — FR-011; clarification Q3 (scoped-strict).

## Purpose

Adapt the pre-release gate to the git pre-push hook protocol with **scoped-strict** semantics: block pushes that include an annotated `v*` tag until the gate runs to PASS at HEAD; advisory (WARN-only) on every other push.

## Installation

Shipped under `.git-hooks/pre-push` in the template. Operator installs by either:

```sh
git config core.hooksPath .git-hooks
```

…or by symlinking `.git-hooks/pre-push` into `.git/hooks/pre-push`. The template's `scripts/scaffold.sh` MAY surface a hint after scaffolding but MUST NOT auto-install.

## Protocol

Git invokes the hook with arguments `<remote_name> <remote_url>` and a series of refspec lines on stdin:

```text
<local_ref> <local_sha> <remote_ref> <remote_sha>
```

The hook reads stdin line by line and classifies each refspec.

## Strict-mode trigger

Strict mode activates iff:
1. Any refspec's `remote_ref` matches the glob `refs/tags/v[0-9]*`, AND
2. The local object at `<local_sha>` is an annotated tag (`git cat-file -t <local_sha> == "tag"`).

If either condition fails for every refspec, the hook is in advisory mode.

## Strict-mode behaviour

1. Invoke `scripts/pre-release-gate.sh` (no flags — `--only` / `--skip` are ignored in strict mode per R-2).
2. If the gate exits 0, the hook exits 0 (push proceeds).
3. If the gate exits non-zero:
   - If `SKIP_PRE_RELEASE_GATE=1` is set in the environment, append an override-audit row to `docs/pm/pre-release-gate-overrides.md` (R-11), print the appended row to stderr, then exit 0 (push proceeds).
   - If `SKIP_PRE_RELEASE_GATE` is unset, exit non-zero with a stderr message: `pre-release-gate failed; push blocked. Override with SKIP_PRE_RELEASE_GATE=1 git push ... (audit-logged).`
4. If the audit log file is unwritable (R-11), the hook MUST refuse to bypass — exit non-zero with the original gate-failure message AND a note about the unwritable log path.

## Advisory-mode behaviour

1. If a recent `scripts/pre-release-gate.sh` run is known-passing at HEAD (cached `$GATE_TEMP_ROOT/last-pass.sha` matches HEAD), the hook exits 0 silently.
2. Otherwise, the hook emits a stderr WARN: `pre-release-gate not run against HEAD; push proceeding (advisory mode).`
3. The hook exits 0 unconditionally (advisory).

## Override audit row (data-model.md E-7)

Appended to `docs/pm/pre-release-gate-overrides.md` BEFORE the hook returns 0 in bypass mode. Schema v2 per FW-ADR-0010 (customer-ruled 2026-05-14) adds a `Gate` column at position 2; the pre-push hook always writes `pre-release` there (the `pre-bootstrap` value is reserved for `scripts/upgrade.sh` / `migrations/v0.14.0.sh` bypass rows under `SWDT_PREBOOTSTRAP_FORCE=1`). Format:

```text
| 2026-05-14 | pre-release | abc1234 | v1.0.0-rc11 | user@host | hot-fix tag; gate red on cross-MAJOR | upgrade-paths,advisory-pointers |
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Push allowed (either gate passed, or bypassed via `SKIP_PRE_RELEASE_GATE=1` with audit row, or advisory mode). |
| non-zero | Strict mode + gate failed + no valid bypass. |

## Invariants

1. The hook NEVER blocks a push that does not include an annotated `v*` tag.
2. The hook ALWAYS appends an audit row before returning 0 in bypass mode; if appending fails, the hook returns non-zero.
3. The hook NEVER reads or writes the worktree outside of `docs/pm/pre-release-gate-overrides.md`.
4. The hook NEVER prompts (no interactive input; this is a git protocol surface).

## Operator UX

Operator typing `git push origin main` on a feature branch sees nothing (advisory mode, no recent gate run → stderr WARN only).

Operator typing `git push origin v1.0.0-rc11` triggers strict mode. If the gate passes, the push proceeds silently. If not:

```text
pre-release-gate: FAIL — 4/6 sub-gates green, 2 failed, total 134s
  failing sub-gates: upgrade-paths, advisory-pointers
pre-release-gate failed; push blocked.
Override with SKIP_PRE_RELEASE_GATE=1 git push ... (audit-logged).
```

Operator escalating with `SKIP_PRE_RELEASE_GATE=1 git push origin v1.0.0-rc11`:

```text
pre-release-gate: FAIL — 4/6 sub-gates green, 2 failed, total 134s
  failing sub-gates: upgrade-paths, advisory-pointers
override appended to docs/pm/pre-release-gate-overrides.md:
  | 2026-05-14 | pre-release | <sha> | v1.0.0-rc11 | abe@kab | unspecified | upgrade-paths,advisory-pointers,worktree-clean,lint-contracts,check-spdx,migrations-standalone |
```

## Negative behaviours (forbidden)

- The hook MUST NOT silently rewrite the override-audit log.
- The hook MUST NOT install itself; operators install explicitly via `core.hooksPath` or symlink.
- The hook MUST NOT depend on `bash` features beyond what `/usr/bin/env sh` provides — `git` hooks are POSIX-sh by convention.

## Test coverage

- Positive (strict, gate pass): `tests/release-gate/test-hook-strict-pass.sh` — feed a `refs/tags/v*` refspec on stdin with an annotated tag SHA; gate's mock returns 0; hook exits 0.
- Negative (strict, gate fail, no bypass): hook exits non-zero with the documented stderr.
- Negative (strict, gate fail, bypass): hook exits 0; one row appended to `docs/pm/pre-release-gate-overrides.md`.
- Advisory: feed a `refs/heads/main` refspec; hook exits 0 with WARN.
- Bypass + unwritable log: chmod 0500 the log; hook exits non-zero with the documented error.
- Lightweight tag (not annotated): hook treats as advisory (per R-10).
