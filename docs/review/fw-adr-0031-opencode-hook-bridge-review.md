# Code Review — OpenCode enforcement hook bridge (fw-adr-0031)

<!-- TOC -->

- [1. Identification](#1-identification)
- [2. Scope and method](#2-scope-and-method)
- [3. Original review record — commit 6244214](#3-original-review-record--commit-6244214)
  - [3.1 Items verified correct](#31-items-verified-correct)
  - [3.2 Findings raised](#32-findings-raised)
  - [3.3 Original ship recommendation](#33-original-ship-recommendation)
- [4. This pass — review of the five commits since](#4-this-pass--review-of-the-five-commits-since)
  - [4.1 ac5d005 — close W1/W2](#41-ac5d005--close-w1w2)
  - [4.2 65349ea — close H-1(b)/M-2](#42-65349ea--close-h-1bm-2)
  - [4.3 c4bc456 — close the session.updated privilege escalation](#43-c4bc456--close-the-sessionupdated-privilege-escalation)
  - [4.4 1368fab — S1 bounded eviction](#44-1368fab--s1-bounded-eviction)
  - [4.5 ab1d952 — S2, decouple handledIdleSessions eviction](#45-ab1d952--s2-decouple-handledidlesessions-eviction)
- [5. Findings register (this pass)](#5-findings-register-this-pass)
- [6. Independent verification performed](#6-independent-verification-performed)
- [7. Out-of-scope commits still lacking a durable review record](#7-out-of-scope-commits-still-lacking-a-durable-review-record)
- [8. Disposition](#8-disposition)
- [9. Record of review](#9-record-of-review)
- [10. References](#10-references)

<!-- /TOC -->

---

## 1. Identification

- **Artefact / subsystem reviewed:** OpenCode enforcement hook bridge —
  `.opencode/plugin/hook-bridge.js`, `tests/hooks/test-opencode-hook-bridge.sh`,
  `scripts/opencode/tool-arg-map.json`. Same artefact boundary as
  `docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md`.
- **Commits reviewed:** `6244214` (original pass, § 3) and
  `ac5d005`, `65349ea`, `c4bc456`, `1368fab`, `ab1d952` (this pass, § 4),
  covering the full range `6244214..ab1d952` for the files above.
- **Reviewer:** `code-reviewer`.
- **Dates:** original review of `6244214` — 2026-07-25, same day as
  authorship, prior to `ac5d005` (00:15 CEST); this durable filing and
  the review of the five subsequent commits — 2026-07-25 (later
  session, after `ab1d952`, working tree at `ab1d952`).
- **Trigger for this filing:** Hard Rule #3 (no commit without
  `code-reviewer` review) plus the specific gap the Hard Rule #7
  security assessment named as UA-OPENCODE-HOOK-BRIDGE-0002: the
  original review of `6244214` existed only as agent output, never
  persisted, and the four (then five, after `ab1d952` landed) fix
  commits that followed it had no review record — durable or
  otherwise — at all.
- **Supersedes:** None as a filed artefact. First persisted
  `code-reviewer` record for this branch.

---

## 2. Scope and method

**In scope.** `.opencode/plugin/hook-bridge.js` (all 1123 lines at
HEAD, `ab1d952`), `tests/hooks/test-opencode-hook-bridge.sh` (851
lines), `scripts/opencode/tool-arg-map.json`, and the full diff
`6244214..ab1d952` restricted to these paths plus the two
release-gate scripts the range touches
(`scripts/lib/gate-hook-negative-corpus.sh`,
`scripts/lib/gate-hook-exec-bits.sh` — read for context, not
re-reviewed line-by-line since `4dcb41a`/`edfb485` are outside this
task's five-commit brief; see § 7).

**Method — read plus independent execution**, not read-only. Unlike
the Hard Rule #7 security assessment (`docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md`),
which was static-only for lack of a Bash tool, this review had shell
access and used it:

- Read every diff in the range in full (`git show <sha> -- <path>`),
  cross-referenced against each commit's own message.
- Ran `node --check .opencode/plugin/hook-bridge.js` — syntax OK.
- Ran `tests/hooks/test-opencode-hook-bridge.sh` independently at HEAD:
  **39 passed, 0 failed, 0 skipped, 0 findings** — matches the
  `ab1d952` commit message's self-reported count exactly.
- Ran `tests/hooks/run-negative-corpus.sh --all` and `--all --harness
  opencode` independently: **40/40 pass** both modes — matches.
- Performed **two independent mutation ("load-bearing") checks** on
  the shipped test suite rather than trusting the commit messages'
  own load-bearing claims at face value (§ 6): reintroduced the
  pre-S2 shared-eviction-clock bug and reproduced the exact 37/39
  failure the `ab1d952` message claims; separately neutralised the
  `c4bc456` `session.updated`-follow fix and confirmed the two tests
  that specifically cover it (and only those two) fail. Both mutations
  were reverted and the working tree confirmed byte-identical
  (`md5sum`) before and after.
- Constructed and ran two additional reproduction scripts, outside the
  shipped suite, to independently probe the eviction/resume
  interaction the task brief asked this review to scrutinise (§ 4.5,
  § 5, finding CR-0001) — these are not part of the shipped test
  suite and are not proposed as a replacement for one; they exist to
  verify a hypothesis before reporting it as a finding.

**Out of scope for this filing.** `scripts/hooks/*.py` themselves
(unchanged across the whole range — confirmed:
`git diff --name-only 6244214..HEAD -- scripts/hooks/` returns exactly
one path, `scripts/hooks/role-routing-reminder.sh`, and that diff is a
mode-bit change (`100644` → `100755`), not a content change — logic
untouched). `docs/adr/fw-adr-0031-opencode-hook-bridge.md`,
`docs/templates/security-template.md`, and the security assessment
itself are read for context but not re-reviewed as artefacts in their
own right (`tech-writer`/`security-engineer` territory). The six
commits in `6244214..HEAD` not named in this task's brief
(`725b5a6`, `4dcb41a`, `edfb485`, `a7420dd`, `62ac407`, `62f59f6`) are
named but not reviewed here — see § 7.

---

## 3. Original review record — commit 6244214

Reconstructed retroactively, per this task's instruction, from the
review session's own findings as they survive today: the W1/W2 labels
inline in `ac5d005`'s diff and commit message (which quotes the
findings verbatim as the fix's own justification), plus this
reviewer's independent re-reading of `6244214`'s tree
(`git show 6244214:.opencode/plugin/hook-bridge.js`, 687 lines) against
that same commit message. No claim is made that this reconstruction is
verbatim beyond what `ac5d005` already preserves; it is presented as
the best available record, which is the entire point of this filing.

**Scope of the original review.** `.opencode/plugin/hook-bridge.js` at
`6244214` (687 lines, first version), `tests/hooks/test-opencode-hook-bridge.sh`
at the same commit (437 lines, Part A table-driven plus Part B 30
live-differential cases), `scripts/opencode/tool-arg-map.json`, and the
governing ADR narrative for the two runtime-spike claims the code's own
comments cite.

**Method.** Full read of `hook-bridge.js`'s control flow, traced
against `fw-adr-0031`'s binding verdict-translation and
fail-open/fail-closed contract; test file read and (per the commit's
own "Verified" block, reproduced independently at review time)
executed — `test-opencode-hook-bridge.sh` 30/30,
`run-negative-corpus.sh --all --harness opencode` 40/40,
`pre-release-gate.sh --only opencode-hook-parity` PASS.

### 3.1 Items verified correct

- **Subprocess safety.** Guard-hook subprocesses are spawned via
  `child_process.spawn` with an explicit argument array (no shell
  interpolation of untrusted input into a command string), a bounded
  timeout (`GUARD_HOOK_TIMEOUT_MS`, default 5000ms) that kills and
  fails closed on expiry, and the parent's own `process.env` spread
  forward unmodified (no secret material newly introduced or logged).
- **Per-session state shape.** At `6244214`, `sessionParent` and
  `sessionAgent` (`Map<sessionID, value>`) and `handledIdleSessions`
  (`Set<sessionID>`) are populated unconditionally from
  `session.created`/`session.idle` with no eviction — correctly
  understood at the time as later flagged low-severity (S1, closed
  this pass's range — § 4.4).
- **Guard-chain ordering.** `WRITE_EDIT_BASH_CHAIN` runs
  `customer-notes-guard.py` → `tech-lead-authoring-guard.py` →
  `handoff-pre-tool-gate.py` in a `for...of` loop with
  `// eslint-disable-next-line no-await-in-loop -- ordering is the
  point`, first-deny-wins (a `throw` inside the loop short-circuits
  the remaining chain). Confirmed by the original test suite's
  ordering assertion (case B3, still present and passing at HEAD).
- **`scripts/hooks/` untouched.** `6244214`'s own commit message
  states `git diff --name-only scripts/hooks/` was empty at commit
  time; independently re-confirmed for the full `6244214..HEAD` range
  in this pass (§ 2) — still true, with the sole exception of a
  mode-bit fix on one shell script, not a logic change.
- **The ADR-vs-scaffold planning-artefact question.** `fw-adr-0031`
  lands in `docs/adr/` inside the scaffold repository itself, not only
  in the meta-project's planning tree. This was checked against
  CLAUDE.md's PLAN/DO split at review time and found correct, not a
  violation: this repository's `docs/adr/fw-adr-NNNN-*.md` series is
  the framework's own **self-hosted** architecture-decision record —
  product content shipped alongside the code that implements it (the
  scaffold has always carried its own `fw-adr-0001` onward, e.g.
  `fw-adr-0009-opencode-harness-adapter.md`), not a copy of the
  meta-project's separate decisions about *how to improve* the
  scaffold. The meta-project's own `docs/adr/` mirrors these
  by consuming/upgrading from the scaffold, which is the documented,
  intentional relationship, not drift.

### 3.2 Findings raised

**W1 (Warning).** The `agent_type` privilege-forwarding path —
`session.created`'s `info.agent` forwarded as `agent_type` on every
guarded `tool.execute.before` payload, which
`tech-lead-authoring-guard.py`'s `_resolve_subagent_role()` reads to
decide `caller_role`, i.e. the entire allow/deny decision for a
non-tech-lead caller — shipped with **zero automated coverage**.
Verified correct by hand at review time, but nothing in the suite
would have caught a future refactor silently breaking it. Compounding
factor: the suite's existing `subagent_type` checks cover the `task`
tool's *spawn-target* argument, a different mechanism with a
confusingly similar name, so the coverage gap read as closed when it
was not.

**W2 (Warning).** `GUARD_CHAIN_BY_TOOL` could declare a tool id (e.g.
`bash`) with no corresponding `scripts/opencode/tool-arg-map.json`
entry (a future edit to the map dropping or typo-ing a key).
`buildGuardPayload` would then return `null` for that tool id,
`tool.execute.before`'s `if (!payload) return;` would exit silently,
and the **entire guard chain for that tool would stop running with no
error and no log line** — a silent, bridge-wide-scoped enforcement
bypass for as long as the mismatch persisted, caught only by the
release-time `opencode-hook-parity` sub-gate, meaning any working tree
between releases was exposed. Per `fw-adr-0031`'s own framing, a
silent enforcement bypass is the worst outcome this bridge can
produce, so this should not depend solely on a release-time check.

Both findings are Warning-severity (not Critical): neither was
observed to have actually occurred (the map and the chain were
consistent at commit time), and both are latent-defect classes rather
than live exploits — but both sit directly on the trust boundary Hard
Rule #7 governs, which is why they were not waved through as
Suggestions.

### 3.3 Original ship recommendation

**APPROVED WITH FINDINGS**, conditional on W1 and W2 being closed
before the Hard Rule #7 sign-off could be considered unconditional.
Everything in § 3.1 was sound; nothing in W1/W2 was assessed as
disqualifying for continued work on the branch, but both were assessed
as too close to the bridge's core trust mechanism (privilege
forwarding, fail-closed enforcement) to defer past this branch. This
recommendation was **not persisted anywhere else** — the gap this
document exists to close.

---

## 4. This pass — review of the five commits since

Each commit below is read against its own stated diff, its own stated
verification, and (where practical) independently re-executed or
mutation-tested rather than taken on the commit message's word alone.

### 4.1 ac5d005 — close W1/W2

Closes both § 3.2 findings.

**W1 closure.** Adds B9/B10/B11 to
`tests/hooks/test-opencode-hook-bridge.sh`: three chained
`session.created` → `tool.execute.before` scenarios on the same
`sessionID`, asserting on the **actual wire payload** sent to
`tech-lead-authoring-guard.py` (`agent_type`), not merely the resulting
verdict — B9 (specialist allowed, `agent_type` present and correct),
B10 (tech-lead self-claim denied, `agent_type=tech-lead` confirmed
forwarded so the denial is provably `_validate_role()`'s explicit
self-push rejection and not the bridge silently dropping the field),
B11 (no prior `session.created` for that `sessionID` → throw with
`agent_type` genuinely absent — fail-safe). This is the correct
design: a naive test asserting only the verdict would pass even if
forwarding silently broke, since both a correctly-forwarded and a
silently-dropped `agent_type` can independently produce a deny
verdict for other reasons. Confirmed present and passing at HEAD
(independently re-run, § 2).

**W2 closure.** `TOOL_ARG_MAP_MISSING_TOOL_IDS`
(`.opencode/plugin/hook-bridge.js:112–126`) computed once at module
load: every `GUARD_CHAIN_BY_TOOL` key must have a
`tool-arg-map.json` entry, else `tool.execute.before` throws on
**every** guarded call, bridge-wide, naming the missing ids
(`hook-bridge.js:415–429` at `6244214`'s successor line numbers, now
`~696–712` at HEAD after later insertions). Deliberately bridge-wide
rather than per-tool — an untrustworthy map is a bridge-wide problem,
matching the ADR's own framing. The residual `if (!payload)` path
(previously a silent `return`) now throws as an unreachable-invariant
guard, defense-in-depth against a future refactor that violates the
module-load assertion's own guarantee some other way. Read and
confirmed matching the commit message exactly; no discrepancy found.

**Assessment:** both fixes correctly close the findings they target,
the new tests are load-bearing (verified for W1's B9-B11 via mutation
in § 6), and neither fix introduces a new risk. **No findings.**

### 4.2 65349ea — close H-1(b)/M-2

Closes two of the Hard Rule #7 security assessment's conditions
(read from the security assessment's own § 7, which records these
under `SEC-OPENCODE-HOOK-BRIDGE-0002` and `-0006`).

**H-1(b).** `session.created` previously wrote `sessionParent` and
`sessionAgent` unconditionally on every fire for a given `sessionID`.
Since `tech-lead-authoring-guard.py` grants an unconditional write
bypass to any validated non-tech-lead role (binary tech-lead-vs-not,
not role-scoped), an unverified re-fire with a different `info.agent`
could silently change the guard-visible role mid-session with no
re-dispatch through `tech-lead`. Now first-write-wins for both maps:
a re-fire with a differing value is retained-and-logged
(`console.error`, not thrown — correctly reasoned as an event handler
with no defined abort semantics, not a gate). `sessionParent` gets the
identical treatment because it drives Stop-vs-SubagentStop routing at
`session.idle`, the same silent-misroute risk class. Read at
`hook-bridge.js:600–660` (HEAD line numbers); matches the commit
message. The fix is correctly framed as not depending on confirming
whether OpenCode actually re-fires `session.created` — it removes the
assumption rather than resting on it, which is the right posture given
the assumption was later found to matter in a different way (§ 4.3).

**M-2.** A guard hook whose stdout failed to JSON-parse fell through
to the fail-open posture silently. The fail-open *decision* is
correctly left unchanged (mandated by the ADR's binding
"inherit the hook's own posture" contract) — only visibility changes:
`applyVerdict()` now logs the hook name and a 500-byte stdout excerpt
via `console.error` on this path (`hook-bridge.js:296–306`). A 1MB
stdout accumulation cap (`MAX_STDOUT_BYTES`, `runSubprocess` at
`~200-220`) is bundled in the same commit as adjacent hardening — the
stream still drains (needed for `close` to fire) rather than killing
the process, correctly reasoned as not escalating a merely-verbose
hook to a bridge-infrastructure failure.

**Assessment:** both fixes match their stated intent exactly on
reading, and correctly preserve the ADR's binding fail-open/fail-closed
split rather than silently tightening or loosening it. **No
findings.**

### 4.3 c4bc456 — close the session.updated privilege escalation

The most consequential commit in this range: a HIGH-severity
privilege-escalation finding from a runtime spike against OpenCode
1.18.5, closed the same day.

**The defect it fixes.** `sessionAgent` was written only in the
`session.created` branch; `session.created` never re-fires for an
existing `sessionID` (confirmed by spike), but `info.agent` for an
existing `sessionID` **does** change via plain `session.updated` when
a session is resumed with a different `--agent`
(`opencode run --session <id> --agent <other-agent>`). Without a
`session.updated` subscription, a session that legitimately spawned as
(say) `software-engineer` kept receiving `tech-lead-authoring-guard.py`'s
write bypass on every later call even after its real running identity
had moved on. Attack cost: `opencode session list` (any bash-capable
session) plus one resume invocation.

**The fix.** Subscribes to `session.updated`
(`hook-bridge.js:~888-940`) and follows the session's current
`info.agent`, logging every observed change. `session.created` keeps
first-write-wins (RETAIN); `session.updated` is deliberately the
opposite policy (FOLLOW) — documented inline at length, correctly,
because it reads as inconsistent without the explanation.

**Scrutiny of the deliberate asymmetry (per this task's explicit
ask).** The escalation-vector argument in the code comment
(`hook-bridge.js:~446-472`) is: `tech-lead-authoring-guard.py` grants
the *same* bypass to every validated non-tech-lead role and
`_validate_role()` rejects the literal string `"tech-lead"` outright,
so a followed change can only move a session between "some specialist"
(already-equivalent bypass) and "tech-lead-or-unknown" (`None`, the
restrictive outcome) — no transition through this handler grants a
tier the session could not already reach by being freshly dispatched
as that role. **This reasoning is sound as stated** and correctly
scoped to the guard's actual (binary, not role-scoped) privilege
model — it does not overclaim a stronger guarantee than the guard it
is reasoning about actually provides. It is also correctly
distinguished from spoofing a role name outright: an undefined role
string is caught by `_validate_role()` regardless of which event
carried it, so `session.updated` following an *invalid* agent name
does not itself open a new hole.

**Documentation adequacy against a future "harmonising" reader.** The
task asked specifically whether the asymmetry is adequately documented
against someone later "fixing" it into one consistent policy. It is —
the `sessionAgent` declaration comment states outright "do not 'fix'
this into one consistent policy, they answer different questions" and
gives the full reasoning inline at the point of declaration, not just
buried in a commit message. This is the correct place for it: the next
reader of the *code* sees the warning, not only the next reader of
`git log`.

**Also fixed in the same commit:** a factually wrong code comment
(top-level sessions were claimed to carry a "mode name" `info.agent`
at `session.created` that "correctly fails `_validate_role()`" — in
fact `info.agent` is absent entirely at `session.created` for a
top-level session and arrives later via its first `session.updated`,
carrying `opencode.json`'s `default_agent: "tech-lead"`, rejected by
name). Corrected comment matches observed behaviour; the "top-level
session safety" test (present, passing) covers this path.

**Tests.** B12/B13 assert on the actual wire `agent_type`, not just
the verdict — correctly, per the same reasoning as W1's B9-B11, since
both the stale and the current role can independently produce the same
bypass verdict. **Independently confirmed load-bearing this pass**
(§ 6): neutralising the fix causes exactly these two tests (and only
these two) to fail, with the fail-open direction unaffected.

**Assessment:** the fix is correct, the asymmetry is sound and well
documented, and the tests are load-bearing. **No findings against this
commit in isolation.** Its interaction with the two commits that
follow it, however, is the subject of finding CR-0001 (§ 4.5, § 5).

### 4.4 1368fab — S1 bounded eviction

Closes the security assessment's S1 finding (`SEC-OPENCODE-HOOK-BRIDGE-0008`):
`sessionParent`/`sessionAgent`/`handledIdleSessions` grew unboundedly
for the life of a long-running OpenCode server process, since the
bridge's wired event surface has no session-ended signal and
`session.idle` cannot safely be treated as one (it is the
Stop-equivalent, not "this session will never be touched again", and a
second `session.idle` is the documented double-fire the bridge already
dedupes rather than a stronger done-signal).

**The fix.** A single shared FIFO ledger, `sessionInsertOrder`,
populated once per distinct `sessionID` at `session.created` time,
evicting the oldest entry from all three structures together once
`SESSION_STATE_CAP` (10000) is exceeded. Bound chosen two orders of
magnitude above `subcall-limit-guard.py`'s `DEFAULT_SUBCALL_BUDGET`
(100), the closest existing per-top-level-session bound in this
codebase. Correctly reasoned as degrading fail-safe on the identity
axis: an evicted-but-still-live session's next guarded call resolves
`caller_role = None` (denies) rather than granting anything.

**At commit time, this had zero executable coverage** — the "verified
fail-safe" claim in the commit message rested on a one-off manual run
with the cap forced to 3 in a scratch copy, not on anything in the
shipped suite. This gap was itself later closed by `62f59f6`
(B14–B17, outside this task's five-commit list but directly relevant
context — it is what surfaced the regression `ab1d952` fixes, § 4.5)
and is not re-litigated as a separate finding here since it was closed
same-day and is superseded by the working, passing B14–B17 at HEAD.

**Assessment on its own terms:** the eviction logic is correct for
what it claims (FIFO, atomic across the original three structures,
fail-safe degrade on the identity axis) — confirmed independently via
B14 (oldest-first + fail-safe degrade) and B15 (exact-boundary,
no off-by-one), both still passing at HEAD. Sharing one ledger across
all three structures was, however, the wrong shape for
`handledIdleSessions`, which answers a different question (has this
session's lifecycle gate already run) with the opposite retention
requirement — that is the defect `ab1d952` fixes (§ 4.5). **No new
findings against `1368fab` beyond what its own successor commit
already identified and fixed same-day.**

### 4.5 ab1d952 — S2, decouple handledIdleSessions eviction

**The regression it fixes.** `handledIdleSessions` — whose entire
purpose is remembering a session *after* its idle gate has already
run — was evicted on the same FIFO clock as `sessionParent`/
`sessionAgent`, which hold identity state that only matters while a
session is live. Once a `sessionID` aged off that shared 10,000-entry
clock, a *later* `session.idle` for the same `sessionID` was no longer
deduped (`handoff-stop-gate.py`/`handoff-subagent-stop-gate.py`
re-fired), and because `sessionParent` evicted at the same instant, a
re-fired *child* session's idle additionally misrouted to
`handoff-stop-gate.py` instead of `handoff-subagent-stop-gate.py`.
Reproduced by `62f59f6`'s B16/B17 before this fix existed (B17 shipped
as a `record_finding`, deliberately not a hard failure, precisely so
the open disposition question would not silently block the suite).

**The fix.** `handledIdleSessions` gets its own independent ledger
(`handledIdleInsertOrder`) and its own, much larger cap
(`HANDLED_IDLE_SESSIONS_CAP = 100_000`), evicted from the
`session.idle` handler rather than from `session.created`.
`sessionParent`/`sessionAgent` keep sharing `sessionInsertOrder` at
the original `SESSION_STATE_CAP = 10000` — they still answer the same
question (session identity) and correctly still expire together.

**Scrutiny of "the two-cap arrangement is sound" (per this task's
explicit ask).** The claim as stated in the commit message and code
comments — *"the identity maps always evict long before
`handledIdleSessions` forgets it, so a near-term duplicate
`session.idle` always finds its ID still present"* — is **true as
narrowly stated**, and this review independently confirmed it: B16 and
B17 both pass at HEAD, and reintroducing the shared-clock bug
(reverting the fix in place) reproduces the exact documented 37/39
failure (§ 6). The two-order-of-magnitude gap between the caps means a
genuine near-term duplicate `session.idle` — the seconds-apart
double-fire the ADR documents — will essentially always still find its
`sessionID` in `handledIdleInsertOrder`, since reaching that cap
requires two orders of magnitude more *distinct* sessions to have gone
idle than `sessionInsertOrder` needs to start evicting sessionParent/
sessionAgent for unrelated sessions.

**Where the claim should not be over-read.** "Sound" here is scoped
to the specific compounding failure B16/B17 were built to catch:
**repeat** `session.idle` for a session that already fired one before
eviction. It does not extend to — and the commit does not claim it
extends to — a session's **first-ever** `session.idle` arriving after
its `sessionParent` entry has already been evicted by
`SESSION_STATE_CAP` (independent of `handledIdleSessions` entirely,
since dedup only applies to a *repeat*). That base case was already
present after `1368fab` alone, is unchanged by `ab1d952`, and remains
present at HEAD — independently reproduced this pass (a single
long-lived child session, evicted by 10,000 unrelated sessions, whose
*first* `session.idle` still routes to `handoff-stop-gate.py` instead
of `handoff-subagent-stop-gate.py`). This specific instance is judged
**not** a new finding: it is the same low-severity, same-threshold,
already-named trade-off `1368fab`'s own inline reasoning anticipates
("a subsequent session.idle for it could re-run its Stop/SubagentStop
gate"), gated behind the same implausible session count, and no worse
in kind after this range than it was after `1368fab` alone.

**What this review did find that is new — finding CR-0001, § 5.**
Constructing a slightly different scenario — the same evicted, still-
live child session, but one that subsequently receives a legitimate
`session.updated` (a resume, per `c4bc456`'s own threat model) before
its first `session.idle` — surfaces a compounding path neither
`1368fab`, `c4bc456`, nor `ab1d952` analysed together, and that is not
covered by B14–B17 or any other test in the suite. See § 5 for the
full write-up and reproduction.

**Assessment:** `ab1d952`'s fix is correct and load-bearing for the
regression it targets (independently confirmed, § 6); its own framing
of what it closes is accurate and not overstated within the document
itself, though a reader skimming only the commit *title*
("decouple handledIdleSessions eviction") could reasonably assume the
whole eviction-interaction surface is now closed, which it is not.
**One new finding raised against the cumulative state at HEAD — see
§ 5, CR-0001.**

---

## 5. Findings register (this pass)

| ID | Severity | Description | Location | Status | Owner | Recommended follow-up |
|---|---|---|---|---|---|---|
| CR-OPENCODE-HOOK-BRIDGE-0001 | Low | `session.updated`'s FOLLOW handler (`hook-bridge.js`, `sessionAgent.set(sessionID, info.agent)`, ~line 926) writes `sessionAgent` directly with no interaction with `sessionInsertOrder`/`trackSessionAndEvictIfOverCap`. A session evicted by `SESSION_STATE_CAP` that later receives a legitimate `session.updated` (an operator resume, per `c4bc456`'s own threat model) has its `sessionAgent` entry silently resurrected **outside** the FIFO ledger's accounting — permanently exempting that entry from any future eviction (a narrow leak against S1's own stated purpose, since the session can never re-fire `session.created` to re-register), while `sessionParent` for the same session is never repaired (only `session.created`, which cannot re-fire, writes it). The next `session.idle` for that session — proven alive moments earlier by the very `session.updated` that refreshed its identity — still misroutes to `handoff-stop-gate.py` instead of `handoff-subagent-stop-gate.py`, with no diagnostic trace naming this specific composite path (the eviction log line and the `session.updated` log line are each individually accurate but do not warn of the interaction). Independently reproduced this pass: create a child session, evict it via 10,000 unrelated `session.created` events (`SESSION_STATE_CAP`), confirm `agent_type` absent on a guarded write (correct eviction), send `session.updated` with a new agent for the evicted `sessionID` (confirm `agent_type` now forwards again — resurrection confirmed), then send that session's first-ever `session.idle` — observed 1 call to `handoff-stop-gate.py`, 0 to `handoff-subagent-stop-gate.py`, for a session whose original `info.parentID` was set at creation. | `.opencode/plugin/hook-bridge.js:912-939` (session.updated handler); interaction with `:590-657` (`sessionInsertOrder`/`trackSessionAndEvictIfOverCap`, S1/S2) | **Open — new, this review** | `software-engineer` (fix or explicit accept), `qa-engineer` (regression test), `security-engineer` (register in the assessment's § 7/§ 8 if disposition is accept-as-residual-risk rather than fix) | Either (a) have `trackSessionAndEvictIfOverCap`-equivalent bookkeeping run from the `session.updated` handler too, so a resurrected `sessionAgent` entry re-enters the FIFO ledger, or (b) explicitly extend S1/S2's accepted-residual-risk framing in `docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md` § 8 to name this composite path by description, not just by the base case it is a variant of. Not release-blocking at LOW severity, same threshold-gating class as the already-accepted S1 risk, but should not ship un-disposed a second time. |

No Critical or High findings against the five reviewed commits. W1 and
W2 (§ 3.2) are Closed by `ac5d005`. The security assessment's H-1(b),
M-2, the session.updated HIGH finding, and S1 are Closed by
`65349ea`/`c4bc456`/`1368fab` respectively, each independently
re-verified in this pass. `ab1d952`'s own S2 fix is Closed and
load-bearing.

---

## 6. Independent verification performed

Not merely re-stating each commit's self-reported "Verified" block —
this section is what this reviewer actually ran, this session, against
the working tree at `ab1d952`:

| Check | Result |
|---|---|
| `node --check .opencode/plugin/hook-bridge.js` | OK |
| `tests/hooks/test-opencode-hook-bridge.sh` | 39 passed, 0 failed, 0 skipped, 0 findings |
| `tests/hooks/run-negative-corpus.sh --all` | 40 pass, 0 fail |
| `tests/hooks/run-negative-corpus.sh --all --harness opencode` | 40 pass, 0 fail |
| Mutation test 1: reintroduce shared-clock eviction bug (`handledIdleSessions.delete(oldest)` back inside `trackSessionAndEvictIfOverCap`) | 37 passed, 2 failed — `S2 bounded eviction: ...` and `S2 idempotency survives eviction: ...` fail exactly as `ab1d952`'s own commit message claims; file restored, `md5sum` confirmed byte-identical to pre-mutation |
| Mutation test 2: neutralise the `c4bc456` session.updated FOLLOW write (early `return` before `sessionAgent.set`) | 37 passed, 2 failed — `HIGH-severity fix: session.updated follows the agent change` and `top-level-session safety: ...` fail, and only those two; file restored, `md5sum` confirmed byte-identical |
| Reproduction: post-eviction `session.updated` resurrection then first `session.idle` (finding CR-0001) | `agent_type` absent pre-update, present post-update (`qa-engineer`); `handoff-stop-gate.py` called once, `handoff-subagent-stop-gate.py` called zero times, for a session created with a `parentID` |
| `git diff --name-only 6244214..HEAD -- scripts/hooks/` | One path, `role-routing-reminder.sh`, mode-bit only (`100644`→`100755`); no content change |
| `GUARD_CHAIN_BY_TOOL` keys vs. `tool-arg-map.json` `tools` keys at HEAD | `["write", "edit", "bash", "task"]` on both sides — consistent |
| SPDX header on `hook-bridge.js` | Present, unchanged (`SPDX-License-Identifier: MIT`) |

Both mutation tests confirm the specific tests naming these fixes are
load-bearing, not passing for the wrong reason or by coincidence —
directly responsive to this task's framing that quiet-looking passes
are the higher-risk failure mode to weight attention toward.

---

## 7. Out-of-scope commits still lacking a durable review record

Six commits in `6244214..HEAD` were not named in this task's brief and
are correspondingly not reviewed here: `725b5a6` (ADR narrative
amendment), `4dcb41a` (negative-corpus sub-gate now runs both harness
modes), `edfb485` (new hook-exec-bits sub-gate), `a7420dd`
(`security-template.md` rebuild), `62ac407` (the security assessment
itself), `62f59f6` (adds B14–B17, the S1 test-coverage closure that
surfaced the `ab1d952` regression). Strictly, Hard Rule #3 ("no commit
without `code-reviewer` review") applies to all of these too, and
`tech-lead`'s independent re-run (39/39, 40/40 both modes, five
sub-gates PASS, `compile-runtime-agents.sh --verify` clean,
`lint-canonical-sha` PASS — cited in this task's brief) covers their
*behavioural* correctness but is not itself a code review. Flagged
here rather than silently left out: recommend a follow-up dispatch
sweeps these six, particularly `4dcb41a`/`edfb485` (release-gate
logic — process-conformance-relevant per IEEE 1028 § 8) and `62f59f6`
(the test file that this review leaned on heavily for its own
independent-verification step, § 6). Not a blocking condition for
this filing's own disposition (§ 8), which is scoped to the five
commits this task named.

---

## 8. Disposition

**APPROVED WITH FINDINGS.**

The five reviewed commits (`ac5d005`, `65349ea`, `c4bc456`, `1368fab`,
`ab1d952`) each do exactly what their commit messages claim, each
closes the finding it targets without reopening or weakening any prior
fix or any contract `fw-adr-0031` pins (verdict-translation contract,
fail-open/fail-closed split, first-deny-wins ordering — all
independently re-confirmed present and passing at HEAD), and the tests
specifically covering the two highest-risk fixes in this range (W1's
agent_type forwarding, the session.updated privilege-escalation close)
were independently confirmed load-bearing by mutation, not merely
present. This is not a rubber stamp: this review is filed **with** one
new finding (CR-0001, § 5) — a genuine, independently-reproduced, LOW-
severity interaction gap between the `c4bc456` privilege-tracking fix
and the `1368fab`/`ab1d952` eviction caps that none of the five
commits' own analysis, and none of the shipped test suite, currently
covers. It is not blocking at LOW severity and the same
implausible-threshold gating the already-accepted S1 residual risk
carries, but it must be explicitly disposed (fixed, or formally
registered as residual risk) rather than left silently undocumented a
second time — which is the exact failure mode this whole filing exists
to close.

This disposition covers Hard Rule #3 for the five named commits. It
does not by itself satisfy the Hard Rule #7 security-assessment
condition that named this gap (UA-OPENCODE-HOOK-BRIDGE-0002) end to
end — that condition also named the execution-verification conditions
in the same assessment's § 11, which this review's § 6 independently
satisfies for the specific commands the assessment named
(`test-opencode-hook-bridge.sh`, `run-negative-corpus.sh` both modes),
consistent with `tech-lead`'s separately-reported independent re-run.

---

## 9. Record of review

This review record does not itself constitute a Hard Rule #7 customer
sign-off — that is `security-engineer`'s artefact
(`docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md`) plus
the `CUSTOMER_NOTES.md` entries `tech-lead` obtains. Per the intake
log (`docs/intake-log.md` in the meta-project, turns 5 and 6, both
`2026-07-25`), both residual-risk rows named in that assessment's § 8
have been put to the customer and accepted. At the time of this
filing, the meta-project's `CUSTOMER_NOTES.md` carries the turn-5
transcription (boundary-ceiling risk) but does not yet carry a
turn-6 entry (M-3) — the intake-log turn-6 record itself notes the
target anchor `CUSTOMER_NOTES.md#2026-07-25-m-3-residual-risk-accepted`,
which does not yet resolve. That transcription gap is `researcher`'s
stewardship duty (per CLAUDE.md's escalation protocol), not this
review's to close, but is flagged here since it sits on the same
Hard Rule #7 dependency chain this filing is meant to unblock.

- **This review file:** `docs/review/fw-adr-0031-opencode-hook-bridge-review.md`
- **Commits reviewed:** `6244214` (§ 3), `ac5d005`, `65349ea`,
  `c4bc456`, `1368fab`, `ab1d952` (§ 4)
- **Working tree at review time:** `ab1d952` (clean, unpushed,
  `feat/opencode-hook-bridge`)

---

## 10. References

- `docs/adr/fw-adr-0031-opencode-hook-bridge.md` — governing ADR.
- `docs/security/fw-adr-0031-opencode-hook-bridge-assessment.md` —
  Hard Rule #7 assessment; source of the UA-OPENCODE-HOOK-BRIDGE-0002
  condition this filing closes, and of the SEC-OPENCODE-HOOK-BRIDGE-*
  finding IDs cross-referenced in § 4.
- `.opencode/plugin/hook-bridge.js`, `tests/hooks/test-opencode-hook-bridge.sh`,
  `scripts/opencode/tool-arg-map.json` — read and executed directly
  for this review.
- IEEE Std 1028-2008 — Standard for Software Reviews and Audits,
  § 5 (technical review) / § 6 (inspection) shape, paraphrased.
- CLAUDE.md Hard Rule #3 (no commit without `code-reviewer` review),
  Hard Rule #7 (security sign-off for authorization-touching changes).
