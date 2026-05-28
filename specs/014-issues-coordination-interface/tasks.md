# Tasks: Issues-Based Multi-Machine Coordination Interface

**Input**: Design documents from `specs/014-issues-coordination-interface/`
**Prerequisites**: `plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`, `quickstart.md`

**Verification**: Each task has exactly one `Primary verification:` command or review check.
**Organization**: Tasks grouped by user story for independent implementation/testing. All source paths are under `sw-dev-team-template/`.

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the doc/test locations for the coordination interface.

- [X] T001 Create `sw-dev-team-template/docs/coordination/` and `sw-dev-team-template/tests/coordination/` directories (with a `.gitkeep` where needed). Primary verification: `test -d sw-dev-team-template/docs/coordination && test -d sw-dev-team-template/tests/coordination`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The shared coordination vocabulary every user story rides on.

- [X] T002 Author the label taxonomy + milestone convention + structured-comment-type vocabulary in `sw-dev-team-template/docs/coordination/label-taxonomy.md`, matching `contracts/label-taxonomy.md` (status/role/priority/meta labels, milestones, the 6 comment types) (FR-005). Primary verification: `grep -q 'status:claimed' sw-dev-team-template/docs/coordination/label-taxonomy.md && grep -q 'role:software-engineer' sw-dev-team-template/docs/coordination/label-taxonomy.md`

**Checkpoint**: Shared vocabulary exists; user stories can begin.

---

## Phase 3: User Story 1 - Claim a task across machines without collisions (Priority: P1)

**Goal**: An advisory issue "checkout"/claim with a deterministic tie-break so two operators never both hold the same task; the loser yields and re-queues.

**Independent Test**: Simulate two near-simultaneous claims on one issue; exactly one wins, the other yields, and the resolution is deterministic and observer-independent.

### Implementation for User Story 1

- [X] T003 [US1] Author the claim-protocol operating doc (advisory claim sequence, post-then-re-read, collision tie-break, yield/release, stale-claim recovery, explicitly advisory/not-a-hard-lock) in `sw-dev-team-template/docs/coordination/claim-protocol.md`, matching `contracts/claim-protocol.md` (FR-001–FR-004). Primary verification: `grep -qi 'advisory' sw-dev-team-template/docs/coordination/claim-protocol.md && grep -qi 'earliest' sw-dev-team-template/docs/coordination/claim-protocol.md`
- [X] T004 [US1] Encode the deterministic tie-break decision (earliest UTC ts → lexical operator id over a set of fixture claim records) as a TEST-ONLY helper/function inside `sw-dev-team-template/tests/coordination/` (NOT a shipped `scripts/` runtime artifact — the feature stays convention+docs+test per spec opt-in framing; research R7). Primary verification: the helper resolves a fixture two-claim collision to the documented winner — exercised by `cd sw-dev-team-template && tests/coordination/test-claim-protocol.sh` (the relevant case passes).
- [X] T005 [US1] Implement the simulated-concurrency claim/collision smoke `sw-dev-team-template/tests/coordination/test-claim-protocol.sh` using the T004 tie-break helper: asserts 0 double-claims, deterministic + observer-independent winner, loser yields → reclaimable, release → reclaimable, and the protocol is advisory (no hard lock) (FR-001–FR-004, FR-016, SC-001). Primary verification: `cd sw-dev-team-template && tests/coordination/test-claim-protocol.sh`

**Checkpoint**: US1 independently testable (the claim core is proven offline).

---

## Phase 4: User Story 2 - Coordinate via issues, labels, and milestones (Priority: P2)

**Goal**: Shared at-a-glance task state via labels/milestones, and a one-issue ↔ one-handoff mapping with defined authority.

**Independent Test**: Labeled issues expose status/role/priority/blocked/release unambiguously; one issue maps to one durable handoff with a documented authority split.

### Implementation for User Story 2

- [X] T006 [US2] Add an OPTIONAL `github_issue` field to `sw-dev-team-template/schemas/handoff.schema.json` (issue number or URL; absence keeps existing handoffs valid) (FR-017). Primary verification: `cd sw-dev-team-template && tests/hooks/test-handoff-contracts.sh`
- [X] T007 [US2] Document the one-issue ↔ one-handoff mapping and the issue-vs-handoff authority split in `sw-dev-team-template/docs/coordination/multi-operator-model.md` (FR-006). Primary verification: `grep -qi 'one issue' sw-dev-team-template/docs/coordination/multi-operator-model.md && grep -q 'github_issue' sw-dev-team-template/docs/coordination/multi-operator-model.md`

**Checkpoint**: US2 independently testable.

---

## Phase 5: User Story 3 - Comments as handoff records without weakening gates (Priority: P3)

**Goal**: Structured issue comments reconstruct task history but never satisfy an evidence gate.

**Independent Test**: The comment types reconstruct claim→progress→handback history; a GATE-PASSED comment does not pass the completion gate.

### Implementation for User Story 3

- [X] T008 [US3] Document the structured comment types (CLAIM/YIELD/PROGRESS/HANDBACK/GATE-PASSED/BLOCKED) and the explicit invariant that no comment (incl. GATE-PASSED) satisfies an evidence gate, in `sw-dev-team-template/docs/coordination/multi-operator-model.md` (FR-007, FR-008). Primary verification: `grep -q 'GATE-PASSED' sw-dev-team-template/docs/coordination/multi-operator-model.md && grep -qi 'does not satisfy' sw-dev-team-template/docs/coordination/multi-operator-model.md`
- [X] T009 [US3] Add a smoke assertion (in `sw-dev-team-template/tests/coordination/test-claim-protocol.sh` or a sibling) that a GATE-PASSED comment alone does NOT satisfy the completion gate — only hook-captured `verification.*`/role-owned evidence does (SC-004, FR-008). Primary verification: `cd sw-dev-team-template && tests/coordination/test-claim-protocol.sh`

**Checkpoint**: US3 independently testable.

---

## Phase 6: User Story 4 - Opt-in downstream adoption (Priority: P4)

**Goal**: A fresh project can stand up the interface from a setup guide without editing template internals; single-operator/offline projects ignore it entirely.

**Independent Test**: Following the setup guide yields the labels/milestones/templates with no template-internal edits; a project that skips setup runs normally.

### Implementation for User Story 4

- [X] T010 [US4] Author the multi-machine operating-model content (one issue per task, comments as handoff records, labels for routing, milestones for release, only tech-lead talks to the customer, opt-in/additive) in `sw-dev-team-template/docs/coordination/multi-operator-model.md` (FR-009, FR-014). Primary verification: `grep -qi 'opt-in' sw-dev-team-template/docs/coordination/multi-operator-model.md && grep -qi 'tech-lead' sw-dev-team-template/docs/coordination/multi-operator-model.md`
- [X] T011 [US4] Author the register-sync authority table (in-repo registers vs GitHub issues/labels; registers remain binding) in `sw-dev-team-template/docs/coordination/register-authority.md` (FR-010). Primary verification: `grep -q 'CUSTOMER_NOTES.md' sw-dev-team-template/docs/coordination/register-authority.md && grep -q 'OPEN_QUESTIONS.md' sw-dev-team-template/docs/coordination/register-authority.md`
- [X] T012 [US4] Create agent-routed issue templates `sw-dev-team-template/.github/ISSUE_TEMPLATE/agent-task.yml` and `agent-review-request.yml` (role routing, acceptance criteria, prior-art/proposal links, review owner, release-note impact; default labels) (FR-011). Primary verification: `test -f sw-dev-team-template/.github/ISSUE_TEMPLATE/agent-task.yml && test -f sw-dev-team-template/.github/ISSUE_TEMPLATE/agent-review-request.yml && grep -q 'name:' sw-dev-team-template/.github/ISSUE_TEMPLATE/agent-task.yml` (and, if a YAML parser is available in-env, parse both — degrade to the grep when absent so the check reflects the template, not the toolchain).
- [X] T013 [US4] Integrate the multi-operator model-routing playbook (when to use plan mode / raise model tier / increase reasoning effort, mapped to labels) into `sw-dev-team-template/docs/model-routing-guidelines.md` (FR-012). Primary verification: `grep -qi 'multi-operator\|coordination' sw-dev-team-template/docs/model-routing-guidelines.md`
- [X] T014 [US4] Author the setup guide / `gh` bootstrap transcript (create labels via `gh label create`, milestones, confirm templates) in `sw-dev-team-template/docs/coordination/setup-guide.md` (FR-013). Primary verification: `grep -q 'gh label create' sw-dev-team-template/docs/coordination/setup-guide.md`
- [X] T015 [US4] Amend `sw-dev-team-template/scripts/scaffold.sh` so scaffolded downstream projects gitignore `.devteam/active-handoff.json` (template's own example handoff unaffected); confirm a no-setup project still scaffolds normally (FR-018, FR-014). Primary verification: `grep -q 'active-handoff.json' sw-dev-team-template/scripts/scaffold.sh`

**Checkpoint**: US4 independently testable.

---

## Final Phase: Polish & Cross-Cutting Concerns

**Purpose**: Governance, full validation, and review before commit.

- [X] T016 Move `sw-dev-team-template/docs/adr/fw-adr-0020-issues-based-coordination-model.md` Proposed→Accepted and amend `sw-dev-team-template/ROADMAP.md` v1.1.0 "Half B" exit criteria from the GitHub-Projects framing to the issues-based framing per the ADR's recorded before/after wording (FR-015). Primary verification: `grep -qi 'Status.*Accepted' sw-dev-team-template/docs/adr/fw-adr-0020-issues-based-coordination-model.md`
- [X] T017 Run the full 014 validation AND confirm the doc-validated success criteria. Run the claim/collision smoke + the handoff-schema contracts (with the new `github_issue` field) + the issue-template presence/parse (FR-016, SC-006). Then verify the inspection-validated criteria against the delivered artifacts: SC-002 (status/role/priority/blocked/release each derivable from the label taxonomy alone — checked against `docs/coordination/label-taxonomy.md` + a sample-labeled issue in the setup guide), SC-003 (claim→progress→handback history reconstructable from the structured comment types in `multi-operator-model.md`), and SC-005 (the setup-guide transcript produces the labels/milestones/templates with no template-internal edits, and a no-setup project still scaffolds/runs — opt-out). Primary verification: `cd sw-dev-team-template && tests/coordination/test-claim-protocol.sh && tests/hooks/test-handoff-contracts.sh` (plus a recorded inspection note in this task's closure covering SC-002/SC-003/SC-005 against the named artifacts).
- [X] T018 Obtain `code-reviewer` review of the changed schema, scripts, templates, docs, and ADR/ROADMAP paths before commit. Primary verification: code-reviewer SHIP verdict recorded for the 014 change set.

---

## Dependencies & Execution Order

### Requirement Coverage

- **FR-001, FR-002, FR-003, FR-004**: T003 (doc), T004 (test-only tie-break), T005 (smoke).
- **FR-005**: T002.
- **FR-006, FR-017**: T006, T007.
- **FR-007, FR-008, SC-004**: T008, T009.
- **FR-009, FR-014**: T010, T015.
- **FR-010**: T011.
- **FR-011**: T012.
- **FR-012**: T013.
- **FR-013**: T014.
- **FR-015, SC-006**: T016.
- **FR-016, SC-001**: T005, T017.
- **FR-018**: T015.
- **SC-002, SC-003, SC-005** (inspection-validated): T017 (against label-taxonomy.md / multi-operator-model.md / setup-guide.md + opt-out).

### Phase Dependencies

- **Setup (Phase 1)**: none.
- **Foundational (Phase 2)**: depends on Setup; T002 vocabulary blocks US1/US2/US3.
- **US1 (P1)**: after Foundational; the claim core + offline smoke (MVP of the coordination value).
- **US2 (P2)**: after Foundational; T006 (schema) is independent of the docs.
- **US3 (P3)**: after Foundational; shares the operating-model doc + smoke file with US2/US4 — sequence edits.
- **US4 (P4)**: after US1–US3 content exists (the operating model + setup guide reference the claim protocol, labels, comment types, mapping).
- **Polish**: after the user stories; T016 governance, T017 full validation, T018 review.

### Parallel Opportunities

- T006 (schema field) is independent of all docs and can run in parallel with US1 doc tasks.
- T012 (issue templates) is independent of the prose docs and can run in parallel within US4.
- Doc tasks that edit the SAME file (`multi-operator-model.md`: T007/T008/T010) must be sequenced.

---

## Implementation Strategy

### MVP First

1. Setup + Foundational (vocabulary).
2. US1 — the advisory claim protocol + offline simulated-concurrency smoke (the core value; proves 0 double-claims).
3. Validate: `cd sw-dev-team-template && tests/coordination/test-claim-protocol.sh`.

### Incremental Delivery

1. US1 claim core (testable offline).
2. US2 labels/mapping + the `github_issue` link.
3. US3 comments-as-records (gate-safe).
4. US4 adoption surface (operating model, register authority, templates, setup guide, scaffold gitignore, model-routing playbook).
5. Polish: accept the ADR, amend the ROADMAP exit criteria, full validation, review.

### Task Ownership

- `tech-writer`: vocabulary, claim-protocol doc, operating model, register authority, setup guide, model-routing integration, issue templates prose (T002, T003, T007, T008, T010, T011, T013, T014; T012 prose).
- `software-engineer`: `github_issue` schema field, scaffold gitignore, issue-template YAML wiring (T006, T012 wiring, T015).
- `qa-engineer`: test-only tie-break helper + claim/collision smoke + gate smoke + full validation (T004, T005, T009, T017).
- `architect`: FW-ADR-0020 acceptance + ROADMAP amendment (T016).
- `code-reviewer`: review before commit (T018).
