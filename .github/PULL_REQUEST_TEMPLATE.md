<!-- SPDX-License-Identifier: MIT -->
<!-- Copyright 2026 occamsshavingkit/sw-dev-team-template contributors -->

## Summary

<!-- One-paragraph description of what this PR does. -->

## Checklist

- [ ] Tests pass locally (`tests/release-gate/`, `tests/hooks/`, smoke suite).
- [ ] CHANGELOG entry added (if user-visible change).
- [ ] **If this PR adds or removes flags in `scripts/upgrade.sh`:** the stub at
  `tests/release-gate/dogfood-examples/_shared/upgrade.sh` is updated to match.
  Stub and driver flag sets must stay in lockstep — drift causes the dogfood
  capture to fail-loud only when the capture is next exercised, which may be
  days after the driver change lands. (Issue #194.)
