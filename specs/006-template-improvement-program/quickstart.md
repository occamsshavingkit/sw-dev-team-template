# Quickstart: kicking off the M0–M9 program

**Plan**: [plan.md](./plan.md)
**Spec**: [spec.md](./spec.md)
**Research**: [research.md](./research.md)
**Date**: 2026-05-13

Runbook for the first three sessions of the program. Output of `/speckit-tasks` will produce the full per-task breakdown; this file gets the team to G1 without surprises.

---

## 0. Pre-flight (run once per session)

```bash
cd /home/quackdcs/SWEProj
git status -sb
cat sw-dev-team-template/VERSION
gh issue list --repo <upstream-template-owner>/sw-dev-team-template --limit 5 --label template-gap
```

Confirm:
- Working tree is on branch `004-m8-m10-plan` or a child of it.
- Sub-repo `./sw-dev-team-template` is on the expected upstream tag (or a working branch of it).
- No unrelated WIP is open in either tree.

If pre-flight fails: route to `project-manager` for state reconciliation; do NOT proceed.

---

## 1. M0 kickoff — baseline measurement (Gate G0)

**Owner**: `project-manager`. **Specialist**: `software-engineer` (script).

### 1.1 Author the baseline script

Create `sw-dev-team-template/scripts/baseline-token-economy.sh` per [research.md R-4](./research.md). The script:

1. Walks `.claude/agents/*.md` and records `{role, lines, words}` (FR-002).
2. Walks live registers (`docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`, `docs/pm/RISKS.md`, `docs/pm/LESSONS.md`, `CUSTOMER_NOTES.md`, `docs/pm/SCHEDULE.md`) and records `{file, rows, words}` (per E-14).
3. Counts answered-but-still-live `OPEN_QUESTIONS.md` rows (status-column parse).
4. Records `wc -l` of `docs/pm/SCHEDULE.md`.
5. For each of the four reference downstream repos (paths provided via `BASELINE_DOWNSTREAM_ROOTS` env var), records `{repo, intake_log_present, template_version}`.
6. Greps Markdown link references and records broken ones (path does not exist).
7. Emits `docs/pm/token-economy-baseline.md` with all the above as a single Markdown table set; idempotent (same git SHA → same output).

Smoke check:
```bash
cd sw-dev-team-template
BASELINE_DOWNSTREAM_ROOTS="../QuackDCS:../QuackPLC:../QuackS7:../QuackSim" \
  scripts/baseline-token-economy.sh
diff <(scripts/baseline-token-economy.sh --stdout) docs/pm/token-economy-baseline.md
```

### 1.2 Open M0 deliverables

- `docs/pm/SCHEDULE.md`: add M0 / M1 rows; record this program as the active sprint.
- `docs/pm/RISKS.md`: file the four canonical risks (context bloat, authority drift, prompt compiler drift, model-routing volatility) per spec § M0 deliverables.
- `docs/pm/token-economy-baseline.md`: committed output of step 1.1.

### 1.3 G0 sign-off

`code-reviewer` reviews the PR. Pass criteria (G0):
- Baseline report exists and is reproducible.
- Largest recurring context surfaces are named.
- M0/M1 PRs are sliced by workstream per source plan §5 (PR-1 through PR-4).
- No M5/M6/M7 work has started.

---

## 2. M1 quick wins (Gate G1)

**Owner**: `architect` (M1.1 design) + `software-engineer` (scripts) + `project-manager` (M1.4).

### 2.1 M1.1 — Compact runtime contract prototype

1. Create `docs/runtime/agents/` and `docs/agents/manual/` directories in the sub-repo.
2. `software-engineer` writes `scripts/compile-runtime-agents.sh` per [research.md R-1 / R-7](./research.md) and `schemas/agent-contract.schema.json` per [contracts/](./contracts/agent-contract.schema.json). At this milestone the generator only emits compact runtime contracts; OpenCode adapter generation arrives at M5.
3. Generate compact runtime contracts for at least `tech-lead`, `researcher`, `code-reviewer`, `qa-engineer`.
4. `qa-engineer` writes the initial prompt-regression set per [research.md R-11](./research.md): the eight cases listed in the source plan §M6.3. Run them against canonical contracts (compiled-contract pass arrives at G6).
5. Measure and record per-role word-count deltas; SC-001 target ≥30% reduction on `tech-lead`, SC-002 target ≥20% on others where safe.
6. `code-reviewer` audit: every hard rule, escalation path, output format, and hard-block from canonical survives in compact form.

### 2.2 M1.2 — Archive live registers

1. Write `scripts/archive-registers.sh` per FR-004 and the live-bound rule (spec clarification 1).
2. Run it dry against the sub-repo and the four downstream repos; record dry-run output.
3. `researcher` updates its agent contract to point at the archival script for memory-policy consistency.
4. Apply the archival in a separate PR per repo; preserve the tombstone-plus-archive-pointer pattern.

### 2.3 M1.3 — Token ledger refactor

1. Rewrite `docs/pm/token-ledger.md` schema to the eight-column form (per E-5 / FR-005).
2. Move verbatim prompts (where retained) to `docs/pm/token-ledger/prompts/<task-id>-<agent>.md`.
3. Update `docs/templates/task-template.md` DoD to reference the new schema (M2.1 fields land at M2; this is the structural prep).

### 2.4 M1.4 — Split PM schedule live / evidence / archive

1. Create `docs/pm/SCHEDULE-EVIDENCE.md` and `docs/pm/SCHEDULE-ARCHIVE.md` as empty files with their headers.
2. Move closure evidence and historical reconciliations out of `SCHEDULE.md` into the appropriate file.
3. `project-manager` verifies the live `SCHEDULE.md` carries current plan only.

### 2.5 G1 sign-off

`code-reviewer` reviews each PR; `qa-engineer` runs the prompt-regression set; `project-manager` records pass/fail per source plan §M1 acceptance criteria.

Pass criteria (G1):
- Largest live context files have measured reductions or a recorded reduction path.
- Compact runtime contract prototype exists (≥4 roles).
- Live register archival is scripted and dry-run-verified.
- PM schedule split is implemented.
- No new cross-AI integration added yet.

---

## 3. After G1 — the rest of the program

Subsequent milestones (M2 → M9) follow the source plan §5 PR slicing. They are not in this quickstart because (a) they depend on G1 outputs and (b) `/speckit-tasks` will produce the per-task breakdown.

High-level sequence reminder:
- **M2** (PR-3 final, ongoing) — task-template token budgets land; PM delta pass documented; memory-first patterns in binding docs.
- **M3** (PR-5, PR-6, PR-7) — atomic seed questions; Customer Question Gate; question linter (warning-only); intake-log scaffold + repair.
- **M4** (PR-8, PR-9) — Documentation Authority Policy; roadmap leakage fix; binding-status flip on model-routing; workflow-pipeline canonical move.
- **M5** (PR-10, PR-11) — model-routing extensions; OpenCode adapter ADR and generated thin adapters.
- **M6** (PR-12, PR-13) — schemas; agent-contract lint; runtime compiler full pass; canonical + compiled prompt-regression run.
- **M7** (PR-14, PR-15) — issue taxonomy; framework-gap issue template; AI improvement workflow + four CI workflows.
- **M8** (PR-16+) — downstream rollout, one repo at a time; deferred deliverables file framework-gap issues on the upstream template per FR-029.
- **M9** — full conformance audit; v1.0.0 release.

---

## Common failure modes and recovery

| Symptom | Likely cause | Recovery |
|---|---|---|
| `baseline-token-economy.sh` output not reproducible | Non-deterministic file ordering | Sort outputs lexically; pin LANG=C; verify with two consecutive runs producing identical diffs |
| Prompt regression fails on a hard rule after M1.1 compaction | Section filter dropped a hard rule | Restore the rule's section to the runtime-contract allowlist in `schemas/agent-contract.schema.json`; rerun compiler |
| `archive-registers.sh` over-archives an open row | Status-column parse drift | Live file preserves tombstone pointer; revert by copy-back from archive (append-only history is intact) |
| Downstream repo missing `TEMPLATE_VERSION` | Pre-template-era retrofit | Record as `present_bool=false` in baseline; create `TEMPLATE_VERSION` during M8.2 repair sequence |
| OpenCode adapter `canonical_sha` drifts after rebase | Generator wasn't rerun | CI gate (`agent-contract-check.yml`) catches it; rerun `compile-runtime-agents.sh` and amend |
| Question lint fires on a legacy compound row | Grandfathering not yet applied (pre-`HARDGATE_AFTER_SHA`) | Verify row commit predates the SHA; if so, lint should have skipped (bug → file framework-gap issue) |
| Self-improvement loop wants to edit `CUSTOMER_NOTES.md` | Logic touched customer-truth set | Loop MUST instead emit a paired Markdown proposal under `docs/proposals/`; the PR description references the proposal |

---

## Reference

- Spec: [./spec.md](./spec.md) — feature scope, FRs, SCs, clarifications
- Plan: [./plan.md](./plan.md) — technical context, constitution check, structure
- Research: [./research.md](./research.md) — tooling decisions (compiler, tokenizer, schemas)
- Data model: [./data-model.md](./data-model.md) — entities and validation rules
- Contracts: [./contracts/](./contracts/) — three JSON Schemas the linter consumes
- Source plan: `sw_dev_template_implementation_plan-2.md` at the meta-project root
