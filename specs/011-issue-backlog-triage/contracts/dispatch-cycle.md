# Contract: Per-Issue Dispatch Cycle

The only interface this feature exposes is the **dispatch cycle** — the lifecycle every issue traverses from the 2026-05-16 baseline open-state to its terminal closed-state. The contract is consumed by tech-lead (orchestrator), owning specialists (implementers), code-reviewer (gate), and the customer (close-comment audience).

## Cycle states and transitions

```text
pending-triage  ──(triage table written)────►  dispatched
                                                    │
                                                    ▼
                                              in-review  ◄──┐
                                                    │       │ (re-dispatch on
                                                    │       │  rejection;
                                                    ▼       │  dispatch_seq++)
                                              ready-to-close
                                                    │
                                                    ▼
                                                  closed
```

Sideband paths from `pending-triage`:

- `defer-to-v2` and `wontfix-and-close` skip `in-review` and `ready-to-close`; they transition directly to `closed` once the close-comment is posted.
- `consolidate-with-other-issue` and `close-as-duplicate` skip review entirely; they transition to `closed` once the cross-link comment lands.

## State entry / exit contracts

### `pending-triage`

**Entry**: issue appears in `triage.md` § buckets with bucket + disposition assigned.
**Exit**: tech-lead invokes the Agent tool with `subagent_type` = owning_role; dispatch-log.md gains a row.
**Required artifact at exit**: dispatch-log.md row (issue_number, dispatch_seq=1, owning_role, brief, started_at) and the task/dispatch brief names exactly one primary verification command/test.

### `dispatched`

**Entry**: specialist has the brief and is working.
**Exit**: specialist commits work on a `fix/issue-NNN-<slug>` branch and returns control to tech-lead with a terse report (per the `code-reviewer.md` / `software-engineer.md` agent contracts, ≤300 words).
**Required artifact at exit**: a commit on `fix/issue-NNN-<slug>` referencing the issue in its body.

### `in-review`

**Entry**: tech-lead dispatches code-reviewer to read the branch + run any specified tests.
**Exit**: code-reviewer returns one of:
- APPROVED → state advances to `ready-to-close`.
- APPROVED-WITH-CHANGES → blocking findings re-dispatch to specialist; state returns to `dispatched` (`dispatch_seq++`).
- REJECTED → re-dispatch with a revised brief; state returns to `dispatched` (`dispatch_seq++`).

**Required artifact at exit**: code-reviewer verdict text in the dispatch-log row.

### `ready-to-close`

**Entry**: APPROVED verdict received; branch pushed to origin; PR opened.
**Exit**: PR merges to default branch via GitHub UI (or `gh pr merge`).
**Required artifact at exit**: PR link recorded in dispatch-log; PR body includes `Closes #NNN` syntax so GitHub auto-closes the issue on merge.

### `closed`

**Entry**: GitHub `state = closed` (auto-set by `Closes #NNN`, or set by `gh issue close` for sideband paths).
**Exit**: terminal.
**Required artifact at exit**: close-comment on the issue, content depending on disposition:
- `fix-and-close`: cite the merged PR (FR-004).
- `wontfix-and-close`: rationale of at least one sentence (FR-005).
- `defer-to-v2`: anchor link to `ROADMAP.md#v2-deferred` + `v2-deferred` label (FR-006).
- `consolidate-with-other-issue` / `close-as-duplicate`: cross-link to surviving / canonical issue (FR-007).

## Cluster PRs

A cluster PR closes multiple issues atomically. The PR body lists every closed issue with `Closes #N1 #N2 #N3 …` GitHub syntax. Each closed issue gets its own close-comment naming the PR. The dispatch-log records one row per issue in the cluster, all sharing the same `branch` and `pr_link`.

Cluster work must split into sequential atomic subtasks unless one named primary verification command/test proves the whole cluster. Each task or dispatch may name secondary checks as context, but exactly one command/test is the primary verification gate.

## Failure modes

- **Specialist returns work that doesn't compile / fails tests**: code-reviewer REJECTS → re-dispatch.
- **Specialist makes off-allow-list writes (HR-8 violation)**: FW-ADR-0012 tool-layer guard blocks the write before it lands; specialist's brief should note the right escape-hatch role if tool-bridge work is intentional.
- **PR fails CI**: CI is the gate; tech-lead does NOT use `--no-verify` to bypass. Re-dispatch with the CI failure surfaced.
- **Issue requires customer ruling discovered mid-dispatch**: pause dispatch, queue the question in `docs/OPEN_QUESTIONS.md`, return to `pending-triage`; do not block sibling buckets on the queued question.
- **PR conflicts with an in-flight cluster PR**: rebase the trailing PR onto the merged head; do not merge with conflicts unresolved.
- **Code-review approved but merge conflict appears at merge-time**: re-dispatch to specialist for rebase; re-review may be light (no behaviour change).

## Non-goals

- Automation of any of the transitions — every transition is tech-lead-initiated. No GitHub Actions automate dispatch routing.
- Synthetic progress metrics — the only progress signal is "issue closed" per GitHub.
- External notification (Slack, email) — out of scope.

## Audit surface

At meta-close, every state of every dispatch is reconstructible from:
- `triage.md` — initial bucket + disposition assignment.
- `dispatch-log.md` — every dispatch row with branch, PR, verdict, merge status.
- GitHub issue close-comments — final disposition rationale.
- GitHub PR commit history — exact code changes.

No additional persistence is required; the audit is a join across these four surfaces.
