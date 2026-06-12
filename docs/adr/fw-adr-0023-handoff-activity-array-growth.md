---
name: fw-adr-0023-handoff-activity-array-growth
description: >
  Two coupled decisions on handoff JSON integrity: (1) deliberate hash-exclusion
  of the runtime-mutable "activity" array from TEMPLATE_MANIFEST.lock verification,
  and (2) disposition of the unbounded growth that exclusion exposes.
status: accepted
date: 2026-06-02
---


# FW-ADR-0023 — Handoff activity-array: hash-exclusion and unbounded growth

<!-- TOC -->

- [Status](#status)
- [Scaffold placement note](#scaffold-placement-note)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Decision 1 — Hash-exclusion of the activity array](#decision-1--hash-exclusion-of-the-activity-array)
  - [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
    - [Option M — Minimalist: gitignore handoff files](#option-m--minimalist-gitignore-handoff-files)
    - [Option S — Scalable: normalize before hashing (shipped as #276 fix)](#option-s--scalable-normalize-before-hashing-shipped-as-276-fix)
    - [Option C — Creative: separate activity sidecar, handoff files stay static](#option-c--creative-separate-activity-sidecar-handoff-files-stay-static)
  - [Decision outcome — D1](#decision-outcome--d1)
  - [Security trade-off (explicit)](#security-trade-off-explicit)
- [Decision 2 — Unbounded growth of the activity array](#decision-2--unbounded-growth-of-the-activity-array)
  - [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding-1)
    - [Option M — Minimalist: leave as-is](#option-m--minimalist-leave-as-is)
    - [Option S — Scalable: move activity to a sidecar file outside the manifest set](#option-s--scalable-move-activity-to-a-sidecar-file-outside-the-manifest-set)
    - [Option C — Creative: cap-and-rotate within the handoff file](#option-c--creative-cap-and-rotate-within-the-handoff-file)
  - [Decision outcome — D2](#decision-outcome--d2)
- [Consequences](#consequences)
  - [Positive (D1, already realized)](#positive-d1-already-realized)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up work](#follow-up-work)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). Two coupled decisions (D1
hash-exclusion, D2 growth disposition) are recorded in one ADR because
they share the same root: `activity` is runtime telemetry stitched into
a git-tracked durable contract file.

---

## Status

- **Proposed** — 2026-06-02
- **Accepted** — 2026-06-03. Option S (Sidecar) adopted per customer ruling 2026-06-03; move `activity` array to gitignored `docs/handoffs/<task>.activity.jsonl`, MINOR schema bump + one-time migration, remove hash-exclusion normalizer.
- **D1 (hash-exclusion):** implemented in PR #304 / issue #276; this ADR
  provides post-hoc rationale and security trade-off documentation for
  the shipped fix. No further implementation work required for D1.
- **D2 (growth):** Option S (Sidecar) chosen; customer ruling recorded 2026-06-03; implemented in this PR (`feat/activity-sidecar`).
- **Deciders:** `architect` (proposed); `tech-lead` + customer (accepted 2026-06-03)
- **Consulted:** `scripts/lib/manifest.sh` (`manifest_file_sha_normalized`,
  PR #304); `security-engineer` (sign-off on #276, recorded in
  `CUSTOMER_NOTES.md` 2026-06-02); FW-ADR-0002 (manifest model);
  FW-ADR-0014 (preservation vs manifest); issue #276

## Scaffold placement note

This ADR was drafted in the meta-project (`docs/adr/`) per the PLAN/DO
convention (CLAUDE.md § "Project Identity / Working Tree"). It migrated
into the scaffold's `docs/adr/` as part of the D2 implementation PR
(`feat/activity-sidecar`) so the rationale travels with the code,
matching the pattern established by FW-ADR-0001 through FW-ADR-0022.
The meta-project draft copy is retained as the team's working reference;
this scaffold copy is the canonical version from the implementation PR
forward.

---

## Context and problem statement

FW-ADR-0002 introduced `TEMPLATE_MANIFEST.lock`: a git-tracked file
containing SHA256 hashes of every template-shipped file. `upgrade.sh
--verify` compares on-disk hashes against the manifest to detect drift
without network access.

`docs/handoffs/*.json` files are template-shipped (they carry durable
contract data: `status`, `mode`, `allowed_paths`, `hard_rule_traces`,
`acceptance_criteria`, `verification`) and therefore appear in the
manifest.

An activity hook (`handoff-record-activity.py`) appends an entry to the
top-level `"activity"` array inside each handoff JSON file on every
PreToolUse and PostToolUse boundary during a session. This is runtime
telemetry — it is not a durable contract field — but it lives in the
same file as the durable fields. The result: the file's SHA256 changes
on every tool call, causing `--verify` to report drift on every session
even when no contract field changed.

PR #304 (issue #276) shipped a fix: `manifest_file_sha_normalized` in
`scripts/lib/manifest.sh` strips `"activity"` before hashing, applied
symmetrically in both `manifest_write` and `manifest_verify`. The fix
is fail-closed: if `python3` is unavailable it returns an error rather
than silently falling back to the raw hash.

A reviewer flagged two residual concerns not addressed by the PR:
1. The `"activity"` content receives no integrity guarantee once
   excluded from hashing. Is that acceptable?
2. The `"activity"` array grows without bound on every session; the
   handoff files are git-tracked. What is the long-term growth
   disposition?

This ADR records the structural decisions behind the shipped fix (D1)
and evaluates options for the growth problem (D2).

---

## Decision drivers

- **Manifest integrity must be stable.** `--verify` serving a false
  "drift" on every session destroys operator trust and CI signal.
  This was the immediate driver for the #276 fix.
- **Fail-closed.** An unavailable normalizer must not silently produce
  a wrong hash. The PR satisfied this with the `python3` guard.
- **Symmetric write/verify.** The hash used at manifest-write time
  must be computed identically at verify time. Asymmetry produces
  either permanent drift (write includes activity, verify strips it)
  or a false clean (write strips, verify includes).
- **Security honesty.** A reviewer correctly noted that excluding a
  field from integrity coverage is a security-relevant choice that
  must be named and justified, not left implicit.
- **Git hygiene.** Unbounded growth in a git-tracked file compounds
  with every session — clone size, diff noise, pre-commit hook
  runtime — and is a correctness risk for tooling that greps handoff
  content.
- **Backward compatibility.** Any growth remediation must not break
  existing handoff consumers (the gate hook, the bounded-Codex
  schema, `schemas/handoff.schema.json`).

---

## Decision 1 — Hash-exclusion of the activity array

### Considered options (Three-Path Rule, binding)

#### Option M — Minimalist: gitignore handoff files

Add `docs/handoffs/*.json` to `.gitignore` so the activity-mutated
files are never tracked, and remove them from the manifest set.

- **Sketch:** One `.gitignore` entry; `manifest_ship_files` exclusion
  regex gains a `docs/handoffs/` line. Manifest no longer covers
  handoff files. Implementation cost: one PR, zero Python, no new
  `manifest.sh` function.
- **Pros:** Simple; eliminates the drift problem entirely; no integrity
  surface to reason about for handoff files.
- **Cons:** Also eliminates verification of the _durable_ fields
  (`allowed_paths`, `acceptance_criteria`, `verification`, etc.) that
  the manifest is supposed to protect. A hand-edit to
  `fw-012-v1-1-handoff-contracts.json`'s `allowed_paths` would go
  undetected by `--verify`. This is a regression in the framework's
  tamper-evidence promise, which FW-ADR-0002 makes explicitly for all
  template-shipped files. Also, untracked runtime-telemetry files have
  no audit trail of session activity.
- **When M wins:** if the durable contract fields in handoff files
  needed no integrity coverage — i.e., if handoffs were treated as
  fully operator-owned. They are not: the bounded-Codex gate in
  FW-ADR-0021 depends on `allowed_paths` and `acceptance_criteria`
  being tamper-evident.

#### Option S — Scalable: normalize before hashing (shipped as #276 fix)

Strip `"activity"` from the JSON before computing the hash, both at
write time and at verify time, using canonical JSON serialization
(sorted keys). All other fields remain under integrity coverage.

- **Sketch:** `manifest_file_sha_normalized` in `scripts/lib/manifest.sh`
  (already implemented). Applies only to `docs/handoffs/*.json` by
  path pattern. All other files use the raw `manifest_file_sha` path
  unchanged.
- **Pros:** Durable contract fields remain covered by the manifest.
  Session telemetry stops causing spurious drift. Symmetric write/verify
  produces stable hashes. Fail-closed on missing `python3`. Narrow
  scope — only handoff files are normalized; all other template files
  are hashed raw.
- **Cons:** The `"activity"` key and its contents receive no integrity
  guarantee. An actor who can write to a handoff file can inject
  arbitrary content into `"activity"` without detection by `--verify`.
  This is the security trade-off named explicitly in the section below.
- **When S wins:** when the durable contract fields must stay covered and
  the telemetry field's integrity is acceptable to leave unguaranteed.
  That is the framework's actual posture (see security trade-off below).

#### Option C — Creative: separate activity sidecar, handoff files stay static

Move the `"activity"` array out of the handoff JSON entirely. The hook
writes to `docs/handoffs/<task_id>.activity.jsonl` (a newline-delimited
append-only log) instead of mutating the handoff JSON. The handoff JSON
becomes fully static after creation; `manifest_file_sha_normalized` is
no longer needed; the raw `manifest_file_sha` path applies to all files.

- **Sketch:** Modify `handoff-record-activity.py` to open a sidecar
  `*.activity.jsonl` file instead of loading and rewriting the handoff
  JSON. Add `docs/handoffs/*.activity.jsonl` to `.gitignore` (or track
  them separately). `schemas/handoff.schema.json` drops `"activity"` or
  marks it deprecated. `manifest_ship_files` exclusion regex ignores
  `*.activity.jsonl`.
- **Pros:** Handoff files are structurally static after creation;
  hashing is simple and no normalizer is needed. Sidecar files can be
  gitignored without losing durable contract integrity. Eliminates the
  growth problem in git history. Clean separation of concerns: durable
  contract vs. runtime log.
- **Cons:** Requires a schema change to `schemas/handoff.schema.json`
  (removing or deprecating `"activity"`); a migration for any existing
  handoff files that already carry accumulated `"activity"` entries;
  and a change to `handoff-record-activity.py`. Downstream consumers
  that read `handoff.activity` must be updated. This is the correct
  long-term architecture but has non-trivial migration cost.
- **When C wins:** when the growth problem (D2) is resolved in favor of
  the sidecar model — the Option C sidecar _is_ the D2 Option S
  approach (see below). The two decisions are coupled.

### Decision outcome — D1

**Chosen option: S — Normalize before hashing (shipped in PR #304)**

Option M drops durable contract integrity for handoff files; that
regresses the tamper-evidence property FW-ADR-0002 exists to provide
and which the bounded-Codex gate (FW-ADR-0021) depends on. Option C
is the structurally correct long-term design but carries schema
migration cost that was not in scope for the #276 hotfix; it maps to
the D2 growth-remediation track below. Option S is the narrowest
correct fix: it preserves durable-field integrity, is fail-closed, is
symmetric, and does not require a schema change or migration. The #276
fix shipped under Option S.

### Security trade-off (explicit)

**The `"activity"` array has no integrity guarantee under this scheme.**
Content written into `"activity"` by `handoff-record-activity.py` — or
by any other process with write access to the handoff file — is
invisible to `--verify`. A compromised or malicious hook could inject
content into `"activity"` without detection.

Why this is accepted:

1. **`"activity"` is session telemetry, not a trust boundary.** It
   records tool call events for observability. No framework gate, no
   bounded-Codex authorization path, and no customer-facing decision
   reads from `"activity"` as a source of authority. A manipulated
   `"activity"` log cannot cause the framework to take a privileged
   action.
2. **The integrity coverage that matters is on the durable contract
   fields.** `allowed_paths`, `acceptance_criteria`, `verification`,
   `status`, `mode`, and `hard_rule_traces` remain covered by the
   manifest hash. These are the fields the bounded-Codex gate and the
   operator's security posture depend on.
3. **Write access to handoff files is equivalent to write access to the
   repo.** The threat model for `TEMPLATE_MANIFEST.lock` is not
   adversarial injection by an actor with filesystem access — it is
   silent drift from tooling bugs, partial upgrades, or hand-edits.
   FW-ADR-0002 states this explicitly (Option C/tree-hash was rejected
   because "supply-chain attack threat models" are not in scope).
4. **`security-engineer` reviewed and signed off on this trade-off**
   for the #276 fix (recorded in `CUSTOMER_NOTES.md` 2026-06-02,
   confirmed via the two carry-forward items noted there; neither
   carry-forward blocks the D1 decision).

If `"activity"` is ever read by a trust-sensitive code path, this
trade-off must be re-evaluated and this ADR superseded.

---

## Decision 2 — Unbounded growth of the activity array

The `"activity"` array in `docs/handoffs/*.json` grows by at least two
entries (PreToolUse + PostToolUse) per tool call per session. A session
with 200 tool calls adds 400 entries. These files are git-tracked; the
array's growth is recorded in every commit and every clone. On a project
with several active handoffs and long sessions, the cumulative size can
reach hundreds of kilobytes of telemetry in git history within weeks.

This is a distinct problem from the hash-exclusion decision. Hash
exclusion prevents `--verify` noise; it does not stop the files from
growing.

### Considered options (Three-Path Rule, binding)

#### Option M — Minimalist: leave as-is

Accept unbounded growth. Document it. Rely on periodic `git gc` and
periodic manual pruning of `"activity"` entries by operators.

- **Sketch:** No code change. Add a note in `docs/handoffs/README.md`
  (or equivalent) describing the growth behavior and recommending
  operators truncate `"activity"` to `[]` before committing.
- **Pros:** Zero implementation cost. No schema change. No migration.
  No risk of breaking existing consumers.
- **Cons:** Operator discipline as the only control. In practice,
  telemetry entries accumulate silently because no agent or gate
  prompts the operator to prune. Clone size grows monotonically.
  Grep and diff tooling that reads handoff files becomes noisier.
  The #276 fix made the growth invisible to `--verify` but did
  nothing to stop it in git history.
- **When M wins:** if the volume of tool calls per session were low,
  handoff lifetimes were short, or the project repo were
  ephemeral. None hold for the typical multi-week framework project.

#### Option S — Scalable: move activity to a sidecar file outside the manifest set

Move runtime telemetry out of the handoff JSON entirely. The hook
writes to `docs/handoffs/<task_id>.activity.jsonl` (or
`.activity.json`), which is gitignored. The handoff JSON drops the
`"activity"` key. The manifest normalizer in D1 is then a no-op for
handoff files and can eventually be removed.

- **Sketch:**
  - `handoff-record-activity.py` writes to
    `docs/handoffs/<task_id>.activity.jsonl` (append-only, one JSON
    object per line) instead of mutating the handoff JSON.
  - `docs/handoffs/*.activity.jsonl` is added to `.gitignore`.
  - `schemas/handoff.schema.json` removes or deprecates `"activity"`.
  - A migration strips `"activity"` from existing handoff JSON files
    and optionally exports accumulated entries to sidecar files.
  - `manifest_file_sha_normalized` in `manifest.sh` becomes a no-op
    for handoff files (or is removed in a follow-up, since normalization
    is no longer needed).
- **Pros:** Structural fix. Git history no longer accumulates telemetry.
  Handoff JSON files are static after creation; hash verification is
  simple and needs no special normalizer. Clean separation of concerns.
  Gitignored sidecars are not subject to manifest coverage questions.
  Forward-compatible: consumers that need activity logs read the
  sidecar; consumers that need the contract read the JSON.
- **Cons:** Schema change to `schemas/handoff.schema.json`. Migration
  required for existing handoff files carrying `"activity"`. Change to
  `handoff-record-activity.py`. Any downstream project or tool that
  reads `handoff["activity"]` must be updated. This is real work (one
  sprint), not a hotfix.
- **When S wins:** when the growth problem is real and git history
  hygiene matters for the project's lifetime. Recommended (see below).

#### Option C — Creative: cap-and-rotate within the handoff file

Keep `"activity"` in the handoff JSON but impose a hard cap (e.g.,
the most recent N entries, with older entries replaced by a summary
count). The hook trims `"activity"` to the last N entries on every
write.

- **Sketch:** `handoff-record-activity.py` reads the current
  `"activity"` array, appends the new entry, and discards entries
  beyond a cap (e.g., 100). The handoff JSON's `"activity"` array
  never exceeds N entries. Git history still grows (each session
  produces a modified file), but the per-file size is bounded.
- **Pros:** No schema change. No migration for durable contract fields.
  No gitignore change. Simpler than Option S. Activity data stays in
  one file.
- **Cons:** Git history still accumulates churn on every session (the
  file is still modified and committed). The cap is arbitrary; the
  right value is unclear and potentially project-dependent. Older
  activity entries are silently discarded — if a debugging or audit
  scenario needs the full history, it is gone. A summary-count
  replacement loses individual event fidelity. The normalizer in D1
  (`manifest_file_sha_normalized`) is still required and still
  carries the `"activity"`-has-no-integrity-guarantee trade-off.
  Essentially this option buys bounded file size while keeping all
  the other costs of D1's accepted trade-off.
- **When C wins:** when the schema migration cost of Option S is
  prohibitive and a bounded file size is sufficient — i.e., the team
  needs a quick bound without a structural fix. It is an acceptable
  interim step if D2 implementation must be deferred.

### Decision outcome — D2

**Chosen option: S — Sidecar file, gitignored.**

Customer ruling recorded 2026-06-03: Option S adopted. Implemented in
`feat/activity-sidecar`.

Option M is the prior state and has known long-term hygiene costs
with no structural bound. Option C bounds file size but keeps git
churn and the `"activity"`-has-no-integrity-guarantee trade-off alive
indefinitely. Option S is the structurally correct fix: it eliminates
git churn for telemetry, removes the normalizer dependency, and
cleanly separates runtime telemetry from durable contract data. The
migration cost is real but bounded and follows the existing pattern of
schema version bumps (FW-ADR-0021 set the precedent for the handoff
schema with a MINOR bump).

If Option C had been chosen as an interim step pending a later Option S
migration, a follow-up ADR would record the interim status explicitly.

---

## Consequences

### Positive (D1, already realized)

- `--verify` no longer reports spurious drift on handoff files after
  every session. Operator trust in the manifest is restored.
- Durable contract fields (`allowed_paths`, `acceptance_criteria`,
  `verification`, `status`, `mode`, `hard_rule_traces`) remain under
  integrity coverage. The bounded-Codex gate (FW-ADR-0021) retains
  its tamper-evidence foundation.
- The normalizer is fail-closed: a missing `python3` produces an error
  rather than a silently wrong hash.
- The symmetric write/verify design means no manifest entry can be
  written with one hash function and verified with another.

### Negative / trade-offs accepted

- **`"activity"` has no integrity guarantee (D1, accepted).** Named and
  bounded above. Acceptable because `"activity"` is not on any trust
  or authorization path. Must be re-evaluated if that changes.
- **The normalizer is a new failure mode in the manifest write/verify
  path (D1).** If the inline Python in `manifest_file_sha_normalized`
  has a bug, it affects all handoff file hashes symmetrically (write
  and verify agree on a wrong hash). Mitigation: the normalizer is
  small (~5 lines of Python), its behavior is unit-testable, and the
  fail-closed guard prevents a silent wrong answer.
- **D2 Option S requires schema migration.** Any downstream project or
  tool that reads `handoff["activity"]` must be updated. The migration
  strips `"activity"` from existing handoff files; this is a one-way
  data transformation for the JSON file (the data migrates to the
  sidecar, not discarded).

### Follow-up work

- Remove or no-op the handoff-file branch of `manifest_file_sha_normalized`
  in a follow-up PR once the sidecar migration is confirmed stable in
  downstream projects. The normalizer is still correct to leave in place
  during the transition; removing it is a cleanup, not a correctness fix.
- Any downstream project that reads `handoff["activity"]` directly must
  be updated to read the sidecar `*.activity.jsonl` instead.

---

## Verification

- **D1 success signal (already verified in PR #304):** `upgrade.sh
  --verify` exits 0 on a project where `handoff-record-activity.py`
  has appended entries since the last manifest write. The manifest
  hash for the handoff file matches the post-strip SHA regardless of
  how many `"activity"` entries are present. `manifest_file_sha_normalized`
  returns an error (non-zero exit) when `python3` is absent.
- **D1 failure signal:** `--verify` reports drift on a handoff file
  whose only change since manifest-write is new `"activity"` entries
  (indicates the normalizer is not being applied symmetrically); or
  `--verify` exits 0 on a handoff file whose durable contract fields
  were modified without a manifest regeneration (indicates the
  normalizer is stripping too much).
- **D2 success signal:** `git log --stat` on a multi-session branch
  shows no modifications to `docs/handoffs/*.json` attributable to
  telemetry; sidecar files exist locally but do not appear in `git
  status` (gitignored); existing handoff consumers continue to read
  durable contract fields correctly.
- **D2 failure signal:** git history grows at the same rate as before
  the remediation; or a consumer of `"activity"` breaks silently
  after the sidecar migration without producing an error.
- **Review cadence:** Re-examine at the next MINOR release that touches
  `handoff-record-activity.py`, `schemas/handoff.schema.json`, or
  `manifest_file_sha_normalized`. Supersede or close if the normalizer
  is removed and all known consumers have migrated to sidecars.

---

## Links

- Issue #276 (root cause: activity growth breaks `--verify`)
- PR #304 (D1 fix: `manifest_file_sha_normalized`)
- FW-ADR-0002 (`docs/adr/fw-adr-0002-upgrade-content-verification.md`) —
  the manifest model this ADR amends; security threat-model scoping
  (supply-chain not in scope)
- FW-ADR-0014 (`docs/adr/fw-adr-0014-preservation-vs-manifest.md`) —
  preservation vs manifest semantics; `manifest_file_sha_normalized`
  is called from the same `manifest_write` / `manifest_verify` paths
  this ADR's D1 fix touches
- FW-ADR-0021 (`docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`) —
  bounded-Codex gate that depends on durable handoff contract fields
  being tamper-evident
- `scripts/lib/manifest.sh` — `manifest_file_sha_normalized` (D1
  implementation), `manifest_write`, `manifest_verify`
- `scripts/hooks/handoff-record-activity.py` — the hook whose writes
  trigger the growth problem; modified in D2 implementation
- `schemas/handoff.schema.json` — the `"activity"` field definition;
  deprecated/removed by D2 schema change
- `docs/handoffs/fw-012-v1-1-handoff-contracts.json` — example of an
  existing handoff file; `"activity"` entries migrated to sidecar by
  D2 migration
- `CUSTOMER_NOTES.md` (2026-06-02) — `security-engineer` sign-off on
  #276; two carry-forward items (neither blocks D1)
