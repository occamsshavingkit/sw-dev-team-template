# Workflow Pipeline — sw-dev-team-template

<!-- Classification: canonical. Source plan §M4.4, FR-017. Owners:
     architect (pipeline shape), tech-writer (this document). Binding
     for the template's downstream ship-set. -->

Binding rules for the multi-agent workflow pipeline used by the
sw-dev-team-template framework: pipeline stages, the trigger threshold,
integration with existing gates, the artifact catalogue, agent-file
binding rules, escape hatches, and Hard-Rule interaction.

This file is the canonical home. Shipped-downstream files MAY reference
it but MUST NOT reference `docs/proposals/workflow-redesign-v0.12.md` for
binding content. The proposal doc is retained only for historical
rationale and migration narrative; it is excluded from the downstream
scaffold (see `scripts/scaffold.sh` exclude list for `docs/proposals/`).

## Stages

The pre-code workflow is a five-stage pipeline. Each stage's artifact is
the next stage's required input. Skipping mid-pipeline is allowed only
via the escape hatches below.

| # | Stage | Owner | Input | Output artifact | Consumed by |
|---|---|---|---|---|---|
| 1 | Prior-art scan | `researcher` | task brief | `docs/prior-art/<task-id>.md` | stages 2, 3 |
| 2 | Three-path design | `architect` | task brief + prior-art | ADR §Alternatives considered (three alternatives) | stage 3 |
| 3 | Engineer proposal | `software-engineer` | chosen path + prior-art | `docs/proposals/<task-id>.md` | stage 4 |
| 4 | Solution duel | `qa-engineer` → `software-engineer` revision | proposal | duel annex appended to `docs/proposals/<task-id>.md` | stage 5 |
| 5 | Code | `software-engineer` | revised proposal | diff + tests | existing review + merge flow |

**Feed relationships (binding).**

- Prior-art feeds both the architect (so alternatives aren't reinvented)
  and the engineer (so implementation picks the right library/API
  signatures). Writing it once, consuming it twice is the reason it goes
  first.
- Three-path is **upstream of** proposal, not parallel. The engineer's
  proposal is the chosen path made concrete. If the three-path step is
  skipped (see trigger below), the engineer's proposal stands alone; if
  kept, the proposal cites which of M/S/C it implements and why.
- The duel is a **revision loop on stage 3's artifact**, not a separate
  document class. QA's "three ways this fails in production" attaches as
  an annex to the proposal; engineer either revises the proposal
  in-place or rebuts each finding in-annex. This matters for retention
  and for not creating a fifth artifact.
- Code does not start until the duel annex is closed (either all
  findings addressed or explicitly accepted-as-risk by `tech-lead`).

This is a pipeline, not a gate: each stage's artifact is the next
stage's required input.

## Transition rules

### Trigger threshold (mechanical, not judgment)

Each issue's triage hint asks whether the rule fires every task or only
"non-trivial" ones. A judgment threshold ("only for non-trivial tasks")
is gameable and inconsistent across agents. Binding rule: **any
OR-clause triggers the full pipeline.** All conditions are mechanically
checkable from the task file, the diff plan, or the routing table.

**Trigger = true if any of:**

1. **New external dependency.** Task adds or upgrades any
   library/framework not previously in the project's dependency
   manifest. (Pure transitive-pin bumps don't count; direct-dependency
   adds do.) This is `architect.md` ADR trigger #2 and the single
   strongest hallucination signal for the prior-art stage.
2. **Public-API change.** Task modifies any exported symbol (function,
   type, endpoint, CLI flag, config key) that is named in
   `docs/requirements.md`, an ADR, or a public interface doc. Detected
   by comparing the proposed diff's changed-symbol set against `grep -l`
   of those files.
3. **Cross-module boundary crossed.** Task's file set spans two or more
   top-level source modules/packages as defined in the project's
   architecture doc. Single-module changes don't trigger.
4. **Safety-critical or Hard-Rule-#4 path touched.** Any file flagged
   safety-critical in `CUSTOMER_NOTES.md` or by an ADR.
5. **Hard-Rule-#7 path touched.** Any file in auth / authz / secrets /
   PII / network-exposed surface as enumerated for `security-engineer`.
6. **Data model change.** Schema, serialization format, persistence swap
   (matches ADR trigger #3).

**Trigger = false** (pipeline skipped) if none of (1)–(6) holds.
Typical below-threshold work: typo fix, single-function internal
refactor, adding a log line, updating a docstring, tightening a lint
rule.

**Why OR-set rather than a single metric.** File-count alone (e.g., "≥5
files") is the wrong proxy: a one-line auth change is more consequential
than a ten-file rename. Each of (1)–(6) is already an independent ADR or
Hard-Rule trigger elsewhere in the template; reusing those definitions
means the workflow threshold drifts in lockstep with the gates it sits
next to.

**Who decides trigger status (binding).** `tech-lead`, at task dispatch
time, writes a single-line trigger annotation into the task file:
`Trigger: <list of clauses that fire, or "none">`. Annotation is
mechanically auditable post-hoc by `qa-engineer` at milestone close
(new DoD row in task template).

### Integration with existing gates (no duplication)

The pipeline slots **between DoR and code**, not in parallel with
existing gates. Concretely:

- **Task template DoR** stays as-is. A new DoR row is added: *"If
  trigger fires (see trigger threshold), required pipeline artifacts
  (prior-art / design-options / proposal) exist and are linked from
  this task."*
- **`architect` ADR trigger list** overlaps heavily with the workflow
  trigger. Rather than duplicate, **the three-path artifact for a task
  under trigger is the ADR body's "Alternatives considered" section** —
  the architect writes one ADR that incorporates the three-path
  options, rather than writing an ADR and a separate design-options
  doc. This collapses three-path into the existing ADR stream.
- **`qa-engineer` adversarial stance** is *attitude at diff-review
  time.* Solution Duel is *attitude at proposal-review time.* They
  compose: same adversarial posture, applied earlier. The qa-engineer
  agent file gains a new job item; the stance text stays put.
- **`code-reviewer` two modes** are unchanged. Review mode still fires
  at diff time. The duel does not replace review — it catches
  design-level fails earlier; review still catches implementation-level
  fails.
- **Hard Rules #2, #4, #7** are unchanged. The pipeline produces
  artifacts that *feed* the customer and security-engineer sign-offs
  those rules require; it does not substitute for them. See Hard-Rule
  interaction section below.
- **`docs/templates/pm/CHANGES.md`** is unchanged. Scope changes
  discovered during prior-art (stage 1) or duel (stage 4) still route
  through CHANGES.md.

**No new gate file.** The pipeline is DoR-resident; the task template's
DoR row is the single enforcement point.

### Parallelism

Parallelism default still applies: stages 1 and 2 can overlap if the
three-path design doesn't need prior-art (e.g., architectural choice is
library-agnostic). `tech-lead` makes that call.

### Artifact catalogue (binding paths, owners, retention)

Four new (or one new + three existing-reuses) artifact classes:

#### Prior-art scan

- **Path:** `docs/prior-art/<task-id>.md`
- **Template:** `docs/templates/prior-art-template.md` — sections: Task
  reference / Search scope (which standards + vendor docs + canonical
  libraries queried) / Canonical solution found (or "none") / Candidate
  libraries + versions + license / Known pitfalls / Citations
  (Tier-1/2/3 per `researcher.md`).
- **Owner:** `researcher`.
- **Consumers:** `architect` (stage 2), `software-engineer` (stages 3
  and 5).
- **Retention:** **durable**. Git-tracked. Small (one page typical),
  high reuse value on follow-up tasks, and it's the audit trail for
  "why we picked library X." Stored under `docs/prior-art/`
  permanently; archived via `researcher`'s archival rule only when the
  covered feature is removed.

#### Three-path design options (collapsed into ADR)

- **Path:** no new file. The three alternatives land in the ADR's
  **Alternatives considered** section. ADR path remains
  `docs/adr/ADR-NNN-<slug>.md`.
- **Template:** existing `docs/templates/architecture-template.md` ADR
  shape; the "Alternatives considered" guidance requires **three**
  alternatives labeled Minimalist / Scalable / Creative, with
  one-paragraph trade-off per alternative.
- **Owner:** `architect`.
- **Consumers:** `software-engineer` (stage 3), `code-reviewer` (audit
  mode — checks that the shipped code matches the chosen path).
- **Retention:** **durable** (ADRs are already durable).

#### Engineer proposal

- **Path:** `docs/proposals/<task-id>.md`
- **Template:** `docs/templates/proposal-template.md` — sections: Task
  reference / Chosen ADR path (M/S/C) / Implementation sketch
  (pseudocode or interface-level, not production code) / Dependencies
  touched / Test plan outline / Risks + mitigations / Open questions.
- **Owner:** `software-engineer`.
- **Consumers:** `qa-engineer` (stage 4 duel), `code-reviewer` (audit
  mode reference).
- **Retention:** **durable for non-trivial; transient below
  threshold.** Proposals for tasks that triggered stay in the repo as
  the design-intent record the code is measured against. If the
  customer prefers slimming, a post-merge archival pass can move
  proposals to `docs/proposals/ARCHIVE/` after the next milestone
  close.

#### Solution duel annex

- **Path:** appended to `docs/proposals/<task-id>.md` as a fenced
  `## Duel` section. Not a separate file.
- **Template:** `docs/templates/proposal-template.md` ships a `## Duel`
  section with two subsections: *Findings* (QA lists three
  ways-to-fail) and *Rebuttals / revisions* (engineer responds
  per-finding — either proposal revised, or risk accepted with
  justification and tech-lead ratification).
- **Owner:** jointly stewarded — `qa-engineer` writes Findings;
  `software-engineer` writes Rebuttals.
- **Consumers:** `tech-lead` (for ratification if any finding is
  disputed), `code-reviewer` (audit reference).
- **Retention:** travels with the proposal — same policy.

### Agent-file binding rules

#### `researcher.md`

Binding rule: *"Prior-art artifact on triggered tasks. When `tech-lead`
dispatches a task annotated with any trigger clause, produce
`docs/prior-art/<task-id>.md` per `prior-art-template.md` before the
architect or engineer is dispatched to downstream stages."* This makes
the researcher's §Job item on prior-art scans concrete rather than
ambient.

#### `architect.md`

Binding rule: *"On triggered tasks, the ADR's Alternatives considered
section carries three named alternatives (Minimalist / Scalable /
Creative) with one-paragraph trade-offs per alternative, not a single
recommendation disguised as alternatives."* The existing ADR trigger
list already requires ADRs on the same conditions as the workflow
trigger — they align by design.

#### `software-engineer.md`

Two binding rules:

1. *"On triggered tasks, produce `docs/proposals/<task-id>.md` per
   `proposal-template.md` before writing production code. Code without
   a matching proposal under trigger is a DoR violation."*
2. *"Respond to every Solution Duel finding in the proposal's Duel
   section — either revise the proposal, or record an accepted-risk
   rebuttal with `tech-lead` ratification. Unaddressed findings block
   code start."*

The existing Constraints "Do not silently expand scope" is unaffected.
Output "Diffs with short rationale. No essays." is unchanged —
proposals are a pre-code artifact.

#### `qa-engineer.md`

Binding rule (peer to "Adversarial stance (binding)"): *"Solution Duel
— pre-code adversarial review. On triggered tasks, read the engineer's
proposal and write three failure scenarios ('three ways this fails in
production') into the proposal's Duel section. Post-code Adversarial
stance is unchanged and still fires at diff-review time; the duel is
the same stance applied earlier on the design artifact."* The duel
extends the adversarial posture to an earlier gate.

**Round-limit rule (binding):** each duel is one round — QA writes
findings, engineer rebuts/revises once, then either (a) all findings
addressed → code starts, or (b) any finding disputed → escalate to
`tech-lead`, who decides (ratify engineer, ratify QA, or kick back for
more design work). No back-and-forth past round one without tech-lead
involvement.

## Exit gates / Hard-block conditions

### Hard-blocks

The pipeline produces three hard-block conditions on code start:

1. **Trigger fires and required artifacts are missing.** If the
   task-file `Trigger:` annotation lists any clause and the
   corresponding stage artifacts (`docs/prior-art/<task-id>.md`, the
   ADR Alternatives-considered section, `docs/proposals/<task-id>.md`,
   the proposal's `## Duel` section) do not exist, code MUST NOT start.
   This is the DoR row enforced by the task template.
2. **Duel findings unaddressed.** If the proposal's Duel section
   contains any QA finding with no engineer rebuttal or revision, code
   MUST NOT start. Either the proposal is revised, or the risk is
   accepted with `tech-lead` ratification recorded in the rebuttal.
3. **Escape-hatch invocation unrecorded.** If any pipeline stage is
   skipped or downgraded for a triggered task, the `tech-lead` decision
   and one-line justification MUST appear in the task file. Unrecorded
   skips are a DoR violation flagged by `code-reviewer` audit mode.

### Escape hatches

The pipeline is heavy; heavy ceremony kills trivial work. Documented
exits (all `tech-lead` calls, recorded in the task file;
`code-reviewer` audit mode checks that every escape-hatch use is
recorded):

1. **Sub-trigger tasks.** Trigger returns `none` → pipeline skipped
   entirely. DoR + DoD apply as today. Typical: typo, log-line
   addition, single-function internal refactor, docstring update,
   lint-rule tightening.
2. **Emergency security patch.** Hard Rule #7 path touched under time
   pressure (actively-exploited CVE). `tech-lead` invokes an
   emergency-patch override, records in `CUSTOMER_NOTES.md` with
   timestamp and justification, dispatches `security-engineer` +
   `software-engineer` in parallel without the three-path or duel
   stages. Prior-art + proposal stages are **collapsed** into the patch
   PR description rather than separate files. Post-merge, `architect`
   writes a retroactive ADR within seven days. This is the same shape
   as the existing Hard-Rule-#4 live-approval path.
3. **Single-line fix on a triggered path.** Trigger fires because of
   (3) cross-module or (1) dep-bump, but the actual change is one line.
   `tech-lead` may downgrade to "proposal only, no three-path, no duel"
   with one-line justification in the task file. Auditable post-hoc by
   `qa-engineer`.
4. **Spike / throwaway.** Tasks with Type: Spike in the task template.
   Spikes produce learning, not shipping code — the pipeline is
   optional; whatever was learned is written up in the spike's closure
   note.
5. **Pipeline re-entry not required after a failed revision.** If QA's
   duel forces a rethink that lands in a new task, the new task runs
   its own pipeline; the old task closes as "dropped" or "split." No
   infinite-regression duels.

### Interaction with Hard Rules #2, #4, #7

- **Hard Rule #2:** unchanged. Proposal stage produces the artifact the
  customer reads before signing off; it's upstream of #2, not a
  substitute.
- **Hard Rule #4:** unchanged. Pipeline artifacts inform what the
  customer approves; approval is still live.
- **Hard Rule #7:** trigger clause (5) aligns with this rule's file
  set. On Rule #7 paths, the duel stage's findings pull
  `security-engineer` in as a joint duelist alongside `qa-engineer`,
  not instead of. Binding rule for `security-engineer.md`: *"For Rule
  #7 paths on triggered tasks, participate in the Solution Duel
  alongside `qa-engineer` before code starts; your sign-off per Hard
  Rule #7 is distinct and still required at release time."* No rule
  duplication — duel is design-time; sign-off is release-time.

## References

- Source plan §M4.4 + FR-017 in `specs/006-template-improvement-program/spec.md`
- Proposal rationale and migration history: `docs/proposals/workflow-redesign-v0.12.md` (non-binding — see this file for binding rules)
- Task template DoR row: `docs/templates/task-template.md`
- Prior-art template: `docs/templates/prior-art-template.md`
- Proposal template: `docs/templates/proposal-template.md`
- ADR template (Three-Path Rule in Alternatives considered): `docs/templates/adr-template.md`
- Agent contracts: `.claude/agents/researcher.md`, `.claude/agents/architect.md`, `.claude/agents/software-engineer.md`, `.claude/agents/qa-engineer.md`, `.claude/agents/security-engineer.md`, `.claude/agents/tech-lead.md`
