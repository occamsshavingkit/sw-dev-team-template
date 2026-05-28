# Release Plan v1.1.1–v1.4.0

**Scope:** Framework maintenance and template-gap backfill across one year of operations.  
**Date:** 2026-05-28  
**Source:** GitHub issue triage (35 open issues as of 2026-05-28); updated 2026-05-28 post Gate 3 sign-off.  
**Reviewer:** Customer ratified 2026-05-28 (Q-0020/Q-0021/Q-0022 + addendum + Gate 3 sign-off per CUSTOMER_NOTES.md); tech-lead orchestrated. Code-reviewer SHIP-with-nits 2026-05-28. Post-gate-3 update: v1.2.0 + v1.3.0 gates cleared; v1.4.0 expanded with SC-001 residual.

---

## v1.1.1 (Patch)

Correctness and safety fixes for v1.1.0 production use. No contract breaks. Small surface.

| # | Title | Labels | Est. Size | Role | Rationale |
|---|-------|--------|-----------|------|-----------|
| 276 | TEMPLATE_MANIFEST.lock pins runtime-mutable handoff-activity file → --verify drifts | template-friction | S | release-engineer | Runtime verification fails on every tool call; customer-visible regression. |
| 275 | software-engineer agent still uses 'model: inherit' → default to sonnet | enhancement | S | software-engineer | Cost optimization, no behavior break; ships safely in patch. |
| 268 | fix(branch-guard): --allow-non-default-branch flag unimplemented | bug, upgrade | M | release-engineer | Test cases 3,4,5,7 fail; blocking upgrade path reliability. |
| 222 | upgrade.sh: .template-conflicts.json parser fail-opens on malformed input | bug, upgrade, template-friction | M | release-engineer | Silent safety bypass in conflict handling; security posture. |
| 269 | Auto-merged SPDX-delta files mislabeled in upgrade.sh summary report | template-friction | S | release-engineer | Reporting accuracy; low impact but shipping now avoids confusion. |
| 254 | v0.16.0 → candidate upgrade-paths fix in PR #217 was dead code | bug, upgrade, template-friction | S | release-engineer | Dead code cleanup; low risk. |

**v1.1.1 Summary:** 6 issues, est. 4.5–5 person-days. **Gating:** All bugs verified closed + regression tests green.

---

## v1.2.0

Non-breaking template enhancements + framework-gap fills + upgrade-reliability improvements. Natural checkpoint per ADR-0020 §676 to re-examine issues-based coordination. **Entry gate:** Gate cleared 2026-05-28 — see CUSTOMER_NOTES.md § "Gate 3 sign-off: spec 016 token-economy design pass".

| # | Title | Labels | Est. Size | Role | Rationale |
|---|-------|--------|-----------|------|-----------|
| 262 | Upgrade path rc9→rc14 produces 7 manual conflicts in framework-owned scripts | enhancement, upgrade | M | architect + release-engineer | Multi-version upgrade reliability; pulled forward per Q-0021 customer ruling. |
| 261 | rc14 agent contract schema: migration doesn't backfill required sections in preserved/customized agent files | enhancement, upgrade | M | architect + software-engineer | Schema evolution + migration completeness; pulled forward per Q-0021 customer ruling. |
| 273 | SW_DEV_ROLE_TAXONOMY.md not loaded at session start | template-gap | M | software-engineer | Ad-lib role boundaries in tech-lead; fix via startup contract. |
| 271 | tests/upgrade/ missing rc9 migration test file | enhancement, upgrade | M | release-engineer | Test coverage gap; no shipped code broken, but blocks confidence. |
| 270 | tech-lead.md Job §2: parallel background dispatch not mentioned | docs-drift | S | tech-writer | Contract prose gap; non-blocking but clarifies intent. |
| 265 | tech-lead default Agent-dispatch mode should be run_in_background:true | enhancement | S | software-engineer | Better default; no behavior change for explicit users. |
| 264 | Agent dispatch templates should include redirect notice for direct user contact | enhancement, template-gap | S | tech-writer | UX clarity; codifies escalation guardrail. |
| 247 | release-engineer-manual: spot-check 3 CR non-blocking citations | docs-drift | S | code-reviewer | Docs-only; citation accuracy. |
| 244 | docs/sme/INVENTORY-template.md missing remote-only reference row pattern | enhancement, template-gap | S | tech-writer | Template completeness for SME librarians. |
| 250 | [framework-gap] add pre-commit guard for runtime-mirror canonical_sha staleness | enhancement, upgrade, template-gap | M | release-engineer | Recurring pitfall (PR #234, #248); guardrail pay-for-itself. |
| 236 | scoping-questions-template: 5a substitute-criteria seed lacks conditional skip cue | template-friction | S | tech-writer | Template UX; subtle but helps downstream projects. |
| 230 | lint-questions: last_eff_had_q regex misses ? + inline-comment-close | template-friction | S | software-engineer | Regex drift; low-cost fix, high visibility. |
| 227 | improve-template numeric validator: leading-zero ISSUE_NUMBER accepted | template-friction | S | software-engineer | gh CLI sensitivity; catches bad input. |
| 223 | lint-canonical-sha: detect orphan runtime artefacts | enhancement, template-friction | M | software-engineer | Audit completeness; catches config debt. |
| 219 | migration: git rm --cached docs/pm/token-ledger.md for downstreams | upgrade, template-friction | S | release-engineer | Cleanup for rc9→rc14 downstreams; one-time migration step. |
| 218 | docs/pm/token-ledger/prompts/README.md references lowercase path | docs-drift | S | tech-writer | Docs-only; cross-file consistency. |
| 216 | fixture-06: cleanup glob safety — killed run before register_revert | template-friction | S | software-engineer | Test fixture robustness. |
| 213 | schemas/model-routing.schema.json: claude_equivalent lacks enum | template-friction | S | software-engineer | Schema correctness; missing validation. |
| 211 | tests/release-gate/test-gate-pass.sh: skip-untracked check blocks self-validation | template-friction | M | software-engineer | Test authoring friction; blocks dogfooding. |
| 208 | test-settings-merge.sh + tech-lead-authoring-guard fallback path unexercised | template-friction | S | software-engineer | Test coverage gap; low risk but completeness. |

**v1.2.0 Summary:** 20 issues, est. 14–16 person-days. **Entry gate:** Gate cleared 2026-05-28 (CUSTOMER_NOTES.md). **Exit gating:** Template regression tests pass + downstream project upgrade validates cleanly + multi-version upgrade conflicts resolved.

---

## v1.3.0

Thematic clusters and larger composable enhancements: token-economy overhaul, taxonomy refresh, multi-issue design passes.

| # | Title | Labels | Est. Size | Role | Rationale |
|---|-------|--------|-----------|------|-----------|
| 239 | [framework-gap] tech-lead.md missing Token economy (binding) section | enhancement, template-gap, token-economy | L | architect + tech-writer | WIP=1, vertical slicing, JIT context binding; core contract extension. Scope-validation design pass required. |
| 245 | [token-economy] agent contract prose audit — measure and reduce per-spawn context load | enhancement, token-economy | L | architect | Complements #239; measurement + optimization pass. Scope-validation design pass required. |
| 274 | SW_DEV_ROLE_TAXONOMY.md content refresh: §4 scaffold-only, §5 gaps stale | enhancement, template-gap | L | architect + researcher | Downstream patterns surface new taxonomy entries; design-heavy. |
| 238 | [framework-gap] IEEE standard paraphrase integration deferred from v0.15 | enhancement, template-gap | M | researcher | STD-1 IEEE 1044, STD-2 IEEE 730, STD-3 IEEE 1012 + prose audit. |
| 241 | [framework-gap] requirements-template.md missing: Verification Method, apportioning, per-area ID prefixes, Compliance NFR | enhancement, template-gap | M | tech-writer | ISO/IEC 29148 completeness; multi-row work. |
| 240 | [framework-gap] requirements-template.md missing AI/ML requirements subsection | enhancement, template-gap | M | tech-writer | MSRS § 3.6 pattern; separate subsection. |
| 242 | [framework-gap] requirements-template.md + architecture-template.md missing MSRS-style inline guidance | enhancement, template-gap | M | tech-writer | Author-assistance markers across two templates. |
| 243 | [framework-gap] architecture-template.md missing IEEE 1016 viewpoints + explicit 42010 reasoning | enhancement, template-gap | L | architect | First-class viewpoints + reasoning chain; design layer. |

**v1.3.0 Summary:** 8 issues, est. 18–22 person-days. **Entry gate:** Gate cleared 2026-05-28 (CUSTOMER_NOTES.md). **Exit gating:** Token economy binding documented + measured; taxonomy and IEEE gaps closed; downstream projects benefit from new template sections.

---

## v1.4.0

Ambitious work, design-heavy, or low-urgency/high-cost items. May require architect input first or sustained effort budget.

| # | Title | Labels | Est. Size | Role | Rationale |
|---|-------|--------|-----------|------|-----------|
| 212 | concurrency: parallel specialist agents share one working tree, race over branch state | template-gap, ai-behavior | XL | architect | Core concurrency model; high design cost, low customer urgency. Left in v1.4.0 per Q-0020 customer ruling. |
| SC-001 | Close residual SC-001 gap (7 contracts still > 85% cap after spec 016 design pass) | token-economy, technical-debt | XL | architect | 7 of 13 contracts exceed 85% capacity threshold per spec 016 findings. Worst case: project-manager.md at 101.3%. Requires FR-007 restructuring or D-3 redefinition. |

**v1.4.0 Summary:** 2 issues, est. 16–24 person-days. **Gating:** Architect design review + customer sign-off on concurrency model scope + SC-001 remediation strategy.

---

## v2 Deferred (Contract-Break Items)

None identified in current triage. All 35 issues fit into v1.x without contract breaks.

---

## Phase Summary

| Phase | Count | Est. Effort (person-days) | Gating Criteria |
|-------|-------|---------------------------|-----------------|
| **v1.1.1** | 6 | 4.5–5 | Bugs verified; regression tests green. |
| **v1.2.0** | 20 | 14–16 | **Entry:** Gate cleared 2026-05-28. **Exit:** Template regression tests + downstream upgrade validates + multi-version conflicts resolved. |
| **v1.3.0** | 8 | 18–22 | **Entry:** Gate cleared 2026-05-28. **Exit:** Token economy binding + measured; taxonomy/IEEE gaps closed. |
| **v1.4.0** | 2 | 16–24 | Architect design review; concurrency model + SC-001 remediation scoped + signed. |
| **TOTAL** | **36** | **52.5–63 person-days** | Rolling gating per phase. |

---

## Cross-Phase Dependencies

- **v1.1.1 → v1.2.0:** #268 (branch-guard fix) prerequisite to overall upgrade-reliability work in v1.2.0.
- **Design gate → v1.2.0 entry:** Token-economy scope-validation design pass (#239+#245) must complete and be reviewed by architect+tech-writer before v1.2.0 implementation begins. This is a blocking entry condition (Q-0022 customer ruling).
- **Design gate → v1.3.0 entry:** Same token-economy composite design pass output gates v1.3.0 entry (confirms full scope and completeness before implementation).
- **v1.2.0 → v1.3.0:** #273 (TAXONOMY loading) prerequisite to #274 (taxonomy refresh content).
- **v1.3.0 → v1.4.0:** #239 (token-economy binding) informs #212 (concurrency model design).

---

## Execution Notes

**Spec Kit integration:** Each phase will be broken into one or more specs in the Spec Kit (per phase or per cluster). This plan governs the phase structure and gating; detailed story/task breakdown happens in the specs as downstream artifacts.

**Resolved customer decisions (Q-0020, Q-0021, Q-0022):** 
- Q-0020: #212 concurrency → v1.4.0. 
- Q-0021: #262, #261 multi-version reliability → v1.2.0 (pulled forward).
- Q-0022: #239+#245 token-economy → single composite design-pass gate before v1.2.0 and v1.3.0 implementation.
