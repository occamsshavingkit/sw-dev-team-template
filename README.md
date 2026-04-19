# SW-dev Team Template for Claude Code

A ready-to-use Claude Code project scaffold that turns a single Claude
session into a 9-role software-development team with a strict escalation
protocol and a per-project SME pattern.

## Quickstart

1. Unzip this folder into an empty directory.
2. `cd` into that directory.
3. Run `claude`.
4. Claude reads `CLAUDE.md` on session start and runs the two-step first-
   action flow:
   - **Step 1 — Skill packs.** Claude shows five curated skill-pack options
     and waits for you to pick.
   - **Step 2 — Project scoping + SME discovery.** `tech-lead` asks about
     the project, which SME domains it needs, which you're expert in,
     and which need external recruiting. Then `tech-lead` proposes
     additional SMEs you might not have thought of.

Only after both steps are complete does `tech-lead` dispatch the first
real work subagent.

## What's in here

| Path | What it is |
|---|---|
| `CLAUDE.md` | Project guide; Claude reads this every session. |
| `CUSTOMER_NOTES.md` | Append-only log of customer answers, stewarded by `researcher`. |
| `SW_DEV_ROLE_TAXONOMY.md` | Reference taxonomy (SWEBOK / ISO 12207 / IEEE 1028 / ISTQB / SFIA v9 / Google SRE / PMBOK) that CLAUDE.md cites. |
| `docs/glossary/ENGINEERING.md` | **Binding** generic software-engineering terminology. All agents use these senses. |
| `docs/glossary/PROJECT.md` | **Binding** project-specific jargon (customer-domain, vendor, site, codenames). |
| `docs/AGENT_NAMES.md` | Canonical role → teammate name → pronouns mapping (agent-teams panel). |
| `docs/OPEN_QUESTIONS.md` | Register of open questions, with answerer and status. |
| `docs/INDEX.md` | Table of contents for everything under `docs/` plus repo-root bindings. |
| `docs/ISSUE_FILING.md` | How to file framework-gap issues upstream; cites the template version. |
| `VERSION` | Current template version (SemVer). |
| `CHANGELOG.md` | Release history. |
| `LICENSE` | MIT — permissive; downstream projects may be closed-source. Not shipped in scaffolded projects; each project picks its own license. |
| `scripts/scaffold.sh` | Scaffolds a new downstream project from this template. |
| `docs/templates/` | Document templates shaped after the relevant standards (ISO/IEC/IEEE 29148 / 42010 / 12207, arc42, C4, INVEST). |
| `.claude/agents/*.md` | 9 specialist subagents + 1 SME template. |
| `docs/sme/` | SME reference material, per-domain. `INVENTORY.md` per domain; copyrighted items in `local/` (gitignored). |

### IP policy, in one line

Anything not created within the project is assumed copyrighted unless
the customer overrides that in `CUSTOMER_NOTES.md`. Copyrighted items
stay in `docs/sme/<domain>/local/` and are cited in the domain's
`INVENTORY.md`. See CLAUDE.md § IP policy.

## Agent roster

| Agent | Canonical role |
|---|---|
| `tech-lead` | Tech Lead + orchestrator + **sole human interface** |
| `architect` | Software Architect |
| `software-engineer` | Implementation / construction |
| `researcher` | Standards librarian + `CUSTOMER_NOTES.md` steward |
| `qa-engineer` | Test strategy, integration/system/acceptance testing |
| `sre` | Reliability + performance |
| `tech-writer` | User-facing documentation |
| `code-reviewer` | Pre-commit review + IEEE 1028-style audit |
| `release-engineer` | Build pipeline + packaging + releases |
| `sme-<domain>` (×N) | Per-project domain experts, created in Step 2 |

## The escalation model in one line

**`tech-lead` is the only agent that talks to the human.** Every other
agent, when stuck, first looks for another agent who can answer, and only
escalates to `tech-lead` as a last resort. Customer answers land in
`CUSTOMER_NOTES.md` verbatim so the team doesn't re-ask.

## Customizing

- **Per-project SMEs:** `tech-lead` proposes these in Step 2. Each SME
  becomes `.claude/agents/sme-<domain>.md` based on `sme-template.md`.
- **Additional specialists:** add a new `.claude/agents/<role>.md` and
  wire it into `tech-lead.md`'s routing table so `tech-lead` knows when
  to delegate to it.
- **Skills:** the first-action flow proposes five skill packs; install
  whatever fits the project's stack.

## Philosophy

- Claude already knows how to write code. The scaffold's job is to give
  it explicit role boundaries, prevent context drift, and protect the
  customer's attention.
- One role = one agent. Small overlap acknowledged (see
  `SW_DEV_ROLE_TAXONOMY.md` §3 heatmap); silent overlap is a bug.
- Customer rulings are binding; agent opinions are advisory.
