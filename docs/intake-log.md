# Intake Log — SWEProj

---
turn: 1
timestamp: 2026-05-12T19:51Z
asked-by: tech-lead
framing: |
  Customer provided guidance on the correct Spec Kit integration model for a
  scaffolded sw-dev-team-template project, clarifying that the main session is
  already tech-lead and Spec Kit should be treated as a subordinate workflow
  tool whose output remains draft material until governed by tech-lead.
options-presented: []
recommended-default: none
agents-running-at-ask: []
customer-answer: |
  Correct. In an already scaffolded `sw-dev-team-template` project, the **main session is already `tech-lead`**, so Spec Kit does not need to become its own intake authority.

  That changes the integration framing.

  # Revised model

  Instead of:

  ```text
  Spec Kit must be wrapped so it cannot bypass tech-lead
  ```

  Use:

  ```text
  tech-lead invokes Spec Kit as a planning/specification tool
  ```

  The guardrail is not “prevent Spec Kit from talking to the user” in the abstract. The guardrail is:

  ```text
  tech-lead must treat Spec Kit output as candidate work product,
  not as automatically customer-facing output or final authority.
  ```

  # Practical implication

  If you call Spec Kit from the scaffolded project, the flow is:

  ```text
  customer → tech-lead main session
  tech-lead → Spec Kit workflow
  Spec Kit → draft spec / clarify candidates / plan / tasks / analysis
  tech-lead → routes to agents or asks customer atomically
  ```

  So yes: the **default interface remains tech-lead**.

  # What still needs protection

  Even with tech-lead as caller, Spec Kit can still generate things that would be unsafe to pass through directly:

  ```text
  - compound clarification questions
  - multi-choice bundles
  - plans that skip architect / QA / code-reviewer
  - tasks that modify framework-managed files during product work
  - implementation steps that bypass specialist routing
  - duplicate truth surfaces
  ```

  So the rule should be:

  ```text
  Spec Kit output is draft material.
  tech-lead adjudicates, routes, atomizes, and records.
  ```

  # Plan adjustment

  The implementation plan should say this more cleanly:

  ```md
  ## Spec Kit Invocation Model

  In a scaffolded sw-dev-team-template project, the main harness session
  already plays `tech-lead`.

  Therefore, Spec Kit is invoked by `tech-lead` as a subordinate workflow
  tool for:

  - feature specification
  - clarification discovery
  - technical planning
  - task generation
  - consistency analysis
  - optional task-to-issue conversion

  Spec Kit does not introduce a new human interface. Its outputs are
  candidate artifacts that `tech-lead` routes through the existing agent
  system.
  ```

  Then add:

  ```md
  ## Spec Kit Output Handling

  When Spec Kit produces clarification questions, `tech-lead` must:

  1. classify each question as agent-owned or customer-owned;
  2. route agent-owned questions to the appropriate specialist;
  3. split customer-owned questions into atomic rows in `docs/OPEN_QUESTIONS.md`;
  4. ask at most one customer-owned question per turn;
  5. ensure all agents and tool calls are idle before asking;
  6. record answers through the existing intake / researcher / CUSTOMER_NOTES flow.
  ```

  And:

  ```md
  ## Spec Kit Implementation Boundary

  Do not allow raw Spec Kit implementation output to bypass sw-dev roles.

  Generated tasks must still route through:

  - `architect` for structural decisions / ADRs
  - `software-engineer` for code
  - `qa-engineer` for test strategy and acceptance
  - `code-reviewer` before commit
  - `project-manager` for schedule/risk/change reconciliation
  - `release-engineer` for release mechanics
  ```

  # Slash commands vs skills, revised

  Given your clarification, I would phrase it as:

  ```text
  Tech-lead may invoke whichever Spec Kit surface is available:
  slash command, skill, or wrapper command.

  But the sw-dev contract governs how the output is used.
  ```

  So the plan does **not** need to forbid slash commands. It should say:

  ```md
  Spec Kit invocation surface is harness-specific.

  Allowed:
  - `/speckit.*` slash commands
  - `$speckit-*` skills
  - OpenCode skills
  - generated sw-dev wrapper commands

  Required:
  - output returns to tech-lead for routing and gate enforcement
  ```

  # Final adjustment

  Your point is right: in the scaffolded-project context, the main risk is **not** that Spec Kit becomes the user interface.

  The main risk is that tech-lead treats Spec Kit output as already-approved.

  So the correct rule is:

  ```text
  Spec Kit may generate.
  tech-lead must govern.
  ```

  That is the line I would put into the plan.
decision: Spec Kit is subordinate draft-generation workflow invoked by tech-lead; tech-lead governs routing, atomization, role gates, and customer-facing use.
cross-refs:
  - CUSTOMER_NOTES.md#2026-05-12-spec-kit-tech-lead-governance
notes: Customer provided this as guidance during M2 implementation; researcher records the durable customer-notes entry.
---
turn: 2
timestamp: 2026-05-13T15:23Z
asked-by: tech-lead
framing: |
  Tech-lead misidentified the active repository location and treated
  `/home/quackdcs/SWEProj` as the work target instead of recognizing
  the project-specific meta/worktree split.
options-presented: []
recommended-default: none
agents-running-at-ask: []
customer-answer: |
  HOLY SHIT THIS NEEDS TO BE IN THE INFO FOR THIS DIRECTORY: this is the meta-project to improve sw-dev-team-template. All work happens in ./sw-dev-team-template

  this was already known and somehow got lost.
decision: SWEProj is the meta-project for improving sw-dev-team-template; work target is `./sw-dev-team-template`, and active directory instructions must state that explicitly.
cross-refs:
  - CUSTOMER_NOTES.md#2026-05-13-sweproj-meta-project-working-tree
notes: Customer correction after repo-location drift; prior repo docs already contained this fact, but active entrypoint instructions did not make it explicit enough.
---
turn: 3
timestamp: 2026-06-13T14:15Z
asked-by: tech-lead
framing: |
  Tech-lead requested customer authorization to spawn native specialist agents
  for the current session to address GitHub issue #350 in `sw-dev-team-template`.
options-presented: []
recommended-default: none
agents-running-at-ask: []
customer-answer: |
  yes
decision: Customer authorized spawning native specialist agents for the current session to address GitHub issue #350.
cross-refs:
  - CUSTOMER_NOTES.md#2026-06-13-spawn-authorization-issue-350
notes: Customer approved the request during the session.

