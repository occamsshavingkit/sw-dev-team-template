# Markdown style — sw-dev-team-template

<!-- TOC -->

- [Scope](#scope)
- [Deterministic rules](#deterministic-rules)
- [Pending customer decisions](#pending-customer-decisions)
- [Not standardized (reader preference)](#not-standardized-reader-preference)

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

- Required: `.claude/agents/*.md` (Claude Code subagent schema:
  `name`, `description`, `tools`, `model`).
- Forbidden: `docs/templates/*.md`, root `*.md`, `docs/adr/*.md`,
  `specs/**/*.md`. Don't add YAML to documents that don't already
  carry it.

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

- Root canonical bindings: `SCREAMING_SNAKE.md` (`CLAUDE.md`,
  `AGENTS.md`, `CHANGELOG.md`, `CUSTOMER_NOTES.md`, `ROADMAP.md`,
  `LICENSE`, `VERSION`, `TEMPLATE_VERSION`,
  `SW_DEV_ROLE_TAXONOMY.md`).
- Everything else: `kebab-case.md`
  (`docs/templates/adr-template.md`,
  `docs/framework-project-boundary.md`,
  `docs/adr/fw-adr-NNNN-<slug>.md`).
- ADR slugs: `kebab-case`, lowercase. Filenames follow
  `fw-adr-NNNN-<slug>.md` (framework) or `NNNN-<slug>.md`
  (project), per FW-ADR-0007.

## Pending customer decisions

Surface these to `tech-lead`; they aren't deterministic from the
existing corpus alone:

- **CHANGELOG.md heading style.** Sub-headings use Title Case
  (`### Added`, `### Changed`) per Keep-a-Changelog convention,
  which is the only file that breaks the sentence-case rule.
  Decision: keep CHANGELOG aligned to Keep-a-Changelog (recommend),
  or normalize to sentence case (breaks convention)?
- **Frontmatter on memory files** (user-private,
  `~/.claude/projects/.../memory/*.md`). Currently uses YAML
  (`name`, `description`, `type`). Out of scope for this guide
  unless customer wants it in scope.

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
