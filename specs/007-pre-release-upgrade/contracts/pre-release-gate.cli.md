# Contract: `scripts/pre-release-gate.sh` CLI

**Owner**: `release-engineer`
**Status**: design (Phase 1 plan output)
**Spec**: [../spec.md](../spec.md) — FR-001, FR-002, FR-009, FR-010, FR-012.

## Synopsis

```text
scripts/pre-release-gate.sh [--only <subgate>] [--skip <subgate>...] [--help]
```

## Behaviour

Runs every registered sub-gate against the candidate tree at HEAD, in deterministic order, with fail-all semantics. Emits a single PASS / FAIL summary line and, on FAIL, a per-sub-gate detail block. Exits 0 iff every executed sub-gate exited 0.

## Flags

| Flag | Type | Default | Notes |
|---|---|---|---|
| `--only <subgate>` | string | (unset) | Run only the named sub-gate. Mutually exclusive with `--skip`. Ignored by the pre-push hook in strict mode (R-2). |
| `--skip <subgate>` | string (repeatable) | (empty) | Exclude one or more sub-gates by name. Mutually exclusive with `--only`. Ignored by the pre-push hook in strict mode. |
| `--help` | flag | — | Print usage + every registered sub-gate name + description; exit 0. |

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Every executed sub-gate exited 0 (PASS). |
| `1` | One or more sub-gates exited non-zero (FAIL). Most common case. |
| `2` | Invalid flag combination (`--only` and `--skip` together; unknown sub-gate name; unknown flag). |

The exit code MUST be the orchestrator's own exit; no wrapper inside the gate MAY consume a sub-gate's non-zero exit (FR-002).

## Output format

**Always** (stderr):
```text
pre-release-gate vX.Y.Z (candidate <sha-short>)
running N sub-gates: <name1>, <name2>, ...

[<name1>] PASS (Ns)
[<name2>] FAIL (Ns)
  <one-line diagnostic from name2's diagnostic field>
  <… additional lines as needed; indent 2 spaces>
[<name3>] PASS (Ns)
...

PASS  — N/N sub-gates green, total Ns
```

or, on failure:
```text
FAIL  — M/N sub-gates green, K failed, total Ns
  failing sub-gates: <name2>, <name7>, ...
  rerun with --only <name> to iterate on one sub-gate
```

The PASS / FAIL summary line is the LAST line printed to stderr. The gate writes nothing to stdout (so `out=$(...)` patterns capture empty content; consumers should read stderr).

## Invariants

1. Sub-gate order is deterministic: preconditions first, then regression gates alphabetically by name.
2. The gate MUST exit non-zero if the worktree is dirty (`worktree-clean` sub-gate is a precondition; its failure does not short-circuit later sub-gates — fail-all — but its failure alone makes the overall exit non-zero).
3. `--only` runs one sub-gate (precondition or regression) without skipping others; `--skip` runs every sub-gate except the named one(s).
4. `--only` and `--skip` MUST NOT both be supplied; exit 2 on that combo.
5. Unknown sub-gate name → exit 2 with a list of known names.
6. The gate's exit code is the maximum of every executed sub-gate's exit code, never reduced.
7. The gate emits its `version` (from `VERSION`) and the candidate-HEAD short SHA in the header line, so the summary identifies which template version produced it.
8. No stdout output: every diagnostic goes to stderr. (Permits `gate_output=$(scripts/pre-release-gate.sh 2>&1)` for full capture, or silent stdout for piped CI consumers.)

## Negative behaviours (forbidden)

- The gate MUST NOT call `set +e` and let a sub-gate's non-zero exit pass through unnoticed.
- The gate MUST NOT pipe its summary line through `tail` or any command whose exit code masks the gate's own.
- The gate MUST NOT prompt for interactive input (CI / hook use).
- The gate MUST NOT write to the worktree; all fixtures live in tempdirs.

## Test coverage

`tests/release-gate/test-gate-pass.sh` — positive end-to-end on a known-clean candidate.
`tests/release-gate/test-gate-fail-each.sh` — every negative fixture (one per sub-gate) produces non-zero exit AND surfaces in the summary's `failing sub-gates:` list.
`tests/release-gate/test-gate-wrapper.sh` — exit-code propagation through the 5 wrapper compositions in R-5.
