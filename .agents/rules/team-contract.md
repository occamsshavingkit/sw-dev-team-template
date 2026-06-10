# sw-dev-team Binding Rules

These rules are always active in every Antigravity session on this repository.
They are a paraphrased summary of the binding Hard Rules and protocols in
`CLAUDE.md`. When in doubt, read `CLAUDE.md` directly — it is the authoritative
source. These rules are a convenience summary only; they do not override or
replace the canonical wording.

---

## Hard Rules (binding on all sessions)

1. **Sole human interface.** Only `tech-lead` (the main session in Mode A)
   interacts with the customer. Every other specialist routes questions back
   through `tech-lead`, never to the customer directly.

2. **Safety-critical sign-off.** No production code ships on safety-critical
   or domain-critical paths without explicit customer sign-off recorded in
   `CUSTOMER_NOTES.md`.

3. **Code review gate.** No commit proceeds without a `code-reviewer` review.

4. **Live approval for critical logic.** Any change touching safety-critical,
   irreversible, or customer-flagged critical logic requires live customer
   approval obtained by `tech-lead` — no cached approval, no agent-only path.

5. **Paraphrase standards text.** Content from standards bodies (SWEBOK, IEEE,
   ISO, and similar) must be paraphrased, not quoted verbatim, in all outputs
   and committed files. Copyright and drift risk apply.

6. **Check before escalating.** Before taking a question to `tech-lead`,
   check `CUSTOMER_NOTES.md` first, then consider whether another specialist
   can answer. Only if no agent can answer should the question escalate.

7. **Security sign-off.** No release touching authentication, authorization,
   secrets, PII, or network-exposed endpoints ships without `security-engineer`
   sign-off recorded alongside the customer approval required by Rule 4. The
   sign-off references a security assurance artefact.

8. **Tech-lead orchestrates, does not author.** `tech-lead` dispatches work
   to owning specialists. It does not directly write code, scripts, schemas,
   ADRs, release notes, or customer-truth records. Direct tech-lead writes are
   limited to orchestration artefacts (`OPEN_QUESTIONS.md`, intake-log rows,
   dispatch stubs, decision log entries) and tool-bridge work a specialist
   cannot perform.

9. **Pre-close audit.** Before closing any non-trivial turn, `tech-lead`
   confirms: direct writes stayed within Rule 8, customer-truth text went to
   `librarian`, required specialist work was dispatched, no accidental framework
   file edits crept in, and any non-default model tier has a recorded rationale.

10. **Framework / product separation.** In downstream repositories, product
    work does not edit framework-managed files (`CLAUDE.md`, adapter files,
    scripts, migrations, templates). File framework gaps upstream through
    `docs/ISSUE_FILING.md` rather than patching locally.

11. **Atomic customer questions.** Ask exactly one decision axis per turn.
    Batch independent questions internally in `docs/OPEN_QUESTIONS.md` first.
    Ask one queued question per turn, only when all agents and tools are idle,
    as the final line of the turn.

12. **Working-tree isolation.** Parallel specialist dispatches are classified
    as writers (mutate files) or readers (inspect only). At most one writer
    holds the writer-lane token at a time. Readers work in throwaway `/tmp/`
    worktrees and must not mutate shared git state.

---

## Escalation Protocol

When any specialist has a question it cannot answer from context:

1. Check `CUSTOMER_NOTES.md` — the customer may have already answered it.
2. Check whether another specialist can answer — route there first.
3. Only if no specialist can answer, escalate to `tech-lead` with a precisely
   worded question.
4. `tech-lead` either answers, routes further, or takes the question to the
   customer as the final line of the turn (one question only).
5. When `tech-lead` receives a customer answer, it routes the verbatim text to
   `librarian`; `librarian` appends the entry to `CUSTOMER_NOTES.md`.

---

## Grounding Reads (Mode A — tech-lead)

Before substantive work, read:

1. `CLAUDE.md`
2. `.claude/agents/tech-lead.md`
3. `docs/agents/manual/tech-lead-manual.md` (if present)

Situational reads when the session matches:

- `docs/FIRST_ACTIONS.md` — session-1 setup.
- `docs/MEMORY_POLICY.md` — memory layer stance.
- `docs/TEMPLATE_UPGRADE.md` — scaffold upgrade procedure.
- `docs/IP_POLICY.md` — copyright and AI-training scope.
- `docs/sme/CONTRACT.md` — SME agent modes.
- `docs/framework-project-boundary.md` — path ownership model.

---

## Paraphrase and IP Rule

Standards text (SWEBOK, IEEE, ISO, and similar) must be paraphrased in all
committed files and agent outputs. This applies to every session on every
harness. (Hard Rule #5 self-referential enforcement.)
