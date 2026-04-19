#!/usr/bin/env bash
#
# scripts/scaffold.sh — scaffold a new downstream project from this template.
#
# Run from the template repo root. Copies the template to <target-dir>,
# resets project-specific registers to empty-but-shaped stubs, stamps
# TEMPLATE_VERSION, initializes git in the target, and prints a
# next-steps checklist.
#
# Usage: scripts/scaffold.sh <target-dir> [<project-display-name>]
#
# Closes upstream issue #1.

set -euo pipefail

usage() {
  cat >&2 <<EOF
Usage: scripts/scaffold.sh <target-dir> [<project-display-name>]

Copies this template to <target-dir>, resets project-specific registers
(docs/OPEN_QUESTIONS.md, CUSTOMER_NOTES.md, docs/AGENT_NAMES.md) to
empty-but-shaped stubs, stamps TEMPLATE_VERSION, initializes git,
and prints a next-steps checklist.

<target-dir>              path to a new directory (must not already exist
                          or must be empty).
<project-display-name>    display name used in the scaffolded README.
                          Defaults to basename of <target-dir>.
EOF
  exit 2
}

# --- Sanity: must run from template repo root --------------------------------
if [[ ! -f VERSION || ! -f CLAUDE.md || ! -d .claude/agents || ! -d docs/templates ]]; then
  echo "ERROR: run this from the template repo root." >&2
  echo "Expected: VERSION, CLAUDE.md, .claude/agents/, docs/templates/" >&2
  exit 1
fi

[[ $# -ge 1 ]] || usage
target="$1"
project_name="${2:-$(basename "$target")}"

if [[ -e "$target" ]]; then
  if [[ -d "$target" && -z "$(ls -A "$target" 2>/dev/null || true)" ]]; then
    : # empty dir, OK
  else
    echo "ERROR: target '$target' exists and is not empty." >&2
    exit 1
  fi
fi

mkdir -p "$target"

template_version="$(cat VERSION | tr -d '[:space:]')"
template_sha="$(git rev-parse HEAD 2>/dev/null || echo unknown)"
today="$(date -u +%Y-%m-%d)"

# --- Copy template content, excluding template-only paths --------------------
# tar is POSIX and preserves permissions; explicit excludes beat wildcard cp.
tar --exclude='./.git' \
    --exclude='./VERSION' \
    --exclude='./CHANGELOG.md' \
    --exclude='./CONTRIBUTING.md' \
    --exclude='./LICENSE' \
    --exclude='./dryrun-project' \
    --exclude='./.github' \
    --exclude='./migrations' \
    -cf - . | (cd "$target" && tar -xf -)

# --- Reset project-specific registers ----------------------------------------
cat > "$target/docs/OPEN_QUESTIONS.md" <<'EOF'
# Open Questions register

Tracks every open question on the project. Steward: `researcher`.
`tech-lead` opens items; the named answerer closes them.

Columns:

- **ID** — `Q-NNNN`, monotonic.
- **Opened** — ISO date.
- **Question** — single sentence, sharp enough to answer.
- **Blocked on** — what cannot proceed until this is answered.
- **Answerer** — `customer` / `tech-lead` / `architect` / `researcher` / `sme-<domain>` / agent name.
- **Status** — `open` / `answered` / `deferred` / `withdrawn`.
- **Resolution** — verbatim answer (if from customer, mirror into `CUSTOMER_NOTES.md`) + date.

Ask the customer **one question per turn**, only when all agents are idle.
See `.claude/agents/tech-lead.md` Job #1 and `CLAUDE.md` Step 2.

At project start, `tech-lead` copies seed questions from
`docs/templates/scoping-questions-template.md` into the table below.

| ID | Opened | Question | Blocked on | Answerer | Status | Resolution |
|---|---|---|---|---|---|---|
EOF

cat > "$target/CUSTOMER_NOTES.md" <<'EOF'
# CUSTOMER_NOTES.md

Append-only log of customer-originated facts: domain truths,
requirements, acceptance criteria, and rulings relayed by `tech-lead`.
Maintained by `researcher`.

**Rules:**
- Append only. Never rewrite or delete past entries.
- Record customer answers verbatim. Paraphrase only in the surrounding
  framing, not in the quoted text.
- One entry per topic. If a later answer supersedes an earlier one,
  add a new entry and cross-reference the superseded one.
- If an entry is ambiguous on re-read, do not reinterpret —
  `tech-lead` must take the clarification back to the customer.

**Entry template:**

```
## YYYY-MM-DD — <short topic>

**Question (from <agent>, relayed by tech-lead):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim response>

**Supersedes:** <date + topic of prior entry, if any>
**Recorded by:** researcher
```

---

<!-- Entries begin below this line. First entry will typically be the
     Step-2 project charter + SME plan from the CLAUDE.md first-action flow. -->
EOF

cat > "$target/docs/AGENT_NAMES.md" <<EOF
# Agent Names — $project_name

Category: *(to be chosen at Step 3 of CLAUDE.md FIRST ACTIONS)*.

Conventions (pronoun rule, pronoun-verification procedure,
gender-representation rule, personality-match rule, usage) are
defined in the upstream template's \`docs/AGENT_NAMES.md\`. This
file holds this project's mapping only.

| Canonical role       | Teammate name | Pronouns | Source (with date) |
|---|---|---|---|
| \`tech-lead\`          |               |          |                    |
| \`project-manager\`    |               |          |                    |
| \`architect\`          |               |          |                    |
| \`software-engineer\`  |               |          |                    |
| \`researcher\`         |               |          |                    |
| \`qa-engineer\`        |               |          |                    |
| \`sre\`                |               |          |                    |
| \`tech-writer\`        |               |          |                    |
| \`code-reviewer\`      |               |          |                    |
| \`release-engineer\`   |               |          |                    |

**SMEs** (added as per-project SME agents are created):

| Canonical role          | Teammate name | Pronouns | Source (with date) |
|---|---|---|---|
| \`sme-<domain>\`        |               |          |                    |

From Step 3 onward, \`tech-lead\` passes teammate names to the Agent
tool's \`name\` parameter so teammates appear on the agent-teams panel.
EOF

# --- Stamp TEMPLATE_VERSION --------------------------------------------------
cat > "$target/TEMPLATE_VERSION" <<EOF
$template_version
$template_sha
$today
EOF

# --- Seed empty .template-customizations -------------------------------------
cat > "$target/.template-customizations" <<'EOF'
# .template-customizations — one path per line (project-root-relative).
#
# Paths listed here are PERMANENTLY customized by this project. During
# scripts/upgrade.sh, they are:
#   - never overwritten with upstream content
#   - never flagged as conflicts
#   - reported as "preserved" in the upgrade summary
#
# Common candidates: .gitignore (if you added project-specific ignores),
# README.md (if you rewrote the project stub), docs/templates/<name>.md
# (if you adapted a template to your project's shape).
#
# SME agents (.claude/agents/sme-<domain>.md), all of docs/pm/*.md, and
# any other file the template does not ship are ALREADY preserved by
# default — they don't need to be listed here.
#
# Blank lines and lines starting with # are ignored.

EOF

# --- Replace template README with project stub -------------------------------
cat > "$target/README.md" <<EOF
# $project_name

Scaffolded from \`sw-dev-team-template\` $template_version
(commit \`$template_sha\`) on $today.

See \`CLAUDE.md\` for the multi-agent workflow and FIRST ACTIONS,
\`docs/INDEX.md\` for a table of contents, and \`docs/ISSUE_FILING.md\`
for how to file framework gaps back upstream.

Template version is recorded in \`TEMPLATE_VERSION\`.
EOF

# --- Init git (no initial commit; let the project owner do that) -------------
(
  cd "$target"
  git init -b main -q
  git add . >/dev/null
)

# --- Report -------------------------------------------------------------------
cat <<EOF

Scaffolded "$project_name" at: $target
  Template:  $template_version  ($template_sha)
  Stamped:   $today

Next steps (see $target/CLAUDE.md § FIRST ACTIONS):
  1. Step 1 — install skill packs.
  2. Step 2 — scoping: seed docs/OPEN_QUESTIONS.md from
     docs/templates/scoping-questions-template.md, then ask one
     question per turn with agents idle.
  3. Step 3 — agent naming: fill docs/AGENT_NAMES.md.
  4. Step 4 — issue-feedback opt-in: record in CUSTOMER_NOTES.md.
  5. Make the first git commit when scoping DoD is clean.
EOF
