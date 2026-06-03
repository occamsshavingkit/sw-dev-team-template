#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/test-worktree-helpers.sh — unit tests for the worktree helper scripts
#   (fw-adr-0024 §3 / §6)
#
# Tests:
#   T1.  worktree-setup.sh prints a /tmp/agent-* path and git worktree list
#        shows the new entry.
#   T2.  worktree-teardown.sh removes the worktree and directory.
#   T3.  worktree-teardown.sh is idempotent: exits 0 when worktree already gone.
#   T4.  worktree-teardown.sh refuses a non-/tmp/agent-* path.
#   T5.  worktree-health-check.sh exits 0 and outputs no WARN when no stale
#        worktrees exist.
#   T6.  worktree-health-check.sh warns (on stderr) when a /tmp/agent-* worktree
#        entry is present in git worktree list.
#   T7.  worktree-setup.sh exits nonzero on a non-git-repo argument.
#   T8.  worktree-teardown.sh exits nonzero on a non-git-repo scaffold argument.
#
# HERMETICITY: this test file is itself hermetic (fw-adr-0024 §4):
#   - All git operations use a throwaway repo in $TMPDIR.
#   - No git reset / clean / stash / switch / checkout / commit / merge / rebase
#     on the live scaffold.
#   - Temporary directories are cleaned up in the EXIT trap.
#   - The scaffold's HEAD is never touched.
#
# Honors PROJECT_ROOT env var as a no-op override (tests create their own
# fixture repo and do NOT operate on the live scaffold checkout).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SETUP="$REPO_ROOT/scripts/worktree-setup.sh"
TEARDOWN="$REPO_ROOT/scripts/worktree-teardown.sh"
HEALTHCHECK="$REPO_ROOT/scripts/worktree-health-check.sh"

pass=0
fail=0
failures=()

# ---------------------------------------------------------------------------
# Reporting helpers
# ---------------------------------------------------------------------------
_pass() { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
_fail() {
  fail=$((fail + 1))
  failures+=("$1: $2")
  printf 'FAIL  %s\n      %s\n' "$1" "$2"
}

# ---------------------------------------------------------------------------
# Fixture: throwaway git repo in a temp directory
# ---------------------------------------------------------------------------
FIXTURE_ROOT="$(mktemp -d)"
FIXTURE_REPO="$FIXTURE_ROOT/scaffold"
# shellcheck disable=SC2154  # w is the for-loop variable inside the trap string; shellcheck can't see it
trap 'rm -rf "$FIXTURE_ROOT"; for w in /tmp/agent-*; do [ -d "$w" ] && git -C "$FIXTURE_REPO" worktree remove "$w" --force 2>/dev/null || true; done' EXIT INT TERM

# Initialise a minimal git repo with one commit so HEAD is valid.
git init -q -b main "$FIXTURE_REPO"
git -C "$FIXTURE_REPO" config user.email "test@test.invalid"
git -C "$FIXTURE_REPO" config user.name "Test"
touch "$FIXTURE_REPO/README.md"
git -C "$FIXTURE_REPO" add README.md
git -C "$FIXTURE_REPO" commit -q -m "init"

# ---------------------------------------------------------------------------
# T1: worktree-setup.sh prints a /tmp/agent-* path; git worktree list shows it
# ---------------------------------------------------------------------------
wt_path=""
if wt_path="$("$SETUP" "$FIXTURE_REPO" 2>/dev/null)"; then
  if [[ "$wt_path" =~ ^/tmp/agent-[^/]+$ ]] && [[ -d "$wt_path" ]]; then
    if git -C "$FIXTURE_REPO" worktree list --porcelain 2>/dev/null | grep -qF "$wt_path"; then
      _pass "T1: worktree-setup.sh prints /tmp/agent-* path and git worktree list shows it"
    else
      _fail "T1" "worktree path $wt_path not in git worktree list"
    fi
  else
    _fail "T1" "output '$wt_path' is not a /tmp/agent-* directory"
  fi
else
  _fail "T1" "worktree-setup.sh exited nonzero"
fi

# ---------------------------------------------------------------------------
# T2: worktree-teardown.sh removes the worktree and directory
# ---------------------------------------------------------------------------
if [[ -n "$wt_path" ]]; then
  if "$TEARDOWN" "$wt_path" "$FIXTURE_REPO" 2>/dev/null; then
    if [[ ! -d "$wt_path" ]]; then
      if ! git -C "$FIXTURE_REPO" worktree list --porcelain 2>/dev/null | grep -qF "$wt_path"; then
        _pass "T2: worktree-teardown.sh removes directory and git worktree entry"
      else
        _fail "T2" "worktree still in git worktree list after teardown"
      fi
    else
      _fail "T2" "directory $wt_path still exists after teardown"
    fi
  else
    _fail "T2" "worktree-teardown.sh exited nonzero"
  fi
else
  _fail "T2" "skipped (T1 did not produce a worktree path)"
fi

# ---------------------------------------------------------------------------
# T3: worktree-teardown.sh is idempotent — exits 0 when worktree already gone
# ---------------------------------------------------------------------------
if [[ -n "$wt_path" ]]; then
  if "$TEARDOWN" "$wt_path" "$FIXTURE_REPO" 2>/dev/null; then
    _pass "T3: worktree-teardown.sh exits 0 when worktree already absent (idempotent)"
  else
    _fail "T3" "worktree-teardown.sh exited nonzero on already-removed worktree"
  fi
else
  _fail "T3" "skipped (T1 did not produce a worktree path)"
fi

# ---------------------------------------------------------------------------
# T4: worktree-teardown.sh refuses a non-/tmp/agent-* path
# ---------------------------------------------------------------------------
if "$TEARDOWN" "/tmp/NOT-AN-AGENT-PATH" "$FIXTURE_REPO" 2>/dev/null; then
  _fail "T4" "teardown should have rejected non-/tmp/agent-* path but exited 0"
else
  _pass "T4: worktree-teardown.sh exits nonzero for non-/tmp/agent-* path"
fi

# Also reject a path that looks like /tmp/agent but has extra path components.
if "$TEARDOWN" "/tmp/agent-abc123/subdir" "$FIXTURE_REPO" 2>/dev/null; then
  _fail "T4b" "teardown should have rejected /tmp/agent-*/subdir but exited 0"
else
  _pass "T4b: worktree-teardown.sh rejects /tmp/agent-*/subdir (must be top-level)"
fi

# ---------------------------------------------------------------------------
# T5: health-check exits 0 and no WARN when no stale worktrees
# ---------------------------------------------------------------------------
hc_stderr="$(mktemp)"
"$HEALTHCHECK" "$FIXTURE_REPO" >"$hc_stderr.stdout" 2>"$hc_stderr"
hc_rc=$?
hc_err_content="$(cat "$hc_stderr")"
rm -f "$hc_stderr" "$hc_stderr.stdout"

if [[ $hc_rc -eq 0 ]]; then
  if ! printf '%s' "$hc_err_content" | grep -q 'WARN'; then
    _pass "T5: worktree-health-check.sh exits 0 and no WARN when clean"
  else
    _fail "T5" "unexpected WARN in output: $hc_err_content"
  fi
else
  _fail "T5" "health-check exited $hc_rc (expected 0)"
fi

# ---------------------------------------------------------------------------
# T6: health-check warns on stderr when a /tmp/agent-* worktree is present
# ---------------------------------------------------------------------------
# Create a worktree, check for WARN, then clean up.
stale_wt=""
if stale_wt="$("$SETUP" "$FIXTURE_REPO" 2>/dev/null)"; then
  hc2_stderr="$(mktemp)"
  "$HEALTHCHECK" "$FIXTURE_REPO" >/dev/null 2>"$hc2_stderr"
  hc2_rc=$?
  hc2_err="$(cat "$hc2_stderr")"
  rm -f "$hc2_stderr"

  if [[ $hc2_rc -eq 0 ]] && printf '%s' "$hc2_err" | grep -q 'WARN'; then
    _pass "T6: worktree-health-check.sh warns on stderr for stale /tmp/agent-* worktree"
  else
    _fail "T6" "expected rc=0 and WARN; got rc=$hc2_rc stderr='$hc2_err'"
  fi

  # Clean up the planted stale worktree.
  "$TEARDOWN" "$stale_wt" "$FIXTURE_REPO" 2>/dev/null || true
else
  _fail "T6" "could not create worktree for stale-entry test"
fi

# ---------------------------------------------------------------------------
# T7: worktree-setup.sh exits nonzero on a non-git-repo argument
# ---------------------------------------------------------------------------
non_git_dir="$(mktemp -d)"
if "$SETUP" "$non_git_dir" >/dev/null 2>&1; then
  _fail "T7" "worktree-setup.sh exited 0 on a non-git-repo — expected nonzero"
else
  _pass "T7: worktree-setup.sh exits nonzero on non-git-repo argument"
fi
rm -rf "$non_git_dir"

# ---------------------------------------------------------------------------
# T8: worktree-teardown.sh exits nonzero on a non-git-repo scaffold argument
# ---------------------------------------------------------------------------
# We need a path matching /tmp/agent-* for the path guard to pass,
# then hit the git-repo check.
fake_wt="$(mktemp -d /tmp/agent-XXXXXX)"
non_git_scaffold="$(mktemp -d)"
if "$TEARDOWN" "$fake_wt" "$non_git_scaffold" >/dev/null 2>&1; then
  _fail "T8" "worktree-teardown.sh exited 0 on a non-git-repo scaffold — expected nonzero"
else
  _pass "T8: worktree-teardown.sh exits nonzero on non-git-repo scaffold argument"
fi
rm -rf "$fake_wt" "$non_git_scaffold"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nworktree-helpers self-test: %s passed, %s failed.\n' "$pass" "$fail"
if [[ "$fail" -gt 0 ]]; then
  for f in "${failures[@]}"; do
    printf '  - %s\n' "$f"
  done
  exit 1
fi
exit 0
