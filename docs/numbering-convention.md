# Claim-first numbering convention

<!-- TOC -->

- [The rule](#the-rule)
- [Reserve procedure by artifact family](#reserve-procedure-by-artifact-family)
  - [ADR (`fw-adr-NNNN`)](#adr-fw-adr-nnnn)
  - [Spec directory (`specs/NNN-…`)](#spec-directory-specsnnn-)
  - [Open question (`Q-NNNN`)](#open-question-q-nnnn)
  - [Decision (`D-NNNN` heading block in `docs/DECISIONS.md`)](#decision-d-nnnn-heading-block-in-docsdecisionsmd)
- [Preview without writing](#preview-without-writing)
- [How the next number is computed](#how-the-next-number-is-computed)
- [Abandoned and gap numbers](#abandoned-and-gap-numbers)
- [Offline and single-operator use](#offline-and-single-operator-use)
- [Cross-tree scope and feature-014 integration](#cross-tree-scope-and-feature-014-integration)
- [Out of scope](#out-of-scope)

<!-- /TOC -->

## The rule

**Claim the number before authoring the content.** When a contributor
(human or agent) needs the next number in a sequenced artifact
family, they run `scripts/reserve-number.sh` first. The helper
computes the next free number, writes a placeholder stub that claims
that number, and prints the claimed number and stub path to stdout.
Content authoring then fills in the same stub; the claimed number
never changes.

This is the **claim-first** approach. It closes the window that
causes collisions: the old read-then-create-later pattern lets two
contributors read the same "current highest" value, both author
content for the same number, and collide when they commit.
Claim-first makes the reservation visible the instant the stub is
written, so a second contributor scanning the same directory sees the
stub and receives the following number.

Do not derive the next number by hand and then create a file later.
Use the helper.

## Reserve procedure by artifact family

All four artifact families below share the same invocation shape:

```bash
scripts/reserve-number.sh <type> --slug <short-name>
```

`--slug` names the stub. If omitted, the helper uses
`reserved-placeholder`. Rename the file or directory when authoring.
`--title` sets the title field inside the stub; it also defaults to a
placeholder when omitted.

The helper prints one line to stdout on success:

```
<family> <NNNN> <stub-path>
```

It exits nonzero on any error (unknown type, malformed register, or
a would-overwrite condition). It never overwrites an existing file or
row.

### ADR (`fw-adr-NNNN`)

```bash
scripts/reserve-number.sh adr --slug <short-name>
```

Creates `docs/adr/fw-adr-<NNNN>-<slug>.md` with YAML frontmatter
`status: reserved`. The file is immediately visible to the next-number
scan and to other contributors.

When authoring the ADR later, edit this file in place and change
`status: reserved` to `status: proposed` (or the appropriate status).
Do not create a new file for the same number.

### Spec directory (`specs/NNN-…`)

```bash
scripts/reserve-number.sh spec --slug <short-name>
```

Creates `specs/<NNN>-<slug>/spec.md` with `Status: Reserved` in the
body. The directory itself is the reservation claim; the helper
refuses to run if the directory already exists.

Fill in `spec.md` at authoring time. Change `Status: Reserved` to
`Status: Draft` or the appropriate status.

### Open question (`Q-NNNN`)

```bash
scripts/reserve-number.sh open-question --slug <short-name>
```

Appends a reserved row to `docs/OPEN_QUESTIONS.md` claiming the next
`Q-NNNN` ID. The row status is `reserved` and the fields are blank
placeholders. The register file must already exist; the helper exits
nonzero if it is missing. A `--slug` or `--title` value is accepted
but has no effect on the appended row format.

Fill in the row when authoring the question. Keep the `Q-NNNN` ID
unchanged.

### Decision (`D-NNNN` heading block in `docs/DECISIONS.md`)

```bash
scripts/reserve-number.sh decision
```

Appends a reserved `## D-NNNN — <date> — reserved` heading block to
`docs/DECISIONS.md` claiming the next four-digit zero-padded number.
The register file must already exist; the helper exits nonzero if it
is missing. A `--slug` or `--title` value is accepted but has no
effect on the appended heading block.

Fill in the heading block when authoring the decision.

## Preview without writing

Pass `--dry-run` to see the next free number without creating any
stub or modifying any file:

```bash
scripts/reserve-number.sh adr --dry-run
scripts/reserve-number.sh spec --dry-run
scripts/reserve-number.sh open-question --dry-run
scripts/reserve-number.sh decision --dry-run
```

`--dry-run` prints the same `<family> <NNNN> <path>` line as a live
run, then exits 0. No file is created, no row is appended, no
directory is made. Running it against the live repository leaves a
clean working tree.

Use `--dry-run` when you want to know what number comes next without
committing to the reservation yet, or when verifying the helper
against the existing sequence.

## How the next number is computed

The helper scans the on-disk artifacts for the family and returns
`max(existing numbers) + 1`, zero-padded to the family width (four
digits for ADRs, open questions, and decisions; three for specs). When
a family's directory or register has no existing entries, the result
is the first number in the sequence (e.g., `001` for specs, `0001`
for decisions).

The scan counts **both** fully authored artifacts and existing
reserved stubs. A stub that was reserved but not yet authored holds
its number in the sequence; the next reserver gets the number after
it.

| Family | Scanned location | Width |
|---|---|---|
| `adr` | `docs/adr/fw-adr-[0-9][0-9][0-9][0-9]-*.md` | 4 digits |
| `spec` | `specs/[0-9][0-9][0-9]-*` directories | 3 digits |
| `open-question` | `Q-NNNN` IDs in `docs/OPEN_QUESTIONS.md` | 4 digits |
| `decision` | `## D-NNNN` headings in `docs/DECISIONS.md` | 4 digits |

## Abandoned and gap numbers

A reserved stub that is never filled in still holds its number. The
helper will not issue that number to a later reserver. If a
reservation is abandoned, leave the stub in place or delete it after
confirming no external references (commits, issues, or docs) point to
that number. Deleting an abandoned stub creates a gap; the next
reservation takes the number after the highest remaining one.

Gaps are permanent. The helper always returns `max + 1`; it does not
backfill gaps or reuse a withdrawn number. This prevents collisions
with any external references that may have captured the old number
before it was withdrawn.

## Offline and single-operator use

The helper requires no network connection and no external coordination
infrastructure. It reads and writes only the local working tree. A
single contributor working offline can reserve numbers in all four
families exactly as described above.

The mechanism is additive: it does not replace or block any existing
workflow. Contributors who are not yet using the helper can still
create artifacts manually. The only effect is that those manual
creations are counted by the next-number scan as long as they follow
the naming convention.

## Cross-tree scope and feature-014 integration

Reservation is **best-effort-atomic within a single working tree**.
When two contributors work in the same tree sequentially, the
claim-first stub written by the first reservation is visible to the
second, so they receive distinct numbers. Simultaneous writes to the
same file in the same tree are an edge case that filesystem creation
semantics handle on most systems; the helper refuses to overwrite an
existing file.

Cross-branch and cross-machine collisions are **reduced and bounded,
not eliminated**. Two contributors on separate branches or machines,
each reserving a number before merging, may independently claim the
same number. The same gap-and-rename process used for any merge
conflict applies. Committing reserved stubs promptly makes the
reservation visible to others as soon as they fetch.

When the feature-014 issue-coordination interface is in use, a
reservation may additionally surface as a claimed issue, making the
reservation visible before a branch is merged. This cross-reference
is optional. The in-repo placeholder is the authoritative reservation
primitive. The helper works correctly with no issue infrastructure
present.

## Out of scope

Migration files under `migrations/` follow a version-name scheme
(`migrations/<semver>.sh`) and are not part of a free integer counter.
The claim-first numbering convention and `reserve-number.sh` do not
apply to migrations.
