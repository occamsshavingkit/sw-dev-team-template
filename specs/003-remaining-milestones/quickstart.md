# Quickstart: Remaining Milestones M3-M9 Planning Validation

## Validate Planning Artifacts

1. Before `/speckit.tasks`, confirm only Phase 0 and Phase 1 artifacts exist for this feature:
   - `specs/003-remaining-milestones/plan.md`
   - `specs/003-remaining-milestones/research.md`
   - `specs/003-remaining-milestones/data-model.md`
   - `specs/003-remaining-milestones/quickstart.md`

2. Before `/speckit.tasks`, confirm `tasks.md` and `contracts/` were not created. After `/speckit.tasks`, confirm `tasks.md` exists as a candidate planning artifact and `contracts/` still does not exist.

3. Confirm no unresolved clarification markers or template placeholders remain in the relevant planning artifacts only:
   ```sh
   grep -n -E \
     -e 'NEEDS[[:space:]]CLARIFICATION' \
     -e '\[''FEATURE\]' \
     -e '\[''###' \
     -e 'ACTION[[:space:]]REQUIRED' \
     -e 'REMOVE[[:space:]]IF UNUSED' \
     -e 'Option [123]' \
     specs/003-remaining-milestones/spec.md \
     specs/003-remaining-milestones/plan.md \
     specs/003-remaining-milestones/research.md \
     specs/003-remaining-milestones/data-model.md \
     specs/003-remaining-milestones/quickstart.md
   ```
   The command should return no matches; do not run this check across `checklists/` because checklist prose may intentionally mention marker names.

4. Confirm G3 through G9 remain separate acceptance boundaries:
   ```sh
   grep -R -n -E 'G3|G4|G5|G6|G7|G8|G9' specs/003-remaining-milestones/*.md
   ```

5. Confirm planning does not implement M3-M9 and does not introduce direct release or protected-branch execution:
   ```sh
   grep -R -n -E 'planning only|do not implement|protected-branch|release execution|PR-only' specs/003-remaining-milestones/*.md
   ```

6. Confirm Spec Kit governance is explicit:
   ```sh
   grep -R -n -E 'Spec Kit may generate|tech-lead.*govern|candidate' specs/003-remaining-milestones/*.md
   ```

7. Confirm `AGENTS.md` points at the current plan inside the Spec Kit block:
   ```sh
   grep -n -E 'specs/003-remaining-milestones/plan.md' AGENTS.md
   ```

8. Run whitespace validation for tracked files:
   ```sh
   git diff --check
   ```

9. For any untracked planning file, run no-index whitespace validation, for example:
   ```sh
   git diff --check --no-index /dev/null specs/003-remaining-milestones/research.md
   git diff --check --no-index /dev/null specs/003-remaining-milestones/data-model.md
   git diff --check --no-index /dev/null specs/003-remaining-milestones/quickstart.md
   ```

## Later Implementation Readiness

1. Generate tasks only after this plan is reviewed and accepted; once generated, keep `tasks.md` candidate until `tech-lead` governance accepts it.

2. Keep task generation split by gate so no task implements multiple milestone gates without explicit review.

3. Route later work through owning specialists:
   - M3 question/intake validation: `qa-engineer`, `tech-lead`, `researcher`
   - M4 authority/drift policy: `architect`, `tech-writer`, `code-reviewer`
   - M5 adapter routing: `architect`, `release-engineer`, `code-reviewer`
   - M6 scripts/schemas/generation: `software-engineer`, `qa-engineer`, `code-reviewer`
   - M7 automation hardening: `release-engineer`, `security-engineer`, `code-reviewer`
   - M8 rollout: `project-manager`, `release-engineer`, `qa-engineer`
   - M9 release readiness: `code-reviewer`, `qa-engineer`, `release-engineer`, `project-manager`, `onboarding-auditor`, `process-auditor`

4. Treat every Spec Kit output as candidate material until `tech-lead` routes and governs it through the sw-dev role model.
