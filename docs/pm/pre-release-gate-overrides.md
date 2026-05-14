# Pre-release-gate override audit log

<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

Append-only audit log of `SKIP_PRE_RELEASE_GATE=1` bypasses at strict-mode
git pre-push events. Format and write contract per `specs/007-pre-release-upgrade/data-model.md` E-7 and `specs/007-pre-release-upgrade/contracts/pre-push-hook.contract.md`.

**Append-only.** Do not edit existing rows. Any retroactive change is detectable via
`git log -p docs/pm/pre-release-gate-overrides.md` — that is the tamper-evidence mechanism.

The hook MUST refuse to bypass if this file is unwritable; recovery is to fix the path
or permissions, not to ignore the audit requirement.

| Date | Commit SHA | Tag pushed | Operator | Reason | Sub-gates that would have run |
|------|------------|------------|----------|--------|-------------------------------|
