# Code Review — OpenCode enforcement hook bridge (fw-adr-0031)

<!-- TOC -->

- [1. Identification](#1-identification)
- [2. Scope and method](#2-scope-and-method)
- [3. Original review record — commit 6244214](#3-original-review-record-commit-6244214)
  - [3.1 Items verified correct](#31-items-verified-correct)
  - [3.2 Findings raised](#32-findings-raised)
  - [3.3 Original ship recommendation](#33-original-ship-recommendation)
- [4. This pass — review of the five commits since](#4-this-pass-review-of-the-five-commits-since)
  - [4.1 ac5d005 — close W1/W2](#41-ac5d005-close-w1w2)
  - [4.2 65349ea — close H-1(b)/M-2](#42-65349ea-close-h-1bm-2)
  - [4.3 c4bc456 — close the session.updated privilege escalation](#43-c4bc456-close-the-sessionupdated-privilege-escalation)
  - [4.4 1368fab — S1 bounded eviction](#44-1368fab-s1-bounded-eviction)
  - [4.5 ab1d952 — S2, decouple handledIdleSessions eviction](#45-ab1d952-s2-decouple-handledidlesessions-eviction)
- [5. Findings register (this pass)](#5-findings-register-this-pass)
- [6. Independent verification performed](#6-independent-verification-performed)
- [7. Out-of-scope commits still lacking a durable review record](#7-out-of-scope-commits-still-lacking-a-durable-review-record)
- [8. Disposition](#8-disposition)
- [9. Record of review](#9-record-of-review)
- [10. This pass — review of four commits since `ab1d952`](#10-this-pass-review-of-four-commits-since-ab1d952)
  - [10.1 `4dcb41a` — negative-corpus sub-gate now runs both harness modes](#101-4dcb41a-negative-corpus-sub-gate-now-runs-both-harness-modes)
  - [10.2 `edfb485` — new `hook-exec-bits` sub-gate](#102-edfb485-new-hook-exec-bits-sub-gate)
  - [10.3 `62f59f6` — B14-B17 and the `record_finding()` bucket](#103-62f59f6-b14-b17-and-the-record_finding-bucket)
  - [10.4 `f054c90` — route `session.updated` through the ledger, repair `sessionParent`](#104-f054c90-route-sessionupdated-through-the-ledger-repair-sessionparent)
- [11. Findings register (this pass)](#11-findings-register-this-pass)
- [12. Independent verification performed (this pass)](#12-independent-verification-performed-this-pass)
- [13. Addendum (dated 2026-07-25, this pass) — correction to § 9](#13-addendum-dated-2026-07-25-this-pass-correction-to-9)
- [14. Disposition (this pass)](#14-disposition-this-pass)
- [15. References](#15-references)

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

**Update (this pass, § 10).** `4dcb41a`, `edfb485`, and `62f59f6` are now reviewed in § 10.1-§ 10.3, along with `f054c90` (landed after this document's first filing). `725b5a6`, `a7420dd`, and `62ac407` remain intentionally out of scope as prose/ADR artefacts, not code — see § 14 for the updated disposition.

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

## 10. This pass — review of four commits since `ab1d952`

Trigger: same as § 1 — Hard Rule #3, extended to the four commits in
`6244214..HEAD` that were named-but-not-reviewed in § 7 of the prior
filing (`4dcb41a`, `edfb485`, `62f59f6`) plus `f054c90`, which landed
after this document's own first filing (`16f1475`) and fixes this
document's own § 5 finding CR-OPENCODE-HOOK-BRIDGE-0001. `725b5a6`
(ADR narrative), `a7420dd` (security-template rebuild), and `62ac407`
(the security assessment itself) remain out of this reviewer's scope —
prose/ADR artefacts, not code.

**Method.** Same as § 2: full read of each diff against its own commit
message, independent execution (not trust) of every claim that could be
checked, and mutation testing (introduce the regression the fix targets,
confirm the *specific* tests named as load-bearing fail and only those,
restore, confirm `md5sum` byte-identical) on every commit whose message
asserted a test was load-bearing. Working tree at review time: `f054c90`
(clean, unpushed, `feat/opencode-hook-bridge`).

### 10.1 `4dcb41a` — negative-corpus sub-gate now runs both harness modes

**Claim.** `scripts/lib/gate-hook-negative-corpus.sh` previously invoked
the driver as `--all` only; the OpenCode round-trip mode (`--all
--harness opencode`) was untested by the release gate. The fix runs
both modes unconditionally, accumulates a failure counter, and names
which mode failed.

**Verified.** Read `scripts/lib/gate-hook-negative-corpus.sh` in full at
HEAD (74 lines) — matches the commit message exactly: `failures=0`,
two `if ! "$driver" ...; then failures=$((failures+1)); fi` blocks with
no short-circuit between them, `[ "$failures" -gt 0 ]` at the end.
Traced the masking question against `gate_run_one` in
`scripts/lib/gate-runner.sh:65-91`: each sub-gate runs inside `(
"gate_subgate_${name}" )`, a fresh subshell per invocation, so the
unqualified (non-`local`) `failures`/`driver` globals inside
`gate_subgate_hook-negative-corpus` cannot leak into or collide with
any other sub-gate's own globals across the sequential dispatch loop —
not a defect.

Independently reproduced, not just read: sourced the function in
isolation against two stub drivers (one failing only in
`--harness opencode` mode, one failing only in plain `--all` mode).
Both orders confirmed: neither invocation's result masks the other's,
both failure labels are attributed to the mode that actually failed
(not a static/decorative string — verified by making each mode fail
independently and checking the label printed matches), and the
sub-gate's own exit code is `1` in both cases, `0` only when both stub
invocations pass. Re-ran the real driver at HEAD in both modes
directly (not through the gate): `run-negative-corpus.sh --all` → 40
pass/0 fail; `run-negative-corpus.sh --all --harness opencode` → 40
pass/0 fail; `pre-release-gate.sh --only hook-negative-corpus` → PASS.

**Gap found (not a defect in the logic itself).** Neither
`tests/release-gate/test-gate-fail-each.sh` (the project's own
per-sub-gate "deliberately break it, assert it surfaces in the failing
list" regression harness) nor any other persisted test exercises this
sub-gate's dual-mode/attribution behaviour. The only verification on
record is the commit message's own manual stub run, which this review
independently reproduced (above) but which is not wired to run again
automatically. See CR-OPENCODE-HOOK-BRIDGE-0005, § 11 — this gap is
shared with `edfb485` and is part of a wider, pre-existing pattern
(`mirror-current`, `version-stamp`, and `opencode-hook-parity` are
likewise absent from that harness), not a regression newly introduced
by this commit specifically.

**Assessment: no findings against the logic itself.** The
masking/attribution behaviour is correct and independently confirmed,
not merely asserted. **One shared coverage-gap finding raised, § 11.**

### 10.2 `edfb485` — new `hook-exec-bits` sub-gate

**Claim.** New `scripts/verify-hook-executable-bits.sh` (registered via
`scripts/lib/gate-hook-exec-bits.sh`) parses `.claude/settings.json` for
every `[ -x "${CLAUDE_PROJECT_DIR:-.}/<path>" ]`-guarded hook reference
and asserts each named script is present and executable — closing the
class of bug the `role-routing-reminder.sh` incident (`725b5a6`)
exposed: a hook committed non-executable under that guard idiom fails
the `-x` test, short-circuits, and `|| true` returns 0, indistinguishable
from "ran and had nothing to say."

**Verified as documented.** `git show HEAD:.claude/settings.json` — all
four `[ -x ... ]`-guarded hooks
(`version-check.sh`, `atomic-question-reminder.sh`,
`role-routing-reminder.sh`, `post-compact-refresh.sh`) use the exact
literal idiom the driver's `GUARD_RE`
(`scripts/verify-hook-executable-bits.sh:106-108`) matches. Re-ran the
driver standalone and via the gate: both PASS, `4` guarded scripts
found. The "refuse to pass trivially on zero guarded refs found" guard
(`:129-138`) is present and sound as a defense against the parser
itself silently breaking. The stated scope decision — excluding the
unconditional `python3 "<path>"` hooks, since those fail loudly on
their own — is documented both in the commit message and inline
(`scripts/verify-hook-executable-bits.sh:14-19`); **that decision is
correctly reasoned and adequately documented.**

**Finding — the parser's own blind spot reproduces the exact incident
class it exists to prevent (per this task's explicit ask: "can a
differently-formatted-but-equivalent wiring slip past it?").**
`GUARD_RE` is a literal-string match on one specific spelling of the
guard idiom. Independently reproduced: constructed a settings file with
one hook wired via the shipped `[ -x ... ]` form (present, executable)
and a second, deliberately non-existent/non-executable hook wired via
the POSIX-equivalent `test -x "<path>" && "<path>" ... || true` idiom —
semantically identical, a completely ordinary sh alternative to `[
-x ]`. The driver reported **PASS**, naming only the one hook it
matched, with no error, warning, or count mismatch flagging that a
second guarded reference existed and was skipped. This is not a
contrived edge case: `test -x` and `[ -x` are interchangeable POSIX
idioms and a future hook author copying an existing OpenCode-adjacent
script, a different internal convention, or even reflowed
whitespace/quoting could reintroduce the silent-no-op class this gate
was built specifically to catch, and the gate would say PASS. See
CR-OPENCODE-HOOK-BRIDGE-0003, § 11.

**Secondary, lower-severity finding.** Malformed `.claude/settings.json`
(reproduced: a syntactically broken JSON file) produces an uncaught
Python `JSONDecodeError` traceback on stderr and exit code `1` —
colliding with the script's own documented exit code `1` ("violations
found") rather than the documented exit code `2` ("usage / environment
error", `scripts/verify-hook-executable-bits.sh:28-31`). Fails closed
(the safe direction — the gate still FAILs), so not release-blocking,
but the diagnostic is not the operator-facing message the rest of the
script is careful to provide, and it violates the script's own
documented exit-code contract. See CR-OPENCODE-HOOK-BRIDGE-0004, § 11.

**Assessment: APPROVED WITH FINDINGS.** The sub-gate does what it
claims for the wiring that exists today, and the scope decision is
sound and documented. The parser's fragility to differently-phrased
guard idioms is a real, reproduced gap in a piece of meta-tooling whose
entire purpose is catching exactly this failure shape.

### 10.3 `62f59f6` — B14-B17 and the `record_finding()` bucket

**Claim.** Adds four scenarios (B14-B17) exercising `1368fab`'s
`SESSION_STATE_CAP` FIFO eviction against the real cap (10,000), which
had zero executable coverage before this commit. B17 is filed via a new
`record_finding()` bucket — printed loudly, kept separate from
pass/fail, does not flip the suite's exit code — because it reproduces
a genuine, then-undisposed regression (`handledIdleSessions` evicting
on the same clock as the identity maps) rather than asserting a
property. B15 is explicitly self-labelled as "not load-bearing for S1's
existence."

**Independently verified, not trusted.** Ran the full suite at HEAD:
40 passed, 0 failed, 0 findings (B17 has since flipped to a plain pass —
`ab1d952` fixed the regression it reported, consistent with the prior
filing's § 4.5). Mutation-tested this task's two explicit questions
directly, rather than accepting the commit message's self-report:

- **Neutralised `trackSessionAndEvictIfOverCap` entirely** (eviction
  disabled process-wide, emulating pre-`1368fab` behaviour) and re-ran
  the suite. Result: B14 (`S1 bounded eviction: FIFO oldest-first +
  fail-safe degrade`) **fails**, the S2/B16 atomicity test **fails**,
  B18 (`f054c90`'s own test, § 10.4) **fails** — all three require an
  eviction to actually occur. B15 (`S1 bounded eviction: exactly
  SESSION_STATE_CAP ... no eviction logged`) **still passes** — trivially
  true whether or not eviction exists at all, since "no eviction at
  exactly the cap boundary" holds vacuously when nothing ever evicts.
  **The author's self-assessment is accurate**: B15 is an off-by-one
  guard that only earns its keep once the cap exists, not proof the cap
  exists. File restored via `git show HEAD:... >
  .opencode/plugin/hook-bridge.js` immediately after; `md5sum`
  confirmed byte-identical before/after both this and every other
  mutation in this pass.
- **B14 and B16 are genuinely load-bearing**, not passing by
  coincidence — confirmed by the same mutation: both fail specifically
  and only when the mechanism they claim to cover (FIFO eviction
  existing at all; the two identity maps evicting together) is removed.

**Finding — `record_finding()`'s design is defensible in isolation, but
its safety net does not currently exist.** The bucket's own reasoning
("disposition belongs to tech-lead / security-engineer, not to a test
file") is sound, and folding an open policy question into a hard `exit
1` would be the wrong call. But `tests/hooks/test-opencode-hook-bridge.sh`
is not registered in `scripts/lib/gate-runner.sh` and is not invoked by
any workflow under `.github/workflows/` (independently confirmed —
`grep -rl test-opencode-hook-bridge .github/workflows/` returns nothing).
`edfb485`'s own commit message discloses this as an open question
("Worth deciding explicitly") rather than an oversight, which is to its
credit, but the risk is not hypothetical: B17's finding was a *real*,
same-branch regression that was caught only because a human happened to
run this exact suite by hand and read the output; nothing would have
surfaced it otherwise. "Prints loudly" currently means "prints loudly
to whoever happens to invoke this one file directly." See
CR-OPENCODE-HOOK-BRIDGE-0006, § 11.

**Assessment: APPROVED WITH FINDINGS.** B14-B17 close a real,
previously-unverified coverage gap, the load-bearing and
not-load-bearing self-assessments are both independently confirmed
accurate, and `record_finding()`'s separation-of-concerns design is
sound. The gap is that nothing currently makes a finding visible
outside a manual run of this one file.

### 10.4 `f054c90` — route `session.updated` through the ledger, repair `sessionParent`

The fix for this document's own CR-OPENCODE-HOOK-BRIDGE-0001, and the
newest code in the branch. Reviewed hardest, per this task's brief.

**The fix, read against the finding it closes.** Two sub-fixes in the
`session.updated` handler
(`.opencode/plugin/hook-bridge.js:1002-1032`), both run unconditionally
before the pre-existing `if (!info.agent) return;` early-out:

1. `trackSessionAndEvictIfOverCap(sessionID)` (line 1002) — the SAME
   function `session.created` calls (line 867), not a parallel
   reimplementation. Re-entry into `sessionInsertOrder` for an
   evicted-then-resumed sessionID is exactly what CR-0001 asked for:
   no permanent carve-out from the cap's accounting.
2. `sessionParent` repair, write-only-when-absent
   (`:1005-1019`) with retain-and-log on a later mismatch
   (`:1020-1032`) — the same first-write-wins shape `session.created`
   uses (`:886-900`), sourced from a second event type.

**Interaction check 1 — does the ledger call interact correctly with
the `has()`-guard and with `HANDLED_IDLE_SESSIONS_CAP`'s separate
ledger?** Read `trackSessionAndEvictIfOverCap`
(`.opencode/plugin/hook-bridge.js:680-701`): it touches only
`sessionInsertOrder`/`sessionParent`/`sessionAgent`; it never reads or
writes `handledIdleSessions`/`handledIdleInsertOrder`
(`HANDLED_IDLE_SESSIONS_CAP`'s own ledger, `:664-669`), which is
touched exclusively by `trackHandledIdleAndEvictIfOverCap` from the
`session.idle` handler. Calling `trackSessionAndEvictIfOverCap` a
second time (from `session.updated`, in addition to `session.created`)
does not reach into the other cap's bookkeeping in any way — the two
caps stay structurally independent, exactly as `ab1d952`'s S2 fix
intended. The `has()`-guard (`sessionInsertOrder.has(sessionID)
return;`, line 681) makes the call a true no-op for the overwhelming
common case (an already-tracked, non-evicted session receiving a
routine `session.updated`) — confirmed by reading, not just asserted:
for such a session, `sessionInsertOrder.has(sessionID)` is `true`, so
the function returns on its first line with zero further work, exactly
as the commit's own inline reasoning claims (`:671-679`).

**Interaction check 2 — does repairing `sessionParent` from a second
event source create an ordering hazard with `session.created`'s
first-write-wins path?** Both writers gate on the same predicate shape
(`if (!sessionParent.has(sessionID))`), and `HookBridge`'s event
handler is a single synchronous callback per event (`await`s inside it
are for subprocess I/O, not concurrent event dispatch) — there is no
interleaving within one event's handling, and OpenCode is not shown
anywhere in this bridge's design to dispatch two events for the same
plugin instance concurrently. Whichever of `session.created` /
`session.updated` fires first for a given sessionID wins the write; the
second one to arrive finds `sessionParent.has(sessionID)` already
`true` and takes the retain-and-log branch. No race, no double-write,
no ordering-dependent divergent outcome — confirmed by reading both
write sites (`:886-900`, `:1004-1032`), which are structurally
identical modulo which map (`sessionParent` only, vs. `sessionParent`
+ `sessionAgent`) each event type writes.

**`c4bc456`'s privilege-escalation guarantee, re-checked, not assumed
intact.** The `sessionAgent` FOLLOW write itself
(`:1042-1058`) is unchanged by this diff — confirmed by diff read, not
inference: `git show f054c90 -- .opencode/plugin/hook-bridge.js` shows
only additions before and around it, no modified lines inside the
FOLLOW block. `sessionParent` affects only Stop-vs-SubagentStop
routing, never `agent_type`/the guard's write-bypass decision — verified
by reading every read site of `sessionParent` in the file (one: the
`session.idle` handler's `parentID = sessionParent.get(sessionID)` at
`:1073`, feeding only the gate-name choice, never a guard payload).
B12/B13 (the tests that specifically pin the FOLLOW fix) re-ran green.

**Mutation-tested both sub-fixes independently, not trusted from the
commit message.** Two separate mutations, each restored and confirmed
`md5sum`-identical before continuing:
1. Disabled the `trackSessionAndEvictIfOverCap(sessionID)` call alone.
   Result: **exactly one test fails** — B18 — with
   `total_evictions=1, resurrection_eviction=0` (the resurrection never
   re-enters the ledger). Matches the commit message's claim exactly.
2. Disabled the `sessionParent` repair write alone (left ledger
   accounting intact). Result: **exactly one test fails** — B18 — with
   `main_gate_calls=1, subagent_gate_calls=0, repaired_parent=0` (the
   reviewer's exact original misroute, reproduced on demand). Matches
   the commit message's claim exactly.

Both confirm B18 is load-bearing for BOTH halves of the fix
independently, not merely present.

**Does B18's ~10,005-step scenario actually assert what it claims?**
Traced its own internal accounting claim (`total_evictions=2`,
`resurrection_eviction=1` naming `s18-filler-0` specifically) against
`trackSessionAndEvictIfOverCap`'s eviction arithmetic by hand: 1
victim + 10,000 fillers = 10,001 distinct sessionIDs tracked by the end
of the fill loop, one over `SESSION_STATE_CAP` (10,000) — the FIRST
eviction (of `s18-victim`, the oldest) fires exactly once, during the
last filler's `session.created`. The subsequent `session.updated`
resurrection re-adds `s18-victim`, pushing the ledger to 10,001 again,
triggering a SECOND eviction of whatever is now oldest —
`s18-filler-0`, the first filler, since `s18-victim` is no longer in
the set to be re-evicted. This is not inferred from the test's own
assertions; it was independently re-derived from the eviction
function's own FIFO logic and matches what the test checks for. This
is a materially stronger proof of ledger re-entry than checking
"agent_type resurrected" alone would be (a resurrection could
conceivably happen through some path that never touches the ledger at
all, and a naive test would not catch that) — **the test earns the
"not merely inferred" claim its own comment makes.** No coincidental-pass
mechanism found: both mutation tests above independently confirm each
half of the assertion block is necessary, and the hand-derived eviction
arithmetic confirms the expected counts are not a copy-paste
placeholder.

**New finding, this pass — an adjacent gap B18 does not cover and is
not claimed to cover.** Constructing a related-but-distinct scenario
per this task's instruction to weight interactions: a session that
already had **one** `session.idle` processed (so
`handledIdleSessions` already contains its sessionID), which is later
legitimately resumed via `session.updated` (exactly the threat model
`c4bc456`, and this commit, both target), and then goes idle a
**second** time — a genuinely new turn ending, not a spurious
near-simultaneous double-fire, per the ADR's own framing that
`session.idle` is a per-turn "Stop-equivalent," not a
once-per-session-lifetime event (the bridge's own comment says so
verbatim: `.opencode/plugin/hook-bridge.js:541-544`, "not 'this session
will never be touched again'"). Independently reproduced (steps:
`session.created` → `session.idle` → `session.updated` with a new
agent → `session.idle` again, all for the same sessionID, no eviction
needed): the SECOND `session.idle` is silently swallowed —
`handoff-subagent-stop-gate.py` is called exactly once total, not
twice, and neither gate fires for the second idle event. No log line
distinguishes this from a correctly-deduped spurious double-fire; it is
indistinguishable from success from the outside. Re-ran the identical
steps against `ab1d952` (pre-`f054c90`) in a separate worktree: **same
result** — this is confirmed pre-existing, not introduced by `f054c90`,
and is a property of `handledIdleSessions`'s permanent (until the
100,000-entry `HANDLED_IDLE_SESSIONS_CAP` evicts it) membership rather
than anything this commit changes. It is flagged here rather than
silently omitted because it sits directly adjacent to, and is not
covered by, either B18 or the resumption-support design intent this
whole commit cluster (`c4bc456`, `1368fab`, `ab1d952`, `f054c90`)
exists to enable — a resumed session's *first* post-resume idle is now
provably correctly routed (B18); its *second* is silently dropped, and
nothing in the suite says so. See CR-OPENCODE-HOOK-BRIDGE-0002, § 11.

**Assessment: the fix is correct, closes CR-0001 completely (both
sub-halves independently confirmed load-bearing, no coincidental
pass), and does not reopen or weaken `c4bc456`'s privilege-escalation
guarantee.** **One new finding raised against the cumulative state at
HEAD** — an adjacent, pre-existing, previously-undocumented gap
surfaced by scrutinizing the same interaction space this fix lives in,
not a defect in the fix itself.

---

## 11. Findings register (this pass)

| ID | Severity | Description | Location | Status | Owner | Recommended follow-up |
|---|---|---|---|---|---|---|
| CR-OPENCODE-HOOK-BRIDGE-0002 | Medium | `handledIdleSessions` marks a sessionID as permanently handled the first time its `session.idle` fires (barring 100,000-entry-scale eviction). `session.idle` is documented in this bridge's own comments as a per-turn "Stop-equivalent," not a once-per-session-lifetime signal — so a session that goes idle once, is later legitimately resumed via `session.updated` (the exact scenario `c4bc456`/`1368fab`/`ab1d952`/`f054c90` collectively exist to support), and then goes idle again for a genuinely new turn has that second, legitimate lifecycle event silently dropped: neither `handoff-stop-gate.py` nor `handoff-subagent-stop-gate.py` runs, and no log line distinguishes this from a correctly-deduped spurious double-fire. Independently reproduced (§ 10.4) and confirmed pre-existing at `ab1d952` (not introduced by `f054c90`), but directly adjacent to, and uncovered by, `f054c90`'s own B18 test and this fix cluster's stated design intent to support session resumption. | `.opencode/plugin/hook-bridge.js:1062-1078` (session.idle handler, `handledIdleSessions.has()` dedup at `:1065`); interacts with `:515-527` (declaration), `:634-669` (S2's independent, larger cap) | **Open — new, this pass** | `software-engineer` (fix or explicit accept), `qa-engineer` (regression test if fixed), `security-engineer` (register in the assessment's residual-risk framing if disposition is accept) | Either (a) scope `handledIdleSessions`'s dedup to a single turn rather than a session's whole lifetime — e.g. clear (not just evict) a sessionID's entry when a `session.updated` resume is observed for it, so a legitimately new turn is not silently treated as a duplicate of an old one, or (b) explicitly extend the residual-risk framing to name this composite path (not just the base double-fire case the dedup was built for). Not release-blocking at Medium/session-count-and-resume-gated severity, but should be disposed rather than left implicit a second time. |
| CR-OPENCODE-HOOK-BRIDGE-0003 | Medium | `scripts/verify-hook-executable-bits.sh`'s `GUARD_RE` matches only the literal `[ -x "${CLAUDE_PROJECT_DIR:-.}/<path>" ]` spelling of the exec-bit guard idiom. A semantically-identical, equally-idiomatic POSIX alternative (`test -x "<path>" && "<path>" ... \|\| true`) is invisible to it: independently reproduced with a settings file mixing one correctly-matched hook and one `test -x`-guarded, deliberately-missing/non-executable hook — the driver reported PASS, naming only the matched entry, with no warning that a second guarded reference existed and was skipped. This reproduces, inside the gate built specifically to prevent it, the same "non-executable/missing hook is indistinguishable from a hook that ran and had nothing to say" failure class the `role-routing-reminder.sh` incident this gate exists to catch. | `scripts/verify-hook-executable-bits.sh:106-108` (`GUARD_RE`) | **Open — new, this pass** | `software-engineer` (broaden detection or add a self-check) | Either broaden the regex to cover common equivalent forms (`test -x`, `[[ -x ]]`), or invert the approach: enumerate every script path referenced anywhere under `scripts/hooks/`-adjacent command strings in `hooks{}` and cross-check which the strict regex did *not* capture, failing loudly on any command string containing a `-x`-shaped test the regex didn't match (a canary against the parser itself silently falling out of sync with the idiom in use), rather than silently omitting anything it doesn't recognize. |
| CR-OPENCODE-HOOK-BRIDGE-0004 | Low | `scripts/verify-hook-executable-bits.sh` has no `try`/`except` around `json.load()` (`:101`). A malformed `.claude/settings.json` produces an uncaught Python traceback on stderr and exit code `1` — colliding with the script's own documented meaning of exit `1` ("violations found") rather than the documented exit `2` ("usage / environment error", per the script's own header comment `:28-31`). Fails closed (safe direction; the gate still FAILs), so not release-blocking, but the diagnostic is not the operator-facing message the rest of the script is careful to provide, and it violates its own documented exit-code contract. | `scripts/verify-hook-executable-bits.sh:96-101` | **Open — new, this pass** | `software-engineer` | Wrap the `json.load()` call in a `try`/`except json.JSONDecodeError`, print an operator-facing message naming the settings path and the parse error, and exit `2` per the script's own documented contract. |
| CR-OPENCODE-HOOK-BRIDGE-0005 | Low | Neither `4dcb41a`'s dual-mode negative-corpus attribution logic nor `edfb485`'s `hook-exec-bits` sub-gate has a persisted regression test in `tests/release-gate/test-gate-fail-each.sh` (the project's own "deliberately break one sub-gate, assert it surfaces in the failing list" harness, which already covers `worktree-clean`, `check-spdx`, `lint-contracts`, `advisory-pointers`, `upgrade-paths`, `readme-current`, `migrations-standalone`). Verification for both currently rests solely on the manual stub/mutation runs recorded in each commit's own message — independently reproduced accurate by this review (§ 10.1, § 10.2) — not on anything that re-runs automatically. Consistent with a pre-existing gap shared by `mirror-current`, `version-stamp`, and `opencode-hook-parity` (also absent from that harness), so not a novel regression uniquely introduced by these two commits, but a real, unaddressed gap on process-conformance-relevant logic (IEEE 1028 § 8: process/tooling conformance is itself an auditable surface). | `scripts/lib/gate-hook-negative-corpus.sh`, `scripts/lib/gate-hook-exec-bits.sh`, `scripts/verify-hook-executable-bits.sh`; absent from `tests/release-gate/test-gate-fail-each.sh` | **Open — new, this pass (shared, pre-existing pattern)** | `qa-engineer` | Add one fixture row per sub-gate to `test-gate-fail-each.sh` (or an equivalent dedicated harness for the `tests/hooks/*` family) — a low-cost, mechanical addition given the manual mutation procedure already exists in each commit message as a ready-made template. |
| CR-OPENCODE-HOOK-BRIDGE-0006 | Medium | `record_finding()` (`62f59f6`)'s separation from pass/fail is a sound design in isolation (a test file should not unilaterally decide a disposition question), but its "prints loudly" safety net is currently backed by zero automated invocation: `tests/hooks/test-opencode-hook-bridge.sh` is registered in neither `scripts/lib/gate-runner.sh` nor any `.github/workflows/*.yml` (independently confirmed by search). `edfb485`'s own commit message discloses this as an open, undecided policy question rather than an oversight — but the risk already materialized once on this same branch: B17's finding (the S1/S2 `handledIdleSessions` regression) was a genuine, undisposed defect that was caught only because a human happened to run this one file by hand and read its output; nothing in CI or the release gate would have surfaced it. | `tests/hooks/test-opencode-hook-bridge.sh:74-92` (`record_finding`); cross-ref `scripts/lib/gate-runner.sh` (no registration), `.github/workflows/*.yml` (no invocation) | **Open — escalating an already-disclosed open question, this pass** | `tech-lead` (disposition owner per `edfb485`'s own framing), `release-engineer` (gate registration if the disposition is "wire it in") | Resolve the open question `edfb485` raised, rather than deferring it further. A registration that preserves `record_finding()`'s own principle (a test file should not decide disposition) while still preventing an un-triaged finding from shipping silently: gate on `findings == 0` (or `fail == 0`) without folding the *substance* of an open finding into a hard pass/fail assertion. |

No Critical or High findings against the four reviewed commits. Every
prior contract this document's earlier passes verified (verdict
translation, fail-open/fail-closed split, first-deny-wins ordering,
the `session.created`/`session.updated` RETAIN/FOLLOW asymmetry,
`scripts/hooks/` untouched) remains intact — independently re-confirmed
in § 12, not merely carried forward by assumption.

---

## 12. Independent verification performed (this pass)

| Check | Result |
|---|---|
| `node --check .opencode/plugin/hook-bridge.js` | OK |
| `tests/hooks/test-opencode-hook-bridge.sh` | 40 passed, 0 failed, 0 skipped, 0 findings |
| `tests/hooks/run-negative-corpus.sh --all` | 40 pass, 0 fail |
| `tests/hooks/run-negative-corpus.sh --all --harness opencode` | 40 pass, 0 fail |
| `scripts/pre-release-gate.sh --only hook-negative-corpus` | PASS |
| `scripts/pre-release-gate.sh --only hook-exec-bits` | PASS |
| `scripts/verify-hook-executable-bits.sh` (standalone) | PASS — 4 guarded scripts found |
| Stub test: `gate-hook-negative-corpus.sh` dual-mode masking, opencode-only failure | Correctly attributed, exit 1, claude-mode label absent |
| Stub test: `gate-hook-negative-corpus.sh` dual-mode masking, claude-only failure | Correctly attributed, exit 1, opencode-mode label absent |
| Repro: `test -x`-guarded, nonexistent/non-executable hook vs. shipped `[ -x ]` regex | Driver reports PASS, second hook silently uncounted (CR-0003) |
| Repro: malformed `.claude/settings.json` | Uncaught `JSONDecodeError` traceback, exit 1 (CR-0004) |
| Mutation: disable `trackSessionAndEvictIfOverCap()` entirely (pre-1368fab emulation) | B14 fails, S2/B16 fails, B18 fails, B15 still passes (author's "not load-bearing" self-assessment confirmed); `md5sum` byte-identical after restore |
| Mutation: disable `f054c90`'s ledger-accounting call in `session.updated` only | Exactly B18 fails, `total_evictions=1 resurrection_eviction=0`; `md5sum` byte-identical after restore |
| Mutation: disable `f054c90`'s `sessionParent` repair write only | Exactly B18 fails, `main_gate_calls=1 subagent_gate_calls=0 repaired_parent=0` (reviewer's original misroute reproduced); `md5sum` byte-identical after restore |
| Repro: second `session.idle` after a `session.updated` resume, no eviction involved | Second idle silently swallowed (CR-0002); identical result reproduced against `ab1d952` in a separate worktree — confirmed pre-existing, not introduced by `f054c90` |
| `git diff --name-only 16f1475..HEAD -- scripts/hooks/` | Empty — `scripts/hooks/` untouched since the prior filing |

Every mutation was restored via `git show HEAD:<path> > <path>`
(never `git checkout --`/`git restore --`, both blocked by
`.claude/settings.json`'s deny list for this session) and confirmed
`md5sum`-identical to the pre-mutation file before proceeding to the
next check.

---

## 13. Addendum (dated 2026-07-25, this pass) — correction to § 9

Filed against a finding from the concurrent docs-focused `code-reviewer`
pass on this same branch: **CR-OPENCODE-HOOK-BRIDGE-0100 (Minor)**,
"stale claim in § 9 'Record of review'."

**What § 9 said, as filed in `16f1475`.** § 9 asserted that, at filing
time, the meta-project's `CUSTOMER_NOTES.md` carried the turn-5
boundary-ceiling transcription but "does not yet carry a turn-6 entry
(M-3)," and that the anchor
`CUSTOMER_NOTES.md#2026-07-25-m-3-residual-risk-accepted` "does not yet
resolve."

**What was actually true at that moment.** It did not. The meta-project's
`CUSTOMER_NOTES.md` already carried the filled turn-6 M-3 acceptance
entry ("## 2026-07-25 — M-3 residual risk accepted (turn: 6)") — added
by meta-project commit `26b15b2` ("docs(records): customer accepts the
M-3 residual risk"), committed 2026-07-25 12:26:07+02:00 — **seven
minutes before** `16f1475` was committed at 12:33:27+02:00. Both
anchors (`#2026-07-25-boundary-ceiling-residual-risk-accepted` and
`#2026-07-25-m-3-residual-risk-accepted`) resolve to populated entries;
neither is missing.

**Why this addendum, not a silent edit.** Per this task's own
instruction and the general principle this document exists to
demonstrate (a durable review record's value is partly in showing what
was believed and verified at the time it was filed): the original § 9
text above is left as written, not rewritten, so the record continues
to show the state the reviewing session actually observed.

**Cause, recorded because it is a process observation, not a typo.**
The `16f1475` reviewing session ran inside the scaffold repository
(`sw-dev-team-template`) and read `CUSTOMER_NOTES.md` from its working
context at whatever point in that session it happened to check —
before the meta-project's `26b15b2` commit reached whatever copy of
`CUSTOMER_NOTES.md` that session could see, even though `26b15b2`
predates `16f1475` by wall-clock time. Concretely: a review that cites
state living in a *different* repository than the one under review is
citing a moving target — the citation is a snapshot of a read that
happened at some point during the review, not of the commit's own
timestamp, and the two repositories' commit clocks are not
synchronized by anything this reviewer's tooling enforces. **Any future
review that cites cross-repo state (meta-project artefacts cited from
inside the scaffold, or vice versa) should re-verify that citation at
filing time — immediately before the commit that files the review —
rather than trusting an earlier read from mid-session,** since the
cited repository can change under the reviewing session without any
signal reaching it.

**Scope of this correction.** This addendum corrects only § 9's
cross-repo status claim. It does not reopen, soften, or restate
`CR-OPENCODE-HOOK-BRIDGE-0001` — that finding stands exactly as filed
in § 5 and was independently re-confirmed accurate by the concurrent
docs-focused review, including its test-count claims. It also does not
change this document's Hard Rule #7 posture: § 9's own final sentence
already correctly named the durable-code-review-record condition
(satisfied by `16f1475`'s own filing) as the one still-outstanding
condition at that time, independent of the M-3 transcription question.

---

## 14. Disposition (this pass)

**APPROVED WITH FINDINGS.**

All four commits (`4dcb41a`, `edfb485`, `62f59f6`, `f054c90`) do what
their commit messages claim. Every claim checkable by independent
execution or mutation was independently executed or mutation-tested in
this pass, not accepted on the commit message's word — including two
explicit self-assessments this task asked to be scrutinised (B15 "not
load-bearing," `edfb485`'s exec-bits scoping decision), both confirmed
accurate, and `f054c90`'s two-sub-fix repair, both halves independently
confirmed load-bearing with no coincidental-pass mechanism found. No
prior contract this document has verified across either pass (verdict
translation, fail-open/fail-closed, first-deny-wins ordering, the
RETAIN/FOLLOW asymmetry, `scripts/hooks/` untouched) is weakened or
reopened by any of the four.

This is not a rubber stamp: five new findings are filed (§ 11). None
are Critical or High. Two (CR-0002, CR-0003) are Medium and worth
timely disposition rather than indefinite deferral — CR-0003 in
particular because it reproduces, inside meta-tooling built specifically
to prevent it, the exact silent-no-op failure class that tooling exists
to catch. CR-0006 escalates a risk `edfb485` already disclosed as an
open question, backed by a concrete same-branch example (B17) of that
risk having already occurred. None are release-blocking at their
current severity and none touch the bridge's core enforcement
guarantees (verdict correctness, privilege-forwarding correctness,
fail-closed posture) — all five sit in the gate/test-coverage and
lifecycle-dedup periphery this whole document's pattern (§ "Standing
context," and every prior finding in this file) has consistently
flagged as the higher-risk shape: defects that look like success until
someone goes looking for the specific interaction.

This disposition covers Hard Rule #3 for these four commits, closing
the last of the six commits named-but-unreviewed in the prior filing's
§ 7 (`725b5a6`, `a7420dd`, `62ac407` remain intentionally out of scope
as prose/ADR artefacts, not code). Combined with the prior filing's § 8,
every code commit in `6244214..HEAD` now has a durable `code-reviewer`
record.

---

## 15. References

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
