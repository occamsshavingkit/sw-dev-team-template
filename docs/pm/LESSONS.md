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
