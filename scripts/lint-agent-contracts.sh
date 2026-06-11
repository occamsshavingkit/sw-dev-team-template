#!/bin/sh
# SPDX-License-Identifier: MIT
# Copyright 2026 occamsshavingkit/sw-dev-team-template contributors
#
# scripts/lint-agent-contracts.sh — schema-validation gate for the
# FR-022 / FR-023 contract surfaces (M1.1 / G6 hard-gate).
#
# Validates four surfaces:
#
#   1. Canonical agent contracts (.claude/agents/*.md, excluding
#      sme-template.md and any non-kebab basenames). For each file,
#      parses YAML frontmatter and `## ` body sections, builds an
#      ad-hoc JSON representation matching schemas/agent-contract.schema.json,
#      and validates with check-jsonschema.
#
#   2. Prompt-regression fixtures (tests/prompt-regression/<agent>/<case>.yaml).
#      Per R-VR-1, each fixture must carry the keys
#        agent / case / input.user_message / input.context /
#        expected_behavior / assertions
#      The schema for this surface is inlined here (key-presence check
#      via awk); R-VR-1 explicitly does not require a YAML parser.
#
#   3. Generated artefacts (docs/runtime/agents/*.md and
#      .opencode/agents/*.md). Each file's frontmatter is extracted to
#      JSON and validated against schemas/generated-artifact.schema.json.
#
#   4. Antigravity adapters (.agents/skills/<role>/SKILL.md and
#      .agents/agents/<role>/agent.json). Validates canonical_sha match,
#      required fields (description/name/classification), and warns on
#      stray files (fw-adr-0026 Q-0033).
#
# Section-to-slug mapping is a verbatim derivation of map_section() in
# scripts/compile-runtime-agents.sh (declared source of truth). Keep in
# sync when the compiler's mapping changes; the lint table is derived,
# not authoritative.
#
# Modes (CLI flags):
#   (default)           Scan all four surfaces.
#   --canonical-only    Only canonical agent contracts.
#   --generated-only    Only generated artefacts (runtime/opencode/gemini).
#   --fixtures-only     Only prompt-regression fixtures.
#   --antigravity-only  Only .agents/skills/ and .agents/agents/ surfaces.
#   -h | --help         Print this header.
#
# Exit codes:
#   0  no errors
#   1  one or more errors (warnings alone do not fail)
#   2  usage error / environment failure (e.g., check-jsonschema missing)
#
# POSIX-sh only; LANG=C/LC_ALL=C; no bashisms.

set -eu
LANG=C
LC_ALL=C
export LANG LC_ALL

# ---- repo-relative paths --------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

AGENTS_DIR=".claude/agents"
RUNTIME_DIR="docs/runtime/agents"
OPENCODE_DIR=".opencode/agents"
GEMINI_DIR=".gemini/agents"
ANTIGRAVITY_DIR=".agents"
FIXTURES_DIR="tests/prompt-regression"
SCHEMA_DIR="schemas"
CONTRACT_SCHEMA="${SCHEMA_DIR}/agent-contract.schema.json"
GENERATED_SCHEMA="${SCHEMA_DIR}/generated-artifact.schema.json"

# ---- arg parsing -----------------------------------------------------
MODE="all"

usage() {
    sed -n '2,46p' "$0" >&2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --canonical-only)    MODE="canonical";    shift ;;
        --generated-only)    MODE="generated";    shift ;;
        --fixtures-only)     MODE="fixtures";     shift ;;
        --antigravity-only)  MODE="antigravity";  shift ;;
        -h|--help) usage; exit 0 ;;
        *)
            printf 'lint-agent-contracts: unknown arg: %s\n' "$1" >&2
            usage
            exit 2
            ;;
    esac
done

# ---- check-jsonschema resolution -------------------------------------
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

if ! resolve_check_jsonschema; then
    printf 'lint-agent-contracts: check-jsonschema not found on PATH or at %s/.local/share/check-jsonschema-venv/bin/\n' "${HOME}" >&2
    exit 2
fi

ERR_COUNT=0
WARN_COUNT=0

err() {
    # err <file> <message>
    printf 'lint-agent-contracts: ERROR: %s: %s\n' "$1" "$2" >&2
    ERR_COUNT=$((ERR_COUNT + 1))
}

# shellcheck disable=SC2317  # false positive: warn() is invoked dynamically from validation paths
warn() {
    printf 'lint-agent-contracts: WARN: %s: %s\n' "$1" "$2" >&2
    WARN_COUNT=$((WARN_COUNT + 1))
}

# ---- section heading -> canonical slug (derived from
# scripts/compile-runtime-agents.sh map_section(); keep in sync) -------
normalize_heading() {
    printf '%s' "$1" \
        | tr '[:upper:]' '[:lower:]' \
        | sed -e 's/([^)]*)//g' \
              -e 's/[^a-z0-9]\{1,\}/ /g' \
              -e 's/^ *//' \
              -e 's/ *$//'
}

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

# ---- helpers: JSON-string escape (awk) -------------------------------
# Used for both canonical-contract JSON synth and frontmatter-only JSON
# synth for generated artefacts.
json_escape() {
    # stdin -> stdout; escape control chars, backslash, double-quote.
    awk '
        BEGIN { ORS = "" }
        {
            s = $0
            gsub(/\\/, "\\\\", s)
            gsub(/"/,  "\\\"", s)
            gsub(/\t/, "\\t",  s)
            gsub(/\r/, "\\r",  s)
            if (NR > 1) printf "\\n"
            printf "%s", s
        }
    '
}

# ---- canonical contract validation -----------------------------------
# Parse one .claude/agents/<role>.md into the JSON shape required by
# agent-contract.schema.json, then validate.
lint_canonical_file() {
    src="$1"
    # Skip files that aren't subject to the canonical-contract schema.
    # See issues #140 (-local.md supplements) and #153 (sme-*.md derived files).
    case "$(basename "$src")" in
        sme-template.md)
            # Already-excluded scaffold; keep current behavior.
            return
            ;;
        sme-*.md)
            # Per-project SME files use a different section vocabulary (Mode /
            # Scope / Knowledge sources / Job / Escalation / Anti-patterns /
            # Metadata) per docs/sme/CONTRACT.md. They are project-specific
            # and not subject to the canonical-contract schema. Issue #153.
            printf '%s\n' "lint-agent-contracts: SKIP: $src (SME — uses sme-template vocabulary)" >&2
            return
            ;;
        *-local.md)
            # Per-project routing supplements (issue #140, upstream PR #75)
            # are layered on top of canonical contracts and aren't full agent
            # contracts in their own right. Excluded by design.
            printf '%s\n' "lint-agent-contracts: SKIP: $src (-local.md supplement)" >&2
            return
            ;;
    esac
    workdir="$(mktemp -d)"
    # Per-invocation cleanup; no nested trap stacking.
    parsed="${workdir}/parsed.tsv"

    # Reuse the compiler's parser logic (inlined here to keep this
    # script standalone). Emits:
    #   FM<TAB>name<TAB><value>
    #   FM<TAB>description<TAB><value>
    #   FM<TAB>model<TAB><value>
    #   FM<TAB>tools<TAB><value>
    #   SEC<TAB><heading><TAB><idx>
    # ...with sec.<idx> body files in workdir.
    awk -v workdir="${workdir}" '
        BEGIN { state = "pre"; sec_n = 0 }
        function flush_sec() {
            if (sec_n > 0) close(workdir "/sec." sec_n)
        }
        {
            if (state == "pre") {
                if ($0 == "---") { state = "fm"; next }
                state = "body"
            }
            if (state == "fm") {
                if ($0 == "---") { state = "body"; next }
                line = $0
                sub(/^[ \t]+/, "", line)
                if (line ~ /^name[ \t]*:/) {
                    v = line; sub(/^name[ \t]*:[ \t]*/, "", v)
                    gsub(/^"|"$/, "", v); gsub(/^'\''|'\''$/, "", v)
                    print "FM\tname\t" v
                } else if (line ~ /^description[ \t]*:/) {
                    v = line; sub(/^description[ \t]*:[ \t]*/, "", v)
                    gsub(/^"|"$/, "", v); gsub(/^'\''|'\''$/, "", v)
                    print "FM\tdescription\t" v
                } else if (line ~ /^model[ \t]*:/) {
                    v = line; sub(/^model[ \t]*:[ \t]*/, "", v)
                    gsub(/^"|"$/, "", v); gsub(/^'\''|'\''$/, "", v)
                    print "FM\tmodel\t" v
                } else if (line ~ /^tools[ \t]*:/) {
                    v = line; sub(/^tools[ \t]*:[ \t]*/, "", v)
                    gsub(/^"|"$/, "", v); gsub(/^'\''|'\''$/, "", v)
                    print "FM\ttools\t" v
                }
                next
            }
            # state == body
            if ($0 ~ /^## /) {
                flush_sec()
                sec_n++
                h = $0
                sub(/^## /, "", h)
                sub(/[ \t]+$/, "", h)
                print "SEC\t" h "\t" sec_n
                printf "" > (workdir "/sec." sec_n)
                next
            }
            if (sec_n > 0) {
                print $0 >> (workdir "/sec." sec_n)
            }
        }
        END { flush_sec() }
    ' "${src}" > "${parsed}"

    # Pull frontmatter fields.
    fm_name="$(awk -F'\t' '$1=="FM" && $2=="name" {print $3; exit}' "${parsed}")"
    fm_desc="$(awk -F'\t' '$1=="FM" && $2=="description" {print $3; exit}' "${parsed}")"
    fm_model="$(awk -F'\t' '$1=="FM" && $2=="model" {print $3; exit}' "${parsed}")"
    fm_tools="$(awk -F'\t' '$1=="FM" && $2=="tools" {print $3; exit}' "${parsed}")"

    # Build a per-slug map: first-match-wins on section index, mirroring
    # the compiler. Skip headings whose normalized text yields no slug.
    seen="${workdir}/seen"
    : > "${seen}"
    order="${workdir}/order"
    : > "${order}"

    awk -F'\t' '$1=="SEC" {print $2 "\t" $3}' "${parsed}" \
        > "${workdir}/sections.tsv"

    while IFS="$(printf '\t')" read -r heading idx; do
        [ -z "${heading}" ] && continue
        norm="$(normalize_heading "${heading}")"
        slug="$(map_section "${norm}")"
        if [ -z "${slug}" ]; then
            continue
        fi
        secondary=""
        if [ "${slug}" = "output_format" ] && \
           [ "${norm}" = "customer facing output discipline" ]; then
            secondary="customer_interface_rule"
        fi
        if ! grep -q "^${slug}\t" "${seen}" 2>/dev/null; then
            printf '%s\t%s\t%s\n' "${slug}" "${heading}" "${idx}" >> "${seen}"
            printf '%s\t%s\t%s\n' "${slug}" "${heading}" "${idx}" >> "${order}"
        fi
        if [ -n "${secondary}" ] && \
           ! grep -q "^${secondary}\t" "${seen}" 2>/dev/null; then
            printf '%s\t%s\t%s\n' "${secondary}" "${heading}" "${idx}" >> "${seen}"
        fi
    done < "${workdir}/sections.tsv"

    # Build JSON. The schema requires:
    #   frontmatter.{name, description} (model, tools optional)
    #   sections.{role_overview, hard_rules, escalation, output_format}
    # plus optional slugs. Each section is an object with heading +
    # body (or rules[] for hard_rules) per the schema.
    json="${workdir}/contract.json"

    # Escape frontmatter strings.
    esc_name="$(printf '%s' "${fm_name}" | json_escape)"
    esc_desc="$(printf '%s' "${fm_desc}" | json_escape)"
    esc_model="$(printf '%s' "${fm_model}" | json_escape)"
    esc_tools="$(printf '%s' "${fm_tools}" | json_escape)"

    {
        printf '{\n'
        printf '  "frontmatter": {\n'
        printf '    "name": "%s",\n' "${esc_name}"
        printf '    "description": "%s"' "${esc_desc}"
        if [ -n "${fm_model}" ]; then
            printf ',\n    "model": "%s"' "${esc_model}"
        fi
        if [ -n "${fm_tools}" ]; then
            printf ',\n    "tools": "%s"' "${esc_tools}"
        fi
        printf '\n  },\n'
        printf '  "sections": {\n'

        first=1
        # Emit each retained slug. For hard_rules, attempt to extract
        # numbered or lettered rules; if parsing yields zero, fall back
        # to a single synthetic rule using the whole body so the schema
        # passes when the canonical does carry the section (text-heavy
        # bodies still trip minItems=1).
        while IFS="$(printf '\t')" read -r slug heading idx; do
            [ -z "${slug}" ] && continue
            body_file="${workdir}/sec.${idx}"
            if [ ! -f "${body_file}" ]; then
                : > "${body_file}"
            fi

            if [ "${first}" -eq 0 ]; then
                printf ',\n'
            fi
            first=0

            esc_heading="$(printf '%s' "${heading}" | json_escape)"

            case "${slug}" in
                hard_rules)
                    # Pull lines that look like "1. ..." / "2. ..." or
                    # "A. ..." rule entries. We keep first letter / number
                    # as the id and the line text (with leading marker
                    # stripped) as the rule text.
                    rules_tmp="${workdir}/rules.${idx}"
                    awk '
                        /^[0-9]+\.[ \t]+/ {
                            id = $0
                            sub(/\..*$/, "", id)
                            txt = $0
                            sub(/^[0-9]+\.[ \t]+/, "", txt)
                            printf "HR-%s\t%s\n", id, txt
                            next
                        }
                        /^[A-Z]\.[ \t]+/ {
                            id = substr($0, 1, 1)
                            txt = $0
                            sub(/^[A-Z]\.[ \t]+/, "", txt)
                            printf "%s\t%s\n", id, txt
                        }
                    ' "${body_file}" > "${rules_tmp}"

                    printf '    "%s": {\n' "${slug}"
                    printf '      "heading": "%s",\n' "${esc_heading}"
                    printf '      "rules": [\n'

                    rcount=0
                    if [ -s "${rules_tmp}" ]; then
                        while IFS="$(printf '\t')" read -r rid rtxt; do
                            [ -z "${rid}" ] && continue
                            esc_rtxt="$(printf '%s' "${rtxt}" | json_escape)"
                            if [ "${rcount}" -gt 0 ]; then printf ',\n'; fi
                            printf '        {"id": "%s", "text": "%s"}' \
                                "${rid}" "${esc_rtxt}"
                            rcount=$((rcount + 1))
                        done < "${rules_tmp}"
                    fi
                    if [ "${rcount}" -eq 0 ]; then
                        # Schema requires minItems=1. Synthesize a
                        # single rule from the whole body. This still
                        # satisfies the structural check; the section
                        # exists and carries non-trivial text.
                        body_text="$(json_escape < "${body_file}")"
                        printf '        {"id": "HR-1", "text": "%s"}' \
                            "${body_text}"
                    fi
                    printf '\n      ]\n'
                    printf '    }'
                    ;;
                allowed_tools)
                    # tools[] minItems=1; harvest backtick-quoted tokens
                    # or comma-separated tool names. If nothing matches,
                    # synthesize one entry from the body.
                    tools_tmp="${workdir}/tools.${idx}"
                    awk '
                        {
                            line = $0
                            while (match(line, /`[^`]+`/)) {
                                tok = substr(line, RSTART+1, RLENGTH-2)
                                print tok
                                line = substr(line, RSTART+RLENGTH)
                            }
                        }
                    ' "${body_file}" > "${tools_tmp}"

                    printf '    "%s": {\n' "${slug}"
                    printf '      "heading": "%s",\n' "${esc_heading}"
                    printf '      "tools": [\n'
                    tcount=0
                    if [ -s "${tools_tmp}" ]; then
                        while IFS= read -r tline; do
                            [ -z "${tline}" ] && continue
                            esc_tline="$(printf '%s' "${tline}" | json_escape)"
                            if [ "${tcount}" -gt 0 ]; then printf ',\n'; fi
                            printf '        "%s"' "${esc_tline}"
                            tcount=$((tcount + 1))
                        done < "${tools_tmp}"
                    fi
                    if [ "${tcount}" -eq 0 ]; then
                        body_text="$(json_escape < "${body_file}")"
                        printf '        "%s"' "${body_text}"
                    fi
                    printf '\n      ]\n'
                    printf '    }'
                    ;;
                *)
                    body_text="$(json_escape < "${body_file}")"
                    printf '    "%s": {\n' "${slug}"
                    printf '      "heading": "%s",\n' "${esc_heading}"
                    printf '      "body": "%s"\n' "${body_text}"
                    printf '    }'
                    ;;
            esac
        done < "${order}"

        printf '\n  }\n'
        printf '}\n'
    } > "${json}"

    if ! "${CHECK_JSONSCHEMA}" --schemafile "${CONTRACT_SCHEMA}" "${json}" \
            >"${workdir}/out" 2>&1; then
        # Surface the first useful diagnostic line.
        diag="$(grep -v '^$' "${workdir}/out" | head -3 | tr '\n' ' ')"
        if [ -z "${diag}" ]; then
            diag="schema validation failed"
        fi
        err "${src}" "${diag}"
    fi

    rm -rf "${workdir}"
}

scan_canonical() {
    if [ ! -d "${AGENTS_DIR}" ]; then
        printf 'lint-agent-contracts: %s not found\n' "${AGENTS_DIR}" >&2
        ERR_COUNT=$((ERR_COUNT + 1))
        return
    fi
    if [ ! -f "${CONTRACT_SCHEMA}" ]; then
        printf 'lint-agent-contracts: %s not found\n' "${CONTRACT_SCHEMA}" >&2
        ERR_COUNT=$((ERR_COUNT + 1))
        return
    fi
    # ls -> filter -> sort, matching the compiler's role-walk rules.
    ls "${AGENTS_DIR}" 2>/dev/null \
        | grep '\.md$' \
        | sed 's/\.md$//' \
        | grep -E '^[a-z0-9][a-z0-9-]*$' \
        | grep -v '^sme-template$' \
        | LC_ALL=C sort \
        | while IFS= read -r role; do
            lint_canonical_file "${AGENTS_DIR}/${role}.md"
            # The counters live in our shell, but the while loop runs in
            # a subshell because of the pipe. Print sentinel lines so
            # the outer caller can roll them up.
            printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
        done > "${TMP_COUNTERS}"
    # Roll subshell counters back into ours: take the last sentinel.
    last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
    if [ -n "${last}" ]; then
        e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
        w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
        [ -n "${e}" ] && ERR_COUNT="${e}"
        [ -n "${w}" ] && WARN_COUNT="${w}"
    fi
}

# ---- generated-artifact validation -----------------------------------
# lint_generated_file <src> [gemini]
#   Pass the literal string "gemini" as $2 when validating a file under
#   .gemini/agents/; this enables the Gemini-specific description check
#   (fw-adr-0022 §4: description must be present and non-empty).
#   The schema itself does not enforce this for generated artifacts
#   (doing so would break runtime/opencode adapters which omit the field).
lint_generated_file() {
    src="$1"
    is_gemini="${2:-}"
    workdir="$(mktemp -d)"
    tmpjson="${workdir}/fm.json"
    # Extract frontmatter to a JSON object. Same recipe used by the
    # compiler's maybe_validate_output().
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
    ' "${src}" \
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

    if ! "${CHECK_JSONSCHEMA}" --schemafile "${GENERATED_SCHEMA}" "${tmpjson}" \
            >"${workdir}/out" 2>&1; then
        diag="$(grep -v '^$' "${workdir}/out" | head -3 | tr '\n' ' ')"
        if [ -z "${diag}" ]; then
            diag="schema validation failed"
        fi
        err "${src}" "${diag}"
    fi

    # Gemini-specific: description must be present and non-empty
    # (fw-adr-0022 §4 — load-bearing for autonomous Gemini role selection).
    # Not enforced via the shared schema to avoid breaking runtime/opencode
    # adapters that legitimately omit description.
    if [ "${is_gemini}" = "gemini" ]; then
        desc_val="$(awk -F'\t' '$1=="description" {print $0; exit}' "${tmpjson}" 2>/dev/null || true)"
        # Re-extract directly from the raw frontmatter for reliability.
        desc_val="$(awk '
            BEGIN { state = "pre" }
            {
                if (state == "pre") {
                    if ($0 == "---") { state = "fm"; next }
                    exit
                }
                if (state == "fm") {
                    if ($0 == "---") { exit }
                    if ($0 ~ /^description[ \t]*:/) {
                        v = $0
                        sub(/^description[ \t]*:[ \t]*/, "", v)
                        print v
                        exit
                    }
                }
            }
        ' "${src}")"
        if [ -z "${desc_val}" ]; then
            err "${src}" "gemini adapter missing required description field (fw-adr-0022 §4)"
        fi
    fi

    rm -rf "${workdir}"
}

scan_generated() {
    if [ ! -f "${GENERATED_SCHEMA}" ]; then
        printf 'lint-agent-contracts: %s not found\n' "${GENERATED_SCHEMA}" >&2
        ERR_COUNT=$((ERR_COUNT + 1))
        return
    fi
    for dir in "${RUNTIME_DIR}" "${OPENCODE_DIR}" "${GEMINI_DIR}"; do
        [ -d "${dir}" ] || continue
        # Only validate role-shaped basenames; skip READMEs and any
        # non-role markdown the directories may hold (e.g.,
        # generated-artifacts.manifest.json sits in docs/runtime/agents/
        # at a sibling path but is not .md). The role check mirrors the
        # compiler's role walk (kebab-case slug, no sme-template).
        #
        # Pass "gemini" as the second arg when scanning .gemini/agents/ so
        # lint_generated_file applies the description-required check
        # (fw-adr-0022 §4) for that surface only.
        _lint_extra=""
        [ "${dir}" = "${GEMINI_DIR}" ] && _lint_extra="gemini"
        ls "${dir}" 2>/dev/null \
            | grep '\.md$' \
            | sed 's/\.md$//' \
            | grep -E '^[a-z0-9][a-z0-9-]*$' \
            | grep -v '^sme-template$' \
            | grep -v '^readme$' \
            | LC_ALL=C sort \
            | sed 's/$/.md/' \
            | while IFS= read -r f; do
                lint_generated_file "${dir}/${f}" "${_lint_extra}"
                printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
            done > "${TMP_COUNTERS}"
        last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
        if [ -n "${last}" ]; then
            e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
            w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
            [ -n "${e}" ] && ERR_COUNT="${e}"
            [ -n "${w}" ] && WARN_COUNT="${w}"
        fi
    done
}

# ---- fixture validation (inline YAML schema, R-VR-1) -----------------
# Required keys (per task spec): agent, case, input.user_message,
# input.context, expected_behavior, assertions.
#
# Implementation: awk-based key-presence check. We do NOT parse YAML
# values; we only check that the named keys appear at the correct
# indentation. Block scalars (`|` / `>`) for the leaf string values
# count as present.
lint_fixture_file() {
    src="$1"
    missing=""

    # Top-level keys at column 0.
    for k in agent case input expected_behavior assertions; do
        if ! grep -E "^${k}:" "${src}" >/dev/null 2>&1; then
            missing="${missing} ${k}"
        fi
    done

    # input.user_message and input.context: must appear indented under
    # the `input:` block. Tolerant of 2-space indent (the convention in
    # the existing fixtures).
    if grep -E "^input:" "${src}" >/dev/null 2>&1; then
        if ! awk '
            /^input:/ { in_block = 1; next }
            /^[a-zA-Z_]/ { in_block = 0 }
            in_block && /^[ \t]+user_message[ \t]*:/ { found = 1 }
            END { exit found ? 0 : 1 }
        ' "${src}"; then
            missing="${missing} input.user_message"
        fi
        if ! awk '
            /^input:/ { in_block = 1; next }
            /^[a-zA-Z_]/ { in_block = 0 }
            in_block && /^[ \t]+context[ \t]*:/ { found = 1 }
            END { exit found ? 0 : 1 }
        ' "${src}"; then
            missing="${missing} input.context"
        fi
    fi

    if [ -n "${missing}" ]; then
        err "${src}" "missing required key(s):${missing}"
    fi
}

scan_fixtures() {
    [ -d "${FIXTURES_DIR}" ] || return
    # Walk every .yaml file under fixtures dir (any nesting depth).
    find "${FIXTURES_DIR}" -type f -name '*.yaml' 2>/dev/null \
        | LC_ALL=C sort \
        | while IFS= read -r f; do
            lint_fixture_file "${f}"
            printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
        done > "${TMP_COUNTERS}"
    last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
    if [ -n "${last}" ]; then
        e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
        w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
        [ -n "${e}" ] && ERR_COUNT="${e}"
        [ -n "${w}" ] && WARN_COUNT="${w}"
    fi
}

# ---- antigravity surface validation ----------------------------------
# Validates .agents/skills/<role>/SKILL.md and
# .agents/agents/<role>/agent.json files.
#
# Checks (per fw-adr-0026 Q-0033 § "Lint changes"):
#   SKILL.md:
#     - canonical_sha matches git rev-parse HEAD:.claude/agents/<role>.md
#     - description field present and non-empty
#     - classification: generated present
#   agent.json:
#     - canonical_sha matches same
#     - name field present
#     - classification field present with value "generated"
#   Stray files in .agents/skills/ or .agents/agents/ → warning.

# Extract a top-level YAML scalar value from a file.
# yaml_scalar <file> <key> — prints value or empty string.
# Handles bare scalars AND double-quoted scalars (W-4): strips surrounding
# double-quotes and unescapes \" → " and \\ → \ so canonical_sha and
# description checks pass for the double-quoted SKILL.md format.
yaml_scalar() {
    awk -v key="$2" '
        BEGIN { state = "pre" }
        {
            if (state == "pre") {
                if ($0 == "---") { state = "fm"; next }
                exit
            }
            if (state == "fm") {
                if ($0 == "---") { exit }
                line = $0
                sub(/^[ \t]+/, "", line)
                # Extract key name (up to first colon).
                k = line; sub(/:.*$/, "", k)
                sub(/[ \t]+$/, "", k)
                if (k == key) {
                    val = line
                    sub(/^[^:]*:[ \t]*/, "", val)
                    # Strip surrounding single quotes (bare) if present.
                    if (substr(val,1,1) == "\047" && substr(val,length(val),1) == "\047") {
                        val = substr(val, 2, length(val)-2)
                    # Strip surrounding double quotes and unescape (double-quoted scalar).
                    } else if (substr(val,1,1) == "\"" && substr(val,length(val),1) == "\"") {
                        val = substr(val, 2, length(val)-2)
                        # Unescape \" → " and \\ → \
                        # Use ["] instead of \" in regex to avoid gawk warning.
                        gsub(/\\["]/, "\"", val)
                        gsub(/\\\\/, "\\", val)
                    }
                    print val
                    exit
                }
            }
        }
    ' "$1"
}

# Extract a top-level JSON string field value from an agent.json.
# json_field <file> <key> — prints value or empty string.
# W-2: handles \" escape sequences inside values so fields whose content
# contains escaped quotes (e.g., description with internal quotes) are
# read correctly. Walks the value char-by-char tracking escape state.
json_field() {
    awk -v key="$2" '
        {
            line = $0
            # Match: "key": "value"
            pat = "\"" key "\""
            idx = index(line, pat)
            if (idx > 0) {
                rest = substr(line, idx + length(pat))
                # skip : and whitespace
                sub(/^[ \t]*:[ \t]*/, "", rest)
                if (substr(rest, 1, 1) == "\"") {
                    rest = substr(rest, 2)
                    # Walk chars tracking backslash-escape to find closing ".
                    val = ""
                    n = length(rest)
                    i = 1
                    while (i <= n) {
                        c = substr(rest, i, 1)
                        if (c == "\\") {
                            # consume escape pair
                            nc = substr(rest, i+1, 1)
                            if (nc == "\"") { val = val "\"" }
                            else if (nc == "\\") { val = val "\\" }
                            else if (nc == "n")  { val = val "\n" }
                            else if (nc == "t")  { val = val "\t" }
                            else if (nc == "r")  { val = val "\r" }
                            else { val = val nc }
                            i += 2
                        } else if (c == "\"") {
                            # closing quote
                            print val
                            exit
                        } else {
                            val = val c
                            i++
                        }
                    }
                } else if (substr(rest, 1, 5) == "false") {
                    print "false"
                    exit
                } else if (substr(rest, 1, 4) == "true") {
                    print "true"
                    exit
                }
            }
        }
    ' "$1"
}

lint_skill_file() {
    src="$1"
    role="$2"
    canonical="${AGENTS_DIR}/${role}.md"

    # canonical_sha check
    skill_sha="$(yaml_scalar "${src}" "canonical_sha")"
    if [ -z "${skill_sha}" ]; then
        err "${src}" "missing canonical_sha field"
    else
        if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
            expected_sha="$(git rev-parse "HEAD:${canonical}" 2>/dev/null || true)"
            if [ -n "${expected_sha}" ] && [ "${skill_sha}" != "${expected_sha}" ]; then
                err "${src}" "canonical_sha mismatch: file has ${skill_sha}, HEAD:${canonical} is ${expected_sha}"
            fi
        fi
    fi

    # description check
    desc_val="$(yaml_scalar "${src}" "description")"
    if [ -z "${desc_val}" ]; then
        err "${src}" "missing or empty description field"
    fi

    # classification check
    class_val="$(yaml_scalar "${src}" "classification")"
    if [ "${class_val}" != "generated" ]; then
        err "${src}" "classification must be 'generated', got '${class_val}'"
    fi
}

lint_agent_json() {
    src="$1"
    role="$2"
    canonical="${AGENTS_DIR}/${role}.md"

    if [ ! -f "${src}" ]; then
        return
    fi

    # canonical_sha check
    agent_sha="$(json_field "${src}" "canonical_sha")"
    if [ -z "${agent_sha}" ]; then
        err "${src}" "missing canonical_sha field"
    else
        if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
            expected_sha="$(git rev-parse "HEAD:${canonical}" 2>/dev/null || true)"
            if [ -n "${expected_sha}" ] && [ "${agent_sha}" != "${expected_sha}" ]; then
                err "${src}" "canonical_sha mismatch: file has ${agent_sha}, HEAD:${canonical} is ${expected_sha}"
            fi
        fi
    fi

    # name check
    name_val="$(json_field "${src}" "name")"
    if [ -z "${name_val}" ]; then
        err "${src}" "missing name field"
    fi

    # classification check
    class_val="$(json_field "${src}" "classification")"
    if [ "${class_val}" != "generated" ]; then
        err "${src}" "classification must be \"generated\", got '${class_val}'"
    fi
}

scan_antigravity() {
    skills_dir="${ANTIGRAVITY_DIR}/skills"
    agents_dir="${ANTIGRAVITY_DIR}/agents"

    # Walk expected roles (same set as compiler: .claude/agents/*.md minus
    # sme-template.md and non-kebab basenames).
    expected_roles="$(ls "${AGENTS_DIR}" 2>/dev/null \
        | grep '\.md$' \
        | sed 's/\.md$//' \
        | grep -E '^[a-z0-9][a-z0-9-]*$' \
        | grep -v '^sme-template$' \
        | LC_ALL=C sort)"

    # Early check: if canonical roles exist but adapter directories are
    # wholly absent, that is an error — the surfaces have not been generated.
    # (C-2: addresses S-1 from code-review; a missing directory means every
    # expected file is missing, which the per-role loop below also catches,
    # but this early error makes the root cause obvious.)
    if [ -n "${expected_roles}" ]; then
        if [ ! -d "${skills_dir}" ]; then
            err "${skills_dir}" "directory missing — run compile-runtime-agents.sh to generate Antigravity skill adapters"
        fi
        if [ ! -d "${agents_dir}" ]; then
            err "${agents_dir}" "directory missing — run compile-runtime-agents.sh to generate Antigravity agent adapters"
        fi
    fi

    for role in ${expected_roles}; do
        skill_path="${skills_dir}/${role}/SKILL.md"
        agent_path="${agents_dir}/${role}/agent.json"

        # C-2: ERROR if expected generated file is absent (mirrors --verify
        # behaviour for missing committed files). A missing file means the
        # canonical was edited without regenerating the adapter surface.
        if [ ! -f "${skill_path}" ]; then
            err "${skill_path}" "missing expected generated file — run compile-runtime-agents.sh to regenerate"
        else
            lint_skill_file "${skill_path}" "${role}"
        fi
        printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"

        if [ ! -f "${agent_path}" ]; then
            err "${agent_path}" "missing expected generated file — run compile-runtime-agents.sh to regenerate"
        else
            lint_agent_json "${agent_path}" "${role}"
        fi
        printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
    done > "${TMP_COUNTERS}"
    last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
    if [ -n "${last}" ]; then
        e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
        w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
        [ -n "${e}" ] && ERR_COUNT="${e}"
        [ -n "${w}" ] && WARN_COUNT="${w}"
    fi

    # Stray-file warnings: files in .agents/skills/ that don't match
    # <role>/SKILL.md pattern.
    if [ -d "${skills_dir}" ]; then
        find "${skills_dir}" -type f 2>/dev/null \
            | while IFS= read -r f; do
                # Normalize: strip leading .agents/skills/
                rel="${f#${skills_dir}/}"
                # Expected pattern: <role>/SKILL.md
                role_part="${rel%%/*}"
                file_part="${rel#*/}"
                case "${role_part}" in
                    *[!a-z0-9-]*|"") warn "${f}" "stray file in .agents/skills/ (role-dir name '${role_part}' is not a valid role slug)" ;;
                    *)
                        if [ "${file_part}" != "SKILL.md" ]; then
                            warn "${f}" "stray file in .agents/skills/${role_part}/ (expected SKILL.md only)"
                        fi
                        ;;
                esac
                printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
            done > "${TMP_COUNTERS}"
        last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
        if [ -n "${last}" ]; then
            e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
            w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
            [ -n "${e}" ] && ERR_COUNT="${e}"
            [ -n "${w}" ] && WARN_COUNT="${w}"
        fi
    fi

    # Stray-file warnings: files in .agents/agents/ that don't match
    # <role>/agent.json pattern.
    if [ -d "${agents_dir}" ]; then
        find "${agents_dir}" -type f 2>/dev/null \
            | while IFS= read -r f; do
                rel="${f#${agents_dir}/}"
                role_part="${rel%%/*}"
                file_part="${rel#*/}"
                case "${role_part}" in
                    *[!a-z0-9-]*|"") warn "${f}" "stray file in .agents/agents/ (role-dir name '${role_part}' is not a valid role slug)" ;;
                    *)
                        if [ "${file_part}" != "agent.json" ]; then
                            warn "${f}" "stray file in .agents/agents/${role_part}/ (expected agent.json only)"
                        fi
                        ;;
                esac
                printf 'COUNTERS\t%d\t%d\n' "${ERR_COUNT}" "${WARN_COUNT}"
            done > "${TMP_COUNTERS}"
        last="$(tail -1 "${TMP_COUNTERS}" 2>/dev/null || true)"
        if [ -n "${last}" ]; then
            e="$(printf '%s' "${last}" | awk -F'\t' '{print $2}')"
            w="$(printf '%s' "${last}" | awk -F'\t' '{print $3}')"
            [ -n "${e}" ] && ERR_COUNT="${e}"
            [ -n "${w}" ] && WARN_COUNT="${w}"
        fi
    fi
}

# ---- main dispatch ---------------------------------------------------
TMP_COUNTERS="$(mktemp)"
trap 'rm -f "${TMP_COUNTERS}"' EXIT INT TERM

case "${MODE}" in
    all)
        scan_canonical
        scan_fixtures
        scan_generated
        scan_antigravity
        ;;
    canonical)
        scan_canonical
        ;;
    generated)
        scan_generated
        ;;
    fixtures)
        scan_fixtures
        ;;
    antigravity)
        scan_antigravity
        ;;
esac

printf 'lint-agent-contracts: %d errors, %d warnings\n' \
    "${ERR_COUNT}" "${WARN_COUNT}" >&2

if [ "${ERR_COUNT}" -gt 0 ]; then
    exit 1
fi
exit 0
