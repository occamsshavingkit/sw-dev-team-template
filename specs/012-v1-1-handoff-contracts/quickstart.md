# Quickstart: v1.1 Handoff Contracts

## Prerequisites

- Work from the repository root: `/home/quackdcs/SWEProj`.
- Treat `sw-dev-team-template` as the framework-maintenance target.
- Keep gates in warning mode until readiness evidence is accepted.

## Plan Validation

1. Confirm active feature paths:

   ```bash
   .specify/scripts/bash/check-prerequisites.sh --json --paths-only
   ```

2. Review the v1.1 spec and plan:

   ```bash
   test -f specs/012-v1-1-handoff-contracts/spec.md && test -f specs/012-v1-1-handoff-contracts/plan.md
   ```

## Implementation Verification Baseline

Run focused hook tests as each implementation slice lands:

```bash
cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh
```

```bash
cd sw-dev-team-template && tests/hooks/test-handoff-pre-tool-gate.sh
```

```bash
cd sw-dev-team-template && tests/hooks/test-handoff-task-completed-gate.sh
```

## Enforce-Readiness Smoke Baseline

Before promoting warning mode to enforce mode, collect zero-unresolved-false-positive evidence for:

- Handoff create/update.
- Allowed edit.
- Forbidden edit.
- Evidence acceptance.
- Evidence rejection.
- Bounded Codex.
- Model fallback.

## Expected Role Gates

- `software-engineer`: implementation changes and tests.
- `qa-engineer`: verification strategy and smoke evidence.
- `code-reviewer`: code/schema/hook review before commit.
- `security-engineer`: review if gates affect security-sensitive paths or approval semantics.
- `release-engineer`: release handoff and warning-to-enforce readiness.
