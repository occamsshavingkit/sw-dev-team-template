#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# compile-runtime-agents.sh — compact runtime-contract compiler (M1.1)
# version: 0.3.0
#
# Reads canonical role files at .claude/agents/<role>.md, applies the
# section allowlist from schemas/agent-contract.schema.json, and writes
# a deterministic compact runtime contract to docs/runtime/agents/<role>.md.
#
# T054 scope: also writes a thin OpenCode adapter stub to
# .opencode/agents/<role>.md per FR-021 + research.md R-7. The adapter's
# model class is resolved from the binding default-class table in
# docs/model-routing-guidelines.md; unknown roles default to
# claude-sonnet with a stderr WARN. Pass --no-opencode-adapters to
# skip adapter generation (compact-runtime-only mode for self-tests).
#
# fw-adr-0022 scope: also writes a thin Gemini CLI adapter stub to
# .gemini/agents/<role>.md. The adapter's model class is resolved from
# the Gemini-equivalent column of the same binding table in
# docs/model-routing-guidelines.md. The Gemini adapter MUST include the
# description field (load-bearing for Gemini autonomous role selection).
# Pass --no-gemini-adapters to skip Gemini adapter generation.
#
# Codex scope: also writes a thin Codex adapter stub to
# .codex/agents/<role>.toml. The adapter resolves the OpenAI-equivalent
# class from the same binding table to a concrete Codex model ID so
# Codex-facing role files never expose Claude aliases such as `sonnet`
# or abstract OpenAI classes such as `openai-coding`.
# Pass --no-codex-adapters to skip Codex adapter generation.
#
# fw-adr-0026 Q-0033 scope: also writes Antigravity adapter files to
# .agents/skills/<role>/SKILL.md and .agents/agents/<role>/agent.json.
# toolNames is emitted as [] (passthrough) for all roles; a WARN is
# emitted per role with a non-empty tools: frontmatter line.
# Pass --no-antigravity-adapters to skip Antigravity adapter generation.
#
# Usage:
#   scripts/compile-runtime-agents.sh [--check] [--verify] [--strict] \
#                                     [--out-dir <path>] \
#                                     [--no-opencode-adapters] \
#                                     [--no-gemini-adapters] \
#                                     [--no-codex-adapters] \
#                                     [--no-antigravity-adapters] [role...]
#
# Inputs:
#   * Zero positional args -> walk every .claude/agents/*.md (excluding
#     sme-template.md and files whose basename is not alphanumeric/kebab).
#   * One or more role slugs -> compile only those.
#
# Flags:
#   --check         Validate inputs and report which canonical files
#                   exist; do not write outputs.
#   --verify        Read-only mode (T056 / FR-021): for each requested
#                   role, regenerate adapter + compact-runtime contract
#                   to a tempfile and `cmp -s` against the committed
#                   on-disk copy. Print `verify OK: <role>` for matches
#                   and `verify FAIL: <path> differs from generator
#                   output` for mismatches. Exit 0 if all clean, 1 if
#                   any drift, 2 on usage error. Never writes to the
#                   committed output paths.
#   --strict        Treat canonicals missing one or more required
#                   sections as a fatal error rather than a WARN.
#                   Default (without --strict): print a SKIP line per
#                   missing section to stderr, omit the compact runtime
#                   contract for that role, remove any stale runtime
#                   contract previously written for it, but still
#                   produce the OpenCode adapter (FR-021 only needs
#                   frontmatter + fixed body). Exit 0 unless a true
#                   error occurred (missing canonical, write failure,
#                   schema validation failure on a file that WAS
#                   generated). With --strict, missing-section
#                   conditions flip back to ERROR -> exit 1.
#   --out-dir <p>   Output directory (default: docs/runtime/agents).
#   --no-opencode-adapters
#                   Skip writing .opencode/agents/<role>.md adapters.
#                   Default behaviour generates both compact-runtime
#                   contracts and adapter stubs. In --verify mode this
#                   restricts verification to compact-runtime only.
#   --no-gemini-adapters
#                   Skip writing .gemini/agents/<role>.md adapters
#                   (fw-adr-0022). Default behaviour generates Gemini
#                   adapters alongside OpenCode adapters. In --verify
#                   mode this restricts verification to compact-runtime
#                   and OpenCode only.
#   --no-codex-adapters
#                   Skip writing .codex/agents/<role>.toml adapters.
#                   Default behaviour generates Codex adapters alongside
#                   OpenCode and Gemini. In --verify mode this restricts
#                   verification to compact-runtime, OpenCode, and Gemini.
#   --no-antigravity-adapters
#                   Skip writing .agents/skills/<role>/SKILL.md and
#                   .agents/agents/<role>/agent.json adapters
#                   (fw-adr-0026 Q-0033). Default behaviour generates
#                   Antigravity adapters alongside OpenCode and Gemini.
#                   In --verify mode this restricts verification to
#                   compact-runtime, OpenCode, and Gemini only.
#
# Section-heading mapping (canonical-slug <- accepted heading patterns,
# case-insensitive, whitespace-tolerant; punctuation/parentheticals
# stripped before comparison):
#   role_overview          : "role overview", "job", "two modes", "overview"
#   hard_rules             : "hard rules", "hard-block conditions",
#                            "enforcement", "constraints"
#   escalation             : "escalation", "escalation protocol",
#                            "escalation format", "hand-offs"
#   output_format          : "output", "output format",
#                            "customer-facing output discipline"
#   allowed_tools          : "allowed tools", "tools"
#   local_supplement_rule  : "project-specific local supplement",
#                            "local supplement"
#   customer_interface_rule: "customer interface",
#                            "customer-facing output discipline",
#                            "customer question gate"
#
# Determinism: same canonical inputs + same GENERATOR_VERSION ->
# byte-identical output. canonical_sha is read from the git index
# (git rev-parse HEAD:<path>), not the working tree.

set -eu
LANG=C
LC_ALL=C
export LANG LC_ALL

GENERATOR_VERSION="0.3.0"
GENERATOR_PATH="scripts/compile-runtime-agents.sh"
AGENTS_DIR=".claude/agents"
SCHEMA_DIR="schemas"
DEFAULT_OUT_DIR="docs/runtime/agents"
GENERATED_SCHEMA="${SCHEMA_DIR}/generated-artifact.schema.json"
OPENCODE_OUT_DIR=".opencode/agents"
OPENCODE_LOCAL_DIR=".opencode/agents/local"
GEMINI_OUT_DIR=".gemini/agents"
CODEX_OUT_DIR=".codex/agents"
ANTIGRAVITY_OUT_DIR=".agents"
ROUTING_DOC="docs/model-routing-guidelines.md"
DEFAULT_MODEL_CLASS="claude-sonnet"
DEFAULT_GEMINI_MODEL_CLASS="gemini-pro"
DEFAULT_CODEX_MODEL_CLASS="openai-coding"
DEFAULT_CODEX_MODEL_ID="gpt-5.4"

# ---- ANTIGRAVITY_TOOLS_MAP -------------------------------------------
# Maps role-slug -> toolNames array for agent.json emission.
# Absent = passthrough (toolNames: []). Add entries when Antigravity
# tool-name vocabulary is confirmed from a Tier-1 source (Q-0033 open
# sub-point 3). Currently empty; generator emits [] for all roles and
# warns for each role whose .claude/agents/<role>.md has a non-empty
# tools: frontmatter line.
# Example entry: ANTIGRAVITY_TOOLS_MAP_tech_lead='["Read","Write"]'
# (role slug with hyphens replaced by underscores).

# ---- arg parsing -----------------------------------------------------
CHECK_MODE=0
VERIFY_MODE=0
STRICT_MODE=0
REPRO_MODE=0
OUT_DIR="${DEFAULT_OUT_DIR}"
ROLES=""
NO_OPENCODE_ADAPTERS=0
NO_GEMINI_ADAPTERS=0
NO_CODEX_ADAPTERS=0
NO_ANTIGRAVITY_ADAPTERS=0

while [ $# -gt 0 ]; do
  case "$1" in
    --check)
      CHECK_MODE=1
      shift
      ;;
    --verify)
      VERIFY_MODE=1
      shift
      ;;
    --reproducibility-check)
      # T061 / SC-007: run two independent compilations and cmp them
      # byte-for-byte. Verifies the compiler itself is deterministic
      # (complement of --verify, which checks committed-vs-fresh).
      # Handled below the arg-parse loop as a wrapper around the
      # ordinary entry-point so the core compile logic stays
      # untouched.
      REPRO_MODE=1
      shift
      ;;
    --strict)
      STRICT_MODE=1
      shift
      ;;
    --out-dir)
      if [ $# -lt 2 ]; then
        echo "compile-runtime-agents: --out-dir requires a path" >&2
        exit 2
      fi
      OUT_DIR="$2"
      shift 2
      ;;
    --out-dir=*)
      OUT_DIR="${1#--out-dir=}"
      shift
      ;;
    --no-opencode-adapters)
      NO_OPENCODE_ADAPTERS=1
      shift
      ;;
    --no-gemini-adapters)
      NO_GEMINI_ADAPTERS=1
      shift
      ;;
    --no-codex-adapters)
      NO_CODEX_ADAPTERS=1
      shift
      ;;
    --no-antigravity-adapters)
      NO_ANTIGRAVITY_ADAPTERS=1
      shift
      ;;
    -h|--help)
      sed -n '2,71p' "$0"
      exit 0
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        ROLES="${ROLES} $1"
        shift
      done
      ;;
    -*)
      echo "compile-runtime-agents: unknown flag: $1" >&2
      exit 2
      ;;
    *)
      ROLES="${ROLES} $1"
      shift
      ;;
  esac
done

# ---- locate sub-repo root -------------------------------------------
# Resolve relative to this script's parent dir (scripts/..).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

if [ ! -d "${AGENTS_DIR}" ]; then
  echo "compile-runtime-agents: ${AGENTS_DIR} not found under ${REPO_ROOT}" >&2
  exit 2
fi

# ---- check-jsonschema resolution ------------------------------------
CHECK_JSONSCHEMA=""
resolve_check_jsonschema() {
  if command -v check-jsonschema >/dev/null 2>&1; then
    CHECK_JSONSCHEMA="check-jsonschema"
    return 0
  fi
  fallback="${HOME}/.local/share/check-jsonschema-venv/bin/check-jsonschema"
  if [ -x "${fallback}" ]; then
    CHECK_JSONSCHEMA="${fallback}"
    return 0
  fi
  return 1
}

# ---- expand role list ------------------------------------------------
# Trim leading whitespace from ROLES.
ROLES="$(printf '%s' "${ROLES}" | sed 's/^ *//')"

if [ -z "${ROLES}" ]; then
  # Zero-arg mode: walk .claude/agents/*.md, lexically sorted.
  ROLES="$(
    ls "${AGENTS_DIR}" 2>/dev/null \
      | grep '\.md$' \
      | sed 's/\.md$//' \
      | grep -E '^[a-z0-9][a-z0-9-]*$' \
      | grep -v '^sme-template$' \
      | LC_ALL=C sort
  )"
fi

if [ -z "${ROLES}" ]; then
  echo "compile-runtime-agents: no roles to process" >&2
  exit 2
fi

# ---- reproducibility-check mode (T061 / SC-007) ---------------------
# Run two independent fresh compilations into separate scratch dirs and
# cmp them byte-for-byte. Verifies that the compiler is deterministic
# (the canonical_sha is read from the git index, not the working tree,
# so determinism reduces to: same inputs + same GENERATOR_VERSION ->
# byte-identical outputs). Intended for CI; complements --verify, which
# instead asserts committed-vs-fresh equality.
#
# Behaviour:
#   * Compile each requested role into tempdir A.
#   * Compile each requested role into tempdir B (separate workdir).
#   * For each role, cmp -s the compact runtime contract AND the
#     OpenCode adapter (when adapter generation is enabled).
#   * Print 'reproducibility OK: <role>' on per-role match, or
#     'reproducibility FAIL: <role> -- diff at <path>' on mismatch.
#   * Exit 0 iff all roles match.
#
# A role that has no compact-runtime contract (incomplete canonical in
# default-WARN mode) still has its adapter checked; the OK line is
# emitted as long as whatever artefacts WERE produced match.
if [ "${REPRO_MODE}" -eq 1 ]; then
  if [ "${CHECK_MODE}" -eq 1 ] || [ "${VERIFY_MODE}" -eq 1 ]; then
    echo "compile-runtime-agents: --reproducibility-check is mutually exclusive with --check / --verify" >&2
    exit 2
  fi

  REPRO_A="$(mktemp -d)"
  REPRO_B="$(mktemp -d)"
  trap 'rm -rf "${REPRO_A}" "${REPRO_B}"' EXIT INT TERM

  # Use the script path captured at startup. Each invocation is a fresh
  # shell process with its own working state, satisfying R-VR-1's
  # "two independent compilations" requirement.
  SELF="$0"

  repro_args_a="--out-dir ${REPRO_A}/runtime"
  repro_args_b="--out-dir ${REPRO_B}/runtime"
  if [ "${STRICT_MODE}" -eq 1 ]; then
    repro_args_a="${repro_args_a} --strict"
    repro_args_b="${repro_args_b} --strict"
  fi
  if [ "${NO_OPENCODE_ADAPTERS}" -eq 1 ]; then
    repro_args_a="${repro_args_a} --no-opencode-adapters"
    repro_args_b="${repro_args_b} --no-opencode-adapters"
  fi
  if [ "${NO_GEMINI_ADAPTERS}" -eq 1 ]; then
    repro_args_a="${repro_args_a} --no-gemini-adapters"
    repro_args_b="${repro_args_b} --no-gemini-adapters"
  fi
  if [ "${NO_CODEX_ADAPTERS}" -eq 1 ]; then
    repro_args_a="${repro_args_a} --no-codex-adapters"
    repro_args_b="${repro_args_b} --no-codex-adapters"
  fi
  if [ "${NO_ANTIGRAVITY_ADAPTERS}" -eq 1 ]; then
    repro_args_a="${repro_args_a} --no-antigravity-adapters"
    repro_args_b="${repro_args_b} --no-antigravity-adapters"
  fi

  # OPENCODE_OUT_DIR is read from the script's own default; we need to
  # override it for the two compilations so adapters land in the
  # scratch dirs, not in the committed .opencode/agents/ path. We do
  # this by exporting an environment override and consuming it at the
  # top of the script's main body. The simpler path used here: redirect
  # via a wrapping shell that pre-sets the script's OPENCODE_OUT_DIR
  # via a chdir-equivalent. Since the compiler hard-codes
  # OPENCODE_OUT_DIR=".opencode/agents", we instead chdir each
  # invocation into a tree rooted at the scratch dir that symlinks the
  # canonical inputs and routing doc.

  mkdir -p "${REPRO_A}/root/.claude/agents" "${REPRO_B}/root/.claude/agents"
  mkdir -p "${REPRO_A}/root/scripts" "${REPRO_B}/root/scripts"
  mkdir -p "${REPRO_A}/root/schemas" "${REPRO_B}/root/schemas"
  mkdir -p "${REPRO_A}/root/docs" "${REPRO_B}/root/docs"

  # Mirror the inputs the compiler reads into each scratch root via
  # hardlinks (no-op for filesystems that don't support links: fall
  # back to copy). Inputs are read-only from the compiler's POV.
  copy_or_link() {
      src_path="$1"; dst_path="$2"
      [ -e "${src_path}" ] || return 0
      mkdir -p "$(dirname "${dst_path}")"
      if ! ln "${src_path}" "${dst_path}" 2>/dev/null; then
          cp "${src_path}" "${dst_path}"
      fi
  }

  for root in "${REPRO_A}/root" "${REPRO_B}/root"; do
      # canonical agents
      for f in "${AGENTS_DIR}"/*.md; do
          [ -f "${f}" ] || continue
          copy_or_link "${f}" "${root}/${f}"
      done
      # schemas
      for f in "${SCHEMA_DIR}"/*.json; do
          [ -f "${f}" ] || continue
          copy_or_link "${f}" "${root}/${f}"
      done
      # routing doc
      copy_or_link "${ROUTING_DOC}" "${root}/${ROUTING_DOC}"
      # the compiler script itself, so $0 resolution inside the child
      # picks up the right SCRIPT_DIR / REPO_ROOT.
      copy_or_link "${SELF}" "${root}/scripts/compile-runtime-agents.sh"
      chmod +x "${root}/scripts/compile-runtime-agents.sh"
      # The child also needs a .git pointer for canonical_sha resolution.
      # Symlink the original .git into each scratch root (read-only ref).
      if [ -d ".git" ]; then
          ln -s "$(pwd)/.git" "${root}/.git" 2>/dev/null || true
      fi
  done

  # Build positional role-list string for the child invocations.
  # Each role name is validated against a strict charset; we still
  # carry the list as a space-separated string and re-split inside
  # the subshells with `set --` so the child sees clean positional
  # parameters (quoted "$@") rather than relying on unquoted
  # word-splitting.
  repro_roles=""
  for r in ${ROLES}; do
      case "${r}" in
          *[!a-z0-9-]*|"") continue ;;
      esac
      repro_roles="${repro_roles} ${r}"
  done

  # Run both compilations. Stderr passes through so users see the
  # compiler's own diagnostics (SKIP / WARN lines).
  (
      cd "${REPRO_A}/root"
      # Re-split validated role list into positional parameters so the
      # child invocation uses quoted "$@" (no unquoted expansion).
      # shellcheck disable=SC2086  # deliberate word-split of validated role list into positional params
      # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-variable-expansion-in-command  # deliberate word-split; roles are validated above
      set -- ${repro_roles}
      sh scripts/compile-runtime-agents.sh "$@" >/dev/null
  ) || true
  (
      cd "${REPRO_B}/root"
      # shellcheck disable=SC2086  # deliberate word-split of validated role list into positional params
      # nosemgrep: bash.lang.correctness.unquoted-expansion.unquoted-variable-expansion-in-command  # deliberate word-split; roles are validated above
      set -- ${repro_roles}
      sh scripts/compile-runtime-agents.sh "$@" >/dev/null
  ) || true

  repro_status=0
  for r in ${repro_roles}; do
      role_ok=1

      a_runtime="${REPRO_A}/root/${DEFAULT_OUT_DIR}/${r}.md"
      b_runtime="${REPRO_B}/root/${DEFAULT_OUT_DIR}/${r}.md"
      if [ -f "${a_runtime}" ] || [ -f "${b_runtime}" ]; then
          if [ ! -f "${a_runtime}" ] || [ ! -f "${b_runtime}" ]; then
              echo "reproducibility FAIL: ${r} -- diff at ${a_runtime} (one side missing)"
              role_ok=0
              repro_status=1
          elif ! cmp -s "${a_runtime}" "${b_runtime}"; then
              echo "reproducibility FAIL: ${r} -- diff at ${a_runtime}"
              role_ok=0
              repro_status=1
          fi
      fi

      if [ "${NO_OPENCODE_ADAPTERS}" -eq 0 ]; then
          a_op="${REPRO_A}/root/${OPENCODE_OUT_DIR}/${r}.md"
          b_op="${REPRO_B}/root/${OPENCODE_OUT_DIR}/${r}.md"
          if [ -f "${a_op}" ] || [ -f "${b_op}" ]; then
              if [ ! -f "${a_op}" ] || [ ! -f "${b_op}" ]; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_op} (one side missing)"
                  role_ok=0
                  repro_status=1
              elif ! cmp -s "${a_op}" "${b_op}"; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_op}"
                  role_ok=0
                  repro_status=1
              fi
          fi
      fi

      if [ "${NO_GEMINI_ADAPTERS}" -eq 0 ]; then
          a_gm="${REPRO_A}/root/${GEMINI_OUT_DIR}/${r}.md"
          b_gm="${REPRO_B}/root/${GEMINI_OUT_DIR}/${r}.md"
          if [ -f "${a_gm}" ] || [ -f "${b_gm}" ]; then
              if [ ! -f "${a_gm}" ] || [ ! -f "${b_gm}" ]; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_gm} (one side missing)"
                  role_ok=0
                  repro_status=1
              elif ! cmp -s "${a_gm}" "${b_gm}"; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_gm}"
                  role_ok=0
                  repro_status=1
              fi
          fi
      fi

      if [ "${NO_CODEX_ADAPTERS}" -eq 0 ]; then
          a_cd="${REPRO_A}/root/${CODEX_OUT_DIR}/${r}.toml"
          b_cd="${REPRO_B}/root/${CODEX_OUT_DIR}/${r}.toml"
          if [ -f "${a_cd}" ] || [ -f "${b_cd}" ]; then
              if [ ! -f "${a_cd}" ] || [ ! -f "${b_cd}" ]; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_cd} (one side missing)"
                  role_ok=0
                  repro_status=1
              elif ! cmp -s "${a_cd}" "${b_cd}"; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_cd}"
                  role_ok=0
                  repro_status=1
              fi
          fi
      fi

      if [ "${NO_ANTIGRAVITY_ADAPTERS}" -eq 0 ]; then
          a_sk="${REPRO_A}/root/${ANTIGRAVITY_OUT_DIR}/skills/${r}/SKILL.md"
          b_sk="${REPRO_B}/root/${ANTIGRAVITY_OUT_DIR}/skills/${r}/SKILL.md"
          if [ -f "${a_sk}" ] || [ -f "${b_sk}" ]; then
              if [ ! -f "${a_sk}" ] || [ ! -f "${b_sk}" ]; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_sk} (one side missing)"
                  role_ok=0
                  repro_status=1
              elif ! cmp -s "${a_sk}" "${b_sk}"; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_sk}"
                  role_ok=0
                  repro_status=1
              fi
          fi
          a_aj="${REPRO_A}/root/${ANTIGRAVITY_OUT_DIR}/agents/${r}/agent.json"
          b_aj="${REPRO_B}/root/${ANTIGRAVITY_OUT_DIR}/agents/${r}/agent.json"
          if [ -f "${a_aj}" ] || [ -f "${b_aj}" ]; then
              if [ ! -f "${a_aj}" ] || [ ! -f "${b_aj}" ]; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_aj} (one side missing)"
                  role_ok=0
                  repro_status=1
              elif ! cmp -s "${a_aj}" "${b_aj}"; then
                  echo "reproducibility FAIL: ${r} -- diff at ${a_aj}"
                  role_ok=0
                  repro_status=1
              fi
          fi
      fi

      if [ "${role_ok}" -eq 1 ]; then
          echo "reproducibility OK: ${r}"
      fi
  done

  exit "${repro_status}"
fi

# ---- verify-mode setup ----------------------------------------------
# In verify mode, redirect outputs to a scratch dir; capture the
# committed paths first so we can cmp after generation. The committed
# paths are NEVER written in verify mode.
VERIFY_SCRATCH=""
VERIFY_COMMITTED_RUNTIME=""
VERIFY_COMMITTED_OPENCODE=""
VERIFY_COMMITTED_GEMINI=""
VERIFY_COMMITTED_CODEX=""
if [ "${VERIFY_MODE}" -eq 1 ]; then
  if [ "${CHECK_MODE}" -eq 1 ]; then
    echo "compile-runtime-agents: --verify and --check are mutually exclusive" >&2
    exit 2
  fi
  VERIFY_SCRATCH="$(mktemp -d)"
  VERIFY_COMMITTED_RUNTIME="${OUT_DIR}"
  VERIFY_COMMITTED_OPENCODE="${OPENCODE_OUT_DIR}"
  VERIFY_COMMITTED_GEMINI="${GEMINI_OUT_DIR}"
  VERIFY_COMMITTED_CODEX="${CODEX_OUT_DIR}"
  VERIFY_COMMITTED_ANTIGRAVITY="${ANTIGRAVITY_OUT_DIR}"
  OUT_DIR="${VERIFY_SCRATCH}/runtime"
  OPENCODE_OUT_DIR="${VERIFY_SCRATCH}/opencode"
  GEMINI_OUT_DIR="${VERIFY_SCRATCH}/gemini"
  CODEX_OUT_DIR="${VERIFY_SCRATCH}/codex"
  ANTIGRAVITY_OUT_DIR="${VERIFY_SCRATCH}/antigravity"
  mkdir -p "${OUT_DIR}" "${OPENCODE_OUT_DIR}" "${GEMINI_OUT_DIR}" "${CODEX_OUT_DIR}" "${ANTIGRAVITY_OUT_DIR}"
  # Trap cleanup; preserved across compile_role's own EXIT trap usage
  # by being installed last and re-installing after each compile.
fi

verify_cleanup() {
  if [ -n "${VERIFY_SCRATCH}" ] && [ -d "${VERIFY_SCRATCH}" ]; then
    rm -rf "${VERIFY_SCRATCH}"
  fi
}

# ---- helpers ---------------------------------------------------------

# Normalize a heading text to a comparison token: lowercase, strip
# parentheticals, collapse non-alphanumerics to single spaces, trim.
normalize_heading() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/([^)]*)//g' \
          -e 's/[^a-z0-9]\{1,\}/ /g' \
          -e 's/^ *//' \
          -e 's/ *$//'
}

# Map a normalized heading to a canonical slug. Echoes the slug, or
# empty string if no match (section is dropped by allowlist).
map_section() {
  norm="$1"
  case "${norm}" in
    "role overview"|"job"|"two modes"|"overview")
      echo "role_overview" ;;
    "hard rules"|"hard block conditions"|"enforcement"|"constraints")
      echo "hard_rules" ;;
    "escalation"|"escalation protocol"|"escalation format"|"hand offs"|"handoffs")
      echo "escalation" ;;
    "output"|"output format"|"customer facing output discipline")
      # "customer facing output discipline" also satisfies
      # customer_interface_rule; the section is retained once and
      # counted for both slots.
      echo "output_format" ;;
    "allowed tools"|"tools")
      echo "allowed_tools" ;;
    "project specific local supplement"|"local supplement"|"local supplement rule")
      echo "local_supplement_rule" ;;
    "customer interface"|"customer interface rule"|"customer question gate")
      echo "customer_interface_rule" ;;
    *)
      echo "" ;;
  esac
}

# Required slugs per agent-contract.schema.json sections.required.
REQUIRED_SLUGS="role_overview hard_rules escalation output_format"

# ---- frontmatter / section parser (awk) -----------------------------
# Produces a TSV stream describing the canonical file:
#   FM<TAB>name<TAB><value>
#   FM<TAB>description<TAB><value>
#   FM<TAB>model<TAB><value>
#   FM<TAB>tools<TAB><value>
#   SEC<TAB><heading><TAB><line_start>
# The body bytes for each section live in numbered temp files written
# by the awk script.
parse_canonical() {
  src="$1"
  workdir="$2"
  awk -v workdir="${workdir}" '
    BEGIN {
      state = "pre"
      sec_n = 0
    }
    function flush_sec() {
      if (sec_n > 0) close(workdir "/sec." sec_n)
    }
    {
      if (state == "pre") {
        if ($0 == "---") { state = "fm"; next }
        # No frontmatter -> bail.
        state = "body"
      }
      if (state == "fm") {
        if ($0 == "---") { state = "body"; next }
        # YAML key: value (shallow; no nested maps expected).
        line = $0
        # Strip leading spaces.
        sub(/^[ \t]+/, "", line)
        if (line ~ /^name[ \t]*:/) {
          val = line; sub(/^name[ \t]*:[ \t]*/, "", val)
          gsub(/^"|"$/, "", val); gsub(/^'\''|'\''$/, "", val)
          print "FM\tname\t" val
        } else if (line ~ /^description[ \t]*:/) {
          val = line; sub(/^description[ \t]*:[ \t]*/, "", val)
          gsub(/^"|"$/, "", val); gsub(/^'\''|'\''$/, "", val)
          print "FM\tdescription\t" val
        } else if (line ~ /^model[ \t]*:/) {
          val = line; sub(/^model[ \t]*:[ \t]*/, "", val)
          gsub(/^"|"$/, "", val); gsub(/^'\''|'\''$/, "", val)
          print "FM\tmodel\t" val
        } else if (line ~ /^tools[ \t]*:/) {
          val = line; sub(/^tools[ \t]*:[ \t]*/, "", val)
          gsub(/^"|"$/, "", val); gsub(/^'\''|'\''$/, "", val)
          print "FM\ttools\t" val
        }
        next
      }
      # state == body
      if ($0 ~ /^## /) {
        flush_sec()
        sec_n++
        heading = $0
        sub(/^## /, "", heading)
        # Trim trailing whitespace.
        sub(/[ \t]+$/, "", heading)
        print "SEC\t" heading "\t" sec_n
        # body file starts empty; lines after this go in.
        printf "" > (workdir "/sec." sec_n)
        next
      }
      if (sec_n > 0) {
        print $0 >> (workdir "/sec." sec_n)
      }
    }
    END { flush_sec() }
  ' "${src}"
}

# ---- per-role compile -----------------------------------------------
overall_status=0
schema_warned=0

# Pre-resolve check-jsonschema only when we actually need to validate.
maybe_validate_output() {
  out_path="$1"
  if [ ! -f "${GENERATED_SCHEMA}" ]; then
    if [ "${schema_warned}" -eq 0 ]; then
      echo "WARN: generated-artifact schema not yet present; skipping output validation (will land at T059)" >&2
      schema_warned=1
    fi
    return 0
  fi
  if [ -z "${CHECK_JSONSCHEMA}" ]; then
    if ! resolve_check_jsonschema; then
      echo "compile-runtime-agents: check-jsonschema not found on PATH or at ${HOME}/.local/share/check-jsonschema-venv/bin/" >&2
      return 1
    fi
  fi
  # Extract frontmatter into a JSON doc and validate.
  tmpjson="$(mktemp)"
  # Use Python for proper YAML→JSON conversion (handles nested objects
  # like OpenCode's permission: map).
  if command -v python3 >/dev/null 2>&1; then
    python3 -c '
import sys, json, yaml
with open(sys.argv[1]) as f:
    parts = f.read().split("---")
    if len(parts) >= 3:
        fm = yaml.safe_load(parts[1])
        json.dump(fm, sys.stdout, default=str)
' "${out_path}" > "${tmpjson}" 2>/dev/null
  else
    # Fallback: extract flat YAML frontmatter with awk (no nested support).
    fm_yaml="$(awk '
      BEGIN { state = "pre" }
      {
        if (state == "pre") {
          if ($0 == "---") { state = "fm"; next }
          exit
        }
        if (state == "fm") {
          if ($0 == "---") { exit }
          print $0
        }
      }
    ' "${out_path}")"
    # WARN: awk fallback cannot handle YAML block scalars (description: |)
    # or nested maps (permission:). Skip validation to avoid false failures.
    if echo "${fm_yaml}" | grep -qE '^[a-zA-Z_][a-zA-Z0-9_]*:[ \t]*\|' \
      || echo "${fm_yaml}" | grep -qE '^permission:'; then
      echo "compile-runtime-agents: WARN: awk fallback cannot validate ${out_path} (block scalars or nested maps); skipping validation" >&2
      return 0
    fi
    echo "${fm_yaml}" \
      | awk '
          BEGIN { print "{" ; first = 1 }
          /^[a-zA-Z_][a-zA-Z0-9_]*[ \t]*:/ {
            k = $0; sub(/[ \t]*:.*$/, "", k)
            v = $0; sub(/^[^:]*:[ \t]*/, "", v)
            gsub(/\\/, "\\\\", v); gsub(/"/, "\\\"", v)
            if (!first) printf ",\n"; first = 0
            printf "  \"%s\": \"%s\"", k, v
          }
          END { printf "\n}\n" }
        ' > "${tmpjson}"
  fi
  if ! "${CHECK_JSONSCHEMA}" --schemafile "${GENERATED_SCHEMA}" "${tmpjson}" >/dev/null 2>&1; then
    rm -f "${tmpjson}"
    echo "compile-runtime-agents: output frontmatter failed schema validation: ${out_path}" >&2
    return 1
  fi
  rm -f "${tmpjson}"
  return 0
}

# ---- model-class resolver -------------------------------------------
# Look up the role's default class in docs/model-routing-guidelines.md.
# Only scans rows under the "## Binding per-agent default-class table"
# heading, since other tables in the doc (e.g., role-defaults / tier
# table) share the `agent` | `value` | shape but carry tier names, not
# class names. The binding table rows look like:
#   | `tech-lead` | `claude-sonnet` | unresolved conflict, ... |
# Emit the class on stdout; emit empty string if not found.
resolve_model_class() {
  role_slug="$1"
  if [ ! -f "${ROUTING_DOC}" ]; then
    echo ""
    return 0
  fi
  awk -v role="${role_slug}" '
    BEGIN { FS = "|"; in_table = 0 }
    /^##[ \t]+Binding per-agent default-class table/ { in_table = 1; next }
    /^##[ \t]+/ { if (in_table) in_table = 0 }
    in_table == 0 { next }
    /^\|[ \t]*`[a-z0-9-]+`[ \t]*\|[ \t]*`[a-z0-9-]+`[ \t]*\|/ {
      agent = $2
      gsub(/^[ \t]+|[ \t]+$/, "", agent)
      gsub(/`/, "", agent)
      if (agent == role) {
        cls = $3
        gsub(/^[ \t]+|[ \t]+$/, "", cls)
        gsub(/`/, "", cls)
        print cls
        exit
      }
    }
  ' "${ROUTING_DOC}"
}

# ---- gemini model-class resolver ------------------------------------
# Like resolve_model_class but reads column 6 (Gemini equivalent) of the
# binding table instead of column 3 (default_class / Claude equivalent).
resolve_gemini_model_class() {
  role_slug="$1"
  if [ ! -f "${ROUTING_DOC}" ]; then
    echo ""
    return 0
  fi
  awk -v role="${role_slug}" '
    BEGIN { FS = "|"; in_table = 0 }
    /^##[ \t]+Binding per-agent default-class table/ { in_table = 1; next }
    /^##[ \t]+/ { if (in_table) in_table = 0 }
    in_table == 0 { next }
    /^\|[ \t]*`[a-z0-9-]+`[ \t]*\|[ \t]*`[a-z0-9-]+`[ \t]*\|/ {
      agent = $2
      gsub(/^[ \t]+|[ \t]+$/, "", agent)
      gsub(/`/, "", agent)
      if (agent == role) {
        cls = $6
        gsub(/^[ \t]+|[ \t]+$/, "", cls)
        gsub(/`/, "", cls)
        print cls
        exit
      }
    }
  ' "${ROUTING_DOC}"
}

# ---- codex model resolver -------------------------------------------
# Like resolve_model_class but reads column 5 (OpenAI equivalent) of the
# binding table. This is the Codex-facing class abstraction; canonical
# .claude/agents files intentionally keep Claude Code aliases.
resolve_codex_model_class() {
  role_slug="$1"
  if [ ! -f "${ROUTING_DOC}" ]; then
    echo ""
    return 0
  fi
  awk -v role="${role_slug}" '
    BEGIN { FS = "|"; in_table = 0 }
    /^##[ \t]+Binding per-agent default-class table/ { in_table = 1; next }
    /^##[ \t]+/ { if (in_table) in_table = 0 }
    in_table == 0 { next }
    /^\|[ \t]*`[a-z0-9-]+`[ \t]*\|[ \t]*`[a-z0-9-]+`[ \t]*\|/ {
      agent = $2
      gsub(/^[ \t]+|[ \t]+$/, "", agent)
      gsub(/`/, "", agent)
      if (agent == role) {
        cls = $5
        gsub(/^[ \t]+|[ \t]+$/, "", cls)
        gsub(/`/, "", cls)
        print cls
        exit
      }
    }
  ' "${ROUTING_DOC}"
}

# Resolve the Codex-facing OpenAI class abstraction to a concrete model
# slug accepted by the active Codex typed-role loader. Keep the binding
# table abstract; only generated .codex/agents frontmatter gets slugs.
resolve_codex_model_id() {
  model_class="$1"
  case "${model_class}" in
    openai-mini) echo "gpt-5.4-mini" ;;
    openai-coding) echo "gpt-5.4" ;;
    openai-frontier) echo "gpt-5.5" ;;
    *)
      echo ""
      return 1
      ;;
  esac
}

# ---- opencode adapter writer ----------------------------------------
# Writes .opencode/agents/<role>.md with full role instructions adapted
# from the canonical .claude/agents/<role>.md. Embeds the body content
# directly so OpenCode subagents receive their role contract as a system
# prompt.
#
# Permission mapping from canonical tools: to opencode keys:
#   Read   → read
#   Write,Edit → edit
#   Grep   → grep
#   Glob   → glob
#   Bash   → bash
#   WebSearch → websearch
#   WebFetch  → webfetch
# All subagents get task:deny and question:deny (only tech-lead spawns/asks).
#
# canonical_sha is the same 40-hex value already resolved for the
# compact-runtime contract. fm_desc and fm_tools come from the parse
# pass in the main compile loop.
write_opencode_adapter() {
  role="$1"
  canonical_src="$2"
  canonical_sha="$3"
  fm_desc="$4"
  fm_tools="$5"

  mkdir -p "${OPENCODE_OUT_DIR}"
  out_path="${OPENCODE_OUT_DIR}/${role}.md"
  tmp_out="${out_path}.tmp"

  # Build the permission map from canonical tools.
  perm_read="deny"
  perm_edit="deny"
  perm_grep="deny"
  perm_glob="deny"
  perm_bash="deny"
  perm_websearch="deny"
  perm_webfetch="deny"

  if [ -n "${fm_tools}" ]; then
    # Normalize: lowercase, replace commas with spaces, collapse whitespace.
    tools_norm="$(printf '%s' "${fm_tools}" | tr '[:upper:]' '[:lower:]' | tr ',' ' ' | sed 's/  */ /g')"
    case " ${tools_norm} " in
      *" read "*)    perm_read="allow" ;;
    esac
    case " ${tools_norm} " in
      *" write "*|*" edit "*) perm_edit="allow" ;;
    esac
    case " ${tools_norm} " in
      *" grep "*)    perm_grep="allow" ;;
    esac
    case " ${tools_norm} " in
      *" glob "*)    perm_glob="allow" ;;
    esac
    case " ${tools_norm} " in
      *" bash "*)    perm_bash="allow" ;;
    esac
    case " ${tools_norm} " in
      *" websearch "*) perm_websearch="allow" ;;
    esac
    case " ${tools_norm} " in
      *" webfetch "*) perm_webfetch="allow" ;;
    esac
  fi

  # Write frontmatter with description, mode, permissions.
  {
    printf -- '---\n'
    printf 'name: %s\n' "${role}"
    if [ -n "${fm_desc}" ]; then
      # YAML-safe: use literal block scalar (|) to avoid quoting issues
      # with descriptions containing colons, quotes, or special chars.
      printf 'description: |\n'
      printf '  %s\n' "${fm_desc}"
    fi
    printf 'mode: subagent\n'
    printf 'permission:\n'
    printf '  read: %s\n' "${perm_read}"
    printf '  edit: %s\n' "${perm_edit}"
    printf '  grep: %s\n' "${perm_grep}"
    printf '  glob: %s\n' "${perm_glob}"
    printf '  bash: %s\n' "${perm_bash}"
    printf '  websearch: %s\n' "${perm_websearch}"
    printf '  webfetch: %s\n' "${perm_webfetch}"
    printf '  task: deny\n'
    printf '  question: deny\n'
    printf '  todowrite: deny\n'
    printf '  skill: deny\n'
    printf 'canonical_source: %s\n' "${canonical_src}"
    printf 'canonical_sha: %s\n' "${canonical_sha}"
    printf 'generator: %s\n' "${GENERATOR_PATH}"
    printf 'generator_version: %s\n' "${GENERATOR_VERSION}"
    printf 'classification: generated\n'
    printf -- '---\n'
    printf '\n'
    # Embed the canonical body content (everything after the frontmatter).
    # Strip the leading ---...--- block and emit the role instructions.
    awk '
      BEGIN { in_body = 0; fm_end = 0 }
      /^---$/ {
        if (fm_end == 0) { fm_end = 1; next }
        if (fm_end == 1) { in_body = 1; next }
      }
      { if (in_body && $0 !~ /^---$/) print }
    ' "${canonical_src}"
  } > "${tmp_out}"

  mv "${tmp_out}" "${out_path}"

  if ! maybe_validate_output "${out_path}"; then
    overall_status=1
  fi
}

# ---- codex adapter writer -------------------------------------------
# Writes .codex/agents/<role>.toml with the fields consumed by Codex
# typed-role loading. The model value must resolve the OpenAI equivalent column to a
# concrete Codex model slug, not copy .claude/agents/<role>.md or the
# abstract class, because Codex typed-role loading validates concrete
# model IDs before agent creation.
write_codex_adapter() {
  role="$1"
  canonical_src="$2"
  canonical_sha="$3"
  canonical_desc="$4"

  codex_model_class="$(resolve_codex_model_class "${role}")"
  if [ -z "${codex_model_class}" ]; then
    echo "compile-runtime-agents: ${role} not in routing table (OpenAI col), defaulting to ${DEFAULT_CODEX_MODEL_CLASS}" >&2
    codex_model_class="${DEFAULT_CODEX_MODEL_CLASS}"
  fi
  codex_model="$(resolve_codex_model_id "${codex_model_class}" || true)"
  if [ -z "${codex_model}" ]; then
    echo "compile-runtime-agents: ${role} has unsupported Codex model class ${codex_model_class}, defaulting to ${DEFAULT_CODEX_MODEL_ID}" >&2
    codex_model="${DEFAULT_CODEX_MODEL_ID}"
  fi

  mkdir -p "${CODEX_OUT_DIR}"
  out_path="${CODEX_OUT_DIR}/${role}.toml"
  tmp_out="${out_path}.tmp"

  # TOML basic-string escaper for single-line scalar values.
  toml_dq_esc() {
    awk 'BEGIN{ORS=""}
    {
      s = $0
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      gsub(/\t/, "\\t",  s)
      gsub(/\r/, "\\r",  s)
      if (NR > 1) printf "\\n"
      printf "%s", s
    }'
  }

  esc_desc="$(printf '%s' "${canonical_desc}" | toml_dq_esc)"

  {
    printf 'description = "%s"\n' "${esc_desc}"
    printf 'model = "%s"\n' "${codex_model}"
    printf 'developer_instructions = """\n'
    # Guard: check canonical body for """ which would break the TOML
    # multi-line basic string. If found, emit a WARN and write a pointer
    # stub instead (the body cannot be safely embedded in TOML).
    if grep -q '"""' "${canonical_src}"; then
      echo "compile-runtime-agents: WARN: ${role}: canonical body contains \"\"\" — cannot embed in TOML basic string; writing pointer stub" >&2
      printf 'Read `.claude/agents/%s.md` (canonical role contract).\n' "${role}"
      printf 'If `.claude/agents/%s-local.md` exists, read it after the canonical file.\n' "${role}"
      printf 'Act only as that role.\n'
      printf "Return output in the role's required format.\n"
    else
      awk '
        BEGIN { in_body = 0; fm_end = 0 }
        /^---$/ {
          if (fm_end == 0) { fm_end = 1; next }
          if (fm_end == 1) { in_body = 1; next }
        }
        { if (in_body && $0 !~ /^---$/) print }
      ' "${canonical_src}"
    fi
    printf '"""\n'
    printf 'name = "%s"\n' "${role}"
  } > "${tmp_out}"

  mv "${tmp_out}" "${out_path}"
}

# ---- gemini adapter writer ------------------------------------------
# Writes .gemini/agents/<role>.md with frontmatter + the fixed
# four-line body (same thin-adapter shape as opencode). Key differences
# from the opencode adapter (per fw-adr-0022 §2):
#   - description field is REQUIRED (load-bearing for Gemini autonomous
#     role selection); copied verbatim from the canonical frontmatter.
#   - model comes from the Gemini-equivalent column of the binding table,
#     not default_class.
write_gemini_adapter() {
  role="$1"
  canonical_src="$2"
  canonical_sha="$3"
  canonical_desc="$4"

  gemini_model="$(resolve_gemini_model_class "${role}")"
  if [ -z "${gemini_model}" ]; then
    echo "compile-runtime-agents: ${role} not in routing table (Gemini col), defaulting to ${DEFAULT_GEMINI_MODEL_CLASS}" >&2
    gemini_model="${DEFAULT_GEMINI_MODEL_CLASS}"
  fi

  mkdir -p "${GEMINI_OUT_DIR}"
  out_path="${GEMINI_OUT_DIR}/${role}.md"
  tmp_out="${out_path}.tmp"

  {
    printf -- '---\n'
    printf 'name: %s\n' "${role}"
    printf 'description: |\n'
    printf '  %s\n' "${canonical_desc}"
    printf 'model: %s\n' "${gemini_model}"
    printf 'canonical_source: %s\n' "${canonical_src}"
    printf 'canonical_sha: %s\n' "${canonical_sha}"
    printf 'generator: %s\n' "${GENERATOR_PATH}"
    printf 'generator_version: %s\n' "${GENERATOR_VERSION}"
    printf 'classification: generated\n'
    printf -- '---\n'
    printf '\n'
    awk '
      BEGIN { in_body = 0; fm_end = 0 }
      /^---$/ {
        if (fm_end == 0) { fm_end = 1; next }
        if (fm_end == 1) { in_body = 1; next }
      }
      { if (in_body && $0 !~ /^---$/) print }
    ' "${canonical_src}"
  } > "${tmp_out}"

  mv "${tmp_out}" "${out_path}"

  if ! maybe_validate_output "${out_path}"; then
    overall_status=1
  fi
}

# ---- antigravity adapter writers ------------------------------------
# Writes:
#   .agents/skills/<role>/SKILL.md  — thin-adapter skill (fw-adr-0026 Q-0033)
#   .agents/agents/<role>/agent.json — per-role subagent (fw-adr-0026 Q-0033)
#
# toolNames: [] passthrough for all roles (ADR mapping rule). A WARN is
# emitted per role whose .claude/agents/<role>.md has a non-empty tools:
# frontmatter line and no ANTIGRAVITY_TOOLS_MAP entry (map absent for now;
# entries added when Antigravity tool-name vocabulary is confirmed).
#
# tech-lead guard: for the tech-lead role only, the systemPromptSections
# content is replaced with a halt-and-report guard message.
write_antigravity_adapters() {
  role="$1"
  canonical_src="$2"
  canonical_sha="$3"
  canonical_desc="$4"
  canonical_tools="$5"

  # WARN for roles with a non-empty tools: line and no ANTIGRAVITY_TOOLS_MAP
  # entry. The map is currently absent; all roles emit toolNames: [].
  if [ -n "${canonical_tools}" ]; then
    # Build the map-key by replacing hyphens with underscores.
    map_key="ANTIGRAVITY_TOOLS_MAP_$(printf '%s' "${role}" | tr '-' '_')"
    # eval-expand the map variable (POSIX-safe indirect variable read).
    # shellcheck disable=SC2163  # false positive: map_key is a valid var name
    map_val="$(eval "printf '%s' \"\${${map_key}:-}\"")"
    if [ -z "${map_val}" ]; then
      printf 'compile-runtime-agents: WARN: %s: tools: line is non-empty but no ANTIGRAVITY_TOOLS_MAP entry found; emitting toolNames: [] (passthrough)\n' "${role}" >&2
    fi
  fi

  # ---- SKILL.md -------------------------------------------------------
  # YAML double-quoted scalar escaper (W-4): emit description as a
  # double-quoted YAML scalar so embedded quotes, backslashes, and other
  # special chars are always valid. Escapes: \ → \\, " → \", TAB → \t,
  # CR → \r, newlines in multi-line input → \n.
  # shellcheck disable=SC2016  # awk script literal
  yaml_dq_esc() {
    awk 'BEGIN{ORS=""}
    {
      s = $0
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      gsub(/\t/, "\\t",  s)
      gsub(/\r/, "\\r",  s)
      if (NR > 1) printf "\\n"
      printf "%s", s
    }'
  }

  esc_yaml_desc="$(printf '%s' "${canonical_desc}" | yaml_dq_esc)"

  skill_dir="${ANTIGRAVITY_OUT_DIR}/skills/${role}"
  skill_path="${skill_dir}/SKILL.md"
  skill_tmp="${skill_path}.tmp"
  mkdir -p "${skill_dir}"

  {
    printf -- '---\n'
    printf 'name: %s\n' "${role}"
    printf 'description: "%s"\n' "${esc_yaml_desc}"
    printf 'canonical_source: %s\n' "${canonical_src}"
    printf 'canonical_sha: %s\n' "${canonical_sha}"
    printf 'generator: %s\n' "${GENERATOR_PATH}"
    printf 'generator_version: %s\n' "${GENERATOR_VERSION}"
    printf 'classification: generated\n'
    printf -- '---\n'
    printf '\n'
    # shellcheck disable=SC2016  # literal backticks for Markdown output
    printf 'Read `.claude/agents/%s.md` (canonical role contract).\n' "${role}"
    # shellcheck disable=SC2016  # literal backticks for Markdown output
    printf 'If `local_supplement` resolves to an existing file, read it after the canonical file.\n'
    printf 'Act only as that role.\n'
    printf "Return output in the role's required format.\n"
  } > "${skill_tmp}"
  mv "${skill_tmp}" "${skill_path}"

  # ---- agent.json -----------------------------------------------------
  agent_dir="${ANTIGRAVITY_OUT_DIR}/agents/${role}"
  agent_path="${agent_dir}/agent.json"
  agent_tmp="${agent_path}.tmp"
  mkdir -p "${agent_dir}"

  # JSON string escaper (RFC-8259 compliant):
  # - backslash, double-quote, \t, \r, \n (multi-line input)
  # - control characters U+0000-U+001F not covered above → \uXXXX (W-1)
  # shellcheck disable=SC2016  # awk script uses literal single quotes internally
  json_esc() {
    awk 'BEGIN{ORS=""}
    {
      s = $0
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      gsub(/\t/, "\\t",  s)
      gsub(/\r/, "\\r",  s)
      # Emit \uXXXX for remaining control chars U+0000-U+001F (W-1).
      out = ""
      n = length(s)
      for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        v = 0
        # Portable ord(): build value via a lookup of the low-ctrl range.
        # We only need to detect < 0x20 (already handled \t and \r above,
        # but they remain in s only if they were literal chars not matched
        # by the gsub above; guard both anyway).
        if (c ~ /[\001-\010\013\014\016-\037]/) {
          for (v = 1; v <= 31; v++) {
            if (sprintf("%c", v) == c) break
          }
          out = out sprintf("\\u%04x", v)
        } else {
          out = out c
        }
      }
      if (NR > 1) printf "\\n"
      printf "%s", out
    }'
  }

  esc_desc="$(printf '%s' "${canonical_desc}" | json_esc)"

  # System prompt content: standard pointer or tech-lead guard.
  if [ "${role}" = "tech-lead" ]; then
    sys_content="This session has been invoked as an Antigravity subagent named tech-lead. This is a harness misconfiguration: tech-lead is the main-session persona and must not be spawned as a specialist subagent (binding rule per .claude/agents/tech-lead.md and CLAUDE.md). Do not perform any work. Report this condition to the operator and halt."
  else
    # shellcheck disable=SC2016  # literal backtick in content string
    sys_content="Read \`.claude/agents/${role}.md\` (canonical role contract). Act only as that role. Return output in the role's required format."
  fi
  esc_sys="$(printf '%s' "${sys_content}" | json_esc)"

  {
    printf '{\n'
    printf '  "name": "%s",\n' "${role}"
    printf '  "description": "%s",\n' "${esc_desc}"
    printf '  "hidden": false,\n'
    printf '  "canonical_source": "%s",\n' "${canonical_src}"
    printf '  "canonical_sha": "%s",\n' "${canonical_sha}"
    printf '  "generator": "%s",\n' "${GENERATOR_PATH}"
    printf '  "generator_version": "%s",\n' "${GENERATOR_VERSION}"
    printf '  "classification": "generated",\n'
    printf '  "config": {\n'
    printf '    "customAgent": {\n'
    printf '      "systemPromptSections": [\n'
    printf '        {\n'
    printf '          "title": "Role contract",\n'
    printf '          "content": "%s"\n' "${esc_sys}"
    printf '        }\n'
    printf '      ],\n'
    printf '      "toolNames": [],\n'
    printf '      "systemPromptConfig": {\n'
    printf '        "includeSections": []\n'
    printf '      }\n'
    printf '    }\n'
    printf '  }\n'
    printf '}\n'
  } > "${agent_tmp}"
  mv "${agent_tmp}" "${agent_path}"
}

compile_role() {
  role="$1"
  src="${AGENTS_DIR}/${role}.md"

  if [ ! -f "${src}" ]; then
    echo "compile-runtime-agents: ${role}: canonical file not found at ${src}" >&2
    overall_status=1
    return 0
  fi

  if [ "${CHECK_MODE}" -eq 1 ]; then
    echo "ok: ${role} -> ${src}"
    return 0
  fi

  workdir="$(mktemp -d)"
  trap 'rm -rf "${workdir}"' EXIT INT TERM

  parsed="${workdir}/parsed.tsv"
  parse_canonical "${src}" "${workdir}" > "${parsed}"

  # Pull frontmatter values.
  fm_name="$(awk -F'\t' '$1=="FM" && $2=="name" {print $3; exit}' "${parsed}")"
  fm_desc="$(awk -F'\t' '$1=="FM" && $2=="description" {print $3; exit}' "${parsed}")"
  fm_model="$(awk -F'\t' '$1=="FM" && $2=="model" {print $3; exit}' "${parsed}")"
  fm_tools="$(awk -F'\t' '$1=="FM" && $2=="tools" {print $3; exit}' "${parsed}")"

  if [ -z "${fm_name}" ]; then
    echo "compile-runtime-agents: ${role}: frontmatter missing 'name'" >&2
    overall_status=1
    rm -rf "${workdir}"; trap - EXIT INT TERM
    return 0
  fi

  # Build per-slug retained sections. We walk parsed.tsv in order and
  # for each SEC line decide whether it maps to an allowed slug. First
  # match wins per slug (canonical-file order preserved on output).
  retained_order="${workdir}/order"
  : > "${retained_order}"
  seen_slugs="${workdir}/seen"
  : > "${seen_slugs}"

  awk -F'\t' '$1=="SEC" {print $2 "\t" $3}' "${parsed}" \
    > "${workdir}/sections.tsv"

  while IFS="$(printf '\t')" read -r heading idx; do
    [ -z "${heading}" ] && continue
    norm="$(normalize_heading "${heading}")"
    slug="$(map_section "${norm}")"
    if [ -z "${slug}" ]; then
      continue
    fi
    # Special case: output_format heading may also fill
    # customer_interface_rule when its normalized form is
    # "customer facing output discipline".
    secondary=""
    if [ "${slug}" = "output_format" ] && \
       [ "${norm}" = "customer facing output discipline" ]; then
      secondary="customer_interface_rule"
    fi

    if ! grep -q "^${slug}$" "${seen_slugs}"; then
      printf '%s\n' "${slug}" >> "${seen_slugs}"
      printf '%s\t%s\t%s\n' "${slug}" "${heading}" "${idx}" \
        >> "${retained_order}"
    fi
    if [ -n "${secondary}" ] && ! grep -q "^${secondary}$" "${seen_slugs}"; then
      printf '%s\n' "${secondary}" >> "${seen_slugs}"
    fi
  done < "${workdir}/sections.tsv"

  # Diagnose missing required slugs. Default (WARN) mode: SKIP the
  # compact runtime contract for this role, remove any stale on-disk
  # copy left over from a previous run, and continue. --strict mode:
  # the missing-section condition is fatal (overall_status=1). Adapter
  # generation is independent and proceeds either way (FR-021 only
  # needs frontmatter + fixed body, not section completeness).
  missing=""
  for r in ${REQUIRED_SLUGS}; do
    if ! grep -q "^${r}$" "${seen_slugs}"; then
      missing="${missing} ${r}"
    fi
  done
  role_incomplete=0
  if [ -n "${missing}" ]; then
    role_incomplete=1
    if [ "${STRICT_MODE}" -eq 1 ]; then
      for r in ${missing}; do
        echo "compile-runtime-agents: ${role} is missing required section \"${r}\"" >&2
      done
      overall_status=1
    else
      for r in ${missing}; do
        echo "compile-runtime-agents: SKIP runtime contract for ${role} — missing required section \"${r}\"" >&2
      done
    fi
  fi

  # Resolve canonical_sha from the git index (staged content), NOT from HEAD.
  # Issue #250: using HEAD:${src} resolves the prior commit's blob SHA when
  # the canonical has been edited but not yet committed, producing stale
  # canonical_sha in the mirror. git ls-files --stage resolves the index
  # (staged) object SHA, which is correct both before and after commit.
  canonical_sha=""
  if command -v git >/dev/null 2>&1; then
    canonical_sha="$(git ls-files --stage "${src}" 2>/dev/null \
        | awk 'NR==1{print $2}' || true)"
    # Fall back to HEAD if the file is not staged (e.g. clean committed state
    # with no pending edits — ls-files --stage returns nothing for unmodified
    # tracked files in older git; HEAD: is correct in that case).
    if [ -z "${canonical_sha}" ] || \
       ! printf '%s' "${canonical_sha}" | grep -qE '^[0-9a-f]{40}$'; then
      canonical_sha="$(git rev-parse "HEAD:${src}" 2>/dev/null || true)"
    fi
  fi
  if [ -z "${canonical_sha}" ] || \
     ! printf '%s' "${canonical_sha}" | grep -qE '^[0-9a-f]{40}$'; then
    echo "compile-runtime-agents: ${role}: could not resolve canonical_sha from git index for ${src}" >&2
    overall_status=1
    canonical_sha="0000000000000000000000000000000000000000"
  fi

  # OpenCode adapter — always written when adapters are enabled.
  # Embeds full role instructions from the canonical file so
  # OpenCode subagents receive their role contract as a system prompt.
  # fm_desc is load-bearing for OpenCode autonomous selection;
  # fm_tools determines the agent's permission surface.
  # Skip tech-lead: the main session persona, never a subagent.
  if [ "${NO_OPENCODE_ADAPTERS}" -eq 0 ] && [ "${role}" != "tech-lead" ]; then
    write_opencode_adapter "${role}" "${src}" "${canonical_sha}" "${fm_desc}" "${fm_tools}"
  fi

  # Gemini adapter (fw-adr-0022) — same conditions as opencode.
  # Skip tech-lead: the main session persona, never a subagent.
  if [ "${NO_GEMINI_ADAPTERS}" -eq 0 ] && [ "${role}" != "tech-lead" ]; then
    write_gemini_adapter "${role}" "${src}" "${canonical_sha}" "${fm_desc}"
  fi

  # Codex adapter — same thin-adapter shape, but using concrete Codex
  # model slugs so typed-role loading never sees Claude aliases or
  # abstract OpenAI classes. Skip tech-lead: the main session persona.
  if [ "${NO_CODEX_ADAPTERS}" -eq 0 ] && [ "${role}" != "tech-lead" ]; then
    write_codex_adapter "${role}" "${src}" "${canonical_sha}" "${fm_desc}"
  fi

  # Antigravity adapters (fw-adr-0026 Q-0033) — SKILL.md and agent.json.
  if [ "${NO_ANTIGRAVITY_ADAPTERS}" -eq 0 ]; then
    write_antigravity_adapters "${role}" "${src}" "${canonical_sha}" "${fm_desc}" "${fm_tools}"
  fi

  out_path="${OUT_DIR}/${role}.md"

  if [ "${role_incomplete}" -eq 1 ] && [ "${STRICT_MODE}" -eq 0 ]; then
    # Default WARN behaviour: do not write the compact runtime contract.
    # Clean up any stale on-disk copy from a previous run so we never
    # leave dangling generated artefacts for a now-incomplete canonical.
    if [ -f "${out_path}" ]; then
      rm -f "${out_path}"
    fi
    rm -rf "${workdir}"
    trap - EXIT INT TERM
    return 0
  fi

  mkdir -p "${OUT_DIR}"
  tmp_out="${workdir}/out.md"

  # Emit frontmatter (deterministic key order).
  {
    printf -- '---\n'
    printf 'name: %s\n' "${fm_name}"
    printf 'description: |\n'
    printf '  %s\n' "${fm_desc}"
    if [ -n "${fm_model}" ]; then
      printf 'model: %s\n' "${fm_model}"
    fi
    printf 'canonical_source: %s\n' "${src}"
    printf 'canonical_sha: %s\n' "${canonical_sha}"
    printf 'generator: %s\n' "${GENERATOR_PATH}"
    printf 'generator_version: %s\n' "${GENERATOR_VERSION}"
    printf 'classification: generated\n'
    printf -- '---\n'
    printf '\n'
  } > "${tmp_out}"

  # Emit retained sections in canonical-file order.
  while IFS="$(printf '\t')" read -r slug heading idx; do
    [ -z "${heading}" ] && continue
    body_file="${workdir}/sec.${idx}"
    {
      printf '## %s\n' "${heading}"
      if [ -f "${body_file}" ]; then
        # Strip trailing whitespace per line; preserve interior blanks.
        sed -e 's/[ \t]\{1,\}$//' "${body_file}"
      fi
    } >> "${tmp_out}"
  done < "${retained_order}"

  # Trim trailing blank lines, then ensure exactly one terminating newline.
  awk '
    { lines[NR] = $0 }
    END {
      last = NR
      while (last > 0 && lines[last] ~ /^[ \t]*$/) last--
      for (i = 1; i <= last; i++) print lines[i]
    }
  ' "${tmp_out}" > "${tmp_out}.trim"
  mv "${tmp_out}.trim" "${tmp_out}"

  mv "${tmp_out}" "${out_path}"

  if ! maybe_validate_output "${out_path}"; then
    overall_status=1
  fi

  rm -rf "${workdir}"
  trap - EXIT INT TERM
}

# ---- main loop -------------------------------------------------------
for role in ${ROLES}; do
  case "${role}" in
    *[!a-z0-9-]*|"")
      echo "compile-runtime-agents: invalid role slug: '${role}'" >&2
      overall_status=1
      continue
      ;;
  esac
  compile_role "${role}"
done

# ---- verify-mode comparison -----------------------------------------
if [ "${VERIFY_MODE}" -eq 1 ]; then
  verify_status=0
  for role in ${ROLES}; do
    case "${role}" in
      *[!a-z0-9-]*|"") continue ;;
    esac

    role_ok=1

    # Compact runtime contract.
    gen_runtime="${OUT_DIR}/${role}.md"
    cmt_runtime="${VERIFY_COMMITTED_RUNTIME}/${role}.md"
    if [ -f "${gen_runtime}" ]; then
      if [ ! -f "${cmt_runtime}" ]; then
        echo "verify FAIL: ${cmt_runtime} differs from generator output (committed file missing)"
        role_ok=0
        verify_status=1
      elif ! cmp -s "${gen_runtime}" "${cmt_runtime}"; then
        echo "verify FAIL: ${cmt_runtime} differs from generator output"
        role_ok=0
        verify_status=1
      fi
    fi

    # OpenCode adapter (unless suppressed).
    if [ "${NO_OPENCODE_ADAPTERS}" -eq 0 ]; then
      gen_opencode="${OPENCODE_OUT_DIR}/${role}.md"
      cmt_opencode="${VERIFY_COMMITTED_OPENCODE}/${role}.md"
      if [ -f "${gen_opencode}" ]; then
        if [ ! -f "${cmt_opencode}" ]; then
          echo "verify FAIL: ${cmt_opencode} differs from generator output (committed file missing)"
          role_ok=0
          verify_status=1
        elif ! cmp -s "${gen_opencode}" "${cmt_opencode}"; then
          echo "verify FAIL: ${cmt_opencode} differs from generator output"
          role_ok=0
          verify_status=1
        fi
      fi
    fi

    # Gemini adapter (unless suppressed).
    if [ "${NO_GEMINI_ADAPTERS}" -eq 0 ]; then
      gen_gemini="${GEMINI_OUT_DIR}/${role}.md"
      cmt_gemini="${VERIFY_COMMITTED_GEMINI}/${role}.md"
      if [ -f "${gen_gemini}" ]; then
        if [ ! -f "${cmt_gemini}" ]; then
          echo "verify FAIL: ${cmt_gemini} differs from generator output (committed file missing)"
          role_ok=0
          verify_status=1
        elif ! cmp -s "${gen_gemini}" "${cmt_gemini}"; then
          echo "verify FAIL: ${cmt_gemini} differs from generator output"
          role_ok=0
          verify_status=1
        fi
      fi
    fi

    # Codex adapter (unless suppressed).
    if [ "${NO_CODEX_ADAPTERS}" -eq 0 ]; then
      gen_codex="${CODEX_OUT_DIR}/${role}.toml"
      cmt_codex="${VERIFY_COMMITTED_CODEX}/${role}.toml"
      if [ -f "${gen_codex}" ]; then
        if [ ! -f "${cmt_codex}" ]; then
          echo "verify FAIL: ${cmt_codex} differs from generator output (committed file missing)"
          role_ok=0
          verify_status=1
        elif ! cmp -s "${gen_codex}" "${cmt_codex}"; then
          echo "verify FAIL: ${cmt_codex} differs from generator output"
          role_ok=0
          verify_status=1
        fi
      fi
    fi

    # Antigravity adapters (unless suppressed).
    if [ "${NO_ANTIGRAVITY_ADAPTERS}" -eq 0 ]; then
      gen_skill="${ANTIGRAVITY_OUT_DIR}/skills/${role}/SKILL.md"
      cmt_skill="${VERIFY_COMMITTED_ANTIGRAVITY}/skills/${role}/SKILL.md"
      if [ -f "${gen_skill}" ]; then
        if [ ! -f "${cmt_skill}" ]; then
          echo "verify FAIL: ${cmt_skill} differs from generator output (committed file missing)"
          role_ok=0
          verify_status=1
        elif ! cmp -s "${gen_skill}" "${cmt_skill}"; then
          echo "verify FAIL: ${cmt_skill} differs from generator output"
          role_ok=0
          verify_status=1
        fi
      fi
      gen_agent="${ANTIGRAVITY_OUT_DIR}/agents/${role}/agent.json"
      cmt_agent="${VERIFY_COMMITTED_ANTIGRAVITY}/agents/${role}/agent.json"
      if [ -f "${gen_agent}" ]; then
        if [ ! -f "${cmt_agent}" ]; then
          echo "verify FAIL: ${cmt_agent} differs from generator output (committed file missing)"
          role_ok=0
          verify_status=1
        elif ! cmp -s "${gen_agent}" "${cmt_agent}"; then
          echo "verify FAIL: ${cmt_agent} differs from generator output"
          role_ok=0
          verify_status=1
        fi
      fi
    fi

    if [ "${role_ok}" -eq 1 ]; then
      echo "verify OK: ${role}"
    fi
  done

  verify_cleanup
  # In verify mode, the verify exit code dominates so drift is the
  # sole signal. (overall_status may be non-zero from canonical-file
  # diagnostics; that's still useful but doesn't change pass/fail.)
  exit "${verify_status}"
fi

exit "${overall_status}"
