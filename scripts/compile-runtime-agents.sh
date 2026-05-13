#!/bin/sh
# compile-runtime-agents.sh — compact runtime-contract compiler (M1.1)
# version: 0.2.0
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
# Usage:
#   scripts/compile-runtime-agents.sh [--check] [--verify] [--strict] \
#                                     [--out-dir <path>] \
#                                     [--no-opencode-adapters] [role...]
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

GENERATOR_VERSION="0.2.0"
GENERATOR_PATH="scripts/compile-runtime-agents.sh"
AGENTS_DIR=".claude/agents"
SCHEMA_DIR="schemas"
DEFAULT_OUT_DIR="docs/runtime/agents"
GENERATED_SCHEMA="${SCHEMA_DIR}/generated-artifact.schema.json"
OPENCODE_OUT_DIR=".opencode/agents"
OPENCODE_LOCAL_DIR=".opencode/agents/local"
ROUTING_DOC="docs/model-routing-guidelines.md"
DEFAULT_MODEL_CLASS="claude-sonnet"

# ---- arg parsing -----------------------------------------------------
CHECK_MODE=0
VERIFY_MODE=0
STRICT_MODE=0
OUT_DIR="${DEFAULT_OUT_DIR}"
ROLES=""
NO_OPENCODE_ADAPTERS=0

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

# ---- verify-mode setup ----------------------------------------------
# In verify mode, redirect outputs to a scratch dir; capture the
# committed paths first so we can cmp after generation. The committed
# paths are NEVER written in verify mode.
VERIFY_SCRATCH=""
VERIFY_COMMITTED_RUNTIME=""
VERIFY_COMMITTED_OPENCODE=""
if [ "${VERIFY_MODE}" -eq 1 ]; then
  if [ "${CHECK_MODE}" -eq 1 ]; then
    echo "compile-runtime-agents: --verify and --check are mutually exclusive" >&2
    exit 2
  fi
  VERIFY_SCRATCH="$(mktemp -d)"
  VERIFY_COMMITTED_RUNTIME="${OUT_DIR}"
  VERIFY_COMMITTED_OPENCODE="${OPENCODE_OUT_DIR}"
  OUT_DIR="${VERIFY_SCRATCH}/runtime"
  OPENCODE_OUT_DIR="${VERIFY_SCRATCH}/opencode"
  mkdir -p "${OUT_DIR}" "${OPENCODE_OUT_DIR}"
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
  awk '
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
  ' "${out_path}" \
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

# ---- opencode adapter writer ----------------------------------------
# Writes .opencode/agents/<role>.md with frontmatter + the fixed
# four-line body required by R-7. canonical_sha is the same 40-hex
# value already resolved for the compact-runtime contract.
write_opencode_adapter() {
  role="$1"
  canonical_src="$2"
  canonical_sha="$3"

  model_class="$(resolve_model_class "${role}")"
  if [ -z "${model_class}" ]; then
    echo "compile-runtime-agents: ${role} not in routing table, defaulting to ${DEFAULT_MODEL_CLASS}" >&2
    model_class="${DEFAULT_MODEL_CLASS}"
  fi

  mkdir -p "${OPENCODE_OUT_DIR}"
  out_path="${OPENCODE_OUT_DIR}/${role}.md"
  tmp_out="${out_path}.tmp"

  local_supplement="${OPENCODE_LOCAL_DIR}/${role}.md"
  {
    printf -- '---\n'
    printf 'name: %s\n' "${role}"
    printf 'model: %s\n' "${model_class}"
    printf 'canonical_source: %s\n' "${canonical_src}"
    printf 'canonical_sha: %s\n' "${canonical_sha}"
    if [ -f "${local_supplement}" ]; then
      printf 'local_supplement: %s\n' "${local_supplement}"
    fi
    printf 'generator: %s\n' "${GENERATOR_PATH}"
    printf 'generator_version: %s\n' "${GENERATOR_VERSION}"
    printf 'classification: generated\n'
    printf -- '---\n'
    printf '\n'
    printf 'Read `.claude/agents/%s.md` (canonical role contract).\n' "${role}"
    printf 'If `local_supplement` resolves to an existing file, read it after the canonical file.\n'
    printf 'Act only as that role.\n'
    printf "Return output in the role's required format.\n"
  } > "${tmp_out}"

  mv "${tmp_out}" "${out_path}"

  if ! maybe_validate_output "${out_path}"; then
    overall_status=1
  fi
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

  # Resolve canonical_sha from the git index.
  canonical_sha=""
  if command -v git >/dev/null 2>&1; then
    canonical_sha="$(git rev-parse "HEAD:${src}" 2>/dev/null || true)"
  fi
  if [ -z "${canonical_sha}" ] || \
     ! printf '%s' "${canonical_sha}" | grep -qE '^[0-9a-f]{40}$'; then
    echo "compile-runtime-agents: ${role}: could not resolve canonical_sha from git index for ${src}" >&2
    overall_status=1
    canonical_sha="0000000000000000000000000000000000000000"
  fi

  # OpenCode adapter (FR-021 / R-7) — always written when adapters
  # are enabled, regardless of section completeness, because the
  # adapter body is fixed and only depends on the canonical slug +
  # sha + routing-table class.
  if [ "${NO_OPENCODE_ADAPTERS}" -eq 0 ]; then
    write_opencode_adapter "${role}" "${src}" "${canonical_sha}"
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
    printf 'description: %s\n' "${fm_desc}"
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

    if [ "${role_ok}" -eq 1 ]; then
      echo "verify OK: ${role}"
    fi
  done

  verify_cleanup
  # In verify mode, the verify exit code dominates so drift is the
  # sole signal. (overall_status may be non-zero from canonical-file
  # diagnostics; that's still useful but doesn't change pass/fail.)
  exit ${verify_status}
fi

exit ${overall_status}
