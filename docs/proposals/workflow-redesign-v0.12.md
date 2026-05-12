# Memo: Workflow redesign for v0.12.0 — composing #32 / #33 / #34 / #35

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

The four proposals are not parallel; they form a dependency chain on
a single deliverable path. Proposed stage order:

| # | Stage | Owner | Input | Output artifact | Consumed by |
|---|---|---|---|---|---|
| 1 | Prior-art scan (#34) | `researcher` | task brief | `docs/prior-art/<task-id>.md` | stages 2, 3 |
| 2 | Three-path design (#33) | `architect` | task brief + prior-art | ADR §Alternatives considered (three alternatives) | stage 3 |
| 3 | Engineer proposal (#32) | `software-engineer` | chosen path + prior-art | `docs/proposals/<task-id>.md` | stage 4 |
| 4 | Solution duel (#35) | `qa-engineer` → `software-engineer` revision | proposal | duel annex appended to `docs/proposals/<task-id>.md` | stage 5 |
| 5 | Code | `software-engineer` | revised proposal | diff + tests | existing review + merge flow |

**Feed relationships.**

- Prior-art feeds both the architect (so alternatives aren't
  reinvented) and the engineer (so implementation picks the right
  library/API signatures). Writing it once, consuming it twice is
  the reason it goes first.
- Three-path is **upstream of** proposal, not parallel. The
  engineer's proposal is the chosen path made concrete. If the
  three-path step is skipped (see §2 trigger), the engineer's
  proposal stands alone; if kept, the proposal cites which of
  M/S/C it implements and why.
- The duel is a **revision loop on stage 3's artifact**, not a
  separate document class. QA's "three ways this fails in
  production" attaches as an annex to the proposal; engineer
  either revises the proposal in-place or rebuts each finding
  in-annex. This matters for retention and for not creating a
  fifth artifact.
- Code does not start until the duel annex is closed (either all
  findings addressed or explicitly accepted-as-risk by
  `tech-lead`).

This is a pipeline, not a gate: each stage's artifact is the next
stage's required input. Skipping mid-pipeline (e.g., "prior-art
says nothing new, go straight to code") is allowed only via the
escape hatches in §7.

## 2. Trigger threshold (mechanical, not judgment)

Each issue's triage hint asks whether the rule fires every task or
only "non-trivial" ones. A judgment threshold ("only for non-trivial
tasks") is gameable and inconsistent across agents. Recommendation:
**any OR-clause triggers the full pipeline.** All conditions are
mechanically checkable from the task file, the diff plan, or the
routing table:

**Trigger = true if any of:**

1. **New external dependency.** Task adds or upgrades any
   library/framework not previously in the project's dependency
   manifest. (Pure transitive-pin bumps don't count; direct-
   dependency adds do.) This is `architect.md` ADR trigger #2 and
   the single strongest hallucination signal for #34.
2. **Public-API change.** Task modifies any exported symbol
   (function, type, endpoint, CLI flag, config key) that is named
   in `docs/requirements.md`, an ADR, or a public interface doc.
   Detected by comparing the proposed diff's changed-symbol set
   against `grep -l` of those files.
3. **Cross-module boundary crossed.** Task's file set spans two or
   more top-level source modules/packages as defined in the
   project's architecture doc. Single-module changes don't
   trigger.
4. **Safety-critical or Hard-Rule-#4 path touched.** Any file
   flagged safety-critical in `CUSTOMER_NOTES.md` or by an ADR.
5. **Hard-Rule-#7 path touched.** Any file in auth / authz /
   secrets / PII / network-exposed surface as enumerated for
   `security-engineer`.
6. **Data model change.** Schema, serialization format,
   persistence swap (matches ADR trigger #3).

**Trigger = false** (pipeline skipped) if none of (1)–(6) holds.
Typical below-threshold work: typo fix, single-function internal
refactor, adding a log line, updating a docstring, tightening a
lint rule.

**Why OR-set rather than a single metric.** File-count alone (e.g.,
"≥5 files") is the wrong proxy: a one-line auth change is more
consequential than a ten-file rename. Each of (1)–(6) is already an
independent ADR or Hard-Rule trigger elsewhere in the template;
reusing those definitions means the workflow threshold drifts in
lockstep with the gates it sits next to.

**Who decides trigger status.** `tech-lead`, at task dispatch time,
writes a single-line trigger annotation into the task file:
`Trigger: <list of clauses that fire, or "none">`. Annotation is
mechanically auditable post-hoc by `qa-engineer` at milestone close
(new DoD row in task template — see §6).

## 3. Integration with existing gates (no duplication)

The new pipeline slots **between DoR and code**, not in parallel
with existing gates. Concretely:

- **Task template DoR** stays as-is. A new DoR row is added: *"If
  trigger fires (see §2), required pipeline artifacts (prior-art /
  design-options / proposal) exist and are linked from this task."*
- **`architect` ADR trigger list** overlaps heavily with the §2
  trigger. Rather than duplicate, **the three-path artifact for a
  task under §2 trigger is the ADR body's "Alternatives considered"
  section** — the architect writes one ADR that incorporates the
  three-path options, rather than writing an ADR and a separate
  design-options doc. This collapses #33's new artifact into the
  existing ADR stream.
- **`qa-engineer` adversarial stance** is *attitude at diff-review
  time.* #35's Solution Duel is *attitude at proposal-review
  time.* They compose: same adversarial posture, applied earlier.
  The qa-engineer agent file gains a new job item; the stance text
  stays put.
- **`code-reviewer` two modes** are unchanged. Review mode still
  fires at diff time. The duel does not replace review — it
  catches design-level fails earlier; review still catches
  implementation-level fails.
- **Hard Rules #2, #4, #7** are unchanged. The pipeline produces
  artifacts that *feed* the customer and security-engineer
  sign-offs those rules require; it does not substitute for them.
  See §9 for interaction detail.
- **`docs/templates/pm/CHANGES.md`** is unchanged. Scope changes
  discovered during prior-art (stage 1) or duel (stage 4) still
  route through CHANGES.md.

**No new gate file.** The pipeline is DoR-resident; the task
template's DoR row is the single enforcement point.

## 4. Artifact catalogue

Four new (or one new + three existing-reuses) artifact classes:

### 4.1 Prior-art scan (#34)

- **Path:** `docs/prior-art/<task-id>.md`
- **Template:** new `docs/templates/prior-art-template.md` —
  sections: Task reference / Search scope (which standards + vendor
  docs + canonical libraries queried) / Canonical solution found
  (or "none") / Candidate libraries + versions + license / Known
  pitfalls / Citations (Tier-1/2/3 per `researcher.md`).
- **Owner:** `researcher`.
- **Consumers:** `architect` (stage 2), `software-engineer` (stages
  3 and 5).
- **Retention:** **durable**. Git-tracked. Small (one page
  typical), high reuse value on follow-up tasks, and it's the
  audit trail for "why we picked library X." Stored under
  `docs/prior-art/` permanently; archived via `researcher`'s
  archival rule only when the covered feature is removed.

### 4.2 Three-path design options (#33, collapsed into ADR)

- **Path:** no new file. The three alternatives land in the ADR's
  **Alternatives considered** section. ADR path remains
  `docs/adr/ADR-NNN-<slug>.md`.
- **Template:** existing `docs/templates/architecture-template.md`
  ADR shape; recommendation is to expand that template's
  "Alternatives considered" guidance to require **three**
  alternatives labeled Minimalist / Scalable / Creative, with
  one-paragraph trade-off per alternative.
- **Owner:** `architect`.
- **Consumers:** `software-engineer` (stage 3), `code-reviewer`
  (audit mode — checks that the shipped code matches the chosen
  path).
- **Retention:** **durable** (ADRs are already durable).

### 4.3 Engineer proposal (#32)

- **Path:** `docs/proposals/<task-id>.md`
- **Template:** new `docs/templates/proposal-template.md` —
  sections: Task reference / Chosen ADR path (M/S/C) /
  Implementation sketch (pseudocode or interface-level, not
  production code) / Dependencies touched / Test plan outline /
  Risks + mitigations / Open questions.
- **Owner:** `software-engineer`.
- **Consumers:** `qa-engineer` (stage 4 duel), `code-reviewer`
  (audit mode reference).
- **Retention:** **durable for non-trivial; transient below
  threshold.** Proposals for tasks that triggered §2 stay in the
  repo as the design-intent record the code is measured against.
  If the customer prefers slimming, a post-merge archival pass can
  move proposals to `docs/proposals/ARCHIVE/` after the next
  milestone close.

### 4.4 Solution duel annex (#35)

- **Path:** appended to `docs/proposals/<task-id>.md` as a fenced
  `## Duel` section. Not a separate file.
- **Template:** `docs/templates/proposal-template.md` ships a
  `## Duel` section with two subsections: *Findings* (QA lists
  three ways-to-fail) and *Rebuttals / revisions* (engineer
  responds per-finding — either proposal revised, or risk accepted
  with justification and tech-lead ratification).
- **Owner:** jointly stewarded — `qa-engineer` writes Findings;
  `software-engineer` writes Rebuttals.
- **Consumers:** `tech-lead` (for ratification if any finding is
  disputed), `code-reviewer` (audit reference).
- **Retention:** travels with the proposal — same policy.

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

### `researcher.md`

New binding rule: *"Prior-art artifact on triggered tasks. When
`tech-lead` dispatches a task annotated with any §2 trigger clause,
produce `docs/prior-art/<task-id>.md` per `prior-art-template.md`
before the architect or engineer is dispatched to downstream
stages."* **No conflict** — this makes §Job #5 ("Prior-art scans")
concrete rather than ambient.

### `architect.md`

New binding rule: *"On triggered tasks, the ADR's Alternatives
considered section carries three named alternatives (Minimalist /
Scalable / Creative) with one-paragraph trade-offs per alternative,
not a single recommendation disguised as alternatives."*
**Conflict check:** existing ADR trigger list already requires ADRs
on the same conditions as §2 — good, they align.

### `software-engineer.md`

Two new binding rules:

1. *"On triggered tasks, produce `docs/proposals/<task-id>.md` per
   `proposal-template.md` before writing production code. Code
   without a matching proposal under trigger is a DoR violation."*
2. *"Respond to every Solution Duel finding in the proposal's Duel
   section — either revise the proposal, or record an
   accepted-risk rebuttal with `tech-lead` ratification.
   Unaddressed findings block code start."*

**Conflict check:** existing Constraints "Do not silently expand
scope" is unaffected. Output "Diffs with short rationale. No
essays." is unchanged — proposals are a pre-code artifact.

### `qa-engineer.md`

New binding rule (peer to "Adversarial stance (binding)"):
*"Solution Duel — pre-code adversarial review. On triggered tasks,
read the engineer's proposal and write three failure scenarios
('three ways this fails in production') into the proposal's Duel
section. Post-code Adversarial stance is unchanged and still fires
at diff-review time; the duel is the same stance applied earlier on
the design artifact."* **No conflict** — the duel extends the
adversarial posture to an earlier gate.

**Round-limit rule (new):** each duel is one round — QA writes
findings, engineer rebuts/revises once, then either (a) all
findings addressed → code starts, or (b) any finding disputed →
escalate to `tech-lead`, who decides (ratify engineer, ratify QA,
or kick back for more design work). No back-and-forth past round
one without tech-lead involvement. See §9.

## 7. Escape hatches

The pipeline is heavy; heavy ceremony kills trivial work. Documented
exits:

1. **Sub-trigger tasks.** §2 trigger returns `none` → pipeline
   skipped entirely. DoR + DoD apply as today. Typical: typo,
   log-line addition, single-function internal refactor, docstring
   update, lint-rule tightening.
2. **Emergency security patch.** Hard Rule #7 path touched under
   time pressure (actively-exploited CVE). `tech-lead` invokes an
   emergency-patch override, records in `CUSTOMER_NOTES.md` with
   timestamp and justification, dispatches `security-engineer` +
   `software-engineer` in parallel without the three-path or duel
   stages. Prior-art + proposal stages are **collapsed** into the
   patch PR description rather than separate files. Post-merge,
   `architect` writes a retroactive ADR within seven days. This is
   the same shape as the existing Hard-Rule-#4 live-approval path.
3. **Single-line fix on a triggered path.** Trigger fires because
   of (3) cross-module or (1) dep-bump, but the actual change is
   one line. `tech-lead` may downgrade to "proposal only, no
   three-path, no duel" with one-line justification in the task
   file. Auditable post-hoc by `qa-engineer`.
4. **Spike / throwaway.** Tasks with Type: Spike in the task
   template. Spikes produce learning, not shipping code — the
   pipeline is optional; whatever was learned is written up in the
   spike's closure note.
5. **Pipeline re-entry not required after a failed revision.** If
   QA's duel forces a rethink that lands in a new task, the new
   task runs its own pipeline; the old task closes as "dropped"
   or "split." No infinite-regression duels.

Escape hatches are always `tech-lead` calls, recorded in the task
file. `code-reviewer` audit mode checks that every escape-hatch use
is recorded.

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

- **Hard Rule #2:** unchanged. Proposal stage produces the
  artifact the customer reads before signing off; it's upstream of
  #2, not a substitute.
- **Hard Rule #4:** unchanged. Pipeline artifacts inform what the
  customer approves; approval is still live.
- **Hard Rule #7:** §2 trigger clause (5) aligns with this rule's
  file set. On Rule #7 paths, the duel stage's findings should
  pull `security-engineer` in as a joint duelist alongside
  `qa-engineer`, not instead of. Recommend one added sentence to
  `security-engineer.md`: *"For Rule #7 paths on triggered tasks,
  participate in the Solution Duel alongside `qa-engineer` before
  code starts; your sign-off per Hard Rule #7 is distinct and
  still required at release time."* No rule duplication — duel is
  design-time; sign-off is release-time.

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
