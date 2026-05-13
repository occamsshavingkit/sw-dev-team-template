# Memo: Workflow redesign for v0.12.0 — composing #32 / #33 / #34 / #35

> **Status**: Proposal doc — non-binding. Binding rules from this
> proposal moved to [docs/workflow-pipeline.md](../workflow-pipeline.md)
> on 2026-05-13 per FR-017 + M4.4. This file is retained for
> historical rationale and migration narrative only.

**Status:** proposed (recommendation only). Tech-lead + customer
review required before any implementation dispatch.
**Author:** `architect`. Persisted by `tech-lead` (architect spawn
did not get `Write` tool access in its invocation — see §Note at end).
**Date:** 2026-04-23. Template version: v0.11.0.

## 0. Executive summary

Four proposals — Researcher-First (#34), Three-Path Rule (#33),
Options Before Actions (#32), Solution Duel (#35) — each add a
pre-code thinking gate. Individually each is defensible; shipped as
four independent rules they will compound into an N-artifact
pre-code ceremony that strangles trivial work. This memo recommends
composing them into **one ordered pipeline** — prior-art →
three-path → proposal → duel → code — gated by a
**mechanically-decidable non-triviality trigger**, with documented
escape hatches, and recommends **phased adoption**: #34 and #32
first (lowest ceremony, highest hallucination-cost payoff), then
#35 as a revision loop on #32's artifact, then #33 last (highest
ceremony, also the most duplicative of existing ADR trigger list).

## 1. Composition — one pipeline, five stages

See `docs/workflow-pipeline.md` § Stages for the canonical
five-stage table, feed relationships, and the pipeline-not-gate
semantics. The composition narrative below (rationale only) explains
*why* the four proposals chain into a single pipeline rather than
shipping independently.

The four proposals are not parallel; they form a dependency chain on
a single deliverable path. Stage order is: prior-art (#34) →
three-path (#33) → engineer proposal (#32) → solution duel (#35) →
code. Prior-art feeds both the architect (so alternatives aren't
reinvented) and the engineer (so implementation picks the right
library/API signatures). Three-path is upstream of proposal, not
parallel. The duel is a revision loop on the proposal artifact,
not a separate document class — that is why this redesign collapses
four proposed rules into a single artifact stream rather than four
independent gates.

## 2. Trigger threshold (mechanical, not judgment)

See `docs/workflow-pipeline.md` § Transition rules for the canonical
six-clause OR-set trigger, the trigger-false default, the
trigger-annotation convention, and post-hoc auditability.

The rationale, retained here, is that a judgment threshold ("only
for non-trivial tasks") is gameable and inconsistent across agents,
and that file-count alone is the wrong proxy: a one-line auth
change is more consequential than a ten-file rename. The OR-set
reuses six conditions that are already independent ADR or
Hard-Rule triggers elsewhere in the template, so the workflow
threshold drifts in lockstep with the gates it sits next to.

## 3. Integration with existing gates (no duplication)

See `docs/workflow-pipeline.md` § Transition rules ("Integration with
existing gates") for the canonical list of DoR / ADR / qa-engineer /
code-reviewer / Hard-Rule / CHANGES.md interactions and the
"no-new-gate-file" rule.

The rationale for slotting between DoR and code (rather than in
parallel with existing gates) is that every overlap below — ADR
trigger list, qa-engineer adversarial stance, code-reviewer two
modes, CHANGES.md — already has a defined home; introducing a
parallel gate would have created drift between the new pipeline and
the existing gates it would shadow.

## 4. Artifact catalogue

See `docs/workflow-pipeline.md` § Transition rules ("Artifact
catalogue") for the canonical paths, owners, consumers, and
retention rules of the four artifact classes (prior-art scan,
three-path design options collapsed into the ADR, engineer
proposal, and solution duel annex).

The catalogue design choice retained here for rationale: only one
genuinely new artifact class ships (prior-art); three-path collapses
into the ADR's Alternatives-considered section, and the duel annex
lives inside the proposal as a fenced `## Duel` section. The
collapse pattern keeps net artifact-count growth to one rather than
four.

## 5. Routing-table changes (proposed in prose)

Proposed additions to `.claude/agents/tech-lead.md` routing table,
no diffs written:

- New row: *"Prior-art scan for a triggered task (new library,
  public-API change, cross-module, safety/security/data-model
  path)"* → `researcher`.
- New row: *"Three-path design options for a triggered task"* →
  `architect`.
- New row: *"Implementation proposal (pre-code think-in-workspace)
  for a triggered task"* → `software-engineer`.
- New row: *"Solution duel — adversarial review of an engineer
  proposal before code starts"* → `qa-engineer`.

Additionally, `tech-lead.md` §Job item 2 gains a sub-bullet: *"For
every task, annotate `Trigger: <clauses|none>` per the
workflow-redesign criteria before dispatch. If trigger fires,
dispatch the pipeline in order (researcher → architect → engineer →
qa → engineer-revise → code); if not, dispatch directly to the
assignee."*

Parallelism default still applies: stages 1 and 2 can overlap if
the three-path design doesn't need prior-art (e.g., architectural
choice is library-agnostic). `tech-lead` makes that call.

## 6. Agent-file changes (new rules; conflicts flagged)

See `docs/workflow-pipeline.md` § Transition rules ("Agent-file
binding rules") for the canonical rule text for `researcher.md`,
`architect.md`, `software-engineer.md`, and `qa-engineer.md`, plus
the duel round-limit rule. The conflict checks performed at design
time (no conflict with existing researcher §Job, ADR trigger list,
software-engineer Constraints, or qa-engineer Adversarial-stance
clause) are reproduced in the rationale notes below.

Conflict-check notes (rationale only):

- `researcher.md` — the new rule makes the existing §Job item on
  prior-art scans concrete rather than ambient.
- `architect.md` — the ADR trigger list already fires on the same
  conditions as the workflow trigger, so the three-path rule lands
  inside an artifact the architect was going to write anyway.
- `software-engineer.md` — the existing "Do not silently expand
  scope" constraint and the "Diffs with short rationale. No
  essays." output rule are both untouched; proposals are a
  pre-code artifact and live alongside, not inside, the diff.
- `qa-engineer.md` — the duel extends the existing
  Adversarial-stance posture to an earlier gate; the post-code
  stance still fires at diff-review time.

## 7. Escape hatches

See `docs/workflow-pipeline.md` § Exit gates / Hard-block conditions
("Escape hatches") for the canonical list of five exits
(sub-trigger, emergency security patch, single-line fix on a
triggered path, spike / throwaway, no-re-entry-after-failed-
revision), plus the rule that all hatches are `tech-lead` calls
recorded in the task file and audited by `code-reviewer`.

The design intent retained here: the pipeline is heavy and heavy
ceremony kills trivial work, so the hatches are deliberately broad
on the lightweight end (typo / log line / docstring / spike) and
narrow on the high-risk end (emergency security only when an
actively-exploited CVE is on the table, with retroactive ADR within
seven days). The hatches mirror the shape of the existing
Hard-Rule-#4 live-approval path; they do not introduce a new
exception model.

## 8. Composition examples

### Example A — trivial task (pipeline skipped)

**T-1042:** "Fix typo in operator manual heading."

- `tech-lead` annotates: `Trigger: none`.
- Pipeline skipped. Task dispatched directly to `tech-writer`.
- Artifacts produced: the diff, nothing else.

Total pre-code artifacts: **0**.

### Example B — medium task (partial pipeline)

**T-1057:** "Add rate-limiting middleware to public HTTP handler
using an existing in-tree token-bucket utility."

- `tech-lead` annotates: `Trigger: (2) public-API change`. No new
  dep; single module; no safety/security path.
- `tech-lead` invokes §7 hatch #3: "proposal only, no three-path,
  no duel — internal utility already exists; no library selection
  and no novel design." Recorded in task file.
- `researcher` produces `docs/prior-art/T-1057.md` — one-page
  scan confirming the token-bucket utility's algorithm is
  canonical; no newer standard to cite.
- `software-engineer` produces `docs/proposals/T-1057.md` —
  implementation sketch, rate-limit config surface, test plan.
- Code proceeds after tech-lead signs off on the proposal.

Total pre-code artifacts: **2** (prior-art + proposal).

### Example C — non-trivial task (full pipeline)

**T-1071:** "Add OAuth2 authorization-code flow to the public API,
using a new library."

- `tech-lead` annotates: `Trigger: (1) new dep, (2) public-API
  change, (5) auth path` — full pipeline plus Hard Rule #7.
- Stage 1: `researcher` produces `docs/prior-art/T-1071.md` —
  RFC 6749 / 8252 landscape, candidate libraries (A / B / C) with
  license + maintenance status.
- Stage 2: `architect` produces ADR-034 with three alternatives:
  - M (minimalist): library A, minimum viable flow, no PKCE
    enforcement server-side.
  - S (scalable): library B + session store abstraction, PKCE
    mandatory, token-revocation endpoint.
  - C (creative): roll own on top of JWT primitives already
    in-tree.
  ADR concludes: S, with stated reason.
- Stage 3: `software-engineer` produces `docs/proposals/T-1071.md`
  — library B chosen, interface sketch, storage sketch, test-plan
  outline, dependency on `security-engineer` review.
- Stage 4: `qa-engineer` writes duel findings into the proposal:
  (a) token-revocation endpoint not tested under concurrent-
  revocation race, (b) refresh-token rotation missing, (c) PKCE
  failure mode leaks error detail in logs. `software-engineer`
  revises for (a) and (b); for (c), rebuts with "log sanitizer
  already in place — cite commit SHA"; tech-lead ratifies.
- Stage 5: code written, tests, `code-reviewer` + `security-
  engineer` joint review per Hard Rule #7, customer sign-off per
  Hard Rule #4, merge.

Total pre-code artifacts: **3 files** (prior-art / ADR-034 /
proposal-with-duel).

## 9. Risks

### 9.1 Token cost

Four pre-code artifacts per non-trivial task, each dispatched
through a named specialist, is expensive. Rough estimate: a
full-pipeline task adds ~4× the pre-code token cost of today's flow.
Mitigations:

- Collapsing three-path into the existing ADR (§4.2) removes one
  artifact class.
- The duel annex living inside the proposal (§4.4) removes
  another.
- Trigger-gated escape hatches (§7) keep the pipeline off trivial
  work.
- Net expected overhead on *eligible* tasks: 2–3× pre-code tokens;
  on the whole task stream (including sub-trigger tasks) the
  average is much smaller.
- Recommendation: `project-manager` instruments
  `docs/pm/TOKEN_LEDGER.md` (existing) with a `pipeline-stage`
  column for v0.12.0, so after one milestone we have empirical
  data to tune the trigger.

### 9.2 Duel stalemate / round-limit

Without a limit, QA and engineer can ping-pong. One round,
escalation to `tech-lead` on unresolved findings, escalation to
customer per Hard Rule #4 if tech-lead can't resolve. The
adversarial stance is not a license for ceremony.

### 9.3 Gaming the trigger

Mechanical triggers are gameable. If "new external dependency"
triggers the pipeline, an engineer might fold a new dep into an
internal utility wrapper and call it "no new dep." Detection:

- `code-reviewer` audit mode grows a check: scan the diff for new
  entries in the dependency manifest (`package.json`, `Cargo.toml`,
  `requirements.txt`, `go.mod`, etc.) and verify a matching
  prior-art artifact exists.
- Similarly for public-API changes: grep the diff's exported-symbol
  set against requirements.md / architecture.md.
- Gaming detection is post-hoc, not preventive. First finding of
  this shape is a culture signal; `process-auditor` at 2–3-
  milestone cadence picks up structural gaps.

### 9.4 Prior-art drift

Library docs change between prior-art write and code ship.
Mitigation:

- Prior-art artifact carries `Last verified: YYYY-MM-DD` and
  library version.
- `researcher` re-verifies prior-art at two points: on any major-
  version bump of a cited library, and at milestone close for
  still-open tasks. Same cadence pattern as pronoun re-verification
  in `researcher.md` §6.
- `code-reviewer` audit mode spot-checks prior-art freshness when
  approving a task older than 30 days from prior-art write.

### 9.5 Interaction with Hard Rules #2, #4, #7

See `docs/workflow-pipeline.md` § Exit gates / Hard-block conditions
("Interaction with Hard Rules #2, #4, #7") for the canonical text,
including the `security-engineer.md` joint-duelist rule.

Rationale retained here: the pipeline is design-time; the existing
hard-rule sign-offs are release-time. Putting `security-engineer`
into the duel on auth / authz / secrets / PII / network-exposed
paths means design-stage failure modes get caught by the right pair
of adversarial reviewers (qa-engineer + security-engineer) without
duplicating or weakening the release-time sign-off the hard rule
already demands.

## 10. Recommendation block

Per-proposal disposition:

- **#34 Researcher-First** — adopt with modifications. Gate on §2
  trigger, not every task. Artifact is durable. Single-highest-
  value change for hallucinated-library-usage prevention.
- **#33 Three-Path Rule** — adopt with modifications. Do not
  create a new artifact class; fold Minimalist / Scalable /
  Creative into the **Alternatives considered** section of the
  ADR that §2 already requires.
- **#32 Options Before Actions** — adopt as drafted, trigger-
  gated. Pre-code proposal artifact is the think-in-workspace
  gate that the duel (#35) attaches to.
- **#35 Solution Duel** — adopt with modifications. Annex to #32's
  proposal, not a separate file. One-round limit, escalate to
  tech-lead on unresolved findings. On Hard-Rule-#7 paths,
  `security-engineer` joins the duel.

### Overall shipping recommendation — phased, not all-at-once

Three-phase rollout across v0.12.0 and v0.13.0:

- **Phase 1 (v0.12.0):** ship #34 prior-art + #32 proposal. New
  templates: `prior-art-template.md`, `proposal-template.md`.
  Trigger annotation in `tech-lead.md`. DoR row in task template.
  Lowest-risk half of the pipeline; builds the artifact flow
  without the adversarial loop.
- **Phase 2 (v0.12.1 or v0.13.0):** ship #35 Solution Duel as an
  annex to the existing proposal. New `qa-engineer.md` job item
  plus a template section add, not a new artifact class. Depends
  on Phase 1 existing.
- **Phase 3 (v0.13.0):** ship #33 Three-Path as an expansion of
  the ADR Alternatives-considered guidance. Smallest code change,
  highest ceremony, most duplicative of existing ADR mechanics —
  lowest urgency, therefore last.

Phasing is a risk-management move: Phase 1 is mechanically simple
and immediately useful; Phase 2 depends on Phase 1 landing
cleanly; Phase 3 is a stylistic upgrade to a shape the team
already writes.

If the customer prefers a single-release bundle, **Phases 1+2 in
v0.12.0** is defensible (the two tightly-coupled halves ship
together; the mostly-ADR-cosmetic Phase 3 slips to v0.13.0).

---

## Note on architect tool-grant gap (flagged for follow-up)

This memo's initial dispatch returned the content in the agent's
response rather than as a written file — the `architect` spawn did
not receive the `Write` tool despite `architect.md` frontmatter
declaring `tools: Read, Grep, Glob, Write, Edit, SendMessage`.
`tech-lead` persisted the content to this path manually.

The `scripts/audit-agent-tools.sh` script (shipped in v0.11.0)
inspects the *declared* tools: line, not the tools actually
granted at dispatch time. If this is a harness pattern (subagent
spawns losing declared tools), file an upstream issue against
Claude Code. If it is a one-off, note it and move on.
