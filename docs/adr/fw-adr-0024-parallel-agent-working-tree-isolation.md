---
name: fw-adr-0024-parallel-agent-working-tree-isolation
description: >
  Working-tree isolation strategy for parallel specialist agents that
  mutate or read the scaffold checkout: strict serialization (current
  interim), per-agent git worktrees, or read-only clone/worktree for
  readers with a single canonical writer.
status: proposed
date: 2026-06-02
---


# FW-ADR-0024 — Parallel agent working-tree isolation

<!-- TOC -->

- [Status](#status)
- [Meta-project placement note](#meta-project-placement-note)
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
- [Required contract changes](#required-contract-changes)
  - [CLAUDE.md / scaffold](#claudemd--scaffold)
  - [tech-lead-manual.md](#tech-lead-manualmd)
  - [Agent contracts (.claude/agents/)](#agent-contracts-claudeagents)
  - [New scaffolding helpers (scripts/)](#new-scaffolding-helpers-scripts)
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
- **Current interim:** strict serialization (Option M) — no parallel
  scaffold mutations are permitted. This ADR proposes replacing that
  interim with a structural fix (Option C).
- **Deciders:** `architect` (proposed); `tech-lead` + customer (pending)
- **Consulted:** issue #212 incident log; issue #306 (non-hermetic
  tests); issue #216 (test-gate git-reset side-effects);
  `docs/agents/manual/tech-lead-manual.md` § "Parallelism default"
  and § "Dispatch discipline"; `.claude/agents/code-reviewer.md`;
  `.claude/agents/tech-lead.md` (background-by-default rule);
  `CLAUDE.md` § "Agent-teams panel"

## Meta-project placement note

Drafted in the meta-project (`docs/adr/`) per the PLAN/DO convention
(`CLAUDE.md` § "Project Identity / Working Tree"). When the chosen
option's implementation PR lands in the scaffold, this ADR migrates
into `sw-dev-team-template/docs/adr/` as part of that PR so the
rationale travels with the agent-contract changes.

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
  advisory prose. The `tech-lead-manual.md` § "Dispatch discipline"
  gains a "Scaffold serialization" subsection. Violators are caught
  after the fact (by the next incident).
- **Pros:** Zero implementation cost. No new scripts, no worktree
  lifecycle to manage, no new agent-contract surface. Immediately
  operative as a policy change.
- **Cons:** Eliminates the parallelism benefit for any session that
  involves scaffold work — which is most sessions. The customer's
  wall-clock time for multi-specialist tasks increases proportionally.
  Enforcement is advisory prose; the root cause of issues #292 and
  #212 is advisory prose without machine enforcement. A serialization
  policy that depends on `tech-lead` dispatch discipline alone will be
  violated when the session is under time pressure or when a dispatcher
  judges two tasks independent without realizing both touch the
  scaffold. Non-hermetic tests (issue #306) mean even "read-only"
  reviewers remain a risk — serialization must cover them too, further
  reducing the window for parallel work.
- **When M wins:** if the implementation cost of worktree isolation
  were prohibitive, or if scaffold mutations were rare enough that
  serializing them had negligible wall-clock impact. Neither holds for
  the typical framework session.

### Option S — Per-agent git worktrees for all mutating agents

Every specialist that reads or writes the scaffold — writer or reader —
gets its own `git worktree add` in a temporary directory under
`./sw-dev-team-template/.worktrees/<role>-<uuid>/`. All git operations
in the specialist's brief are scoped to that worktree. `tech-lead`
creates the worktree before dispatch and tears it down (via
`git worktree remove`) after the specialist reports back. Writers
commit to their worktree branch; `tech-lead` merges or PRs those
branches into main after all specialists have returned.

- **Sketch:** `tech-lead` (or a setup helper) runs `git -C
  sw-dev-team-template worktree add .worktrees/<role>-<uuid>
  -b agent/<role>-<uuid>` before each specialist dispatch. The brief
  includes the absolute path of the worktree. All specialist file
  operations are path-prefixed to that directory. After return,
  `tech-lead` runs `git -C sw-dev-team-template worktree remove
  .worktrees/<role>-<uuid> --force`. Branch integration is via
  `git merge` or `gh pr create`.
- **Pros:** Full isolation for every agent. No shared HEAD, no shared
  index, no shared branch. Writes are structurally isolated; branch-
  ownership is guaranteed by worktree construction; test-induced git
  resets are contained to the worktree and do not affect the canonical
  checkout or any other worktree. Background-parallel dispatch is safe
  for all agents.
- **Cons:** Every dispatch — including read-only reviewers doing
  `git diff` — requires worktree setup overhead. A `code-reviewer`
  doing a 30-second diff check requires the same lifecycle machinery as
  a `software-engineer` doing a three-file refactor. The brief must
  carry absolute paths, which adds coupling between `tech-lead`'s
  setup step and the specialist's working assumptions. The number of
  live worktrees under `.worktrees/` is bounded only by the number of
  concurrent agents; cleanup on crash requires a watchdog or periodic
  `git worktree prune`. Worktrees whose branches diverge significantly
  can produce complex three-way merges that `tech-lead` must resolve
  — the complexity of the integration step grows with the number of
  worktrees.
- **When S wins:** if all specialist interactions with the scaffold were
  at the same risk level (i.e., every read-only operation were as
  dangerous as every write). In practice, a `code-reviewer` running
  only `git diff` and `Read` calls is at negligibly lower risk than a
  `software-engineer` running `git commit`. The full-isolation
  overhead should track actual risk.

### Option C — Hybrid: read-only throwaway worktree for readers, single writer on canonical checkout

Separate agents into two classes — **writers** (those that mutate files
or run non-hermetic tests on the scaffold) and **readers** (those that
only inspect scaffold content using hermetically safe operations). Apply
different isolation strategies to each class:

- **Writers** use the canonical scaffold checkout, serialized: only one
  writer at a time. Writers commit directly to the canonical branch
  (or to a named feature branch they create); they own the HEAD
  transition for their duration.
- **Readers** get a throwaway `git worktree add` at a temporary path,
  checked out at the current canonical HEAD (read-only intent). The
  worktree is created before dispatch and pruned after return. The
  brief instructs the reader to operate entirely within its worktree
  path; it must not run any git command that mutates shared state
  (no `git reset`, no `git switch`, no `git stash`). If the reader
  must run tests, only hermetically verified test scripts are
  permitted (see test hermeticity contract below); otherwise the
  reader is reclassified as a writer.

- **Sketch:** `tech-lead` maintains two dispatch lanes: a serialized
  writer lane (at most one writer active at a time on the canonical
  checkout) and an unrestricted reader lane (multiple concurrent
  readers, each in its own throwaway worktree). Before dispatching a
  reader, `tech-lead` runs `git -C sw-dev-team-template worktree add
  /tmp/agent-<uuid> HEAD` (detached or on a read-branch). The brief
  includes the worktree path. After return, `tech-lead` runs
  `git worktree remove /tmp/agent-<uuid> --force`. Reader worktrees
  are on detached HEAD or a throwaway branch; they do not merge back.
  Writer output merges back via the canonical checkout (or a short-
  lived feature branch + PR).
- **Pros:** Readers run in parallel with zero risk of clobbering the
  canonical checkout or each other. The throwaway worktree contains
  any git-state mutation a non-hermetic test script causes; the
  canonical checkout and other readers are unaffected. Writer
  serialization covers the high-risk lane without imposing overhead
  on the low-risk lane. Implementation complexity is lower than full
  Option S (reader worktrees are simpler — no branch integration
  step) while delivering the most critical safety property (no shared
  HEAD mutation). The worktree lifecycle for readers is simpler than
  for writers because readers never commit; `git worktree remove
  --force` always succeeds.
- **Cons:** Tech-lead must classify every specialist as writer or
  reader before dispatch; misclassification allows a disguised writer
  (e.g., a code-reviewer that runs non-hermetic tests) to run in the
  reader lane and still corrupt state. Classification must be
  conservative: default writer unless the specialist's operations are
  provably hermetic. Writer lane is still serialized; parallel
  independent writers (two software-engineers on disjoint files) are
  not accelerated. Full Option S worktrees for writers (feature
  branches + PR per writer) would allow two writers in parallel, but
  that is out of scope for this ADR's chosen option — it is noted as
  a follow-up.
- **When C wins:** when reader parallelism is more valuable than
  writer parallelism (typical: review passes, research reads, and
  test validation all run in parallel while the single writer
  proceeds), and when the classification overhead is lower than the
  overhead of full per-agent worktree lifecycle management. Both hold
  for the framework's actual session pattern.

---

## Decision outcome

**Recommended option: C — Hybrid isolation (serialized writer lane +
throwaway reader worktrees)**

Option M keeps parallelism safe only by eliminating it, which
contradicts the `tech-lead-manual.md` "Parallelism default" as a
baseline and causes customer wall-clock regression on every multi-
specialist session. Option S delivers full isolation at the cost of
worktree lifecycle overhead on every dispatch including trivially safe
ones; it is the correct long-term target if writers also need
parallelism, but that is a separate problem. Option C addresses all
three documented incident classes with the minimum viable isolation
surface: writers are serialized (closing Incidents 1 and 2), readers
are in throwaway worktrees (closing Incident 3 and its class), and
test-induced git mutations are contained by the worktree boundary
regardless of whether a test script is hermetic or not.

**This recommendation is pending customer ruling.** The contract
changes in the section below are implementation-ready once the ruling
is recorded.

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
| `sre` | Reader | Reads only; no scaffold mutations |
| `security-engineer` | Reader | Reads only unless running exploit-simulation scripts that mutate state |
| `project-manager` | Reader | Meta-project artifact only; scaffold reads are incidental |

Classification is declared in the dispatch brief and in the
`tech-lead-manual.md` dispatch-discipline section. Tech-lead is
responsible for the classification; misclassification is a `tech-lead`
protocol violation, not a specialist violation.

### 2. Writer protocol: canonical checkout, serialized

- At most one writer active on the scaffold at any time.
- `tech-lead` maintains a logical writer-lane token. A writer dispatch
  acquires the token; no second writer is dispatched until the first
  returns and the token is released.
- The writer operates on the canonical checkout at
  `./sw-dev-team-template`. It may create branches, commit, and push
  as its task requires.
- The brief must state the expected branch at entry and exit:
  `working_branch: <name>`. If the canonical HEAD is not on that branch
  at dispatch time, `tech-lead` switches branches before dispatch (not
  the writer).
- `tech-lead` verifies the canonical HEAD is on the expected branch
  before releasing the token and before dispatching the next writer.
- **Optional upgrade (follow-up, not in scope for this ADR):** if two
  writers are provably working on disjoint paths, `tech-lead` may
  instead use `git worktree add` for each writer (full Option S for
  the writer lane). This requires a merge/PR integration step and is
  deferred to a follow-up ADR.

### 3. Reader protocol: throwaway worktree, one per dispatch

Before dispatching a reader, `tech-lead` (or a setup helper script)
runs:

```bash
WDIR=$(mktemp -d /tmp/agent-XXXXXX)
git -C ./sw-dev-team-template worktree add "$WDIR" HEAD
```

The worktree is checked out at the current canonical HEAD (detached
or on a read-tracking branch, never a named branch the reader owns).
The brief includes `scaffold_worktree: <absolute-path>` and the
binding instruction:

> You are operating in a throwaway worktree at `<path>`. All scaffold
> file operations must use this path as the root. Do NOT run any git
> command that modifies shared state: no `git reset`, no `git switch`,
> no `git stash`, no `git commit`, no `git push`. If your task
> requires any of those operations, STOP and return to tech-lead with
> a reclassification request (you are a writer, not a reader, and
> must use the writer lane).

After the reader returns (or after a timeout), `tech-lead` runs:

```bash
git -C ./sw-dev-team-template worktree remove "$WDIR" --force
rm -rf "$WDIR"
```

Multiple reader worktrees may be live simultaneously; they do not
interfere with each other or with the canonical checkout.

### 4. Test hermeticity contract

A test script is considered **hermetically safe for the reader lane**
only if it satisfies all of the following, verified by `qa-engineer`
and recorded in `docs/tests/hermetic-verified.txt`:

1. It does not call `git reset`, `git clean`, `git stash`, `git switch`,
   `git checkout`, `git commit`, `git merge`, or `git rebase`.
2. It does not write to the git index (`git add`, `git rm`, `git mv`).
3. It does not create or delete branches or tags.
4. All temporary files it creates are in `$TMPDIR` or within the
   worktree path (not in the caller's `$PWD` or a hard-coded path
   that could resolve outside the worktree).
5. It exits cleanly (any exit code) and leaves the worktree tree at
   the same HEAD SHA it started with.

Test scripts that fail any criterion are **not hermetic** and must not
be run in the reader lane. A reader whose brief includes such a test
script is automatically reclassified as a writer.

`test-gate-fail-each.sh` is explicitly **not hermetic** (issues #306
/ #216: it calls `git reset --hard`). It must run in the writer lane
or be refactored to meet the criteria above before being used in the
reader lane.

`docs/tests/hermetic-verified.txt` is the canonical list maintained
by `qa-engineer`. Tech-lead consults it before classifying any
test-running brief as Reader.

### 5. Tech-lead integration flow

```
Turn N:
  Writer W1 dispatched (token held)
  Reader R1 dispatched (worktree /tmp/agent-abc123 created, brief includes path)
  Reader R2 dispatched (worktree /tmp/agent-def456 created, brief includes path)

  [R1, R2 run in parallel; W1 runs serialized]

  R1 returns → tech-lead tears down /tmp/agent-abc123
  R2 returns → tech-lead tears down /tmp/agent-def456
  W1 returns → tech-lead verifies HEAD, releases writer token

Turn N+1:
  Writer W2 dispatched (token held)
  ...
```

If a writer fails or times out, `tech-lead` inspects the canonical
checkout's `git status` before dispatching the next writer. If the
checkout is in a dirty or partially-committed state, `tech-lead`
routes to `software-engineer` to clean up before proceeding; it does
not `git reset --hard` without specialist review.

### 6. Worktree lifecycle and cleanup

- Reader worktrees are always created in `/tmp/` (outside the repo),
  not under `.worktrees/` inside the scaffold. This prevents
  accidental `git add` of worktree state by a writer operating on the
  canonical checkout.
- `git worktree list` is the recovery tool. If a session crashes
  with live reader worktrees, the operator runs:
  ```bash
  git -C ./sw-dev-team-template worktree list
  git -C ./sw-dev-team-template worktree prune
  ```
  This is documented in `docs/TEMPLATE_UPGRADE.md` § "Recovery".
- A startup check (added to `scripts/agent-health.sh` or equivalent)
  warns if stale worktrees are detected at session start.

---

## Required contract changes

The following changes are required in the scaffold to implement
Option C. A follow-up implementation issue should cite this list.

### CLAUDE.md / scaffold

1. Add a § "Parallel agent working-tree isolation" section (or a
   reference to `docs/agents/manual/tech-lead-manual.md` § "Working-
   tree isolation") stating the two-lane model and the writer-
   serialization rule as a Hard Rule (candidate: Hard Rule #12,
   pending customer ratification of the numbering).

### tech-lead-manual.md

2. Add § "Working-tree isolation" immediately after § "Parallelism
   default" with:
   - Writer vs reader classification table (§1 above).
   - Writer-lane token protocol (§2 above).
   - Reader worktree setup/teardown commands (§3 above).
   - Brief fields: `scaffold_worktree` for readers, `working_branch`
     for writers.
   - The reader-lane prohibition list (no `git reset`, no `git switch`,
     etc.) as binding prose.
   - Reclassification request format for specialists that discover
     mid-task they need writer access.

3. Update § "Parallelism default" to add: "Reader specialists
   dispatched with a `scaffold_worktree` brief field may be
   parallelized freely. Writer specialists must be serialized through
   the writer-lane token. Do not dispatch two writers in the same
   Agent-tool block."

### Agent contracts (.claude/agents/)

4. `code-reviewer.md`: Add a "Working-tree isolation" section
   specifying that `code-reviewer` operates as a Reader by default,
   must use the `scaffold_worktree` path from its brief for all
   scaffold reads, and must not run non-hermetic test scripts (if
   the brief asks it to run `test-gate-fail-each.sh` or any script
   not in `docs/tests/hermetic-verified.txt`, it must stop and return
   a reclassification request).

5. `software-engineer.md`: Add a "Working-tree isolation" section
   specifying that `software-engineer` always operates as a Writer,
   must not run non-hermetic tests outside the canonical checkout,
   and must state its active branch in every progress report.

6. `qa-engineer.md`: Add a "Working-tree isolation" section
   specifying that `qa-engineer` is a Writer by default; reclassified
   Reader only when its brief explicitly restricts it to the hermetic-
   verified test set and the brief includes `scaffold_worktree`.

7. `release-engineer.md`: Add a "Working-tree isolation" note
   confirming Writer classification; release scripts that call
   `git reset` or manage branches are never hermetic.

### New scaffolding helpers (scripts/)

8. `scripts/worktree-setup.sh <scaffold-path>`: creates a reader
   worktree in `/tmp/agent-<uuid>`, prints the absolute path to
   stdout, and exits. Used by tech-lead before each reader dispatch.

9. `scripts/worktree-teardown.sh <worktree-path> <scaffold-path>`:
   runs `git worktree remove <path> --force` against the scaffold,
   then `rm -rf <path>`. Used by tech-lead after each reader returns.

10. `scripts/worktree-health-check.sh <scaffold-path>`: lists stale
    worktrees (via `git worktree list --porcelain`), warns if any
    `/tmp/agent-*` paths exist without a live dispatch, and suggests
    `git worktree prune`. Invoked by `scripts/agent-health.sh` at
    session start.

11. Update `docs/tests/hermetic-verified.txt` (new file if absent):
    initial content is an empty list with a header explaining the
    criteria from §4. `qa-engineer` populates it as test scripts are
    audited. This file is template-shipped and covered by
    `TEMPLATE_MANIFEST.lock`.

---

## Consequences

### Positive

- Incidents 1 and 2 (stash clobber, wrong-branch commit) are
  structurally impossible under writer serialization: only one agent
  holds the canonical checkout at a time, so no concurrent git
  commands compete for HEAD or the stash.
- Incident 3 (test-gate git-reset dropping commits) is structurally
  impossible for the reader lane: the throwaway worktree contains the
  `git reset --hard`, which leaves the canonical checkout and all
  other worktrees untouched.
- Reader parallelism is preserved. `code-reviewer`, `researcher`,
  `architect`, and `sre` can all run concurrently in their own
  worktrees, which is the dominant parallelism pattern in a typical
  session.
- The worktree lifecycle is simple for readers: create at dispatch,
  remove at return, no branch integration step.
- Non-hermetic test scripts are now an explicit classification input
  rather than a silent hazard; the `hermetic-verified.txt` list gives
  tech-lead a machine-checkable source rather than per-dispatch
  judgment.

### Negative / trade-offs accepted

- Writer serialization is still a throughput constraint for sessions
  that require multiple parallel writers (two software-engineers
  on independent files). This is the known cost of the chosen option;
  full Option S worktrees for writers would address it but requires
  branch integration work that is out of scope for this ADR.
- Tech-lead must classify every dispatch before sending it. This adds
  one classification step per dispatch; misclassification is a
  `tech-lead` protocol violation. The classification table in the
  manual reduces per-dispatch judgment to a table lookup for common
  roles.
- Reader worktrees in `/tmp/` may be lost on system restart without
  teardown. `git worktree prune` recovers the scaffold's internal
  reference list; the `/tmp/` directories themselves become orphaned
  (no data loss, just temporary disk waste). The health-check script
  mitigates this at the next session start.
- Adding `scaffold_worktree` to reader briefs adds a coupling between
  tech-lead's setup step and the specialist's working path. Briefs
  must use absolute paths; a relative path in the `scaffold_worktree`
  field is a silent bug. The setup helper script produces the absolute
  path on stdout to eliminate the manual quoting risk.
- The `hermetic-verified.txt` list requires ongoing maintenance by
  `qa-engineer` as new test scripts are added. A test script added
  without hermetic audit defaults to non-hermetic (writer-only), which
  is the safe default.

### Follow-up ADRs

- **Writer-lane worktrees (Option S for writers).** If two writers need
  to run in parallel, a follow-up ADR should evaluate full per-writer
  worktrees with branch integration (full Option S for the writer lane).
  The prerequisite is a clean branch-ownership model and a tested merge
  strategy; this ADR's writer-serialization is the interim.
- **Hermetic test audit (issues #306 / #216).** A separate work item
  (not an ADR, but an implementation issue) should audit every scaffold
  test script against the §4 criteria and populate
  `docs/tests/hermetic-verified.txt`. Until that audit is complete,
  all test-running briefs must be classified Writer.

---

## Verification

- **Success signal:** A session where `code-reviewer` and
  `software-engineer` are dispatched in parallel completes without
  either agent reporting a git conflict, stash collision, or unexpected
  HEAD position. `git log` on the canonical checkout after the session
  shows exactly the commits the writer produced, in order, with no
  gaps. Reader worktrees do not appear in `git worktree list` after
  teardown.
- **Failure signal (writer-lane):** `git log` on the canonical checkout
  after a session shows a commit attributable to an agent that was not
  the active writer at that time; or a writer reports that its branch
  was switched by a concurrent process.
- **Failure signal (reader-lane):** `git reflog` on the canonical
  checkout after a session shows a `reset` entry that was not initiated
  by a writer; or a reader's return includes a note that it could not
  read expected files because the canonical HEAD had moved.
- **Reclassification signal:** A reader returns with a reclassification
  request ("I need to run `test-gate-fail-each.sh` which is not in
  `hermetic-verified.txt`"). Tech-lead should queue the reader's task
  into the writer lane and re-dispatch. If this happens frequently for
  a given role, update that role's default classification.
- **Review cadence:** Re-examine after ten parallel-dispatch sessions
  using the new model, or after any new incident in the writer or
  reader lane, whichever comes first. Promote writer-lane worktrees to
  a full Option S if two-writer parallelism is requested by the customer.

---

## Links

- Issue #212 (`occamsshavingkit/sw-dev-team-template`) — incident log
  (stash clobber, wrong-branch commit, test-gate git-reset)
- Issue #306 — non-hermetic test scripts mutating git state
- Issue #216 — `test-gate-fail-each.sh` `git reset --hard`
  side-effects
- FW-ADR-0021 (`docs/adr/fw-adr-0021-harness-agnostic-leaf-task-dispatch.md`) —
  single-task dispatch discipline; the bounded-Codex model this ADR's
  writer serialization is consistent with
- FW-ADR-0008 (`docs/adr/fw-adr-0008-tech-lead-orchestration-boundary.md`) —
  role-stealing / orchestration-boundary rules; the "tech-lead does not
  reset the checkout without specialist review" rule above is consistent
  with FW-ADR-0008's no-role-stealing posture
- `docs/agents/manual/tech-lead-manual.md` § "Parallelism default"
  and § "Dispatch discipline" — the dispatch model this ADR constrains
- `.claude/agents/code-reviewer.md` — role contract receiving the
  reader-lane classification and brief-field additions
- `scripts/agent-health.sh` — receives the worktree health-check
  integration
- `CLAUDE.md` § "Agent-teams panel" and § "Hard rules" — the
  parallel-dispatch model and hard-rule surface this ADR extends
