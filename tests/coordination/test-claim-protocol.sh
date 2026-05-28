#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# Claim-protocol smoke tests — US1: advisory claim with deterministic tie-break.
#
# Uses the pure-function tie-break helper at tests/coordination/lib/claim_tiebreak.py.
# No gh / network required; operates on fixture Claim Records only.
#
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIB="$REPO_ROOT/tests/coordination/lib/claim_tiebreak.py"

pass=0
fail=0
failures=()

record_pass() {
    pass=$((pass + 1))
    printf 'PASS  %s\n' "$1"
}

record_fail() {
    fail=$((fail + 1))
    failures+=("$1")
    printf 'FAIL  %s\n' "$1"
    if [ -n "${2:-}" ]; then
        printf '      %s\n' "$2"
    fi
}

# ---------------------------------------------------------------------------
# Runner: invoke the tie-break helper via Python and capture the winning
# operator id. The helper is given a JSON array of Claim Records; it returns
# the winner's operator id on stdout.
# ---------------------------------------------------------------------------
run_tiebreak_case() {
    local name=$1
    local claims_json=$2        # JSON array of {operator, ts, ...} objects
    local expected_winner=$3    # operator id string
    local actual rc output

    output=$(python3 - "$claims_json" "$LIB" 2>&1 <<'PY'
import json
import sys
import importlib.util

claims_json = sys.argv[1]
lib_path    = sys.argv[2]

spec = importlib.util.spec_from_file_location("claim_tiebreak", lib_path)
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

claims = json.loads(claims_json)
winner = mod.resolve_winner(claims)
print(winner["operator"])
PY
    )
    rc=$?

    if [ "$rc" -ne 0 ]; then
        record_fail "$name" "helper exited rc=$rc output=$output"
        return
    fi

    actual="$output"
    if [ "$actual" = "$expected_winner" ]; then
        record_pass "$name"
    else
        record_fail "$name" "expected=$expected_winner actual=$actual"
    fi
}

# ---------------------------------------------------------------------------
# Helper: run the same claim set in forward order, then in reversed order,
# and assert both produce the same winner (observer-independence check).
# ---------------------------------------------------------------------------
run_tiebreak_observer_independent_case() {
    local name=$1
    local claims_json=$2
    local expected_winner=$3

    # Forward order
    run_tiebreak_case "$name (forward order)" "$claims_json" "$expected_winner"

    # Reversed order — Python reversal via inline jq-free transform
    local reversed_json
    reversed_json=$(python3 -c "import json,sys; arr=json.loads(sys.argv[1]); print(json.dumps(arr[::-1]))" "$claims_json")
    run_tiebreak_case "$name (reversed order)" "$reversed_json" "$expected_winner"
}

# ---------------------------------------------------------------------------
# TC-001: Collision — two operators, DIFFERENT timestamps.
#   operator-alice posts ts=2026-05-27T18:00:00Z
#   operator-bob   posts ts=2026-05-27T18:00:05Z  (5 s later)
# Rule: earliest ts wins → alice wins.
# Observer-independence: result must be identical regardless of input order.
# ---------------------------------------------------------------------------
FIXTURE_DIFF_TS='[
  {"type":"CLAIM","operator":"operator-alice","machine":"machine-a","session":"sess-001","ts":"2026-05-27T18:00:00Z","issue":"42"},
  {"type":"CLAIM","operator":"operator-bob",  "machine":"machine-b","session":"sess-002","ts":"2026-05-27T18:00:05Z","issue":"42"}
]'

run_tiebreak_observer_independent_case \
    "TC-001: collision different timestamps — earliest ts wins (alice)" \
    "$FIXTURE_DIFF_TS" \
    "operator-alice"

# ---------------------------------------------------------------------------
# TC-002: Collision — two operators, IDENTICAL timestamps.
#   operator-alice ts=2026-05-27T18:00:00Z
#   operator-bob   ts=2026-05-27T18:00:00Z  (same second)
# Rule: ts tie → lexicographically lower operator id wins → alice < bob → alice wins.
# Observer-independence: result must be identical regardless of input order.
# ---------------------------------------------------------------------------
FIXTURE_SAME_TS='[
  {"type":"CLAIM","operator":"operator-alice","machine":"machine-a","session":"sess-003","ts":"2026-05-27T18:00:00Z","issue":"42"},
  {"type":"CLAIM","operator":"operator-bob",  "machine":"machine-b","session":"sess-004","ts":"2026-05-27T18:00:00Z","issue":"42"}
]'

run_tiebreak_observer_independent_case \
    "TC-002: collision same timestamp — lexical operator id decides (alice < bob)" \
    "$FIXTURE_SAME_TS" \
    "operator-alice"

# ---------------------------------------------------------------------------
# TC-003: Lexical winner is NOT the first in list order.
#   operator-zebra ts=2026-05-27T18:00:00Z  (earlier ts, but lexically higher id)
#   operator-aardvark ts=2026-05-27T18:00:00Z  (same ts, lexically lower id)
# Rule: same ts → aardvark < zebra → aardvark wins (NOT zebra despite appearing first).
# Verifies that the tie-break is NOT insertion-order-dependent.
# ---------------------------------------------------------------------------
FIXTURE_LEXICAL_NOT_FIRST='[
  {"type":"CLAIM","operator":"operator-zebra",    "machine":"machine-z","session":"sess-005","ts":"2026-05-27T18:00:00Z","issue":"42"},
  {"type":"CLAIM","operator":"operator-aardvark", "machine":"machine-a","session":"sess-006","ts":"2026-05-27T18:00:00Z","issue":"42"}
]'

run_tiebreak_observer_independent_case \
    "TC-003: same timestamp — lexical winner is not the first list element (aardvark wins over zebra)" \
    "$FIXTURE_LEXICAL_NOT_FIRST" \
    "operator-aardvark"

# ---------------------------------------------------------------------------
# TC-004: Uncontested — only one active claim.
# Rule: single claim always wins.
# ---------------------------------------------------------------------------
FIXTURE_SOLO='[
  {"type":"CLAIM","operator":"operator-solo","machine":"machine-s","session":"sess-007","ts":"2026-05-27T18:00:00Z","issue":"42"}
]'

run_tiebreak_case \
    "TC-004: uncontested single claim — sole operator wins" \
    "$FIXTURE_SOLO" \
    "operator-solo"

# ---------------------------------------------------------------------------
# TC-005: 0 double-claims (I1, SC-001) — contested two-claim scenario.
#
# Two operators post simultaneous CLAIM records. The tie-break MUST resolve
# to exactly ONE winner; the other operator is the loser/yielder.
# Assert: exactly one operator is identified as winner; the winner is
# deterministic; the loser is the non-winning operator.
#
# Protocol note (I4): the two CLAIM records CAN coexist transiently during
# the race window — the protocol does NOT prevent a race via a hard lock.
# The tie-break (not a mutex) is the sole mechanism that produces single
# ownership. This test validates the tie-break output, not lock prevention.
# ---------------------------------------------------------------------------
FIXTURE_CONTESTED='[
  {"type":"CLAIM","operator":"operator-charlie","machine":"machine-c","session":"sess-010","ts":"2026-05-27T19:00:00Z","issue":"99"},
  {"type":"CLAIM","operator":"operator-delta",  "machine":"machine-d","session":"sess-011","ts":"2026-05-27T19:00:03Z","issue":"99"}
]'

# Helper: assert that the winner is operator-charlie AND that the winner is
# NOT operator-delta (i.e. exactly one holder, the other is the yielder).
WINNER_CHARLIE=$(python3 - "$FIXTURE_CONTESTED" "$LIB" 2>&1 <<'PY'
import json, sys, importlib.util
claims_json = sys.argv[1]; lib_path = sys.argv[2]
spec = importlib.util.spec_from_file_location("claim_tiebreak", lib_path)
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
claims = json.loads(claims_json)
winner = mod.resolve_winner(claims)
print(winner["operator"])
PY
)

# Assert exactly one winner (charlie, earliest ts)
if [ "$WINNER_CHARLIE" = "operator-charlie" ]; then
    record_pass "TC-005a: 0 double-claims (I1, SC-001) — exactly one winner (charlie, earlier ts)"
else
    record_fail "TC-005a: 0 double-claims (I1, SC-001) — exactly one winner" \
        "expected=operator-charlie actual=$WINNER_CHARLIE"
fi

# Assert the two-claim set resolves to exactly one winner AND a distinct identified
# loser. Compute the loser as the non-winning operator from the input set; assert
# the loser is operator-delta (not merely "not the winner", which TC-005a already
# implies, but positively identified as the specific yielding operator).
LOSER_DELTA=$(python3 - "$FIXTURE_CONTESTED" "$LIB" 2>&1 <<'PY'
import json, sys, importlib.util
claims_json = sys.argv[1]; lib_path = sys.argv[2]
spec = importlib.util.spec_from_file_location("claim_tiebreak", lib_path)
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
claims = json.loads(claims_json)
winner = mod.resolve_winner(claims)
winner_op = winner["operator"]
all_ops = [c["operator"] for c in claims]
losers = [op for op in all_ops if op != winner_op]
# Must be exactly one winner and exactly one loser in a two-claim set.
if len(losers) != 1:
    print("ERROR: expected exactly 1 loser, got " + str(len(losers)))
    sys.exit(1)
print(losers[0])
PY
)
_LOSER_RC=$?
if [ "$_LOSER_RC" -ne 0 ]; then
    record_fail "TC-005b: 0 double-claims (I1, SC-001) — two-claim set yields exactly one winner + one identified loser" \
        "loser-computation failed: $LOSER_DELTA"
elif [ "$LOSER_DELTA" = "operator-delta" ]; then
    record_pass "TC-005b: 0 double-claims (I1, SC-001) — two-claim set yields exactly one winner + one identified loser (delta)"
else
    record_fail "TC-005b: 0 double-claims (I1, SC-001) — two-claim set yields exactly one winner + one identified loser" \
        "expected loser=operator-delta actual=$LOSER_DELTA"
fi

# ---------------------------------------------------------------------------
# TC-006: Loser yields → reclaimable (I3).
#
# After the loser yields (YIELD posted, assignment cleared, issue returned to
# queued), the issue is reclaimable. Model this as: the active claim set for
# the loser is now empty (their CLAIM is cancelled by a YIELD), so only the
# winner's claim remains. A new operator can then claim the issue freely.
#
# The tie-break helper operates on ACTIVE claim records (those not cancelled
# by a YIELD for the same operator). Post-yield state: only winner's record
# is active. A new claimant entering after the yield should win uncontested.
#
# Assert: post-yield active claim set for the issue (winner only) resolves to
# the winner — confirming no residual loser claim blocks reclaim. Then assert
# that if the winner also releases, a brand-new operator can claim uncontested.
# ---------------------------------------------------------------------------

# Post-yield: loser's CLAIM has been cancelled — only winner remains active.
# (In the real protocol the YIELD comment cancels the loser's active claim;
# we model that here by simply omitting the yielded operator's CLAIM record
# from the active set.)
FIXTURE_POST_YIELD_WINNER_ONLY='[
  {"type":"CLAIM","operator":"operator-charlie","machine":"machine-c","session":"sess-010","ts":"2026-05-27T19:00:00Z","issue":"99"}
]'

run_tiebreak_case \
    "TC-006a: loser yields → post-yield active set has only winner; winner still resolves correctly (I3)" \
    "$FIXTURE_POST_YIELD_WINNER_ONLY" \
    "operator-charlie"

# Post-yield, new operator reclaims: issue is in queued state, no residual
# claim from anyone. New operator echo claims uncontested.
FIXTURE_POST_YIELD_RECLAIM='[
  {"type":"CLAIM","operator":"operator-echo","machine":"machine-e","session":"sess-020","ts":"2026-05-27T19:05:00Z","issue":"99"}
]'

run_tiebreak_case \
    "TC-006b: loser yields → issue reclaimable by new operator uncontested (I3)" \
    "$FIXTURE_POST_YIELD_RECLAIM" \
    "operator-echo"

# ---------------------------------------------------------------------------
# TC-007: Release/handback → reclaimable (FR-004).
#
# After the winner releases (clears claim, restores status:queued, clears
# local pointer), no active CLAIM exists. Model post-release state as an
# empty active-claim set. A subsequent sole claimant wins uncontested.
#
# Assert: after release, a new operator claiming the issue wins uncontested
# (the active claim set has exactly one entry — theirs).
# ---------------------------------------------------------------------------
FIXTURE_POST_RELEASE_RECLAIM='[
  {"type":"CLAIM","operator":"operator-foxtrot","machine":"machine-f","session":"sess-030","ts":"2026-05-27T20:00:00Z","issue":"99"}
]'

run_tiebreak_case \
    "TC-007: release/handback → issue reclaimable by next operator uncontested (FR-004, I3)" \
    "$FIXTURE_POST_RELEASE_RECLAIM" \
    "operator-foxtrot"

# ---------------------------------------------------------------------------
# TC-008: Advisory, not a hard lock (I4).
#
# The protocol does NOT prevent two CLAIM records from coexisting transiently
# during the race window — this is by design (optimistic/advisory, not mutex).
# The resolution mechanism is the tie-break computation, not lock prevention.
#
# This test verifies:
#   (a) Two CLAIM records CAN be fed to the helper (modelling the race window
#       where both exist simultaneously) — no error, no rejection.
#   (b) The tie-break (not a lock) produces a single unambiguous winner.
#   (c) The result is identical regardless of evaluation order (I2 /
#       observer-independence), confirming the determinism is in the
#       tie-break algorithm, not in any mutex that would prevent the second
#       claim from being recorded.
#
# Contrast: a hard-lock protocol would REJECT the second CLAIM at write time.
# This protocol ACCEPTS both and resolves via computation — that is the
# advisory property captured by I4.
# ---------------------------------------------------------------------------
FIXTURE_ADVISORY_RACE='[
  {"type":"CLAIM","operator":"operator-golf",  "machine":"machine-g","session":"sess-040","ts":"2026-05-27T21:00:00Z","issue":"55"},
  {"type":"CLAIM","operator":"operator-hotel", "machine":"machine-h","session":"sess-041","ts":"2026-05-27T21:00:00Z","issue":"55"}
]'

# Both claims coexist (no rejection) — tie-break resolves to single winner.
# Same ts → lexical: golf < hotel → golf wins.
run_tiebreak_observer_independent_case \
    "TC-008: advisory/no-hard-lock — two coexistent CLAIM records in race window; tie-break (not lock) yields single owner (I4)" \
    "$FIXTURE_ADVISORY_RACE" \
    "operator-golf"

# ---------------------------------------------------------------------------
# TC-009: GATE-PASSED comment does NOT satisfy the completion gate (SC-004, FR-008, I5).
#
# The coordination layer is observational; it MUST NOT short-circuit the
# evidence gates from feature 012.  A "GATE-PASSED" comment is a GitHub-
# issue artifact with no representation in the handoff's verification.*
# fields.  The completion gate reads ONLY verification.*/completion.evidence
# in the handoff JSON; it never consults GitHub comments.
#
# Assertions:
#   TC-009a: The gate script and its lib contain no reference to any
#            comment field (GATE-PASSED, gh, or comment keyword).  This
#            structural check is a proxy for "no coordination comment can
#            ever be consulted" — confirmed offline without network access.
#
#   TC-009b: Running the completion gate against a fixture that has
#            NO accepted verification.* evidence (completion-evidence-missing.json)
#            with SWDT_HANDOFF_GATES=enforce produces a "deny" decision.
#            The presence of a hypothetical GATE-PASSED comment changes
#            nothing: the fixture models "a handoff that would accompany a
#            GATE-PASSED comment but carries zero hook-captured evidence",
#            and the gate still denies.
# ---------------------------------------------------------------------------

# TC-009a: structural absence — gate and lib contain no comment-consulting code.
GATE_SCRIPT="$REPO_ROOT/scripts/hooks/handoff-task-completed-gate.py"
HANDOFF_LIB="$REPO_ROOT/scripts/hooks/lib/handoff.py"

_gate_comment_hits=$(grep -c "GATE.PASSED\|gh \|\.comment\b" "$GATE_SCRIPT" "$HANDOFF_LIB" 2>/dev/null | awk -F: '{sum += $NF} END {print sum+0}')
if [ "$_gate_comment_hits" = "0" ]; then
    record_pass "TC-009a: gate script + lib contain no GitHub-comment-consulting code (SC-004, FR-008, I5)"
else
    record_fail "TC-009a: gate script + lib contain no GitHub-comment-consulting code" \
        "grep found $_gate_comment_hits match(es) of GATE-PASSED/gh/comment in gate or lib"
fi

# TC-009b: gate denies a handoff with zero accepted evidence regardless of any
# (absent) coordination comment.  Build a minimal ephemeral repo tree, point
# the active-handoff pointer at the 'completion-evidence-missing' fixture, and
# invoke the gate with SWDT_HANDOFF_GATES=enforce.
#
# The fixture already requires:
#   tests: ["tests/hooks/test-handoff-task-completed-gate.sh"]
#   review: true
# and its verification.* blocks are empty — so the gate MUST deny.

_GATE_TMP=$(mktemp -d)
# Provide the .devteam pointer.
mkdir -p "$_GATE_TMP/.devteam"
# Copy the fixture into a docs/handoffs/ location within the tmp tree.
mkdir -p "$_GATE_TMP/docs/handoffs"
cp "$REPO_ROOT/tests/hooks/fixtures/handoff/completion-evidence-missing.json" \
   "$_GATE_TMP/docs/handoffs/completion-evidence-missing.json"
# Write the active-handoff pointer referencing the fixture by path.
printf '{"handoff_path":"docs/handoffs/completion-evidence-missing.json"}\n' \
    > "$_GATE_TMP/.devteam/active-handoff.json"

# Provide a stub schemas/ directory so load_active_handoff can find the schema.
# Use the real schema from the repo.
mkdir -p "$_GATE_TMP/schemas"
cp "$REPO_ROOT/schemas/handoff.schema.json" "$_GATE_TMP/schemas/handoff.schema.json"

_GATE_EVENT='{"hook_event_name":"TaskCompleted"}'
_GATE_OUTPUT=$(
    SWDT_HANDOFF_GATES=enforce \
    CLAUDE_PROJECT_DIR="$_GATE_TMP" \
    python3 "$GATE_SCRIPT" <<< "$_GATE_EVENT" 2>&1
)
_GATE_RC=$?
rm -rf "$_GATE_TMP"

# The gate should exit 0 (it never exits non-zero for a deny; it prints JSON).
# The output JSON must contain "deny" in the permissionDecision field.
if [ "$_GATE_RC" -ne 0 ]; then
    record_fail "TC-009b: gate denies handoff with no accepted evidence (GATE-PASSED comment absent from data model)" \
        "gate exited rc=$_GATE_RC; output: $_GATE_OUTPUT"
elif echo "$_GATE_OUTPUT" | python3 -c "
import json, sys
out = sys.stdin.read().strip()
if not out:
    sys.exit(1)  # no output at all → gate was off or passed silently, unexpected
d = json.loads(out)
decision = d.get('hookSpecificOutput', {}).get('permissionDecision', '')
sys.exit(0 if decision == 'deny' else 2)
" 2>/dev/null; then
    record_pass "TC-009b: gate denies handoff with no accepted evidence — GATE-PASSED comment cannot satisfy the gate (SC-004, FR-008, I5)"
else
    record_fail "TC-009b: gate denies handoff with no accepted evidence (GATE-PASSED comment absent from data model)" \
        "expected permissionDecision=deny; gate output: $_GATE_OUTPUT"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\nSummary: %s passed, %s failed\n' "$pass" "$fail"
if [ "$fail" -ne 0 ]; then
    printf 'Failures:\n'
    printf '  - %s\n' "${failures[@]}"
    exit 1
fi

exit 0
