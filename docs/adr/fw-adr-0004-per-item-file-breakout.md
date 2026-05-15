---
name: fw-adr-0004-per-item-file-breakout
description: Break requirements and architecture views into per-item files with a thin index.
status: accepted
date: 2026-04-25
---


# FW-ADR-0004 — Per-item / per-view file breakout for requirements and architecture

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: keep monolithic, document a search-first protocol](#option-m--minimalist-keep-monolithic-document-a-search-first-protocol)
  - [Option S — Scalable: break out per-item / per-view, with a thin index](#option-s--scalable-break-out-per-item--per-view-with-a-thin-index)
  - [Option C — Creative: per-item with content-addressed naming](#option-c--creative-per-item-with-content-addressed-naming)
- [Decision outcome](#decision-outcome)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted**
- **Date:** 2026-04-25
- **Deciders:** `architect` + `tech-lead` + customer
- **Consulted:** `docs/research/sw-dev-repos-survey-2026-04-25.md`
  (Recommendation 2); `jam01/SDD-Template`'s `view-template.md` +
  `view-template-bare.md`; `jam01/SRS-Template`'s `req-template.md`
  + `req-template-bare.md`; `LIB-0009` (IEEE 1016 § 5 viewpoints +
  views); `LIB-0010` (ISO/IEC/IEEE 29148 § 5.2 requirement
  characteristics).

## Context and problem statement

The project's `docs/requirements.md` and `docs/architecture.md` are
**monolithic** — one file holds every functional requirement, every
non-functional requirement, every C4 view, every cross-cutting
section. When an agent (most often `software-engineer`,
`code-reviewer`, or `qa-engineer`) needs to reason about a *single*
requirement or a *single* view, it must load the whole file.

The cost compounds with project growth: a 50-requirement system
project produces a 30+ KB requirements file that gets fully loaded
on every agent dispatch that touches anything requirements-related.
Most of those tokens are unused per-dispatch: the agent reads about
FR-0023 but just paid to load FR-0001 through FR-0050.

**The decision is whether to keep the monolithic shape or break out
to per-item / per-view files.** The jam01 templates demonstrate a
two-tier shape: a thin top-level index file, plus one file per
individual requirement (`docs/req/FR-NNNN.md`) or per individual
view (`docs/views/<viewpoint>-<name>.md`). Agents load only what they
need; the index file is a navigation aid, not a content store.

ADR trigger row: cross-module boundary (changes the file layout
contract that agents depend on); cross-cutting concern (every agent
that loads requirements or architecture is affected).

## Decision drivers

- **Token economy.** Same as FW-ADR-0003; this one is about loading
  granularity, not template shape.
- **Tooling neutrality.** The choice must not require a specific
  documentation generator or build step in the default path.
- **Traceability.** Each FR/NFR must remain trivially traceable from
  the index, and the requirements traceability matrix must continue
  to work.
- **Diff legibility.** A per-item file makes diffs scoped to the
  requirement that changed, instead of one giant file's diff.
- **Search.** Agents must still be able to grep across all requirements
  in one operation; the breakout must not destroy whole-set queries.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: keep monolithic, document a search-first protocol

No file changes. Add a binding section to `tech-lead.md` and the
template instructing agents to use Grep / smart-search **before**
loading the full file, and to load only the relevant section by
line range when possible.

- **Sketch:** Add a "section-scoped loading protocol" to
  `tech-lead.md` + `architect.md`. Each agent's dispatch brief
  cites the specific FR-NNNN or view name, and the agent uses
  Grep + Read with offset/limit instead of full Read.
- **Pros:** Zero file restructuring. No traceability changes. No
  tooling. Existing references intact.
- **Cons:** Discipline-dependent — agents may forget and load full
  files. The savings depend on every dispatcher writing
  scoped briefs. Section-scoped reads still require knowing the
  line range in advance, which itself requires loading the index
  or running grep. Net token savings smaller than per-file
  breakout.
- **When M wins:** project-size scenarios where the requirements
  file stays under ~10 KB and per-item proliferation cost would
  exceed the token savings.

### Option S — Scalable: break out per-item / per-view, with a thin index

Adopt the jam01 two-tier pattern. `docs/requirements.md` becomes a
thin index (one row per requirement: ID, title, status, link).
Each requirement lives at `docs/req/<FR-NNNN>.md` (or
`<NFR-NNNN>.md`). Same for architecture: `docs/architecture.md` keeps
the cross-cutting sections (overview, solution strategy, ADR index,
quality attributes) and indexes views; each view lives at
`docs/views/<viewpoint>-<name>.md` (e.g., `views/composition-main.md`,
`views/runtime-checkout.md`).

- **Sketch:** New template files:
  - `docs/templates/req-item-template.md` (guided per-FR)
  - `docs/templates/req-item-template-bare.md` (lean per-FR)
  - `docs/templates/architecture-view-template.md` (guided per-view)
  - `docs/templates/architecture-view-template-bare.md` (lean per-view)
  - Updated `docs/templates/requirements-template.md` and
    `architecture-template.md` to be thin-index shapes that link
    out to per-item files.
  Project conventions:
  - `docs/req/<ID>.md` filename per requirement
  - `docs/views/<viewpoint>-<name>.md` filename per view
  - Both directories ship as scaffolded empty stubs; populated as
    the project grows.
- **Pros:** Agents load only the FR / view they need —
  per-dispatch token cost scales with what's in scope, not with
  project size. Per-file diffs are scoped. Per-file commit
  messages are meaningful. Whole-set queries still work via
  `grep -r docs/req/` or `find docs/views/ -type f`. Aligns with
  CC0 jam01 convention.
- **Cons:** More files in the tree. Index file must be kept in sync
  with the per-item files (a missing row or a stale row is a
  finding for `code-reviewer`). Initial migration effort for any
  existing project with a populated monolithic file.
- **When S wins:** the framework's primary use case — projects with
  a non-trivial requirement / view count where per-dispatch token
  cost compounds.

### Option C — Creative: per-item with content-addressed naming

Same as S but use content-addressed filenames (hash of body) for
per-item files, with the index mapping ID → content-hash. Filenames
become immutable; renames / supersessions land as new files plus
index updates.

- **Sketch:** `docs/req/sha256:<first-12>.md` filenames; index file
  maps `FR-0001 → sha256:abcd…`. A requirement edit produces a new
  file; the old one stays for archival traceability.
- **Pros:** Immutable history at the filesystem level. Every diff
  is a new file. Powerful for regulated / audit-heavy domains.
- **Cons:** Filenames are unreadable by humans. Renaming on edit
  produces filesystem churn proportional to edit frequency. Git
  already provides content-addressed history; this duplicates it
  at higher noise. Unfamiliar to most contributors.
- **When C wins:** projects with hard regulatory requirements that
  the *filesystem* (not just git) carry the immutable record (e.g.,
  pharma, aviation, nuclear). Not this framework's default audience.

## Decision outcome

**Chosen option: S — Scalable: per-item / per-view with thin index.**

**Reason:** Option S directly serves the v0.14.0 token-economy goal
with the largest leverage of any single recommendation in the survey
(loading granularity scales with what's in scope, not project size).
Option M's savings depend on dispatcher discipline; agents that
forget and load the full file pay the full cost. Option C buys
filesystem-level immutability at a readability and tooling cost the
framework's audience doesn't need.

The thin-index + per-item shape is the binding scaffold for new
projects from v0.14.0; existing projects can migrate at their pace
(no forced break). The index file structure is binding — one row per
item with `ID | Title | Status | File`.

## Consequences

### Positive

- Per-dispatch token cost scales with scope, not project size.
- Per-item commits + diffs are immediately legible.
- Whole-set queries unchanged (grep / find / search continue to work).
- Aligns with widely-recognised CC0 convention.

### Negative / trade-offs accepted

- More files in the tree. Mitigated by the convention that they
  live under predictable directories (`docs/req/`, `docs/views/`)
  and the scaffolder seeds them as empty.
- Index drift is a `code-reviewer` audit-mode finding (per
  IEEE 730 § 5.4 — products conform to plans). The audit
  cadence already covers it.
- Migration effort for existing projects. Mitigated by no-forced-
  break: monolithic files remain valid; per-item is the new
  default for *new* artefacts.

### Follow-up ADRs

- FW-ADR-0003 — Bare variants of structural templates (decides the
  shape of each individual per-item template, not the breakout
  itself).
- A future ADR if downstream projects request automation
  (scaffolder writes index + first per-item file from one command).

## Verification

- **Success signal:** by v0.15.0, downstream projects scaffolded
  on v0.14.0 ship with `docs/req/` + `docs/views/` populated as
  per-item files, and per-dispatch token-ledger entries (per
  `docs/templates/task-template.md` § DoD) show measurably lower
  per-task token consumption than v0.13.x baselines.
- **Failure signal:** index files routinely drift from per-item
  files — `code-reviewer` audit findings cite drift more than
  ~10% of slice-close audits.
- **Review cadence:** at v0.15.0 release planning. Reconsider if
  drift accumulates or if downstream projects request a
  consolidation back to monolithic.

## Links

- Survey: `docs/research/sw-dev-repos-survey-2026-04-25.md` (Recommendation 2)
- External references:
  - `https://github.com/jam01/SDD-Template` (CC0 1.0; per-view
    file pattern)
  - `https://github.com/jam01/SRS-Template` (CC0 1.0; per-req
    file pattern)
- Related ADRs: FW-ADR-0003 (bare variants — pairs with this one for
  per-item templates), FW-ADR-0007 (reference adoption catalogue).
- External standards: `LIB-0009` IEEE 1016 § 5 (per-viewpoint
  views), `LIB-0010` ISO/IEC/IEEE 29148 § 5.4 (information items
  composed of requirement records).
