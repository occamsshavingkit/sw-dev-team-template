# Risk Register — sw-dev-team-template improvement program (M0–M9)

PMBOK Planning / Monitoring artifact. Owned by `project-manager`. One
row per risk. Risks are only closed, never deleted.

Source plan: `sw_dev_template_implementation_plan-2.md` (meta-project
root). Spec directory: `specs/006-template-improvement-program/`.

## Scoring scale

- **Probability.** 1 = rare, 2 = unlikely, 3 = possible, 4 = likely,
  5 = almost certain.
- **Impact.** 1 = negligible, 2 = minor, 3 = moderate, 4 = major,
  5 = severe.
- **Score.** probability × impact (1–25). Any risk ≥ 12 is material
  and requires an explicit response plan, not acceptance.

## Register

| ID | Description | Category | Prob | Impact | Score | Owner | Response (avoid / transfer / mitigate / accept) | Trigger | Status | Last reviewed |
|---|---|---|---|---|---|---|---|---|---|---|
| R-1 | Context bloat — recurring agent-contract / live-register size grows past the live-bound rule between baseline passes. | technical | 3 | 4 | 12 | `project-manager` | mitigate — M1.1 compact runtime contracts (FR-003); M1.2 archive-registers.sh (FR-004 + SC-003); ongoing PM delta pass (FR-008) at every gate. | Token ledger shows live-bound regression vs. previous gate baseline. | open | 2026-05-13 |
| R-2 | Authority drift — generated artifacts (compact contracts, OpenCode adapters) silently become source of truth, violating Constitution III. | compliance | 3 | 4 | 12 | `architect` | mitigate — FR-022 schemas reject manually-edited generated files via `canonical_sha` mismatch; CI gate `agent-contract-check.yml` (FR-028); release-note classification of ship-set (SC-014). | CI flags a `canonical_sha` mismatch, or a generated file diverges from its canonical source in PR review. | open | 2026-05-13 |
| R-3 | Prompt compiler drift — `scripts/compile-runtime-agents.sh` semantic changes between releases break prompt-regression (FR-024). | technical | 3 | 4 | 12 | `software-engineer` | mitigate — generator pinned by version in artifact frontmatter; prompt-regression runs against canonical AND compiled (SC-013); two-layer safety (CI gate + runtime canonical fallback) per `research.md` R-5. | Prompt-regression suite fails after a compiler version bump, or generated frontmatter omits the pinned generator version. | open | 2026-05-13 |
| R-4 | Model-routing volatility — exact Gemini / OpenAI / Anthropic model IDs change mid-program. | external | 4 | 3 | 12 | `architect` | mitigate — routing uses model classes (FR-019); exact IDs marked runtime-reverifiable (FR-016); fallback policy logs every substitution (FR-020 + spec clarification 8). | Vendor deprecates or renames a referenced model ID; routing fallback log records a substitution. | open | 2026-05-13 |
| R-5 | Branch protection on `main` not enabled; `improve-template.yml`'s "never push to `main`" guarantee relies on it. | technical | 2 | 4 | 8 | `release-engineer` | mitigate — document the prerequisite in `docs/TEMPLATE_UPGRADE.md`; the customer enables branch protection at first scaffold and before any non-dry-run invocation of the self-improvement workflow. | Customer skips branch-protection setup; first `improve-template.yml` run could push to `main` if `feat/improve/*` branch creation fails. | open | 2026-05-13 |
| R-6 | Phase-3+ LLM wiring re-introduces API-key + data-egress + prompt-injection surface. | external | 3 | 4 | 12 | `security-engineer` | mitigate — security review MUST re-run at Phase-3+ LLM wire-up covering API-key handling, egress fields, prompt-injection from issue bodies, and adversarial diffs that target the size / protected-files checks; document the gate in `docs/pm/LESSONS.md` §M7 close. | Phase-3+ task proposes wiring without `security-engineer` re-review. | open | 2026-05-13 |
| R-7 | `setup-github-labels.sh` writes to the GitHub remote on actualization; idempotent but customer must verify dry-run first. | operational | 2 | 2 | 4 | `release-engineer` | mitigate — `--dry-run` flag + `docs/TEMPLATE_UPGRADE.md` guidance that operator runs dry-run first against the right `REPO` slug. | Operator runs without `--dry-run` against the wrong repo. | open | 2026-05-13 |
| R-8 | FR-027's "any file containing a Hard Rule" clause is content-based; the workflow path regex covers explicit paths only and misses files such as `docs/FIRST_ACTIONS.md`, `docs/workflow-pipeline.md`, `docs/MEMORY_POLICY.md`, `docs/TEMPLATE_UPGRADE.md`, `README.md`, `CHANGELOG.md` that reference Hard Rules. | technical | 3 | 3 | 9 | `security-engineer` | mitigate — for M7 the `code-reviewer` human-review gate on every draft PR is the active mitigation; Phase-3+ task adds a content-grep step (`grep -l "Hard Rule"` over the changed-paths set) or broadens the regex to include the identified Hard-Rule-bearing docs. | A self-improvement PR edits a Hard-Rule-bearing doc without a paired proposal and the human reviewer misses it. | open | 2026-05-13 |
| R-9 | `workflow_dispatch` input `issue_number` flows into `$GITHUB_OUTPUT` without numeric validation; multi-line input from a write-access actor could inject extra output rows. | technical | 1 | 2 | 2 | `security-engineer` | accept — invocation requires repo write access (limited blast radius); add numeric validator (`case "$ISSUE_NUMBER" in ''\|*[!0-9]*) exit 2 ;; esac`) at Phase-3+ LLM-wire-up hardening pass. | A write-access actor supplies a non-numeric `issue_number` to a future workflow run; output-row injection only matters once downstream steps read attacker-controlled output fields. | open | 2026-05-13 |

## Response plan details (for material risks)

For each risk with score ≥ 12, a sub-section with:

- Detailed response plan.
- Contingency: what we do if the risk is realized.
- Secondary risks introduced by the response.
- Cost of the response (cross-reference `COST.md`).

### R-1 — Context bloat

- **Response.** Generate compact runtime contracts (M1.1, FR-003);
  ship `archive-registers.sh` (M1.2, FR-004 + SC-003); enforce PM
  delta-pass (FR-008) at every gate review.
- **Contingency.** If live-bound regresses ≥ 10% vs. prior gate
  baseline, freeze new canonical-doc additions until a compact pass
  closes the gap.
- **Secondary risks.** Compact-contract generation introduces
  generator drift (see R-3).
- **Cost.** See `COST.md` once opened (M1 follow-on task).

### R-2 — Authority drift

- **Response.** Generated artifacts carry `canonical_sha`
  frontmatter (FR-022); CI gate `agent-contract-check.yml` (FR-028)
  blocks merges with mismatched `canonical_sha`; release notes
  classify every shipped artifact as canonical / generated /
  ephemeral per plan §2.2 (SC-014).
- **Contingency.** If a generated file is found edited in-place,
  revert to canonical, regenerate, and file an upstream issue
  against the generator.
- **Secondary risks.** CI gate false-positives could block
  legitimate canonical edits — mitigated by clear error messages
  pointing back to the canonical source.
- **Cost.** See `COST.md` once opened.

### R-3 — Prompt compiler drift

- **Response.** Pin generator version in every generated artifact's
  frontmatter; prompt-regression suite (SC-013) compares canonical
  and compiled outputs; runtime falls back to canonical if compiled
  artifact is missing or unreadable (`research.md` R-5).
- **Contingency.** If prompt-regression fails after a compiler bump,
  hold the compiler bump in a branch and run the regression diff
  through `code-reviewer` before merge.
- **Secondary risks.** Two-layer safety adds maintenance burden —
  accepted as a cost of generated-artifact discipline.
- **Cost.** See `COST.md` once opened.

### R-4 — Model-routing volatility

- **Response.** Reference model classes, not exact IDs, in routing
  (FR-019); flag exact IDs in `docs/model-routing-guidelines.md` as
  runtime-reverifiable (FR-016); fallback policy logs every
  substitution to the token ledger (FR-020 + spec clarification 8).
- **Contingency.** When a vendor deprecates an ID, the fallback log
  drives a same-session PR updating the model class binding;
  customer is notified through `tech-lead` if the substitution
  changes capability tier.
- **Secondary risks.** Class-based routing may hide capability
  regressions if the class binding is sloppy — mitigated by the
  fallback log review at each gate.
- **Cost.** See `COST.md` once opened.

## Review cadence

`project-manager` reviews the register at least every milestone. High-
score open risks reviewed in the **first session of each calendar
week**. Every review bumps `Last reviewed`.

Cadences in this framework are **session-anchored, run-once** — the
agent only executes when the customer opens a session, so a cadence
expressed as "weekly" means "in the first session on or after the
week boundary." Missed weeks do not accumulate; the next session runs
the review once, not twice. See `CLAUDE.md` § "Time-based cadences."
