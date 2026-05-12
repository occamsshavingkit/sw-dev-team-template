# Research: M2 Token Operating Model

## Decision: Scope M2 as a template-maintenance slice only

**Rationale**: The accepted clarification limits M2 to canonical docs/templates: `docs/templates/task-template.md`, project-manager guidance, `docs/MEMORY_POLICY.md`, `.claude/agents/tech-lead.md`, `.claude/agents/researcher.md`, and the AGENTS.md Spec Kit plan-pointer block. This keeps the work reviewable and avoids mixing operating-model guidance with later milestone implementation.

**Alternatives considered**: Updating generated runtime candidates from M0/M1 was rejected because they are out of scope unless a later planning step explicitly chooses synchronization. Pulling in M3-M9 was rejected because those milestones remain future gates.

## Decision: Use five token budget bands in the task template

**Rationale**: The source M2 plan defines `tiny`, `small`, `medium`, `large`, and `XL` with intended-use guidance. These bands are coarse enough for planning and review without pretending to provide exact token accounting.

**Alternatives considered**: Exact token estimates were rejected because M2 needs planning signals, not precise metering. Fewer bands were rejected because they would hide the important distinction between focused tasks, multi-specialist work, triggered workflows, and oversized work.

## Decision: Treat XL tasks as split candidates by default

**Rationale**: The spec requires XL work to be split or explicitly accepted as oversized. This makes high-context work visible before execution and prevents accidental single-task context blowups.

**Alternatives considered**: Allowing XL without review was rejected because it weakens the token operating model. Prohibiting XL entirely was rejected because some exceptional tasks may be intentionally accepted after review.

## Decision: Require a just-in-time file list before context expansion

**Rationale**: A focused first-read list gives assignees a bounded start point and supports the constitution's token/context economy principle. It also gives reviewers a concrete way to detect tasks that start with broad rereads.

**Alternatives considered**: Letting assignees discover files ad hoc was rejected because it makes context cost invisible. Requiring exhaustive file lists was rejected because M2 should guide first reads, not predict every file eventually touched.

## Decision: Capture token actuals at material task closure

**Rationale**: Closure actuals, or an explicit note that an actual was not captured, allow future calibration of the budget bands and make token cost visible in review.

**Alternatives considered**: Capturing actuals only for large tasks was rejected because calibration needs routine examples. Leaving blanks for non-material work was rejected because blank fields are ambiguous.

## Decision: Define PM refresh as a delta pass

**Rationale**: M2 requires PM cadence to prefer changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas before rereading all PM artifacts. The output is either a no-op confirmation or minimal edits to affected PM registers.

**Alternatives considered**: Full PM artifact rereads were rejected as recurring context sinks. Fully automated register updates were rejected because M2 only defines operating guidance and preserves PM judgment.

## Decision: Allow targeted PM fallback reads when deltas are insufficient

**Rationale**: Delta inputs can be stale, incomplete, or conflicting. A targeted fallback to affected files preserves correctness while avoiding default broad rereads.

**Alternatives considered**: Never falling back was rejected because PM registers must remain accurate. Falling back to a full reread by default was rejected because it contradicts the M2 objective.

## Decision: Make memory use prescriptive but pointer-only

**Rationale**: M2 requires concrete query patterns before broad reads of old customer notes, old schedules, customer escalation or prior-answer history, and reopened ADR topics. Memory may reduce old-context reads, but repository artifacts remain authoritative.

**Alternatives considered**: Keeping memory guidance optional was rejected because agents need predictable memory-first behavior. Treating memory as source of truth was rejected because it would violate canonical source authority.

## Decision: Skip contracts for M2

**Rationale**: M2 updates internal framework guidance only. It exposes no external API, CLI command, service, package interface, database schema, user-facing integration, or protocol.

**Alternatives considered**: Creating placeholder contracts was rejected because it would add non-authoritative surface area. Defining future adapter or compiler contracts was rejected because those are later milestone concerns.

## Decision: Update `AGENTS.md` only as a thin Spec Kit plan pointer

**Rationale**: The requested agent-context update is limited to the text between `<!-- SPECKIT START -->` and `<!-- SPECKIT END -->` in `AGENTS.md`, pointing to this M2 plan. This keeps the live entrypoint small and avoids duplicating planning content.

**Alternatives considered**: Copying plan excerpts into `AGENTS.md` was rejected because it increases recurring context cost. Updating unrelated adapter or runtime files was rejected because the requested write scope only allows the Spec Kit block in `AGENTS.md`.
