# Implementation Plan: Claim-First Numbering Reservation

**Branch**: `015-claim-first-numbering` | **Date**: 2026-05-27 | **Spec**: `specs/015-claim-first-numbering/spec.md`
**Input**: Feature specification from `specs/015-claim-first-numbering/spec.md`

## Summary

Eliminate the read-then-create-later numbering window that has caused repeated collisions: ship a reservation helper that, for a given free-counter artifact type (ADR `fw-adr-NNNN`, spec dir `specs/NNN-…`, register row `Q-NNNN`/DECISIONS), atomically computes the next number — counting reserved placeholders, not just authored artifacts — and writes a `reserved`/`draft` claiming stub as the first action; plus a documented "claim-first numbering" convention directing humans and agents to use the helper. Independent of feature-014 issues (works offline/single-operator); migrations are out of scope (version-named). Covered by a test that two reservations get distinct numbers and neither stub is overwritten, with existing numbered artifacts left untouched.

## Technical Context

**Language/Version**: Bash (the reservation helper + reserve-point hardening, matching the existing `scripts/` style); Markdown (the convention doc / ADR); the helper reads existing artifact names with standard text tooling.  
**Primary Dependencies**: Existing repo layout — `docs/adr/fw-adr-NNNN-*.md`, `specs/NNN-*`, `docs/OPEN_QUESTIONS.md`, `docs/DECISIONS.md`; the existing zero-padded numbering schemes; no new third-party dependency.  
**Storage**: Repo files — reserved placeholders are committed stubs (ADR stub, spec-dir stub, register row); the "sequence" is derived from filenames/rows on disk.  
**Testing**: A shell test that simulates two consecutive/interleaved reservations of a covered artifact type and asserts distinct consecutive numbers + no stub overwrite; plus a check that the next-number computation reads the current repo's existing artifacts correctly and changes none of them.  
**Target Platform**: Any contributor working tree (human or agent); offline/single-operator must work without coordination infrastructure.  
**Project Type**: Framework/template repository — a small shell helper + convention doc + reserve-point hardening.  
**Performance Goals**: N/A (a few filesystem reads per reservation).  
**Constraints**: Reservation is best-effort-atomic WITHIN a working tree (closes the in-tree window); cross-branch/cross-machine collisions are reduced/bounded, not eliminated (the 014 issue-claim is the cross-machine complement). Additive/opt-in; must not renumber or overwrite existing artifacts; in-repo registers remain binding.  
**Scale/Scope**: Three free-counter artifact families; one helper; one convention doc; reserve-point touch-ups; one test. Small.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Role routing (Principle I)**: PASS. Helper + reserve-point hardening + test → `software-engineer` (test assertions → `qa-engineer`); the convention doc → `tech-writer`; if a governing ADR is warranted, `architect`; pre-commit review → `code-reviewer`. `tech-lead` orchestrates only.
- **Token/context economy (Principle II)**: PASS. A helper + a convention doc; no recurring runtime context added to the agent set.
- **Source authority (Principle III)**: PASS. Canonical: the helper under `scripts/`, the convention doc (and any ADR), the reserve points. Generated/planning: this plan + research/data-model/contracts/quickstart. Reserved placeholders are draft artifacts until authored.
- **Customer intake (Principle IV)**: PASS. Customer-directed (recurring collisions); the three sub-decisions resolved in clarify (FR-010/011/012). Nothing open.
- **Quality gates (Principle V)**: PASS. The two-reservation test must pass; the no-renumber/no-overwrite check must pass; `code-reviewer` sign-off before commit.
- **Framework/project boundary (Principle VI)**: PASS. Template-maintenance in `sw-dev-team-template`. The meta-project speckit-skill internals are harness-level and out of the shipped scope (referenced, not edited).
- **Adapter discipline (Principle VII)**: PASS. Additive mechanism; no parallel authority; registers stay binding; independent of the opt-in 014 issue interface.

## Project Structure

### Documentation (this feature)

```text
specs/015-claim-first-numbering/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── reservation-helper.md      # the helper CLI contract + next-number/stub semantics per artifact type
└── tasks.md                       # /speckit-tasks output (not created here)
```

### Source Code (repository root)

```text
sw-dev-team-template/
├── scripts/
│   └── reserve-number.sh           # NEW — the reservation helper (next free number + write claiming stub) per artifact type
├── docs/
│   ├── numbering-convention.md     # NEW — the claim-first convention (per-artifact reserve procedure; points at the helper)
│   └── adr/                        # ADR reserve point (helper writes a reserved stub here)
├── specs/                          # (template-side spec dirs, if any) reserve point
├── docs/OPEN_QUESTIONS.md          # register reserve point (Q-NNNN row)
├── docs/DECISIONS.md               # register reserve point
└── tests/
    └── numbering/                  # NEW — two-reservation + no-overwrite + no-renumber smoke
        └── test-reserve-number.sh
```

**Structure Decision**: A single `scripts/reserve-number.sh` helper owns the next-number + stub-write logic for the three artifact families; `docs/numbering-convention.md` documents the claim-first rule and directs everyone to the helper; a `tests/numbering/` smoke proves the collision-free + no-overwrite + no-renumber behavior. (If a governing ADR is wanted, it would itself be reserved via the helper — dogfooding.) Exact filenames confirmed at task time.

## Complexity Tracking

No constitution violations require justification.

## Phase 0: Research

`research.md` captures: how to compute "next free number incl. reserved placeholders" deterministically per family (ADR/spec/registers) and handle gaps; the stub shape per family (ADR `status: reserved` front-matter, spec-dir stub, register row marked reserved); how to make the reserve best-effort-atomic within a tree (create-stub-first; optionally a quick re-scan); the test approach (simulate two reservations offline); and the explicit boundedness of cross-branch/cross-machine collisions (014 complement).

## Phase 1: Design & Contracts

Design outputs: `data-model.md` (reservation placeholder / sequence / next-number computation / claim-first convention entities, per-family stub shapes), `contracts/reservation-helper.md` (the helper CLI: inputs = artifact type [+ optional short name/title], outputs = the claimed number + the created stub path; the next-number rule incl. reserved placeholders; idempotent/no-overwrite guarantees; exit codes), and `quickstart.md` (reserve an ADR / spec / register row; two-reservation collision check; fill-in-later; opt-out/offline). The Spec Kit plan pointer in `CLAUDE.md` is updated to this plan.

## Post-Design Constitution Check

- **Role routing**: PASS. Helper/test → software-engineer/qa; convention → tech-writer; review → code-reviewer.
- **Token/context economy**: PASS. Helper + doc only.
- **Source authority**: PASS. Canonical inputs cited; placeholders are drafts.
- **Customer intake**: PASS. All decisions recorded.
- **Quality gates**: PASS. Two-reservation + no-overwrite + no-renumber tests; review before commit.
- **Framework/project boundary**: PASS. Framework-managed paths only.
- **Adapter discipline**: PASS. Additive; independent of 014; registers binding.
