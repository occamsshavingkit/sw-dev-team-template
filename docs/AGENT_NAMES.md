# Agent Names — this project

Category: **Muppets** (customer, 2026-04-19).

Conventions (pronoun rule, gender-representation rule, usage) are
defined in `sw-dev-team-template/docs/AGENT_NAMES.md`. This file only
holds the project-specific mapping.

| Canonical role       | Teammate name         | Pronouns        | Source (with date) |
|---|---|---|---|
| `tech-lead`          | Kermit the Frog       | he / him        | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `project-manager`    | Miss Piggy            | she / her       | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `architect`          | Dr. Bunsen Honeydew   | he / him        | *Dr. Bunsen Honeydew*, Disney Wiki — https://disney.fandom.com/wiki/Dr._Bunsen_Honeydew, as of 2026-04-19 |
| `software-engineer`  | Beaker                | he / him        | *Beaker (Muppet)*, Wikipedia — https://en.wikipedia.org/wiki/Beaker_(Muppet), as of 2026-04-19 |
| `researcher`         | Sam Eagle             | he / him        | *Characters in The Muppet Show*, TV Tropes — https://tvtropes.org/pmwiki/pmwiki.php/Characters/TheMuppetShow, as of 2026-04-19 |
| `qa-engineer`        | Statler & Waldorf     | he / him (both) | *Statler and Waldorf*, Wikipedia — https://en.wikipedia.org/wiki/Statler_and_Waldorf, as of 2026-04-19 |
| `sre`                | Animal                | he / him        | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `tech-writer`        | Rowlf                 | he / him        | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `code-reviewer`      | Janice                | she / her       | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `release-engineer`   | Scooter               | he / him        | *The Muppet Movie (1979)*, IMDb — https://www.imdb.com/title/tt0079588/, as of 2026-04-19 |

*Pronouns verified by `researcher` teammate Sam Eagle, 2026-04-19, per
the procedure in `sw-dev-team-template/.claude/agents/researcher.md`
§ Job #6. Primary canon source preferred; Wikipedia / Disney Wiki /
TV Tropes / IMDb accepted here because each cross-references canon
Henson / Disney materials. Re-verify before next template major
release.*

From now on, `tech-lead` passes the teammate name above to the Agent
tool's `name` parameter when spawning specialists, so they appear on
the agent-teams panel at the bottom of the TUI.
