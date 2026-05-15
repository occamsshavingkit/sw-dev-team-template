---
name: fw-adr-0012-tech-lead-authoring-guard
description: PreToolUse allow-list hook is the primary preventive enforcement for Hard Rule 8; supersedes FW-ADR-0011's primary-enforcement framing.
status: accepted
date: 2026-05-14
---


# FW-ADR-0012 — PreToolUse authoring guard for Hard Rule #8

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: keep ADR-0011 + raise the SessionStart banner](#option-m--minimalist-keep-adr-0011--raise-the-sessionstart-banner)
  - [Option S — Scalable: PreToolUse allow-list hook (primary preventive) + trailer / lint downgraded to audit](#option-s--scalable-pretooluse-allow-list-hook-primary-preventive--trailer--lint-downgraded-to-audit)
  - [Option C — Creative: chroot the main session to an orchestration workspace](#option-c--creative-chroot-the-main-session-to-an-orchestration-workspace)
- [Decision outcome](#decision-outcome)
  - [Three-pronged enforcement (restated)](#three-pronged-enforcement-restated)
  - [Allow-list specification (binding)](#allow-list-specification-binding)
  - [`docs/tech-lead/` directory (binding)](#docstech-lead-directory-binding)
  - [Escape-hatch semantics (binding)](#escape-hatch-semantics-binding)
  - [Scaffold-time exception (binding)](#scaffold-time-exception-binding)
  - [Decision-log path winner (binding)](#decision-log-path-winner-binding)
  - [Bash write-pattern detection](#bash-write-pattern-detection)
  - [Hook specification (handoff to `software-engineer`)](#hook-specification-handoff-to-software-engineer)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Migration notes](#migration-notes)
  - [Follow-up ADRs](#follow-up-adrs)
- [Relationship to other rules and ADRs](#relationship-to-other-rules-and-adrs)
- [Verification](#verification)
- [ADR-internal follow-ups](#adr-internal-follow-ups)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`). Supersedes FW-ADR-0011 on
primary enforcement; FW-ADR-0011 is recharacterised as audit /
defense-in-depth tooling. See [Migration notes](#migration-notes).

---

## Status

- **Accepted: 2026-05-14**. Supersedes FW-ADR-0011's
  primary-enforcement framing. FW-ADR-0011 is **not** deprecated;
  its trailer convention and `scripts/lint-routing.sh` lint remain
  in place as defense-in-depth audit tooling (prong 2). The
  CI workflow (`.github/workflows/role-routing-lint.yml`) is
  retired by this ADR.
- **Deciders:** `architect` + `tech-lead` + customer (this ADR
  changes the primary preventive mechanism for Hard Rule #8;
  customer rejected the CI-blocking + reviewer-return shape in
  three turns on 2026-05-14 — verbatim quotes in
  [Context and problem statement](#context-and-problem-statement)).
- **Consulted:** `software-engineer` (PreToolUse hook
  implementation surface; the `customer-notes-guard.py`
  precedent), `researcher` (`researcher-techlead-writes` survey
  of tech-lead's legitimate direct-write paths, 2026-05-14),
  `tech-writer` (SessionStart banner text rewrite),
  `code-reviewer` and `release-engineer` (reviewer-agent role
  changes are explicitly scoped *out* of this ADR per the
  customer pivot; the hook is the primary mechanism, reviewers
  do not become the safety net).

## Context and problem statement

Hard Rule #8 in `CLAUDE.md` (verbatim):

> 8. `tech-lead` orchestrates; it does not author production artifacts
>    directly. Code, scripts, schemas, prose deliverables, requirements,
>    ADRs, release notes, and customer-truth records route to the owning
>    specialist (`software-engineer`, `tech-writer`, `researcher`,
>    `project-manager`, `architect`, etc.). Direct `tech-lead` writes are
>    limited to orchestration artifacts (`OPEN_QUESTIONS.md`,
>    intake-log rows, dispatch/task stubs, Turn Ledger / decision-log
>    entries) and tool-bridge work a specialist cannot perform in its
>    sandbox. When unsure, dispatch.

FW-ADR-0011 (2026-05-14, earlier same session) shipped a
three-pronged enforcement model whose **primary** prong was a
`Routed-Through:` commit-message trailer + `scripts/lint-routing.sh`
+ a CI workflow that would block PRs on lint failures. The customer
rejected the CI-blocking + reviewer-return shape in three
consecutive turns on 2026-05-14 (verbatim, recorded by `researcher`
as the customer-truth input that drives this superseding ADR):

> "if tech-lead goes rogue and the code reviewer accepts and the
> release engineer also accepts it, then it shouldn't block on
> github, they should return to tech-lead that they found it
> authoring files that it shouldn't be."

> "this doesn't stop tech-lead going rogue, it just makes the
> cleanup more painful"

> "if tech-lead is already off the path, then tech-lead authors a
> file, but the code review never happens."

> "ok. so maybe tech-lead needs the directories it can write to
> limited. so it can't even write to the source directory."

> "what files does tech-lead legitimately write to? can we
> whitelist those and a tech-lead directory in docs?"

The customer's reasoning: review-catch cannot fire if `tech-lead`
skips the review dispatch in the first place. CI gating cleans up
the consequence; it does not prevent the act. Reviewer-return-to-
tech-lead presumes the review happens, which presumes `tech-lead`
behaved correctly enough to dispatch a reviewer — the same
discipline that just failed. The only mechanism that does not
depend on `tech-lead`'s own discipline to trigger is a tool-layer
intercept on the write itself.

ADR-trigger rows that fire: cross-cutting pattern change (the
authoring-permission boundary becomes mechanically enforced at
the tool layer); existing-ADR supersession (FW-ADR-0011's primary
prong); change to a SessionStart hook on the framework surface;
and choice that locks downstream projects into a hook-based
write-gate they inherit from the template. Customer pivot of
2026-05-14 (recorded verbatim in `CUSTOMER_NOTES.md` by
`researcher`) is the binding input.

## Decision drivers

- **Prevention must not depend on the discipline that failed.**
  The rejected shape used `code-reviewer` / `release-engineer` /
  CI as the catch. All three require `tech-lead` to dispatch the
  review or run the gate — the same discipline Hard Rule #8
  enforces. A mechanism that fires only when the violator is
  already behaving correctly is not a mechanism.
- **Allow-list over deny-list.** A small, enumerated set of
  paths `tech-lead` may write to is auditable in one screen.
  A classify-and-deny table grows under change pressure and
  drifts; FW-ADR-0011's embedded file-class table already
  acquired 14 rows in its first pass and a documented drift
  finding (its own `software-engineer` follow-up §"ADR-internal
  follow-ups", item 2) within hours of shipping. Allow-listing
  what is permitted is shorter than enumerating what is
  forbidden and fails closed by default.
- **Mirror an existing hook the team already maintains.**
  `scripts/hooks/customer-notes-guard.py` is a working
  PreToolUse hook that intercepts Write / Edit / MultiEdit /
  Bash, parses tool inputs, detects shell write-patterns
  (heredocs, redirects, `tee`, in-place edits, interpreter
  inlines), and returns a structured permission decision. The
  same infrastructure generalises; reusing its shape limits new
  surface to one file.
- **Tool-bridge work is legitimate and must not require
  workarounds.** Sub-agent sandboxes sometimes cannot perform
  the writes their work produces (filesystem boundary,
  permission scope). The escape hatch must be present from day
  one, mirror the precedent the team already has, and remain
  a *flag* — not a free-text override.
- **Bounded ongoing cost.** The allow-list must change rarely.
  If the set grows beyond ~10 entries within the first two
  MINOR releases, that is a failure signal that the orchestration
  surface is being mis-scoped; the hook surfaces the pressure
  rather than absorbing it.
- **Downstream extensibility, but defaulted closed.** Downstream
  projects may add project-local `tech-lead` write surfaces
  (e.g., a project-specific ledger). The override surface
  exists from day one via the `docs/tech-lead/` catch-all
  glob; project-specific files land there rather than
  fragmenting into bespoke allow-list entries.

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: keep ADR-0011 + raise the SessionStart banner

Keep FW-ADR-0011 unchanged. Strengthen the SessionStart banner
text to emphasise "check before writing"; treat the trailer +
lint + CI workflow as sufficient mechanical enforcement.

- **Sketch:** No new hook. Update
  `scripts/hooks/role-routing-reminder.sh` banner text. Keep
  the CI workflow + lint script + trailer convention as the
  primary mechanism.
- **Pros:**
  - Zero new framework surface beyond the ADR-0011 footprint.
  - Reuses the work already shipped on the trailer branch.
  - SessionStart banner is the cheapest reinforcement available.
- **Cons:**
  - Fails the customer pivot's core argument: a CI catch fires
    *after* the act, not before. The customer rejected this
    shape explicitly in three consecutive turns.
  - Banner text is not a mechanism — it is a reminder. The
    same discipline that ignores Hard Rule #8 prose in the
    file ignores the banner prose at session start.
  - Leaves the structural failure mode (reviewer-skip → no
    catch fires) in place.
- **When M wins:** if the customer pivot were a preference
  question rather than a structural one. It is not; the
  customer's third quote — "if tech-lead is already off the
  path … the code review never happens" — is a structural
  claim and rules M out by name.

### Option S — Scalable: PreToolUse allow-list hook (primary preventive) + trailer / lint downgraded to audit

A new PreToolUse hook
(`scripts/hooks/tech-lead-authoring-guard.py`) intercepts
`Write` / `Edit` / `MultiEdit` and `Bash` write-patterns. The
hook reads each tool invocation's target path and:

- If the path is on the allow-list (a small enumerated set
  plus the `docs/tech-lead/**` catch-all glob), the hook
  returns silently and the write proceeds.
- If the path is off the allow-list, the hook returns a
  `permissionDecision: "deny"` with a message naming the
  owning specialist for that file class and instructing the
  main session to dispatch instead.
- An environment-variable escape hatch
  (`SWDT_AGENT_PUSH=<role>`) widens the allow-list for one
  invocation cycle to cover the agent-push case
  (specialist's sandbox cannot write; main session bridges
  the file to disk). The variable's value is the specialist
  whose work is being pushed; the hook still enforces a
  carve-out for `CUSTOMER_NOTES.md` (only widens when
  `SWDT_AGENT_PUSH=researcher`, mirroring
  `customer-notes-guard.py`'s domain-specific rule).

The trailer convention from FW-ADR-0011 stays as **audit and
post-hoc debug**: `scripts/lint-routing.sh` runs locally
inside `code-reviewer` and `release-engineer` review
sessions, surfaces drift, and feeds back to the team. The
`.github/workflows/role-routing-lint.yml` CI workflow is
**retired**; no CI gate exists on Hard Rule #8.

- **Sketch:** One new hook script under `scripts/hooks/`
  (Python, ~150 lines, mirroring `customer-notes-guard.py`).
  Four new entries in `.claude/settings.json`'s `PreToolUse`
  hooks array (one per matcher: Write, Edit, MultiEdit,
  Bash) — or, preferred, consolidation of the existing
  per-matcher entries into one hook command that calls both
  `customer-notes-guard.py` and the new guard sequentially
  (see [Hook specification](#hook-specification-handoff-to-software-engineer)).
  One CI workflow file deleted. SessionStart banner text
  updated to reflect "hook will block the write" instead of
  "trailer is the mechanical signal."
- **Pros:**
  - Prevention at the tool layer. Fires before the act,
    not after. Cannot be skipped by `tech-lead`'s own
    discipline failure.
  - Allow-list is small and fits on one screen; auditable.
  - Escape hatch is a single flag (env var), parameterised
    by role, and mirrors a precedent the team already
    maintains. No new override-vocabulary to learn.
  - The trailer + lint do not go away; they become a
    cleaner audit story (commit-by-commit signal of who
    routed what, surfaced during review, not used as a
    CI gate). The two prongs play their natural roles:
    hook prevents, lint audits.
  - CI surface shrinks. One fewer workflow to maintain;
    one fewer place for the gate to be circumvented
    (admin override, force-merge, etc.).
- **Cons:**
  - Adds a hook that runs on every Write / Edit / Bash
    invocation. The cost mirrors the existing customer-
    notes guard; in practice this is sub-millisecond
    per call.
  - The escape hatch is an env var, which is in-process
    state that does not survive a tool-bridge commit's
    full lifecycle. If `tech-lead` forgets to set it
    before the agent-push, the write is denied and the
    main session has to redo the call with the flag.
    Friction-as-feature: the friction is small enough
    not to block real work and large enough to keep the
    flag from going stale ambient state.
  - Allow-list maintenance becomes architect-owned. The
    list changes via this ADR or a follow-up ADR;
    `docs/tech-lead/` is the safety valve for content
    that does not warrant an allow-list rev.
  - Downstream projects inherit the hook and the
    allow-list. Customisation requires either a
    downstream override file (out of scope for v1) or
    landing all new write surfaces under `docs/tech-lead/`.
- **When S wins:** the customer pivot's structural claim.
  Prevention has to fire before the act; the only layer
  before the act is the tool layer. This is the only
  option of the three that satisfies that claim.

### Option C — Creative: chroot the main session to an orchestration workspace

The main session runs with its working directory or
write-permissions restricted to an orchestration workspace
(`docs/tech-lead/`, `docs/OPEN_QUESTIONS.md`, intake-log).
Production paths exist outside the writable scope entirely.
Specialists run with their own write-scopes per role; the
harness composes the union of scopes when a sub-agent is
spawned.

- **Sketch:** Use OS-level facilities — chroot, namespaces,
  bind mounts, or a per-process umask + ACL setup — to make
  production paths physically non-writable for the main
  session. Subagents spawn with their own scope grant.
  Conceptually the strongest form of "tech-lead cannot write
  to the source directory."
- **Pros:**
  - Strongest preventive guarantee available. The write
    cannot succeed even if the hook is bypassed.
  - Conceptually clean: roles map to filesystem scopes the
    way they map to dispatch responsibilities.
- **Cons:**
  - The Claude Code harness does not expose per-agent
    filesystem-scope primitives; sub-agents share the
    operator's filesystem. Building this would require
    harness-level changes (Anthropic-side) or running each
    agent in a container with bind mounts, which is well
    out of the framework's scope.
  - Codex parity is even harder; the framework explicitly
    targets cross-harness compatibility.
  - Hostile to the customer-as-operator model. The same
    human runs `tech-lead` and uses the shell for ad-hoc
    inspection; a chroot blocks both.
  - Tooling like `git`, `rg`, editors, and IDE integrations
    all assume one filesystem view. Splitting the view per
    role breaks every tool simultaneously.
  - The escape hatch becomes "exit the chroot," which is
    either trivial (defeats the point) or impossible
    (defeats legitimate tool-bridge work).
- **When C wins:** in a future harness that natively
  supports per-agent filesystem scopes (capability-based
  delegation). That harness does not exist today; building
  it is not in this ADR's scope. C is the option that names
  the constraint — harness primitives — that rejects it.

## Decision outcome

**Chosen option: S (PreToolUse allow-list hook as primary
preventive; trailer / lint downgraded to defense-in-depth
audit; CI workflow retired).**

**Reason:** Only S satisfies the customer pivot's structural
claim that prevention must fire before the act. M leaves the
post-act catch in place and was explicitly rejected; C
requires harness primitives the framework cannot rely on.
S mirrors a precedent the team already maintains
(`customer-notes-guard.py`), keeps the existing trailer work
useful (as audit), shrinks the CI surface by one workflow,
and lands the prevention where it has to land — at the tool
layer. The allow-list discipline (small, enumerated, with
`docs/tech-lead/` as the catch-all for future content) keeps
the policy auditable in one screen and changes only via this
ADR or a follow-up.

### Three-pronged enforcement (restated)

- **Prong 1 — PreToolUse hook (primary preventive).**
  `scripts/hooks/tech-lead-authoring-guard.py` intercepts
  Write / Edit / MultiEdit / Bash. Denies writes off the
  allow-list. Honours the `SWDT_AGENT_PUSH=<role>` escape
  hatch. **This is the rule's mechanical floor.**
- **Prong 2 — `Routed-Through:` trailer + `scripts/lint-routing.sh`
  (audit / debug aid).** Trailer convention from FW-ADR-0011
  stays. Lint script stays. `code-reviewer` and
  `release-engineer` invoke the lint locally during reviews;
  the lint is no longer a CI gate. The trailer is a
  commit-by-commit *narrative* of routing, not a *check*.
- **Prong 3 — SessionStart hook (in-session reminder).**
  `scripts/hooks/role-routing-reminder.sh` stays. Banner
  text updated to reflect prong-1's tool-layer block, so the
  session opens with an accurate description of the
  mechanism.

### Allow-list specification (binding)

Per the `researcher-techlead-writes` survey of 2026-05-14,
the definitive set of paths `tech-lead` may write to in the
main session (no `SWDT_AGENT_PUSH` flag set) is:

**Always-allowed orchestration files (exact paths):**

- `docs/OPEN_QUESTIONS.md`
- `docs/intake-log.md`
- `docs/DECISIONS.md` (see
  [Decision-log path winner](#decision-log-path-winner-binding))
- `docs/pm/dispatch-log.md`

**Always-allowed orchestration globs:**

- `docs/pm/intake-*.md` — Step-2 scoping dumps and their
  `.local.md` companions, per
  `docs/agents/manual/tech-lead-manual.md:174`.
- `docs/tech-lead/**` — the catch-all for future
  tech-lead-authored orchestration content. See
  [`docs/tech-lead/` directory](#docstech-lead-directory-binding).

**Always-allowed task / dispatch stubs:**

- `docs/tasks/T-*.md` — **stub creation only** (file creation
  + initial INVEST/DoR scaffold from
  `docs/templates/task-template.md`). Body authoring is
  specialist work; the hook cannot reliably distinguish stub
  from body authoring at the tool layer, so this allow-list
  entry is necessarily permissive on the *path* and the
  prose discipline lives in Hard Rule #8's text. The trailer
  + lint pair (prong 2) catches body-authoring drift in
  audit.

**Scaffold-time exception (always allowed; see
[Scaffold-time exception](#scaffold-time-exception-binding) for
semantics):**

- `TEMPLATE_VERSION` (one-shot at project init).
- `docs/AGENT_NAMES.md` (Step-3 fill; rare post-init edits).

Anything else off this list with no `SWDT_AGENT_PUSH` flag
set is **denied** by prong 1. The hook's deny message names
the file class and the owning specialist; the main session
dispatches.

### `docs/tech-lead/` directory (binding)

**Recommendation: create `docs/tech-lead/` as an empty
directory now (with a one-line README pinning its purpose),
do not migrate existing content into it.**

Rationale: the `researcher-techlead-writes` move-cost matrix
shows `docs/OPEN_QUESTIONS.md` (50+ cross-refs across lint
scripts, scaffold scripts, agent contracts, and runtime
docs) and `docs/intake-log.md` (27 cross-refs including the
`migrations/v1.0.0-rc9.sh` ABI) are **high move-cost**
relative to the marginal aesthetic win of a unified
directory. `docs/DECISIONS.md` is medium-cost (8 cross-refs
including a migration script). Moving any of these now would
require coordinated edits across `scripts/lint-routing.sh`,
`scripts/lint-questions.sh`, `scripts/archive-registers.sh`,
`scripts/hooks/atomic-question-reminder.sh`,
`scripts/scaffold.sh`, `scripts/smoke-test.sh`, every
`.claude/agents/*.md`, `CLAUDE.md`, `AGENTS.md`,
`migrations/v1.0.0-rc9.sh`, and downstream
`TEMPLATE_VERSION`-stamped projects' upgrade paths. The
allow-list handles the existing files at their existing
paths cleanly; `docs/tech-lead/` exists as the **extensibility
slot** so future tech-lead-authored orchestration content
lands in one place without requiring an allow-list rev per
file.

Concrete contents of `docs/tech-lead/` on day one:

- `docs/tech-lead/README.md` — one-paragraph pin of the
  directory's purpose. Authored by `tech-writer` at
  implementation time; the architect's design intent
  recorded here.

Nothing else moves in. Files added later are landed there
by default unless they have a structural reason to live
elsewhere (e.g., `docs/pm/` continues to own PM-class
artefacts).

### Escape-hatch semantics (binding)

A single environment variable, `SWDT_AGENT_PUSH=<role>`,
mirrors the precedent of `customer-notes-guard.py`'s
override and extends it to the broader allow-list:

- When `SWDT_AGENT_PUSH` is **unset** or empty, the hook
  applies the allow-list as specified above.
- When `SWDT_AGENT_PUSH=<role>` is set in the environment
  the hook sees, the hook widens the allow-list to the
  union of the always-allowed paths plus *any path the
  named role legitimately owns* — for v1, this means **any
  path except `CUSTOMER_NOTES.md`**. CUSTOMER_NOTES.md
  retains its separate gate (`customer-notes-guard.py`)
  and is only widened when `<role>` is `researcher`.
- The flag is **per-invocation**: the value lives in the
  environment for the single tool call the operator is
  about to make. The main session sets the flag, makes the
  call, the flag is cleared on the next turn. The
  framework does not provide automation for setting it
  durably; the friction is deliberate.
- Disallowed roles (anything not on the canonical roster
  or matching `sme-<domain>`) cause the hook to deny with
  a diagnostic naming the role as unrecognised.

The escape-hatch shape is intentionally **a single flag,
not multiple per-qualifier vars** and not a JSON-file
context. Reasons:

- Single-flag mirrors the customer-notes-guard precedent.
  Operators already know the pattern.
- Multiple vars per qualifier (one for each of
  agent-push / orchestration / ci-fixup / merge / revert /
  rebase / cherry-pick) re-introduce the closed-qualifier
  set FW-ADR-0011 maintained for the trailer. Prong-1's
  job is to prevent the write; the qualifier semantics
  belong to prong-2's audit story.
- A JSON-file context is durable state; durability is the
  failure mode (the flag goes stale and silently widens
  the gate). An env var that vanishes between turns is
  self-cleaning.

#### Addendum 2026-05-14 — inline form (issues #176, #179, #180)

The v1 framing above describes the **harness-env** form of
the escape hatch only. Two PRs landed on 2026-05-14 extended
the contract; this addendum records the resulting binding
shape so the ADR matches the hook in `scripts/hooks/tech-lead-authoring-guard.py`.

**Two supported forms (binding).** The hook now honours the
escape hatch in either of the following shapes; both widen
the allow-list for exactly one tool invocation.

1. **Harness-env (canonical, unchanged from v1).**
   `SWDT_AGENT_PUSH=<role>` is set in the Claude Code session
   environment — via `.claude/settings.json`'s `env` block,
   shell-startup (`~/.bashrc`, `~/.zshenv`, etc.), an
   external launcher wrapping the harness, or any other
   mechanism that puts the variable into the harness's
   process environment before the tool call runs. Preferred
   for multi-command sessions where the same role is
   pushing several writes.

2. **Inline-on-Bash (added by PR #178, tightened by commit
   85d9e4a / issue #179).** A Bash command prefixed with
   either `SWDT_AGENT_PUSH=<role> <command>` or
   `export SWDT_AGENT_PUSH=<role>; <command>` honours the
   hatch for that single Bash invocation. The prefix MUST
   appear in the **leading position** of the command — i.e.
   the assignment is the first non-whitespace token, with
   only optional `export ` ahead of it. Forms placed
   mid-chain (after `&&`, `||`, `;`, or `|`) are explicitly
   NOT honoured by the hook; from a shell-semantics
   standpoint the assignment would scope to a subshell that
   has nothing to do with the outer command, and naming it
   "the escape hatch for the whole command" is misleading.
   The leading-position anchor in `_INLINE_AGENT_PUSH_RE`
   is the mechanical floor for this rule.

The inline form was added because the deny diagnostic's
natural reading — "set `SWDT_AGENT_PUSH=<role>`" — suggested
inline assignment should work, and Claude Code's `Bash` tool
spawns a fresh shell per call, which made the bare inline
prefix silently inert before PR #178. Issue #176 surfaced
the ambiguity; the inline parser closes it. Harness-env
remains preferred when the operator is pushing more than one
write under the same role; inline is the right form for
one-off tool-bridge calls where editing durable session
config is friction the operator does not want to absorb.

**Threat model (refined).** The escape hatch trusts the
command-string author by definition: anyone with the ability
to author a command string can prefix it with whatever they
want. Two specific abuse vectors were tightened during
PR #178 review and commit 85d9e4a:

- **`tech-lead` self-push is rejected in both forms.** The
  guard exists to prevent `tech-lead` from authoring
  production artifacts; allowing `SWDT_AGENT_PUSH=tech-lead`
  (harness-env or inline) to widen the allow-list defeats
  that purpose. `_validate_role()` rejects `tech-lead`
  explicitly before the canonical-roles check. Code-
  reviewer's PR #178 finding #2.
- **Leading-position anchoring (issue #179).** Before commit
  85d9e4a the inline regex matched the assignment anywhere
  in the command, which meant patterns like
  `cd foo && SWDT_AGENT_PUSH=architect echo y > path/x.md`
  silently widened the allow-list even though the
  assignment, in a real shell, would only have taken effect
  for a subshell that did not include the preceding `cd`.
  The tightened regex requires the assignment to be the
  leading token of the command string. Forms that the
  shell would actually have interpreted as command-prefix
  variables (i.e. assignment immediately before the command
  that performs the write) are still honoured; chained
  forms hidden in command pipelines no longer match.

Accepted role vocabulary is unchanged: the canonical roster
plus `sme-<slug>` matching `^sme-[a-z][a-z0-9_-]*$`.
`tech-lead` is in the roster for other vocabulary purposes
but is rejected as an escape-hatch value in both forms.

**Heredoc-body redirect handling (issue #180, commit
85d9e4a).** Adjacent to the escape-hatch tightening, commit
85d9e4a fixed an over-block in the Bash write-pattern
detector: heredoc bodies were being scanned as if they were
shell syntax, and prose containing `>` (e.g. `"If x > y …"`,
`"stdout > stderr.log"`, or a `python -c` string with
`print('a > b')`) was tripping the redirect regex on phantom
paths. The fix treats heredoc bodies and non-shell-
interpreter inline bodies as DATA for the shell-redirect
scanner; real `open(..., 'w'|'a'|…)` writes inside an
interpreter body are still caught by
`_extract_interpreter_inline_targets`. This is detector-side
tightening, not escape-hatch surface, but it lands in the
same commit and is documented here for cross-reference; see
issue #180 for the test cases the corpus pins.

**Verification responsibility (forward reference).** Future
hooks that introduce an escape-hatch surface MUST verify the
hatch fires under every harness mode the hook can be invoked
from — at minimum: the Claude Code `Bash` tool, the
inline-bang `!`-bash form, the Codex shell, command-
substitution wrappers, and heredoc-fed shells. The
hook-negative-corpus convention captured in `specs/009-hook-negative-corpus/contract.md`
(once that spec lands) is the canonical contract for this
discipline; it grew out of the same process-auditor R-B
audit that surfaced issues #175 / #176 / #179 / #180. Until
spec 009 is merged, treat the test script at
`tests/hooks/test-tech-lead-authoring-guard.sh` as the
provisional shape and mirror it for new hooks.

**Cross-references for this addendum:**

- Issue #175 — over-block on read-only operations against
  paths whose names contain a literal write-pattern string
  (closed by PR #178).
- Issue #176 — inline escape-hatch was documented as
  permitted by the deny diagnostic but not honoured by the
  hook (closed by PR #178; the inline parser added by that
  PR is the binding mechanism above).
- Issue #179 — leading-position anchoring for the inline
  form (closed by commit 85d9e4a; reflected in the
  threat-model and binding shape above).
- Issue #180 — heredoc-body and non-shell-interpreter-body
  redirect over-block on prose containing `>` (closed by
  commit 85d9e4a; detector-side tightening described
  above).
- Issue #181 — this addendum (ADR amendment recording the
  inline-form contract and leading-position anchor that
  PR #178 + commit 85d9e4a landed).
- Spec 009 (`specs/009-hook-negative-corpus/contract.md`) —
  forthcoming negative-corpus contract; binding once
  merged.

### Scaffold-time exception (binding)

`TEMPLATE_VERSION` and `docs/AGENT_NAMES.md` are
tech-lead-authored at Step 0 / Step 3 of project
initialisation (per `docs/FIRST_ACTIONS.md`) and seldom
edited thereafter. Two viable shapes:

1. **Always-allow these two paths** in the hook's
   allow-list. The hook cannot tell Step-0 / Step-3 from
   a later session, but the rule against rewriting these
   files is documentary (the `docs/FIRST_ACTIONS.md`
   guidance plus `tech-lead`'s pre-close audit). False
   positives — `tech-lead` rewriting `TEMPLATE_VERSION`
   in a non-init session — are caught by prong 2's
   trailer audit, not by prong 1.
2. **Session-gate env var** (`SWDT_SETUP_SESSION=1`) that
   widens the gate only during the init session.

**Chosen shape: option 1 (always-allow the two paths).**

Reason: option 2 introduces a second env-var flag, which
fragments the escape-hatch vocabulary; it also requires
the operator to remember to set it during a session that
is already cognitively loaded (Step 0–3 walkthrough). The
two paths are narrow enough (one file each, both rare-edit)
that always-allowing them costs nothing in policy expressiveness
and the trailer audit catches abuse. The pre-close audit
under Hard Rule #9 covers the documentary side.

### Decision-log path winner (binding)

Three documented references diverge:

- `CLAUDE.md` Hard Rule #8 says "decision-log entries"
  with no path.
- `.claude/agents/tech-lead.md:101` pins `docs/DECISIONS.md`.
- FW-ADR-0011 §326-328 says "decision-log entries under
  `docs/pm/`."

**Winner: `docs/DECISIONS.md` (canonical, repo root under
`docs/`).** FW-ADR-0011's "under `docs/pm/`" hint is
**not** adopted.

Reasons:

- `docs/DECISIONS.md` is the path already wired into
  `.claude/agents/tech-lead.md`, multiple runtime docs,
  and `migrations/v1.0.0-rc9.sh` (a migration ABI). Moving
  it costs migration coordination for no policy gain.
- The PM artefacts under `docs/pm/` are project-manager-
  owned per Hard Rule #8 and the FW-ADR-0011 file-class
  table. `docs/DECISIONS.md` is `tech-lead`-authored as
  an orchestration record; co-locating it with PM
  artefacts blurs ownership.
- The 8 cross-references are addressable in a single
  `tech-writer` follow-up (see
  [Migration notes](#migration-notes)); the file itself
  stays put.

Reconciliation plan:

- `CLAUDE.md` Hard Rule #8 — `tech-writer` adds the
  explicit path `docs/DECISIONS.md` next to "decision-log
  entries" in a follow-up edit on the same branch.
- `.claude/agents/tech-lead.md:101` — already correct;
  no change.
- FW-ADR-0011 §326-328 — `architect` adds a one-line
  superseded-by note at that section pointing to this
  ADR's binding ruling.

### Bash write-pattern detection

The hook **reuses** the bash-pattern detection from
`scripts/hooks/customer-notes-guard.py` rather than
reimplementing it. Specifically, the hook generalises
the detection from a single-file target (`CUSTOMER_NOTES.md`)
to a path predicate (`is_on_allow_list(path)`). Patterns
covered (mirroring the precedent):

- Shell redirects (`>`, `>>`, `1>`, `2>&1 >`, `&>`,
  `&>>`, `>|`).
- `tee <path>` / `tee -a <path>`.
- `dd of=<path>`.
- In-place edits: `sed -i`, `gawk -i inplace`, `perl -i`,
  `ruby -i`.
- Mutation commands: `mv`, `cp`, `rm`, `truncate`,
  `install`.
- Interpreter inlines / heredocs: `python -c`, `node -e`,
  `bash <<EOF`, etc., when the heredoc body or `-c`
  argument names a path off the allow-list.

**Consolidation question.** Two viable shapes:

1. Keep two separate hooks
   (`customer-notes-guard.py` + `tech-lead-authoring-guard.py`)
   running in sequence on the same matchers.
2. Merge into one hook
   (`tech-lead-authoring-guard.py`) that handles both the
   broader allow-list and the CUSTOMER_NOTES-specific
   researcher-only rule.

**Chosen shape: option 1 (keep two separate hooks).**

Reason: `customer-notes-guard.py` has its own
review-and-test history, its own pattern-tuning for the
"prompt on actual writes only" UX issue #111, and its own
semantic (it returns `permissionDecision: "ask"`, not
`"deny"`). The new guard returns `"deny"` for off-list
paths. Conflating the two semantics into one hook
muddles the failure modes. Two hooks running in sequence
on the same matchers is the same pattern
`.claude/settings.json` already encodes for SessionStart
hooks (version-check + atomic-question-reminder +
role-routing-reminder all run in sequence). The new hook
imports / vendors the bash-pattern detection helpers from
`customer-notes-guard.py` to avoid duplicate maintenance
of the regex set; see
[Hook specification](#hook-specification-handoff-to-software-engineer).

### Hook specification (handoff to `software-engineer`)

This section is the implementation contract.
`software-engineer` owns the actual write; the architect's
design intent is fixed here.

**File.** `scripts/hooks/tech-lead-authoring-guard.py`.
Python 3 (matches `customer-notes-guard.py`). Approximately
~150 lines.

**Wiring.** Add four `PreToolUse` hook entries to
`.claude/settings.json` (matchers: `Write`, `Edit`,
`MultiEdit`, `Bash`), each calling
`python3 "${CLAUDE_PROJECT_DIR}/scripts/hooks/tech-lead-authoring-guard.py"`
with `timeout: 5`. The new hooks run **after** the existing
`customer-notes-guard.py` entries for each matcher; ordering
matters because the CUSTOMER_NOTES gate's `"ask"` semantic
must compose cleanly with the authoring-guard's `"deny"`
semantic (the customer-notes gate's "ask" wins on the
specific file; the broader guard catches everything else).

**Allow-list constants.** Encoded at the top of the script
as Python tuples / sets:

```python
ALLOW_EXACT = frozenset({
    "docs/OPEN_QUESTIONS.md",
    "docs/intake-log.md",
    "docs/DECISIONS.md",
    "docs/pm/dispatch-log.md",
    "TEMPLATE_VERSION",
    "docs/AGENT_NAMES.md",
})

ALLOW_GLOBS = (
    "docs/pm/intake-*.md",
    "docs/pm/intake-*.local.md",
    "docs/tech-lead/**",
    "docs/tasks/T-*.md",
)
```

Path normalisation: resolve to repo-root-relative form
before matching (strip leading `./`, collapse `..`, reject
any path that resolves outside the repo). Glob matching via
`fnmatch.fnmatch` for the `*` cases and `pathlib.PurePath.match`
for `**`.

**Escape-hatch parsing.** Read `SWDT_AGENT_PUSH` from
`os.environ`. Allowed values: the canonical roster
(`tech-lead`, `project-manager`, `architect`,
`software-engineer`, `researcher`, `qa-engineer`, `sre`,
`tech-writer`, `code-reviewer`, `release-engineer`,
`security-engineer`, `onboarding-auditor`,
`process-auditor`) plus the regex `^sme-[a-z][a-z0-9_-]*$`.

When set:

- For paths other than `CUSTOMER_NOTES.md` (and not under
  `docs/customer-notes/**`): hook returns silently
  (write proceeds).
- For `CUSTOMER_NOTES.md` and `docs/customer-notes/**`:
  hook returns silently *only if* the value is
  `researcher`; otherwise denies (the customer-notes
  guard's `"ask"` may still fire on the same call —
  that is correct composition; the operator gets the
  CUSTOMER_NOTES prompt independent of this guard's
  decision).

When unset / empty / unrecognised: applies the allow-list
as normal.

**Bash write-pattern detection.** Vendor (import) the
helpers from `customer-notes-guard.py`. Generalisation
shape — the new hook's pattern detection follows the same
structure but parameterises on the target path rather
than the fixed `CUSTOMER_NOTES.md`:

```python
def _command_writes_off_allow_list(command: str) -> str | None:
    # Returns the first off-allow-list path the command writes to,
    # or None if the command does not perform a write to an
    # off-list path. Recognises shell redirect, tee, dd of=,
    # in-place edits, mutation commands, interpreter inlines.
    ...
```

The function extracts candidate paths from the command,
filters to paths off the allow-list, and returns the
first one (or None). The hook's caller uses the returned
path to populate the deny message.

**Exit codes & permission decisions.**

- Path / command on allow-list → `return 0` with no
  output (write proceeds; matches the
  `customer-notes-guard.py` "no opinion" case).
- Path / command off allow-list and no escape hatch →
  print JSON
  `{"hookSpecificOutput": {"hookEventName": "PreToolUse",
  "permissionDecision": "deny",
  "permissionDecisionReason": "<diagnostic>"}}`
  and `return 0`. The harness honours the `deny` and blocks
  the tool call.
- Path / command off allow-list with escape hatch set →
  apply the escape-hatch rules above; return silently or
  deny per the rules.
- Malformed JSON / unexpected payload shape → fail open
  (`return 0` silently), mirroring
  `customer-notes-guard.py`'s issue #156 posture.

**Diagnostic format.** The `permissionDecisionReason`
names the file, the owning specialist (best-effort guess
from the path: code → `software-engineer`, ADR →
`architect`, etc.; the guess is informational only —
the policy is allow-list, not classify-and-deny), and the
remedy: "dispatch `<specialist>` to author this file, or
set `SWDT_AGENT_PUSH=<role>` if this is tool-bridge work
on behalf of a specialist whose sandbox cannot write."

**Self-test.** Mirrors `customer-notes-guard.py`'s
fixture pattern. Add `tests/fixtures/tech-lead-authoring-guard/`
with pairs `(tool_input_json, expected_decision)`:
allow-list paths (proceed), off-list paths (deny), off-list
Bash commands (deny), off-list paths with
`SWDT_AGENT_PUSH=software-engineer` set (proceed), CUSTOMER_NOTES.md
with `SWDT_AGENT_PUSH=architect` set (deny), `docs/tech-lead/foo.md`
(proceed), `docs/tasks/T-0042.md` (proceed).

## Consequences

### Positive

- **Hard Rule #8 acquires a real preventive layer.** The
  hook fires before the write, not after the commit.
  This is the only configuration that satisfies the
  customer's structural claim of 2026-05-14.
- **Allow-list is auditable in one screen.** Six exact
  paths, four globs, one env-var escape hatch. Readers
  of the policy do not have to keep a file-class table
  in their head.
- **CI surface shrinks.** One workflow file
  (`.github/workflows/role-routing-lint.yml`) goes away.
  One fewer place for the gate to be bypassed.
- **Trailer + lint find their natural role.** Per-commit
  routing narrative remains useful as audit and
  post-incident debugging; not coupled to CI gating.
  Reviewers run the lint locally as part of their
  review, surfacing routing drift in the human-review
  step where the customer wanted it.
- **`docs/tech-lead/` opens an extensibility slot
  without forcing a migration.** Future tech-lead-authored
  content lands there by default; high-move-cost
  existing files stay put.
- **Single-flag escape hatch mirrors the customer-notes
  precedent.** Operators already know the pattern.
- **Decision-log path divergence is resolved** in favour
  of the path with the lowest move-cost (`docs/DECISIONS.md`).

### Negative / trade-offs accepted

- **Every Write / Edit / MultiEdit / Bash call runs
  one more hook.** Cost is dominated by Python startup
  (~10–50 ms on a warm cache) per call. In practice
  this is unmeasurable inside the harness's existing
  per-call overhead, but it is non-zero.
- **The allow-list is short and architect-owned.**
  Adding a new always-allowed path requires this ADR
  to be amended or superseded. The
  `docs/tech-lead/**` glob is the safety valve;
  content that doesn't fit there reveals an architecture
  decision worth recording explicitly.
- **The escape-hatch env var is in-process state.**
  Operators forgetting to set it before a legitimate
  agent-push see a deny and have to retry. Intentional
  friction; the alternative (durable override) silently
  widens the gate.
- **`code-reviewer` and `release-engineer` role
  contracts are *not* extended** to "check for routing
  drift during review." Reviewers may run
  `scripts/lint-routing.sh` locally if they choose;
  that is a discretionary tool, not a contract
  obligation. Reason: making reviewer-catch a contract
  obligation re-introduces the same dependency on
  downstream discipline that the customer pivot
  rejected. The hook is the floor; reviewers may
  optionally surface what the trailer audit reveals,
  but their sign-off does not depend on it. **Out of
  scope, by design.**
- **The hook does not catch sub-agent writes.** A
  specialist sub-agent writing to a path it does not
  own is a separate violation class (a specialist
  authoring out-of-role). The hook intercepts the
  *main session's* writes; sub-agent role discipline
  remains contract-text and pre-close-audit territory.
  Recorded as a follow-up below.
- **Downstream projects cannot extend the allow-list
  via a project-local file in v1.** They land
  project-specific tech-lead-authored files under
  `docs/tech-lead/`. If the demand for downstream
  allow-list extension becomes recurrent, a follow-up
  ADR introduces a `.tech-lead-allowlist` mirroring
  the precedent FW-ADR-0011 set for `.routing-allowlist`.

### Migration notes

The implementation handoff covers four discrete changes:

1. **Add the hook.**
   `scripts/hooks/tech-lead-authoring-guard.py` —
   `software-engineer` (spec in
   [Hook specification](#hook-specification-handoff-to-software-engineer)).
2. **Wire the hook.** Update `.claude/settings.json` to
   add four PreToolUse entries (one per matcher: Write,
   Edit, MultiEdit, Bash), each running the new hook
   after the existing `customer-notes-guard.py` entries.
   `software-engineer`.
3. **Create `docs/tech-lead/`** with `README.md` (one-paragraph
   pin of purpose, cross-ref to this ADR). `tech-writer`.
4. **Retire the CI workflow.** Delete
   `.github/workflows/role-routing-lint.yml`.
   `release-engineer`.
5. **Update the SessionStart banner.** Edit
   `scripts/hooks/role-routing-reminder.sh`'s banner text
   so it reads "PreToolUse hook will block off-list writes
   (see FW-ADR-0012)" instead of the current "every commit
   needs a `Routed-Through:` trailer" framing. The trailer
   sentence stays, but is reframed as the audit signal,
   not the mechanism. `tech-writer`.
6. **Reconcile the decision-log path.** `CLAUDE.md` Hard
   Rule #8 gets the explicit `docs/DECISIONS.md` path
   added; FW-ADR-0011 §326-328 gets a one-line
   superseded-by pointer to this ADR's
   [Decision-log path winner](#decision-log-path-winner-binding).
   `tech-writer` for `CLAUDE.md`, `architect` for the
   FW-ADR-0011 pointer.
7. **Update FW-ADR-0011 status.** Add a single-line note
   at the top: "Primary-enforcement framing superseded
   by FW-ADR-0012 (PreToolUse hook). Trailer convention
   and `scripts/lint-routing.sh` retained as
   defense-in-depth audit tooling per FW-ADR-0012 § Three-
   pronged enforcement (restated)." `architect`.

The migration is non-destructive: the trailer convention
and lint script keep working; only their stated role
changes.

### Follow-up ADRs

- **None required for v1 scope.** The allow-list and
  escape-hatch shape are minimal by design; the next ADR
  is only triggered by an actual emergent pressure
  (downstream allow-list extension demand, sub-agent
  write-discipline violations, allow-list growing past
  ~10 entries).

## Relationship to other rules and ADRs

- **Hard Rule #8 (`CLAUDE.md`).** This ADR provides the
  primary preventive mechanism for Hard Rule #8. The rule
  text itself does not change shape; the enforcement
  layer underneath it does.
- **FW-ADR-0011 (`Routed-Through:` trailer).** This ADR
  supersedes FW-ADR-0011's *primary-enforcement* framing.
  The trailer convention and `scripts/lint-routing.sh`
  remain in place as defense-in-depth audit tooling;
  `.github/workflows/role-routing-lint.yml` is retired.
  FW-ADR-0011's Status header gets a superseding-note edit
  per [Migration notes](#migration-notes) item 7.
- **FW-ADR-0008 (tech-lead orchestration boundary).**
  Unchanged. This ADR is the new mechanical floor for
  FW-ADR-0008's prose boundary; FW-ADR-0011 was the
  previous floor (now reclassified as audit layer).
- **Customer-notes guard (`scripts/hooks/customer-notes-guard.py`).**
  This ADR's hook mirrors that hook's shape and runs in
  the same `PreToolUse` matchers. The two hooks compose:
  the customer-notes guard returns `"ask"` on
  CUSTOMER_NOTES.md (researcher-routing reminder), this
  ADR's hook returns `"deny"` on everything else off the
  allow-list. The escape-hatch env var
  (`SWDT_AGENT_PUSH=<role>`) widens this ADR's hook for
  any role, but only widens the customer-notes guard
  when the role is `researcher`.

## Verification

- **Success signal.** Across a 4-week observation window
  after the hook ships:
  - Off-allow-list `tech-lead` writes drop to zero in
    the main session (the hook denies them; the deny
    appears in operator logs).
  - The `SWDT_AGENT_PUSH` flag appears on the expected
    cadence (matches the tool-bridge work pattern
    `researcher`'s 2026-05-14 survey identified).
  - The `Routed-Through:` trailer audit (prong 2)
    finds no R3 / R4 / R5 violations on commits the
    main session authored — because prong 1 prevented
    them.
  - `code-reviewer` PR notes stop citing direct-write
    incidents as blocking findings.
- **Failure signal.**
  - Allow-list grows past ~10 entries within two MINOR
    releases. This indicates the orchestration surface
    is mis-scoped; revisit the
    `docs/tech-lead/**` discipline.
  - Operators routinely set `SWDT_AGENT_PUSH=tech-lead`
    (the carve-out is being abused to land hand-written
    code under the agent-push framing). Trailer audit
    catches this; the hook does not, by design.
  - The deny rate (per session) on legitimate work
    causes operator friction the customer flags. This
    means the allow-list is too narrow; revisit with
    the customer.
- **Review cadence.** Session-anchored, first session on
  or after the calendar-month boundary, for the first
  three months post-merge. After three months, the ADR
  is reviewed once at every two MINOR-release boundaries
  per `CLAUDE.md` § "Time-based cadences", or sooner if
  a failure signal fires.

## ADR-internal follow-ups

Recorded inside this ADR per the customer-record
discipline; none block acceptance.

- **Sub-agent write discipline.** The hook intercepts
  the main session's writes only. A sub-agent
  (`software-engineer`, `tech-writer`, etc.) writing to
  a path *it* does not own is a separate violation
  class — a specialist authoring out-of-role. The
  trailer + lint pair (prong 2) is the audit signal
  there; a future ADR may consider whether the hook
  should grow per-spawned-agent allow-lists. Out of
  scope for v1.
- **Downstream allow-list extension.** v1 does not ship
  a `.tech-lead-allowlist` file. If downstream projects
  surface recurrent need for project-local additions
  beyond `docs/tech-lead/**`, a follow-up ADR mirrors
  the `.routing-allowlist` precedent FW-ADR-0011
  established (and which this ADR does not retire).
- **`docs/tech-lead/README.md` content.** `tech-writer`
  authors at implementation time. The README pins:
  (a) directory purpose (catch-all for future
  tech-lead-authored orchestration content),
  (b) what does *not* belong here (PM artefacts,
  customer-truth, code, ADRs), (c) cross-reference to
  this ADR.
- **`CLAUDE.md` § "Hard rules" item 8 wording.**
  `tech-writer` adds the explicit
  `docs/DECISIONS.md` path inline; consider whether the
  rule should also mention the PreToolUse hook by name
  (the rule has historically stayed mechanism-agnostic;
  prefer leaving the rule abstract and letting this ADR
  carry the mechanism).
- **Hook ordering invariant.**
  `.claude/settings.json`'s `PreToolUse` array order
  must keep `customer-notes-guard.py` *before*
  `tech-lead-authoring-guard.py` so the CUSTOMER_NOTES
  `"ask"` semantic fires first on the relevant file.
  `software-engineer` records this invariant as a
  comment in `.claude/settings.json` at implementation
  time; a future ADR formalises if the ordering
  contract becomes load-bearing for additional hooks.
- **Hook performance budget.** Python-startup per Write
  / Edit / Bash invocation. If the cumulative cost
  becomes a session-pacing issue, consider rewriting
  both hooks in a compiled language or consolidating
  them despite the semantics-muddling cost.
  `software-engineer` records baseline timing in the
  self-test fixture at implementation time.

## Links

- Customer-truth inputs:
  - `CUSTOMER_NOTES.md` entry of 2026-05-14 recording
    the three verbatim customer quotes that drove the
    pivot (recorded by `researcher` on the same
    branch).
  - `researcher-techlead-writes` survey of 2026-05-14
    (tech-lead's legitimate direct-write surface;
    move-cost matrix for relocating to `docs/tech-lead/`).
- Related ADRs:
  - FW-ADR-0011 — `Routed-Through:` trailer enforcement
    (this ADR supersedes its primary-enforcement framing;
    its trailer + lint live on as audit tooling).
  - FW-ADR-0008 — Tech-lead orchestration boundary
    (the prose rule this ADR's hook enforces at the
    tool layer).
- Related artefacts:
  - `CLAUDE.md` § Hard rules item 8 (the rule this ADR
    enforces — quoted verbatim in
    [Context and problem statement](#context-and-problem-statement)).
  - `scripts/hooks/customer-notes-guard.py` (the
    PreToolUse hook precedent this ADR mirrors).
  - `scripts/hooks/role-routing-reminder.sh` (the
    SessionStart hook whose banner text needs updating
    per [Migration notes](#migration-notes) item 5).
  - `.claude/settings.json` § `PreToolUse` array (the
    wiring surface).
  - `scripts/lint-routing.sh` (the audit tool, now
    prong 2 rather than primary enforcement).
- External references: MADR 3.0 (`https://adr.github.io/madr/`);
  Claude Code PreToolUse hook reference (Anthropic
  documentation, accessed 2026-05-14).
