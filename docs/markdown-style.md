# Markdown style — sw-dev-team-template

<!-- TOC -->

- [Scope](#scope)
- [Deterministic rules](#deterministic-rules)
- [Not standardized (reader preference)](#not-standardized-reader-preference)
- [Resolved decisions](#resolved-decisions)

<!-- /TOC -->

## Scope

Binds all markdown under the template repo and downstream scaffolds:
`*.md` at the repo root, `.claude/agents/*.md`, `docs/**/*.md`,
`specs/**/*.md`, and `examples/**/*.md`. Memory files under
`~/.claude/projects/.../memory/*.md` are user-private and not bound by
this guide.

Authored by `tech-writer`. Amendments require `tech-lead` +
`tech-writer` + `code-reviewer` consensus and a `docs/pm/CHANGES.md`
row. Do not bulk-reformat existing files on a style-guide change —
let new edits land into compliance opportunistically.

## Deterministic rules

These reflect the dominant pattern already present in the repo.
Outliers should converge to these on next touch; no mass rewrite.

**Headings.**

- ATX only (`# `, `## `, ...). No setext (`====` / `----`
  underline). No trailing `#` close-tags.
- One `# H1` per file, on line 1 (after YAML frontmatter, if any).
- No level skipping (`##` then `####` is wrong). Each level descends
  by one.
- Sentence case: `## Decision drivers`, not `## Decision Drivers`.
  Acronyms keep their case (`## ADR index`, `## SemVer rules`).
  File-root canonical headings that are themselves acronyms or
  proper nouns stay capitalized (`CHANGELOG`, `ROADMAP`).
- `CHANGELOG.md` uses sentence case for all multi-word `###`
  sub-headings; single-word Keep-a-Changelog labels (`### Added`,
  `### Fixed`, etc.) are sentence-case-compatible and conform by
  default.
- **Exception:** `AGENTS.md` (Codex adapter) uses Title Case for
  section headings as a Codex-side convention. Do not normalize to
  sentence case. All other root canonical files use sentence case.

**Lists.**

- Unordered: `-` only. Do not use `*` or `+`.
- Ordered: `1.`, `2.`, ... — period, not paren. Numbers may be all
  `1.` (Markdown renumbers) or sequential; pick one per list.
- Indent nested items by two spaces.

**Code fences.**

- Triple backticks only. No `~~~`.
- Tag the language when known (`bash`, `sh`, `python`, `yaml`,
  `json`, `text`, `markdown`). Untagged fences are reserved for
  shell-transcript snippets where the prompt itself carries the
  language signal, or for prose-literal blocks (entry templates,
  question-format blocks).

**Inline code vs. emphasis.**

- Backticks for: file paths, command names, env vars, role names
  (`tech-lead`), config keys, code identifiers, exact string
  literals.
- `**bold**` for: rule labels (`**REQUIRED**`), strong qualifiers
  in a definition line, the first occurrence of a defined term in
  a section header's body paragraph.
- `*italic*` is reserved for genuine emphasis or short titles
  (book / standard names). Do not stack `***bold-italic***`.

**Links.**

- Inline only: `[text](url-or-path)`. No reference-style
  (`[text][label]`) — the repo has zero of those today.
- Relative paths for in-repo links: `docs/templates/adr-template.md`,
  not absolute URLs to GitHub.
- No bare URLs in prose. If a URL must appear verbatim (e.g., in
  a citation row), wrap it in backticks.

**Tables.**

- Header row required. Alignment row is `|---|---|...|` (no
  alignment markers unless a numeric column actually needs
  `---:`).
- Surrounding pipes required on every row.
- No padding spaces inside cells beyond a single space after the
  pipe.

**Blockquotes.**

- `> ` for verbatim customer quotes, customer-question text in
  `CUSTOMER_NOTES.md`, and rule-text blocks reproduced from
  binding docs.
- Not for callouts / asides — use a labeled bold line or a
  parenthetical instead.

**Frontmatter.**

Required on the file classes below with the minimum fields shown.
Existing files predating this rule are exempt; backfill is a
separate work-item. New files in these classes MUST land with
frontmatter from creation.

- `.claude/agents/*.md` — `name`, `description`, `tools`, `model`.
- Memory files (`~/.claude/projects/.../memory/*.md`) — `name`,
  `description`, `metadata.type`.
- ADRs (`docs/adr/*.md`) — `name`, `description`, `status`
  (`proposed` | `accepted` | `superseded` | `superseded-in-part`),
  `date`.
- Templates (`docs/templates/*.md`) — `name`, `description`,
  `template_class` (e.g., `requirements`, `architecture`, `phase`,
  `task`).
- Spec files (`specs/*/spec.md`, `specs/*/contracts/*.md`) —
  `name`, `description`, `status` (`draft` | `active` |
  `resolved`), `created_date`.

Other documents (root `*.md`, free-form `docs/**/*.md` prose) do
not carry YAML.

**Whitespace.**

- LF line endings. No tabs (spaces only). No trailing whitespace.
- Single blank line between top-level sections. No more than one
  consecutive blank line.
- File ends with exactly one newline.

**Line wrapping.**

- Hard-wrap prose at 72 columns where the surrounding file
  already does. Most agent contracts and ADRs follow this.
- Do not wrap inside link text, inside code spans, or inside
  table cells.
- Long inline-code strings (paths, command lines) may exceed 72
  when wrapping would split them.

**Table-of-contents (TOC).**

- Files with > ~3 `##` sections carry an `<!-- TOC -->` /
  `<!-- /TOC -->` block right under the `# H1`. Generated, not
  hand-maintained — bump it when section headings change.

**Horizontal rules.**

- `---` on its own line, one blank line above and below. Used
  sparingly to separate a doc preamble from numbered sections
  (see ADRs, templates). Do not use to decorate.

**File naming.**

- Root canonical bindings MUST use `SCREAMING_SNAKE.md` — this is a
  deterministic rule, no exceptions. The enumerated set is:
  `CLAUDE.md`, `AGENTS.md`, `CHANGELOG.md`, `CUSTOMER_NOTES.md`,
  `ROADMAP.md`, `LICENSE`, `VERSION`, `TEMPLATE_VERSION`,
  `SW_DEV_ROLE_TAXONOMY.md`. Adding a new root canonical binding
  requires `tech-lead` consensus and an entry in this list.
- Everything else: `kebab-case.md`
  (`docs/templates/adr-template.md`,
  `docs/framework-project-boundary.md`,
  `docs/adr/fw-adr-NNNN-<slug>.md`).
- ADR slugs: `kebab-case`, lowercase. Filenames follow
  `fw-adr-NNNN-<slug>.md` (framework) or `NNNN-<slug>.md`
  (project), per FW-ADR-0007.

## Not standardized (reader preference)

These vary in the corpus, but the variance does not impair
readability or diffability:

- Em-dash spacing — both `word—word` and `word — word` appear; the
  spaced form dominates and is fine.
- Whether a definition list uses `**Term.**` or `**Term:**`
  before the body sentence.
- Whether a section's first paragraph repeats the heading as a
  topic sentence.
- Whether numbered ordered lists restart at 1 inside subsections
  or continue from the parent.

## Resolved decisions

Customer rulings that moved items out of "Pending customer
decisions" into the deterministic-rules sections above.

- **2026-05-15 — CHANGELOG heading case.** Normalize to sentence
  case; Keep-a-Changelog single-word labels conform by default.
  Bulk-normalize pass same day was a no-op.
- **2026-05-15 — YAML frontmatter expansion.** Tighten — require
  frontmatter on memory files, ADRs, templates, and spec files
  per the Frontmatter rule. Backfill is a separate work-item.
- **2026-05-15 — SCREAMING_SNAKE for root canonical files.** Keep
  as a deterministic rule, no exceptions; new bindings require
  `tech-lead` consensus and an entry in the enumerated list.
- **2026-05-15 — AGENTS.md Title Case sections.** Keep as a
  Codex-side convention. `AGENTS.md` uses Title Case; do not
  normalize. All other root canonical files use sentence case.
