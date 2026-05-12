# Quickstart: Validate M2 Token Operating Model

Use these steps after `/speckit.tasks` and M2 implementation work are complete.

## 1. Confirm Planning Scope

```sh
test -f specs/002-m2-token-operating-model/plan.md
test -f specs/002-m2-token-operating-model/research.md
test -f specs/002-m2-token-operating-model/data-model.md
test -f specs/002-m2-token-operating-model/quickstart.md
! test -d specs/002-m2-token-operating-model/contracts
test -f specs/002-m2-token-operating-model/tasks.md
```

Expected result: the plan, Phase 0/1 artifacts, and generated task list exist; no contracts directory was created for M2.

## 2. Check for Unresolved Planning Markers

```sh
files="
specs/002-m2-token-operating-model/spec.md
specs/002-m2-token-operating-model/plan.md
specs/002-m2-token-operating-model/research.md
specs/002-m2-token-operating-model/data-model.md
specs/002-m2-token-operating-model/quickstart.md
specs/002-m2-token-operating-model/tasks.md
"
needs="NEEDS"
clarification="CLARIFICATION"
todo="TODO"
fill="FILL"
feature="FEATURE"
hashes="###"
if grep -E "${needs}[ ]${clarification}|${todo}-${fill}|${clarification}-REQUIRED|\[${feature}\]|\[${hashes}" $files; then
  exit 1
fi
```

Expected result: no unresolved planning markers remain in the M2 planning artifacts; checklist prose is intentionally excluded.

## 3. Validate Runtime Context Pointer

```sh
grep -A3 -B1 "SPECKIT START" AGENTS.md
grep "specs/002-m2-token-operating-model/plan.md" AGENTS.md
```

Expected result: `AGENTS.md` points sessions to `specs/002-m2-token-operating-model/plan.md` between the Spec Kit markers.

## 4. Verify Task Template Token Fields

```sh
grep -n "Token budget" docs/templates/task-template.md
grep -n "JIT file list\|just-in-time" docs/templates/task-template.md
grep -n "Token actual" docs/templates/task-template.md
grep -n "tiny\|small\|medium\|large\|XL" docs/templates/task-template.md
```

Expected result: task planning guidance includes token budget bands, just-in-time file list guidance, token actual closure guidance, and XL split-or-accept behavior.

## 5. Verify PM Delta Pass Guidance

```sh
grep -n "delta pass\|changed files\|merged PR\|current milestone\|open-question\|risk/change" .claude/agents/project-manager.md docs/pm/*.md 2>/dev/null
```

Expected result: project-manager guidance prefers changed files, merged PR titles, current milestone rows, changed open-question rows, and risk/change deltas before broad project-manager rereads.

## 6. Verify Memory Query Patterns

```sh
grep -n "customer decision\|current milestone blocker\|similar prior answer\|accepted ADR" docs/MEMORY_POLICY.md .claude/agents/tech-lead.md .claude/agents/researcher.md
grep -n "pointer-only\|source of truth\|repository" docs/MEMORY_POLICY.md .claude/agents/tech-lead.md .claude/agents/researcher.md
```

Expected result: binding guidance includes concrete memory-first query patterns and preserves repository artifacts as authority.

## 7. Confirm Scope Exclusions

```sh
approved='^(specs/002-m2-token-operating-model/.*|AGENTS.md|docs/templates/task-template.md|docs/MEMORY_POLICY.md|\.claude/agents/(project-manager|tech-lead|researcher)\.md)$'
if test -n "${M2_IMPLEMENTATION_FILES:-}"; then
  printf '%s\n' "$M2_IMPLEMENTATION_FILES" | sed '/^$/d' | grep -v -E "$approved" && exit 1
else
  git ls-files --modified --others --exclude-standard -- \
    AGENTS.md \
    specs/002-m2-token-operating-model/ \
    docs/templates/task-template.md \
    docs/MEMORY_POLICY.md \
    .claude/agents/project-manager.md \
    .claude/agents/tech-lead.md \
    .claude/agents/researcher.md | grep -v -E "$approved" && exit 1
fi
```

Expected result: the intended M2 implementation file list stays within the approved canonical docs/templates and planning artifacts. In a dirty worktree, set `M2_IMPLEMENTATION_FILES` to the newline-separated M2 review/PR file list; if unset, the fallback check validates only approved M2 path diffs and intentionally ignores unrelated pre-existing dirty files.

## 8. Run Static Checks

```sh
git diff --check
```

Expected result: whitespace checks pass.

## 9. Review Gate Checklist

Before accepting M2, confirm:

- `project-manager` verifies token-budget planning fields and PM delta-pass guidance.
- `researcher` verifies customer-truth stewardship and memory pointer-only language.
- `tech-lead` verifies sole customer-interface routing remains intact.
- `qa-engineer` verifies requirements from `spec.md` are covered by changed guidance.
- `code-reviewer` verifies no role authority, source authority, or framework/project boundary rule regressed.
