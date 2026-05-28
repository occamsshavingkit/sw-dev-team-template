# Data Model: Claim-First Numbering Reservation

## Reservation placeholder

- **Fields**: artifact type (adr | spec | open-question | decision); claimed number (zero-padded to family width); slug/title (optional); status marker `reserved`/`draft`; created-at.
- **Per-family form**:
  - adr → `docs/adr/fw-adr-NNNN-<slug>.md` with front-matter `status: reserved`.
  - spec → `specs/NNN-<slug>/spec.md` stub with `Status: Reserved`.
  - open-question → a `Q-NNNN` row in `docs/OPEN_QUESTIONS.md` with status `reserved`.
  - decision → a reserved `## D-NNNN` heading entry in `docs/DECISIONS.md` (heading-block format, not a table row).
- **Rules**: created as the FIRST action of a reservation (FR-001); visible to the next-number scan (FR-002); distinguishable as reserved/abandoned (FR-009); filled in later, not recreated, number unchanged (FR-003).

## Sequence

- **Fields**: per family, the ordered set of numbers in use (authored + reserved), including gaps.
- **Rules**: derived from on-disk artifacts + reserved stubs; existing numbers never renumbered/overwritten (FR-006).

## Next-number computation

- **Definition**: `next(family) = max(numbers in use incl. reserved) + 1`, zero-padded. Counts reserved placeholders (FR-002); does not gap-fill or reuse withdrawn numbers (research R2).
- **Determinism**: same repo state → same next number; reading is side-effect-free until the stub is written.

## Reservation helper (CLI)

- **Inputs**: artifact type [+ optional slug/title].
- **Outputs**: claimed number + created stub path; exit 0 success / nonzero on bad type or any would-overwrite condition (never clobbers).
- **Guarantee**: single source of the next-number logic (FR-010); never overwrites an existing file/row (FR-006).

## Claim-first convention

- **Content**: the rule (reserve = create the claiming stub first, then author) + per-family reserve procedure pointing at the helper; the offline/single-operator note (FR-008) and the cross-tree boundedness + optional 014 cross-reference (FR-012).
- **Audience**: human contributors and agents.
