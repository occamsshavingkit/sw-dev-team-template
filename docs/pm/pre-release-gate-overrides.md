# Pre-release-gate override audit log

<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

Append-only audit log of bypasses at upgrade-contract gates. Two event
types share this file (per FW-ADR-0010, customer ruling 2026-05-14):

- `Gate: pre-release` — `SKIP_PRE_RELEASE_GATE=1` bypass at the
  strict-mode git pre-push event. Format and write contract per
  `specs/007-pre-release-upgrade/data-model.md` E-7 and
  `specs/007-pre-release-upgrade/contracts/pre-push-hook.contract.md`.
- `Gate: pre-bootstrap` — `SWDT_PREBOOTSTRAP_FORCE=1` bypass at
  `scripts/upgrade.sh` self-bootstrap or at the `migrations/v0.14.0.sh`
  pre-bootstrap step (FW-ADR-0010). `Tag pushed` and `Sub-gates` are
  left empty for these rows; `Reason` records the matrix-row that
  fired (`local-edit` or `baseline-unreachable`), optionally with an
  operator-supplied note from `SWDT_PREBOOTSTRAP_FORCE_REASON`.

Schema (v2 per FW-ADR-0010): `Gate` column was added 2026-05-14. Rows
that predate the bump have an empty `Gate` cell; treat empty as
`pre-release` for back-compat.

**Append-only.** Do not edit existing rows. Any retroactive change is detectable via
`git log -p docs/pm/pre-release-gate-overrides.md` — that is the tamper-evidence mechanism.

The hook (and `scripts/upgrade.sh` / `migrations/v0.14.0.sh`) MUST refuse to bypass if
this file is unwritable; recovery is to fix the path or permissions, not to ignore the
audit requirement.

| Date | Gate | Commit SHA | Tag pushed | Operator | Reason | Sub-gates that would have run |
|------|------|------------|------------|----------|--------|-------------------------------|
