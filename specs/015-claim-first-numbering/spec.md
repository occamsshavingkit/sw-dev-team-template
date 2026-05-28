# Feature Specification: Claim-First Numbering Reservation

**Feature Branch**: `015-claim-first-numbering`  
**Created**: 2026-05-27  
**Status**: Draft  
**Input**: User description: "Harden the framework's sequenced-ID reservation so reserving a number atomically creates a placeholder stub BEFORE content is written, preventing numbering collisions the customer has repeatedly hit (especially under the multi-machine/multi-operator coordination model from feature 014)."

## Clarifications

### Session 2026-05-27

- Q: Delivery mechanism — helper, convention, or both? (FR-010) → A: **Both** — a small reservation helper that atomically computes the next number (counting reserved placeholders) and writes the stub, PLUS a documented claim-first convention pointing humans and agents at the helper. The helper is the single source of the next-number logic.
- Q: Artifact-type scope for this feature? (FR-011) → A: **ADRs + spec directories + OPEN_QUESTIONS/DECISIONS rows only** — the genuine free-counter sequences. Migrations are version-named (`migrations/<semver>.sh`), not a free counter, so the next-integer reservation does not apply; excluded.
- Q: Integration with the feature-014 issues-coordination model? (FR-012) → A: **Independent** — the in-repo placeholder is the authoritative reservation primitive and works offline/single-operator; when the 014 issue interface is in use a reservation MAY also surface as a claimed issue, but that is never required (preserves the additive/opt-in non-goal and FR-008).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reserve a number without collisions (Priority: P1)

A contributor (human or agent) needs the next number for a sequenced artifact (an ADR, a spec directory, an OPEN_QUESTIONS/DECISIONS row). They reserve it and immediately get an exclusive placeholder claiming that number; a second contributor reserving at nearly the same time gets the *next* number, never the same one — because the reservation is visible the instant it is made.

**Why this priority**: This is the whole point — it eliminates the read-then-create-later window that has caused repeated collisions, which only gets worse under the feature-014 multi-machine model. Without it, the rest is just documentation.

**Independent Test**: Simulate two reservations of the same artifact type back-to-back (or interleaved); confirm they receive distinct, consecutive numbers and neither overwrites the other's placeholder.

**Acceptance Scenarios**:

1. **Given** the current highest number for an artifact type, **When** a contributor reserves the next one, **Then** a placeholder stub claiming that number is created as the first action (before any content authoring), and the number is now visibly taken.
2. **Given** one reservation just made, **When** a second contributor reserves the next number of the same type, **Then** the next-number computation counts the existing placeholder and returns the following number (no duplicate).
3. **Given** a reserved placeholder, **When** its content is authored later, **Then** the placeholder is filled in (not recreated) and the claimed number is unchanged.
4. **Given** two near-simultaneous reservations, **When** both complete, **Then** the two artifacts have distinct numbers and neither placeholder was overwritten.

---

### User Story 2 - One documented convention across artifact types (Priority: P2)

Contributors and agents follow a single, documented "claim-first numbering" convention that applies uniformly to the framework's numbered artifacts, so nobody falls back to the old read-then-create-later habit.

**Why this priority**: The mechanism (US1) must be backed by a clear, discoverable rule so it's actually followed across ADRs, specs, and registers; second because it depends on the mechanism existing.

**Independent Test**: The convention is documented and names each covered artifact type with its reserve procedure; a reviewer can follow it for an ADR, a spec, and a register row without guessing.

**Acceptance Scenarios**:

1. **Given** the convention doc, **When** a contributor reserves any covered artifact type, **Then** the doc tells them to create the placeholder first and how the next number is computed.
2. **Given** the covered artifact types, **When** inspected, **Then** ADRs (`fw-adr-NNNN`), spec directories (`specs/NNN-…`), and the in-repo register rows (`OPEN_QUESTIONS.md` Q-NNNN, `DECISIONS.md`) are each addressed.

---

### Edge Cases

- A reserved-but-never-filled placeholder (abandoned reservation) — it still holds its number; recovery/cleanup is documented (and does not silently re-issue the number).
- Gaps in the sequence (a number skipped or withdrawn) — next-number computation handles gaps deterministically (does not reuse a withdrawn number unless explicitly intended).
- A placeholder created out of band (manually) — the next-number computation still counts it.
- A reservation made on a different machine/branch not yet merged — documented limitation (the convention bounds, not eliminates, cross-branch collisions; the placeholder + the 014 issue-claim reduce it).
- Existing numbered artifacts (ADR 0001–0020, specs 001–015, Q-0001…) — the mechanism must read them correctly and never renumber or overwrite them.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Reserving a sequenced artifact MUST create a placeholder/stub that claims the number as the FIRST action, before any content is authored.
- **FR-002**: The next-number computation MUST count already-reserved placeholders (not just fully-authored artifacts) so a subsequent reserver gets the following number.
- **FR-003**: A reserved placeholder MUST be filled in (not recreated) when its content is later authored, and the claimed number MUST NOT change between reservation and authoring.
- **FR-004**: The reservation mechanism MUST cover at least: ADRs (`fw-adr-NNNN` under `docs/adr/`), spec directories (`specs/NNN-…`), and the in-repo register rows (`docs/OPEN_QUESTIONS.md` Q-NNNN and `docs/DECISIONS.md`).
- **FR-005**: A "claim-first numbering" convention MUST be documented so both human contributors and agents follow the same reserve procedure for every covered artifact type.
- **FR-006**: The mechanism MUST NOT renumber, overwrite, or corrupt existing numbered artifacts; it MUST read the current sequence (including gaps) deterministically.
- **FR-007**: The behavior MUST be covered by an automated test that simulates two reservations and asserts they receive distinct numbers and neither placeholder is overwritten.
- **FR-008**: The mechanism MUST be additive and MUST NOT disrupt single-operator or offline workflows (a contributor can still reserve correctly without any coordination infrastructure).
- **FR-009**: Reserved placeholders MUST be visibly distinguishable from completed artifacts (e.g. a `reserved`/`draft` status) so an abandoned/empty reservation is identifiable.
- **FR-010**: The framework MUST ship a reservation helper (a small script/command) that atomically computes the next free number for a given artifact type — counting reserved placeholders, not only authored artifacts — and writes the claiming stub; the documented convention MUST direct human contributors and agents to use this helper as the single source of the next-number logic (customer ruling 2026-05-27).
- **FR-011**: This feature's reservation scope MUST cover the free-counter sequences only: ADRs (`fw-adr-NNNN` under `docs/adr/`), spec directories (`specs/NNN-…`), and the in-repo register rows (`docs/OPEN_QUESTIONS.md` Q-NNNN and `docs/DECISIONS.md`). Migrations (`migrations/<semver>.sh`) are version-named, not a free counter, and are explicitly OUT of scope (customer ruling 2026-05-27).
- **FR-012**: Numbering reservation MUST be independent of the feature-014 issues-coordination model: the in-repo placeholder is the authoritative reservation primitive and MUST work offline/single-operator (FR-008). When the 014 issue interface is in use, a reservation MAY additionally surface as a claimed issue (cross-reference), but the issue MUST NOT be required for reservation (customer ruling 2026-05-27).
- **FR-013**: The reservation helper MUST provide a read-only / dry-run mode that returns the next free number for a family WITHOUT writing any stub or mutating any file, so the next number can be previewed and so the no-mutation guarantee (FR-006) is verifiable against the live repository.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority — the convention doc/ADR, any reservation helper under `scripts/`, and the reserve points are canonical framework-managed artifacts; this spec/plan/tasks are generated planning artifacts; reserved placeholders are draft artifacts until authored.
- **CA-002**: Customer-owned requirements — the customer directed this feature (recurring numbering collisions). Open sub-decisions are the three `[NEEDS CLARIFICATION]` markers (delivery mechanism, artifact scope, 014 integration), to resolve in `/speckit-clarify`.
- **CA-003**: Framework-managed edits — template-maintenance in `sw-dev-team-template` (`docs/` convention/ADR, `scripts/` helper, the ADR/spec/register reserve points). Meta-project speckit skills are harness-level and out of the shipped scope (may be referenced).
- **CA-004**: Adapter discipline — the mechanism is additive; it does not create a parallel authority or a second customer interface, and in-repo registers remain the binding records.

### Key Entities

- **Reservation placeholder**: the stub (ADR file with `reserved`/`draft` status, spec-dir stub, or register row) that claims a number at reserve time.
- **Sequence**: the ordered set of numbers in use for an artifact type (ADR, spec, Q-number), including gaps.
- **Next-number computation**: the deterministic function that returns the next free number, counting reserved placeholders.
- **Claim-first convention**: the documented rule + per-artifact reserve procedure.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In a simulated two-reservation scenario for a covered artifact type, the two reservations receive distinct, consecutive numbers and neither placeholder is overwritten (0 collisions across the test).
- **SC-002**: For every covered artifact type, the reserve procedure produces a number-claiming placeholder before any content is authored (verifiable per type).
- **SC-003**: Running the mechanism against the existing repository leaves all existing numbered artifacts unchanged (no renumber/overwrite) and computes the correct next number for each covered type.
- **SC-004**: A contributor can follow the documented convention to reserve an ADR, a spec, and a register row without external clarification.

## Assumptions

- "Atomic" reservation is best-effort within a single working tree (create-placeholder-first closes the in-tree read-then-create window); cross-branch/cross-machine collisions before merge are reduced and bounded, not fully eliminated (the 014 issue-claim is the cross-machine complement). This mirrors the advisory nature of the 014 claim model.
- The existing numbering schemes (zero-padded ADR `fw-adr-NNNN`, `specs/NNN`, `Q-NNNN`) are kept; this feature changes *when/how* a number is claimed, not the format.
- Reserved placeholders are committed/visible promptly so the claim is seen by others (a placeholder that is never saved cannot prevent a collision).
- Scope is framework-maintenance in `sw-dev-team-template`; the meta-project's own speckit-skill internals are harness-provided and not shipped by the template.
- The in-repo registers remain the binding records; reservation does not move authority into any external system.
