# Quickstart: Claim-First Numbering Reservation

Validates the reservation helper + convention. The automated form lives in `tests/numbering/test-reserve-number.sh` (runs against a sandbox, never the live repo).

## 1. Reserve an ADR (claim-first) — US1, FR-001/FR-003

1. `scripts/reserve-number.sh adr --slug example-decision`
2. Expect: a `docs/adr/fw-adr-<NNNN>-example-decision.md` stub with `status: reserved` is created; the claimed number is printed; nothing else changes.
3. Author it later → the SAME file's status moves reserved→proposed/accepted; the number is unchanged.

## 2. Collision-free under two reservations — US1, FR-002, SC-001

1. Call the helper twice for the same family back-to-back (`adr` then `adr`).
2. Expect: two distinct, consecutive numbers (the second counts the first's reserved stub); neither stub overwritten. 0 collisions.

## 3. Each covered family — US2, FR-004, SC-002

1. Reserve one of each: `adr`, `spec`, `open-question`, `decision`.
2. Expect: each produces a number-claiming placeholder (ADR stub / `specs/NNN-<slug>/` stub / `Q-NNNN` row / DECISIONS row) before any content authoring.

## 4. No renumber / no overwrite of existing artifacts — FR-006, SC-003

1. Run the helper against the current repo layout (in the sandbox copy).
2. Expect: the computed next number is correct for each family; ALL existing numbered artifacts (ADR 0001–00NN, specs 001–0NN, Q-0001…) are unchanged; a would-overwrite condition exits nonzero with no mutation.

## 5. Gaps not reused — research R2

1. With a withdrawn number leaving a gap, reserve the next.
2. Expect: `max+1` (the gap is not back-filled; the withdrawn number is not reused).

## 6. Offline / single-operator — FR-008, FR-012

1. Run the helper with no network and no GitHub/issue setup.
2. Expect: reservation succeeds purely from the working tree; no issue is required. (When the 014 interface is in use, a reservation MAY also be surfaced as a claimed issue, but that is optional.)

## 7. Convention discoverable — SC-004

1. Read `docs/numbering-convention.md`.
2. Expect: it states the claim-first rule and the per-family reserve procedure, directing the reader to `scripts/reserve-number.sh` for ADR, spec, and register reservations.
