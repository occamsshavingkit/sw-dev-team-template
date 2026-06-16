# Agent health + respawn contract (binding)

This framework uses standard one-shot subagents: each specialist
is spawned, completes its task, and returns. There are no
persistent named teammates, no addressable agent panel, and no
`SendMessage` channel. Despite the one-shot model, specialists
dispatched on long-running work can still accumulate bad context
within a single long dispatch, or can be re-dispatched on
successive turns with stale prior artifacts. This document
defines what "agent context health" means under that model, how
health is diagnosed, and how a failing dispatch is re-dispatched
without losing work.

## 1. Failure modes (what can go wrong)

- **Context poisoning.** An early mistake embeds; subsequent
  reasoning builds on the bad foundation.
- **Stale facts.** Something true early in the engagement is
  later false; the agent keeps quoting the old fact.
- **Hallucination spiral.** A hallucinated fact becomes "truth"
  in later turns and the agent self-references it.
- **Role drift.** A specialist gives generic non-role advice —
  `architect` writes implementation, `researcher` editorializes,
  `qa-engineer` makes product calls.
- **Correction resistance.** A correction in turn N doesn't
  land; turn N+1 regenerates the same mistake.
- **Token-budget pressure.** Approaching the model's context
  limit degrades performance before outright failure.

## 2. Detection signals

Two tiers. **Any ≥ 3 signals in a single week = trigger the
health check.** Red result = respawn.

### Passive (noticed during routine flow)

1. Specialist contradicts its own earlier verified output
   without new information.
2. References files, versions, or APIs that do not exist or are
   stale relative to the current repo state.
3. Repeats a mistake after an explicit correction — the
   correction did not incorporate.
4. Role drift — specialist giving generic non-role advice.
5. Degraded specificity — answers getting shorter / vaguer
   against the same agent's earlier baseline.
6. Self-flagged confusion — asks for context it demonstrably had
   earlier in the engagement.

### Mechanical (observable without deep reading)

7. `code-reviewer` flags the same class of issue on the same
   agent's work ≥ 3 times across unrelated changes.
8. Token count for a dispatch approaches the model's context limit
   (default threshold: 80 %). This is most relevant for long
   dispatches; it is a signal to split the remaining work and
   re-dispatch rather than continuing into a degraded context.
9. Same question routed to the same agent ≥ 2 times in a
   session without a useful answer.
10. Agent asks for an SME answer that is already recorded in
    `CUSTOMER_NOTES.md` within its own memory window.

### Slot queue and closure protocol (Codex-compatible)

Some Codex harnesses expose a limited number of specialist slots. Treat
"spawning unavailable" and "no slot is free" as different states:

- **Spawning unavailable:** continue only with orchestration or
  non-specialist work, record the limitation, and do not claim specialist
  work occurred. If the customer required agents, or the task needs
  specialist-owned work, stop and ask before proceeding; do not perform
  specialist work locally without a customer-approved one-item exception.
- **No free slot:** queue the specialist brief with canonical role,
  write scope, trigger clauses, expected duration, and required
  `reasoning_effort`. Do not implement the queued work locally
  unless the customer explicitly grants an exception for that item.

When a specialist returns, `tech-lead` reviews the result, verifies any
file changes, records acceptance or retry, and closes the completed
agent promptly. Then dispatch the next queued wave whose inputs are
ready and whose write scope does not overlap with active work. The
Turn Ledger records completed agents closed and queued waves launched.

**Closure is routine (binding).** Closing completed, failed, or
no-longer-needed specialists is routine slot hygiene and does NOT
require additional customer authorization — that authorization was
granted upstream for the dispatch. Customer auth gates DISPATCH, not
CLOSE. Do not close a still-running specialist unless the customer
redirects the work or the work is no longer needed.

**Spawn authorization is not transferable (binding).** Customer
authorization to spawn specialists belongs to the top-level `tech-lead`
session. Specialists receiving a brief do not inherit spawning rights;
they return escalations to `tech-lead`, which owns the native spawn
surface.

### Codex completion/status recovery (binding)

Codex adapter sessions use this state vocabulary for every specialist:

- **Queued:** brief is recorded but no slot has started it.
- **Running:** specialist was dispatched and has not returned durable
  results.
- **Completed:** specialist returned reviewable findings, verified file
  changes, or an explicit completed notification with enough content to
  inspect.
- **Failed:** specialist returned an error, invalid result, role drift,
  or a future-tense / zero-output completion claim.
- **Closed:** `tech-lead` reviewed the result or failure, recorded the
  outcome, and released the slot where the harness permits.
- **Unknown/unreachable:** waits, status calls, or transcript access
  time out or return empty / contradictory status.

`wait_agent` timeout, empty status, or an absent return payload is
**not** completion and is **not** permission for `tech-lead` to do the
specialist work locally. Preserve the issue #100 invariant: a silent
worker leaves specialist work pending, failed, or unknown; it does not
convert the task into top-level implementation.

When a Codex specialist is `unknown/unreachable`, run a direct
status-check ping before respawn if the harness permits. The ping asks
for exactly one of:

- completed findings or changed-file summary;
- stuck-state summary with blocker and last completed step;
- not-started / still-queued confirmation.

The ping must set a bounded response window, normally 60 seconds. After
N timed-out waits or status pings (default N = 2 unless the dispatch
brief set a lower limit), `tech-lead` closes the silent / unknown agent
if possible, records the lost report in the Turn Ledger or
`docs/pm/LESSONS.md`, and re-dispatches the same canonical role with
the prior prompt plus any surviving durable context. If close is not
available, record the harness limitation and re-dispatch only if a slot
is free; otherwise leave the brief queued.

Completion channels can diverge: a harness may emit a completed
notification while `wait_agent` returns empty, or vice versa. Reconcile
conservatively. Accept work only after durable returned content,
verified file changes, or an explicit completed notification that
contains enough findings to review. If channels conflict, classify the
agent as `unknown/unreachable` or `failed` until durable evidence
exists.

If a spawned Codex specialist claims that spawning is unavailable after
the top-level session already received a live agent id or durable
completed payload, classify the result as `failed` role drift. Do not
accept it as a harness limitation. Re-dispatch the same canonical role
with a smaller prompt and an explicit preamble:

> Top-level tech-lead dispatched you. You have already been spawned
> successfully; do not report spawning unavailable. Do not spawn,
> delegate, or contact the customer; return findings, blockers, and
> escalation requests to tech-lead.

### Progress signals for long-running dispatches (non-binding guidance)

Specialists dispatched on tasks estimated to exceed 10 minutes —
`researcher` (surveys, audits), `architect` (decomposition and
ADR drafting), `project-manager` (artifact production),
`qa-engineer` (test-plan drafting), `software-engineer`
(multi-file refactors), `sre` (capacity / DR plan drafting),
`security-engineer` (threat-model / assurance-case drafting) —
SHOULD write intermediate artifacts to disk as work progresses
rather than accumulating everything in context and writing at the
end. File writes serve two purposes: they give `tech-lead`
reviewable evidence of partial work if the dispatch is
interrupted, and they make the "resumable from" field of a
re-dispatch concrete.

The dispatching `tech-lead` should note the expected checkpoint
artifact path in the brief for long tasks. Example brief phrasing:

> "Budget ~45 minutes. Write each completed section to
> `docs/pm/pre-release-gate-log.md` as you go so the task is
> resumable from a partial artifact if the dispatch is
> interrupted."

## 3. Health-check protocol (per agent)

The health check is **ground-truth-based** — it tests whether the
agent's claims match files on disk, not whether the agent "feels"
coherent.

Procedure (orchestrated by `tech-lead`; the `scripts/agent-health.sh`
helper assembles the packet):

1. Generate a **health-check packet** containing:
   - The fixed prompt (see §3.1).
   - The ground-truth snapshot: key facts from
     `CUSTOMER_NOTES.md`, open row count from
     `docs/OPEN_QUESTIONS.md`, the current milestone from
     `docs/pm/CHARTER.md` if present, the last `git log -1`
     summary, the current `TEMPLATE_VERSION`.
   - A grading rubric (see §3.2).
2. Send the prompt to the teammate.
3. Capture the response.
4. Grade:
   - **Green** — every claim cites a file + line, citations
     check out, no contradictions with ground truth.
   - **Yellow** — ≤ 1 unverified claim or mild staleness.
   - **Red** — any contradiction with ground truth, or any
     fabricated citation.
5. Record result in `docs/pm/LESSONS.md` under an
   "Agent-health check" heading with the date and the grade.
6. Red → proceed to §4 (respawn).

### 3.1 Fixed health-check prompt

```
Before continuing your current work, run a self-check. Answer the
following, and for every claim cite the source — file path, and
if applicable section or line. If you cannot cite a source, say
"no source" rather than guessing.

1. Who are you (role), and what is the specific project you are
   working on?
2. What are the three highest-priority open items right now?
3. What is the most recent customer decision recorded in
   CUSTOMER_NOTES.md?
4. What milestone is this project currently in, and what are its
   exit criteria?
5. What is the current TEMPLATE_VERSION of this project?
6. Which agent last handed work off to you, and what was the ask?

Keep each answer to one or two sentences. Citations are required
on every factual claim.
```

### 3.2 Grading rubric

| Criterion | Green | Yellow | Red |
|---|---|---|---|
| Role identification | Correct, cites agent file | Partially correct | Wrong role or no citation |
| Project identification | Matches the charter / repo | Close | Wrong project |
| Open items | Three items, each with a Q-ID | Two with IDs | Items without IDs or contradicting `OPEN_QUESTIONS.md` |
| Last customer decision | Matches latest `CUSTOMER_NOTES.md` entry | Off-by-one entry | Fabricated or no citation |
| Milestone | Matches `docs/pm/CHARTER.md` | Partial match | Wrong or no citation |
| TEMPLATE_VERSION | Matches the file | Slightly stale | Wrong / fabricated |
| Last handoff | Matches recent `OPEN_QUESTIONS.md` / chat flow | Close | No valid source |

The `scripts/agent-health.sh` helper emits the packet including
the ground-truth facts; `tech-lead` scores the response by hand
(or delegates to `code-reviewer` for independent grading — see
§5 for why this matters for tech-lead self-audits).

## 4. Respawn protocol

**Invariant: all durable state survives a respawn.** Durable
state = anything committed to `docs/`, `CUSTOMER_NOTES.md`,
`docs/OPEN_QUESTIONS.md`, `docs/pm/*`, `docs/adr/*`,
`AGENT_NAMES.md`, or the codebase itself. Respawn only resets
the in-memory context window.

### 4.1 Steps

1. **Write the handover brief** at
   `docs/handovers/<role>-<YYYY-MM-DD-HHMM>.md` using
   `docs/templates/handover-template.md`. Every claim cites a
   file + line.
2. **Let the current dispatch end.** One-shot subagents complete
   and return naturally; there is no persistent agent to stop.
   If a dispatch is mid-flight, wait for it to return, then
   treat its partial output as the state to hand over. If the
   harness permits cancellation, cancel; otherwise wait.
3. **Re-dispatch a fresh one-shot specialist** with the same
   canonical role. The spawn prompt = the handover brief plus
   the specific task that needs doing next, plus the paths of
   any surviving partial artifacts from the prior dispatch.
4. **Log the re-dispatch** in `docs/pm/LESSONS.md` (why
   triggered, what the brief said, whether the new instance
   recovered).
5. **Archive the handover brief** after 30 days or at project
   close (whichever is sooner).

### 4.2 Handover brief — required fields

Per `docs/templates/handover-template.md`:

- Teammate name + canonical role.
- Project identifier + charter location.
- Current state of this teammate's work, as of last known-good
  turn. Every claim cites a file + line.
- Open questions assigned to this teammate (`Q-NNNN` IDs from
  `docs/OPEN_QUESTIONS.md`).
- Current blocker, if any.
- Decisions that must NOT be revisited (cite
  `CUSTOMER_NOTES.md`).
- Reason for respawn (cite signal numbers from §2).

## 5. Special case — tech-lead self-diagnosis

`tech-lead` is the sole customer interface and has no peer above
it inside the team. A single-supervisor failure mode would leave
a drifting tech-lead undetected. The template handles this with
three overlapping checks:

### 5.1 Scheduled self-audit

At every milestone-close (when `project-manager` closes a
milestone per `docs/pm/SCHEDULE.md`), `project-manager` triggers
a tech-lead health check. `project-manager` writes the
evaluation itself, since it is the agent with the least routing
overlap with tech-lead.

### 5.2 Peer-audit (triggered)

Any of `architect`, `project-manager`, or `researcher` may
trigger an ad-hoc health check on `tech-lead` if they observe:

- Tech-lead routing the same question to the same specialist
  twice with different instructions.
- Tech-lead citing `CUSTOMER_NOTES.md` content that the peer
  agent cannot find in the file.
- Tech-lead giving the customer a status that contradicts the
  peer agent's view of the same state.

The peer files the trigger as a new `Q-NNNN` row in
`OPEN_QUESTIONS.md` (answerer: `project-manager`).

### 5.3 Customer-audit (backstop)

At every milestone close, `tech-lead` surfaces a "What I
believe is true" summary to the customer:

- Current milestone + exit criteria.
- Open customer-action items.
- Recent customer decisions as tech-lead understands them.

The customer confirms or corrects. This is the ultimate
backstop — the customer **is** tech-lead's supervisor, even
though the template does not model them as a roster agent.
Corrections get recorded in `CUSTOMER_NOTES.md` as a new
entry ("Customer correction to tech-lead state"), not as an
edit to prior entries.

### 5.4 Who respawns tech-lead

If tech-lead's health is red, `project-manager` runs the
respawn — writing the handover brief and orchestrating the
spawn. `tech-lead` does not respawn itself; that would be
chain-of-custody broken.

**Announcement discipline (Fix B, customer ruling 2026-04-20).**
`project-manager` **does not** contact the customer directly.
The "sole human interface" invariant stands without carve-outs.
Instead, the newly-spawned `tech-lead` announces the respawn to
the customer on its **own first turn**, as its first
customer-facing message, using the handover-brief summary that
`project-manager` prepared. The customer therefore hears about
the respawn from the (new) tech-lead — the only agent allowed
to speak to them — rather than from `project-manager`.

The handover brief (see `docs/templates/handover-template.md`)
must include a "First-turn customer message" section that the
replacement tech-lead speaks verbatim (or adapts) as its first
output. Shape:

> *"I am `tech-lead`, respawned on YYYY-MM-DD at HH:MM because
> <reason, citing signal numbers from §2>. The prior instance's
> state has been handed over via `docs/handovers/<file>.md`.
> What I believe is true right now, with citations: <three-bullet
> what-I-believe summary>. Please correct anything that looks
> wrong — customer corrections land in `CUSTOMER_NOTES.md` as
> new entries."*

The customer is never silently handed to a replacement instance.

## 6. Limits

- A green health check does not prove the agent is fully
  correct — only that its cited claims check out against
  files. Agents can be green and still subtly wrong on
  nuance that files do not record.
- The mechanical signal set (§2) is conservative by design.
  Tune it, but do not tune it so loose that passive signals
  alone trigger re-dispatches.
- The "respawn" concept in this contract means re-dispatch: a
  new one-shot spawn with a fresh prompt seeded from the
  handover brief. There is no persistent in-memory context to
  reset; what survives is what is written to disk.
- Very short one-shot dispatches (quick lookups, single-file
  verifications) rarely accumulate context problems within a
  single run. The detection signals in §2 and the health-check
  protocol in §3 are most relevant for dispatches that span
  many tool calls or that are re-dispatched across sessions.
