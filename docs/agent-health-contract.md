# Agent health + respawn contract (binding)

Long-lived named teammates (via the experimental agent-teams
feature) accumulate failure modes that single-turn agents never
see. This document defines what "agent context health" means for
this template, how health is diagnosed, and how an unhealthy
agent is respawned without losing work.

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
8. Token count for the named teammate approaches the model's
   context limit (default threshold: 80 %).
9. Same question routed to the same agent ≥ 2 times in a
   session without a useful answer.
10. Agent asks for an SME answer that is already recorded in
    `CUSTOMER_NOTES.md` within its own memory window.

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
   `docs/handovers/<teammate-name>-<YYYY-MM-DD-HHMM>.md` using
   `docs/templates/handover-template.md`. Every claim cites a
   file + line.
2. **Stop the current teammate:** preferred via
   `SendMessage({to: <name>, …}) …stop…`; fallback, let the
   turn end and the teammate expire.
3. **Spawn a fresh teammate** with identical `name` and
   `subagent_type`. The spawn prompt = the handover brief plus
   the specific task that needs doing next.
4. **Agent-teams panel continuity:** the slot stays; the human
   sees no name change.
5. **Log the respawn** in `docs/pm/LESSONS.md` (why triggered,
   what the brief said, whether the new instance recovered).
6. **Archive the handover brief** after 30 days or at project
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

`project-manager` informs the customer of the respawn at the
next interaction. The customer is never silently handed to a
replacement instance.

## 6. Limits

- A green health check does not prove the agent is fully
  correct — only that its cited claims check out against
  files. Agents can be green and still subtly wrong on
  nuance that files do not record.
- The mechanical signal set (§2) is conservative by design.
  Tune it, but do not tune it so loose that passive signals
  alone trigger respawns.
- This contract does not cover single-turn agents or
  one-shot helpers. They have no persistent context to go
  bad; respawn semantics do not apply.
