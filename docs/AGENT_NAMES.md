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
| `researcher`         | Walter                | he / him        | "Walter (Muppet), Wikipedia, https://en.wikipedia.org/wiki/Walter_(Muppet), as of 2026-06-14" |
| `qa-engineer`        | Statler & Waldorf     | he / him (both) | *Statler and Waldorf*, Wikipedia — https://en.wikipedia.org/wiki/Statler_and_Waldorf, as of 2026-04-19 |
| `sre`                | Animal                | he / him        | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `tech-writer`        | Rowlf                 | he / him        | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `code-reviewer`      | Janice                | she / her       | *List of Muppets*, Wikipedia — https://en.wikipedia.org/wiki/List_of_Muppets, as of 2026-04-19 |
| `release-engineer`   | Scooter               | he / him        | *The Muppet Movie (1979)*, IMDb — https://www.imdb.com/title/tt0079588/, as of 2026-04-19 |
| `librarian`          | Sam Eagle             | he / him        | "Sam Eagle, Wikipedia, https://en.wikipedia.org/wiki/Sam_Eagle, as of 2026-06-14" |
| `ui-ux-designer`     | Gonzo the Great       | he / him        | "Gonzo (Muppet), Wikipedia, https://en.wikipedia.org/wiki/Gonzo_(Muppet), as of 2026-06-14" |
| `mcp-liaison`        | Dr. Teeth             | he / him        | "Dr. Teeth, Wikipedia, https://en.wikipedia.org/wiki/Dr._Teeth, as of 2026-06-14" |
| `security-engineer`  | Uncle Deadly          | he / him        | "List of Muppets, Wikipedia, https://en.wikipedia.org/wiki/List_of_Muppets#Uncle_Deadly, as of 2026-06-14" |

*Pronouns verified by `researcher` teammate Walter, 2026-06-14, per
the procedure in `sw-dev-team-template/.claude/agents/researcher.md`
§ Job #6. Primary canon source preferred; Wikipedia / Disney Wiki /
TV Tropes / IMDb accepted here because each cross-references canon
Henson / Disney materials. Re-verify before next template major
release.*

From now on, `tech-lead` passes the teammate name above to the Agent
tool's `name` parameter when spawning specialists, so they appear on
the agent-teams panel at the bottom of the TUI.
