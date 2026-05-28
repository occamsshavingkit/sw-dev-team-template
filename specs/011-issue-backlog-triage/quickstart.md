# Quickstart: Pick Up the Next Dispatch

> Historical note: this handoff records the early `/speckit-plan` resume state before rc14 completion; `spec.md` status and `tasks.md` final phase now supersede it for current completion state.

Where we are at the end of `/speckit-plan`:

- 35-issue baseline locked in `triage.md` (2026-05-16).
- PR #204 (fix for #203) **open, code-reviewer APPROVED, awaiting merge**. Once merged, #203 closes automatically (`Closes #203` in PR body) — that completes the first dispatch and validates the reference fix-and-close cycle.

## To resume the burndown in the next session

### 1. Confirm PR #204 status

```sh
gh -R occamsshavingkit/sw-dev-team-template pr view 204 --json state,mergeable,statusCheckRollup
```

If merged: #203 is closed; the upgrade-flow bucket has 9 remaining issues.
If still open with conflicts: re-dispatch to software-engineer for rebase.

### 2. Pick the next dispatch from `triage.md` § Next dispatches

Order:

1. **PR-A** (hook-behavior, P1): #201 + NEW-A + NEW-B + #184. File NEW-A and NEW-B first (`gh issue create`), then dispatch software-engineer with a brief that names all four.
2. **PR-B** (version-check, P1): #161 + #199 + #154. Dispatch software-engineer.
3. **PR-C** (upgrade.sh, P1): #169 + #190 + #171 + (re-check #163 — may be obsolete post-#203). Dispatch software-engineer after PR-A and PR-B land.
4. **Solo P1**: #200 (re-run safety), #202 (canonical-scope guard inversion — may need architect read first), #188 (qa-engineer).
5. Then P2 buckets in `triage.md` order.

### 3. Dispatch the next specialist

Use the Agent tool with `subagent_type` = the bucket's owning role and `name` = the role file name (e.g., `name: "software-engineer"`). Brief shape:

- Working tree: `/home/quackdcs/SWEProj/sw-dev-team-template/`
- GitHub remote: `occamsshavingkit/sw-dev-team-template`
- Issue numbers + the `gh issue view <N>` command to read each binding spec.
- Branch name: `fix/issue-NNN-<short-slug>` (or `fix/cluster-X-<bucket>` for multi-issue PRs).
- Files in scope (cite by path).
- Test requirements (see contract).
- Deliverable shape: commit on the named branch; report under 300 words with branch / commit / files / test results.
- Hard rule reminders: no commit without code-reviewer, no `--no-verify`, no writes outside the named scope.

The dispatch brief used for #203 (now in PR #204's body) is the canonical template.

### 4. After the specialist reports

Dispatch code-reviewer with the branch + commit + brief excerpt. Verdict shape: APPROVED / APPROVED-WITH-CHANGES / REJECTED with file:line findings.

### 5. On APPROVED

`gh pr create` against `main` with body listing `Closes #N1 #N2 …` for each issue in the PR. Reference both the spec issue and any review observations.

### 6. After merge

Update `docs/pm/dispatch-log.md` with the merge time and PR link. Verify the issue auto-closed on GitHub. Move the next dispatch.

## When to invoke `/speckit-tasks`

`/speckit-tasks` is the next step when atomic task regeneration is desired. It consumes `plan.md`, `data-model.md`, and `contracts/`, then produces a per-task breakdown where each task touches one coherent behavior or disposition and names exactly one primary verification command/test.

## Meta-close trigger

When the last baseline issue closes:
1. Cut `v1.0.0-rc14` per FR-012 (release-engineer dispatch).
2. Run the QuackDCS-fixture downstream upgrade-test for SC-007.
3. Write the meta-summary commit per SC-006.
4. Disposition any net-new issues filed during the effort per FR-010.
5. Optionally invoke `/ultrareview` on the cumulative diff as a final sanity check (user-initiated, not auto).
