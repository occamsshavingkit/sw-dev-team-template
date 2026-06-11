#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# tests/upgrade/test-execbit-preserved.sh — regression test for issue #337:
# executable bits must be preserved across upgrade sync.
#
# Cases:
#   T1. atomic_install copies an executable src to dst and the dst gains +x.
#   T2. atomic_install copies a non-executable src to dst; dst stays non-exec.
#   T3. upgrade.sh --verify (standalone) flags a shipped file whose git-
#       tracked mode is 100755 but on-disk lacks +x.
#   T4. upgrade.sh --verify (standalone) does NOT flag a file whose
#       git-tracked mode is 100644 (legitimately non-exec).
#
# T1/T2 exercise the fixed atomic_install function extracted from upgrade.sh.
# T3/T4 exercise the --verify exec-bit drift check on the live repo.
#
# HAZARD: do NOT run tests/release-gate/test-gate-fail-each.sh — it
# git-resets/commits the work branch (issue #306). This test is safe:
# it uses only temp directories and read-only git operations on the live
# repo (T3 temporarily strips +x from one file then restores it).

set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UPGRADE_SH="$REPO_ROOT/scripts/upgrade.sh"

tmp="$(mktemp -d -t execbit-test-XXXXXX)"
keep=0
[[ "${1:-}" == "--keep" ]] && keep=1
trap 'if [[ $keep -eq 0 ]]; then rm -rf "$tmp"; else echo "(kept $tmp)" >&2; fi' EXIT

fail=0
pass=0

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label" >&2
        fail=$((fail + 1))
    fi
}

# ---------------------------------------------------------------------------
# Extract and exercise atomic_install in isolation (T1, T2).
#
# We source the fixed atomic_install definition directly in a child process
# (no full upgrade.sh parse needed — the function has no external deps
# other than install(1) and mktemp(1)).
# ---------------------------------------------------------------------------
echo "-- T1/T2: atomic_install preserves executable bit --"

_exec_src="$tmp/exec_src.sh"
_noexec_src="$tmp/noexec_src.sh"
_exec_dst="$tmp/exec_dst.sh"
_noexec_dst="$tmp/noexec_dst.sh"

printf '#!/usr/bin/env bash\necho hello\n' > "$_exec_src"
chmod 0755 "$_exec_src"

printf '# not executable\n' > "$_noexec_src"
chmod 0644 "$_noexec_src"

# Source atomic_install from upgrade.sh and call it.  Use a wrapper script
# rather than a heredoc to avoid quoting/variable-expansion hazards.
_wrapper="$tmp/run_atomic_install.sh"
cat > "$_wrapper" <<'WRAPPER_EOF'
#!/usr/bin/env bash
set -euo pipefail
# Extract the atomic_install function from upgrade.sh and source it.
UPGRADE_SH="$1"
src="$2"
dst="$3"
# Source the function definition by evaluating its body.
eval "$(awk '/^atomic_install\(\)/{found=1} found{print; if(/^}$/){exit}}' "$UPGRADE_SH")"
atomic_install "$src" "$dst"
WRAPPER_EOF
chmod +x "$_wrapper"

# T1: executable src -> dst gets +x
bash "$_wrapper" "$UPGRADE_SH" "$_exec_src" "$_exec_dst"
check "T1: atomic_install preserves +x from executable src" \
    test -x "$_exec_dst"

# T2: non-executable src -> dst stays non-exec (no spurious +x)
bash "$_wrapper" "$UPGRADE_SH" "$_noexec_src" "$_noexec_dst"
check "T2: atomic_install does NOT add +x for non-executable src" \
    bash -c "! test -x '$_noexec_dst'"

# ---------------------------------------------------------------------------
# T3: --verify flags exec-bit drift (shipped +x file on-disk lacks +x).
# We pick a file tracked as 100755 in the live repo's git index, temporarily
# strip its exec bit, run --verify, then restore.
# ---------------------------------------------------------------------------
echo ""
echo "-- T3: --verify detects exec-bit drift --"

_test_target=""
# ls-files --stage format: "<mode> <hash> <stage>\t<path>"
# awk splits on any whitespace; $4 is the path after the tab.
while IFS= read -r _path; do
    case "$_path" in
        scripts/*.sh|.git-hooks/*)
            if [[ -f "$REPO_ROOT/$_path" && -x "$REPO_ROOT/$_path" ]]; then
                _test_target="$_path"
                break
            fi
            ;;
    esac
done < <(git -C "$REPO_ROOT" ls-files --stage 2>/dev/null | awk '$1=="100755"{sub(/^[^ ]+ [^ ]+ [^ ]+\t/, ""); print}')

if [[ -z "$_test_target" ]]; then
    echo "  SKIP: T3 — no suitable 100755-tracked script found in the repo" >&2
    echo "  SKIP: T4 — skipping companion test"
else
    # Strip the exec bit temporarily.
    chmod -x "$REPO_ROOT/$_test_target"

    # --verify should now report exec-bit drift (nonzero exit).
    _verify_rc=0
    bash "$UPGRADE_SH" --verify --root "$REPO_ROOT" >/dev/null 2>&1 || _verify_rc=$?

    # Restore exec bit BEFORE evaluating result (safety-first).
    chmod +x "$REPO_ROOT/$_test_target"

    if [[ $_verify_rc -ne 0 ]]; then
        echo "  PASS: T3: --verify exits nonzero when exec-bit is stripped"
        pass=$((pass + 1))
    else
        echo "  FAIL: T3: --verify exited 0 even though exec-bit was stripped" >&2
        fail=$((fail + 1))
    fi

    # ---------------------------------------------------------------------------
    # T4: --verify does NOT flag a legitimately non-executable file (100644).
    # ---------------------------------------------------------------------------
    echo ""
    echo "-- T4: --verify does not false-positive on legitimately non-exec files --"

    _noexec_target=""
    while IFS= read -r _path; do
        case "$_path" in
            docs/*.md|.claude/agents/*.md)
                if [[ -f "$REPO_ROOT/$_path" && ! -x "$REPO_ROOT/$_path" ]]; then
                    _noexec_target="$_path"
                    break
                fi
                ;;
        esac
    done < <(git -C "$REPO_ROOT" ls-files --stage 2>/dev/null | awk '$1=="100644"{sub(/^[^ ]+ [^ ]+ [^ ]+\t/, ""); print}')

    if [[ -z "$_noexec_target" ]]; then
        echo "  SKIP: T4 — no suitable 100644-tracked file found" >&2
    else
        # --verify output should NOT mention this path as exec-bit drift.
        _verify_out="$(bash "$UPGRADE_SH" --verify --root "$REPO_ROOT" 2>&1)" || true
        if printf '%s' "$_verify_out" | grep -qF "exec-bit drift: $REPO_ROOT/$_noexec_target"; then
            echo "  FAIL: T4: --verify incorrectly flagged non-exec file $_noexec_target" >&2
            fail=$((fail + 1))
        else
            echo "  PASS: T4: --verify does not flag legitimately non-exec file $_noexec_target"
            pass=$((pass + 1))
        fi
    fi
fi

# ---------------------------------------------------------------------------
# T5: upgrade repairs exec-bit on content-identical files that the sync loop
# SKIPS (the "skipped-file repair path", issue #337).
#
# Scenario: a project has a shipped script whose on-disk content is byte-
# identical to upstream but whose file mode is 0644 (no exec bit) — as
# happens in old fixtures like v1.0.0-rc3 which predated exec-bit tracking.
# The sync loop detects content parity and skips the file; atomic_install
# is never called.  The Phase-B repair pass must still chmod +x the file
# and the upgrade must exit 0 (not 1).
#
# We use a minimal synthetic upstream git repo + project so no network is
# needed and the live work branch is never mutated.
# ---------------------------------------------------------------------------
echo ""
echo "-- T5: upgrade repairs exec-bit on content-identical skipped file --"

_up="$tmp/t5-upstream"
_proj="$tmp/t5-project"
mkdir -p "$_up" "$_proj"

# Build a minimal upstream repo with one executable script.
(
  cd "$_up"
  git init -q
  git config user.email test@example.invalid
  git config user.name "T5 test"

  # Minimal scaffold-compatible files (upgrade.sh needs TEMPLATE_VERSION).
  printf 'v1.0.0\n' > VERSION
  printf 'v1.0.0\nunknown\n2026-01-01\n' > TEMPLATE_VERSION

  # The file under test: a script that upstream ships as executable.
  mkdir -p scripts
  printf '#!/usr/bin/env bash\necho ok\n' > scripts/run.sh
  chmod 0755 scripts/run.sh

  git add .
  git commit -q -m "v1.0.0"
  git tag v1.0.0
)

# Build the project: same content for scripts/run.sh, but mode 0644 (no +x).
# This simulates an rc3-era fixture whose file predates exec-bit tracking.
(
  cd "$_proj"
  git init -q
  git config user.email test@example.invalid
  git config user.name "T5 project"

  printf 'v0.9.0\nunknown\n2026-01-01\n' > TEMPLATE_VERSION
  mkdir -p scripts
  # Identical content to upstream, but non-executable.
  printf '#!/usr/bin/env bash\necho ok\n' > scripts/run.sh
  chmod 0644 scripts/run.sh   # ← no exec bit: the bug condition

  # No TEMPLATE_MANIFEST.lock: upgrade.sh detects it as missing and falls
  # through to the full sync path, then writes a fresh one at the end.
  # Pre-seeding a stub lock file would cause upgrade to record it as a
  # conflict (project vs upstream divergence), which would make --verify
  # exit 1 even after a clean upgrade — unrelated to the exec-bit fix.

  git add .
  git commit -q -m "project at v0.9.0"
)

# Confirm precondition: scripts/run.sh is NOT executable in the project.
if [[ -x "$_proj/scripts/run.sh" ]]; then
    echo "  FAIL: T5: precondition — scripts/run.sh should start non-exec" >&2
    fail=$((fail + 1))
else
    echo "  PASS: T5: precondition — scripts/run.sh starts non-exec (0644)"
    pass=$((pass + 1))
fi

# Run upgrade from the project, targeting upstream v1.0.0.
_t5_upgrade_rc=0
_t5_upgrade_log="$tmp/t5-upgrade.log"
(
  cd "$_proj"
  SWDT_UPSTREAM_URL="$_up" bash "$UPGRADE_SH" --target v1.0.0
) > "$_t5_upgrade_log" 2>&1 || _t5_upgrade_rc=$?

# Assertion 1: upgrade exits 0 (not 1 from the old gating behavior).
if [[ $_t5_upgrade_rc -eq 0 ]]; then
    echo "  PASS: T5: upgrade exits 0 despite skipped-file exec-bit drift"
    pass=$((pass + 1))
else
    echo "  FAIL: T5: upgrade exited $_t5_upgrade_rc — expected 0" >&2
    sed 's/^/        /' "$_t5_upgrade_log" >&2
    fail=$((fail + 1))
fi

# Assertion 2: scripts/run.sh is now executable in the project.
if [[ -x "$_proj/scripts/run.sh" ]]; then
    echo "  PASS: T5: scripts/run.sh has exec bit restored after upgrade"
    pass=$((pass + 1))
else
    echo "  FAIL: T5: scripts/run.sh still non-exec after upgrade" >&2
    fail=$((fail + 1))
fi

# Assertion 3: upgrade log mentions the repair.
if grep -q "restoring exec bit" "$_t5_upgrade_log"; then
    echo "  PASS: T5: upgrade log notes exec-bit restoration"
    pass=$((pass + 1))
else
    echo "  FAIL: T5: upgrade log does not mention exec-bit restoration" >&2
    fail=$((fail + 1))
fi

# Assertion 4: --verify does NOT report exec-bit drift after upgrade.
# (The minimal fixture has a TEMPLATE_VERSION conflict which is expected and
# unrelated to the exec-bit fix; we check only that --verify does not print
# exec-bit drift for scripts/run.sh, which would indicate the repair failed.)
_t5_verify_out="$tmp/t5-verify.log"
(cd "$_proj" && bash "$UPGRADE_SH" --verify) >"$_t5_verify_out" 2>&1 || true
if grep -q "exec-bit drift.*scripts/run.sh" "$_t5_verify_out"; then
    echo "  FAIL: T5: --verify still reports exec-bit drift for scripts/run.sh" >&2
    fail=$((fail + 1))
else
    echo "  PASS: T5: --verify does not report exec-bit drift for scripts/run.sh"
    pass=$((pass + 1))
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "PASS: $pass"
echo "FAIL: $fail"
if [[ "$fail" -gt 0 ]]; then
    exit 1
fi
exit 0
