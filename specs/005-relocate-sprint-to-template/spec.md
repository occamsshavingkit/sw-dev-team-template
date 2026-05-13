# Feature Specification: Relocate sprint update to sw-dev-team-template (keep template virgin)

**Feature Branch**: `005-relocate-sprint-to-template`
**Created**: 2026-05-13
**Status**: Draft

## Clarifications

### Session 2026-05-13

- Q: How are sprint artifacts that straddle planning and substantive content classified? → A: **Default-to-process.** The framework itself is the product; the decisions taken to get there are not part of a clean `./sw-dev-team-template`. Only pure scaffold/stub diffs (the actual framework files a downstream consumer uses) cross into the template. Anything that documents the sprint's deliberation — including ADRs authored during the sprint — stays in the meta-project, even when the deliberation is durable framework rationale.
**Input**: User description: "I did a 10-milestone sprint to update this project. It was unwittingly done on this current directory - the meta project - and not the actual project. Obviously while doing the work plans, records, tasks, etc. were created. We need to move the update to the proper directory - ./sw-dev-team-template - and make sure that it has none of the artifacts that were created during the sprint, but is a clean 'virgin' project that has scaffolds and stubs and not plans from the sprint."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Substantive template updates land in the template repo (Priority: P1)

The substantive scaffold and stub improvements produced by the sprint
spanning milestones M0 through M10 are present inside the `./sw-dev-team-template`
subrepository at the paths a downstream consumer of the template expects.
Anyone who pulls a fresh copy of the template (clone or scaffold) receives
the improved scaffolds and stubs without being aware that a sprint ever
occurred.

**Why this priority**: The whole point of the sprint was to update the
template. Until that update reaches the template subrepository, the work
has no customer-visible value.

**Independent Test**: Clone `./sw-dev-team-template` to a clean working
directory, run the project's standard smoke check (scaffold a downstream
project from it, run its self-tests / linters), and confirm that the
template content reflects the sprint's intended improvements (versioned
scaffold files updated, new helper scripts present, role contracts
updated). No additional work in the meta-project is required for the
template to be useful.

**Acceptance Scenarios**:

1. **Given** a fresh clone of `./sw-dev-team-template`, **When** an
   inspector compares the template's tracked files against the pre-sprint
   baseline, **Then** every substantive scaffold/stub change that the
   sprint produced is present at the correct template-repo path.
2. **Given** the template's own version stamp and changelog, **When** the
   sprint's improvements are merged, **Then** the template version is
   bumped (per the template's own semver policy) and the changelog cites
   the relocated work, without leaking sprint task IDs or proposal IDs
   that exist only in the meta-project.
3. **Given** the template's own pre-commit and review gates, **When** the
   relocation lands, **Then** all template-side quality gates pass
   (`code-reviewer` review on the template diff, security-engineer review
   if any framework-managed authentication / secrets surface is touched).

---

### User Story 2 - Template repo stays virgin: no sprint-process artifacts (Priority: P1)

The `./sw-dev-team-template` subrepository contains only template content
(scaffolds, stubs, role files, scripts, docs templates). It does not
contain sprint planning records, proposals, intake-log entries, task
lists, ADR drafts about the sprint, or `specs/` directories whose feature
slugs reference the M0–M10 sprint. A downstream consumer cloning the
template cannot tell that a sprint produced the contents — it just sees a
clean scaffold/stub starting point.

**Why this priority**: Equal-weight with Story 1. A "moved" update that
drags sprint-process noise into the template defeats the purpose; the
template must remain a clean reusable starting point.

**Independent Test**: After relocation, inspect `./sw-dev-team-template`
for the presence of any of the following content classes and confirm
none are present:

- Sprint proposals (`docs/proposals/T0NN.md` or equivalent task-ID-keyed
  proposals tied to the sprint).
- Sprint intake log entries (Q&A captured during sprint planning).
- Sprint ADRs whose context is the sprint itself rather than a durable
  framework decision.
- Sprint `specs/` directories produced by `/speckit-specify` for M0–M10
  planning.
- Sprint schedules, change logs, lessons-learned drafts produced by
  `project-manager` for the sprint.
- Sprint prior-art compilations produced for sprint tasks.

**Acceptance Scenarios**:

1. **Given** the relocated template, **When** a reviewer searches the
   tree for sprint task IDs (e.g., `T020`, `T021`, … through the sprint's
   highest task ID) and milestone slugs (e.g., `M8`, `M9`, `M10`), **Then**
   no matches exist outside content that already existed in the template
   before the sprint started.
2. **Given** the relocated template's `specs/` directory (if present),
   **When** inspected, **Then** it contains no feature directories whose
   slugs reference the sprint (no `00N-m1-...`, `00N-m8-m10-...`, etc.).
3. **Given** the relocated template, **When** a downstream consumer
   scaffolds a new project from it, **Then** the scaffolded project shows
   no sprint planning content and matches the documented virgin scaffold
   layout.

---

### User Story 3 - Meta-project state after relocation is coherent (Priority: P2)

After relocation, the meta-project working tree at
`/home/quackdcs/SWEProj` is in a coherent, reviewable state. Files that
were edited in the meta-project root by mistake (rather than in the
template subrepo) are either reverted, archived under a clearly named
meta-project subpath, or kept as legitimate meta-project edits — with the
classification recorded so a future reviewer can tell which is which.
Sprint-process artifacts that originated in the meta-project (proposals,
intake log entries, sprint specs) have an explicit final disposition
recorded.

**Why this priority**: Without this, the meta-project is left in a
half-cleaned state that confuses subsequent sessions and risks the same
miscoding happening again.

**Independent Test**: Run `git status` and `git diff` against
`origin/main` at the meta-project root and inspect the working tree. A
reviewer can read a short relocation-disposition note and immediately
classify every changed/added/deleted file as one of: (a) reverted
because it belonged in the template, (b) committed in meta-project
because it is legitimate meta-project scope, or (c) archived under a
named meta-project subpath. No file is in an unclassified state.

**Acceptance Scenarios**:

1. **Given** the meta-project working tree after relocation, **When**
   `git status` is run, **Then** every reported path maps cleanly to one
   of the three categories above per a written disposition record.
2. **Given** the meta-project's sprint planning artifacts, **When** the
   relocation is complete, **Then** they either remain in their original
   meta-project paths (as a historical record) or are moved to a named
   archive subpath — with the choice recorded once and applied uniformly.
3. **Given** the meta-project's `TEMPLATE_VERSION` and any cross-repo
   pointers, **When** the relocation is complete, **Then** they reflect
   the post-relocation template state, not the pre-sprint state.

---

### Edge Cases

- A sprint-produced file at meta-project root is **content-identical** to
  a file already in `./sw-dev-team-template`: the relocation MUST NOT
  produce a no-op duplicate or overwrite the template's existing file
  with the same bytes. Detect and skip these cleanly.
- A sprint-produced file at meta-project root is a **modification of a
  template file that already exists in `./sw-dev-team-template` with
  divergent content** (template subrepo has been independently advanced
  since the sprint started): conflict MUST be surfaced for human
  resolution; the relocation MUST NOT silently overwrite the template's
  newer version.
- A sprint commit (e.g., `d7d93de [Spec Kit] Implementation progress`)
  already exists in the meta-project's git history. The relocation MUST
  preserve auditability of what was done — either by leaving the
  meta-project commit in place with a note explaining its status, or by
  recording the relocation operation in a way that future readers can
  trace the move.
- A sprint artifact straddles both planning AND substantive content.
  Resolution rule (per Clarification 2026-05-13): **default-to-process**
  — the framework itself is the product; anything that documents the
  sprint's deliberation stays in the meta-project even when the
  deliberation is durable framework rationale. Only pure scaffold/stub
  diffs cross into the template. This applies even to ADRs authored
  during the sprint: the *decision text* stays in the meta-project; the
  *resulting framework change* (file edit, new scaffold) crosses.
- A sprint proposal references files that no longer exist after the
  relocation (broken cross-reference). Either the proposal is moved with
  the reference still resolvable, or the broken reference is flagged.
- Both repositories have independent quality gates (`code-reviewer`
  review, `security-engineer` review for sensitive surfaces). A single
  relocation operation may need approvals in both, applied to the
  appropriate diff each side.
- The meta-project's own `.claude/agents/*.md`, `AGENTS.md`, and
  `CLAUDE.md` files are deliberately separate from the template's copies
  (they govern meta-project sessions). The relocation MUST NOT confuse
  these with template content even when filenames match.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The relocation MUST produce, in `./sw-dev-team-template`, the
  full set of substantive scaffold/stub improvements that the M0–M10
  sprint intended for the template — applied at the template-repo paths
  a downstream consumer expects.
- **FR-002**: The relocation MUST exclude all sprint-process artifacts
  from `./sw-dev-team-template`. Excluded classes include sprint
  proposals, sprint intake-log entries, sprint ADRs (all of them,
  including durable framework decisions — per the
  default-to-process rule), sprint `specs/` directories, sprint
  schedules, sprint change logs, and sprint prior-art compilations.
  Only pure scaffold/stub file diffs cross into the template; any
  artifact whose content is *about* the sprint's deliberation stays in
  the meta-project.
- **FR-003**: The relocation MUST produce a written classification
  inventory that lists every meta-project file the sprint touched and
  categorizes it as one of: (a) substantive template content to relocate,
  (b) sprint-process artifact to exclude from the template, (c)
  legitimate meta-project edit to keep at meta-project root, (d) revert
  in meta-project.
- **FR-004**: The relocation MUST surface conflicts (where a sprint file
  diverges from an independently-advanced template file) for human
  review and MUST NOT silently overwrite the template's newer version.
- **FR-005**: The relocation MUST preserve auditability of the original
  sprint work — a future reader MUST be able to trace from the
  template-subrepo result back to the sprint that produced it.
- **FR-006**: The relocation MUST respect each repo's quality gates: the
  template-side diff is reviewed under `./sw-dev-team-template`'s review
  rules, and any residual meta-project changes are reviewed under the
  meta-project's review rules.
- **FR-007**: `./sw-dev-team-template`'s own version stamp and changelog
  MUST be updated to reflect the relocated improvements, using the
  template repo's own versioning policy, without leaking sprint task IDs
  or proposal IDs that exist only in the meta-project.
- **FR-008**: The meta-project MUST end in a state where every modified,
  added, or deleted path has an explicit disposition recorded — none
  left ambiguous.
- **FR-009**: The relocation MUST be re-runnable / verifiable: an
  independent reviewer can, given the inventory and the two repos, check
  every claim in the inventory without re-doing the work.
- **FR-010**: The classification inventory MUST be produced by the
  appropriate canonical owning role(s) (e.g., `architect` for scope
  classification, `researcher` for verbatim customer-truth records,
  `release-engineer` for version/changelog updates) — not authored by
  `tech-lead` directly.

### Constitution Alignment *(mandatory)*

- **CA-001**: Source authority MUST be classified for affected artifacts as
  canonical, generated, or ephemeral. The classification inventory itself
  is canonical; the sprint-produced proposals are canonical (in the
  meta-project, if retained) or excluded (from the template); compiled
  manifest files (e.g., `TEMPLATE_MANIFEST.lock`) are generated and MUST
  be regenerated from canonical inputs after the relocation.
- **CA-002**: Customer-owned requirements MUST cite a recorded customer
  answer, a documented assumption, or one queued atomic question. The
  three scope decisions (sprint-process disposition, meta-project
  git-history target, milestone scope of "the sprint") have been
  resolved by customer answer on 2026-05-13 and are recorded inline in
  FR-CLAR-A, FR-CLAR-B, and FR-CLAR-C. No clarifications remain
  outstanding. Researcher MUST record these verbatim in
  `CUSTOMER_NOTES.md` before planning proceeds.
- **CA-003**: Framework-managed file edits MUST be marked as framework
  work and require explicit authorization unless this feature is a
  template-maintenance task. This feature IS a template-maintenance task
  (it is, by definition, a relocation of template content), so framework
  edits are in-scope; meta-project-only changes MUST be separated from
  template-bound changes and reviewed under each repo's gates.
- **CA-004**: Cross-AI or generated-output changes MUST preserve existing
  role authority and identify canonical inputs. The relocation MUST NOT
  silently change harness-adapter behavior; any harness-adapter file
  movement (e.g., AGENTS.md, .claude/agents/*.md) MUST keep the canonical
  role authority intact in the destination repo.

### Resolved Clarifications (all answered 2026-05-13)

- **FR-CLAR-A** (resolved 2026-05-13): Sprint-process artifacts in the
  meta-project (proposals, intake-log entries, sprint specs, sprint
  ADRs, schedules, lessons-learned drafts, prior-art compilations)
  **remain at their original meta-project paths** as a historical
  record (customer answer). The relocation MUST NOT move, archive, or
  delete them from the meta-project; the disposition recorded in the
  classification inventory is "keep in meta-project at original path"
  for every artifact in this class.
- **FR-CLAR-B** (resolved 2026-05-13): The meta-project git-history
  target is **"keep existing commits + add a relocation commit on top"**
  (customer answer). The relocation MUST NOT rewrite, reset, or
  cherry-pick the existing branch history. The existing sprint commit
  (e.g., `d7d93de [Spec Kit] Implementation progress` and any
  subsequent sprint commits) remains in place; the relocation outcome
  (classification inventory, any meta-project reverts, version-stamp
  and pointer updates) lands as a new commit on top.
- **FR-CLAR-C** (resolved 2026-05-13): "The sprint" is scoped as
  **milestones M0 through M10 inclusive** (customer answer). All
  artifacts produced for M0–M10 are in scope for classification and
  relocation; pre-M0 meta-project state is treated as the baseline.

### Key Entities *(include if feature involves data)*

- **Sprint-produced artifact**: any file added or modified at the
  meta-project root or under meta-project subpaths between the sprint's
  start and the relocation. Classified by destination (template /
  meta-project / archive / discard) and by class (substantive content /
  process record).
- **Template repository (`./sw-dev-team-template`)**: the destination
  subrepository whose virgin scaffold/stub state MUST be preserved
  except for substantive sprint improvements being relocated in.
- **Meta-project (`/home/quackdcs/SWEProj`)**: the parent working tree
  that hosts sprint planning and orchestrates work; remains the home of
  retained sprint-process artifacts (if any) and meta-project-scope
  configs.
- **Classification inventory**: the canonical written record produced by
  this feature, listing every sprint-touched path with disposition,
  class, destination, and reviewer.
- **Sprint milestone (M0 through M10, inclusive — 11 milestones)**: a
  unit of sprint work that produced a bounded set of artifacts; the
  milestone boundary informs which task IDs and proposal IDs are
  sprint-internal vs durable.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of paths in the classification inventory have exactly
  one disposition and one class; zero rows are blank, ambiguous, or
  duplicated.
- **SC-002**: A reviewer cloning `./sw-dev-team-template` fresh and
  searching the tree for any of the sprint's task IDs or milestone slugs
  (M1 through the sprint's highest milestone) returns zero matches
  outside of files that existed pre-sprint.
- **SC-003**: The template's smoke / scaffold check (its own existing
  validation flow) passes on the relocated state in a single run, with
  no errors and no warnings beyond those already present on the
  pre-sprint template baseline.
- **SC-004**: A reviewer who reads only the classification inventory and
  the resulting template diff can verify every relocated change without
  reading any sprint proposal or sprint plan document.
- **SC-005**: The relocation completes without introducing any new
  customer-facing question other than the queued clarifications already
  named in the spec.
- **SC-006**: After relocation, the meta-project `git status` shows zero
  unclassified working-tree changes (every changed / added / deleted
  path is accounted for in the inventory).
- **SC-007**: An independent reviewer can re-run a verification pass
  against the inventory and the two repos in under 30 minutes and
  confirm every claim (or flag specific exceptions) without re-running
  any sprint task.

## Assumptions

- The sprint produced both (a) substantive scaffold/stub changes
  intended for `./sw-dev-team-template` and (b) sprint-process artifacts
  (proposals, intake-log entries, ADR drafts, schedules) used to plan
  and execute the sprint. Both classes are present in the current
  meta-project working tree and meta-project git history.
- `./sw-dev-team-template` is the canonical destination subrepository,
  is independently versioned and reviewed, and has its own
  pre-commit / pre-release quality gates including `code-reviewer`
  review.
- The meta-project's own top-level `.claude/agents/*.md`, `AGENTS.md`,
  `CLAUDE.md`, and similar harness-adapter files are deliberately
  distinct from the template's copies and are NOT in scope for
  relocation to the template merely because filenames match. The
  classification inventory disambiguates per file.
- `architect`, `release-engineer`, `researcher`, `code-reviewer`,
  `security-engineer`, and `project-manager` are available to participate
  in classification, relocation, and review per Constitution Principle I
  (Role-Bound Delegation). `tech-lead` orchestrates and does not author
  the inventory or the template diff directly.
- The customer is available to answer the three queued atomic
  clarifications before planning begins.
- No production deployment depends on the meta-project's current
  half-state being preserved; the relocation can take as long as it
  needs to be done safely.
