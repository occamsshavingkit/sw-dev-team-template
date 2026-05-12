# Common Runtime Rules Candidate

Generated candidate for M0/M1 token-reduction review. This file is not canonical policy and does not replace `CLAUDE.md`, `AGENTS.md`, `.claude/agents/*.md`, or any matching `.claude/agents/*-local.md` supplement.

## Canonical Inputs

- `CLAUDE.md`
- `AGENTS.md`
- `.claude/agents/*.md`
- `.claude/agents/*-local.md`, when present
- `specs/001-template-improvement-plan/` M0/M1 planning artifacts

## Shared Rules

- `tech-lead` is the sole customer interface. Specialists do not contact the customer.
- Every role must check for its matching local supplement before role work; if it conflicts with canonical policy or `CLAUDE.md` Hard Rules, stop and escalate to `tech-lead`.
- Specialists answer within their role boundary. If work belongs elsewhere, return a routing request instead of absorbing it.
- Customer-domain facts come from `CUSTOMER_NOTES.md`, a relevant `sme-<domain>`, or a `tech-lead` escalation; do not guess.
- Escalations go through `tech-lead` with need, blocker, best responder, and what was already checked.
- No specialist spawns, delegates, or creates a new customer channel unless its canonical file and the harness explicitly allow that action through `tech-lead`.
- Hard Rules from `CLAUDE.md` remain binding, including no commit without `code-reviewer` review, critical-path customer sign-off, security sign-off for Rule #7 paths, and role-routed artifact ownership.
- Generated runtime candidates require review before operational use. If a candidate conflicts with canonical sources, canonical sources win and the candidate must be corrected.

## Standard Escalation Shape

```text
Need: <one line>
Why blocked: <one line>
Best candidate responder: <agent name, or "customer">
What I already checked: <CUSTOMER_NOTES / local supplement / other agents / relevant files>
```
