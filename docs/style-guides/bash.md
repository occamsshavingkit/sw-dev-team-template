# Bash style guide — seed

Seed file. Covers the `scripts/` directory and any Bash-dominated
tooling. Projects may extend; changes propose via
`architect` + `software-engineer` consensus and land with a row in
`docs/pm/CHANGES.md`.

## Baseline standards

- **POSIX shell** for maximum portability — preferred when the
  script is short and has no reason to be Bash-specific.
- **Google Shell Style Guide** —
  `https://google.github.io/styleguide/shellguide.html`.
- **ShellCheck** enforcement —
  `https://www.shellcheck.net/wiki/`. Every `.sh` in `scripts/`
  must pass `shellcheck -s bash -S warning` on CI.

## Required toolchain

| Tool | Role | Config |
|---|---|---|
| `shellcheck` | static check | CI-gated; `-S warning` minimum, `-S style` on new scripts |
| `shfmt` | formatter | `shfmt -i 2 -ci -bn` recommended |
| `bats` | test runner | for scripts with non-trivial logic |

## Required script header

```
#!/usr/bin/env bash
#
# scripts/<name>.sh — <one-line purpose>.
# <2–4 line longer description; cite issues / CHANGELOG if relevant.>
#
# Usage:
#   scripts/<name>.sh [args…]
#
# Exit codes:
#   0 — success
#   1 — <specific failure>
#   2 — usage error

set -euo pipefail
```

- `set -euo pipefail` is mandatory.
- Quote every variable expansion: `"$var"` not `$var`, unless
  intentional word-splitting with shellcheck disable + comment.
- Use `[[ … ]]` tests, not `[ … ]`.
- Prefer `$(cmd)` over backticks.

## Style points

- **Functions** start with underscore for private
  (`_helper_fn`), no underscore for public; always local-scope
  variables with `local`.
- **Array handling:** `"${arr[@]}"` for element expansion;
  `"${#arr[@]}"` for count; never unquoted array expansion.
- **Long pipelines:** break at `|` with the operator at the
  start of the next line for readability.
- **Temp files:** `mktemp` + `trap 'rm -rf "$tmp"' EXIT`; never
  hardcoded `/tmp/foo.$$`.

## Anti-patterns

- `eval` (require ADR + justification).
- Parsing `ls` output (use globs or `find -print0 | xargs -0`).
- Hidden side-effects in functions (functions should return
  status, not mutate globals that cross call boundaries).
- Silent `|| true` after a substantive command without a comment
  explaining why failure is OK.

## References

- Google Shell Style Guide
  https://google.github.io/styleguide/shellguide.html
- ShellCheck wiki https://www.shellcheck.net/wiki/
- `man bash(1)`, `man sh(1)`.
- "Bash Pitfalls" (Greg Wooledge, Tier-2)
  https://mywiki.wooledge.org/BashPitfalls
