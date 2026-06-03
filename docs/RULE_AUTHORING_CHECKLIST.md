# Rule Authoring Checklist

<!-- TOC -->

- [Status](#status)
- [When to use this checklist](#when-to-use-this-checklist)
- [Anti-proliferation concern](#anti-proliferation-concern)
- [Checklist](#checklist)
  - [1. Is a new rule necessary?](#1-is-a-new-rule-necessary)
  - [2. Enforcement](#2-enforcement)
  - [3. Testability](#3-testability)
  - [4. Placement and mirrors](#4-placement-and-mirrors)
  - [5. Wording](#5-wording)
  - [6. Before opening a PR](#6-before-opening-a-pr)
- [Where hard rules live](#where-hard-rules-live)

<!-- /TOC -->

## Status

**Non-binding guidance.** This document is NOT a hard rule. It is a checklist
reminding anyone authoring a new hard rule or binding policy to think through
enforcement before adding it. Failing to follow this checklist does not itself
constitute a framework violation. The Hard Rules that already exist — located
in `CLAUDE.md` § "Hard rules" — remain binding regardless.

This checklist was introduced in response to the Q-0018 anti-proliferation
concern: adding rules that cannot be enforced increases compliance theater
without improving behavior.

---

## When to use this checklist

Work through it before proposing any addition to `CLAUDE.md` § "Hard rules",
any binding policy in an agent contract (`.claude/agents/*.md`), or any
"binding" declaration in a framework document.

---

## Anti-proliferation concern

Every new hard rule imposes a maintenance cost and a reading burden. Rules
that are unenforceable or redundant dilute the authority of rules that are
enforced. Before adding one, ask whether guidance — something a reasonable
practitioner would follow without a gate — would achieve the same outcome.

Customer ruling Q-0018 established this concern. It is the reason this
document is guidance rather than a rule.

---

## Checklist

### 1. Is a new rule necessary?

- [ ] Does an existing rule already cover this case? Check `CLAUDE.md`
      § "Hard rules" (all eleven current rules) before drafting a new one.
- [ ] Could this be guidance or a template convention instead of a binding
      rule? If the failure mode is "someone forgot," guidance may be enough.
      If the failure mode is "someone will actively skip this and it causes
      harm," a rule (with enforcement) is warranted.
- [ ] Does the proposed rule duplicate wording that already appears in an
      agent contract? If so, the contract is the right home; amending a
      central binding document for agent-specific behavior adds drift risk.

### 2. Enforcement

Answer all three before proceeding:

- [ ] **What enforces this rule?** Name the mechanism: CI gate, pre-commit
      hook, lint script, mandatory review step, or review-only (no
      automation). "We will remember to do it" is not enforcement.
- [ ] **Who owns the enforcement artifact?** Name the agent
      (`release-engineer` for CI, `qa-engineer` for test gates,
      `software-engineer` for scripts, etc.). Unowned enforcement artifacts
      rot.
- [ ] **What happens when the gate fires?** Is it a hard block (CI fails,
      PR cannot merge) or a soft warning? Hard rules warrant hard blocks.
      Soft warnings belong in guidance.

If you cannot answer all three, the proposed rule is not ready. Either design
enforcement first, or downgrade to guidance.

### 3. Testability

- [ ] Can a test or lint check distinguish a compliant artifact from a
      non-compliant one without human interpretation? If not, the rule
      cannot be enforced automatically and relies entirely on review.
- [ ] Does a test for this rule already exist? If so, cite it. If not, who
      writes it and in which PR?

### 4. Placement and mirrors

- [ ] Where does the rule live? (`CLAUDE.md` § "Hard rules" is for
      team-wide invariants; agent contracts are for role-specific behavior;
      framework docs are for process detail.)
- [ ] Which mirrors must regenerate? Agent contracts in
      `.claude/agents/*.md` have runtime mirrors. Any edit to those files
      requires the mirrors to be regenerated in the same commit; else
      agent-contract CI fails. Name which mirror generation step applies.
- [ ] Does the rule appear in more than one location (canonical + mirrors)?
      Identify the canonical home and every mirror. Record the canonical
      wording once; reference it elsewhere — do not duplicate the prose.

### 5. Wording

- [ ] Is the rule phrased as an observable, checkable condition? Vague
      rules ("be careful," "consider X") cannot be enforced.
- [ ] Does the rule reference the enforcement artifact by name (script path,
      CI job name, hook name)?
- [ ] If the rule has an exception or escape hatch, is the escape hatch
      documented and itself auditable?

### 6. Before opening a PR

- [ ] At least one agent other than the author has reviewed the proposed
      rule and its enforcement design.
- [ ] The PR description states: the rule text, the enforcement mechanism,
      the owner of the enforcement artifact, and which mirrors regenerate.
- [ ] If the rule is Hard Rule #4 or #7 scope (safety-critical, auth/authz,
      secrets, PII, network-exposed), customer sign-off is recorded in
      `CUSTOMER_NOTES.md` before merge.

---

## Where hard rules live

The canonical hard-rules list is `CLAUDE.md` § "Hard rules" (currently 11
rules; this file is at the repo root from a downstream project's perspective,
and at `sw-dev-team-template/CLAUDE.md` from the meta-project). Both the
upstream template copy and any scaffolded downstream copy must stay in sync;
divergence is a framework defect.

Agent-specific behavioral rules live in the relevant `.claude/agents/*.md`
file, not in the central hard-rules list, unless the behavior is team-wide.
