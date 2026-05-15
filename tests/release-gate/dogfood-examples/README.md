<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

# Dogfood-driver example fixtures

Synthetic, hand-crafted minimal trees for smoke-testing
`tests/release-gate/dogfood-downstream.sh`. **These are NOT real
downstream projects.** They exist solely to exercise the driver's
control flow (fixture validation, scratch-clone, upgrade invocation,
report emission, PASS/FAIL classification) without requiring an
operator-local fixture.

## Layout

```text
dogfood-examples/
├── _shared/
│   └── upgrade.sh                 — single source of truth for the stub
├── alpha/rc8/
│   ├── TEMPLATE_VERSION
│   └── scripts/upgrade.sh         → symlink ../../../_shared/upgrade.sh
├── beta/rc10/
│   ├── TEMPLATE_VERSION
│   └── scripts/upgrade.sh         → symlink ../../../_shared/upgrade.sh
├── gamma/rc11/
│   ├── TEMPLATE_VERSION
│   └── scripts/upgrade.sh         → symlink ../../../_shared/upgrade.sh
└── delta/rc11/
    ├── TEMPLATE_VERSION
    ├── .template-conflicts.json   — pre-placed; 1 accepted_local + 1 conflict
    └── scripts/upgrade.sh         → symlink ../../../_shared/upgrade.sh
```

Three previously byte-identical stub copies were collapsed into one
shared script under `_shared/`; each fixture's `scripts/upgrade.sh`
is a relative symlink to it. Editing the stub now means editing one
file. The driver's `cp -a` resolves the symlinks into the scratch
tree as expected.

**Portability constraint:** symlinks require a filesystem that
supports them. POSIX environments (Linux, macOS, WSL) work; native
Windows shells (cmd.exe, PowerShell on NTFS without
`mklink`-equivalent git config) may fail to materialise the
symlinks on checkout. The smoke-test fixtures are not intended to
run on native Windows; operators running the driver on Windows
should use real captured fixtures, not these examples.

Codenames are deliberately generic Greek letters (alpha / beta /
gamma) — no project identity leaks through. Operators running real
dogfood passes use their own codenames over their own fixtures
stored under `${HOME}/ref/dogfood/<codename>/<rc>/` and never
commit those.

## What each fixture contains

A minimal stub project: `TEMPLATE_VERSION` plus a no-op
`scripts/upgrade.sh` that accepts the driver's flags (`--target`,
`--verify`) and exits 0. This is enough to satisfy the driver's
fixture-validation step and exercise the report-emission path.

`delta/rc11/` additionally pre-places a hand-crafted
`.template-conflicts.json` containing one `accepted_local` and one
`conflict` entry (canonical shape, per `scripts/upgrade.sh:302`
writer and the snapshot fixture at
`tests/release-gate/snapshots/v1.0.0-rc12/with-accepted-local/
.template-conflicts.json`). It exercises the driver's jq-parse
branch — which alpha/beta/gamma do not, since the stub never writes
that file. Expected driver verdict for delta: FAIL with
`conflicts=1`, exit 1.

The stub deliberately does **not** accept `--dry-run`. The driver
never invokes it; the real `scripts/upgrade.sh` covers `--dry-run`
through its own smoke-test suite. Keeping unused flags out of the
stub avoids misleading "looks supported here too" signals.

The stub upgrade.sh deliberately does **not** clone upstream or
mutate the tree — these examples are smoke tests for the driver,
not regression tests for the real upgrade flow. Real regression
testing uses operator-supplied fixtures of actual downstream
projects.

## Usage

From the repo root, smoke-test the driver against any example:

```sh
tests/release-gate/dogfood-downstream.sh \
    --fixture tests/release-gate/dogfood-examples/alpha/rc8 \
    --upstream origin/main \
    --codename alpha
```

Expected: PASS, report written to `/tmp/dogfood-alpha-<ts>.txt`,
exit 0.

Drive the conflict-bearing case:

```sh
tests/release-gate/dogfood-downstream.sh \
    --fixture tests/release-gate/dogfood-examples/delta/rc11 \
    --upstream origin/main \
    --codename delta
```

Expected: FAIL with `conflicts=1` in the report, exit 1.

## Replacement protocol

When running a real dogfood pass:

1. `scripts/capture-dogfood-fixture.sh --from-url <op-only-url> --rc <state> --codename <op-chosen>`
2. Driver replays against `${HOME}/ref/dogfood/<codename>/<rc>/`.
3. The fixtures in this directory remain untouched — they are the
   driver's self-test, not a replacement for real downstream
   coverage.
