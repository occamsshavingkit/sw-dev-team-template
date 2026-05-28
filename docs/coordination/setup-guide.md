# Coordination interface setup guide

<!-- TOC -->

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step 1 — Create labels](#step-1--create-labels)
  - [Status labels](#status-labels)
  - [Role labels](#role-labels)
  - [Priority labels](#priority-labels)
  - [Meta labels](#meta-labels)
- [Step 2 — Create a milestone](#step-2--create-a-milestone)
- [Step 3 — Confirm issue templates](#step-3--confirm-issue-templates)
- [Step 4 — Verify](#step-4--verify)
- [Opt-out note](#opt-out-note)

<!-- /TOC -->

## Overview

This guide bootstraps the coordination interface for a downstream repo: label
set, milestone convention, and issue templates. All commands use the GitHub
CLI (`gh`). Run them once per repo, from any machine with `gh` authenticated
against that repo.

This interface is **opt-in**. A project that skips this setup runs the normal
single-operator agent workflow unchanged. Nothing in the framework requires
these labels, milestones, or templates. See [Opt-out note](#opt-out-note).

---

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status`).
- Current repo set as the default (`gh repo set-default` or run from within
  the cloned directory so `gh` resolves `--repo` automatically).
- The repo's `.github/ISSUE_TEMPLATE/` directory contains `agent-task.yml`
  and `agent-review-request.yml` (scaffolded from the template).

---

## Step 1 — Create labels

Copy and run each block. The `--force` flag updates an existing label if it
was created with a different color or description; it is safe to run twice.

### Status labels

```sh
gh label create "status:queued"       --color "d1d5db" --description "Available to claim. No operator holds it." --force
gh label create "status:claimed"      --color "fde68a" --description "Advisory checkout posted; claim sequence ran. Operator is self-assigned." --force
gh label create "status:in-progress"  --color "3b82f6" --description "Claimed and actively being worked." --force
gh label create "status:in-review"    --color "8b5cf6" --description "Handed to review." --force
gh label create "status:blocked"      --color "b60205" --description "Cannot proceed. Pair with meta:blocked-external or a BLOCKED comment." --force
gh label create "status:done"         --color "6ee7b7" --description "Completed. Evidence gates satisfied via the durable handoff." --force
```

> Note: status-label colors are advisory and cosmetic. Downstream projects may recolor to match their conventions without affecting protocol behavior.

Status is **single-valued**. Remove the old `status:*` label before applying
a new one. See `docs/coordination/label-taxonomy.md` for the full state
machine.

### Role labels

One label per canonical roster role. Attach the label matching the role
responsible for current work. Missing or conflicting `role:*` labels trigger
needs-triage handling.

```sh
gh label create "role:tech-lead"          --color "c5def5" --description "Tech Lead + orchestrator." --force
gh label create "role:project-manager"    --color "c5def5" --description "Project Manager." --force
gh label create "role:architect"          --color "c5def5" --description "Software Architect." --force
gh label create "role:software-engineer"  --color "c5def5" --description "Software Engineer." --force
gh label create "role:researcher"         --color "c5def5" --description "Researcher / librarian." --force
gh label create "role:qa-engineer"        --color "c5def5" --description "QA / Test Engineer." --force
gh label create "role:sre"                --color "c5def5" --description "SRE + Performance Engineer." --force
gh label create "role:tech-writer"        --color "c5def5" --description "Technical Writer." --force
gh label create "role:code-reviewer"      --color "c5def5" --description "Code Reviewer + Auditor." --force
gh label create "role:release-engineer"   --color "c5def5" --description "Build + Release Engineer." --force
gh label create "role:security-engineer"  --color "c5def5" --description "Security Engineer." --force
```

Note: `onboarding-auditor`, `process-auditor`, and `sme-<domain>` agents are
per-project and one-shot. Route their issues through the owning canonical
role per the agent roster.

### Priority labels

```sh
gh label create "priority:p0" --color "b60205" --description "Drop everything. Immediate action required." --force
gh label create "priority:p1" --color "e99695" --description "High — current sprint / next available slot." --force
gh label create "priority:p2" --color "f9d0c4" --description "Normal — scheduled work." --force
gh label create "priority:p3" --color "fef2c0" --description "Whenever — low urgency, no schedule pressure." --force
```

### Meta labels

Meta labels are additive — multiple may apply simultaneously.

```sh
gh label create "meta:framework-maintenance"        --color "d4c5f9" --description "Work targets the template framework, not a downstream product." --force
gh label create "meta:customer-approval-required"   --color "d4c5f9" --description "Hard Rule #4 applies; live customer sign-off required before completion." --force
gh label create "meta:security-review-required"     --color "d4c5f9" --description "Hard Rule #7 applies; security-engineer sign-off required." --force
gh label create "meta:blocked-external"             --color "d4c5f9" --description "Blocker is outside the team. Pair with status:blocked." --force
```

---

## Step 2 — Create a milestone

One milestone per release semver tag. Milestone names match the version tag
exactly (e.g., `v1.1.0`). Issues targeted at a release carry that milestone.

Create milestones via `gh api`:

```sh
# Replace v1.1.0 and the due-on value with your target version and date.
gh api repos/{owner}/{repo}/milestones \
  --method POST \
  --field title="v1.1.0" \
  --field description="Issues targeted at the v1.1.0 release." \
  --field due_on="2026-06-30T00:00:00Z"
```

Or via `gh milestone create` if your `gh` version supports that extension:

```sh
gh milestone create --title "v1.1.0" --description "Issues targeted at the v1.1.0 release."
```

Repeat for each release semver tag. Issues that span multiple releases should
be split; one issue maps to one durable handoff. See
`docs/coordination/multi-operator-model.md`.

---

## Step 3 — Confirm issue templates

The framework scaffolds two issue templates into `.github/ISSUE_TEMPLATE/`.
Confirm they are present before filing coordination issues:

```sh
test -f .github/ISSUE_TEMPLATE/agent-task.yml \
  && echo "agent-task.yml present" \
  || echo "MISSING: agent-task.yml"

test -f .github/ISSUE_TEMPLATE/agent-review-request.yml \
  && echo "agent-review-request.yml present" \
  || echo "MISSING: agent-review-request.yml"
```

If either file is missing, the repo was scaffolded from a template version
that predates the coordination interface. Copy the missing file(s) from
`sw-dev-team-template/.github/ISSUE_TEMPLATE/` manually — this is a
one-time copy, not a template-internal edit.

---

## Step 4 — Verify

List all labels to confirm the full set was created:

```sh
gh label list --limit 100
```

Expected output includes all `status:*`, `role:*`, `priority:*`, and
`meta:*` entries from this guide. A quick count check:

```sh
gh label list --limit 100 | grep -c '^status:\|^role:\|^priority:\|^meta:'
```

Expected count: 6 status + 11 role + 4 priority + 4 meta = **25 labels**.

List milestones:

```sh
gh api repos/{owner}/{repo}/milestones | jq '.[].title'
```

---

## Opt-out note

This entire setup is opt-in. A downstream project that does not run this
guide operates normally under the single-operator workflow. The agent set,
claim protocol, durable handoffs, and all in-repo registers function without
GitHub issues, labels, milestones, or the claim convention.

Nothing in the framework checks for the presence of these labels at runtime.
The coordination interface activates only when an operator explicitly files
issues and uses the claim protocol in `docs/coordination/claim-protocol.md`.

A project that skips setup incurs no errors, no missing-state warnings, and
no required coordination actions.
