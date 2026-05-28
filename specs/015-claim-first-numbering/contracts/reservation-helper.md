# Contract: Reservation Helper (`scripts/reserve-number.sh`)

The single source of next-number logic + the claim-first stub writer. Convention doc directs humans and agents here.

## Invocation

```
scripts/reserve-number.sh <artifact-type> [--slug <short-name>] [--title <text>] [--dry-run]
```

- `<artifact-type>` ∈ { `adr`, `spec`, `open-question`, `decision` } (the free-counter families; migrations are out of scope).
- `--slug` / `--title`: optional; used to name the stub / fill the row label. If omitted, a generic reserved stub is created (renamed/filled at authoring time).
- `--dry-run`: read-only — compute and print the next free number for the family and write NOTHING (no stub, no row, no mutation). Used to preview the next number and to verify the no-mutation guarantee against the live repository (FR-013).

## Behavior

1. Compute `next(family)` = highest number in use (authored artifacts AND existing reserved stubs) + 1, zero-padded to the family width (ADR/Q = 4 digits, spec = 3).
2. Write the claiming stub FIRST (before any content authoring), marked `reserved`/`draft`:
   - `adr` → `docs/adr/fw-adr-<NNNN>-<slug>.md` (front-matter `status: reserved`).
   - `spec` → `specs/<NNN>-<slug>/spec.md` (Status: Reserved).
   - `open-question` → append a `Q-<NNNN>` row (status `reserved`) to `docs/OPEN_QUESTIONS.md`.
   - `decision` → append a reserved `## D-NNNN — <date> — reserved` heading entry (matching the file's Row template) to `docs/DECISIONS.md`.
3. Print the claimed number and the created stub path to stdout.

## Outputs / exit codes

- stdout: `<family> <NNNN> <stub-path>` (parseable).
- exit 0: reservation succeeded (stub created/row appended).
- exit nonzero: unknown artifact type, malformed registers, or a would-overwrite condition (the computed target already exists) — the helper MUST fail rather than clobber.

## Invariants

- **I1 (no duplicate)**: two consecutive invocations for the same family return distinct, consecutive numbers (the first stub is counted by the second call). (SC-001)
- **I2 (no overwrite)**: never overwrites an existing file or rewrites an existing row; would-overwrite ⇒ nonzero exit, no mutation. (FR-006)
- **I3 (no renumber)**: existing authored/reserved artifacts are never renumbered or modified by a reservation. (FR-006/SC-003)
- **I4 (counts reserved)**: a reserved-but-unauthored stub is counted by `next(family)`. (FR-002)
- **I5 (monotonic)**: `next` = max+1; withdrawn/gap numbers are not reused by default. (research R2)
- **I6 (offline)**: requires no network and no GitHub/issue infrastructure. (FR-008/FR-012)
- **I7 (dry-run no-mutation)**: with `--dry-run`, the helper prints the next free number and makes ZERO filesystem changes (no stub, no row, no edit) — verifiable by running it against the live repo and confirming a clean working tree after. (FR-013)

## Fill-in-later

Authoring a reserved artifact updates the SAME stub in place (status reserved → draft/proposed/accepted, or the row's content) without changing the claimed number (FR-003). The helper does not author content; it only reserves.
