---
name: fw-adr-0030-subagent-bash-permission-posture
description: >
  Establishes the v1.5.4 subagent Bash permission posture: allow: ["Bash(*)"]
  paired with an 18-entry deny list covering privilege escalation, disk
  destruction, and destructive git operations. Ratifies the "destructive Bash
  operations are a tech-lead duty" principle (Hard Rule #13) as the primary
  control, with the deny list as defense-in-depth. Customer-ratified Option C
  (hybrid) from the design doc.
status: accepted
date: 2026-06-23
---


# FW-ADR-0030 — Subagent Bash permission posture: allow-all with targeted deny list and tech-lead destructive-ops duty

<!-- TOC -->

- [Status](#status)
- [Context and problem statement](#context-and-problem-statement)
- [Decision drivers](#decision-drivers)
- [Considered options (Three-Path Rule, binding)](#considered-options-three-path-rule-binding)
  - [Option M — Minimalist: targeted allow list](#option-m--minimalist-targeted-allow-list)
  - [Option S — Scalable: broad Bash(*) with no deny](#option-s--scalable-broad-bash-with-no-deny)
  - [Option C — Creative / hybrid: Bash(*) allow with targeted deny list and duty statement](#option-c--creative--hybrid-bashallowtargeted-deny-list-and-duty-statement)
- [Decision outcome](#decision-outcome)
  - [Ratified configuration (copy-ready)](#ratified-configuration-copy-ready)
  - [Hard Rule #13 duty statement](#hard-rule-13-duty-statement)
- [Consequences](#consequences)
  - [Positive](#positive)
  - [Negative / trade-offs accepted](#negative--trade-offs-accepted)
  - [Residual-risk note](#residual-risk-note)
  - [Follow-up ADRs](#follow-up-adrs)
- [Verification](#verification)
- [Links](#links)

<!-- /TOC -->

Shape per MADR 3.0 + this template's Three-Path Rule
(`docs/templates/adr-template.md`).

---

## Status

- **Accepted: 2026-06-23**
- **Deciders:** `architect` + `security-engineer` + `tech-lead` + customer
  (permission-posture change alters a cross-cutting security configuration
  affecting all subagents; customer ratification required per CLAUDE.md Hard
  Rules #4 and #7 boundary)
- **Consulted:** `docs/pm/v1.5.4-subagent-permission-posture-design.md`
  (security-engineer design doc, full threat-model analysis in §§1–8.5);
  customer directive of 2026-06-23: "all destructive work should run through
  the tech lead as a declared duty of the tech lead"; FW-ADR-0029 (prior
  ADR: drop of experimental agent-teams flag and reversion to one-shot
  subagents — establishes the permission-inheritance context this ADR builds on)

---

## Context and problem statement

FW-ADR-0029 removed `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` from the
scaffold and added `permissions.defaultMode: acceptEdits` so that subagents
inherit the main session's permission mode without prompting. This eliminated
the Hard Rule #1 violation (Bug #356) and the remote-control silent-wedge
(Bug #355) for Edit / Write / MultiEdit tool calls. However, Bash tool calls
by subagents still required human-visible confirmation prompts for any command
not in a `permissions.allow` entry. On remote-control interfaces (MCP
tool-bridge, headless CI) those prompts are not surfaced to the operator —
the subagent hangs indefinitely until timeout or restart.

The ADR trigger is a cross-cutting configuration change that affects every
Bash-capable subagent (nine agents: `tech-lead`, `software-engineer`,
`release-engineer`, `qa-engineer`, `sre`, `project-manager`,
`onboarding-auditor`, `process-auditor`, `code-reviewer`), touches a
security-relevant permission surface, and locks the scaffold into a vendor
permission model. Per `architect.md` § "ADR trigger list": cross-cutting
concern change; authentication / authorization / session handling modified;
vendor platform choice that is expensive to reverse.

Design doc: `docs/pm/v1.5.4-subagent-permission-posture-design.md`.

---

## Decision drivers

- **Remote-control Bash wedge must be eliminated.** Any Bash command not
  in `permissions.allow` prompts — and on remote control that prompt is
  invisible. Only `Bash(*)` or the upstream harness fix (Bug #356) fully
  eliminates this.
- **Targeted allow lists drift.** New scripts, compound shell forms, and
  project-specific patterns always escape a prefix-glob allow list. The design
  doc (§4) establishes this plainly: partial allow lists reduce wedge
  frequency but do not eliminate it.
- **Destructive operations must have a human backstop.** Accidental `rm -rf`,
  `git push --force`, or remote-ref deletion by a confused subagent is a
  recoverable but disruptive event. The customer's directive: route all
  destructive work through `tech-lead` as an explicit duty, not as a
  permission-layer inference.
- **The hook layer is the primary enforcement tier.** Three deny-hooks
  (`customer-notes-guard.py`, `tech-lead-authoring-guard.py`,
  `handoff-pre-tool-gate.py`) enforce path scope, authoring rules, and
  CUSTOMER_NOTES.md integrity regardless of `permissions` settings. A
  `permissions.allow: Bash(*)` removes the human checkpoint but does not
  disable hook-based denies.
- **`rm` cannot be denied at the permission layer.** The release scripts
  (`pre-release-gate.sh`, `smoke-test.sh`, `worktree-teardown.sh`, and
  others) use `rm -rf` in `trap ... EXIT` handlers for temp-dir cleanup. A
  `deny` on `Bash(rm*)` would break these scripts. The `rm` residual is
  accepted under the trusted-specialist threat model and the duty statement.
- **Precedent: `defaultMode: acceptEdits`.** v1.5.3 (FW-ADR-0029) already
  accepted that all Edit / Write / MultiEdit subagent calls proceed without a
  human prompt. `Bash(*)` extends the same principle to the Bash tool.

---

## Considered options (Three-Path Rule, binding)

### Option M — Minimalist: targeted allow list

Allow only the specific Bash command prefixes that routinely fire and are
judged safe (git read ops, grep/cat/find, pytest, bash scripts/*, gh
subcommands, etc.). Everything else still prompts — and wedges on remote
control for any uncovered pattern.

- **Sketch:** Add ~30 `Bash(<prefix>*)` entries to `permissions.allow`
  covering the commands enumerated in the design doc §2 Option A. No deny
  entries. No duty statement. The human checkpoint on uncovered commands
  (compound forms, new scripts, project-specific patterns) remains.
- **Pros:**
  - Provides explicit human checkpoints for anything not on the list.
  - Shorter permission block, easier to read.
  - No change to the existing governance model — destructive operations
    that escape the prefix matching still prompt.
- **Cons:**
  - Does not solve the wedge problem. Compound commands (`cd /tmp && pytest`),
    shell built-ins, subshell forms, and any unanticipated script remain
    uncovered. Remote-control deployments still wedge on those patterns.
  - The targeted list provides false assurance: once `Bash(bash scripts/*)`,
    `Bash(git push*)`, and `Bash(gh release*)` are included — which they
    must be for routine operations — the meaningful security delta over
    `Bash(*)` collapses to protecting only bare `rm` and `curl`. The design
    doc §3.4 establishes this quantitatively.
  - Drift risk: every new script added to `scripts/`, every new agent Bash
    pattern, and every downstream project's custom scripts require allow-list
    maintenance. A missed entry wedges production use.
- **When M wins:** if the customer required human checkpoints on specific Bash
  families as a hard workflow requirement, or if remote-control deployment were
  not a priority. Neither holds here.

### Option S — Scalable: broad Bash(*) with no deny

Allow all Bash commands unconditionally via a single `Bash(*)` entry. Rely
entirely on the hook layer (three deny-hooks) and agent contract text for
enforcement. No `deny` entries; no explicit duty statement beyond existing
Hard Rules.

- **Sketch:** Replace or add to `permissions.allow` with `["Bash(*)"]` only.
  No `deny` array. The three existing deny-hooks remain the sole enforcement
  layer. Agent contracts instruct agents not to run destructive commands.
- **Pros:**
  - Single-line allow entry; no maintenance surface.
  - Fully eliminates the remote-control Bash wedge.
  - Hook layer (which operates independently of `permissions`) continues to
    enforce path-scope, authoring rules, and customer-notes integrity.
- **Cons:**
  - No permission-layer backstop for the most dangerous operations:
    `git push --force`, `git push --delete`, `git push --mirror`,
    `git reset --hard`, `git clean -f`, `rm`, `sudo`, `dd`, `mkfs`,
    `shred`, `truncate`, `chmod 777`. If a confused subagent emits any of
    these, nothing at the permission layer catches it.
  - No formal architectural statement that destructive operations are a
    tech-lead duty. The constraint lives only in agent prose, which the
    customer's directive explicitly elevates to a Hard Rule.
  - Misses the customer's ratified direction: "all destructive work should
    run through the tech lead as a declared duty." Option S satisfies the
    technical requirement but not the governance requirement.
- **When S wins:** if the governance statement were considered unnecessary
  given the hook layer and agent contracts. The customer directive of
  2026-06-23 rules this out.

### Option C — Creative / hybrid: Bash(*) allow with targeted deny list and duty statement

Allow all Bash commands via `Bash(*)` to eliminate the remote-control wedge
entirely, then add a small `deny` list covering operations that are both
genuinely destructive and never legitimately emitted by a framework
specialist. Simultaneously codify a Hard Rule (rule #13) and a `tech-lead.md`
duty statement making destructive-ops routing an explicit architectural
constraint, not merely a prose guideline.

- **Sketch:** Set `permissions.allow: ["Bash(*)"]` and `permissions.deny`
  to the 18-entry union list (see Decision outcome below). Add CLAUDE.md
  Hard Rule #13 and a `## Destructive Bash duty` section to `tech-lead.md`.
  The deny list is the permission-layer backstop; the duty statement is the
  primary governance control; the hook layer is the independent third tier.
- **Pros:**
  - Fully eliminates the remote-control Bash wedge (same as Option S).
  - Provides a permission-layer backstop for the most dangerous operations in
    their most naive/accidental forms.
  - The duty statement (Hard Rule #13) elevates the constraint to the same
    structural tier as the other Hard Rules — it is binding on all agents, not
    advisory prose.
  - Deny list is small (18 entries), admission-criteria-gated (genuinely
    destructive, never legitimate for a specialist, expressible as a prefix
    glob), and requires no maintenance for the covered categories.
  - The three-tier model (duty statement primary, deny list defense-in-depth,
    hook layer independent) is explicit and auditable.
- **Cons:**
  - The deny list is a coarse backstop only. Compound commands, piped
    invocations, and reversed-argument forms evade prefix-glob matching
    (see Residual-risk note below). This is a known and accepted limitation.
  - Adds a `deny` array to `settings.json` — a new key that downstream
    projects must be aware of on upgrade. The upgrade script deep-merges;
    semantic conflicts with project-local deny entries require per-project
    review.
  - `rm` is in the deny list (following the customer's principle), which
    means the release scripts' `trap ... EXIT` cleanup handlers are blocked
    when invoked directly as subagent Bash commands. Mitigation: tech-lead
    runs release scripts from the main session (bypass mode); subagents invoke
    them indirectly via higher-level dispatch rather than direct Bash.
- **When C wins:** when the customer's governance directive requires a formal
  architectural constraint on destructive-ops routing, and the permission-layer
  backstop (even coarse) adds observable value over relying on the hook layer
  and prose contracts alone. Both conditions hold here per the 2026-06-23
  customer ratification.

---

## Decision outcome

**Chosen option: C — hybrid `Bash(*)` allow with targeted deny list and duty
statement.**

Option M does not solve the wedge problem and was not presented to the
customer as a viable option given the remote-control deployment requirement.
Option S satisfies the technical requirement but not the customer's governance
directive of 2026-06-23. Option C satisfies both: it eliminates the wedge,
provides a coarse permission-layer backstop for the most dangerous operations,
and elevates the destructive-ops routing constraint to a binding Hard Rule.
The known limitation (coarse prefix-glob matching) is accepted under the
trusted-specialist threat model (specialists are the team's own agents; the
concern is accidental misuse, not adversarial bypasses).

### Ratified configuration (copy-ready)

The exact `permissions` block for `sw-dev-team-template/.claude/settings.json`
(and the meta-project `settings.json` union, per design doc §9.1):

```json
"permissions": {
  "defaultMode": "acceptEdits",
  "allow": [
    "Bash(*)"
  ],
  "deny": [
    "Bash(sudo *)",
    "Bash(dd *)",
    "Bash(mkfs *)",
    "Bash(shred *)",
    "Bash(truncate *)",
    "Bash(rm *)",
    "Bash(chmod 777 *)",
    "Bash(git reset --hard*)",
    "Bash(git clean -f*)",
    "Bash(git checkout -- *)",
    "Bash(git restore --*)",
    "Bash(git branch -D *)",
    "Bash(git push --force*)",
    "Bash(git push --force-with-lease*)",
    "Bash(git push -f *)",
    "Bash(git push -f)",
    "Bash(git push --delete*)",
    "Bash(git push --mirror*)"
  ]
}
```

**18 deny entries** in four category groups: privilege escalation (`sudo`);
disk / storage destruction (`dd`, `mkfs`, `shred`, `truncate`, `rm`,
`chmod 777`); destructive local git operations (`git reset --hard`,
`git clean -f`, `git checkout --`, `git restore --`, `git branch -D`);
destructive remote git operations (`git push --force`, `--force-with-lease`,
`-f`, `--delete`, `--mirror`).

Entry-by-entry rationale for every entry is in the design doc §§8.2 and 9.2.
Candidates considered and rejected (including `curl`, `wget`, `kill`,
`git tag -d`, `git push --tags`) are in the design doc §9.3.

`deny` takes precedence over `allow` per Claude Code's documented permission
semantics. A matching `deny` blocks regardless of `Bash(*)` in `allow`.

### Hard Rule #13 duty statement

Codified in `CLAUDE.md` § "Hard rules" as rule #13:

> Destructive Bash operations are a tech-lead duty. The `deny` list in
> `.claude/settings.json` blocks the most obvious destructive Bash commands
> (disk destruction, privilege escalation, destructive git operations) for all
> subagents. When a specialist determines that a destructive operation is
> required, it does not attempt the operation; it returns to `tech-lead` with
> a structured request naming the exact command and the justification.
> `tech-lead` performs the operation from the main session, which operates in
> bypass mode and is not subject to the `deny` list. This centralizes all
> destructive shell execution at the single supervised orchestrator. The `deny`
> list is a coarse backstop — compound commands, piped invocations, and
> reversed-argument forms can evade prefix-glob matching — so the duty
> statement is the primary control and the `deny` list is defense-in-depth.

The corresponding duty note in `.claude/agents/tech-lead.md`
§ "Destructive Bash duty":

> Destructive Bash duty. When a specialist returns a request for a destructive
> Bash operation (any command matching the deny list in `.claude/settings.json`,
> or any operation the specialist has flagged as irreversible), tech-lead
> evaluates the request, confirms the justification is sound, and executes the
> command from the main session. Tech-lead does not delegate destructive Bash
> operations back to a subagent. The main session's bypass mode is not a
> license for unsupervised destruction — tech-lead must review each request
> individually before executing.

---

## Consequences

### Positive

- Remote-control Bash wedge is fully eliminated. No subagent Bash call ever
  prompts; headless and MCP invocations complete without hanging.
- The 18 most dangerous command forms are blocked at the permission layer for
  all subagents in their most naive/accidental forms, providing a first-line
  catch against confused-agent behavior.
- Hard Rule #13 elevates the destructive-ops routing constraint to the same
  structural tier as all other Hard Rules — binding, not advisory.
- The three-tier enforcement model (duty statement → deny list → hook layer)
  is explicit and each tier is independently auditable.
- No drift risk on the allow side: `Bash(*)` requires no maintenance as
  agents gain new Bash patterns or projects add scripts.

### Negative / trade-offs accepted

- `rm` is in the deny list. The release scripts' temp-dir cleanup handlers
  (`trap 'rm -rf "$tmp"' EXIT` patterns in `pre-release-gate.sh`,
  `smoke-test.sh`, `worktree-teardown.sh`, and others) are blocked when
  these scripts are invoked as direct subagent Bash commands. Mitigation:
  tech-lead runs release scripts from the main session (bypass mode). This
  is a direct consequence of the customer's principle; accepted.
- Downstream projects receive the 18 deny entries on upgrade. Projects with
  project-local `permissions` configurations must verify no semantic conflict.
  Projects that rely on `git push --force` as a legitimate specialist
  operation (uncommon; no framework agent uses it) must override at the
  project level.
- The deny list adds a new `settings.json` key that the upgrade deep-merge
  must handle. The upgrade script's existing deep-merge strategy (per v1.5.3
  migration precedent) handles additive `deny` arrays without conflict.

### Residual-risk note

The deny list is a thin backstop constrained by Claude Code's coarse
prefix-glob matcher. The following evasion classes are not caught:

- **Compound commands where the destructive verb is not the leading token.**
  Example: `cd /tmp && rm -rf .` — the leading token is `cd`, not `rm`.
  The deny pattern `Bash(rm *)` does not match.
- **Bash-wrapped invocations.** Example: `bash -c "git push --force origin
  main"` — the leading token is `bash`, not `git push`.
- **Reversed-argument ordering.** Example: `git push origin main --force`
  evades `Bash(git push --force*)` because `--force` appears after the
  refspec. This is a real and unaddressed gap.
- **Subshell forms.** Example: `$(git push --force ...)` — the outer token
  is not `git push`.

The deny list therefore catches only the most naive and textbook forms of the
blocked operations — protection against confused/misdirected agents, not
against any agent constructing an evasion. Under the trusted-specialist threat
model (specialists are the team's own agents with no adversarial motivation),
this is judged sufficient. The primary control remains the duty statement:
the architectural constraint that destructive operations are categorically
routed through `tech-lead` rather than executed by subagents. Projects
requiring stronger containment should add hook-based command inspection
(a `PreToolUse` Bash hook parsing the command string with shell-grammar
awareness) and remote-side protections (GitHub branch protection rules,
required pull request reviews, tag protection rules) as independent backstops.

**Independent remote-side backstop recommendation:** Configure GitHub
branch protection on `main` (and any other protected branch) with required
pull request reviews and disallow force-pushes at the repository level. Add
tag protection rules to prevent force-pushing or deleting release tags. These
remote-side controls operate independently of the Claude Code permission
posture and provide a layer the deny list cannot: they catch the reversed-
argument and compound-command evasion classes that the prefix-glob matcher
misses, because GitHub evaluates the resulting git operation, not the command
string that produced it.

### Follow-up ADRs

- A superseding ADR is expected if upstream Claude Code adds shell-grammar-
  aware deny matching (non-prefix-glob). At that point the 18 coarse entries
  can be replaced with more precise patterns that close the compound-command
  and reversed-argument gaps.
- If `rm` usage in release scripts becomes a recurring operational friction
  point (tech-lead regularly running cleanup scripts manually), a follow-up
  ADR may introduce a scoped `rm` exception covering only the temp-dir
  patterns used in trap handlers (e.g., paths under `/tmp/swdt-*` or
  `/tmp/agent-*`).

---

## Verification

- **Success signal:** Subagents running under remote control (MCP
  tool-bridge, headless CI) complete Bash-bearing tasks without prompting or
  hanging. The 18 deny-list patterns are blocked when a confused subagent
  emits one in its naive/textbook form — observable by injecting a test
  invocation and confirming the permission deny fires.
- **Failure signal (wedge recurrence):** Any remote-control session hangs
  on a Bash prompt. Indicates a compound-command or other evasion of `Bash(*)`
  that Claude Code is treating as a distinct permission event — escalate
  upstream.
- **Failure signal (operational friction):** Tech-lead is frequently
  manually running `rm`-bearing release scripts because subagents cannot.
  Indicates the `rm` deny is creating more friction than it prevents; triggers
  the scoped-exception follow-up ADR.
- **Failure signal (deny evasion):** A subagent successfully executes a
  force-push, remote-ref deletion, or disk-destruction command via compound
  or wrapped form. Confirms the gap documented in the residual-risk note;
  escalate to hook-based command inspection.
- **Review cadence:** First session of each calendar quarter. Check whether
  any of the three failure signals fired and whether upstream Claude Code
  permission-matching has improved beyond prefix-glob. If the remote-side
  backstop (branch/tag protection) has not been configured, flag it.

---

## Links

- Design doc (full threat-model analysis, option sketches, entry-by-entry
  rationale, honest limitations):
  `docs/pm/v1.5.4-subagent-permission-posture-design.md`
- Prior ADR (agent-teams drop; establishes permission-inheritance context):
  FW-ADR-0029 (`docs/adr/fw-adr-0029-drop-experimental-agent-teams-flag.md`)
- Hard Rule #13 source: `CLAUDE.md` (scaffold) § "Hard rules" rule 13
- Duty statement source: `.claude/agents/tech-lead.md` § "Destructive Bash
  duty"
- Settings file modified: `.claude/settings.json`
- Customer ratification: 2026-06-23, recorded in `CUSTOMER_NOTES.md` by
  `librarian`
- FW-ADR-0012 — tech-lead-authoring-guard (hook layer precedent; one of the
  three independent deny-hooks that operate regardless of `permissions`
  settings)
- FW-ADR-0008 — tech-lead orchestration boundary (architectural principle
  this ADR's duty statement extends to the Bash execution layer)
- Upstream Claude Code bugs #355 and #356 (remote-control prompt routing
  failure; permission-mode inheritance failure — root cause addressed by
  FW-ADR-0029; residual Bash wedge addressed here)
