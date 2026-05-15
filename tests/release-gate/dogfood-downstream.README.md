<!--
SPDX-License-Identifier: MIT
Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
-->

# dogfood-downstream — driver + capture tooling

Two-stage dogfood harness for exercising `scripts/upgrade.sh` against
real downstream projects, *without* committing any project-identifying
information to this repo.

## Why

The pre-release gate (`scripts/pre-release-gate.sh`) and the spec-008
fixture-snapshot matrix cover the upgrade path against synthetic
trees. Real downstream projects accumulate idiosyncratic
customisations, accepted-local files, half-resolved conflicts,
out-of-date manifests, and so on, in ways the synthetic matrix does
not anticipate. The dogfood pass replays the upgrade against those
real trees and reports whether the template's upgrade story holds
up.

## Components

| Path | Role |
|---|---|
| `scripts/capture-dogfood-fixture.sh` | Operator-only. Clones a downstream repo, strips `.git/` + git/CI metadata, stores the content tree under `${HOME}/ref/dogfood/<codename>/<rc>/`. |
| `tests/release-gate/dogfood-downstream.sh` | Driver. Replays a stored fixture through `scripts/upgrade.sh --target <ref>` + `--verify` in a scratch clone; runs an AI TUI check phase against the upgraded fixture's hooks; emits a PASS/FAIL report. |
| `tests/hooks/run-ai-tui-check.sh` | AI TUI check sub-driver. Feeds session-shape payloads (`tests/hooks/fixtures/session-shapes.yml`) through the upgraded fixture's PreToolUse hooks (per its `.claude/settings.json`). Catches hook regressions that script-level checks miss (e.g. blocking commit-message HEREDOCs). |
| `tests/release-gate/dogfood-examples/` | Synthetic minimal fixtures (alpha / beta / gamma / delta) for smoke-testing the driver. Stubs are symlinks into `_shared/`. The delta fixture additionally ships hook scripts + `.claude/settings.json` so the AI TUI phase exercises its full path during driver smoke tests. |

## Requirements

- `git` (clone + init).
- POSIX `sh`, `find`, `cp -a`, `mktemp`.
- `jq` (recommended): used by the driver to parse
  `.template-conflicts.json` structurally. When absent the driver
  falls back to a tighter regex and prints a `WARN: jq not found`
  line in the report; precision drops slightly but the driver still
  runs.

## Workflow

```text
operator-only clone URL
        │
        ▼
scripts/capture-dogfood-fixture.sh        ← strips .git/, redacts codename
        │
        ▼
${HOME}/ref/dogfood/<codename>/<rc>/      ← operator-local; never committed
        │
        ▼
tests/release-gate/dogfood-downstream.sh  ← scratch-clones the fixture
        │                                   runs upgrade.sh + --verify
        │                                   captures git status + diffstat
        │                                   classifies conflicts
        │                                   runs AI TUI check on the
        │                                     upgraded fixture's hooks
        │                                     (skipped if fixture has
        │                                      no .claude/settings.json)
        ▼
/tmp/dogfood-<codename>-<ts>.txt          ← PASS/FAIL report; safe to share
```

## Safety properties

- **Originals untouched.** The driver `cp -a`'s the fixture into a
  `mktemp -d` scratch tree and operates only on the copy. The
  operator's `~/ref/dogfood/` tree is never written.
- **No URLs persisted.** The capture tool consumes `--from-url` once
  for the clone and never echoes it to logs or writes it to disk.
- **No project identity in reports.** Reports contain only the
  operator-supplied codename, paths under the scratch dir, and
  `TEMPLATE_VERSION` lines (which are framework version stamps, not
  project identity).
- **.gitignore protection.** The repo-local path `.dogfood-fixtures/`
  is gitignored — defensive guard against an operator accidentally
  staging a fixture into a working tree.

## Redaction discipline

Codenames are operator-chosen. Per the 2026-05-14 customer ruling on
examples/-class sensitivity inversion, **no project name appears in
any committed file** — only generic placeholders. Suggested
conventions:

- Greek letters: `alpha`, `beta`, `gamma`
- Generic nouns: `example-project`, `sample-downstream`
- Numbered: `dogfood-01`, `dogfood-02`

Avoid: customer names, vendor names, internal codenames, site names,
domain words that narrow the field of possible downstreams.

## Driver usage

```sh
tests/release-gate/dogfood-downstream.sh \
    --fixture ${HOME}/ref/dogfood/alpha/rc11 \
    --upstream origin/main \
    --codename alpha \
    --out /tmp/my-dogfood-run.txt
```

Exits 0 on PASS, 1 on FAIL, 2 on arg / fixture validation error.
PASS requires: upgrade exit 0, `--verify` exit 0, and no entries
classified `"conflict"` in `.template-conflicts.json`.

`--upstream` accepts anything `scripts/upgrade.sh --target` accepts
(tag, branch, commit SHA) thanks to the untagged-target feature.

## Capture usage

```sh
scripts/capture-dogfood-fixture.sh \
    --from-url <op-only-url> \
    --rc rc11 \
    --codename alpha
```

Defaults the destination to `${HOME}/ref/dogfood/alpha/rc11/`.
Existing destinations are rejected — remove first or pick a different
`--out`.

### Optional flags

- `--ref <name>` — clone a specific tag or branch instead of the
  source URL's default branch. Passed to `git clone --branch`, which
  accepts both. Useful when the downstream's default branch isn't
  the rc you want to capture.
- `--verbose` — print one line per scrub-step path (kept or
  removed). Default behaviour is silent.

### What the capture tool scrubs

Always removed from the snapshot before it lands at the destination:

| Path | Why |
|---|---|
| `.git/` | full history; the snapshot is content, not history |
| nested `.git` files | submodule pointer files (defensive) |
| `.gitattributes` | may carry org-specific normalisation rules |
| `.gitmodules` | leaks submodule URLs / org identifiers |
| `.github/` | workflow YAML often hard-codes org/repo URLs |
| `.git-credentials` | defensive; should never be present, scrubbed if so |

**Operator responsibility:** any other identifying metadata that may
have crept into the source tree (custom `.dockerignore` comments
mentioning the repo, CI runner labels, dotfile configs embedding
org/repo URLs, lockfile registry URLs that name a private mirror,
etc.) is NOT auto-scrubbed. Inspect the destination tree before
sharing reports outside your machine.

## Smoke-testing the driver

The synthetic fixtures under `tests/release-gate/dogfood-examples/`
exist solely to exercise the driver's control flow. They are NOT
representative of real downstream projects:

```sh
tests/release-gate/dogfood-downstream.sh \
    --fixture tests/release-gate/dogfood-examples/alpha/rc8 \
    --upstream origin/main \
    --codename alpha
```

Expected: PASS, exit 0. If this fails, the driver is broken before
you ever get to real fixtures.
