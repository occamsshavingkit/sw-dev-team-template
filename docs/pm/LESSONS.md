# Lessons Learned — sw-dev-team-template

PMBOK Closing artifact **captured continuously**, not only at closure.
Owned by `project-manager`. A running journal plus a synthesis at
every milestone.

## Journal

### 2026-05-04 — G-9 needs explicit release-note evidence

**Context.** The final checklist needed a durable proof point for rollback
and upgrade guidance.

**Event.** `docs/v1.0.0-release-notes.md` was added and now covers the
upgrade path, rollback targets, rc3 workaround boundary, local agent
supplements, release-audit scope, and GitHub Release handling.

**What went well.** The checklist gate can now point at one concrete
artifact instead of implied release intent.

**What did not.** Other final gates are still open, so the checklist as a
whole remains not final-ready.

**Recommendation.** Keep release-note evidence as a first-class PM record
whenever a final gate depends on operator guidance rather than test output.

**Category.** release governance / PM control.

**References.** `docs/v1.0.0-final-checklist.md`; `docs/v1.0.0-release-notes.md`;
`docs/pm/CHANGES.md` C-9.

### 2026-05-04 — Do not repair historical rc tags in place

**Context.** Post-rc5 release prep still had three final-boundary
items: issue #84 on upgrade-bootstrap history, issue #104 on Codex
dispatch-policy binding, and issue #105 on post-copy manifest
verification.

**Event.** The release docs needed another rc step, but issue #84 could
not be "fixed" by rewriting `v1.0.0-rc3` because public rc tags are
immutable historical records.

**What went well.** The current script behavior and smoke coverage gave
enough evidence to frame rc6 as a focused release-governance candidate
instead of a broad re-triage.

**What did not.** rc5 wording left too much room to read the #84
bootstrap mitigation as if it repaired rc3 in place instead of
documenting the current/future behavior and the one-time workaround for
already-affected trees.

**Contributing factors.** Release notes, roadmap state, and upgrade
evidence all needed to distinguish historical tag immutability from the
live upgrade contract.

**Recommendation.** When a late rc follow-up mixes historical release
history with current script behavior, cut a narrow new rc and document
the immutable old tag plus the supported workaround/evidence path.

**Category.** release governance / versioning.

**References.** GitHub issues #84, #104, #105; `CHANGELOG.md`;
`ROADMAP.md`; `docs/v1.0.0-final-checklist.md`; `docs/pm/CHANGES.md` C-7;
`scripts/lib/manifest.sh`.

### 2026-05-04 — rc6 closes the blocker queue, not final promotion

**Context.** `v1.0.0-rc6` was pushed with the final blocker set
reduced to the remaining release-governance evidence.

**Event.** Issue #79 and issues #84-#105 were closed or downgraded, the
staged-candidate smoke passed 134/134, and the code-reviewer approved
the final staged diff.

**What went well.** The objective gates now separate release evidence
from downstream sample evidence and customer ratification.

**What did not.** Final promotion is still blocked because no downstream
clean-window sample has been recorded and final customer ratification
has not happened.

**Contributing factors.** The rc6 pass resolved the blocker queue, but
G-1, G-4, G-6, G-7, and G-8 intentionally depend on evidence that is not
yet present in the project record.

**Recommendation.** Keep the final checklist evidence-driven: mark only
the gates with direct proof as green, and leave downstream sample and
release-object gates pending until the records exist.

**Category.** release governance / PM control.

**References.** GitHub issues #79, #84-#105; `docs/v1.0.0-final-checklist.md`;
`docs/pm/CHANGES.md` C-8.

### 2026-05-03 — rc validation findings need their own release boundary

**Context.** `v1.0.0-rc4` was tagged as a stabilization candidate after
issues #71 through #83, but downstream rc4 validation then produced
issues #84 through #103.

**Event.** Release prep for `v1.0.0-rc5` found stale final-readiness
language that still treated rc4 validation as the path to final.

**What went well.** The issue range was concrete and mostly clustered
around release governance, Codex parity, local-supplement clarity, and
framework / project boundaries.

**What did not.** Final-readiness wording was too tightly coupled to
the previous rc number, so it needed another pass after the release
boundary moved.

**Contributing factors.** The rc4 plan was both a historical
stabilization record and a live final-readiness reference.

**Recommendation.** When downstream validation opens a new contiguous
rc issue set, update `VERSION`, changelog, roadmap, final checklist,
versioning policy, and PM change records in one release-boundary pass.

**Category.** release governance / process.

**References.** GitHub issues #84-#103; `CHANGELOG.md`;
`ROADMAP.md`; `docs/v1.0.0-final-checklist.md`;
`docs/pm/CHANGES.md` C-6.

### 2026-05-03 — Codex wait status is not completion evidence

**Context.** Codex subagent orchestration can expose multiple completion
channels, including wait calls, status notifications, and returned
payloads.

**Event.** Issue #103 reported that specialist completion or status
reporting can disappear after dispatch.

**What went well.** Existing liveness and queue rules already prohibited
local `tech-lead` implementation when a specialist slot was unavailable.

**What did not.** The contract did not explicitly name
`unknown/unreachable`, so an empty `wait_agent` result could be mistaken
for completion or for permission to absorb specialist work locally.

**Contributing factors.** Harness status channels can diverge, and
timeout semantics are easy to overread without a state vocabulary.

**Recommendation.** Treat timed-out waits and empty status as
`unknown/unreachable`; send one bounded status ping; after repeated
timeouts, close if possible, record the lost report, and re-dispatch the
same role with the prior prompt and surviving context.

**Category.** process / tooling.

**References.** GitHub issue #103; `AGENTS.md`;
`docs/agent-health-contract.md`; `.claude/agents/tech-lead.md`;
`docs/pm/CHANGES.md` C-5.

### 2026-05-03 — Product release audits need artifact-scope first

**Context.** Downstream repositories carry both product release files
and template release / upgrade files.

**Event.** Issue #102 reported that downstream project audits can drift
from product release checks into upstream template or release-file edits.

**What went well.** The issue #99 boundary model already provided the
right split between product, project-filled registers, template upgrade,
and framework maintenance.

**What did not.** Release/version artifacts had an extra ambiguity:
`TEMPLATE_VERSION` is project-filled during scaffold / upgrade flows, but
it is not a product release artifact during ordinary product audits.

**Contributing factors.** Release audits naturally search for version
and stabilization files, and downstream copies include upstream template
release docs and scripts.

**Recommendation.** Require release-engineer audits to state artifact
scope before writing. Product-only audits leave framework release files
unchanged and file upstream gaps through `docs/ISSUE_FILING.md`.

**Category.** process / quality.

**References.** GitHub issue #102; `docs/framework-project-boundary.md`;
`.claude/agents/release-engineer.md`; `docs/pm/CHANGES.md` C-4.

### 2026-05-03 — Framework churn must not hide product review scope

**Context.** Downstream repositories carry the sw-dev team framework in
the same tree as product files.

**Event.** Issue #99 reported that a product review can accidentally
review dirty framework files, producing findings about the team
scaffold instead of the downstream product.

**What went well.** The existing index split and issue-filing convention
already provided pieces of the solution.

**What did not.** There was no single practical boundary model that
reviewers, agents, and commit authors could apply before inspecting a
dirty tree.

**Contributing factors.** Template-managed files, project-filled
registers, and product files are colocated by design, and review tools
often default to "all uncommitted changes."

**Recommendation.** Classify work as product, project-filled register,
template upgrade, or framework maintenance before review. Split product
commits / PRs from template upgrade and framework-maintenance commits.
File framework gaps upstream rather than patching framework files
locally during product work.

**Category.** process / quality.

**References.** GitHub issue #99; `docs/framework-project-boundary.md`;
`docs/ISSUE_FILING.md`; `docs/pm/CHANGES.md` C-3.

### 2026-05-03 — Release-state vocabulary needs one source of truth

**Context.** The rc4 stabilization plan, review record, and roadmap all
described the release candidate from slightly different angles.

**Event.** Review found that `draft`, `reviewed`, `tagged`, and
`final-ready` wording could be read as overlapping states.

**What went well.** The ambiguity was found before the rc4 tag and
before `v1.0.0` final.

**What did not.** The release path did not yet have a durable final
checklist, so "review approved" could be mistaken for "final ready."

**Contributing factors.** The rc4 review was focused on issue closure
and smoke evidence, while PM release-governance artifacts had not yet
been instantiated.

**Recommendation.** Maintain explicit state vocabulary in the roadmap,
active stabilization plan, and final checklist whenever a release
candidate is between review and tagging.

**Category.** process / quality.

**References.** `docs/v1.0-rc4-stabilization.md`,
`docs/audits/v1.0.0-rc4-review.md`,
`docs/v1.0.0-final-checklist.md`, `docs/pm/CHANGES.md` C-2.

### 2026-05-03 — Durable PM records should exist before release close-out

**Context.** The PM templates existed, but project-local `CHANGES.md`,
`LESSONS.md`, and `TOKEN_LEDGER.md` had not yet been instantiated.

**Event.** The rc4 governance review required durable evidence records
for scope change, lessons, and token-budget status.

**What went well.** The templates were adequate and could be copied
into project-local records with minimal project-specific adaptation.

**What did not.** Absence of the durable records meant release
governance evidence had to be reconstructed from other docs.

**Contributing factors.** The template treats `TOKEN_LEDGER.md` as
"create on first use," and earlier release work focused on functional
smoke evidence over PMBOK record completeness.

**Recommendation.** At the first release-candidate planning milestone,
instantiate the core PM records even if some rows are explicit
initial-state entries.

**Category.** process / tooling.

**References.** `docs/pm/CHANGES.md`, `docs/pm/TOKEN_LEDGER.md`,
`docs/v1.0.0-final-checklist.md` G-10.

## M0 baseline (2026-05-13)

- `scripts/baseline-token-economy.sh` lines 250–259 carry dead `awk_extract` commented-out gawk approach; safe to remove in a Phase 3 cleanup pass. (non-blocking, deferred)
- `baseline-token-economy.sh` invocation expects `BASELINE_DOWNSTREAM_ROOTS` paths relative to the sub-repo's cwd; document canonical invocation (`BASELINE_DOWNSTREAM_ROOTS="../../QuackDCS:../../QuackPLC:../../QuackS7:../../QuackSim"`) at top of script for reproducibility. (non-blocking, deferred)
- Live-register row count includes header rows (off-by-one over data rows); consistent and deterministic, do not change mid-program. (non-blocking, deferred)

## M1.1 evidence (2026-05-13)

- code-reviewer canonical contract reached only 1.5% runtime reduction vs M0 (520 vs 528 words); SC-002 "where safe" clause invoked because the M0 contract was already among the leanest in the roster and had no extractable rationale to absorb into a manual without deleting normative review-gate content. Non-blocking; recorded for future-program reference if SC-002 thresholds tighten. See `docs/pm/token-economy-baseline.md` §M1.1 token-reduction evidence (post-T013).
- M1 close: G1 first-audit BLOCK on researcher canonical_sha staleness (compiler reads HEAD blob SHA, not working-tree; a post-canonical-edit re-compile is required). Fix landed at commit `5f96450`. Recommend CI guard at M6 or M7 that fails when `git hash-object .claude/agents/<role>.md != canonical_sha` in `docs/runtime/agents/<role>.md`. (non-blocking, deferred)

## Milestone syntheses

### 2026-05-03 — v1.0.0-rc4 governance pass

- Top 3 things that worked: downstream issue evidence (#71-#83)
  produced a concrete stabilization queue; specialist review evidence
  was already captured in `docs/audits/v1.0.0-rc4-review.md`; PM
  templates were ready to instantiate.
- Top 3 things to fix: release-state vocabulary needed normalization;
  final-readiness gates needed an objective checklist; PM durable
  records needed to exist before final close-out.
- Changes made to process / templates / roster as a result:
  `docs/v1.0.0-final-checklist.md` added; rc4 plan / review / roadmap
  normalized; `docs/pm/CHANGES.md`, `docs/pm/LESSONS.md`, and
  `docs/pm/TOKEN_LEDGER.md` created. Cross-reference:
  `docs/pm/CHANGES.md` C-2.

Sustainability review: no direct sustainability impact identified for
the rc4 governance documentation change.

Agent-health check: not run in this PM documentation pass; next
milestone-close check should run `scripts/agent-health.sh tech-lead`
per `.claude/agents/project-manager.md`.

## Final synthesis

`v1.0.0` remains pending. rc6 cleared the final blocker queue, but the
downstream clean-window sample, customer ratification, and GitHub Release
object are still open.

## M3.4 question-lint dry-run (2026-05-13)

Ran `scripts/lint-questions.sh --summary` (FR-012, warning-only mode;
`HARDGATE_AFTER_SHA=DEFERRED_SET_AT_HARDGATE_PR`) against the default
file set on branch `feat/m1-token-quick-wins`.

Output:

```
docs/templates/scoping-questions-template.md:11: pattern-2-multi-numbered: "   and what counts as "done" for the first milestone?"
.claude/agents/tech-lead.md:68: pattern-2-multi-numbered: "2. **Is it atomic?** One decision axis only. Compound asks queue internally in `docs/OPEN_QUESTIONS.md`."
docs/runtime/agents/tech-lead.md:45: pattern-2-multi-numbered: "2. **Is it atomic?** One decision axis only. Compound asks queue internally in `docs/OPEN_QUESTIONS.md`."
lint-questions: WARN 3 violation(s); hard-gate not yet active (HARDGATE_AFTER_SHA=DEFERRED_SET_AT_HARDGATE_PR)
lint-questions: 3 warnings, 0 errors
```

Per-line classification:

- `docs/templates/scoping-questions-template.md:11` — **false positive**.
  The template is the Step-2 scoping queue; items `0.`, `1.`, `2.`, `3.`,
  ... are *independent* customer questions to be asked one per turn (the
  file header explicitly says "ask them one per turn"). The regex flags
  adjacent numbered items as a compound, but they are a queue of atomic
  questions, not a multi-numbered compound ask.
- `.claude/agents/tech-lead.md:68` — **false positive**. Line is item `2.`
  of the Customer Question Gate's four-check enumeration (`1.` ... `4.`).
  This is a procedural checklist that gates customer-facing questions; it
  is not itself a question asked of the customer.
- `docs/runtime/agents/tech-lead.md:45` — **false positive**. Compiled
  runtime mirror of the same Customer Question Gate enumeration in
  `.claude/agents/tech-lead.md:68`. Same classification, downstream of the
  same source.

Recommendation for the next iteration of `scripts/lint-questions.sh`
(future refinement task, not in scope for T040): tighten pattern-2 so it
does not fire on numbered-bullet lists that (a) sit under a heading whose
purpose is a procedural checklist or a queue of atomic items, or (b) do
not contain a `?` within the matched item, or (c) appear in
`docs/templates/scoping-questions-template.md` and the runtime/source
pair of `tech-lead.md` Customer Question Gate. Pre-existing
`tech-lead.md:68` and its `docs/runtime/agents/tech-lead.md:45` mirror
should not fire after the refinement.

Hard-gate cutover (per spec clarification 13 and FR-012) lands at the
next MINOR-boundary Release. Any warnings still firing at that cutover
MUST be either (a) legitimate and fixed in source, or (b) grandfathered
by setting `HARDGATE_AFTER_SHA` to a SHA prior to the offending row so
the lint script treats pre-cutoff occurrences as warnings while erroring
on new ones. The three current warnings are all false positives and
should be resolved by pattern refinement before the cutover; no
grandfathering needed if the regex is tightened first.

## M2.3 researcher SC-002 exception (2026-05-13)

T034 added the FR-009 memory-first-lookup patterns to
`.claude/agents/researcher.md`. The four canonical patterns are binding
governance and cannot be elided. Effect on the runtime contract:

| Measure | M0 baseline | Post-M1.1 (G1) | Post-T034 (G3) |
|---|---:|---:|---:|
| Runtime words | 1996 | 1590 | 1653 |
| Reduction vs M0 | — | 20.3% | **17.2%** |

**SC-002 floor for researcher**: 1597 words (20.0% reduction).
**Breach**: 1653 - 1597 = 56 words over the floor (1.8 percentage
points below the threshold).

**Justification under SC-002 "any exception is justified and recorded"**:
The +63-word delta is the FR-009 memory-first-lookup binding text. The
four query patterns are normative (binding governance — `CLAUDE.md` §
Escalation protocol step 1 references the same patterns; reducing them
below information-completeness would lose the verbatim invariants that
make memory pointer-only). Trimmed as far as possible (33 words for
patterns + 30 words for pointer-only and repo-wins-on-conflict
invariants); further trim would lose the verbatim rule.

**Deferral plan**:
- Future trim candidate (non-binding rationale): the pronoun-verification
  block at canonical lines 129-158, currently retained for the
  customer-naming Step 3 in `docs/FIRST_ACTIONS.md`. If a future
  milestone moves naming rationale into a manual companion (similar to
  M1.1's rationale absorption pattern), the +56-word delta would be
  recovered comfortably.
- Considered at G3 close (2026-05-13); not actioned, deferred to a
  Phase-3+ pass.

This is the binding "justified and recorded" entry for the SC-002
researcher exception. The exception is acknowledged and acceptable
under the "where safe" clause of SC-002. (non-blocking, deferred)

## M3.5 follow-up — scoping-questions-template (2026-05-13)

G2+G3 audit observation OBS-G3-1: T035 atomicized
`docs/FIRST_ACTIONS.md` seed questions but did not touch the canonical
binding seed queue at `docs/templates/scoping-questions-template.md`,
which contains the original compound forms that FR-010 was designed to
prevent. The lint correctly flagged
`docs/templates/scoping-questions-template.md:11` as
`pattern-2-multi-numbered`; classification was previously "false
positive" but on re-reading in context it is a genuine compound seed
question split across numbered rows.

**Recommendation**: open an issue for a follow-up task to atomize
`scoping-questions-template.md` seed entries, matching the
decomposition pattern used in `FIRST_ACTIONS.md` (one decision axis per
row, atomic-gate preamble at the top). Update FR-010 acceptance scope
to explicitly include `scoping-questions-template.md` if the template
shape persists. (non-blocking, deferred — does not block G3 close
because the lint surface is warning-only and the template won't ship
into a fresh project until M8 retrofit triggers it.)

## M3 close (2026-05-13)

- G3 first-audit BLOCK on a missing durable record of SC-002 researcher exception (commit message ≠ LESSONS entry; spec § SC-002 requires "any exception is justified and recorded"). Fix landed at commit `a37165c`. Recommend at M6 or M7 a CI guard that fails when a commit message claims an SC exception but `docs/pm/LESSONS.md` doesn't have a matching `## <SC-id> exception (date)` heading. (non-blocking, deferred)
- Pattern continues from M1 close: canonical_sha staleness across canonical-edit → runtime-recompile cycles. Two-commit dance is fragile but worked. Same CI guard recommendation as in M1 close LESSONS still applies.

## M4 close (2026-05-13)

- G4 passed first-try (no rework cycle). M4 was doc-only, so the canonical_sha staleness pattern from M1/M3 close-outs still required a two-commit dance (canonical at `cc44c8d` + runtime re-stamp at `4a44cdd`), but no SC/Constitution defects surfaced.
- T047 moved workflow-pipeline binding rules from `docs/proposals/workflow-redesign-v0.12.md` to `docs/workflow-pipeline.md`. The proposal doc retains historical/rationale content and now carries a non-binding status banner — the canonical/non-binding split is the pattern future binding-rule extractions should follow.
- T048 cross-link redirect: 10 canonical files updated; remaining 4 references (canonical pointer, the proposal itself, runtime contracts, CHANGELOG) are expected and intentional. Documentation Authority Policy (T044) explicitly permits the canonical-pointer + historical-reference pattern. (non-blocking, deferred)

## M5 close (2026-05-13)

- G5 passed first-try (no rework cycle). M5 was substantial: ADR-0009 + model-routing extensions + log-fallback.sh + compiler adapter-generation + --verify mode. No SC regressions.
- **OBS-G5-1 — incomplete canonicals**: `onboarding-auditor` (missing escalation + output_format), `process-auditor` (missing hard_rules + escalation + output_format), `project-manager` (missing output_format), `sre` (missing hard_rules). Compiler's skip-incomplete behavior (with `--strict` flag for CI) means these get adapters but not runtime contracts. Recommend section additions at M6 (when `lint-agent-contracts.sh` hard-gates) or by M9 release readiness; otherwise these 4 agents ship without compact runtime contracts. (non-blocking, deferred)
- **OBS-G5-2 — duplicate routing tables**: `docs/model-routing-guidelines.md` carries both the older `## Role defaults` tier table (fast/standard/strong/frontier vocabulary) and the new T052 `## Binding per-agent default-class table` (binding-schema-enum vocabulary). Two overlapping per-agent tables in one binding doc invite drift. Reconciliation: collapse to one table or formalize the two-system layering in a follow-up. (non-blocking, deferred)
- **OBS-G5-3 — fallback-log.jsonl contract**: `scripts/log-fallback.sh` creates `docs/pm/fallback-log.jsonl` on first event. No file exists pre-event; this is intended steady-state. Consider documenting the create-on-first-write contract in `docs/pm/README.md` (or whichever PM index exists) or seeding an empty `fallback-log.jsonl` at scaffold time so the path is greppable from session start. (non-blocking, deferred)
- The canonical_sha staleness pattern from M1/M3/M4 close-outs DID NOT recur at M5 close because M5 didn't edit any `.claude/agents/<role>.md` canonical file. Confirms the pattern: the staleness only fires when M-x edits canonical AND M-x's commit includes the runtime contracts; the two-commit dance is required only when canonical changes. M5 modified only the routing-guidelines doc + the compiler script + new schema/log scripts; runtime contracts regenerated cleanly because canonical SHAs at HEAD matched.

## M6 close (2026-05-13)

- G6 passed first-try (single trailing audit observation: 4 adapter SHAs lagged the canonical commit by one cycle; closed at `c243aa0` before SCHEDULE flip). The two-commit dance pattern from earlier milestones held at M6 close.
- M5 OBS-G5-1 (4 incomplete canonicals — onboarding-auditor, process-auditor, project-manager, sre — missing schema-required sections) is CLOSED at M6. Pre-T060 work added the missing `## Hard rules` / `## Escalation` / `## Output format` sections sourced from existing canonical prose + CLAUDE.md hard-rule citations + spec clarification 14 (advisory roles). 4 new compact runtime contracts generated cleanly.
- T059 schema activation surfaced a real defect: generated-artifact.schema.json's `additionalProperties: false` was incompatible with the compiler's `description: <text>` frontmatter emission. Fixed by adding `description` as an optional string property in the schema (both spec and sub-repo copies). Pattern lesson: **schema activation is a behavioral check** — schemas should be authored under `additionalProperties: false` and EVERY field the compiler emits must be enumerated. A future M9 release-readiness check should run schema validation against every newly-generated artifact.
- Real-LLM prompt regression remains stubbed at G6 per T011 design. The structural SC-013 pass is what G6 audits; behavioral pass requires actual LLM invocation (Phase-3+). The stub harness's value: it catches fixture-validation bugs and missing-compiled-contract gaps; it does not catch behavioral regressions in the agents themselves. Recommend Phase-3+ task to wire the harness to real LLM execution against canonical AND compiled contracts; results would augment LESSONS as the agents drift over time.
- canonical_sha staleness pattern recurred at M6 (4 new runtime contracts post-canonical-edit) AND for 4 OpenCode adapters (audit T064 caught these mid-audit). The two-commit dance (canonical + scripts in one commit; runtime+adapter regeneration in the next) remains the manual workaround. The CI guard idea from M1/M3 close LESSONS now applies to BOTH runtime contracts AND adapters; recommend the guard check `git hash-object` against the canonical_sha frontmatter for EVERY file under `docs/runtime/agents/` AND `.opencode/agents/`.
