<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

# Release-gate test fixtures (Style-B reserved space)

This directory is the reserved location for **Style-B static fixtures**
per `specs/007-pre-release-upgrade/contracts/sub-gate.contract.md`
§ "Negative-fixture contract".

Per the 2026-05-14 contract amendment, all v1 sub-gates use **Style A
(in-test perturbation)** — the runner at
`tests/release-gate/test-gate-fail-each.sh` mutates the live candidate
tree, asserts the sub-gate fails, then reverts. Tasks T010–T013,
T026–T027, and T034–T035 (the original Style-B per-fixture-directory
shape) are marked `[~]` superseded.

Style B is reserved for future sub-gates whose breaks cannot be
expressed as a one-shot mutation (multi-file, structural, or otherwise
non-local). When the first such sub-gate lands, its fixture tree shape
is:

```text
fixtures/
└── 0N-<sub-gate-name-broken>/
    ├── README.md       # which sub-gate, what the break is, last
    │                   # canonical-tree reconciliation commit
    └── ...             # the pre-materialised broken candidate
```

Static fixtures are reconciled against the canonical tree at every
MINOR boundary; the reconciliation procedure is added to
`docs/v1.0.0-final-checklist.md` when the first Style-B sub-gate lands.
