---
name: fw-adr-0015-upgrade-orchestrator-stub-model
description: scripts/upgrade.sh becomes a stable sub-100-line stub on the downstream tree; the real upgrade orchestrator is fetched fresh per invocation from upstream. Foundational ADR for the upgrade-flow rearchitecture; supersedes FW-ADR-0010 and FW-ADR-0013, partially supersedes FW-ADR-0014.
status: accepted
date: 2026-05-15
---


# FW-ADR-0015 — Upgrade orchestrator stub model (out-of-tree runner)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: stable stub + network-fetched runner](#option-m--minimalist-stable-stub--network-fetched-runner)
  - [Option S — Scalable: current model with content-addressed migration discovery + per-cliff downloaded runner](#option-s--scalable-current-model-with-content-addressed-migration-discovery--per-cliff-downloaded-runner)
  - [Option C — Creative: no driver shipped at all (curl|bash with pinned-checksum gate)](#option-c--creative-no-driver-shipped-at-all-curlbash-with-pinned-checksum-gate)
- [Decision outcome](#decision-outcome)
  - [Customer ruling (verbatim)](#customer-ruling-verbatim)
- [Interface decisions (binding)](#interface-decisions-binding)
  - [Stub CLI surface (frozen across v1.x)](#stub-cli-surface-frozen-across-v1x)
  - [Stub-to-runner fetch protocol](#stub-to-runner-fetch-protocol)
  - [Runner discovery rules](#runner-discovery-rules)
  - [Integrity verification posture](#integrity-verification-posture)
  - [Failure modes and operator recovery](#failure-modes-and-operator-recovery)
  - [Backward-compat shim contract](#backward-compat-shim-contract)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Migration path forward](#migration-path-forward)
- [Relationship to other ADRs and issues](#relationship-to-other-adrs-and-issues)
- [Verification](#verification)
- [Implementation notes for software-engineer](#implementation-notes-for-software-engineer)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). This is a **foundational ADR**;
its acceptance unblocks a sequenced family of follow-up ADRs
(FW-ADR-0016 through FW-ADR-0019) that detail the project-state
schema, file-keyed migration discovery, the migration path for
already-deployed downstreams, and the formal retirement of the
pre-bootstrap class.

---

## Status

- **Proposed: 2026-05-15**
- **Accepted: 2026-05-15**
- **Deciders:** `architect` + `tech-lead` + customer (cross-cutting
  pattern change to the upgrade contract; lock-in choice to a
  network-fetch model; customer approval required per CLAUDE.md
  Hard Rules)
- **Consulted:** `process-auditor` (parallel paired-dispatch report,
  `docs/pm/upgrade-flow-process-debt-2026-05-15.md`), prior
  `architect-conceptual` dispatch
  (`docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`),
  FW-ADR-0010 (pre-bootstrap interface this ADR retires),
  FW-ADR-0013 (rc-to-rc pre-bootstrap class this ADR moots),
  FW-ADR-0014 (preservation/manifest split this ADR partially
  supersedes), `security-engineer` (integrity-verification posture;
  this ADR frames the threat model for downstream review),
  `sre` + `release-engineer` (network-dependency / air-gapped
  operator question; flagged below as a follow-up driver).

## Context and problem statement

Every "fix" landed for an upgrade-class regression in 2026-05 has
patched the layer one step deeper than the framework's current
structure naturally supports. Q-0017 fixed self-overwrite in
`migrations/v0.14.0.sh`; the failure recurred rc2 → rc12. FW-ADR-0013
added a cloned `migrations/v1.0.0-rc13.sh` with the same body; the
migration is unreachable because discovery walks `git tag -l 'v*'`
and no rc13 tag exists. FW-ADR-0014 patched the runtime preservation
classifier, but the failing manifest was synthesised earlier by
v0.14.0 and never re-baked. PR #186 taught a newer `upgrade.sh`
about untagged `--target`, but the `upgrade.sh` on disk in the field
is still the rc3..rc11 version that does not know the new flag.
Four merged blockers, zero PASSes on re-dogfood, and the new failure
modes are not the same as the old ones. This is the signature of a
category error, not a list of bugs.

The conceptual mistake is structural. The framework treats
`scripts/upgrade.sh` as a *file* that the template ships, when it is
in fact a *runtime* that the project hosts. Every other shipped file
can be upgraded by the running upgrade.sh because the running
upgrade.sh is not the one being upgraded. `scripts/upgrade.sh` is the
one file whose old version on disk is doing the work of replacing
itself with the new version on disk — and that work is being driven
by exactly the version we are trying to retire. The pre-bootstrap
migration concept (FW-ADR-0010, FW-ADR-0013) is a workaround for
this: ship the new driver via the old driver's migration runner, on
the theory that the old driver will reach the migration runner before
its sync loop touches `upgrade.sh`. But the migration runner itself
lives in the old driver, uses the old driver's enumeration logic
(`git tag -l 'v*'`), the old driver's target-resolution flag set,
and the old driver's structural assumptions about file format. We do
not control any of those at the moment the upgrade starts. We control
them only after the upgrade has finished — and the upgrade cannot
finish until they cooperate. The parallel `process-auditor` dispatch
reached the same conclusion via independent evidence
(`docs/pm/upgrade-flow-process-debt-2026-05-15.md`).

ADR-trigger rows that fire: major refactor that changes a public
boundary (the entire `scripts/upgrade.sh` contract); new external
dependency (the network fetch at upgrade time); cross-cutting pattern
change (the upgrade-flow concept itself); choice that locks the
framework into a fetch model that would be expensive to reverse;
change touching a customer-flagged critical path (upgrade is, per
customer ruling, "always buggy" and therefore quality-gated highest).

## Decision drivers

- **Customer's standing rule: "dogfood before cutting an rcX"**
  (binding, 2026-05). The current tag-keyed migration-discovery model
  is in direct tension with this rule: the rc-cutting ritual requires
  running the not-yet-tagged migrations against not-yet-existing
  tags. The structure-fix here must honour the rule by construction.
- **Customer's standing rule: "upgrade is always buggy"** (binding).
  Quality bar on the upgrade-flow design is raised; the model must
  reduce surface area, not add to it.
- **Recurring-failure pattern, dogfooded.** Every recent upgrade
  regression traces to the orchestrator's dual role as a managed
  artefact AND the manager. Symptoms include self-overwrite mid-
  execution, pre-bootstrap as workaround, `--target` semantics
  fragmenting because old orchestrators cannot parse new flags,
  manifest-vs-preserve-list disagreement persisting because the
  orchestrator is too far from the manifest writer, and rc-cliffs
  spawning more migrations to patch the orchestrator itself.
- **Industry precedent.** Every comparable self-update system
  (rustup, asdf, nvm, brew, apt, pyenv, the Cargo/Go-toolchain
  installers) treats the updater as out-of-band from the artefacts it
  manages. The framework has been swimming against this pattern; the
  swim has not paid off.
- **Customer's ruling 2026-05-15 (verbatim, captured below).** The
  out-of-tree orchestrator path is the chosen direction. Migration
  path is S (one transitional rc bridge); detail belongs in
  FW-ADR-0018, not this ADR.
- **Air-gapped operator population — ruled out of scope.** Customer
  ruling 2026-05-15 (`CUSTOMER_NOTES.md` L323): "air gapped operators
  will have to figure it out on their own. the only current user of
  this template is me." Network-fetch at upgrade time is the
  framework-supported path; air-gap is an operator-implementable
  footnote (pre-fetched runner archive, internal-mirror URL), not a
  framework deliverable. The forward-looking failure signal in
  §Verification re-opens this if the downstream population grows
  and the constraint surfaces.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: stable stub + network-fetched runner

The downstream project hosts a thin, stable shim (`scripts/upgrade.sh`,
sub-100 lines, frozen API/CLI surface for the v1.x line) whose only
job is to fetch the upstream runner for the requested target and
exec it with the operator's arguments. The runner
(`scripts/upgrade-runner.sh` upstream) is fetched fresh per invocation,
not persisted to the project tree. The runner carries the migration
queue (`migrations/v*.sh`), manifest, schema definitions, and
everything else that today lives in the project's `scripts/lib/`
tree. The project owns a single state artefact
(`TEMPLATE_STATE.json`, schema defined in FW-ADR-0016) capturing the
upstream ref, per-path declarations
(`managed`/`customised`/`project-owned`), and per-managed-path
content hashes at the last sync. The runner reads it at sync entry,
writes it at sync exit.

- **Sketch:** Stub is sub-100 lines; reads `--target` / `--dry-run`
  / `--verify` / `--help`; resolves upstream URL from
  `SWDT_UPSTREAM_URL` (default `https://github.com/occamsshavingkit/
  sw-dev-team-template`); fetches the runner at the requested ref
  via `git archive` over `https` (or equivalent fetch — `curl` of
  the raw blob URL works as a fallback); verifies integrity against
  a checksum pinned in the project (or `--no-verify` for development);
  exec's the runner. Stub exits with the runner's exit code.
- **Pros:**
  - The self-overwrite problem dissolves: nothing is overwriting
    itself, because the running runner came from the network for
    this invocation only.
  - The migration-discovery problem dissolves: the runner that
    discovered the migrations is the same runner that knows the full
    target's migration set, by file presence in `migrations/`, not by
    tag enumeration. Customer's "no tag before PASS" rule is honoured
    by construction.
  - The untagged-target problem dissolves: the runner's CLI surface
    is the new surface, because the runner is current by construction.
  - Pre-bootstrap retires (FW-ADR-0010, FW-ADR-0013 supersede);
    the stub does not self-mutate.
  - Manifest-vs-preservation contradictions become syntactically
    impossible once `TEMPLATE_STATE.json` (FW-ADR-0016) is the single
    source of truth.
  - Dogfooding works against `main` without cutting an rc tag, because
    the runner is fetched by ref, not by tag.
  - Industry-standard pattern; operators recognise the shape.
- **Cons:**
  - Network dependency at upgrade time. Air-gapped operators are
    **out of scope as a framework-supported requirement** per
    customer ruling 2026-05-15 (`CUSTOMER_NOTES.md` L323): "air
    gapped operators will have to figure it out on their own. the
    only current user of this template is me." Air-gap support
    remains an operator-implementable footnote (pre-fetched runner
    archive + `SWDT_PRESTAGED_RUNNER=<path>`, or internal-mirror
    URL via `SWDT_UPSTREAM_URL`), not a framework deliverable. The
    forward-looking failure signal in §Verification (operator
    filings naming network-dependency as a blocker for an unknown
    population segment) is preserved as a re-open trigger.
  - Integrity-verification posture is locked at the customer's
    floor per ruling 2026-05-15 (`CUSTOMER_NOTES.md` L348): "TLS
    and checksum will be plenty." `security-engineer` review of
    the implementation-ADR section remains the binding gate and
    may surface a stronger posture, but the baseline is fixed; no
    open question.
  - Transition cost: every currently-deployed downstream needs a
    one-time retrofit to install the new stub. Cost analysis lives
    in FW-ADR-0018 (the customer's chosen migration path S).
- **When M wins:** when the failure pattern is structural (it is) and
  no operationally-binding constraint forces in-tree code (the open
  air-gap question is the one remaining check). Customer's ruling
  endorses this path conditionally on the air-gap question being
  resolvable.

### Option S — Scalable: current model with content-addressed migration discovery + per-cliff downloaded runner

Keep `scripts/upgrade.sh` project-shipped, but make migration
discovery content-addressed (file presence in `migrations/` semver-
sorted against the project's `TEMPLATE_VERSION`, never against
`git tag -l`). Each structural cliff in `upgrade.sh` spawns a
downloaded "cliff runner" — a one-shot script fetched from upstream
that handles the self-rewrite atomically. Pre-bootstrap stays as a
distinct concept but its tag-keyed discovery is replaced with file-
presence discovery.

- **Sketch:** `scripts/upgrade.sh` keeps its current role but its
  migration enumeration switches to walking
  `$WORKDIR_NEW/migrations/v*.sh` by file presence. Each migration
  that mutates `upgrade.sh` structurally also fetches a cliff runner
  via curl, verifies its checksum, and exec's it for the self-replace
  step. The cliff-runner shape is stable; the migration body that
  triggers it is per-cliff.
- **Pros:**
  - Resolves the rc13-tag-unreachable bug without changing the
    overall model.
  - No new operator-facing surface (no stub/runner split to learn).
  - Air-gapped operators only need network when a cliff migration
    actually fires; non-cliff upgrades remain in-tree.
  - Smaller blast radius if the structural change misfires.
- **Cons:**
  - Does not address the orchestrator-self-mutation root cause; it
    relocates the cliff-fix from "pre-bootstrap migration" to
    "downloaded cliff runner". Same shape, different name.
  - Every future structural cliff still spawns a one-shot artefact;
    the cliff inventory keeps growing.
  - The orchestrator on disk still has to understand its own future
    versions' command-line surface for non-cliff upgrades.
  - The three-source-of-truth problem (`.template-customizations`,
    `TEMPLATE_MANIFEST.lock`, migration queue) is not addressed
    here; would need a separate ADR with broadly the same scope as
    FW-ADR-0016.
  - "Same model with smarter discovery" is what we tried in PR #186;
    the failure pattern survived the smarter discovery.
- **When S wins:** if the customer rejects the network-fetch model
  outright for air-gap reasons and the team is willing to absorb the
  per-cliff cost indefinitely.

### Option C — Creative: no driver shipped at all (curl|bash with pinned-checksum gate)

The project ships no upgrade driver of any kind. Operators run
upgrades via a one-liner: `curl -fsSL <upstream>/scripts/upgrade-runner.sh
| SHA=<pinned> sh -s -- --target <ref>`. The pinned checksum lives
in the project's `TEMPLATE_VERSION` or a sibling pin file; the
one-liner's prelude verifies it before exec. There is no
`scripts/upgrade.sh` in the project tree at all.

- **Sketch:** Operator documentation includes the one-liner. Project
  tree contains only the pin file. Each rc release publishes a
  fresh runner and its checksum. The pin file is updated on each
  upgrade.
- **Pros:**
  - Zero project-owned upgrade surface.
  - Maximum simplicity: no stub, no shim, no pre-bootstrap, no
    cliff runners.
  - Forces operators to engage with the upgrade as a deliberate act
    rather than a "run the script" muscle-memory.
- **Cons:**
  - `curl | bash` is a well-known anti-pattern in operator culture
    even when checksum-gated. Trust posture is harder to argue.
  - No stable place for project-specific upgrade hooks if the
    framework ever needs them.
  - CI / dogfood harnesses lose their familiar `scripts/upgrade.sh`
    entrypoint; every consumer of that path updates simultaneously.
  - No graceful path for `--dry-run` / `--verify` operations that
    feel "local" to the project — every invocation hits the
    network.
  - The one-liner is harder to wrap in a Makefile / CI step than a
    sub-100-line stub; the stub is essentially the same code, on
    disk, easier to audit.
- **When C wins:** if the framework wanted to commit hard to
  "operators are sophisticated; the upgrade is an explicit act" and
  could accept the one-liner culture cost. This framework's operator
  profile (templated downstream projects, often opened by less-
  experienced contributors) does not match.

## Decision outcome

**Chosen option: M (stable stub + network-fetched runner).**

**Reason:** Option M is the only option that dissolves the
orchestrator-self-mutation root cause rather than relocating it.
Option S preserves the conceptual mistake the dogfood evidence
identified; "smarter discovery within the same model" was tried in
PR #186 and the failure pattern survived. Option C is structurally
adjacent to M but trades a project-owned stub for a `curl | bash`
one-liner that does not fit the framework's operator profile. Option
M maps onto established industry precedent (rustup/asdf/nvm shape),
honours the customer's "dogfood before cutting an rc" rule by
construction (file-keyed migration discovery removes the tag
precondition), and reduces ongoing per-rc cliff cost to zero once
the transition (FW-ADR-0018) completes. The network-fetch dependency
is the one binding cost; the air-gap question is ruled out of scope
per customer 2026-05-15 (`CUSTOMER_NOTES.md` L323), and the security
posture is locked at TLS + checksum per customer 2026-05-15
(`CUSTOMER_NOTES.md` L348).

### Customer ruling (verbatim)

> "yes, let's make it a stub." — customer, 2026-05-15.

Customer additionally ruled that the migration path for currently-
deployed downstreams is option S (one transitional rc bridges
existing downstreams onto the stub model). That decision is the
subject of FW-ADR-0018 and is **not** detailed in this ADR; only the
dependency is named here.

## Interface decisions (binding)

### Stub CLI surface (frozen across v1.x)

`scripts/upgrade.sh` is the project-owned stable shim. Its CLI
surface freezes here for the v1.x line; changes require a new
foundational ADR.

| Flag                 | Semantics                                                        |
|----------------------|------------------------------------------------------------------|
| `--target <ref>`     | Upstream ref to fetch the runner from. Tag, branch, or short / full SHA. Default: latest stable tag (per current `upgrade.sh` default-resolution behaviour). The stub does **not** interpret the ref beyond passing it through; the runner resolves it. |
| `--dry-run`          | Pass-through. The stub fetches the runner and execs it with `--dry-run` appended. The runner performs the dry-run logic; the stub does not. |
| `--verify`           | Pass-through. The stub fetches the runner at the project's currently-stamped ref and execs it with `--verify`. `--verify` MUST work without a `--target` (it verifies against the project's recorded state). |
| `--help`, `-h`       | Print stub-local usage (the table above) and exit 0. Does **not** fetch the runner. |
| `--no-verify`        | Stub opt-out for integrity verification. Development-only; emits a `WARN` line; otherwise unchanged. |
| `--`                 | Standard "stop parsing flags" terminator. Everything after `--` is forwarded verbatim to the runner. |

**Legacy flag footnote:** The legacy flags `--resolve` and
`--self-test-semver` (live in the rc-era `scripts/upgrade.sh` usage
block and exercised by `scripts/smoke-test.sh:462`) are **not** part
of the stub's frozen surface. They forward verbatim to the runner
per the [Backward-compat shim contract](#backward-compat-shim-contract);
the runner owns their semantics (accept, reject, or deprecate). The
freeze table above enumerates only the stub-interpreted surface; any
other flag (legacy or future) is unknown to the stub and forwards.

**Forbidden in the stub:** the stub MUST NOT parse, interpret, or
gate on any flag not in the table above. Unknown flags are forwarded
to the runner verbatim. The stub MUST NOT carry per-version logic,
migration knowledge, manifest parsing, or schema awareness. The stub
exits with the runner's exit code; the runner owns the exit-code
semantics defined in FW-ADR-0014 (and any successor ADR).

**Sub-100-line budget.** The stub MUST fit in under 100 lines of
shell, exclusive of comments and the SPDX header. This is a hard
budget. If the stub grows past 100 lines, the growth IS the signal
that orchestration logic has leaked back into the stub; the fix is
to move the logic into the runner, not to raise the budget.

### Stub-to-runner fetch protocol

1. **Resolve upstream URL.** From `SWDT_UPSTREAM_URL` env var if set;
   otherwise from a pinned constant in the stub (default:
   `https://github.com/occamsshavingkit/sw-dev-team-template`).
2. **Resolve target ref.** From `--target <ref>` if present;
   otherwise default-target logic (mirror current `upgrade.sh`
   default: latest stable tag for stable projects, latest tag for
   pre-release projects). The stub resolves the default; once the
   runner is fetched, the runner owns all subsequent ref handling.
3. **Fetch the runner.** Architect picks the fetch mechanism. The
   recommended baseline is a `curl -fsSL` of the raw blob URL
   (`https://raw.githubusercontent.com/<owner>/<repo>/<ref>/scripts/upgrade-runner.sh`)
   into a temp file; rejected alternative is a full `git clone --
   depth=1` (10–100× the bandwidth, no observable benefit for the
   single-file fetch case). `software-engineer` MAY refine the
   choice during implementation if a measured constraint surfaces;
   the runner-discovery semantics below are independent of the
   chosen mechanism.
4. **Verify integrity.** See [Integrity verification posture](#integrity-verification-posture)
   below. If verification fails, the stub refuses with a non-zero
   exit code (10, distinct from runner exits) and does not exec.
5. **Exec the runner.** The stub `exec`s the runner with all
   forwarded arguments. The stub does not survive the exec; the
   runner owns the rest of the process.

The temp-file lifetime is bounded by the exec; the stub does not
need to clean it up because exec replaces the process. If
verification fails before exec, the stub cleans up the temp file
before exit. The runner MUST NOT be persisted to any project-tree
path; on the next invocation, a fresh fetch happens.

### Runner discovery rules

The runner is discovered by **upstream URL + ref**, not by tag
enumeration, not by content-addressed hash chain, not by registry
lookup. The discovery is exactly the URL composed from the upstream
URL and the resolved ref. This is the binding rule that retires the
tag-enumeration model.

The runner's *internal* migration discovery (`migrations/v*.sh`) is
the subject of FW-ADR-0017 (file-keyed, semver-ordered against
`TEMPLATE_STATE.json`). This ADR does not pin FW-ADR-0017's shape; it
names the dependency.

### Integrity verification posture

Threat model framed for `security-engineer` review:

- **Hostile upstream:** Out of scope. Operators trust their upstream
  URL by construction; the URL is configured in the project at
  scaffold time and changes via deliberate operator action. The
  framework cannot defend against an operator who points at a
  hostile clone of itself. This matches the trust posture of
  rustup/asdf/nvm.
- **MITM on the fetch:** In scope. TLS via the upstream URL's
  scheme defends. The stub MUST refuse non-`https` upstream URLs
  unless `--no-verify` is set (development opt-out).
- **Tampering at rest at the upstream:** In scope to the extent that
  the framework provides a per-ref checksum pin. The recommended
  posture is:
  1. The project's `TEMPLATE_STATE.json` (FW-ADR-0016) carries the
     runner checksum that was verified on the last successful
     upgrade. Subsequent runs against the same ref MUST match.
  2. Cross-ref upgrades (operator advances `--target`) accept the
     fetched runner unconditionally on the first run and pin the
     observed checksum for future runs against that ref. **This is
     TOFU (Trust-On-First-Use):** the first fetch against a new ref
     trusts the upstream; subsequent fetches verify against the pin
     recorded in `TEMPLATE_STATE.json`. The customer ruled
     2026-05-15 (`CUSTOMER_NOTES.md` L348) that this posture
     ("TLS and checksum will be plenty") is acceptable; the TOFU
     window is an explicit, accepted cost of the baseline.
  3. `--no-verify` opts out of checksum pinning entirely;
     development-only, emits a `WARN`.
- **Pinned-checksum file alternative:** A separate `RUNNER_PINS`
  file at project root, mapping refs to checksums, is the rejected
  alternative; rejected because it duplicates content
  `TEMPLATE_STATE.json` will already carry, and because per-ref
  pins encourage operators to hand-edit pins to silence
  verification failures (the very behaviour the gate is supposed
  to surface).
- **Signed manifest alternative:** GPG / cosign signature on the
  runner is the more-secure-but-more-operationally-heavy
  alternative; deferred to a future ADR if and when the threat
  model justifies it. This ADR's posture (TLS + checksum pinning
  in `TEMPLATE_STATE.json`) is the minimum-viable security posture
  for the recommended fetch mechanism.

`security-engineer` review is the binding gate on this section
before the implementation ADR (FW-ADR-0015-impl) ships. If the
review surfaces a stronger posture (e.g., signature required),
that posture supersedes the recommended baseline above without a
fresh foundational ADR; the change records as a security-posture
amendment to this ADR.

### Failure modes and operator recovery

| Failure                                        | Stub behaviour                                                                                | Operator recovery |
|------------------------------------------------|-----------------------------------------------------------------------------------------------|-------------------|
| Network unreachable                            | Refuse with exit 11, stderr message naming the unreachable URL.                               | Restore network; re-run. Air-gapped operators are out of scope per customer ruling 2026-05-15 (`CUSTOMER_NOTES.md` L323); the operator-implementable workaround is `SWDT_PRESTAGED_RUNNER=<path>` or an internal-mirror `SWDT_UPSTREAM_URL`, but neither is a framework-supported path. |
| Runner not found at target ref (HTTP 404 / equivalent) | Refuse with exit 12, stderr message naming the ref and URL.                          | Operator re-specified `--target` to a valid ref. Common cause: typo, force-pushed branch, deleted tag. |
| Integrity verification failed                  | Refuse with exit 10, stderr message naming the expected and observed checksums.               | Operator investigates (legitimate upstream change, MITM, local tampering). `--no-verify` is the explicit escape hatch; emits WARN. |
| Legitimate runner update (upstream re-published at moving ref) | Refuse with exit 10; the pin in `TEMPLATE_STATE.json` no longer matches because the upstream content at the moving ref has advanced. | Operator runs `scripts/upgrade.sh --refresh-pin <target>` (or the equivalent re-pin path defined in FW-ADR-0015-impl / FW-ADR-0016) to re-pin against the new content. Without a documented re-pin workflow, operators reflexively reach for `--no-verify` and the pin becomes ceremonial; the re-pin path is therefore part of the binding interface. |
| Stub itself corrupted / missing                | Operator cannot run the stub; nothing to do at runtime.                                       | Re-install the stub via the retrofit path (FW-ADR-0018). The retrofit path is a single curl one-liner that writes the stub atomically. |
| Runner exits non-zero                          | Stub propagates the runner's exit code verbatim.                                              | Operator follows the runner's documented recovery path for that exit code. |

Exit code namespace split:

- Codes 0, 1, 2 are owned by the runner (per FW-ADR-0010 +
  FW-ADR-0014 inheritance — these contracts move INTO the runner;
  see Relationship section).
- Codes 10, 11, 12 are owned by the stub (verification, network,
  runner-not-found). They precede any runner exec.
- Codes 3–9 reserved; do not assign without a new ADR.
- Codes 13+ reserved for future stub-level conditions.

**Stub does not interpret runner exit codes.** Once the stub `exec`s
the runner, the stub is gone — the runner's exit code IS the process
exit code, byte-for-byte. The stub interprets ONLY its own
self-emitted codes 10/11/12 (which fire **before** exec, when the
fetch / verify / discovery step refuses). Everything the runner
emits — including codes 0/1/2, the currently-reserved 3–9 range, and
any future runner-owned codes — passes through verbatim to the
caller without stub-side interpretation, mapping, or rewriting. The
reserved 3–9 range is reserved at the **framework** level for future
runner-owned use, not at the stub level. If a future ADR assigns
semantics to a code in that range, the stub does not change; the
runner emits, the stub is already gone.

### Backward-compat shim contract

For projects that retrofit to the stub model via FW-ADR-0018, the
stub MUST accept the legacy flag set
(`--resolve`, `--self-test-semver`, any flag listed in the current
`scripts/upgrade.sh` usage block) by forwarding it to the runner
verbatim. The runner is responsible for accepting or rejecting
legacy flags; the stub is not the place to deprecate them. This
keeps the retrofit cost down to "swap the stub", without operator
muscle-memory regressing.

Env-var pass-through: the stub passes its environment to the runner
unmodified. `SWDT_UPSTREAM_URL`, `SWDT_PRESTAGED_WORKDIR`,
`SWDT_BOOTSTRAPPED`, `SWDT_PREBOOTSTRAP_FORCE`,
`SWDT_PRESERVATION_FORCE`, `GH_TOKEN`, and any future `SWDT_*`
variables remain readable by the runner. The stub MUST NOT consume
or rewrite any of them; the only env-var the stub may read is
`SWDT_UPSTREAM_URL` (for fetch-URL resolution). Pre-bootstrap-class
env vars (`SWDT_PREBOOTSTRAP_FORCE`) are passed through but become
no-ops in the runner per FW-ADR-0019 once that ADR lands.

## Consequences

### Positive

- **The recurring-failure pattern dissolves.** Every recent upgrade
  regression (self-overwrite, untagged-target parsing, manifest-vs-
  preserve-list, rc-cliff cost) is a symptom of the orchestrator's
  dual role; removing the dual role removes the symptom class.
- **Dogfood against `main` works without an rc tag.** File-keyed
  migration discovery (FW-ADR-0017) plus ref-keyed runner discovery
  honour the customer's "no tag before PASS" rule by construction.
- **Pre-bootstrap retires.** FW-ADR-0010 and FW-ADR-0013 supersede;
  the entire pre-bootstrap class (and its operator-facing surface —
  `SWDT_PREBOOTSTRAP_FORCE`, `.template-prebootstrap-blocked.json`,
  `Gate=pre-bootstrap` audit rows) becomes a deprecation tail per
  FW-ADR-0019.
- **`.template-customizations` folds away.** FW-ADR-0016's
  `TEMPLATE_STATE.json` absorbs preservation declarations alongside
  the manifest, removing the two-source-of-truth class the
  `process-auditor` flagged.
- **Cliff-class cost drops to zero.** Future structural changes to
  the upgrade runner are made in the runner, not in the project
  tree; no per-cliff migration is required.
- **Industry-standard shape.** Operators recognise the stub-and-
  runner pattern; the framework stops being unusual along this axis.
- **Stub is auditable.** Sub-100 lines, frozen surface — the stub
  is the smallest piece of upgrade-flow code the framework ships.

### Negative / trade-offs accepted

- **Network dependency at upgrade time.** Every upgrade fetches.
  Air-gapped operators need an offline path; open question routed
  to `sre` + customer (see below). The minimum-viable offline path
  is "pre-fetch the runner to a local file and set
  `SWDT_PRESTAGED_RUNNER=<path>`"; the recommended path is a
  documented internal-mirror URL configured via
  `SWDT_UPSTREAM_URL`. Both fall within the architect-owned design
  surface; the customer rules on which path becomes default.
- **Transition cost.** Currently-deployed downstreams (every
  v1.0.0-rc* project, plus any v0.x project not yet upgraded) need
  a one-time stub retrofit. Detail in FW-ADR-0018; the customer's
  ruling pins migration path S (one transitional rc bridge).
- **Operator trust posture must be made explicit.** TLS + checksum
  pinning is the recommended baseline; the framework can no longer
  pretend "the upgrade is just running a local script". Operator
  documentation grows a "network trust" section;
  `security-engineer` reviews before implementation lands.
- **Diagnostics surface area grows.** The stub introduces three new
  failure modes (exit 10/11/12) that did not exist in the pure-
  in-tree model. Documentation must cover them; the runner's exit
  codes 0/1/2 keep their existing semantics inherited from
  FW-ADR-0010 / FW-ADR-0014 (the inheritance is by *being moved
  into the runner*, not by the stub re-implementing them).
- **`--verify` semantics need explicit definition once the runner
  is fetched per-invocation.** "Does the project match its
  recorded state?" is the rule; the runner reads
  `TEMPLATE_STATE.json` and reports. Verifies do not mutate state.
  This is a re-affirmation, not a change.
- **Downstreams that skip the bridging rc (FW-ADR-0018) are
  unreachable.** The stub model is reachable from any downstream
  that runs the FW-ADR-0018 transitional rc at least once. A
  downstream that tries to jump from a pre-bridge rc (e.g.,
  v1.0.0-rc11) directly to a post-bridge release (v1.1.0+) lands
  on an `upgrade.sh` it cannot self-replace; the framework has no
  remediation path for that downstream other than re-running the
  transitional rc. This is a structural cost of the bridging
  model. At ADR acceptance the customer is the only known
  downstream user, bounding operational impact today, but the ADR
  is foundational and will outlive that fact.
- **Stub-format v2.0 migration story is unsolved.** The stub CLI
  surface freezes across v1.x by construction (a change requires a
  new foundational ADR). When the stub format itself needs to
  evolve at v2.0 or later — new flag, new fetch protocol, new
  integrity posture — the same orchestrator-self-mutation problem
  this ADR dissolves re-applies to the stub. The implicit answer
  is "the stub is small enough that operators swap it via a
  retrofit one-liner, the way FW-ADR-0018 does for v1.x," but
  that answer is not pinned. A hypothetical FW-ADR-NNNN (post-v1.x)
  will need to address the v1.x → v2.x stub migration. Deferred,
  not solved.
- **Runner-calling-back-into-stub is an architectural lock.** The
  stub deliberately does nothing the runner could need: it `exec`s
  the runner and is gone. Any future ADR proposing the runner call
  back into the stub (e.g., for a `--version` reflection, a
  `--self-update` invocation, a stub-emitted progress callback) IS
  a proposal to re-introduce the dual-role pattern this ADR
  dissolves; it SHOULD be REJECTED on principle. The sub-100-line
  budget plus the §"Forbidden in the stub" clause are the
  structural defences; the verification section's line-budget
  failure signal catches leakage at review time. Future architects
  reading this ADR: the temptation to "just expose this one
  thing in the stub" IS the failure mode the budget defends
  against.

### Follow-up ADRs

- **FW-ADR-0016 — `TEMPLATE_STATE.json` schema.** Defines the
  single project-owned state artefact, the migration shape from
  `(TEMPLATE_VERSION, TEMPLATE_MANIFEST.lock,
  .template-customizations)` into it, schema-version field,
  forward-compat rules. `architect` drafts; `qa-engineer`
  consulted; `tech-writer` polishes.
- **FW-ADR-0017 — File-keyed migration discovery.** Replaces
  `git tag -l 'v*'` enumeration with file-presence discovery in
  the runner's `migrations/` directory, semver-ordered against
  `TEMPLATE_STATE.json`'s recorded ref. `architect` owns;
  depends on FW-ADR-0015 + FW-ADR-0016.
- **FW-ADR-0018 — Migration path for currently-deployed
  downstreams.** Three-Path Rule re-runs at this granularity;
  customer's standing ruling is option S (one transitional rc
  bridge — the bridging rc ships an `upgrade.sh` that, on first
  run, installs the new stub atomically, then re-execs as the
  stub). `architect` + `release-engineer`; depends on
  FW-ADR-0015 + FW-ADR-0016.
- **FW-ADR-0019 — Pre-bootstrap retirement.** Formal supersession
  of FW-ADR-0010 + FW-ADR-0013; their interface surfaces become
  documented no-ops with one-time deprecation warnings. `architect`
  owns; depends on FW-ADR-0015 (the stub model is what makes pre-
  bootstrap unnecessary).

The sequence is binding: FW-ADR-0016 must close before FW-ADR-0017
can be drafted (the file-keyed discovery references the state
artefact's schema); FW-ADR-0018 must close before any
implementation work begins on the stub (the implementation ships
together with the bridging rc); FW-ADR-0019 must close before the
pre-bootstrap interface surfaces are removed from documentation.

## Migration path forward

Detail lives in FW-ADR-0018 (not yet drafted). The customer's
standing ruling 2026-05-15 pins the migration path to **option S
(one transitional rc bridge)**. The shape, by name only:

- One additional in-tree rc is cut. Its `scripts/upgrade.sh`
  carries both the legacy upgrade body AND, as a final migration
  step, atomically installs the new stub. Operators who run that
  rc transition through it once; afterwards, they are on the stub
  model.
- The bridge rc is the last `upgrade.sh` the framework ships in the
  v1.x line. From the next rc onward, `scripts/upgrade.sh` IS the
  stub.

This ADR does **not** specify the bridging-rc's content or
operator UX; that is FW-ADR-0018's mandate. The dependency is
named here so readers know the migration story exists.

## Relationship to other ADRs and issues

### Supersedes (full)

- **FW-ADR-0010 (pre-bootstrap respects local edits).** The entire
  pre-bootstrap concept retires under the stub model. The stub does
  not self-mutate; nothing requires the 3-SHA matrix, the block
  artefact, the `SWDT_PREBOOTSTRAP_FORCE` env var, or the `Gate=pre-
  bootstrap` audit-log row. FW-ADR-0010's status changes from
  `accepted` to `superseded by FW-ADR-0015` once FW-ADR-0019 lands
  (FW-ADR-0019 documents the back-compat deprecation tail; this ADR
  authorises the supersession).
- **FW-ADR-0013 (rc-to-rc pre-bootstrap via cloned migration).**
  The migration class FW-ADR-0013 created is unreachable by
  construction once migration discovery is file-keyed (FW-ADR-0017)
  and the orchestrator is fetched fresh per invocation. FW-ADR-0013's
  status changes from `accepted` to `superseded by FW-ADR-0015`
  once FW-ADR-0019 lands. `migrations/v1.0.0-rc13.sh` becomes inert
  and is retired as part of FW-ADR-0019's implementation.

### Supersedes (partial)

- **FW-ADR-0014 (preservation vs manifest).** The two-source-of-
  truth problem the ADR's preservation-vs-manifest gate addressed
  dissolves once `TEMPLATE_STATE.json` (FW-ADR-0016) is the single
  source of truth. Be specific about what survives and what retires:
  - **Survives (moves into the runner unchanged):** FW-ADR-0014 Q2
    — the two-phase exit prose, phase-A (migration-complete) and
    phase-B (verification) semantics. The runner inherits the
    two-phase tail unchanged; the stub never sees it.
  - **Retires (becomes inert):** FW-ADR-0014 Q1 — the
    preservation-rule gate that arbitrated `.template-customizations`
    against the manifest. Preservation becomes a per-path
    declaration class IN `TEMPLATE_STATE.json`, not an emergent
    property arbitrated at runtime. The `software-engineer`'s
    runtime preservation classifier shipped in commit `44c330e`
    becomes inert once `TEMPLATE_STATE.json` is the single source
    of truth; it is retired alongside FW-ADR-0019's pre-bootstrap
    cleanup.
  - **Literal status-line wording for FW-ADR-0014** when FW-ADR-0016
    ships (so the partial-supersession is searchable from the
    FW-ADR-0014 side):
    `status: accepted (Q2 active); Q1 superseded by FW-ADR-0015 / FW-ADR-0016, 2026-MM-DD`
    where the date is the FW-ADR-0016 acceptance date. The
    architect drafting FW-ADR-0016 pins the literal date at that
    point.

### Inherits

- **FW-ADR-0002 (upgrade content verification — manifest).** The
  manifest verification contract moves bodily into the runner.
  Stub's `--verify` is a pass-through; runner owns the semantics.
- **FW-ADR-0014 Q2 (two-phase exit).** Migration-complete +
  verification phases survive into the runner unchanged.

### Cross-references (no technical coupling)

- **FW-ADR-0011 (routed-through trailer), FW-ADR-0012 (tech-lead
  authoring guard).** Unaffected by this ADR's scope; called out
  here only so future readers do not mistake them for affected
  ADRs.

### Issues

- Upstream issue trail for the dogfood failures that triggered this
  rearchitecture: see `docs/pm/dogfood-2026-05-15-results.md` and
  the conceptual-mistake / process-debt paired reports cited at
  the top of this ADR.

## Verification

How we know FW-ADR-0015 is correctly landed (once the implementation
ADR ships and the bridging rc per FW-ADR-0018 is cut):

- **Success signal A — dogfood across rc baselines.** The stub
  passes dogfood against every rc baseline in the project's
  fixture set (rc2..rc12), with the runner fetched from the
  current `main` ref. No tag cut is required for the dogfood to
  pass. This is the customer's "dogfood before cutting an rc"
  rule honoured by construction.
- **Success signal B — file-keyed migration discovery.** No
  invocation of the runner consults `git tag -l 'v*'`. Migration
  discovery is by file presence in the runner's `migrations/`
  directory. Verified by `qa-engineer`'s grep audit of the
  runner.
- **Success signal C — pre-bootstrap retired.** No `upgrade.sh`
  invocation writes `.template-prebootstrap-blocked.json`. The
  artefact's path is documented as a no-op; the override env var
  is a documented no-op; the audit-log column carries no new
  `pre-bootstrap` rows from this date forward. Existing rows are
  preserved (the audit log is append-only).
- **Success signal D — stub line-budget held.** `wc -l` on the
  stub returns a value below 100 across the v1.x line.
- **Success signal E — recurring-failure pattern absent.** For
  six months after the bridging rc cuts, no upgrade regression
  filed against the framework matches the orchestrator-self-
  mutation pattern (self-overwrite, untagged-target parsing,
  manifest-vs-preserve-list, rc-cliff cost). If the pattern
  reappears, the ADR is not correctly landed.
- **Failure signal — stub line-budget breached, or new flag
  added to the stub's CLI surface.** Either is a signal that
  orchestration logic has leaked back into the stub; route to
  `architect` for a structural review before merging.
- **Failure signal — operator filings report network-dependency
  as a blocker for a downstream population segment the framework
  did not know about.** At ADR acceptance, the customer (`CUSTOMER_NOTES.md`
  L323, 2026-05-15) is the only known downstream user and ruled
  air-gap support out of scope. If the downstream population grows
  and operator filings surface network-dependency as a blocker for
  a population segment that was not anticipated, this signal
  re-opens the air-gap question and routes to `sre` + customer
  for a fresh ruling. The framework's current baseline is "no
  framework-supported offline path"; that baseline is revisitable,
  not permanent.
- **Review cadence:** at the first MINOR release after the
  bridging rc cuts, and again at six months post-bridge. Earlier
  if any failure signal fires.

## Implementation notes for software-engineer

This section scopes the SE work for FW-ADR-0015-impl. It is **not**
the implementation; the architect describes the contract, the SE
implements.

- The stub lives at `scripts/upgrade.sh`. Sub-100 lines (hard
  budget). SPDX header + shebang count toward usability but not
  toward the budget; comments do not count.
- The stub's only dependencies are `bash`, `curl` (or the
  architect-approved fetch mechanism — `software-engineer` may
  propose `git archive` if measurement shows it strictly better),
  and `sha256sum` (or BSD `shasum -a 256`, with feature-detection).
  No `git` operations in the stub. No `sed`, `awk`, `jq` unless
  required for a one-line task.
- The stub MUST NOT source any file from `scripts/lib/`. Those
  helpers move into the runner. The stub is self-contained.
- The stub MUST NOT call any function from `scripts/lib/`. It
  inlines what it needs.
- `--help` output is hard-coded in the stub; no help-text fetched
  from the runner.
- The fetch-then-exec sequence runs without a tempfile if at all
  possible (`bash -c "$(curl ...)"` pattern with checksum gate).
  If a tempfile is required, the stub `mktemp`s, verifies, exec's,
  and the tempfile is the runner's responsibility to clean up if
  the runner cares. Stub does not register a cleanup trap.
- Exit-code mapping (stub-owned 10/11/12) is implemented as bare
  `exit N` calls; no exit-code library.
- The stub is the first file shipped in the bridging rc per
  FW-ADR-0018. Before that rc, no implementation work begins.
- Unit tests for the stub (`qa-engineer` scope) cover: (a) `--help`
  exits 0 without fetch; (b) network-down produces exit 11;
  (c) bad ref produces exit 12; (d) integrity-fail produces exit
  10; (e) `--no-verify` bypasses the checksum check and emits a
  WARN; (f) all other flags forward verbatim to a mock runner.

The implementation ADR (FW-ADR-0015-impl) covers code-level details
beyond this contract. Code-review (`code-reviewer`) and security
review (`security-engineer`) are binding gates on the implementation
ADR; this ADR's acceptance does not authorise implementation by
itself.

## Links

- Prior PM reports:
  - `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`
    (architect-conceptual paired dispatch; same conceptual
    mistake from the architect frame).
  - `docs/pm/upgrade-flow-process-debt-2026-05-15.md`
    (process-auditor paired dispatch; same conceptual
    mistake from the process frame).
  - `docs/pm/dogfood-2026-05-15-results.md` (dogfood evidence
    base for the recurring-failure pattern).
- Related ADRs:
  - `docs/adr/fw-adr-0002-upgrade-content-verification.md`
    (manifest verification; moves into runner).
  - `docs/adr/fw-adr-0010-pre-bootstrap-local-edit-safety.md`
    (supersedes; retires under stub model).
  - `docs/adr/fw-adr-0013-rc-to-rc-pre-bootstrap.md`
    (supersedes; mooted by file-keyed migration discovery).
  - `docs/adr/fw-adr-0014-preservation-vs-manifest.md`
    (partially supersedes — Q1; Q2 inherited unchanged).
- Forward-referenced ADRs (sequenced after this one):
  - FW-ADR-0016 — TEMPLATE_STATE.json schema (drafted next).
  - FW-ADR-0017 — File-keyed migration discovery.
  - FW-ADR-0018 — Migration path for deployed downstreams
    (customer's ruling: option S, one transitional rc bridge).
  - FW-ADR-0019 — Pre-bootstrap retirement.
- Related artefacts:
  - `scripts/upgrade.sh` (current driver; becomes the stub via
    the bridging rc per FW-ADR-0018).
  - `docs/framework-project-boundary.md` (path ownership;
    customisation-wins commitment that the stub model honours).
- External references:
  - MADR 3.0 (`https://adr.github.io/madr/`).
  - Industry precedents for stub-and-runner self-update patterns:
    rustup (`rustup-init.sh`), asdf, nvm, pyenv. Cited as shape,
    not as code reuse.
