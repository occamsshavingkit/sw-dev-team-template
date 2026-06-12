---
name: fw-adr-0024-parallel-agent-working-tree-isolation
description: >
  Working-tree isolation strategy for parallel specialist agents that
  mutate or read the scaffold checkout: strict serialization (current
  interim), per-agent git worktrees, or read-only clone/worktree for
  readers with a single canonical writer.
status: accepted
date: 2026-06-02
---


# FW-ADR-0024 — Parallel agent working-tree isolation

<!-- TOC -->

- [Status](#status)
- [Scaffold placement note](#scaffold-placement-note)
- [Context and problem statement](#context-and-problem-statement)
  - [Incident log (issue #212)](#incident-log-issue-212)
  - [Nested-repo topology (binding constraint)](#nested-repo-topology-binding-constraint)
  - [Test hermeticity coupling (issues #306 / #216)](#test-hermeticity-coupling-issues-306--216)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Strict serialization (current interim)](#option-m--strict-serialization-current-interim)
  - [Option S — Per-agent git worktrees for all mutating agents](#option-s--per-agent-git-worktrees-for-all-mutating-agents)
  - [Option C — Hybrid: read-only throwaway worktree for readers, single writer on canonical checkout](#option-c--hybrid-read-only-throwaway-worktree-for-readers-single-writer-on-canonical-checkout)
- [Decision outcome](#decision-outcome)
- [Design: hybrid per-agent working-tree isolation (Option C)](#design-hybrid-per-agent-working-tree-isolation-option-c)
  - [1. Agent classification: writer vs reader](#1-agent-classification-writer-vs-reader)
  - [2. Writer protocol: canonical checkout, serialized](#2-writer-protocol-canonical-checkout-serialized)
  - [3. Reader protocol: throwaway worktree, one per dispatch](#3-reader-protocol-throwaway-worktree-one-per-dispatch)
  - [4. Test hermeticity contract](#4-test-hermeticity-contract)
  - [5. Tech-lead integration flow](#5-tech-lead-integration-flow)
  - [6. Worktree lifecycle and cleanup](#6-worktree-lifecycle-and-cleanup)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Proposed** — 2026-06-02
- **Accepted** — 2026-06-03. Option C (Hybrid) adopted per customer ruling 2026-06-03; implement the 11 enumerated contract/helper changes.
- **Implemented** — `feat/worktree-isolation`. Contract changes (items 1–7) and scaffolding helpers (items 8–11) implemented in this PR.
- **Deciders:** `architect` (proposed); `tech-lead` + customer (accepted 2026-06-03)
- **Consulted:** issue #212 incident log; issue #306 (non-hermetic
  tests); issue #216 (test-gate git-reset side-effects);
  `docs/agents/manual/tech-lead-manual.md` § "Parallelism default"
  and § "Dispatch discipline"; `.claude/agents/code-reviewer.md`;
  `.claude/agents/tech-lead.md` (background-by-default rule);
  `CLAUDE.md` § "Agent-teams panel"

## Scaffold placement note

Drafted in the meta-project (`docs/adr/`) per the PLAN/DO convention
(`CLAUDE.md` § "Project Identity / Working Tree"). Migrated into the
scaffold's `docs/adr/` as part of the `feat/worktree-isolation`
implementation PR so the rationale travels with the agent-contract and
script changes, matching the pattern established by FW-ADR-0001 through
FW-ADR-0023. The meta-project draft copy is retained as the team's
working reference; this scaffold copy is canonical from the
implementation PR forward.

---

## Context and problem statement

`tech-lead`'s dispatch model defaults to background-parallel: when
multiple independent specialists are needed, they are spawned together
in a single `Agent`-tool block. Each subagent runs in its own Claude
Code process context but all of them share a single filesystem view of
the scaffold checkout at `./sw-dev-team-template`. That shared working
tree has one HEAD pointer and one active branch.

### Incident log (issue #212)

Three documented failure modes, all rooted in concurrent access to the
shared working tree:

**Incident 1 — Stash clobber.** Two `software-engineer` subagents were
dispatched in parallel to implement independent features. SE-A ran
`git stash` to save its in-flight edits before switching context;
SE-B's dispatch pre-dated SE-A's stash and had already read the same
files. When SE-B ran `git stash pop` it popped SE-A's stash, dropping
SE-A's work silently.

**Incident 2 — Wrong-branch commit.** A `release-engineer` subagent
ran `git switch -c release/v1.1-rc2` to create a release branch.
Concurrently, a `code-reviewer` subagent running review checks called
`git switch main` to diff against main. The `release-engineer`'s
subsequent `git commit` landed on `main` (the checkout the reviewer
had just switched to) rather than on `release/v1.1-rc2`. The
commit was not immediately visible as misplaced because the reviewer
exited cleanly.

**Incident 3 (2026-06-02) — Test-gate git-reset.** A `code-reviewer`
subagent ran `test-gate-fail-each.sh` as part of its review pass.
That test script internally called `git reset --hard` to restore
fixture state between test cases. The reset targeted the shared
checkout's HEAD, dropping two commits that a concurrently running
`software-engineer` had made but not yet pushed. Neither agent
detected the loss at the time; the commits were recovered from
`git reflog` but required manual triage.

All three incidents share a single root cause: the scaffold's git
working tree is a shared mutable resource with no concurrency control
across parallel subagent processes.

### Nested-repo topology (binding constraint)

The scaffold (`./sw-dev-team-template`) is a **standalone nested git
repository**, not a git submodule of the meta-project. This is load-
bearing for the isolation design:

- The Claude Code `Agent` tool's harness-level repo isolation (if any)
  targets the **meta-project** repo, not the scaffold repo. Any
  harness-side "working-tree-per-agent" feature would apply to
  `/home/quackdcs/SWEProj`, not to the nested scaffold at
  `./sw-dev-team-template`. Subagents reading and writing the scaffold
  all see the same single checkout regardless of harness-level isolation.
- `git worktree add` for the scaffold must be invoked explicitly against
  the scaffold repo (`git -C ./sw-dev-team-template worktree add …`)
  by either `tech-lead` (pre-dispatch setup) or the specialist itself
  (self-setup on arrival).
- The `.worktrees/` directory visible in `git status` is a meta-project
  artifact, not a scaffold worktree; it does not provide isolation for
  scaffold operations.

Any solution that relies on the harness to provide working-tree
isolation for the scaffold is incorrect and will fail silently.

### Test hermeticity coupling (issues #306 / #216)

Issue #306 documents that several test scripts in the scaffold mutate
git state as a side-effect of running: they create commits, switch
branches, reset HEAD, or write to the index to set up fixtures. Issue
#216 identified that `test-gate-fail-each.sh` specifically uses
`git reset --hard` between test cases and leaves the working tree on a
different HEAD than it started.

This means the "read-only reviewer" framing is not sufficient on its
own: a `code-reviewer` that runs tests is a working-tree mutator even
if its own code edits are read-only. The test hermeticity problem and
the working-tree isolation problem are **coupled**: isolation must
account for what tests do to git state, not just what agents do to
files.

---

## Decision drivers

- **Parallelism is load-bearing.** The `tech-lead-manual.md` §
  "Parallelism default" rule and the `background-by-default` dispatch
  rule exist to keep the customer's chat interactive while specialists
  run. Strict serialization (Option M) preserves correctness at the
  cost of eliminating this property for any session that touches the
  scaffold. That is a significant regression in framework usability.
- **No silent data loss.** Incidents 1 and 3 produced silent data loss
  (stashed work overwritten; commits dropped) that required manual
  recovery. A correct solution must make concurrent write conflicts
  impossible, not merely unlikely.
- **No wrong-branch commits.** Incident 2 is undetectable at commit
  time without a branch-ownership contract. A correct solution must
  ensure a specialist cannot commit to a branch it did not create.
- **The nested-repo topology is fixed.** The scaffold's standalone git
  repo status is a deliberate design choice (CLAUDE.md § "Project
  Identity / Working Tree"). Solutions that require changing this
  topology are out of scope.
- **Test non-hermeticity is a first-class concern.** Any solution that
  treats reviewers as safely read-only without accounting for
  test-induced git mutations will reproduce Incident 3.
- **Cleanup must be automatic.** Worktrees left behind on agent exit
  (crash or timeout) accumulate and consume disk. A solution that
  requires manual cleanup is operationally unacceptable for long-running
  sessions.
- **PR flow must remain coherent.** The integration model (specialist
  branches merged via PR) must not require operators to understand
  worktree internals.

---

## Considered options (Three-Path Rule, binding)

### Option M — Strict serialization (current interim)

Only one agent may hold the scaffold working tree at a time. `tech-lead`
maintains a logical "scaffold lock": before dispatching any specialist
that touches the scaffold, it waits for all currently running scaffold-
touching specialists to complete and report back. Background-parallel
dispatch is permitted only for specialists whose work is entirely within
the meta-project or whose scaffold access is demonstrably read-only AND
the test they run is hermetic (verified in advance).

- **Sketch:** No new infrastructure. The constraint lives entirely in
  `tech-lead`'s dispatch discipline: "never dispatch two scaffold-
  mutating specialists in the same dispatch block." Enforcement is
  advisory prose.
- **Pros:** Zero implementation cost. No new scripts, no worktree
  lifecycle to manage, no new agent-contract surface.
- **Cons:** Eliminates the parallelism benefit for any session that
  involves scaffold work — which is most sessions. Enforcement is
  advisory prose; the root cause of issues #292 and #212 is advisory
  prose without machine enforcement.
- **When M wins:** if the implementation cost of worktree isolation
  were prohibitive, or if scaffold mutations were rare enough that
  serializing them had negligible wall-clock impact. Neither holds.

### Option S — Per-agent git worktrees for all mutating agents

Every specialist that reads or writes the scaffold — writer or reader —
gets its own `git worktree add` in a temporary directory. All git
operations in the specialist's brief are scoped to that worktree.

- **Sketch:** `tech-lead` runs `git -C sw-dev-team-template worktree
  add .worktrees/<role>-<uuid> -b agent/<role>-<uuid>` before each
  specialist dispatch.
- **Pros:** Full isolation for every agent. No shared HEAD, no shared
  index, no shared branch.
- **Cons:** Every dispatch — including read-only reviewers doing
  `git diff` — requires worktree setup overhead. The number of live
  worktrees is bounded only by the number of concurrent agents; cleanup
  on crash requires a watchdog.
- **When S wins:** if all specialist interactions with the scaffold were
  at the same risk level. In practice, a simple reviewer is at
  negligibly lower risk than a writer.

### Option C — Hybrid: read-only throwaway worktree for readers, single writer on canonical checkout

Separate agents into two classes — **writers** and **readers** — and
apply different isolation strategies:

- **Writers** use the canonical scaffold checkout, serialized: one writer
  at a time.
- **Readers** get a throwaway `git worktree add` at a temporary path,
  checked out at the current canonical HEAD. The worktree is created
  before dispatch and pruned after return.

- **Sketch:** Two dispatch lanes — a serialized writer lane (one writer
  on canonical checkout) and an unrestricted reader lane (multiple
  concurrent readers, each in a throwaway worktree in `/tmp/`).
- **Pros:** Readers run in parallel with zero risk of clobbering the
  canonical checkout. The throwaway worktree contains any git-state
  mutation a non-hermetic test script causes. Implementation complexity
  is lower than full Option S.
- **Cons:** Tech-lead must classify every specialist before dispatch;
  misclassification allows a disguised writer to run in the reader lane.
  Writer lane is still serialized.
- **When C wins:** when reader parallelism is more valuable than writer
  parallelism (typical session pattern) and classification overhead is
  lower than full per-agent worktree lifecycle management. Both hold.

---

## Decision outcome

**Chosen option: C — Hybrid isolation (serialized writer lane +
throwaway reader worktrees)**

Customer ruling recorded 2026-06-03: Option C adopted. Implemented in
`feat/worktree-isolation`.

Option M keeps parallelism safe only by eliminating it. Option S
delivers full isolation at unnecessary cost for the low-risk reader
lane. Option C addresses all three incident classes: writers serialized
(Incidents 1 and 2 closed), readers in throwaway worktrees (Incident 3
and its class closed), test-induced git mutations contained by worktree
boundary.

---

## Design: hybrid per-agent working-tree isolation (Option C)

### 1. Agent classification: writer vs reader

Every specialist dispatched against the scaffold is classified as
**writer** or **reader** before dispatch. Classification is
conservative: default to writer.

| Role | Default class | Override condition |
|---|---|---|
| `software-engineer` | Writer | Never overridden |
| `release-engineer` | Writer | Never overridden |
| `tech-writer` | Writer | Never overridden |
| `code-reviewer` | Reader | Only if the brief explicitly prohibits test execution; otherwise Writer |
| `qa-engineer` | Writer | Reclassified Reader only when running a hermetic-verified, git-state-clean test subset (see §4) |
| `architect` | Reader | Reads only; produces ADR text routed back to meta-project |
| `researcher` | Reader | Reads only; no scaffold mutations |
| `librarian` | Reader | Record reads only; no scaffold mutations |
| `ui-ux-designer` | Reader | Design and audit reads; Writer if brief requires editing scaffold files (default Reader) |
| `mcp-liaison` | Reader | Delegation only; no scaffold mutations |
| `sre` | Reader | Reads only; no scaffold mutations |
| `security-engineer` | Reader | Reads only unless running exploit-simulation scripts that mutate state |
| `project-manager` | Reader | Meta-project artifact only; scaffold reads are incidental |

Classification is declared in the dispatch brief. Tech-lead is
responsible; misclassification is a `tech-lead` protocol violation.

### 2. Writer protocol: canonical checkout, serialized

- At most one writer active on the scaffold at any time.
- `tech-lead` maintains a logical writer-lane token. A writer dispatch
  acquires the token; no second writer is dispatched until the first
  returns and the token is released.
- The writer operates on the canonical checkout at
  `./sw-dev-team-template`. It may create branches, commit, and push
  as its task requires.
- The brief must state `working_branch: <name>`. If the canonical HEAD
  is not on that branch at dispatch time, `tech-lead` switches branches
  before dispatch (not the writer).
- `tech-lead` verifies the canonical HEAD is on the expected branch
  before releasing the token and before dispatching the next writer.

### 3. Reader protocol: throwaway worktree, one per dispatch

Before dispatching a reader, `tech-lead` (or `scripts/worktree-setup.sh`)
runs:

```bash
WDIR=$(mktemp -d /tmp/agent-XXXXXX)
git -C ./sw-dev-team-template worktree add "$WDIR" HEAD
```

The brief includes `scaffold_worktree: <absolute-path>` and the
binding instruction:

> You are operating in a throwaway worktree at `<path>`. All scaffold
> file operations must use this path as the root. Do NOT run any git
> command that modifies shared state: no `git reset`, `git checkout`,
> `git switch`, `git stash`, `git clean`, `git commit`, `git merge`,
> `git rebase`, or `git push`; and no index, branch, or tag mutations
> (`git add`/`rm`/`mv`, branch/tag create or delete). If your task
> requires any of those operations, STOP and return to tech-lead with
> a reclassification request (you are a writer, not a reader, and
> must use the writer lane).

After the reader returns:

```bash
git -C ./sw-dev-team-template worktree remove "$WDIR" --force
rm -rf "$WDIR"
```

Multiple reader worktrees may be live simultaneously.

### 4. Test hermeticity contract

A test script is **hermetically safe for the reader lane** only if all
of the following hold, verified by `qa-engineer` and recorded in
`docs/tests/hermetic-verified.txt`:

1. Does not call `git reset`, `git clean`, `git stash`, `git switch`,
   `git checkout`, `git commit`, `git merge`, or `git rebase`.
2. Does not write to the git index (`git add`, `git rm`, `git mv`).
3. Does not create or delete branches or tags.
4. All temporary files are in `$TMPDIR` or within the worktree path.
5. Exits cleanly and leaves the worktree at the same HEAD SHA it started.

`test-gate-fail-each.sh` is explicitly **not hermetic** (calls
`git reset --hard`). It must run in the writer lane.

### 5. Tech-lead integration flow

```
Turn N:
  Writer W1 dispatched (token held)
  Reader R1 dispatched (worktree /tmp/agent-abc123, brief includes path)
  Reader R2 dispatched (worktree /tmp/agent-def456, brief includes path)

  [R1, R2 run in parallel; W1 runs serialized]

  R1 returns → tech-lead tears down /tmp/agent-abc123
  R2 returns → tech-lead tears down /tmp/agent-def456
  W1 returns → tech-lead verifies HEAD, releases writer token

Turn N+1:
  Writer W2 dispatched (token held) ...
```

### 6. Worktree lifecycle and cleanup

- Reader worktrees are always created in `/tmp/` (outside the repo).
- Recovery after a crash: `git -C ./sw-dev-team-template worktree list`
  then `git -C ./sw-dev-team-template worktree prune`. Documented in
  `docs/TEMPLATE_UPGRADE.md` § "Recovery".
- A startup check in `scripts/worktree-health-check.sh` warns if stale
  worktrees are detected at session start.

---

## Consequences

### Positive

- Incidents 1 and 2 are structurally impossible under writer
  serialization: only one agent holds the canonical checkout at a time.
- Incident 3 is structurally impossible for the reader lane: the
  throwaway worktree contains the `git reset --hard`.
- Reader parallelism is preserved for the dominant session pattern.
- The worktree lifecycle for readers is simple: no branch integration step.
- Non-hermetic test scripts are an explicit classification input rather
  than a silent hazard.

### Negative / trade-offs accepted

- Writer serialization is still a throughput constraint for sessions
  that require multiple parallel writers. Full Option S for writers is
  deferred to a follow-up ADR.
- Tech-lead must classify every dispatch; misclassification is a
  protocol violation.
- Reader worktrees in `/tmp/` may be lost on system restart. `git
  worktree prune` recovers the scaffold's reference list; the `/tmp/`
  directories become orphaned but cause no data loss.
- `scaffold_worktree` in reader briefs couples tech-lead's setup step
  to the specialist's working path; the setup helper script produces
  the absolute path on stdout to eliminate the manual quoting risk.

### Follow-up ADRs

- **Writer-lane worktrees (Option S for writers).** If two writers need
  parallel execution, a follow-up ADR evaluates full per-writer worktrees
  with branch integration.
- **Hermetic test audit.** A separate implementation issue audits every
  scaffold test script and populates `docs/tests/hermetic-verified.txt`.

---

## Verification

- **Success signal:** A parallel session with `code-reviewer` and
  `software-engineer` completes without git conflict, stash collision,
  or unexpected HEAD position. Reader worktrees do not appear in
  `git worktree list` after teardown.
- **Failure signal (writer-lane):** `git log` shows a commit from an
  agent that was not the active writer; or a writer reports its branch
  was switched by a concurrent process.
- **Failure signal (reader-lane):** `git reflog` shows a `reset` entry
  not initiated by a writer; or a reader could not read expected files
  because canonical HEAD had moved.
- **Reclassification signal:** A reader returns with a reclassification
  request. If this happens frequently for a given role, update that
  role's default classification.
- **Review cadence:** Re-examine after ten parallel-dispatch sessions
  using the new model, or after any new incident in either lane.

---

## Links

- Issue #212 — incident log (stash clobber, wrong-branch commit, test-gate git-reset)
- Issue #306 — non-hermetic test scripts mutating git state
- Issue #216 — `test-gate-fail-each.sh` `git reset --hard` side-effects
- FW-ADR-0021 (`docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`) —
  single-task dispatch; writer serialization is consistent with bounded-Codex model
- FW-ADR-0008 (`docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md`) —
  role-stealing / orchestration-boundary rules
- `docs/agents/manual/tech-lead-manual.md` § "Parallelism default" and
  § "Working-tree isolation" — dispatch model this ADR constrains and extends
- `scripts/worktree-setup.sh` — reader worktree creation helper
- `scripts/worktree-teardown.sh` — reader worktree removal helper
- `scripts/worktree-health-check.sh` — stale-worktree detection at session start
- `docs/tests/hermetic-verified.txt` — canonical list of hermetically safe test scripts

## Change log

- 2026-06-03 — §3 reader-prohibition brief expanded from 5 commands to the canonical 9-command set (+ index/branch/tag clause) per issue #326, to match §4 hermetic criteria.
