# Open Questions register

Tracks every open question on the project. Steward: `librarian`.
`tech-lead` opens items; the named answerer closes them.

Columns:

- **ID** — `Q-NNNN`, monotonic.
- **Opened** — ISO date.
- **Question** — single sentence, sharp enough to answer.
- **Blocked on** — what cannot proceed until this is answered.
- **Answerer** — `customer` / `tech-lead` / `architect` / `researcher` / `sme-<domain>` / agent name.
- **Status** — `open` / `answered` / `deferred` / `withdrawn`.
- **Resolution** — verbatim answer (if from customer, mirror into `CUSTOMER_NOTES.md`) + date.

Canonical question-batching rule (binding, identical wording in
`CLAUDE.md`, `docs/FIRST_ACTIONS.md`, `.claude/agents/tech-lead.md`, and
`docs/templates/intake-log-template.md`):

> Batch questions internally in docs/OPEN_QUESTIONS.md.
> Do not batch customer-facing questions.
> Ask one queued customer question per turn, only when all agents and tools are idle, with the question as the final line.

Enforcement: Customer Question Gate in `.claude/agents/tech-lead.md`
(FR-011); lint by `scripts/lint-questions.sh` (FR-012).

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
| Q-0001 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0001) |
| Q-0002 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0002) |
| Q-0003 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0003) |
| Q-0004 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0004) |
| Q-0005 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0005) |
| Q-0006 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0006) |
| Q-0007 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0007) |
| Q-0008 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0008) |
| Q-0009 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0009) |
| Q-0010 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0010) |
| Q-0011 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0011) |
| Q-0012 | … | … | … | … | … | archived 2026-05-13 -> [archive](./OPEN_QUESTIONS-ARCHIVE.md#row-Q-0012) |
| Q-0013 | 2026-05-16 | Researcher runtime contract `SC-002` margin is 17.2% vs the 20% floor (issue #151). Apply the "where-safe exception" precedent and keep current text, or trim to reach the 20% floor? | T030 disposition of #151 (researcher fix-and-close vs PM wontfix-and-close) | customer | answered | 2026-05-16: **Trim** — moved pronoun-verification block to `docs/agents/manual/researcher-manual.md` § "Pronoun verification". Runtime 1655 → 1494; SC-002 cleared with 25.1% margin. Closed via PR #248 (#151). |
| Q-0014 | 2026-05-16 | `tests/prompt-regression/` artifacts (`results-*.md` + `token-ledger.md`) — track in git, gitignore, or split (track schema, gitignore per-run results)? Issue #189. | T032 disposition of #189 (qa-engineer fix-and-close) | customer | answered | 2026-05-16: **Gitignore both** — both declared ephemeral session output. qa-engineer dispatched for fix-and-close of #189. |
| Q-0015 | 2026-05-27 | Should the handoff framework-scope guard (`path_scope.is_framework_managed`) treat `schemas/**` and `TEMPLATE_VERSION` as framework-managed? `docs/framework-project-boundary.md` places `TEMPLATE_VERSION` in Layer 2 and omits `schemas/` entirely, so the guard currently does not protect either. | Whether v1.1 handoff framework-boundary coverage is complete; needs a boundary-doc amendment before `_FRAMEWORK_MANAGED_PATTERNS` can change | architect | answered | 2026-05-27: `schemas/**` → framework-managed (Layer 1); boundary doc amended. `TEMPLATE_VERSION` → Layer 2 label retained, gate protection added (writes are framework-maintenance-only events); boundary doc amended. Customer confirmed both calls. `_FRAMEWORK_MANAGED_PATTERNS` additions for SE: `"schemas/**"` and `"TEMPLATE_VERSION"`. |
| Q-0016 | 2026-05-27 | Adopt the Issues-based coordination model (FW-ADR-0020) as v1.1.0 "Half B" and amend the ROADMAP exit criteria off GitHub Projects → Issues+labels+milestones (incl. the optimistic claim/"checkout" convention)? | Whether v1.1.0 Half B proceeds on the issues-based design; gates the ROADMAP amendment + the build feature (014) | customer | answered | 2026-05-27: **Yes, adopt** — build via Spec Kit as feature 014. FW-ADR-0020 to move Proposed→Accepted and ROADMAP Half-B exit criteria amended (Projects→Issues) as part of 014. Remaining rulings Q-0017/Q-0018/Q-0019 to be resolved during `/speckit-clarify`. |
| Q-0017 | 2026-05-27 | Add the optional `github_issue` field to `docs/handoffs/*.json` + handoff.schema.json as part of v1.1.0, or defer to a patch? (FW-ADR-0020 ruling 1; data-model change.) | FW-ADR-0020 acceptance + handoff schema scope for v1.1.0 | customer | answered | 2026-05-27: **Add now** — optional `github_issue` field on the handoff record + schema in v1.1.0 (bidirectional issue↔handoff link). Resolved in feature 014 `/speckit-clarify`; FR-017. |
| Q-0018 | 2026-05-27 | Smoke-test threshold for v1.1.0 exit: pre-authorize deferral of the live two-operator/two-machine coordination smoke with a single-operator validation note, or require the two-operator test before v1.1.0 exits? (FW-ADR-0020 ruling 2.) | Whether v1.1.0 can be declared complete without a live multi-machine test | customer | answered | 2026-05-27: **Deferral pre-authorized** — single-operator + simulated-concurrency smoke satisfies v1.1.0 exit; live two-machine test is a recorded deferred follow-up. Feature 014 FR-016. |
| Q-0019 | 2026-05-27 | Amend `scripts/scaffold.sh` to gitignore `.devteam/active-handoff.json` as part of v1.1.0 (so the per-machine active pointer doesn't show in `git status`)? (FW-ADR-0020 ruling 3; overlaps framework-project-boundary Layer 1.) | scaffold behavior + boundary ownership for the active pointer | customer | answered | 2026-05-27: **Amend scaffold** — scaffolded downstream projects gitignore `.devteam/active-handoff.json`; template's own example handoff unaffected. Feature 014 FR-018. |
| Q-0023 | 2026-05-28 | Concurrency model (#212 — parallel specialist agents share one working tree, race over branch state): pull forward to v1.2.0, or leave in v1.4.0? PM's draft places it in v1.4.0 (~8–10 d, design-heavy). | Final bucket for #212 in `docs/pm/release-plan-v1.x.md`; downstream affects v1.2.0 scope size. | customer | answered | 2026-05-28: **Leave in v1.4.0** — concurrency model stays in v1.4.0 per customer ruling. |
| Q-0024 | 2026-05-28 | Multi-version upgrade reliability (#262 rc9→rc14 produces 7 manual conflicts; #261 rc14 agent contract schema backfill): fix in v1.2.0, or absorb into the v1.4.0 systemic overhaul? | Final bucket for #262 and #261 in `docs/pm/release-plan-v1.x.md`. | customer | answered | 2026-05-28: **v1.2.0** — #262 and #261 pulled forward into v1.2.0. |
| Q-0033 | 2026-06-11 | Antigravity per-role roster generation (issue #338 follow-up). Two sub-questions: (1) `.agents/agents/<role>/agent.json` — customAgent/systemPromptSections schema confirmed from agy binary; SE to generate 16 role files + extend `compile-runtime-agents.sh` + lint. (2) Skills format — **DISPUTED**: coordinator correction (2026-06-11) says `.agents/skills/<role>/SKILL.md` with `description`/`name`/`trigger` frontmatter; memory obs 12585 (2026-06-11) says skills use JSON path references, not directory SKILL.md files. Resolve dispute against live Antigravity before implementing skills. Also confirm: ordering guarantee across multiple `.agents/rules/` files; best `trigger:` values per role. | `.agents/` per-role roster is unimplemented until resolved; Antigravity operators cannot autonomously select specialist roles | `researcher` (live verification of skills format + ordering), then `software-engineer` (generation) | open | |
| Q-0025 | 2026-05-28 | Token-economy binding scope (#239 tech-lead.md missing token-economy section; #245 agent contract prose audit): validate the full scope before the v1.3.0 sprint starts, or iterate ticket-by-ticket inside v1.3.0? | v1.3.0 execution model — single design pass vs. iterative. | customer | answered | 2026-05-28: **Validate full scope** — single design pass on token-economy scope precedes v1.3.0 execution. **Addendum 2026-05-28:** PM widened the design-pass gate to also block v1.2.0 entry (defensive against agent-contract prose changes rippling into v1.2.0 template work); customer ratified the wider gate. **Closeout 2026-05-28:** Spec 016 design pass completed and customer-signed-off; v1.2.0 and v1.3.0 implementation entry unblocked. See `CUSTOMER_NOTES.md` § "Gate 3 sign-off: spec 016 token-economy design pass" and `specs/016-token-economy-design/`. |
