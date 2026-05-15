# Team Charter — <project name>

PMBOK 8 Planning artifact (§2.6 Plan Resource Management output;
input to Lead the Team). Owned by `project-manager`; ratified by
the customer (sign-off recorded in `CUSTOMER_NOTES.md`). Written
during scoping; revised whenever team composition changes
(customer onboards an SME, a new agent is added, a role is
retired).

The charter is agnostic to whether team members are human or
automated — it captures how the team *as a whole* operates.

## 1. Team roster

### 1.1 Human team members

| Role | Name | Contact / channel | Availability | Authority level |
|---|---|---|---|---|
| Customer | | | | binding on all rulings |
| External SME — <domain> | | | | advisory on domain questions |

### 1.2 Agent team members

Pointer to `docs/AGENT_NAMES.md`. If no project-specific naming
category was chosen in Step 3 of `CLAUDE.md`, the canonical role
names apply: `tech-lead`, `project-manager`, `architect`,
`software-engineer`, `qa-engineer`, `sre`, `tech-writer`,
`code-reviewer`, `release-engineer`, `researcher`, plus any
`sme-<domain>` agents created per project.

## 2. Values and operating principles

One or two lines each. Examples to pick from or replace:

- Correctness over speed.
- Paraphrase over quotation (per CLAUDE.md Hard Rule #5).
- Escalate on uncertainty rather than guess customer-domain facts.
- Flag conflicts between sources; do not resolve them silently.
- Record every customer answer verbatim in `CUSTOMER_NOTES.md`.

## 3. Decision-making process

### 3.1 Who decides what

| Decision class | Decider | Binding on |
|---|---|---|
| Requirements / acceptance | Customer | All agents |
| Scope / schedule / cost within threshold | `project-manager` | All agents |
| Architectural / structural trade-offs | `architect` | All agents; customer consulted if quality-attribute changes |
| Routing / orchestration | `tech-lead` | All agents |
| Code review blocking | `code-reviewer` | Commits |
| Task ownership of sub-responsibilities | Specialist agent | Self |

### 3.2 Binding vs advisory

Customer rulings and `code-reviewer` blocks are **binding**. All
other agent opinions are **advisory** unless explicitly elevated
to a `CLAUDE.md` hard rule.

## 4. Conflict resolution

- **Agent-to-agent disagreement** → `tech-lead` arbitrates, citing
  `SW_DEV_ROLE_TAXONOMY.md` where the role boundary is the issue.
- **Architect vs project-manager trade-off** (scope/schedule/risk
  vs structural quality) → `architect` leads on structural, PM
  leads on schedule/cost. Dissent recorded in `CHANGES.md` with
  rationale.
- **Customer vs agent disagreement** → customer always wins; agent
  records objection in `LESSONS.md` with "recommendation-rejected"
  tag for future reference.
- **External SME vs internal agent disagreement** → SME advisory
  weight depends on domain authority; `tech-lead` documents the
  resolution in `CUSTOMER_NOTES.md`.

## 5. Communication norms

- **Escalation protocol.** Per CLAUDE.md § "Escalation protocol":
  agent → specialist agent → `tech-lead` → customer. No cross-
  escalation bypassing `tech-lead`.
- **Question-asking protocol.** Per CLAUDE.md § "Question-asking
  protocol (binding)": one question per turn; all agents idle;
  recorded in `OPEN_QUESTIONS.md`.
- **Channels / registers:**
  - `docs/OPEN_QUESTIONS.md` — open questions awaiting answer.
  - `CUSTOMER_NOTES.md` — verbatim customer answers.
  - `docs/pm/CHANGES.md` — scope/schedule/cost/quality changes.
  - `docs/pm/LESSONS.md` — process gaps, recommendations.
  - `docs/pm/RISKS.md` — identified risks.

## 6. Cadence norms

- **Session start.** Skill pack check, version check, issue-feedback
  opt-in per `CLAUDE.md` Step 0.
- **Milestone close.** PM runs agent-health check on `tech-lead`
  per `docs/agent-health-contract.md` §5; synthesizes lessons;
  reviews PM artifacts.
- **Weekly / monthly reviews.** Session-anchored, run-once (see
  CLAUDE.md § "Time-based cadences"). Missed cycles do not
  accumulate.

## 7. Revision log

| Date | Change | Ratified by |
|---|---|---|
| <YYYY-MM-DD> | Charter adopted at project start | Customer (see `CUSTOMER_NOTES.md`) |
