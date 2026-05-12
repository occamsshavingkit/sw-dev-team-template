# Quickstart: Validate M0/M1 Plan Outcomes

Use these steps after `/speckit.tasks` and M0/M1 implementation work are complete.

## 1. Confirm Planning Scope

```sh
test -f specs/001-template-improvement-plan/plan.md
test -f specs/001-template-improvement-plan/research.md
test -f specs/001-template-improvement-plan/data-model.md
test -f specs/001-template-improvement-plan/quickstart.md
! test -d specs/001-template-improvement-plan/contracts
```

Expected result: the plan exists, Phase 0/1 artifacts exist, and no contracts directory exists for M0/M1.

## 2. Check for Unresolved Planning Markers

```sh
if grep -R "TODO-FILL\|CLARIFICATION-REQUIRED" specs/001-template-improvement-plan; then
  exit 1
fi
```

Expected result: no unresolved planning markers remain.

## 3. Validate Runtime Context Pointer

```sh
grep -A3 -B1 "SPECKIT START" AGENTS.md
grep "specs/001-template-improvement-plan/plan.md" AGENTS.md
```

Expected result: `AGENTS.md` points Codex sessions to `specs/001-template-improvement-plan/plan.md` between the Speckit markers.

## 4. Verify M0 Evidence Exists

```sh
test -f docs/pm/token-economy-baseline.md
grep -n "M0\|M1\|Token" docs/pm/SCHEDULE.md
grep -n "context\|authority\|compiler\|routing" docs/pm/RISKS.md
```

Expected result: baseline report, M0/M1 schedule entries, and initial risk entries are present.

## 5. Verify M1 Token Quick-Win Artifacts

```sh
test -d docs/runtime/agents
test -f scripts/archive-registers.sh
test -f docs/pm/SCHEDULE-EVIDENCE.md
test -f docs/pm/SCHEDULE-ARCHIVE.md
grep -R "Prompt hash\|Prompt class\|Token budget\|Token actual" docs/pm docs/templates 2>/dev/null
```

Expected result: compact runtime candidates, archival script, PM schedule split, and compact token-ledger schema changes are present.

## 6. Run Shell and Static Checks

```sh
sh -n scripts/archive-registers.sh
git diff --check
```

Expected result: shell syntax and whitespace checks pass.

## 7. Verify Authority and Traceability

```sh
grep -R "canonical\|generated\|ephemeral" docs/runtime docs/agents docs/pm specs/001-template-improvement-plan 2>/dev/null
grep -R "ARCHIVE\|archive" docs/OPEN_QUESTIONS.md CUSTOMER_NOTES.md docs/intake-log.md docs/pm 2>/dev/null
```

Expected result: changed/generated artifacts state or preserve authority class, and archives/evidence remain discoverable from live surfaces.

## 8. Confirm G0/G1 Gates Before Later Work

```sh
grep -n "G0\|G1\|Gate" docs/pm/SCHEDULE.md docs/pm/token-economy-baseline.md
```

Expected result: G0 and G1 have explicit evidence before any M2-M9 implementation begins.

## 9. Review Gate Checklist

Before accepting M0/M1, confirm:

- `project-manager` verifies baseline, schedule, risk, PR split, and live/evidence/archive PM surfaces.
- `software-engineer` verifies shell-script behavior and portability.
- `tech-writer` verifies documentation/manual separation where applicable.
- `architect` verifies canonical/generated/runtime separation.
- `qa-engineer` verifies prompt-regression coverage for selected role candidates.
- `code-reviewer` verifies no hard rule, role authority, escalation format, or customer-interface rule was lost.
- `release-engineer` verifies changes are split into reviewable framework-maintenance PRs.
