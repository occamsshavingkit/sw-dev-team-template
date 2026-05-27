---
name: fw-adr-0020-issues-based-coordination-model
description: Replace GitHub Projects board with plain GitHub Issues (labels + milestones + optimistic-claim convention) as the v1.1.0 Half-B multi-machine coordination layer.
status: accepted
date: 2026-05-27
---


# FW-ADR-0020 — Issues-based multi-machine coordination model (v1.1.0 Half B)

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist](#option-m--minimalist)
  - [Option S — Scalable](#option-s--scalable)
  - [Option C — Creative (experimental)](#option-c--creative-experimental)
- [Decision outcome](#decision-outcome)
- [Design: Issues-based coordination model](#design-issues-based-coordination-model)
  - [1. Issue ↔ Handoff mapping](#1-issue--handoff-mapping)
  - [2. Label taxonomy](#2-label-taxonomy)
  - [3. Issue claim / checkout convention](#3-issue-claim--checkout-convention)
    - [Claim sequence](#claim-sequence)
    - [Collision tie-break rule](#collision-tie-break-rule)
    - [Release / handback sequence](#release--handback-sequence)
    - [Local active-handoff pointer relationship](#local-active-handoff-pointer-relationship)
    - [Race window and advisory nature](#race-window-and-advisory-nature)
    - [Optional hardening](#optional-hardening)
  - [4. Comments as handoff records](#4-comments-as-handoff-records)
  - [5. Register sync and authority table](#5-register-sync-and-authority-table)
  - [6. Setup surface (bootstrap enumeration)](#6-setup-surface-bootstrap-enumeration)
  - [7. Proposed ROADMAP exit-criteria amendment](#7-proposed-roadmap-exit-criteria-amendment)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Customer rulings needed](#customer-rulings-needed)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

---

## Status

- **Accepted** — customer adopted 2026-05-27 (OPEN_QUESTIONS Q-0016); all three
  sub-rulings resolved (Q-0017/Q-0018/Q-0019; see § "Customer rulings needed")
- **Date:** 2026-05-27
- **Deciders:** `architect` (proposed); `tech-lead` + customer (acceptance)
- **Consulted:** `ROADMAP.md` § v1.1.0 exit criteria; `docs/v1.1-handoff-contracts.md`;
  `schemas/handoff.schema.json`; `docs/DECISIONS.md` D-0001; `.github/ISSUE_TEMPLATE/*`

## Context and problem statement

v1.1.0 Half A (handoff-contract spine, llmdc/Speckit integration docs) is complete.
Half B specified a GitHub-native coordination layer for multiple operators running the
agent set from different machines. The ROADMAP.md exit criteria for Half B were written
around GitHub Projects (board, field/status schema, saved views). The customer has ruled
to pursue a lighter **Issues-only** approach: GitHub Issues + labels + milestones +
comments, with no GitHub Projects board required.

The coordination layer is opt-in and additive. Single-operator and offline downstream
projects need none of it. The core constraint is that GitHub Issues has no atomic
"check out / lock an issue" primitive — task claiming across machines must be solved
by convention, and the race window must be bounded and explicitly acknowledged.

ADR trigger: cross-cutting pattern change (new coordination model + label schema);
external dependency choice locked (GitHub Issues API surface vs Projects API surface);
new convention touching multi-operator workflow. D-0001 in `docs/DECISIONS.md` is
superseded-in-part by this ADR on the GitHub Projects vs Issues choice.

## Decision drivers

- No GitHub Projects requirement: operator may or may not have Projects access; Issues
  is universally available on all plan tiers.
- Opt-in / additive: the interface adds nothing to single-operator or offline projects.
- Only `tech-lead` talks to the customer (Hard Rule #1); the coordination layer must not
  create new customer-escalation paths.
- In-repo registers (`docs/OPEN_QUESTIONS.md`, `docs/DECISIONS.md`, PMBOK artifacts)
  remain binding records; Issues are a coordination surface, not the system of record.
- The durable handoff (`docs/handoffs/<task_id>.json`) is the only authoritative task
  contract; GitHub Issues and labels are a lightweight visibility layer over it.
- Claim/collision behavior must be explicit, bounded, and produce a deterministic winner
  without a server-side lock.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist

Use only `gh` issue body + a single `claimed-by: <operator-id>` heading line in the
issue body, edited by the claimer. Status tracked by label (`status:queued`,
`status:in-progress`, `status:done`). No structured claim comment, no collision
detection, no milestone grouping. Operators self-police.

- **Sketch:** Five labels (three status + two meta), no per-role labels, no milestones.
  Issue body is the only record. No claim comment — claimer edits the body.
- **Pros:** Near-zero setup (two `gh label create` commands); no new conventions to
  document; zero risk of over-specifying a convention nobody uses.
- **Cons:** Body edits from two operators can conflict and produce a merged mess with no
  audit trail; no role-routing signal; no way to detect a collision after the fact; no
  milestone grouping means release-readiness is invisible; milestone and role-routing
  value is lost.
- **When M wins:** single-operator only, or team size ≤ 2 with strong trust and
  out-of-band coordination. Rejects here because the explicit collision story is a named
  requirement.

### Option S — Scalable

Issues + structured labels (status, role, priority) + milestones + a machine-readable
structured claim comment with operator-id, machine, session-id, and UTC timestamp.
Claim logic is optimistic/advisory: self-assign + apply `status:claimed` label + post
claim comment. Tie-break is earliest claim-comment timestamp wins. No GitHub API lock.
Local `.devteam/active-handoff.json` pointer updated at claim time and cleared at
handback. This is Option S (chosen).

- **Sketch:** ~25 labels across four groups (status, role, priority, meta). One milestone
  per release line. Claim sequence is three-step (assign + label + comment). Collision
  detection is: read the issue after posting your claim comment; if another claim comment
  with an earlier timestamp exists, yield. Role-routing labels map to the canonical agent
  roster in `CLAUDE.md`. Full setup via a reproducible `gh label create` transcript.
- **Pros:** Bounded race window (~seconds of API round-trip); deterministic tie-break
  without server changes; visible audit trail as issue comments; no Projects dependency;
  compatible with all GitHub plan tiers; maps cleanly to existing handoff schema fields;
  additive — single-operator projects ignore it.
- **Cons:** Race window is real (~seconds); claimer must re-read the issue after posting;
  advisory, not hard; convention must be documented and followed manually; no automated
  collision enforcement without a bot or CI check.
- **When S wins:** multi-operator, public or enterprise GitHub, need for role-routing
  visibility, milestone-grouped release readiness.

### Option C — Creative (experimental)

Use a dedicated "claims coordination issue" (pinned issue #0 or labeled
`meta:claim-log`) as a single append-only claim log. Every claimer posts a claim line
to that one issue. Because GitHub issue comments are append-only and server-ordered by
timestamp, that issue acts as a de-facto FIFO. Claiming a task = posting to the
coordination issue + posting to the task issue; the coordination issue's server order is
the tie-break. No self-assign step needed.

- **Sketch:** One permanent coordination issue per repo. Claim format: `CLAIM <issue#>
  operator=<id> session=<session-id> UTC=<timestamp>`. Tie-break is comment order on the
  coordination issue as returned by the API. Claimer reads back the coordination issue
  and finds its claim's position relative to any competing claim for the same issue
  number.
- **Pros:** Server-ordered append-only log provides near-hard ordering with minimal
  latency (still advisory, but ordering is server-side); no per-issue self-assign
  confusion; the coordination issue doubles as a global audit log.
- **Cons:** All multi-operator claim traffic funnels through a single issue — becomes
  noisy at scale; any downstream project must create and maintain this pinned issue;
  claim lookup requires reading a potentially long comment thread; GitHub comment
  ordering is eventually consistent in some edge cases (high-rate concurrent posts);
  adds more operational overhead than the coordination gain justifies for teams of 2–4.
- **When C wins:** repo with 10+ concurrent operators where strict FIFO matters more
  than simplicity; team has bot/CI support to maintain the coordination issue. Rejects
  here because complexity is disproportionate to the expected team size (2–4 operators
  in the target use case).

## Decision outcome

**Chosen option: S — Scalable (Issues + labels + milestones + optimistic claim comment)**

Option M has no audit trail and no collision story. Option C has a cleaner
collision model but introduces disproportionate operational overhead and a
single-point-of-noise for the expected team size. Option S gives bounded collision
detection via comment timestamps, a visible audit trail, no Projects dependency, and
a clean mapping to the existing handoff schema — at the cost of an explicit advisory
disclaimer and a documented re-read step.

---

## Design: Issues-based coordination model

### 1. Issue ↔ Handoff mapping

**One GitHub issue per coherent task. One durable handoff per coherent task.**

The relationship is:

```
GitHub Issue #NNN  ←→  docs/handoffs/<task_id>.json
```

- The **durable handoff** (`docs/handoffs/<task_id>.json`) is authoritative for:
  task scope, path boundaries (`allowed_paths`, `forbidden_paths`), role ownership
  (`owner_role`, `review_roles`), evidence gates (`requires`, `verification`), and
  completion state. This is the binding contract; hooks validate against it.
- The **GitHub Issue** is authoritative for: human-readable task description,
  label-based status visible across machines, milestone grouping, comment-based
  audit trail, and the claim record.
- Neither artifact can be authoritative for the other's domain. The issue body
  carries `task_id: <value>` so the link is explicit. The handoff carries
  `github_issue: <repo>#<number>` (a new optional top-level field in the handoff
  schema — this ADR proposes its addition).

**Authority rules:**

| State | Authoritative artifact |
|---|---|
| Task is in scope / allowed paths | `docs/handoffs/<task_id>.json` |
| Task is claimed by whom / on which machine | GitHub Issue claim comment + `status:claimed` label |
| Task is in-progress (work executing) | `.devteam/active-handoff.json` pointer (local machine) |
| Evidence gates satisfied | `docs/handoffs/<task_id>.json` `verification` block |
| Task done / completion accepted | `docs/handoffs/<task_id>.json` `completion` block + `status:done` label |
| Human-readable progress narrative | GitHub Issue comments |

The handoff `status` field and the GitHub Issue `status:*` label are **mirrored
by convention**, not enforced to be in sync. If they diverge, the handoff `status`
field is binding for hook purposes; the label is the human-visible coordination
surface. Operators are expected to keep them aligned but no hook blocks on label
mismatch.

### 2. Label taxonomy

Labels are organized into four groups. Prefixes are mandatory to avoid collision
with repository-native labels. Create with `gh label create`.

#### Group A — Status (mutually exclusive; one active at a time)

| Label | Color | Meaning |
|---|---|---|
| `status:queued` | `#E4E669` (yellow) | Task is defined, handoff exists, not yet claimed |
| `status:claimed` | `#F9A825` (amber) | Claim comment posted; operator assembling local workspace |
| `status:in-progress` | `#1565C0` (blue) | Operator has active-handoff pointer set locally; work executing |
| `status:in-review` | `#6A1B9A` (purple) | Work complete; awaiting code-reviewer or gate artifact |
| `status:blocked` | `#B71C1C` (red) | Cannot proceed; blocking reason in most-recent issue comment |
| `status:done` | `#2E7D32` (green) | Completion accepted; handoff `completion` block populated |

> **Note — label colors are advisory.** The hex values shown above are design-time placeholders. The `gh label create` transcript in `docs/coordination/setup-guide.md` is the authoritative color source for downstream bootstrap; use that transcript, not the values in this table, when creating labels.

#### Group B — Role routing (maps to canonical roster; multiple allowed)

One label per `owner_role` or `review_roles` entry on the handoff. Prefix `role:`.

| Label | Maps to roster entry |
|---|---|
| `role:tech-lead` | `tech-lead.md` |
| `role:architect` | `architect.md` |
| `role:software-engineer` | `software-engineer.md` |
| `role:qa-engineer` | `qa-engineer.md` |
| `role:sre` | `sre.md` |
| `role:tech-writer` | `tech-writer.md` |
| `role:code-reviewer` | `code-reviewer.md` |
| `role:release-engineer` | `release-engineer.md` |
| `role:security-engineer` | `security-engineer.md` |
| `role:researcher` | `researcher.md` |
| `role:project-manager` | `project-manager.md` |

SME roles are dynamic; use `role:sme-<slug>` as needed.

#### Group C — Priority (mutually exclusive)

| Label | Meaning |
|---|---|
| `priority:p0` | Blocking; must resolve before any other work |
| `priority:p1` | High; current milestone focus |
| `priority:p2` | Normal |
| `priority:p3` | Low / nice-to-have |

#### Group D — Meta / structural

| Label | Meaning |
|---|---|
| `meta:framework-maintenance` | Handoff declares `framework_scope: framework-maintenance` |
| `meta:customer-approval-required` | `requires.human_approval: true` on the handoff |
| `meta:security-review-required` | `requires.security_review: true` |
| `meta:blocked-external` | Blocked on external dependency (not another task) |

#### Milestones

One milestone per release line, named after the semver tag: `v1.1.0`, `v1.1.1`,
`v2.0.0`, etc. Milestone title = tag name. Milestone due date = target release date
(optional but recommended). All issues for a release are assigned to the milestone at
triage time. An issue with no milestone is unplanned / backlog.

**Total labels: 6 + 11 + 4 + 4 = 25 at baseline.** SME labels are added per-project.

### 3. Issue claim / checkout convention

**This mechanism is advisory and optimistic. There is no atomic server-side lock.
The race window is bounded to the round-trip time of two sequential GitHub API calls
(typically 1–5 seconds). Teams with high operator concurrency should treat collisions
as a normal occurrence and follow the yield protocol without blame.**

#### Claim sequence

Three steps, executed in order. Do not skip step 3.

**Step 1 — Self-assign.** Assign yourself to the GitHub issue using `gh issue edit
<number> --add-assignee @me`. This is a soft signal; it is not the tie-break
artifact.

**Step 2 — Apply status label.** Replace the current `status:*` label with
`status:claimed` using `gh issue edit <number> --add-label status:claimed --remove-label
status:queued`. If the issue is not `status:queued` (e.g., already `status:claimed` or
`status:in-progress`), stop and read the issue before proceeding — another operator
may have claimed it first.

**Step 3 — Post structured claim comment.** Post a comment with the following
machine-parseable body. This comment is the canonical claim record and the tie-break
artifact.

```
CLAIM task_id=<handoff task_id> issue=#<number>
operator=<operator-identifier>
machine=<hostname or short machine label>
session=<session-id or harness run ID>
ts=<UTC timestamp in ISO 8601, e.g. 2026-05-27T14:32:00Z>
```

Operator identifier is a stable handle chosen by the operator (e.g., git username or
machine nickname). Session-id is any value that ties back to the active harness
session (e.g., a UUID generated at session start, the Claude Code session token, or a
short hash).

#### Collision tie-break rule

**After posting your claim comment (Step 3), re-read the issue (`gh issue view
<number> --comments`) before setting your local `.devteam/active-handoff.json`
pointer.** This is the check step.

- Scan the issue comments for all `CLAIM task_id=<same task_id>` lines.
- Parse the `ts` field from each claim comment.
- The claim with the **earliest UTC timestamp wins**.
- If your claim comment has the earliest timestamp among all CLAIM comments for this
  task, you are the winner. Proceed to set `.devteam/active-handoff.json` and apply
  `status:in-progress`.
- If another claim comment with an earlier timestamp exists, you have **lost the
  race**. Execute the yield protocol:
  1. Post a comment: `YIELD task_id=<task_id> yielding to operator=<other-operator-id>
     reason=earlier-claim`
  2. Remove the `status:claimed` label; apply `status:queued` (or leave current status
     if the winner has already applied `status:in-progress`).
  3. Unassign yourself.
  4. Do not set `.devteam/active-handoff.json` for this task.
  5. Pick a different task or wait and re-queue.

**Clock skew caveat.** If two operators post claim comments within the same second
and UTC timestamps are equal, tie-break is lexicographic order of `operator=` field
(lower alphabetic value wins). This is deterministic and collision-proof; document it
in the operating-model guide.

#### Release / handback sequence

When work is complete and the task is ready for review:

1. Ensure `docs/handoffs/<task_id>.json` `completion` block is populated and all
   required evidence gates in `verification` are satisfied (or the handoff
   `status` is `completed`).
2. Apply `status:in-review`; remove `status:in-progress`.
3. Post a structured handback comment:

```
HANDBACK task_id=<task_id> issue=#<number>
operator=<operator-identifier>
ts=<ISO 8601 UTC timestamp>
handoff_path=docs/handoffs/<task_id>.json
target_role=<role label of the reviewer, e.g. code-reviewer>
summary=<one sentence: what was done>
```

4. Assign the issue to the reviewer if known; otherwise leave assigned to self and let
   the reviewer self-assign.
5. Clear `.devteam/active-handoff.json` (remove the file or set `task_id: null`).

When review is accepted and gates are closed:
6. Apply `status:done`; close the issue.
7. Update the handoff `completion.completed_at` and `completion.claimed_by` fields if
   not already set by the hook.

#### Local active-handoff pointer relationship

`.devteam/active-handoff.json` is a **local machine artifact only**. It is in
`.gitignore` (or should be — note the setup surface below). It points to
`docs/handoffs/<task_id>.json` but is not itself committed. Its lifecycle:

| Event | `.devteam/active-handoff.json` action |
|---|---|
| Claim won (tie-break check passed) | Write pointer: `{"task_id": "<id>", "handoff_path": "docs/handoffs/<id>.json"}` |
| Work session interrupted / machine change | File remains; resuming operator re-validates claim by re-reading the issue |
| Handback posted | Clear or remove the file |
| Yield (lost race) | Do not write the file |

The hooks (`handoff-stop-gate.py`, `handoff-pre-tool-gate.py`) read this pointer.
A winning claimer who forgets to write it will hit hook warnings. A losing claimer
who writes it anyway will have the hooks enforce the claimed handoff's path scope,
which is incorrect — the yield protocol prevents this by explicitly not writing the
pointer.

#### Race window and advisory nature

The race window opens when Step 1 starts and closes when Step 3's claim comment is
server-recorded. In practice this is the sum of three sequential API calls (assign,
label, comment), typically 1–5 seconds on a healthy GitHub API. After Step 3, the
check step (re-read) is synchronous and completes the window.

This is explicitly **not a hard lock**. A network partition, a harness crash between
Steps 2 and 3, or a slow API response can produce a state where the claim record is
absent. Operators should treat an issue that has `status:in-progress` but no claim
comment as suspect and post a coordination comment before taking over.

#### Optional hardening

These are not required for v1.1.0 but can be adopted by downstream projects with
higher operator concurrency:

- **`gh` wrapper script** (`scripts/gh-claim.sh`): automates the three-step claim
  sequence, parses the post-claim re-read, and outputs `WON` or `YIELD`. Reduces
  human error in the sequence.
- **Claims coordination issue** (Option C sketch): a single pinned issue used as an
  append-only claim log. Adds server-side ordering at the cost of a permanent
  coordination issue. Suitable for teams with 5+ concurrent operators.
- **CI claim-comment lint**: a GitHub Actions workflow that validates claim/handback
  comment syntax on issue_comment events and posts a bot comment if the format is
  malformed.

### 4. Comments as handoff records

GitHub issue comments serve as the **human-readable mirror** of the durable handoff
contract's `activity` and `verification` arrays. They do not replace those arrays
and do not satisfy evidence gates on their own.

**Structured comment types:**

| Comment type | Trigger | Fields |
|---|---|---|
| `CLAIM` | Claim sequence Step 3 | See § 3 claim sequence |
| `YIELD` | Losing claimer | `task_id`, `yielding to operator=`, `reason=` |
| `PROGRESS` | Optional mid-task update | `task_id`, `ts=`, `summary=`, `evidence_refs=` (optional) |
| `HANDBACK` | Work complete, routing to reviewer | See § 3 handback sequence |
| `GATE-PASSED` | Evidence gate satisfied | `task_id`, `gate=<test|review|security|human_approval>`, `actor_role=`, `artifact=`, `ts=` |
| `BLOCKED` | Operator cannot proceed | `task_id`, `blocking_reason=`, `ts=` |

**What comments do NOT do:**

- A `GATE-PASSED` comment does not satisfy an evidence gate on the handoff. The gate
  is satisfied when the `verification` block in `docs/handoffs/<task_id>.json` carries
  the required `evidence_kind: "accepted"` entry with the correct `actor_role`. The
  comment is a visibility artifact for other operators; the JSON is the binding record.
- `PROGRESS` comments do not constitute accepted evidence. They are narrative updates.
- No comment written by the implementing operator (`owner_role`) can satisfy a review,
  security, or human-approval gate on that same task. Role ownership rules from
  `docs/v1.1-handoff-contracts.md` § "Evidence Rules" are not relaxed by this
  coordination model.

**Evidence flow summary:**

```
Hook-captured activity  ──► verification.tests (accepted evidence, evidence_kind: "accepted")
Reviewer artifact       ──► verification.reviews (code-reviewer)
Security sign-off       ──► verification.security (security-engineer)
Customer truth          ──► verification.human_approval (researcher-stewarded)
Issue comment           ──► human-visible mirror only; not read by hooks
```

### 5. Register sync and authority table

The coordination layer is **additive**. The following authority table is binding.

| State kind | Authoritative record | GitHub Issues role |
|---|---|---|
| Open questions (unresolved) | `docs/OPEN_QUESTIONS.md` | May be referenced in issue body; not duplicated |
| Decisions made | `docs/DECISIONS.md` | A decision entry may reference the triggering issue number; the issue is not the record |
| Customer truth | `CUSTOMER_NOTES.md` (researcher-stewarded) | No issue comment may record or paraphrase customer truth |
| PMBOK artifacts (risk log, lessons, changes) | `docs/pm/*.md` | Not mirrored to Issues |
| Task scope and path boundaries | `docs/handoffs/<task_id>.json` | Issue body carries `task_id` reference |
| Evidence gates and completion state | `docs/handoffs/<task_id>.json` | `status:done` label mirrors completion; not binding |
| Label-based status (visibility) | GitHub Issues | Mirrors handoff `status`; handoff wins on conflict |
| Role routing (visibility) | GitHub Issues `role:` labels | Source of truth for triage routing |
| Milestone grouping (release) | GitHub Issues milestones | Mirrors ROADMAP release lines |
| Customer-question queue | `docs/OPEN_QUESTIONS.md` | Not in Issues; Hard Rule #11 still governs batching |

**Non-goals preserved:**

- `docs/OPEN_QUESTIONS.md`, `CUSTOMER_NOTES.md`, and `docs/DECISIONS.md` are not
  replaced. Issues are a coordination surface, not a register.
- Only `tech-lead` interfaces with the customer (Hard Rule #1). No issue comment
  creates a new customer-escalation path. Issues are visible to operators, not a
  customer inbox.
- Single-operator and offline downstream projects need none of this. No script, no
  label, no issue template is required for offline use.

### 6. Setup surface (bootstrap enumeration)

What a fresh downstream project needs to enable the coordination model. The eventual
setup guide writes these up; here we enumerate them.

**Labels (all 25 baseline labels via `gh label create`):**

- 6 status labels (see Group A)
- 11 role labels (see Group B, plus `role:sme-<slug>` as needed)
- 4 priority labels (see Group C)
- 4 meta labels (see Group D)

**Milestones:** one per release line, created via `gh api repos/{owner}/{repo}/milestones`.

**Issue templates (additions to existing `.github/ISSUE_TEMPLATE/`):**

The existing templates (`feature-request.yml`, `framework-gap.yml`) cover upstream
framework use. The coordination model needs two new templates for in-project
operational use:

- `agent-task.yml` — for a routable agent task: fields for `task_id`, `owner_role`
  (dropdown from canonical roster), `handoff_path`, `acceptance_criteria` (textarea),
  `blocked_by` (optional). Pre-assigns `status:queued`. Note: GitHub issue-form
  templates can only pre-assign static labels at filing time; the `role:` label must
  be applied manually after the issue is filed (a GitHub platform constraint), so
  "pre-assign role label" should be read as "apply role label at triage."
- `agent-review-request.yml` — for a handback routed to a reviewer: fields for
  `task_id`, `handoff_path`, `gate` (dropdown: review / security / human_approval),
  `reviewer_role`. Pre-assigns `status:in-review`.

These templates produce the structured data that makes saved searches useful. They are
in-project templates, not shipped by the framework (downstream project creates them per
`docs/framework-project-boundary.md` Layer 3).

**`.gitignore` entry:** `.devteam/active-handoff.json` must be ignored so the local
claim pointer is never committed. Verify `scripts/scaffold.sh` adds this (or that
`.devteam/` is already covered).

**Saved searches (no configuration needed — just document these):**

- "My active tasks": `is:open is:issue assignee:@me label:status:in-progress`
- "Available tasks for a role": `is:open is:issue label:status:queued label:role:<role>`
- "Needs review": `is:open is:issue label:status:in-review`
- "Blocked": `is:open is:issue label:status:blocked`
- "Milestone queue": `is:open is:issue milestone:<version>`

**Optional `gh` alias set** (documents `gh alias set` commands for the claim/handback
workflow — part of the setup guide, not the setup script).

### 7. Proposed ROADMAP exit-criteria amendment

The following shows the **before/after** wording for the v1.1.0 exit-criteria bullets
that are affected by the GitHub Projects → Issues change. These are proposed; the
customer and tech-lead must ratify before `ROADMAP.md` is edited.

---

#### BEFORE (current ROADMAP.md lines ~296–311, Half B exit criteria)

```
- A documented GitHub Projects field/status schema exists.
- At least one issue/task template supports agent-routed work from
  intake through review.
- Agent model-routing guidelines are reviewed against current provider
  docs and mapped to issue labels or fields where useful.
- The `llmdc` workflow integration has a documented owner role, allowed
  artifact / hook touchpoints, and explicit evidence-gate boundaries.
- The Speckit workflow integration documents when each Speckit command is
  used, how outputs map to canonical roles and `docs/handoffs/*.json`,
  and what remains governed by `tech-lead` customer-question rules.
- A fresh downstream project can follow the setup guide and produce a
  usable board without hand-editing the template internals.
- The coordination model has been smoke-tested with at least two
  concurrent agent operators on separate machines, or explicitly
  deferred with a narrower single-operator validation note.
```

#### AFTER (proposed replacement)

```
- A documented GitHub Issues label taxonomy exists covering status,
  role routing, priority, and meta groups, creatable via a `gh label
  create` transcript without GitHub Projects access.
- An optimistic issue-claim convention is documented: self-assign +
  status label + structured claim comment (operator-id, machine,
  session-id, UTC timestamp); earliest-timestamp tie-break for
  collisions; yield protocol for the losing claimer; advisory nature
  and race-window bounds are stated explicitly.
- At least two issue/task templates support agent-routed work:
  `agent-task.yml` (intake through in-progress) and
  `agent-review-request.yml` (handback through review).
- The register-authority table is documented: which state is
  authoritative in `docs/handoffs/*.json`, which in `docs/DECISIONS.md`
  / `docs/OPEN_QUESTIONS.md` / PMBOK artifacts, and which in GitHub
  Issues labels/milestones, with explicit preservation of the non-goals
  (in-repo registers not replaced; only `tech-lead` talks to the
  customer; interface is opt-in).
- Agent model-routing guidelines are reviewed against current provider
  docs and mapped to issue `role:` labels where useful.
- The `llmdc` workflow integration has a documented owner role, allowed
  artifact / hook touchpoints, and explicit evidence-gate boundaries.
- The Speckit workflow integration documents when each Speckit command is
  used, how outputs map to canonical roles and `docs/handoffs/*.json`,
  and what remains governed by `tech-lead` customer-question rules.
- A fresh downstream project can follow the setup guide and bootstrap
  the label set, milestones, and issue templates without hand-editing
  template internals.
- The coordination model has been smoke-tested with at least two
  concurrent agent operators on separate machines using the claim/yield
  convention, or explicitly deferred with a narrower single-operator
  validation note and a recorded customer ruling.
```

**Key changes from before to after:**

| Removed | Replaced with |
|---|---|
| "documented GitHub Projects field/status schema" | label taxonomy (status/role/priority/meta groups) + `gh label create` transcript |
| "produce a usable board" | bootstrap the label set, milestones, and issue templates |
| (implicit Projects dependency in "fields") | explicit optimistic-claim convention with tie-break |
| (no register-authority statement) | explicit register-authority table as exit criterion |

The two-template minimum (`agent-task.yml`, `agent-review-request.yml`) replaces
"at least one issue/task template" with a concrete two-template requirement, and
the existing llmdc / Speckit / model-routing / smoke-test criteria carry forward
unchanged in substance.

---

## Consequences

### Positive

- No GitHub Projects plan tier required; works on free-tier repos.
- Additive: zero friction for single-operator or offline downstream projects.
- Claim audit trail is durable (issue comments are immutable append-only records).
- Label taxonomy maps directly to the canonical agent roster and handoff schema fields.
- `github_issue` field on the handoff creates a bidirectional link navigable from
  either artifact.
- Tie-break rule is deterministic (UTC timestamp, then lexicographic on operator-id);
  no ambiguous "who got there first" disputes.

### Negative / trade-offs accepted

- Advisory only. A network partition or harness crash during the claim sequence can
  produce an orphaned claim. The re-read step mitigates but does not eliminate this.
- Label sync is manual by convention. No hook enforces that the label matches the
  handoff `status` field; divergence is possible and operators must self-police.
- The claim convention is a new procedure; operator onboarding must cover it.
- The `github_issue` field proposed for `schemas/handoff.schema.json` is a minor
  schema addition and requires a schema version bump or an optional extension pattern
  (customer ruling needed — see below).

### Follow-up ADRs

- A future ADR may address the optional `gh-claim.sh` wrapper script once the
  convention has been used in practice and the happy-path is known.
- If the claims coordination issue (Option C sketch) is adopted by a downstream
  project, a project-local ADR should record that choice.

## Customer rulings needed

All three rulings were obtained 2026-05-27 and are recorded in OPEN_QUESTIONS.md.
This ADR is accepted.

1. **Schema addition for `github_issue` field.** (Q-0017)
   **RESOLVED 2026-05-27 — Add now.** The optional `github_issue` field is included in
   v1.1.0 on the handoff record and `schemas/handoff.schema.json`, providing a
   bidirectional issue↔handoff link. Implemented as FR-017 in feature 014.

2. **Smoke-test deferral threshold.** (Q-0018)
   **RESOLVED 2026-05-27 — Deferral pre-authorized.** Single-operator validation plus
   a simulated-concurrency smoke satisfies the v1.1.0 exit criterion. A live
   two-machine/two-operator test is a recorded deferred follow-up item; it does not
   block v1.1.0 exit. Implemented as FR-016 in feature 014.

3. **Claim convention in `.devteam/active-handoff.json` gitignore.** (Q-0019)
   **RESOLVED 2026-05-27 — Amend scaffold.** `scripts/scaffold.sh` is amended so that
   scaffolded downstream projects gitignore `.devteam/active-handoff.json`. The
   template's own example handoff files are unaffected. Implemented as FR-018 in
   feature 014.

## Verification

- **Success signal:** A downstream project with two operators can claim, execute, and
  hand back a task without producing a diverged handoff state; the issue comment
  thread shows a clear CLAIM/HANDBACK audit trail; no GitHub Projects board is created
  or required.
- **Failure signal:** Operators routinely find the claim convention ambiguous, skip the
  re-read step and produce conflicting local active-handoff pointers, or find the label
  taxonomy too coarse to route work without an out-of-band channel.
- **Review cadence:** Re-examine at v1.2.0 scoping or after first downstream multi-
  operator project completes a milestone cycle, whichever comes first.

## Links

- `ROADMAP.md` § "v1.1.0 — handoff contracts and coordination interface"
- `docs/v1.1-handoff-contracts.md` (Half A, implemented)
- `schemas/handoff.schema.json`
- `docs/DECISIONS.md` D-0001 (superseded in part by this ADR on the Projects vs Issues choice)
- `.github/ISSUE_TEMPLATE/feature-request.yml`, `.github/ISSUE_TEMPLATE/framework-gap.yml` (existing templates)
- `docs/framework-project-boundary.md` (path ownership for downstream issue templates)
- `docs/model-routing-guidelines.md`
