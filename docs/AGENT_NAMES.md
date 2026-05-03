# Agent Names

Records the mapping between **canonical role** (the `.claude/agents/*.md`
file and the agent type used in routing) and the **teammate name** the
customer has chosen to display on the agent-teams panel at the bottom
of the TUI.

**Stewarded by `tech-lead`;** written by `researcher`; names and
pronouns are confirmed against an authoritative Tier-1 / Tier-2 source
for the real person or character before being committed here.

## Personality-match rule

When a category has a member whose well-known personality maps cleanly
to a canonical role, that member should get that role. A personality
match beats a cosmetic or alphabetical one.

Examples:

- **Muppets** — Sam Eagle's pompous authoritativeness fits `researcher`;
  Statler & Waldorf's critical streak fits `qa-engineer`; Miss Piggy's
  drive and schedule discipline fits `project-manager`; Bunsen's design
  instinct fits `architect`; Beaker's execution under Bunsen fits
  `software-engineer`; Animal's relentless beat fits `sre`; Rowlf's
  articulate calm fits `tech-writer`; Scooter's "get it out the door"
  fits `release-engineer`.
- **Historical scientists** — Ada Lovelace's algorithmic foresight
  fits `architect`; Vera Rubin's painstaking observation fits
  `researcher`; Grace Hopper's compiler + standards work fits
  `tech-lead`; Rosalind Franklin's rigorous X-ray work fits
  `qa-engineer`.

When no clear personality match exists in a category, pick on fit to
role (competence / temperament) first, and only then on aesthetics.
Tie-breakers are `tech-lead`'s call.

## Choosing names

At Step 3 of `CLAUDE.md` FIRST ACTIONS, `tech-lead` asks the customer
to pick exactly one of:

- **A category of names** — e.g., Muppets (fictional), famous singers,
  classical composers, historical scientists, fictional detectives,
  mountaineers, poets, chess world champions, Nobel laureates, or any
  other coherent category the customer proposes. `tech-lead` proposes
  specific members of the category for each canonical role;
  `researcher` verifies pronouns for each real-person or character
  member against an authoritative source. Mixed-gender categories
  (e.g., famous singers has many) are fine — **pronouns follow the
  real person or character**, not a default.
- **A custom list** — the customer assigns specific names per role.
- **Canonical names** — no renaming; teammates appear as
  `tech-lead`, `architect`, etc.

The customer may also skip naming for now and revisit later.

## Pronoun verification procedure

`researcher` owns pronoun verification. See
`.claude/agents/researcher.md` § Job #6 for the authoritative
hierarchy (living persons → record-label / agency bios → reference
encyclopedias that cite primary sources; historical figures →
reference biographies; fictional characters → canon). The `Source`
column in the mapping tables below must cite the specific source and
the date it was checked — not just "Wikipedia". Re-verify if > 12
months old.

## Pronoun rule

When a category's members have mixed pronouns, record each teammate's
pronouns verbatim from the source and use them throughout the project.
When referring to a teammate in written work, use their pronouns
(e.g., if `architect` is named `Aretha Franklin`, she / her). Do not
default to "they" unless the real member uses "they" or the pronouns
are genuinely unknown after `researcher` has checked.

Fictional characters follow the pronouns used in the canon source
(Muppets: Miss Piggy = she / her; Kermit = he / him; Gonzo = he / him;
etc.).

## Gender-representation rule

When picking names from a category, `tech-lead` (with `researcher`)
aims for a roughly even split across genders — **but only insofar as
the category supports it**. The picks should reflect the category's
own distribution, not artificially over-represent any gender beyond
it.

- If the category is already roughly balanced (e.g., famous singers),
  aim for ~50 / 50 and include non-binary members where the category
  has them.
- If the category is naturally skewed (e.g., US presidents, classical
  composers of 1750–1850, Premier League managers, historical queens
  consort), the picks reflect that skew. Do not pump up the minority
  gender beyond its natural presence in the category. The customer
  picked the category; their pick is not challenged on this basis.
- Non-binary representation: include non-binary members of the
  category where they exist and are identifiable from Tier-1/2
  sources. Do not invent or assume.

Pronouns still follow the real person or character in every case.

## Mapping table

Fill in `Teammate name`, `Pronouns`, `Source`, and `Notes` once the
category or custom list is chosen. Leave rows blank if not yet
assigned.

| Canonical role       | Teammate name | Pronouns | Source (person / character & citation) | Notes |
|---|---|---|---|---|
| `tech-lead`          |               |          |                                         |       |
| `project-manager`    |               |          |                                         |       |
| `architect`          |               |          |                                         |       |
| `software-engineer`  |               |          |                                         |       |
| `researcher`         |               |          |                                         |       |
| `qa-engineer`        |               |          |                                         |       |
| `sre`                |               |          |                                         |       |
| `tech-writer`        |               |          |                                         |       |
| `code-reviewer`      |               |          |                                         |       |
| `release-engineer`   |               |          |                                         |       |

**SMEs.** One row per `sme-<domain>` agent the project creates. Add as
new SMEs are added.

| Canonical role       | Teammate name | Pronouns | Source (person / character & citation) | Notes |
|---|---|---|---|---|
| `sme-<domain>`       |               |          |                                         |       |

## Example — Muppets category

(*Muppets canon skews male; the picks reflect that and do not
artificially over-represent female characters.*)

| Canonical role       | Teammate name         | Pronouns | Source | Notes |
|---|---|---|---|---|
| `tech-lead`          | Kermit the Frog       | he / him | The Muppet Show (Henson Productions) | de facto leader |
| `project-manager`    | Miss Piggy            | she / her | The Muppet Show | schedule / scope / drive |
| `architect`          | Dr. Bunsen Honeydew   | he / him | The Muppet Show | designs things |
| `software-engineer`  | Beaker                | he / him | The Muppet Show | builds things |
| `researcher`         | Sam Eagle             | he / him | The Muppet Show | authoritative |
| `qa-engineer`        | Statler & Waldorf     | he / him (both) | The Muppet Show | critics |
| `sre`                | Animal                | he / him | The Muppet Show | keeps the beat |
| `tech-writer`        | Rowlf                 | he / him | The Muppet Show | articulate |
| `code-reviewer`      | Janice                | she / her | The Muppet Show | exacting, creative |
| `release-engineer`   | Scooter               | he / him | The Muppet Show | ships things |

## Example — Famous singers category (balanced)

(*for illustration; balances easily because the category has strong
representation across genders*)

| Canonical role       | Teammate name         | Pronouns   | Source |
|---|---|---|---|
| `tech-lead`          | Freddie Mercury       | he / him   | Queen |
| `project-manager`    | Beyoncé Knowles       | she / her  | solo / Destiny's Child |
| `architect`          | David Bowie           | he / him   | solo |
| `software-engineer`  | Janelle Monáe         | she / her, they / them | solo |
| `researcher`         | Joni Mitchell         | she / her  | solo |
| `qa-engineer`        | Aretha Franklin       | she / her  | solo |
| `sre`                | Bruce Springsteen     | he / him   | solo / E Street Band |
| `tech-writer`        | Leonard Cohen         | he / him   | solo |
| `code-reviewer`      | Nina Simone           | she / her  | solo |
| `release-engineer`   | Sam Smith             | they / them | solo |

(5 women, 4 men, 1 non-binary — within the "roughly even" guideline,
and includes a non-binary artist using they / them. `researcher` would
confirm pronouns against an authoritative source at commit time.)

## Using teammate names

`tech-lead` passes the teammate name to the harness spawn tool's
name parameter. In Claude Code that is the `Agent` tool's `name`
parameter, e.g.:

    Agent({
      subagent_type: "architect",
      name: "Dr. Bunsen Honeydew",
      prompt: "...",
    })

When the agent-teams experimental feature is on
(`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, pinned in
`.claude/settings.json`), the teammate then appears on the bottom panel
of the TUI and is addressable via `SendMessage({to: "Dr. Bunsen
Honeydew"})`.

In Codex, use the native subagent spawn interface and preserve the same
canonical role plus teammate name where the harness supports naming.
If Codex returns an arbitrary nickname, worker label, or opaque ID, that
value is an internal routing handle only. Customer-facing text,
Turn Ledgers, handover briefs, issue comments, status reports, and
durable docs must use the mapped teammate name from this file, or the
canonical role when the row has no teammate name. Do not let harness-
generated names replace this mapping.

If no teammate name is assigned, spawn with `name: "<canonical role>"`
so the panel still shows the role (e.g., `name: "architect"`).
