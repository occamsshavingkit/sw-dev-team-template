# Security Assurance Assessment — OpenCode enforcement hook bridge (fw-adr-0031)

<!-- TOC -->

- [1. Identification](#1-identification)
- [2. Scope and method](#2-scope-and-method)
- [3. Threat model](#3-threat-model)
- [4. Assurance claim](#4-assurance-claim)
- [5. Argument and evidence](#5-argument-and-evidence)
  - [5.1 Security requirements](#51-security-requirements)
  - [5.2 Security design](#52-security-design)
  - [5.3 Security patterns](#53-security-patterns)
  - [5.4 Construction for security](#54-construction-for-security)
  - [5.5 Security testing](#55-security-testing)
  - [5.6 Vulnerability management](#56-vulnerability-management)
- [6. SBOM and supply chain](#6-sbom-and-supply-chain)
- [7. Findings register](#7-findings-register)
- [8. Residual risk](#8-residual-risk)
- [9. Unverified assumptions](#9-unverified-assumptions)
- [10. Security-boundary vs. discipline-control determination](#10-security-boundary-vs-discipline-control-determination)
- [11. Sign-off decision](#11-sign-off-decision)
- [12. Record of sign-off](#12-record-of-sign-off)
- [13. References](#13-references)

<!-- /TOC -->

---

## 1. Identification

- **Artefact / subsystem / release assessed:** OpenCode enforcement hook
  bridge — `.opencode/plugin/hook-bridge.js`, `scripts/opencode/tool-arg-map.json`,
  and the associated release-gate sub-gates
  (`scripts/verify-opencode-hook-parity.sh`, `scripts/lib/gate-hook-exec-bits.sh`,
  `scripts/lib/gate-hook-negative-corpus.sh`). A protocol-translation
  adapter that shells out to the unchanged `scripts/hooks/*.py` guards
  from OpenCode plugin hook points, per `docs/adr/fw-adr-0031-opencode-hook-bridge.md`.
- **Version / commit / tag assessed:** `a7420dd` (branch
  `feat/opencode-hook-bridge`, clean tree at assessment time).
- **Repository and path(s) in scope:** `occamsshavingkit/sw-dev-team-template`
  — see § 2 "In scope" for the exact path list.
- **Assessor:** `security-engineer`
- **Date of assessment:** 2026-07-25
- **Trigger:** CLAUDE.md Hard Rule #7 (authorization category). The
  bridge is the OpenCode-side enforcement path for authorization-equivalent
  guard logic — `tech-lead-authoring-guard.py`'s role-based write bypass
  and `customer-notes-guard.py`'s stewardship gate — introduced by
  `docs/adr/fw-adr-0031-opencode-hook-bridge.md`.
- **Supersedes:** None as a filed artefact. This is the first persisted
  instance of this assessment. A prior assessment of this same artefact
  was conducted (2026-07-24/25) and returned **SIGN-OFF WITH CONDITIONS**,
  but it existed only as agent output — no file was written to the
  repository, a gap `fw-adr-0031`'s own References section names
  explicitly ("No separate persisted assessment artefact was found
  in-repo at the time this ADR revision was authored"). This document
  resolves that gap by (a) recording the original findings retroactively
  in § 7, each tagged with its original identifier (H-1(a), H-1(b), H-2,
  M-1, M-2, M-3, S1) so the ADR's own citations of those identifiers
  resolve to something concrete, and (b) layering this session's
  independent re-verification of each claimed closure on top, so the
  decision in § 11 is this session's live, current-HEAD verdict, not a
  restatement of the original one.

---

## 2. Scope and method

**In scope.**

- `.opencode/plugin/hook-bridge.js` — read in full; every branch traced
  against the six findings and three process conditions below.
- `scripts/opencode/tool-arg-map.json` — read in full.
- `scripts/verify-opencode-hook-parity.sh`, `scripts/lib/gate-hook-exec-bits.sh`,
  `scripts/lib/gate-hook-negative-corpus.sh`, `scripts/verify-hook-executable-bits.sh`
  — read; existence and (for the exec-bits driver) executability
  confirmed on disk.
- `tests/hooks/test-opencode-hook-bridge.sh` — read in full; assertion
  shapes (in particular cases B9–B13, the privilege-forwarding and
  session-identity-escalation coverage) confirmed to test what this
  document and the ADR claim they test.
- `.opencode/agents/*.md` — grepped for `webfetch`/`websearch`/`edit`
  permission frontmatter (M-3 verification).
- `.opencode/.gitignore`, `.opencode/package.json`, `.opencode/node_modules/`
  — checked for the ADR's binding "OpenCode's own auto-generated files
  must be `.gitignore`d, not checked in" requirement.
- `docs/adr/fw-adr-0031-opencode-hook-bridge.md` — read in full as the
  primary narrative source for the two runtime spikes (2026-07-24
  against OpenCode 1.18.4, 2026-07-25 against 1.18.5) this assessment
  did not itself reproduce (see Method below).
- `docs/templates/security-template.md`, `docs/templates/operations-plan-template.md`
  § 7 — read to confirm the template shape and the filing-path
  convention this document follows.
- `CUSTOMER_NOTES.md` — grepped to confirm no Hard Rule #7 sign-off for
  this bridge is recorded yet (it is not).

**Out of scope.**

- `scripts/hooks/*.py` themselves — unchanged by `fw-adr-0031` per its
  own binding Decision text ("`scripts/hooks/*.py` remain unchanged by
  this ADR"); their own security posture is covered by their own
  governing ADRs (e.g. `fw-adr-0012` for `tech-lead-authoring-guard.py`),
  not re-litigated here.
- OpenCode's own binary/source (`@opencode-ai/plugin`, `@opencode-ai/sdk`,
  and the OpenCode host process itself) — vendor-owned, not in this
  repository. `.opencode/node_modules/` is OpenCode's own auto-generated
  dependency tree, excluded from this artefact's supply-chain scope (see
  § 6).
- A fresh live runtime spike against any OpenCode binary — **not
  performed in this pass.** No execution capability (shell/process
  execution) was available to this assessor in this session; see
  Method below.
- Execution of the shipped test suite
  (`tests/hooks/test-opencode-hook-bridge.sh`, `scripts/pre-release-gate.sh`
  and its sub-gates) — **not performed in this pass**, same reason.
- `docs/requirements.md` — does not exist in this repository. This is
  the scaffold/framework project itself, not a downstream product
  instance with a filled requirements document; see § 5.1.
- An exhaustive search for a durable `code-reviewer` review artefact
  for the commits cited below — a single `docs/review/` glob and a
  repo-wide grep for the cited finding labels (`W1`, `W2`) found no
  match outside the shipped code and test file themselves; not
  exhaustively searched beyond that (see § 9, UA-0002).

**Compensating controls for out-of-scope items.** `scripts/hooks/*.py`'s
own logic is unchanged and covered by its own prior ADRs/assessments,
so excluding it here does not leave it unreviewed anywhere. OpenCode's
own binary is a vendor dependency; its behavior is evidenced only
through the ADR's spike narrative (see Method) — there is no
compensating control for the "not independently reproduced" gap itself
beyond naming it plainly, which this document does.

**Method: static review only.** I read the shipped source of
`.opencode/plugin/hook-bridge.js` in full and traced its control flow
against each claimed-closed finding and process condition; read the
mapping table, the release-gate sub-gate scripts, and the test file's
actual assertions (not executed); grepped agent permission frontmatter
and `CUSTOMER_NOTES.md`. **I did not execute any code in this pass** —
no Bash/shell tool was available to this assessor in this session, so
the shipped test suite was read but not run, and neither of the ADR's
cited runtime spikes (2026-07-24 against OpenCode 1.18.4, 2026-07-25
against 1.18.5) was reproduced by this assessor. This is precisely the
static-vs-runtime distinction `docs/templates/security-template.md`
itself calls out as this artefact's own cautionary history: the
original static-only pass is what named the gap that triggered the
spike which found the NEW-HIGH session-identity finding. Carrying that
lesson forward, § 4's claim below is scoped to what static reading can
actually support, and the resulting gap is named explicitly in § 9
rather than absorbed into an unqualified sign-off.

---

## 3. Threat model (STRIDE)

**Assets.** Enforcement fidelity of the 14 Claude-Code-equivalent
guards under OpenCode: `CUSTOMER_NOTES.md` stewardship, Hard Rule #8
authoring-discipline / role-scoped write bypass, handoff-lifecycle
bookkeeping, subagent spawn-budget control. Classification: internal
process-integrity control — not itself secret/PII data, but it gates
write access to files that may carry customer-sensitive project
content. Per project data-classification policy: none formally exists
for this scaffold repository (see § 5.1).

**Actors.** A legitimate OpenCode session running as `tech-lead` or a
freshly-dispatched specialist role; a session resumed/re-attached under
a *different* agent via `opencode run --session <id> --agent <role>`
(the actor class the NEW-HIGH finding concerns); a co-loaded, unrelated
OpenCode global plugin (potentially interfering, not necessarily
malicious — a concrete non-malicious instance was already observed,
see § 10); an operator with bash access able to enumerate and resume
sessions; the bridge's own `python3` subprocess (trusted, out of
scope).

**Trust boundaries** (enforcing mechanism named for each; § 10 states
whether that mechanism is a hard boundary or a discipline control):

1. **`task` dispatch boundary** (`subagent_type`) — enforced by
   OpenCode's own tool-dispatch layer, per the ADR's runtime spike.
2. **Per-session agent-identity boundary** — the bridge's own
   `sessionAgent` map, crossing from "role recorded at spawn time" to
   "role currently resumed" — enforced by the bridge's
   `session.created`/`session.updated` handlers.
3. **`tool.execute.before` mediation boundary** — enforced by this
   bridge's deny-by-throw, contingent on this plugin running and
   winning any hook-ordering race against other co-loaded plugins
   (OpenCode gives no ordering guarantee — see § 10).
4. **Per-agent tool-availability boundary** — enforced by OpenCode's
   own frontmatter permission dispatch (`skill: deny` and similar).
5. **`skill` content boundary** — `skill` returns untrusted markdown
   text into model context; read-only, not an execution primitive.
6. **Network-egress boundary on `researcher`** — unguarded on both
   harnesses (M-3).

**Threats, by boundary:**

- **Spoofing** (boundary 1): a caller mints an arbitrary/undefined
  `subagent_type` to reach the guard chain under a fabricated identity.
  Per the ADR's spike, OpenCode itself rejects this outright with no
  child session spawned — see finding SEC-OPENCODE-HOOK-BRIDGE-0001.
- **Tampering** (boundary 2): a resumed session asserts a stale,
  possibly more-privileged role after its real running identity moved
  on — the NEW-HIGH finding, SEC-OPENCODE-HOOK-BRIDGE-0003.
- **Repudiation**: guard verdicts and identity-change events are logged
  via `console.error`, but that output reaches only the OpenCode
  process's own stderr, not the chat/TUI transcript the operator reads
  — a named, accepted UX gap in the ADR (not itself a security defect,
  since the verdict-enforcement decision does not depend on the log
  being read), not separately re-litigated as a finding here.
- **Information disclosure** (boundaries 5, 6): `skill`-returned
  markdown and `researcher`'s fetched web content are both untrusted
  text reaching a role that can also write files — a prompt-injection
  intake path. Named residual risk, not closed by this ADR (§ 8).
- **Denial of service**: a hung guard hook (mitigated: 5s subprocess
  timeout, `GUARD_HOOK_TIMEOUT_MS`); unbounded session-state growth
  across a long-lived process (S1, SEC-OPENCODE-HOOK-BRIDGE-0008).
- **Elevation of privilege** (boundary 3): the architectural ceiling —
  any co-loaded plugin able to pre-empt or suppress this bridge's throw
  defeats the entire guard chain regardless of how correct the chain's
  own logic is. **Not closed, not closable within this ADR's scope**
  (§ 10).

**Compensating controls for out-of-scope items.** `researcher` (M-3's
subject) holds `task: deny` and `bash: deny` — confirmed by reading
`.opencode/agents/researcher.md` — so the blast radius of injected
content is bounded to file writes within `researcher`'s own turn,
subject to `code-reviewer`'s Hard Rule #3 review before any commit.
`scripts/hooks/*.py`'s own logic is covered by its own governing ADRs,
unaffected by this bridge.

---

## 4. Assurance claim

**Claim.** A static review of the OpenCode enforcement hook bridge at
commit `a7420dd` found that every finding and process condition
attached to the original (unpersisted) 2026-07-24/25 SIGN-OFF WITH
CONDITIONS assessment is represented in the shipped source by code
whose logic matches its claimed remediation, with no contradicting
logic found on inspection, and that the described process conditions
(security-template shape, dual-harness negative-corpus gating,
hook-executable-bits gating) are likewise present as described. This
claim covers **source-code correctness by reading only** — it does not
extend to confirmed-passing execution of the shipped test suite, or to
independent reproduction of the two runtime spikes the original
findings and this ADR's own trust-boundary conclusions (H-1(a), H-2)
rest on; neither was performed in this pass (§ 2, § 9). It also does
not extend to a change in the artefact's architectural ceiling: the
discipline-control-not-hard-boundary determination this assessment
reaches in § 10 is unchanged by any of the closures reviewed here.

---

## 5. Argument and evidence

### 5.1 Security requirements

No `docs/requirements.md` exists in this repository — this is the
scaffold/framework project itself, not a downstream product instance
with a filled security-requirements document — so there is no
`NFR-COMP-NNNN` row to trace to. Treated as a gap for the framework's
own self-hosting posture, not a gap in a downstream project (which is
expected to instantiate its own `docs/requirements.md` from the
template). The closest analog to a formal requirement is
`fw-adr-0031`'s own binding verdict-translation contract and
fail-open/fail-closed split, which function as the de facto
authorization/availability requirements this bridge is held to.

| ID | Requirement | Category | Linked req ID | Status |
|---|---|---|---|---|
| — | Guard verdicts reached under OpenCode must match Claude Code verdicts for identical inputs, modulo two named parity gaps (warn-drop, ask-hardens-to-deny) | Authorization | fw-adr-0031 "Verdict-translation contract" (binding) | Implemented; not independently re-executed this pass (§ 9) |
| — | Bridge-infrastructure absence must fail closed, never silently unenforced | Availability / Integrity | fw-adr-0031 "Fail-open vs. fail-closed" (binding) | Implemented; confirmed present by reading (§ 7) |
| — | Per-session agent identity forwarded to the guard chain must reflect the session's *current* real role, not a stale spawn-time snapshot | Authorization | fw-adr-0031 "Session identity is mutable" (binding) | Implemented (c4bc456); confirmed present by reading (§ 7) |

### 5.2 Security design

The threats named in § 3 are designed against structurally, not just
patched reactively: (a) deny-by-throw and ask-degrades-to-deny are
fail-closed-leaning defaults chosen explicitly over their weaker
alternatives (`fw-adr-0031` Decision); (b) the module-load
`TOOL_ARG_MAP_MISSING_TOOL_IDS` assertion converts a previously-silent
"guard chain stops running for one tool id" failure mode into a
bridge-wide fail-closed throw (M-1's fix); (c) the `session.created`
(retain) vs. `session.updated` (follow) split is a deliberate,
explicitly-commented asymmetry over the same map, chosen because
"harmonising" the two would reopen the escalation the NEW-HIGH finding
closed — this is documented isolation-of-concerns design, not an
accident; (d) the FIFO bounded-eviction fallback for unbounded
session-state growth (S1) is explicitly reasoned to degrade fail-safe
(an evicted-but-still-live session loses its privilege forwarding, not
gains it).

### 5.3 Security patterns

- **Fail-closed default** — bridge-infrastructure absence (missing
  interpreter, missing hook script, spawn failure, non-zero exit,
  missing map entry) throws rather than proceeding unenforced.
- **Complete mediation (attempted)** — every `GUARD_CHAIN_BY_TOOL` tool
  id is routed through the guard chain, with a module-load completeness
  assertion against the mapping table closing the one gap that
  previously let a declared-but-unmapped tool id skip the chain
  silently (M-1).
- **Least privilege / no forwarding beyond reach** — the
  `session.updated`-follows fix's own escalation-vector analysis proves
  the follow-not-retain change cannot itself grant a privilege tier the
  session could not already reach by being freshly dispatched as that
  role (the guard's bypass is binary tech-lead-vs-not, not
  path-scoped).
- **Secure by default** — `ask` degrading to `deny` (not to silent
  allow) is the stricter of the two available poles given OpenCode has
  no interactive re-prompt channel.
- **Defense in depth** — `customer-notes-guard.py` →
  `tech-lead-authoring-guard.py` → `handoff-pre-tool-gate.py` chain on
  write/edit/bash; `subcall-limit-guard.py` on `task`; first-deny-wins
  short-circuit ordering preserved and load-bearing (confirmed by
  `tests/hooks/test-opencode-hook-bridge.sh` case B3's ordering
  assertion, read but not executed).

### 5.4 Construction for security

- **Secrets management.** The bridge introduces no new secret material;
  it forwards the OpenCode process's existing environment unchanged
  into each guard-hook subprocess (`...process.env` spread). No
  secrets are logged — `console.error` calls log hook names, truncated
  stdout/stderr excerpts, and role-identity strings, not credentials.
- **Input validation.** The module-load map-completeness assertion
  (§ 5.3) functions as this bridge's primary input-validation gate on
  its own configuration surface. Per-call `args` are passed through
  `buildGuardPayload`'s explicit key-by-key copy (no dynamic
  key/property injection from untrusted input observed).
- **Output encoding.** N/A beyond `JSON.stringify`/`JSON.parse`
  round-tripping to the same stdin/stdout JSON contract the Python
  hooks already use under Claude Code.
- **Dependency policy.** Zero third-party dependencies in the plugin
  itself — only `node:child_process`, `node:fs`, `node:path`,
  `node:url` are imported, confirmed by reading the file's import
  block. This is a stated, deliberate design choice (header comment:
  "Dependency-free ESM ... so downstream projects need no `npm
  install` step"), not an oversight.
- **Secure coding standard.** Every fail path carries an inline
  rationale comment tracing to either a named finding (H-1(b), M-1,
  M-2, S1, the NEW-HIGH fix, W1, W2) or the ADR's binding contract
  clause it implements — unusually high traceability for a security
  review to work from, and it held up under direct tracing in this
  pass (no contradiction found between a comment's claim and the code
  beneath it).

### 5.5 Security testing

**What this assessment pass actually ran: nothing.** No execution
capability was available (§ 2). What exists in the repository, read
but not executed:

- **`tests/hooks/test-opencode-hook-bridge.sh`** — Part A (table-driven,
  no execution needed) and Part B (13+ live differential cases,
  including B9–B11 privilege-forwarding and B12/B13 covering the
  NEW-HIGH fix and top-level-session safety). Read in full; each
  case's assertions were confirmed to test what the ADR and this
  document claim they test — in particular, B12/B13 assert on the
  *actual wire payload* sent to `tech-lead-authoring-guard.py`
  (`agent_type`), not merely on the downstream allow/deny verdict,
  which is the correct design to catch a silently-broken forwarding
  path rather than one that merely happens to produce the same
  verdict by accident.
- **`scripts/lib/gate-hook-negative-corpus.sh`** — confirmed (by
  reading) to run `tests/hooks/run-negative-corpus.sh` in both
  `--all` (Claude Code) and `--all --harness opencode` modes,
  unconditionally, neither masking the other.
- **`scripts/lib/gate-hook-exec-bits.sh`** → `scripts/verify-hook-executable-bits.sh`
  — confirmed present and executable on disk.
- No SAST/DAST/fuzzing/penetration-testing activity specific to this
  artefact was found or performed in this pass.

**Follow-up recommended** (also a sign-off condition, § 11): a
specialist with execution capability (`qa-engineer` or
`release-engineer`) runs `tests/hooks/test-opencode-hook-bridge.sh` and
the relevant `scripts/pre-release-gate.sh` sub-gates against this exact
commit and records the pass/fail result, closing the gap this static
pass could not close itself.

### 5.6 Vulnerability management

- **Advisory-feed sources monitored.** No advisory-monitoring process
  specific to `@opencode-ai/plugin`/`@opencode-ai/sdk` (the vendor
  binary this bridge's entire trust-boundary reasoning in § 3/§ 10
  depends on) was found referenced anywhere in this repository. Given
  the ADR's own 1.18.4→1.18.5 point-release provenance note (behavior
  the bridge relies on already shifted once, mid-project, on an
  unpinned "binary now on PATH" basis), this is a live gap, not a
  theoretical one.
- **Triage SLA / patch process.** None named for OpenCode specifically.
  `scripts/hooks/*.py`'s own vulnerability-management posture (covered
  by prior ADRs) is unaffected and out of scope here.
- **Disclosure policy.** N/A — no external-facing vulnerability surface
  is newly introduced by this bridge itself (it is an internal
  enforcement adapter, not a network service).

Recommended follow-up: `security-engineer` coordinates with `sre` /
`release-engineer` (per CLAUDE.md's Operations KA split — supplier
management for vendor dependencies is an `sre` Operations-Planning
responsibility) to add the OpenCode binary/SDK to whatever
advisory-monitoring process already exists for other vendor
dependencies.

---

## 6. SBOM and supply chain

- **SBOM.** Not generated for this artefact specifically. Low urgency
  by design: the plugin itself has **zero third-party dependencies**
  (only `node:*` builtins), confirmed by reading its import block.
  `scripts/hooks/*.py` (unchanged, out of scope) presumably remains
  Python-stdlib-only per its own prior assessments; not re-verified in
  this pass.
- **Dependency scanning.** None specific to this artefact's own (empty)
  dependency set. `.opencode/node_modules/` — OpenCode's own
  auto-generated tree (`@opencode-ai/plugin`, `@opencode-ai/sdk`,
  `effect`, `zod`, and transitive deps observed via `Glob`) — is
  OpenCode's own tooling, not this project's dependency surface, and is
  correctly excluded from git tracking: `.opencode/.gitignore` (read)
  contains `node_modules`, `package.json`, `package-lock.json`,
  `bun.lock`, `.gitignore` — matching the ADR's binding requirement
  exactly. Confirmed on disk; not independently confirmed via `git
  status --ignored` (no execution capability this pass), but the
  `.gitignore` content itself is unambiguous.
- **Supply-chain exposure considered.** Typosquatting/dependency
  confusion: N/A, zero third-party deps in the plugin. Compromised
  build tooling: N/A, no build step (plain ESM, `node:*` only).
  Compromised upstream (OpenCode itself): considered and named as a
  live, unmitigated gap in § 5.6 — this bridge's entire trust-boundary
  argument (§ 3, § 10) depends on OpenCode's own dispatch/permission
  layer behaving as observed, and there is no advisory-monitoring
  process named for that dependency.

---

## 7. Findings register

**Severity scale in use:** CVSS v3.1 base score bands — Critical ≥9.0,
High 7.0–8.9, Medium 4.0–6.9, Low 0.1–3.9, Informational — no
exploitability (process/documentation gaps).

| ID | Severity | Description | Location | Status | Owner | Target closure |
|---|---|---|---|---|---|---|
| SEC-OPENCODE-HOOK-BRIDGE-0001 | High | H-1(a): a caller could mint an arbitrary/spoofed agent-role string via `task`'s `subagent_type`, feeding an unvalidated identity into the bridge's guard chain. | OpenCode's own `task`-dispatch layer (not this repo's code) | **Closed** — per the ADR's runtime spike, OpenCode itself rejects an undefined `subagent_type` outright with no child session spawned; tested against a bogus name, a canonical-looking-but-undefined name, and a positive control. **Not independently re-executed by this assessor** (§ 9 UA-0001). | `security-engineer` (verification), `architect` (ADR owner) | Closed 2026-07-25 (ADR revision) |
| SEC-OPENCODE-HOOK-BRIDGE-0002 | Medium | H-1(b): `session.created` re-firing for an already-tracked `sessionID` could silently overwrite the recorded `parentID`/agent, flipping guard routing or forwarded privilege mid-session. | `.opencode/plugin/hook-bridge.js`, `event` handler, `session.created` branch | **Closed** — first-write-wins implemented for both `sessionParent` and `sessionAgent`, with a logged warning on any observed re-fire mismatch. Confirmed present at lines ~700–749. Commit `65349ea`. | `software-engineer` | Closed (`65349ea`) |
| SEC-OPENCODE-HOOK-BRIDGE-0003 | High | **NEW.** A session resumed under a different agent via plain `session.updated` (no accompanying `session.created`) kept the bridge asserting its stale, spawn-time role to `tech-lead-authoring-guard.py`'s binary write-bypass — a live privilege-escalation path, trivial cost (any bash-capable session can enumerate and resume sessions). | `.opencode/plugin/hook-bridge.js`, `event` handler, `session.updated` branch | **Closed** — `session.updated` now FOLLOWS (not retains) `info.agent`, logged via `console.error` on every change. Commit `c4bc456`. Tests B12 (wire-payload assertion of the followed change) and B13 (top-level-session safety) present and read; both assert on the actual `agent_type` sent to the guard, not just the verdict. **Test execution not independently confirmed by this assessor** (§ 9 UA-0001). | `software-engineer` | Closed (`c4bc456`); execution-confirmation outstanding |
| SEC-OPENCODE-HOOK-BRIDGE-0004 | Medium | H-2: the `skill` tool was unwired by the guard chain; unverified whether per-agent `skill: deny` frontmatter is actually enforced, and whether `skill` could be used as an execution primitive bypassing the guarded chain. | `.opencode/plugin/hook-bridge.js` (absence of a `skill` entry in `GUARD_CHAIN_BY_TOOL`); OpenCode's own frontmatter dispatch layer | **Closed** — runtime-verified on two axes per the ADR: (a) `skill: deny` frontmatter removes `skill` from an agent's tool list before `tool.execute.before` runs, confirmed against a non-deny control case; (b) `skill` is read-only (markdown + file listing only), confirmed by invoking a skill with a bundled marker-writing script and observing the marker was never created. Residual prompt-injection risk on skill-returned content named separately (§ 8). **Not independently re-executed by this assessor** (§ 9 UA-0001). | `security-engineer` (verification) | Closed (2026-07-25 ADR revision) |
| SEC-OPENCODE-HOOK-BRIDGE-0005 | Medium | M-1: `GUARD_CHAIN_BY_TOOL` could declare a tool id with no corresponding `tool-arg-map.json` entry; `buildGuardPayload` would silently return `null` and the entire guard chain for that tool would stop running with no error and no log line. | `.opencode/plugin/hook-bridge.js` | **Closed** — module-load assertion (`TOOL_ARG_MAP_MISSING_TOOL_IDS`) computed once at load time; `tool.execute.before` throws (fails closed, bridge-wide) if the map failed to load OR is missing any guarded tool id; a redundant invariant check on `buildGuardPayload`'s `null` return is also present as defense-in-depth. Confirmed present by direct code reading (lines ~112–126, ~574–613). Code-review finding W2. Commit `ac5d005`. | `software-engineer` | Closed (`ac5d005`) |
| SEC-OPENCODE-HOOK-BRIDGE-0006 | Low | M-2: a guard hook producing malformed (non-JSON) stdout silently inherited the hook's fail-open posture with zero operator-visible signal, which could mask a broken/regressed guard. | `.opencode/plugin/hook-bridge.js`, `applyVerdict()` | **Closed** — the fail-open *decision* is unchanged (correctly matches the ADR's binding "inherit the hook's own posture" contract), but the bridge now logs via `console.error`, naming the hook and a truncated stdout excerpt, on this path. A 1MB stdout accumulation cap (`MAX_STDOUT_BYTES`) was added in the same commit as related hardening. Confirmed present (lines ~204, ~280–300). Commit `65349ea`. | `software-engineer` | Closed (`65349ea`) |
| SEC-OPENCODE-HOOK-BRIDGE-0007 | Medium | M-3: `researcher` holds `webfetch: allow` + `websearch: allow` together with `edit: allow`; neither Claude Code's 14-hook set nor this bridge guards network egress at all. | `.opencode/agents/researcher.md` (confirmed `websearch: allow`, `webfetch: allow`, `edit: allow`); no egress-aware hook exists in `scripts/hooks/` or `GUARD_CHAIN_BY_TOOL` | **Open** — deliberately out of scope for `fw-adr-0031` (pre-existing, cross-harness, not a regression from this bridge). Confirmed still accurate on this pass. I agree it should not block this bridge's sign-off, for the same reason the ADR states: it predates the bridge and is unaffected by it. Named as follow-up for a future ADR. | `security-engineer` (to author follow-up), `architect` | No target set — tracked as follow-up scope |
| SEC-OPENCODE-HOOK-BRIDGE-0008 | Low | S1: `sessionParent`/`sessionAgent`/`handledIdleSessions` grow unboundedly for a long-lived OpenCode process (no session-ended event exists in the wired event surface). | `.opencode/plugin/hook-bridge.js` (the three state structures) | **Closed** — shared FIFO cap (`SESSION_STATE_CAP = 10000`) evicts the oldest-tracked session across all three structures atomically, logging the eviction; code comments reason through why eviction degrades fail-safe (an evicted-but-still-live session resolves `caller_role = None` on its next guarded call — the restrictive direction, not a bypass). Confirmed present at lines ~536–563. Commit `1368fab`. **No automated regression test found** for this path (§ 9 UA-0004) — the fail-safe claim is corroborated by direct code reading, not an executable test. | `software-engineer` (fix); `qa-engineer` (test-coverage follow-up) | Closed (`1368fab`); test-coverage gap open |
| SEC-OPENCODE-HOOK-BRIDGE-0009 | Informational | Process condition: `docs/templates/security-template.md` did not exist in the shape required to file a Hard Rule #7 assurance case for this bridge. | `docs/templates/security-template.md` | **Closed** — rebuilt in the required shape (commit `a7420dd`, customer-authorised); confirmed present with all 13 sections. | `tech-writer` / `tech-lead` | Closed (`a7420dd`) |
| SEC-OPENCODE-HOOK-BRIDGE-0010 | Informational | Process condition: `scripts/lib/gate-hook-negative-corpus.sh` exercised only the Claude Code guard path; a regression introduced solely on the OpenCode round-trip path could ship undetected. | `scripts/lib/gate-hook-negative-corpus.sh` | **Closed** — now runs `tests/hooks/run-negative-corpus.sh` in both `--all` (Claude) and `--all --harness opencode` modes unconditionally, neither masking the other. Confirmed present by reading. Commit `4dcb41a`. | `release-engineer` | Closed (`4dcb41a`) |
| SEC-OPENCODE-HOOK-BRIDGE-0011 | Informational | Process condition: no release-gate sub-gate asserted that every `[ -x ... ]`-guarded hook script named in `.claude/settings.json` is present-and-executable; a mode-bit regression would silently no-op forever via the `\|\| true` idiom. | `scripts/lib/gate-hook-exec-bits.sh`, `scripts/verify-hook-executable-bits.sh` | **Closed** — new `hook-exec-bits` sub-gate registered, delegates to `scripts/verify-hook-executable-bits.sh` (confirmed present and executable on disk). Commit `edfb485`. | `release-engineer` | Closed (`edfb485`) |

---

## 8. Residual risk

| ID | Description | Likelihood | Impact | Accepted by | Mitigation (if partial) |
|---|---|---|---|---|---|
| RR-OPENCODE-HOOK-BRIDGE-0001 | The bridge is a discipline/compliance control, not a hard security boundary: OpenCode's additive, unordered global-plugin loading gives no guarantee another co-loaded plugin cannot pre-empt or suppress this bridge's `tool.execute.before` throw. A concrete instance was already observed (a global plugin made `tech-lead` subagent-spawnable until this branch's own `mode: primary` registration shadowed it). | M | H | **Not yet recorded** — requires customer acceptance via `tech-lead` per Hard Rule #4/#7, to be recorded in `CUSTOMER_NOTES.md` | None available within this ADR's scope; `mode: primary` is an incidental partial mitigation for the one observed case, not a general guarantee |
| RR-OPENCODE-HOOK-BRIDGE-0002 | M-3 carried forward: `researcher`'s combined `webfetch`/`websearch`/`edit` permissions remain an unguarded prompt-injection-to-file-write path on both harnesses. | L–M | M (bounded — see below) | **Not yet recorded** | `researcher` holds `task: deny` and `bash: deny` (confirmed by reading `.opencode/agents/researcher.md`), bounding blast radius to file writes within `researcher`'s own turn, subject to Hard Rule #3 review before commit |
| RR-OPENCODE-HOOK-BRIDGE-0003 | Warn-mode and ask-mode both narrow under OpenCode (warn's reason text dropped; ask hardens to deny) — a live behavioral asymmetry between harnesses for the same guard/input. | M | L (ask hardens stricter, not weaker; warn loses only non-blocking information text) | Implicit in the ADR's Accepted status; not separately recorded as a Hard-Rule-#7-tracked item in `CUSTOMER_NOTES.md` | None needed — the asymmetry does not weaken enforcement in either direction |

---

## 9. Unverified assumptions

| ID | Assumption | Why it could not be verified in this pass | Consequence if false | Recommended follow-up |
|---|---|---|---|---|
| UA-OPENCODE-HOOK-BRIDGE-0001 | The shipped test suite (`tests/hooks/test-opencode-hook-bridge.sh`, especially B9–B13) passes when actually run against commit `a7420dd`, and the ADR's two cited runtime spikes (2026-07-24/1.18.4, 2026-07-25/1.18.5) accurately reflect live OpenCode behavior. | This assessment's method was static-only — no Bash/execution tool was available to this assessor in this session (§ 2). The spikes and test suite were read, not run. | Any of the "runtime-verified" claims (H-1(a), H-2, the NEW-HIGH fix's B12/B13 assertions, S1's fail-safe-eviction claim) could be stale, mis-transcribed, or specific to a since-changed OpenCode point release — a live concern given the ADR's own 1.18.4→1.18.5 point-release provenance note. | `qa-engineer` or `release-engineer` executes `tests/hooks/test-opencode-hook-bridge.sh` and the relevant `scripts/pre-release-gate.sh` sub-gates against this exact commit (and ideally against whatever OpenCode point release is current at ship time) and records pass/fail. |
| UA-OPENCODE-HOOK-BRIDGE-0002 | Commits `ac5d005`, `65349ea`, `c4bc456`, `1368fab` each received a `code-reviewer` review satisfying Hard Rule #3. | No durable `docs/review/` artefact was found for this branch; the `W1`/`W2` code-review finding labels are evidenced only via inline code comments and test names in `.opencode/plugin/hook-bridge.js` and `tests/hooks/test-opencode-hook-bridge.sh` themselves, not a separate review record. Search was not exhaustive beyond a targeted glob/grep. | A claimed review pass may not have a durable record even if it occurred; if it did not occur, Hard Rule #3 was not satisfied for these commits. The shipped-code evidence (behavior matching the claimed fix) stands regardless. | `code-reviewer` confirms or produces the durable review record for these four commits. |
| UA-OPENCODE-HOOK-BRIDGE-0003 | OpenCode's own tool-dispatch validation (the mechanism SEC-OPENCODE-HOOK-BRIDGE-0001/H-1(a) now structurally relies on) continues to reject undefined `subagent_type` values in future OpenCode releases. | Upstream, third-party behavior not under this project's control; no repo-local signal exists if it changes (the ADR's own "cannot detect OpenCode renamed a tool id upstream" caveat applies analogously). | An OpenCode release that stops validating `subagent_type` would reopen the spoofing threat this finding currently treats as closed, with no local warning. | None currently automatable; standing upstream-dependency risk, consistent with the ADR's own Consequences section. Track alongside UA-0001's point-release re-verification recommendation. |
| UA-OPENCODE-HOOK-BRIDGE-0004 | S1's FIFO-eviction fix behaves fail-safe under actual load (an evicted-but-still-live session's next guarded call resolves `caller_role = None` rather than granting a bypass or crashing). | No automated regression test exercises the 10000-session eviction path (searched `tests/hooks/`; none found). The fail-safe claim is corroborated only by direct reading of the code's own inline reasoning, which is sound on inspection but untested. | If the eviction path behaves differently than reasoned (e.g. under a race between eviction and an in-flight guarded call for the same session), the actual failure mode is unverified. | `qa-engineer` adds a regression test driving >10000 sessions through `session.created` and asserting the oldest is evicted and that a subsequent guarded call for it resolves `caller_role = None`. |

---

## 10. Security-boundary vs. discipline-control determination

**Determination:** ☐ Security boundary &nbsp;&nbsp; ☒ Discipline
control &nbsp;&nbsp; ☐ Mixed

**Rationale.** No mechanism this bridge controls holds against a
compromised or merely uncooperative component on the other side of the
`tool.execute.before` boundary. OpenCode plugins load additively and
unordered from the operator's global configuration, not exclusively
from this project's `opencode.json`; nothing in the plugin API verifies
or constrains multi-plugin `tool.execute.before` ordering, and nothing
prevents a co-loaded plugin from pre-empting or suppressing this
bridge's throw. This is not hypothetical: a concrete instance of
unrelated-plugin interference was already observed during this work — a
third-party global plugin made `tech-lead` spawnable as a subagent
(a state this framework treats as a defect) until this branch's own
`mode: primary` registration happened to shadow it. Closing every
implementation-level finding in § 7 — including the NEW-HIGH
privilege-escalation fix, which was a genuine, serious defect in the
bridge's *own* logic — raises the floor of what the bridge does
correctly when it runs uncontested; it does not raise the ceiling of
what the bridge can guarantee when it does not run uncontested. Those
are different axes, and this determination speaks to the second one.
This bridge is trustworthy as an honest-operator compliance mechanism —
it reliably translates and enforces the Python guards' verdicts against
a cooperating OpenCode installation with no other plugin actively
working against it — but it is not a boundary this assessment can claim
holds against an adversarial or misconfigured plugin environment. This
determination is unchanged from the original assessment and is not
softened by this re-assessment's closure of every implementation-level
finding.

---

## 11. Sign-off decision

**Decision:** SIGN-OFF WITH CONDITIONS

**Assessor:** `security-engineer`
**Date:** 2026-07-25

**Reasoning.** Every finding and process condition carried over from
the original assessment was independently re-verified in this pass by
direct reading of the shipped source, the mapping table, the release-gate
sub-gates, and the test file's assertions — no contradiction was found
between any claimed closure and the code implementing it (§ 7). That
alone would support a clean SIGN-OFF. This assessment nonetheless stops
short of a bare SIGN-OFF for two reasons, neither of which is a newly
discovered code defect:

1. **Method ceiling (UA-0001).** This pass was static-only — no
   execution capability was available to this assessor. On a
   security-relevant privilege-boundary artefact whose own history
   demonstrates exactly why that distinction matters (the original
   static-only pass is what named the gap that led to the spike which
   found the NEW-HIGH finding), issuing an unconditional sign-off
   without having run the shipped tests or reproduced the runtime
   spikes would let § 4's claim imply more confidence than § 2's
   method supports — precisely what `docs/templates/security-template.md`
   § 2's own guidance warns against.
2. **Two minor, independently-trackable process gaps** (UA-0002: no
   located durable code-review artefact; UA-0004: no regression test
   for S1's eviction path) that do not block functional correctness
   but are worth closing before this artefact is considered fully
   assured.

**Conditions:**

| Condition | Linked ID (§7/§8/§9) | Must be resolved by |
|---|---|---|
| Execute `tests/hooks/test-opencode-hook-bridge.sh` (Part B in full, especially B9–B13) against the exact release-candidate commit and confirm 0 failures; record the result. | UA-OPENCODE-HOOK-BRIDGE-0001 | Before this branch merges / before release tag |
| Execute the relevant `scripts/pre-release-gate.sh` sub-gates (hook-negative-corpus opencode mode, hook-exec-bits, opencode-hook-parity) against the release candidate and confirm PASS. | UA-OPENCODE-HOOK-BRIDGE-0001; SEC-OPENCODE-HOOK-BRIDGE-0009/0010/0011 | Release gate |
| `code-reviewer` confirms or produces the durable review record for commits `ac5d005`, `65349ea`, `c4bc456`, `1368fab`. | UA-OPENCODE-HOOK-BRIDGE-0002 | Before release |
| `qa-engineer` adds a regression test for S1's FIFO-eviction fail-safe behavior. | UA-OPENCODE-HOOK-BRIDGE-0004; SEC-OPENCODE-HOOK-BRIDGE-0008 | Next release touching this bridge (not release-blocking; LOW severity) |
| `tech-lead` obtains customer acceptance of RR-OPENCODE-HOOK-BRIDGE-0001 (discipline-control ceiling) and RR-OPENCODE-HOOK-BRIDGE-0002 (M-3 residual), recorded in `CUSTOMER_NOTES.md`. | RR-OPENCODE-HOOK-BRIDGE-0001, -0002 | Before this Hard Rule #7 sign-off takes effect (§ 12) |

M-3 (SEC-OPENCODE-HOOK-BRIDGE-0007 / RR-OPENCODE-HOOK-BRIDGE-0002)
itself does **not** block this sign-off — it is pre-existing,
cross-harness, unaffected by this bridge, and already named as
follow-up scope in `fw-adr-0031`. I confirm agreement with that framing
on this pass.

---

## 12. Record of sign-off

Per CLAUDE.md Hard Rule #7, this sign-off does not take effect until it
is recorded in `CUSTOMER_NOTES.md`, alongside the customer approval
required by Hard Rule #4. As of this document's authoring, no such
entry exists (confirmed by grep against `CUSTOMER_NOTES.md`). `librarian`
writes the `CUSTOMER_NOTES.md` entry; `tech-lead` obtains and relays
the customer approval, including acceptance of the two residual-risk
rows in § 8 that currently show "Not yet recorded." This assessor does
not write to `CUSTOMER_NOTES.md`.

- **`CUSTOMER_NOTES.md` entry date:** Not yet recorded
- **This assessment file:** `docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md`

---

## 13. References

- SWEBOK V4 ch. 13 "Software Security" (library row LIB-0002), §§4.1–4.6.
- ISO/IEC 15026-2:2022 — Systems and software assurance — Assurance case.
- ISO/IEC 27001:2022 — Information Security Management Systems.
- NIST SP 800-218 Secure Software Development Framework (SSDF).
- OWASP Application Security Verification Standard (ASVS).
- CWE / CAPEC taxonomies.
- `docs/adr/fw-adr-0031-opencode-hook-bridge.md` — the governing ADR;
  primary narrative source for the two runtime spikes this assessment
  did not itself reproduce, and for the binding verdict-translation
  and fail-open/fail-closed contracts evaluated in § 5.
- `.opencode/plugin/hook-bridge.js`, `scripts/opencode/tool-arg-map.json`,
  `scripts/verify-opencode-hook-parity.sh`, `scripts/lib/gate-hook-exec-bits.sh`,
  `scripts/lib/gate-hook-negative-corpus.sh`, `scripts/verify-hook-executable-bits.sh` —
  read directly for this assessment.
- `tests/hooks/test-opencode-hook-bridge.sh` — read directly; assertion
  shapes (B1–B13) confirmed against their described purpose.
- `.opencode/agents/*.md` — grepped for `webfetch`/`websearch`/`edit`
  permission frontmatter (M-3).
- `.opencode/.gitignore` — read to confirm OpenCode's own auto-generated
  `package.json`/`node_modules` are excluded from tracking per the
  ADR's binding requirement.
- `docs/templates/security-template.md` — this document's shape source.
- `docs/templates/operations-plan-template.md` § 7 — confirms the
  `docs/security/<subject>-assessment.md` filing convention this
  document follows.
- `CUSTOMER_NOTES.md` — grepped; confirmed no prior Hard Rule #7 entry
  for this artefact exists.
