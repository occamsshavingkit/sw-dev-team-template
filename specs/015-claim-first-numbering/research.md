# Research: Claim-First Numbering Reservation

## R1 — Next free number, counting reserved placeholders

- **Decision**: For each family the helper derives the sequence from on-disk artifacts AND reserved stubs, then returns max+1 (zero-padded to the family's width). ADR: scan `docs/adr/fw-adr-NNNN-*.md` including reserved stubs. Spec: scan `specs/NNN-*` dirs including reserved stubs. Registers: parse the `Q-NNNN` rows in `docs/OPEN_QUESTIONS.md` / numbered rows in `docs/DECISIONS.md`. Because the claiming stub is written FIRST (FR-001), a concurrent reserver in the same tree sees it and gets the next number (FR-002).
- **Rationale**: Counting reserved placeholders is the whole fix — it closes the read-then-create-later window.
- **Alternatives considered**: a separate counter file (extra state to keep in sync, its own collision surface) — rejected; deriving from the artifacts/stubs themselves is self-consistent.

## R2 — Gaps and withdrawn numbers

- **Decision**: Next number = (highest existing number) + 1, NOT first-gap-fill. A withdrawn/abandoned number is not reused by default (avoids ambiguity and reference breakage). Gaps are left as-is.
- **Rationale**: Reusing withdrawn numbers risks colliding with external references (commits, issues) to the old artifact. Monotonic max+1 is predictable.
- **Alternatives considered**: first-gap-fill (denser numbering but reuse hazard) — rejected.

## R3 — Reserved-stub shape per family

- **Decision**:
  - ADR: a real `docs/adr/fw-adr-NNNN-<slug>.md` with front-matter `status: reserved` (or `draft`) and a title placeholder — distinguishable from `accepted`/`proposed`.
  - Spec dir: a `specs/NNN-<slug>/` with a stub `spec.md` (Status: Reserved) — matches what `/speckit-specify` already does (create dir first), formalized.
  - Register row: append a `Q-NNNN` row to `docs/OPEN_QUESTIONS.md` (Status `reserved`) / a numbered `DECISIONS.md` row — the row itself claims the number.
- **Rationale**: The placeholder must be visible to the next-number scan (FR-002) and identifiable as reserved/abandoned (FR-009).

## R4 — Best-effort atomicity within a tree; cross-tree boundedness

- **Decision**: "Create the stub first" closes the in-tree read-then-create window; an optional immediate re-scan after writing detects a same-instant double-create (rare in a single tree). Cross-branch/cross-machine collisions (two un-merged branches both reserving N) are REDUCED and BOUNDED, not eliminated — the feature-014 issue-claim is the cross-machine complement (a reservation may also be a claimed issue). This is stated honestly (mirrors 014's advisory framing).
- **Rationale**: A filesystem has no cross-branch lock; honesty about the bound matches the 014 model and FR-008 (offline must still work).
- **Alternatives considered**: a central reservation service (heavy, online-only) — rejected (violates offline/opt-in).

## R5 — Helper CLI shape

- **Decision**: `scripts/reserve-number.sh <artifact-type> [--slug <short-name>] [--title <text>]` → computes the next number, writes the reserved stub, prints the claimed number + stub path; exit 0 on success, nonzero on bad type / write failure. Idempotent guard: never overwrites an existing file/row (if the computed target somehow exists, fail rather than clobber). `<artifact-type>` ∈ {adr, spec, open-question, decision}.
- **Rationale**: One helper, one next-number source (FR-010); the convention doc points humans+agents at it.
- **Alternatives considered**: per-family separate scripts (duplication) — rejected.

## R6 — Test approach

- **Decision**: `tests/numbering/test-reserve-number.sh` runs against a TEMP fixture repo layout (or a sandbox copy) so it never mutates the real repo: seed a few artifacts, call the helper twice for the same family, assert two distinct consecutive numbers and that neither stub was overwritten; assert a withdrawn-gap is not reused; and a no-renumber check that running against the existing layout returns the correct next number and changes nothing.
- **Rationale**: Proves SC-001/SC-003 offline and deterministically without touching live artifacts.

## R7 — Scope boundaries (rulings)

- **Decision**: Cover ADR + spec + OPEN_QUESTIONS/DECISIONS only (FR-011). Migrations excluded (version-named). Numbering reservation independent of 014 issues (FR-012) — optional cross-reference only. Helper + convention both shipped (FR-010).
- **Rationale**: Customer rulings 2026-05-27 (recorded in spec Clarifications).
