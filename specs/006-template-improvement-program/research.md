# Phase 0 Research

**Plan**: [plan.md](./plan.md)
**Spec**: [spec.md](./spec.md)
**Date**: 2026-05-13

Resolves the implementation-tooling unknowns left open by `spec.md` and `plan.md`. Customer-policy questions were already resolved across three rounds of `/speckit-clarify` (14 bullets in spec § Clarifications). Items below are tooling/quantification choices the team makes.

---

## R-1 — Markdown compiler tool selection (M6)

**Decision**: Custom compiler implemented as Bash + jq + Python helpers, shipped as `scripts/compile-runtime-agents.sh` and `scripts/lint-agent-contracts.sh`. **Do not** adopt LLMD.

**Rationale**:
- The customer's source plan references "LLMD" as illustrative ("LLMD or similar tooling"). Web search confirms the most prominent LLMD project ([akatz-ai/llmd](https://github.com/akatz-ai/llmd)) is a CLI that bundles a git repo into a single Markdown blob for LLM-context prompting — not a section-extracting, schema-validating contract compiler.
- M6 needs deterministic generation of *compact runtime contracts* from canonical `.claude/agents/*.md` files (specific frontmatter, sections, hard rules, escalation format) plus schema-validated OpenCode adapters (FR-021, FR-022). LLMD's bundling model fits none of these.
- FR-023 requires the compiler to be deterministic, reproducible, and to identify canonical inputs in output frontmatter. Custom code under our review meets this; an external tool with semantic changes between versions does not (risk listed in source plan §7, "LLMD changes semantics").
- Existing project pattern is bash/python scripting; introducing a Node or external markdown-compiler runtime would expand the dependency surface for a task that is fundamentally text manipulation.

**Alternatives considered**:
- **LLMD (akatz-ai/llmd)**: bundles a repo for LLM prompting; no section extraction, no schema validation, no frontmatter regeneration. Rejected for FR-022/FR-023.
- **llm-md (llm.md)**: a multi-provider runtime framework. Out of scope — we already route models via M5; not a Markdown compiler.
- **MarkItDown (Microsoft)**: converts heterogeneous file formats into LLM-ready Markdown. Wrong direction (input is already Markdown).
- **Pandoc + Lua filters**: powerful but heavy; section extraction is simpler with `awk`/`jq` against frontmatter delimiters than a Pandoc AST transform.

**Output**:
- `scripts/compile-runtime-agents.sh` (FR-023): parses canonical agent files into frontmatter + sections (`awk` on `---` and `## ` boundaries), filters sections by an allowlist defined in `schemas/agent-contract.schema.json`, regenerates the compact contract with a canonical-input pointer in frontmatter (`canonical_source: .claude/agents/<role>.md`, `canonical_sha: <git blob sha>`), and validates output against `schemas/generated-artifact.schema.json` before exit.
- `scripts/lint-agent-contracts.sh` (FR-023): validates canonical agent files against `schemas/agent-contract.schema.json`. Both scripts return non-zero on any failure; CI workflow `agent-contract-check.yml` (FR-028) gates PRs.

---

## R-2 — Token-budget band quantification (M2.1)

**Decision**: Default bands by word-count proxy (`wc -w` against the read set), documented in `docs/templates/task-template.md`:

| Band | Words (proxy) | Tokens (approx) | Intended use |
|---|---:|---:|---|
| Tiny | < 1 500 | < ~2 000 | one-file fix, no specialist chain |
| Small | 1 500 – 6 000 | ~2 000 – ~8 000 | one specialist, focused files |
| Medium | 6 000 – 19 000 | ~8 000 – ~25 000 | 2–3 specialists, limited docs |
| Large | 19 000 – 60 000 | ~25 000 – ~80 000 | triggered workflow, multiple artifacts |
| XL | > 60 000 | > ~80 000 | split unless explicitly approved |

**Rationale**: Word-count proxy is portable (`wc -w` everywhere), reproducible (no network call), and stable across model token boundaries. Token approximations assume ~1 token ≈ 0.75 words for English Markdown (Anthropic tokenizer behavior). Bands are PM-tunable — `docs/pm/LESSONS.md` captures band-drift observations and the bands are reviewed at M2 gate close and at G9.

**Alternatives considered**:
- Anthropic SDK `client.count_tokens()`: exact but requires network call and the SDK at task-template-fill time. Rejected for portability.
- `tiktoken` (OpenAI's BPE): approximate for Claude (~5–10% drift); requires Python install. Rejected — adds dependency without changing percentage-based SCs.
- Per-agent bands: more accurate but four times the maintenance burden; rejected for V1.

---

## R-3 — Patch-size limit for the M7 self-improvement loop (FR-027)

**Decision**: One PR per run; **≤400 added+removed lines** total; **≤10 files** changed; **1 commit** (squash-merge enforced). If the proposed change exceeds either ceiling, the loop opens a framework-gap issue describing the change instead of opening a PR.

**Rationale**: 200–400 LOC is the published threshold above which human review quality drops sharply (cf. SmartBear study; Google Engineering practices). 10 files prevents subtle cross-file effects bypassing review. Single commit keeps the PR auditable and the rollback atomic. Spilling to an issue preserves the signal without flooding the queue.

**Alternatives considered**:
- 200 LOC ceiling: too tight for legitimate doc-rewrites that the bot will surface.
- 1 000 LOC ceiling: too loose; loses the review-quality benefit.
- File-count only (no LOC cap): vulnerable to one giant file changing.

**CI enforcement**: The `improve-template.yml` workflow runs the size check before PR creation and aborts with an issue if the threshold is crossed.

---

## R-4 — Tokenizer for M0 baseline measurement (FR-002)

**Decision**: `wc -l` for line counts; `wc -w` for word-count proxy of tokens; `git rev-parse HEAD` to stamp the baseline. Output to `docs/pm/token-economy-baseline.md` as a Markdown table.

**Rationale**: SC-001 and SC-002 use *percentage* reductions, not absolute token counts. A stable proxy is sufficient; precision matters only insofar as the same proxy is used at baseline and post-M1. `wc -w` meets that requirement, is POSIX, and runs in milliseconds. The source plan explicitly endorses "simple tokenizer or word-count proxy" (M0 § Measurements).

**Alternatives considered**:
- `tiktoken cl100k_base`: tighter to Claude tokenization but adds Python+pip dependency for a measurement whose comparison ratio is stable across tokenizer choice.
- Anthropic `count_tokens` API: network round-trip per file; rejected on cost and reproducibility (network failure = unmeasurable).

**Script**: `scripts/baseline-token-economy.sh` is idempotent — re-runs produce the same file given the same git state.

---

## R-5 — Compaction-failure runtime recovery posture (M6 edge case)

**Decision**: Two-layer safety. **Layer 1 (preventive)**: CI gate `agent-contract-check.yml` (FR-028) blocks any PR whose generated runtime contracts fail prompt-regression or schema validation; failing output never lands in main. **Layer 2 (runtime belt)**: runtime loader (the file-read pattern used by Claude Code / OpenCode adapters) treats a missing or malformed `docs/runtime/agents/<role>.md` as a soft error and falls back to the canonical `.claude/agents/<role>.md`, with a warning logged to `docs/pm/LESSONS.md` for follow-up.

**Rationale**: The compiler is a generator, not source of truth (FR-023 + Constitution VII). A failed compile must never compromise role authority. The CI gate keeps bad output out of `main`; the runtime fallback ensures that if it ever slips through (e.g., manual misuse or a corrupted file), the agents still operate from the canonical contracts.

**Alternatives considered**:
- Hard runtime fail: refuses to load the agent; brittle (one stale file blocks the whole session).
- Soft warn + continue with broken compact: violates Constitution VII (silently loses hard rules).

---

## R-6 — JSON Schema validator (FR-022)

**Decision**: `check-jsonschema` (the [check-jsonschema](https://github.com/python-jsonschema/check-jsonschema) CLI from python-jsonschema). Installed via pipx in CI; available via system Python locally. Schema dialect: JSON Schema 2020-12.

**Rationale**: Single mature Python dependency, supports 2020-12, fast, ships as a CLI (no wrapper code needed), maintained by the upstream `python-jsonschema` team. Compatible with the existing CI pattern of using ubuntu-latest with Python 3.11.

**Alternatives considered**:
- `ajv-cli`: Node.js requirement adds a second runtime to the toolchain.
- Inline `python -m jsonschema`: requires wrapper script; less ergonomic than the dedicated CLI.

---

## R-7 — OpenCode adapter generation pattern (M5.4, FR-021)

**Decision**: Each adapter is a single-file Markdown stub generated by `scripts/compile-runtime-agents.sh` with frontmatter pointing to the canonical role file and an optional local supplement path. Body content is a fixed template; no role text is duplicated.

Generated form:

```markdown
---
name: <role>
model: <configured-model-class>
canonical_source: .claude/agents/<role>.md
canonical_sha: <git-blob-sha>
local_supplement: .opencode/agents/local/<role>.md  # optional
generator: scripts/compile-runtime-agents.sh
generator_version: <semver>
---

Read `.claude/agents/<role>.md` (canonical role contract).
If `local_supplement` resolves to an existing file, read it after the canonical file.
Act only as that role.
Return output in the role's required format.
```

**Rationale**: Single-file stub keeps the adapter readable; frontmatter carries everything the lint and the harness need (model class, canonical input, generator provenance). No role text is duplicated, satisfying FR-021. Manual edits to the body or frontmatter `canonical_*` fields are caught by the lint (the body must match the template exactly; `canonical_sha` must match the current canonical file).

**Alternatives considered**:
- Full role text inlined per harness (current bad pattern OpenCode encourages): duplicated content, violates FR-021 and Constitution III.
- Stub + sidecar JSON: two files where one suffices; rejected for clutter.

---

## R-8 — Question-lint detection mechanism (M3.4, FR-012)

**Decision**: A bash + grep + awk pipeline keyed off five patterns, with the hard-gate cutoff via the recorded `HARDGATE_AFTER_SHA` (per spec clarification 13). Patterns:

1. Compound seed question: a row in scoping-questions ending with `?` and containing one of `, and `, `; `, `\.\s+[A-Z]`, or `\?` more than once.
2. Multi-numbered customer question: a paragraph that contains `^\s*[0-9]+\.\s` more than once before the next `?`.
3. Multiple independent option sets: more than one `<details>`, `<table>`, or `## Option` block within a customer-facing turn.
4. Non-empty `agents-running-at-ask` metadata in an OPEN_QUESTIONS row.
5. Compound OPEN_QUESTIONS row: the `question` column passes pattern 1.

Implementation:
- `scripts/lint-questions.sh` walks the staged diff (or full repo on schedule) and emits a non-zero exit on hard-gated violations after `HARDGATE_AFTER_SHA`; warnings only before that SHA.
- Fixture corpus in `tests/lint-questions/` covers known-bad and known-good rows (one per pattern × pass/fail).

**Rationale**: Pattern matching is deterministic, runs in under a second, and is debuggable. Each pattern maps to a concrete violation type the customer named in the source plan §M3.4.

**Alternatives considered**:
- LLM-based judge: non-deterministic and adds inference cost on every PR; rejected.
- Tree-sitter Markdown parsing: overkill for line-level patterns.

---

## R-9 — M8 boundary-check script design (FR-029, FR-030)

**Decision**: `scripts/m8-boundary-check.sh` checks two conditions per PR in a downstream repo:
1. **Product/framework boundary** (FR-030): if any path in the diff matches the framework-managed prefix list (`CLAUDE.md`, `AGENTS.md`, `.claude/agents/`, `docs/adr/`, `docs/framework-project-boundary.md`, `docs/model-routing-guidelines.md`, `.github/workflows/`, `migrations/`, `VERSION`, `TEMPLATE_MANIFEST.lock`) AND any path matches the product prefix list, the PR's task ID MUST appear under `## Mixed-PR authorizations` in `CUSTOMER_NOTES.md`; otherwise fail.
2. **M8 deferred deliverables** (FR-029): for each deliverable in `M8_REQUIRED_DELIVERABLES` (defined in the script), either the deliverable's marker file exists (e.g., `docs/intake-log.md` exists, `docs/pm/SCHEDULE-EVIDENCE.md` exists) or an open issue against `sw-dev-team-template` exists naming both the deliverable and the downstream repo (queried via `gh issue list --repo <upstream> --label m8-waiver --search "<deliverable> <downstream-repo>"`). Otherwise fail.

**Rationale**: Single script, two checks, single grep/gh-query mechanism per check. Matches the customer's accepted clarifications (Q7, Q12 of round 2/3).

**Alternatives considered**:
- Two separate scripts: more code paths, more places to forget to wire into CI.
- GitHub Actions-native check via marketplace action: introduces marketplace-action provenance risk; rolling our own bash is auditable.

---

## R-10 — Model-routing fallback wrapper (M5.3, FR-020)

**Decision**: `scripts/log-fallback.sh` is the canonical fallback recorder, invoked by whichever routing layer makes the substitution. Output format: one JSONL row per event, appended to `docs/pm/fallback-log.jsonl` (live, rolled monthly to `docs/pm/fallback-log-<YYYY-MM>-ARCHIVE.jsonl`).

Required fields (FR-020):

```json
{"agent": "software-engineer", "requested_model": "anthropic/claude-sonnet-4-7", "actual_model": "anthropic/claude-sonnet-4-6", "fallback_reason": "credit_exhausted", "timestamp": "2026-05-13T15:42:00Z", "task_id": "T-0142"}
```

Substitution policy (spec clarification 8): same-class peer first; one-tier-down if no peer; the downgrade is recorded in `fallback_reason` as `"<original_reason>; downgraded_one_tier"`.

**Rationale**: JSONL is grep-able, append-only, schema-compatible with downstream observability tools, and survives partial writes (line-oriented). Logging the event without changing role authority or output format satisfies FR-020.

**Alternatives considered**:
- Markdown table log: harder to ingest by tooling, harder to roll.
- Per-agent log files: distributes the signal; rejected for analysis ergonomics.

---

## R-11 — Prompt-regression test harness (M6.3, FR-024)

**Decision**: Each test case is a YAML fixture under `tests/prompt-regression/<agent>/<case>.yaml` carrying:

```yaml
agent: tech-lead
case: compound-customer-question
input:
  user_message: "Should we use OAuth2 and store sessions in Redis?"
  context: "All agents idle."
expected_behavior:
  - "Refuses to bundle decision axes."
  - "Routes one of the two questions to OPEN_QUESTIONS.md."
  - "Asks one atomic question OR queues both and stays silent."
assertions:
  - kind: regex_absent
    pattern: "^.*\\?.*\\?.*$"
    in: customer_facing_lines
  - kind: customer_question_count_le
    value: 1
```

The harness loads each canonical agent file and the compiled runtime contract, feeds the input through the team's standard test fixture (Claude Sonnet 4.x, fixed seed where the API supports it; otherwise N=3 with majority-vote on assertion results), and records pass/fail to `tests/prompt-regression/results-<YYYY-MM-DD>.md`. CI workflow `agent-contract-check.yml` runs against canonical only on every PR; the full canonical+compiled run executes on a nightly schedule and at every MINOR-boundary Release event.

**Rationale**: YAML fixtures are reviewable, the assertion vocabulary (regex_absent, customer_question_count_le, contains, role_authority_intact) is small and extensible, and the canonical-vs-compiled split keeps PR latency low while preserving the compiled-output gate at release.

**Alternatives considered**:
- Pure unit-test-in-Python: harder for non-engineers (qa-engineer, researcher) to author cases.
- LLM-as-judge: non-deterministic; reserve for ambiguity-resolution within a case, not as the primary assertion.

---

## R-12 — Documentation Authority Policy text (M4.1)

**Decision**: Three-sentence policy inserted as a top-level section of `docs/framework-project-boundary.md`:

```markdown
## Documentation Authority

Every artifact in this repository is canonical, generated, or ephemeral.
Manual mirrors of shared content are prohibited: if two files need the same content, one MUST be generated from the other, link to the other, or be removed in favor of the other.
Generated artifacts MUST identify their canonical inputs and be reproducible by documented tooling before they are used as operational guidance.
```

**Rationale**: Short enough to keep `framework-project-boundary.md` lean (Constitution II), specific enough to make violations grep-able by `code-reviewer`, and uses the exact tri-classification already canonical to the project (CLAUDE.md, Constitution III).

**Alternatives considered**:
- Standalone `docs/policies/documentation-authority.md`: adds a new live surface; rejected for token economy.
- Three separate policy bullets across multiple docs: violates the "one canonical home" principle the policy itself names.

---

## R-13 — PR sequencing through the milestone plan

**Decision**: Follow the source plan's §5 table (PR-1 through PR-16+) verbatim. M0 and M1 may proceed in parallel slices (the baseline measurement does not block M1.1 compaction prototyping), but **no PR from M5 onward begins before G1 closes** (rule in spec § Assumptions and source plan §4 "Do not start with OpenCode integration before token/authority fixes").

**Rationale**: Customer-accepted slicing in the source plan; no Phase-0 reason to deviate.

---

## Summary table

| Topic | Decision | FR/SC | Owner |
|---|---|---|---|
| R-1 | Custom bash/python compiler; not LLMD | FR-022, FR-023 | software-engineer |
| R-2 | Token-budget bands defined by word-count proxy | FR-007 | project-manager |
| R-3 | Self-improvement patch limit: ≤400 LOC, ≤10 files, 1 commit | FR-027 | release-engineer |
| R-4 | M0 measurement: `wc -w` / `wc -l` proxy | FR-002, SC-001, SC-002 | project-manager |
| R-5 | Compaction-failure: CI gate + runtime canonical fallback | FR-023 | software-engineer + sre |
| R-6 | Schema validator: `check-jsonschema` | FR-022 | software-engineer |
| R-7 | OpenCode adapter: single-file stub, frontmatter-canonical pointer | FR-021 | release-engineer |
| R-8 | Question-lint: five bash+grep patterns, SHA-cutoff hard-gate | FR-012 | software-engineer + qa-engineer |
| R-9 | M8 boundary check: single bash script with two checks | FR-029, FR-030 | software-engineer |
| R-10 | Fallback log: JSONL with monthly rollover | FR-020 | release-engineer |
| R-11 | Prompt-regression: YAML fixtures, canonical-on-PR + canonical+compiled at MINOR | FR-024 | qa-engineer |
| R-12 | Documentation Authority Policy: 3-sentence insert into `docs/framework-project-boundary.md` | FR-014 | tech-writer |
| R-13 | PR sequencing follows source plan §5 verbatim | FR-033 | project-manager |

All NEEDS CLARIFICATION items resolved. Ready for Phase 1.

Sources:
- [llm-md (llm.md)](https://llm.md/)
- [akatz-ai/llmd repo bundler](https://github.com/akatz-ai/llmd)
- [llm-wiki-compiler](https://deepwiki.com/atomicmemory/llm-wiki-compiler/1.1-getting-started)
- [check-jsonschema](https://github.com/python-jsonschema/check-jsonschema)
