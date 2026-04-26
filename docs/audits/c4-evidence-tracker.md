# C-4 evidence tracker — workflow-pipeline empirical usage

**Owner:** `tech-lead`. **Drafted:** 2026-04-25.
**Bar source of truth:** `docs/v1.0-rc3-checklist.md` § C-4.
**Pipeline definition:** `docs/proposals/workflow-redesign-v0.12.md`.

This file is the **countdown to C-4 ship**. C-4 turns green when all
four counters below hit their bar AND each stage has had at least
one tuning pass recorded in `docs/pm/LESSONS.md` (or downstream
equivalent).

---

## Status at a glance

| Stage | Bar | Done | Status |
|---|---|---|---|
| Stage 1 — Prior-art (`docs/prior-art/<task-id>.md`) | ≥ 5 across ≥ 2 downstream projects | 5 (3 QuackS7 in `docs/prior-art/` + 2 QuackPLC research-memo equivalents in `docs/research/`) | 🟢 (caveat: QuackPLC files live in `docs/research/`, not `docs/prior-art/`; convention drift — see C-4 audit row) |
| Stage 2 — Three-path ADRs (M/S/C shape) | ≥ 5 ratified | 10 (7 FW-ADR-0001..0007 + 3 QuackS7 draft ADRs) | 🟢 |
| Stage 3 — Engineer proposal (`docs/proposals/<task-id>.md`) | ≥ 3 reviewed | 3 (FR-WP-006, Q-0012, legacy-OQ-0006 — all in QuackS7) | 🟢 |
| Stage 4 — Solution Duel (proposal § 8) | ≥ 3 held with outcome data | 3 (Duel annexes on the three QuackS7 proposals above) | 🟢 |
| Per-stage tuning recorded in `LESSONS.md` | ≥ 1 per stage | 0 (deferred — tuning passes follow accumulated evidence) | 🟡 |

**Net:** Stage 2 already met by FW-ADRs; Stages 1, 3, 4 still need
real downstream usage. Tuning passes happen *after* enough evidence
accumulates that a pattern is visible — chicken-and-egg with
evidence collection.

---

## How a task fires the pipeline

Per `docs/proposals/workflow-redesign-v0.12.md` § 2, **any one** of
these clauses triggers the full pipeline. Mechanically checkable;
not judgment:

1. New external dependency (direct, not transitive pin bump).
2. Public-API change (exported symbol named in requirements / ADR /
   public-interface doc).
3. Cross-module boundary crossed (≥ 2 top-level packages).
4. Safety-critical or Hard-Rule-#4 path touched.
5. Hard-Rule-#7 path touched (auth / authz / secrets / PII /
   network-exposed surface).
6. Data-model change (schema, serialization, persistence swap).

**Below threshold** (skip pipeline): typo fix, single-function
internal refactor, log line, docstring update, lint tightening.

When `tech-lead` opens a triggered task in `docs/tasks/T-NNNN.md`,
it stamps the trigger annotation per `tech-lead.md` § "Trigger
annotation (binding)". From there, the pipeline runs in order:

1. `researcher` writes `docs/prior-art/T-NNNN.md`.
2. `architect` writes the three-path ADR (M/S/C). FW-ADR-0001..0007
   are exemplars of the shape.
3. `software-engineer` writes `docs/proposals/T-NNNN.md`, citing
   the prior-art file and the chosen ADR path.
4. `qa-engineer` (+ `security-engineer` on Rule-#7 paths) appends
   § 8 Duel findings to the proposal. Engineer revises in place
   or rebuts in-annex. `tech-lead` closes the duel.
5. Code lands.

---

## Evidence ledger

Append below as artefacts land. One row per artefact. Source
project links to the file in that project's repo, not in this
template repo.

### Stage 1 — Prior-art

| # | Project | Task | File | Date |
|---|---|---|---|---|
| 1 | QuackS7 | FR-WP-006 (PREEMPT_RT stress harness) | `docs/prior-art/FR-WP-006-preempt-rt.md` | 2026-04-25 |
| 2 | QuackS7 | Q-0012 (upstream bugs schema) | `docs/prior-art/Q-0012-upstream-bugs.md` | 2026-04-25 |
| 3 | QuackS7 | legacy-OQ-0006 (upstream PR cadence) | `docs/prior-art/legacy-OQ-0006-upstream-pr-cadence.md` | 2026-04-25 |
| 4 | QuackPLC | Q-0034 (pragma system) | `docs/research/pragma-system-prior-art-2026-04-24.md` (convention drift — see audit) | 2026-04-24 |
| 5 | QuackPLC | post-M1 protocol licensing | `docs/research/protocol-licensing-survey-2026-04-24.md` (convention drift — see audit) | 2026-04-24 |

### Stage 3 — Proposal (excluding the workflow-redesign meta-proposal that defined the pipeline)

| # | Project | Task | File | Reviewer (qa) | Date |
|---|---|---|---|---|---|
| 1 | QuackS7 | FR-WP-006 stress harness | `docs/proposals/FR-WP-006-stress-harness.md` | qa-engineer (in proposal § 8) | 2026-04-25 |
| 2 | QuackS7 | Q-0012 upstream bugs | `docs/proposals/Q-0012-upstream-bugs.md` | qa-engineer (in proposal § 8) | 2026-04-25 |
| 3 | QuackS7 | legacy-OQ-0006 upstream PR cadence | `docs/proposals/legacy-OQ-0006-upstream-pr-cadence.md` | qa-engineer (in proposal § 8) | 2026-04-25 |

### Stage 4 — Solution Duel

| # | Project | Task | Proposal file | Engineer rebuttal | Outcome | Date |
|---|---|---|---|---|---|---|
| 1 | QuackS7 | FR-WP-006 stress harness | `docs/proposals/FR-WP-006-stress-harness.md` § 8 | round-2 revision in proposal | Duel held; outcome captured in proposal § 8 | 2026-04-25 |
| 2 | QuackS7 | Q-0012 upstream bugs | `docs/proposals/Q-0012-upstream-bugs.md` § 8 | round-2 revision in proposal | Duel held; outcome captured in proposal § 8 | 2026-04-25 |
| 3 | QuackS7 | legacy-OQ-0006 upstream PR cadence | `docs/proposals/legacy-OQ-0006-upstream-pr-cadence.md` § 8 | round-2 revision in proposal | Duel held; outcome captured in proposal § 8 | 2026-04-25 |

### Stage 2 — Three-path ADRs (already met; logged for completeness)

| # | Repo | ADR | Title | Date |
|---|---|---|---|---|
| 1 | template | FW-ADR-0001 | Context memory strategy | (see CHANGELOG) |
| 2 | template | FW-ADR-0002 | Upgrade content verification | |
| 3 | template | FW-ADR-0003 | Bare template variants | |
| 4 | template | FW-ADR-0004 | Per-item file breakout | |
| 5 | template | FW-ADR-0005 | Standards paraphrase cards | |
| 6 | template | FW-ADR-0006 | MADR required-optional split | |
| 7 | template | FW-ADR-0007 | External reference adoption | |

---

## Candidate triggering tasks (ready to fire)

Tagged 2026-04-25. Each entry: project · task · which clauses fire ·
why it's a strong fit. Pick the next 3–5 from this list to drive
C-4 ship. Some will fire all four stages; others (single-clause)
still produce one-or-two stages of evidence.

### QuackPLC

- **C-PLC-001 — Modbus-TCP server implementation (M1).** Clauses 1
  (new dep: a Modbus crate), 2 (public-API: TCP port + register
  layout in requirements), 3 (cross-module: runtime ↔ adapter ↔
  config). All four pipeline stages applicable. *Owner: software-
  engineer Pongo.*
- **C-PLC-002 — Web monitoring UI (M1).** Clauses 1 (HTTP
  framework), 2 (public-API: HTTP endpoints), 3 (cross-module:
  runtime ↔ HTTP ↔ static assets). All four stages. *Owner:
  software-engineer Pongo + tech-writer Peg.*
- **C-PLC-003 — IL execution backend ADR (Q-0020).** Clauses 2, 3,
  6 (data model: IR format). Three-path ADR is the centrepiece;
  also produces prior-art (interpreter vs JIT vs cranelift) and
  proposal + duel for the chosen path. All four stages. *Owner:
  architect Gromit.*
- **C-PLC-004 — Commit-after-successful-swap (M2).** Clauses 4
  (safety-critical), 6 (persistence). All four stages — strongest
  Duel candidate (failure-mode scenarios are exactly what the Duel
  surfaces). *Owner: architect Gromit + sre Hachi.*
- **C-PLC-005 — Squashfs/LBU root for M2.** Clauses 1 (squashfs
  tooling), 3 (cross-module: builder ↔ runtime ↔ persistence), 6
  (boot/persistence model). All four stages. *Owner: release-
  engineer Bella + architect Gromit.*

### QuackS7

- **C-S7-001 — MC7 decompiler (Phase 5 hard).** Clauses 1 (binary
  parser library), 3 (cross-module: parser ↔ AWL emitter), 6 (data
  model: MC7 binary format). All four stages. *Owner: software-
  engineer scooter + s7-braumat SME rowlf.*
- **C-S7-002 — SFB 14/15 GET/PUT (Phase 5 promoted).** Clauses 2
  (S7comm protocol public surface), 3 (cross-module: S7comm ↔
  blocks ↔ memory). All four stages. *Owner: scooter + rowlf.*
- **C-S7-003 — Modbus TCP/RTU master (Phase 4).** Clauses 1, 2, 3.
  Mirrors C-PLC-001 in shape but in the QuackS7 codebase — useful
  for cross-project pattern comparison in the eventual tuning
  pass. *Owner: scooter.*
- **C-S7-004 — DP-config + S7-connection extraction (Phase 4).**
  Clauses 3, 6. Likely two-or-three-stage (Duel may be light if no
  failure modes surface). *Owner: scooter.*

---

## Path to ship

Minimum to flip C-4 green:

1. **Pick 3 of the candidate tasks** above (any 3 — bar is union
   across both projects). Recommend at least one from each project
   for the "≥ 2 downstream projects" prior-art clause.
2. **Run the full pipeline on each.** Don't skip stages. The Duel
   is the highest-value-per-effort step (catches pre-code bugs)
   and the easiest to underuse — set a reminder.
3. **After 3 completed runs, write the per-stage tuning passes
   into `docs/pm/LESSONS.md`** (in each project, or in a shared
   summary referenced from this tracker). Even a one-paragraph
   "what we learned tuning Stage X" entry counts.

Realistic timeline: at the natural pace of QuackPLC + QuackS7
work, this accumulates over ~2–3 weeks. Faster if a triggering
task is already mid-flight when this tracker lands (C-PLC-003 and
C-S7-001 are both warm candidates).

**Anti-pattern to avoid:** synthesising prior-art / proposals /
duels for tasks that *don't* actually trigger the pipeline. C-4 is
about *empirical* usage; manufactured artefacts fail the spirit of
the criterion and bias future tuning toward unrepresentative
shapes. Better to wait for a real trigger than to fake one.

---

## Revision log

| Date | Change | Who |
|---|---|---|
| 2026-04-25 | Tracker created. Stage 2 marked green (FW-ADR-0001..0007); Stages 1, 3, 4 unstarted. Candidate tasks identified. | `tech-lead` |
| 2026-04-26 | Tally updated by `code-reviewer` during rc3 readiness audit. Stage 1 = 5 (3 QuackS7 prior-art + 2 QuackPLC research-memo equivalents); Stage 2 = 10 (FW-ADR-0001..0007 + 3 QuackS7 draft ADRs); Stage 3 = 3 (QuackS7 proposals FR-WP-006, Q-0012, legacy-OQ-0006); Stage 4 = 3 (Duel annexes on the same three). All four stages above bar; per-stage tuning still pending. | `code-reviewer` |
