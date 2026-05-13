# Phase 1 Data Model

**Plan**: [plan.md](./plan.md)
**Spec**: [spec.md](./spec.md)
**Research**: [research.md](./research.md)
**Date**: 2026-05-13

Entities, fields, relationships, and state transitions for the program. This is a documentation/tooling project — there is no application database. The "data" here is the structured shape of Markdown / JSONL / shell-script artifacts the program produces and validates.

---

## Entity catalog

### E-1 Canonical agent contract

The human-maintained source of truth for an agent role.

| Field | Type | Notes |
|---|---|---|
| `name` | string (kebab-case slug) | Identifier; matches file basename and SendMessage `to`. PK. |
| `description` | string | One-paragraph PROACTIVE purpose statement |
| `model` | optional string | Default model class; absent → use `model-routing-guidelines.md` |
| `tools` | string | Comma-separated tool allowlist or `*` |
| `role_overview` | section | Heading + body |
| `hard_rules` | section | Heading + array of `{id, text}` rules |
| `escalation` | section | Heading + body; MUST describe routing to tech-lead |
| `output_format` | section | Heading + body |
| `allowed_tools` | optional section | Heading + array of tool names. Tools canonically live in `frontmatter.tools` (Claude Code convention); a body section MAY restate them in human-readable form but MUST NOT diverge from the frontmatter list. |
| `local_supplement_rule` | optional section | How project-local supplements interact |
| `customer_interface_rule` | section (required for tech-lead) | Sole-interface declaration |

**Path**: `sw-dev-team-template/.claude/agents/<name>.md`
**Classification**: canonical (Constitution III)
**Validated by**: `schemas/agent-contract.schema.json` (FR-022)
**Relationships**: produces 1..N → [E-2 Generated runtime contract]; produces 1..N → [E-3 OpenCode adapter]; referenced by [E-7 Routing config] via `name`.

### E-2 Generated runtime contract

A compact, deterministic projection of an E-1 canonical contract for runtime context-cost reduction.

| Field | Type | Notes |
|---|---|---|
| `name` | string | Mirrors E-1.name |
| `description` | optional string | Mirrored from canonical's frontmatter for reader convenience; not authoritative. |
| `canonical_source` | path | `.claude/agents/<name>.md` |
| `canonical_sha` | git blob SHA | Of the canonical source at generation time |
| `generator` | path | `scripts/compile-runtime-agents.sh` |
| `generator_version` | semver | Generator script version |
| `classification` | const "generated" | Required; lint rejects otherwise |
| `body` | filtered sections | Allowlist from agent-contract schema; rationale and examples stripped to E-1's paired manual |

**Path**: `sw-dev-team-template/docs/runtime/agents/<name>.md`
**Classification**: generated
**Validated by**: `schemas/generated-artifact.schema.json`
**State transitions**:
  `non-existent` → (compile-runtime-agents.sh) → `current` (canonical_sha matches canonical file) → (canonical edited) → `stale` (CI hard-fail; rerun generator) → `current`.

### E-3 OpenCode adapter

A thin Markdown stub pointing the OpenCode harness at an E-1 canonical contract.

| Field | Type | Notes |
|---|---|---|
| `name` | string | Mirrors E-1.name |
| `model` | string | Configured model class for OpenCode |
| `description` | optional string | Mirrored from canonical's frontmatter for reader convenience; not authoritative. |
| `canonical_source` | path | `.claude/agents/<name>.md` |
| `canonical_sha` | git blob SHA | |
| `local_supplement` | optional path | `.opencode/agents/local/<name>.md` |
| `generator` | path | `scripts/compile-runtime-agents.sh` |
| `generator_version` | semver | |
| `classification` | const "generated" | |

**Path**: `sw-dev-team-template/.opencode/agents/<name>.md`
**Classification**: generated
**Validated by**: `schemas/generated-artifact.schema.json` (FR-021)
**Invariant**: body MUST exactly match the canonical adapter-stub template (R-7); no role text duplicated.

### E-4 Live register row

A current-state row in a bounded live register file (`OPEN_QUESTIONS.md`, `intake-log.md`, `RISKS.md`, `LESSONS.md`, `CUSTOMER_NOTES.md` where safe, `SCHEDULE.md`).

| Field | Type | Notes |
|---|---|---|
| `id` | string | Stable ID (e.g., `OQ-0042`, `R-0007`) |
| `created_at` | ISO 8601 date | |
| `answered_at` | optional ISO 8601 date | Set when row reaches a terminal status |
| `status` | enum | `open`, `in-progress`, `answered`, `superseded`, `withdrawn` |
| `body` | markdown row | Live content |

**Live-bound rule** (spec clarification 1): a row is live iff `status == open` OR `answered_at >= most_recent_milestone_close_date`. Otherwise it MUST be moved to the paired archive.
**Classification**: canonical (CUSTOMER_NOTES, OPEN_QUESTIONS, intake-log) or ephemeral (RISKS, LESSONS, SCHEDULE — generated/operational).
**Managed by**: `scripts/archive-registers.sh` (FR-004).
**State transitions**:
  `open` → `in-progress` → `answered` | `superseded` | `withdrawn`. Once terminal AND `answered_at < most_recent_milestone_close_date`, archival script moves row to paired archive on next scheduled run.

### E-5 Token-ledger entry

Compact row recording a task's token spend.

| Field | Type | Notes |
|---|---|---|
| `date` | ISO 8601 date | |
| `task_id` | string | PK |
| `agent` | string | |
| `prompt_hash` | sha256 | Of the full prompt; matches `docs/pm/token-ledger/prompts/<task-id>-<agent>.md` |
| `prompt_class` | enum | `dispatch`, `regen`, `audit`, `summary`, `interactive` |
| `token_budget` | enum | `tiny`, `small`, `medium`, `large`, `xl` (R-2) |
| `token_actual` | integer | Words measured by `wc -w` proxy |
| `notes` | string | Optional |

**Path**: `sw-dev-team-template/docs/pm/token-ledger/ledger.md`
**Classification**: ephemeral
**Companion artifact**: `docs/pm/token-ledger/prompts/<task-id>-<agent>.md` (full prompt, optional; kept only when calibration disputes are likely).

### E-6 Fallback log entry

JSONL record of one model-fallback event.

| Field | Type | Notes |
|---|---|---|
| `agent` | string | Role that invoked the model |
| `requested_model` | string | Provider/model identifier requested |
| `actual_model` | string | Provider/model identifier actually used |
| `fallback_reason` | enum + optional suffix | One of `credit_exhausted`, `provider_unavailable_5xx`, `provider_timeout`, `provider_rate_limit`; optionally `; downgraded_one_tier` if no same-class peer was available |
| `timestamp` | ISO 8601 | |
| `task_id` | string | |

**Path**: `sw-dev-team-template/docs/pm/fallback-log.jsonl` (live), `fallback-log-<YYYY-MM>-ARCHIVE.jsonl` (monthly rollover)
**Classification**: ephemeral
**Substitution policy** (spec clarification 8): closest peer in same class → one tier down (logged in `fallback_reason`).

### E-7 Routing config

The model-routing table: per-agent default class + fallback policy.

| Field | Type | Notes |
|---|---|---|
| `version` | semver | Bumped when defaults change |
| `binding` | bool | true for upstream default; false for project-local override |
| `agents[].agent` | string | Role slug |
| `agents[].default_class` | enum | claude-opus, claude-sonnet, claude-haiku, gemini-pro, gemini-flash, openai-frontier, openai-coding, openai-mini |
| `agents[].frontier_only_when` | string | Plain-language predicate |
| `fallback.triggers` | array | Subset of E-6 reasons |
| `fallback.substitution_policy` | const | "closest-peer-then-one-tier-down" |
| `fallback.log_path` | path | `docs/pm/fallback-log.jsonl` |
| `project_local_override_marker` | required if !binding | Identifies project-local override |

**Path**: `sw-dev-team-template/docs/model-routing-guidelines.md`
**Classification**: canonical (upstream); canonical-with-override-marker (project-local supplement)
**Validated by**: `schemas/model-routing.schema.json` (FR-022)

### E-8 Framework-gap issue

A GitHub issue on `sw-dev-team-template` filed by a downstream consumer (or the AI improvement loop) reporting a gap, friction, or M8 deferred deliverable.

| Field | Type | Notes |
|---|---|---|
| `number` | int | GitHub-assigned PK |
| `template_version` | semver from TEMPLATE_VERSION | Required field |
| `downstream_context` | string | Repo / project where observed |
| `affected_layer` | enum | `agent-contract`, `docs`, `scripts`, `workflows`, `migrations`, `meta`, `m8-deliverable` |
| `observed_behavior` | text | |
| `expected_behavior` | text | |
| `redaction_confirmed` | bool | Required per FR-026 |
| `proposed_acceptance_criteria` | text | |
| `labels` | array of strings | From FR-025 taxonomy |

**Path**: GitHub Issues on `sw-dev-team-template`
**Classification**: ephemeral (becomes canonical evidence when referenced in a PR or LESSONS entry)
**Created via**: `.github/ISSUE_TEMPLATE/framework-gap.yml` (FR-026)
**Used by**: M8 boundary check (FR-029) for waiver verification.

### E-9 Gate (G0–G9)

A pass-criteria predicate over a milestone's deliverables.

| Field | Type | Notes |
|---|---|---|
| `id` | enum `G0..G9` | PK |
| `milestone` | enum `M0..M9` | |
| `pass_criteria` | array of testable statements | Drawn from spec § User Story acceptance scenarios |
| `status` | enum | `pending`, `in-progress`, `passed`, `passed-with-waivers`, `blocked` |
| `passed_at` | optional ISO 8601 | Set when status enters `passed*` |
| `waivers` | array of E-8 references | Used when `status == passed-with-waivers` (FR-029 path) |

**Path**: `sw-dev-team-template/docs/pm/SCHEDULE.md` rows
**Classification**: ephemeral (live operational state)
**State transitions**:
  `pending` → `in-progress` (when first PR for the milestone opens) → `passed` (all pass_criteria met, all canonical-role sign-offs recorded) | `passed-with-waivers` (at G8 only, with FR-029 issue references) | `blocked` (with reason logged in LESSONS).

### E-10 Question-lint rule

A pattern check enforced by `scripts/lint-questions.sh`.

| Field | Type | Notes |
|---|---|---|
| `id` | string | `QL-001..QL-005` |
| `description` | string | What the rule detects |
| `pattern` | regex or predicate | Implementation detail |
| `severity` | enum | `warning` before `HARDGATE_AFTER_SHA`; `error` after |
| `grandfather_after_sha` | optional git SHA | Below this SHA, rule never fires for legacy rows (spec clarification 13) |

**Implemented in**: `sw-dev-team-template/scripts/lint-questions.sh` (FR-012)
**Tested by**: `tests/lint-questions/` fixture corpus.

### E-11 Self-improvement run

An invocation of `.github/workflows/improve-template.yml`.

| Field | Type | Notes |
|---|---|---|
| `run_id` | GitHub Actions run ID | |
| `triggered_at` | ISO 8601 | |
| `input_issues` | array of E-8 numbers | Issues considered in this batch |
| `proposed_change` | path-of-paths + diff summary | One change per run (FR-027) |
| `patch_size` | object | `{lines: int, files: int, commits: int}` |
| `protected_files_touched` | array of paths | MUST be empty unless via paired `docs/proposals/` |
| `customer_truth_touched` | array of paths | MUST be empty unless via paired `docs/proposals/` |
| `outcome` | enum | `pr_opened`, `issue_filed_oversize`, `no_op`, `gate_failed` |
| `pr_number` | optional int | Set when `outcome == pr_opened` |

**State transitions**:
  `triggered` → `gathering_inputs` → `proposing_change` → (size check) → `pr_opened` | `issue_filed_oversize` | (gate check) → `gate_failed` | (no improvements warranted) → `no_op`.
**Path size invariants** (R-3): `lines <= 400`, `files <= 10`, `commits == 1`.
**Protected-files invariant** (FR-027): `protected_files_touched.length == 0 AND customer_truth_touched.length == 0` unless the change is a paired Markdown proposal under `docs/proposals/`.

### E-12 Prompt-regression case

A test fixture covering an agent's behavioral assertion.

| Field | Type | Notes |
|---|---|---|
| `agent` | string | Canonical role slug |
| `case` | string | Unique within agent |
| `input.user_message` | string | Triggering message |
| `input.context` | string | Pre-conditions (idle state etc.) |
| `expected_behavior` | array of strings | Human-readable assertions |
| `assertions` | array of `{kind, ...}` | Mechanical checks: `regex_absent`, `customer_question_count_le`, `contains`, `role_authority_intact` |

**Path**: `sw-dev-team-template/tests/prompt-regression/<agent>/<case>.yaml`
**Classification**: canonical (test fixture)
**Executed by**: prompt-regression harness (R-11); results in `tests/prompt-regression/results-<YYYY-MM-DD>.md`.

### E-13 Reference downstream repo

One of `QuackDCS`, `QuackPLC`, `QuackS7`, `QuackSim`. External target of M8 repair.

| Field | Type | Notes |
|---|---|---|
| `name` | enum | One of the four |
| `scaffold_mode` | enum | `retrofitted` or `from-template` |
| `m8_status` | enum | `pending`, `repaired`, `repaired-with-waivers`, `blocked` |
| `deferred_deliverables` | array of E-8 references | Open issues against `sw-dev-team-template` |

**Path**: Not in the template repo; tracked in `docs/pm/SCHEDULE.md` M8 rows.

### E-14 Token-economy baseline snapshot

The single one-shot measurement file produced by `scripts/baseline-token-economy.sh` at M0 close.

| Field | Type | Notes |
|---|---|---|
| `captured_at` | ISO 8601 | |
| `template_sha` | git SHA | At measurement time |
| `agent_line_counts` | array of `{role, lines, words}` | Per-agent `wc -l` + `wc -w` |
| `live_register_sizes` | array of `{file, rows, words}` | Per-register |
| `open_questions_answered_live` | int | Rows with `status == answered` still live |
| `pm_schedule_length` | int | Lines in `docs/pm/SCHEDULE.md` |
| `downstream_intake_log_present` | array of `{repo, present_bool}` | For each E-13 |
| `broken_internal_refs` | array of `{file, ref}` | Markdown links to missing paths |
| `downstream_template_versions` | array of `{repo, template_version}` | From each downstream's `TEMPLATE_VERSION` |

**Path**: `sw-dev-team-template/docs/pm/token-economy-baseline.md`
**Classification**: ephemeral (one-shot snapshot; superseded by next baseline pass)
**Idempotent**: same input → same output (R-4).

---

## Entity relationship summary

```text
[E-1 Canonical agent contract]
  ├── 1..* generates ──> [E-2 Generated runtime contract]
  ├── 1..* generates ──> [E-3 OpenCode adapter]
  ├── 1..1 referenced by ──> [E-7 Routing config]
  └── 1..* validated by ──> [E-12 Prompt-regression case]

[E-4 Live register row]
  └── archived to ──> paired archive file (append-only)

[E-5 Token-ledger entry]
  └── optional 1..1 archives to ──> docs/pm/token-ledger/prompts/<task-id>-<agent>.md

[E-6 Fallback log entry]
  └── 1..1 produced by ──> routing wrapper invoking [E-7 Routing config]

[E-8 Framework-gap issue]
  ├── 1..* satisfies ──> [E-9 Gate].waivers (M8 path)
  ├── 1..* attributed to ──> [E-13 Reference downstream repo]
  └── 1..* triggers (eventually) ──> [E-11 Self-improvement run].input_issues

[E-9 Gate]
  └── M-by-M sequence: G0 → G1 → G2 → ... → G9

[E-10 Question-lint rule]
  └── 1..* tested by ──> tests/lint-questions/ fixtures

[E-11 Self-improvement run]
  └── 1..1 emits ──> PR | issue | no-op

[E-14 Token-economy baseline snapshot]
  └── 1..1 anchored at ──> M0 close (FR-002, SC-001, SC-002 measurement basis)
```

---

## Validation rules (cross-entity)

- **VR-1** Every E-2 and E-3 with `canonical_sha != git ls-files -s <canonical_source>` is **stale** and fails CI.
- **VR-2** Every E-4 with `status ∈ {answered, superseded, withdrawn}` AND `answered_at < most_recent_milestone_close_date` MUST be archived; absence is a `scripts/archive-registers.sh` violation.
- **VR-3** Every E-5 row's `prompt_hash` either matches an existing archive file under `docs/pm/token-ledger/prompts/` or has no archive (allowed; archive is optional).
- **VR-4** Every E-6 row whose `fallback_reason` contains `; downgraded_one_tier` MUST be visible in monthly review.
- **VR-5** E-7.binding == false implies `project_local_override_marker` present (schema-enforced).
- **VR-6** Every E-9.G8 with `status == passed-with-waivers` MUST have at least one open E-8 issue per deliverable in `waivers`.
- **VR-7** Every E-11 with `outcome == pr_opened` MUST satisfy patch-size invariants (lines ≤ 400, files ≤ 10, commits == 1).
- **VR-8** Every E-11 with `outcome == pr_opened` AND `protected_files_touched.length > 0` MUST also have a paired Markdown proposal under `docs/proposals/` referenced in the PR description.
- **VR-9** Every E-12 case file MUST validate against a small YAML schema (informal, lint-enforced via `scripts/lint-agent-contracts.sh` test-fixture pass).
- **VR-10** The M9 release ship-set (per `TEMPLATE_MANIFEST.lock` + upgrade.sh ship-files list) MUST have a classification entry in release notes per SC-014.

---

## Out of scope

- An application database, ORM, or runtime persistence layer — there is none.
- Persistent state for the agent harness across sessions — that is `claude-mem` territory and remains pointer-only (Constitution III + ADR-0001).
- The four reference downstream repos' internal data models — out of scope for the program; each repo owns its own per-product data.
