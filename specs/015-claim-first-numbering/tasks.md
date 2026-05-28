# Tasks: Claim-First Numbering Reservation

**Input**: Design documents from `specs/015-claim-first-numbering/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Verification**: Each task has exactly one `Primary verification:` command or review check.
**Organization**: Tasks grouped by user story. All source paths under `sw-dev-team-template/`. The helper is built test-first (TDD).

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the test location for the reservation helper.

- [X] T001 Create `sw-dev-team-template/tests/numbering/` and an executable harness skeleton `test-reserve-number.sh` (record_pass/record_fail idiom; runs against a SANDBOX/temp fixture repo so it never mutates the live repo; exits 0 with a sanity assertion). Primary verification: `cd sw-dev-team-template && test -x tests/numbering/test-reserve-number.sh && tests/numbering/test-reserve-number.sh`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: None beyond Setup — the reservation helper is the US1 core; the convention (US2) and tests build on it. (No separate foundational task.)

---

## Phase 3: User Story 1 - Reserve a number without collisions (Priority: P1)

**Goal**: A reservation helper that, per free-counter family, computes the next number (counting reserved placeholders) and writes a `reserved` claiming stub first — so two reservers never collide and existing artifacts are never renumbered/overwritten.

**Independent Test**: Two reservations of the same family get distinct consecutive numbers; neither stub overwritten; existing artifacts unchanged; offline.

### Implementation for User Story 1

- [X] T002 [US1] Author the US1 red tests (test-first) in `sw-dev-team-template/tests/numbering/test-reserve-number.sh` against a sandbox fixture: two reservations → distinct consecutive numbers (FR-002/SC-001); neither stub overwritten (FR-006/I2); a reserved-but-unauthored stub is counted by next-number (FR-002/I4); existing numbered artifacts unchanged + correct next number (FR-006/SC-003/I3); withdrawn-gap not reused (R2/I5); offline/no-network (FR-008/I6). Cases expected RED until T003–T005. Primary verification: `grep -q 'US1:' sw-dev-team-template/tests/numbering/test-reserve-number.sh`
- [X] T003 [US1] Implement `sw-dev-team-template/scripts/reserve-number.sh` for the FILE families (adr, spec): next-number = max+1 counting authored + reserved stubs (zero-padded; ADR 4-digit, spec 3-digit), write a `reserved`/`draft` claiming stub (ADR `status: reserved` front-matter; `specs/NNN-<slug>/spec.md` Status: Reserved), no-overwrite guard (nonzero exit, no mutation), offline, AND a `--dry-run` mode that prints the next number and writes nothing (FR-013/I7); per `contracts/reservation-helper.md` (FR-001/002/003/006/008/010/013). Primary verification: the adr+spec US1 cases pass — `cd sw-dev-team-template && tests/numbering/test-reserve-number.sh 2>&1 | grep -q 'PASS.*US1: adr' && tests/numbering/test-reserve-number.sh 2>&1 | grep -q 'PASS.*US1: spec'`
- [X] T004 [US1] Extend `sw-dev-team-template/scripts/reserve-number.sh` for the REGISTER families (open-question, decision): next Q-NNNN / decision number counting existing rows, append a `reserved`-status claiming row to `docs/OPEN_QUESTIONS.md` / `docs/DECISIONS.md`, no row rewrite/overwrite (FR-004/006), `--dry-run` honored. The appended reserved row MUST stay clean under the `lint-questions.sh` hard-gate (a reserved row carries no customer-facing question). Primary verification: the register US1 cases pass — `cd sw-dev-team-template && tests/numbering/test-reserve-number.sh 2>&1 | grep -q 'PASS.*US1: open-question' && tests/numbering/test-reserve-number.sh 2>&1 | grep -q 'PASS.*US1: decision'`
- [X] T005 [US1] Finalize the smoke: confirm the full US1 suite is green (collision-free, no-overwrite, counts-reserved, no-renumber, gaps-not-reused, offline). Primary verification: `cd sw-dev-team-template && tests/numbering/test-reserve-number.sh`

**Checkpoint**: US1 independently testable (collision-free reservation proven offline against a sandbox).

---

## Phase 4: User Story 2 - One documented convention across artifact types (Priority: P2)

**Goal**: A single documented claim-first convention directing humans and agents to the helper for every covered family.

**Independent Test**: The convention doc states the claim-first rule + per-family reserve procedure pointing at the helper, for ADR/spec/registers.

### Implementation for User Story 2

- [X] T006 [US2] Author `sw-dev-team-template/docs/numbering-convention.md`: the claim-first rule (reserve = create the claiming stub first via the helper, then author), the per-family reserve procedure (adr/spec/open-question/decision) pointing at `scripts/reserve-number.sh`, the offline/single-operator note (FR-008), and the cross-tree boundedness + optional feature-014 issue cross-reference (FR-012). (FR-005, SC-004.) Primary verification: `grep -q 'reserve-number.sh' sw-dev-team-template/docs/numbering-convention.md && grep -qi 'claim-first' sw-dev-team-template/docs/numbering-convention.md`

**Checkpoint**: US2 independently testable.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Full validation and review before commit.

- [X] T007 Run full 015 validation: the reservation smoke (all families, collision-free/no-overwrite/no-renumber/gaps/offline) against the sandbox, AND run the helper with `--dry-run` against the LIVE repo for each family — confirm it prints correct next numbers and leaves the working tree clean (no mutation) (SC-001/SC-003/FR-013/I7). Primary verification: `cd sw-dev-team-template && tests/numbering/test-reserve-number.sh && for t in adr spec open-question decision; do scripts/reserve-number.sh "$t" --dry-run >/dev/null; done && git diff --quiet && echo NO-MUTATION-OK`
- [X] T008 Obtain `code-reviewer` review of the helper, tests, and convention doc before commit. Primary verification: code-reviewer SHIP verdict recorded for the 015 change set.

---

## Dependencies & Execution Order

### Requirement Coverage

- **FR-001, FR-003**: T003, T004 (stub-first + fill-in-later semantics), T002 (test).
- **FR-002, SC-001**: T003, T004, T002, T005.
- **FR-004**: T003 (adr/spec), T004 (registers).
- **FR-005, SC-004**: T006.
- **FR-006, SC-003**: T002, T003, T004, T007 (no-renumber/no-overwrite).
- **FR-007**: T002, T005, T007.
- **FR-008** (offline): T002, T003.
- **FR-009** (reserved distinguishable): T003, T004.
- **FR-010** (helper is next-number source): T003, T004; convention points to it T006.
- **FR-011** (scope adr/spec/registers; migrations excluded): T003, T004 (no migration handling).
- **FR-012** (independent of 014; optional cross-ref): T006 (documented); helper is offline (T003).
- **FR-013** (dry-run / read-only next-number): T003 (implement `--dry-run`), T007 (live no-mutation check).
- **SC-002**: T003, T004 (stub-before-content per family).

### Phase Dependencies

- **Setup (Phase 1)**: none.
- **US1 (Phase 3)**: T002 (red tests) first; T003 (file families) and T004 (register families) implement; T005 confirms full green. T003/T004 edit the same `reserve-number.sh` → sequence them.
- **US2 (Phase 4)**: after the helper exists (the convention points at it).
- **Polish**: after US1+US2.

### Parallel Opportunities

- Limited: the helper is one file (T003→T004 sequential). T006 (doc) can be drafted in parallel with T005 once T003/T004 land, but it references the finished helper behavior — safest after US1.

---

## Implementation Strategy

### MVP First

1. Setup + US1 (test-first helper) — the collision-free reservation core, proven offline against a sandbox.
2. Validate: `cd sw-dev-team-template && tests/numbering/test-reserve-number.sh`.

### Incremental Delivery

1. US1 helper (file families → register families → full green smoke).
2. US2 convention doc pointing at the helper.
3. Polish: full validation + review.

### Task Ownership

- `software-engineer`: the helper (T003, T004) and harness skeleton (T001).
- `qa-engineer`: the red tests + smoke (T002, T005, T007).
- `tech-writer`: the convention doc (T006).
- `code-reviewer`: review before commit (T008).
