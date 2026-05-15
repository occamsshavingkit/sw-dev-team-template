# Retrofit Playbook — adopting `sw-dev-team-template` into an existing codebase

<!-- TOC -->

- [1. Scope and pinned flow](#1-scope-and-pinned-flow)
  - [1.1 In scope](#11-in-scope)
  - [1.2 Out of scope](#12-out-of-scope)
  - [1.3 Preconditions (binding)](#13-preconditions-binding)
- [2. Decision record — scaffold-first vs in-place (pinned)](#2-decision-record--scaffold-first-vs-in-place-pinned)
  - [2.1 The four adoption paths](#21-the-four-adoption-paths)
  - [2.2 Side-by-side vs in-place — the explicit ruling](#22-side-by-side-vs-in-place--the-explicit-ruling)
  - [2.3 `scripts/repair-in-place.sh` is not a retrofit tool](#23-scriptsrepair-in-placesh-is-not-a-retrofit-tool)
  - [2.4 Interstitial cases](#24-interstitial-cases)
- [3. Hard rules specific to retrofit](#3-hard-rules-specific-to-retrofit)
- [4. Roles and stage order](#4-roles-and-stage-order)
  - [4.1 Pre-flight — readiness triage](#41-pre-flight--readiness-triage)
  - [4.2 Stage A — `onboarding-auditor` inventory](#42-stage-a--onboarding-auditor-inventory)
  - [4.3 Stage B — `researcher` IP triage](#43-stage-b--researcher-ip-triage)
  - [4.4 Stage C — `architect` structural migration plan](#44-stage-c--architect-structural-migration-plan)
  - [4.5 Stage D — `project-manager` charter reconstruction](#45-stage-d--project-manager-charter-reconstruction)
  - [4.6 Stage E — `software-engineer` execution, `code-reviewer` gate (+ conditional `security-engineer`)](#46-stage-e--software-engineer-execution-code-reviewer-gate--conditional-security-engineer)
  - [4.7 Stage F — `project-manager` ticket migration (optional)](#47-stage-f--project-manager-ticket-migration-optional)
  - [4.8 Remote disposition decision (conditional)](#48-remote-disposition-decision-conditional)
- [5. Stage gates](#5-stage-gates)
- [6. Decision matrix — per-artifact outcomes](#6-decision-matrix--per-artifact-outcomes)
- [7. Handling pre-existing conventions that conflict with template defaults](#7-handling-pre-existing-conventions-that-conflict-with-template-defaults)
- [8. IP triage protocol](#8-ip-triage-protocol)
  - [8.1 Nested sibling git repositories (issue #53)](#81-nested-sibling-git-repositories-issue-53)
- [9. Migration of existing issues / tickets](#9-migration-of-existing-issues--tickets)
- [10. Register population — summary](#10-register-population--summary)
- [11. `docs/retrofit/` directory](#11-docsretrofit-directory)
- [12. Rollback plan](#12-rollback-plan)
- [13. Anti-patterns](#13-anti-patterns)
- [14. Exit criteria / Definition of Done](#14-exit-criteria--definition-of-done)
- [15. Related artifacts](#15-related-artifacts)
- [16. Change log](#16-change-log)

<!-- /TOC -->

**Introduced in:** v0.13.0 (MINOR; additive — introduces
`docs/templates/retrofit-playbook-template.md` and amends
`tech-lead.md` routing).
**Maintainer:** `tech-lead`.
**Origin:** Customer ruling 2026-04-23 (`CUSTOMER_NOTES.md`, §
"Retrofit adoption flow"); upstream issue #3; ROADMAP.md v0.13.0
roll-up.

> **Not a script.** Retrofit is an **agent workflow** driven by the
> contents of the source project. A script would assume a fixed
> shape; real source projects do not have one. See
> `scripts/scaffold.sh`, `scripts/repair-in-place.sh`, and
> `scripts/upgrade.sh` for the three script-covered cases — this
> playbook covers the fourth (existing-codebase adoption) and is
> deliberately not scripted.

---

## 1. Scope and pinned flow

### 1.1 In scope

- Adopting `sw-dev-team-template` into an **existing, non-scaffolded
  codebase** (`<src-path>`) by producing a **fresh scaffold**
  (`<tgt-path>`) and migrating `<src-path>`'s contents across on an
  audit-driven basis.
- Populating the target's registers (`CUSTOMER_NOTES.md`,
  `docs/pm/CHARTER.md`, `docs/pm/RISKS.md`, `docs/OPEN_QUESTIONS.md`,
  `docs/tasks/`, SME inventories) from evidence in `<src-path>`.
- Migrating the source's existing issue / ticket inventory into
  `docs/tasks/` and `docs/OPEN_QUESTIONS.md`.
- Recording the retrofit itself as PMBOK change `CH-0001` in
  `docs/pm/CHANGES.md`.

### 1.2 Out of scope

- **Multi-source retrofit** (N→1). Deferred to v0.16+ (issue #45).
  Three reshapes required before proper support: (a) per-source
  `docs/retrofit/src-N/` subdirectories; (b) a CHARTER-inception-date
  tie-breaker for cross-source git-log inference; (c) `CHANGES.md`
  numbering convention `CH-0001` … `CH-000N` with cross-referencing.
  Until then, sequential-per-source (with merges as ADRs) is
  best-effort only.
- **Retrofit-in-place** (convert `<src-path>` itself into a
  template-shaped project). See § 2 for the ruling.
- **Concurrent work on the source during the retrofit.** Source is
  frozen (§ 3.2); customer has agreed not to resume source-side work
  after the retrofit completes.

### 1.3 Preconditions (binding)

Before the playbook starts:

- `<src-path>` exists and is readable.
- Customer has stated the source path to `tech-lead` and confirmed
  source-freeze.
- `scripts/scaffold.sh <tgt-path> "<project-display-name>"` has
  produced `<tgt-path>` with `TEMPLATE_VERSION` stamped.
- FIRST ACTIONS Step 0 (issue-feedback opt-in) and Step 1 (skill-pack
  menu) have run in `<tgt-path>`, **OR** the retrofit absorbs them as
  the first actions of pre-flight (issue #51). In the absorbed case
  (the ergonomic default for existing-codebase customers who invoke
  retrofit before forming a FIRST ACTIONS mental model): `tech-lead`
  asks Step 0 atomically at session start; Step 1's skill-pack menu
  is **deferred until after pre-flight's go/no-go** so a tangential
  menu doesn't stall the retrofit.
- Step 2 scoping has begun in `<tgt-path>` but has **not** closed —
  the retrofit feeds Step 2's Definition-of-Done fields (CHARTER, SME
  classification, first milestone) with evidence from `<src-path>`,
  so closing Step 2 before the retrofit produces its findings is a
  sequencing error.

## 2. Decision record — scaffold-first vs in-place (pinned)

### 2.1 The four adoption paths

| Path | Script / playbook | When to pick |
|---|---|---|
| Fresh project | `scripts/scaffold.sh` | Greenfield; no existing code |
| Unzipped template | `scripts/repair-in-place.sh` | User unpacked the template archive *into* their empty project dir, wants it normalized |
| Upgrade | `scripts/upgrade.sh` | Existing scaffolded project wants a newer template version |
| **Retrofit (this playbook)** | *agent workflow* | **Existing, non-scaffolded codebase wants to adopt the template** |

### 2.2 Side-by-side vs in-place — the explicit ruling

Two mechanically plausible approaches:

- **A. Sibling scaffold (`<tgt-path>` ≠ `<src-path>`), selective
  merge.** Source is read-only; target is built fresh; agents
  discover source state and migrate artifacts on audit + triage.
  **This playbook covers Path A.**
- **B. In-place retrofit** (lay scaffolded files into `<src-path>`
  itself). Not supported.

**Customer ruling 2026-04-23 (verbatim, `CUSTOMER_NOTES.md`):**

> "The user scaffolds an empty directory then asks to migrate the
> project from its original directory. The agents have to figure out
> what is there and how they migrate it."

Why Path A over Path B: (1) **reversibility** — `rm -rf <tgt-path>`
restores the world, Path B needs `git reset --hard` against a state
that is often untagged; (2) **no file-shape collisions** — Path B
forces merge decisions before the team even has a charter;
(3) **audit-first is legible** — Path A forces `onboarding-auditor`
to inventory before anything moves; (4) **clean IP triage** —
`researcher` sees an uncontaminated source tree.

Customer-insisted Path B: explain the ruling; if they still insist,
record an ADR under `<tgt-path>/docs/adr/` superseding this
playbook's default, and proceed **only** after customer signs off on
losing reversibility.

### 2.3 `scripts/repair-in-place.sh` is not a retrofit tool

`scripts/repair-in-place.sh` covers a narrower case: a user unzipped
the template tarball *into* an otherwise-empty project directory and
needs the scaffold normalized (TEMPLATE_VERSION stamped, registers
reset). It does not audit, does not triage, does not preserve source
content. Do not invoke it against a populated source tree.

### 2.4 Interstitial cases

Some projects don't cleanly fit "fresh / unzipped / upgrade /
retrofit". Routing:

| Shape | Route |
|---|---|
| Half-scaffolded, Step 2 abandoned (no `CHARTER.md`, empty registers) | **Resume Step 2; do not retrofit.** Nothing has accreted that invalidates the scaffold. |
| Scaffold hand-edited with source code (committed against scaffold) | **Treat the hand-edited scaffold as `<src-path>` and retrofit into a fresh `<tgt-path>` — recursive retrofit.** Hand edits have lost the clean state; the audit re-establishes it. Do not "continue from where the scaffold left off." |
| External codebase imported into a scaffold tree (Path B in disguise) | **Extract the imported code to a sibling scratch dir, delete the scaffold, re-scaffold fresh, then retrofit normally with the sibling as `<src-path>`.** Do not separate template files from source files in-tree. |
| Partial upgrade in progress (`scripts/upgrade.sh` interrupted) | Upgrade concern, not retrofit. Resolve via the upgrade path (`--dry-run` + per-file conflict resolution). |
| Scaffold at older `TEMPLATE_VERSION`, hand-edited and drifted (#46) | One retrofit produces a clean result at the latest version (upgrade is implicit). To preserve the *old* version, record an ADR (usual reason: deferred upgrade as a separate `scripts/upgrade.sh` motion later). |

If the customer's shape matches none of the above and none of
§ 2.1's four paths, `tech-lead` escalates before proceeding — there
may be a template gap to file upstream (`docs/ISSUE_FILING.md`).

## 3. Hard rules specific to retrofit

1. **Source is read-only.** No agent writes to `<src-path>`. If a
   source artifact needs transformation (format conversion, de-PII,
   secret scrubbing), copy to `<scratch-path>` and edit there.
   `<scratch-path>` is the only location where source-derived
   content may be edited before ingestion into `<tgt-path>`.
2. **Source is frozen during and after the retrofit.** Concurrent
   edits abort the retrofit; post-retrofit edits fork the project
   and invalidate the CHARTER.
3. **No bulk copy.** `cp -r` from `<src-path>` to `<tgt-path>` is
   prohibited. Every artifact that moves is selected by an agent
   with a cited rationale.
4. **IP triage gates every move.** Default assumption: external
   unless proven project-created. See § 8.
5. **Stage order is non-negotiable.** Pre-flight → A → B → C → D →
   E (§ 4). No stage begins before the previous stage's exit
   criteria are met (§ 5).
6. **Hard Rule #3 (no commit without `code-reviewer`)** applies to
   `<tgt-path>`.
7. **Hard Rules #4 and #7 apply via the two-fire pattern** —
   surface early (to shape the Stage C plan) and bind late (at the
   latest pre-commit point). The pattern is defined once in § 5
   "Cross-stage Hard-Rule gates" and referenced from stage prose.
   Retrofit specifics:
   - Stage A can **discover** safety-critical surface the customer
     did not flag at pre-flight; any such row routes through Hard
     Rule #4 before Stage C assigns a decision-matrix outcome.
   - Stage B advisories from `security-engineer` on Hard-Rule-#7
     rows (auth / secrets / PII / net-endpoint) are non-binding
     but become inputs to Stage C.
8. **Registers take evidence over description.** When the
   customer's mental model of the source conflicts with the source
   itself, registers reflect what is there. Discrepancies become
   `OPEN_QUESTIONS.md` rows.

## 4. Roles and stage order

```
Pre-flight            tech-lead          Readiness triage, go/no-go
Stage A               onboarding-auditor Inventory + friction report
Stage B               researcher         IP triage + inventory
Stage C               architect          Structural migration plan
Stage D               project-manager    Charter reconstruction + risks
Stage E               software-engineer  Execution, under code-reviewer
                      security-engineer  Conditional Stage E gate — sign-off
                                         on Hard-Rule-#7 rows (auth,
                                         secrets, PII, network endpoints)
Stage F (optional)    project-manager    Ticket migration
Remote disposition    release-engineer   Conditional close-out if Stage A
                                         found a source remote
```

`tech-lead` orchestrates transitions, dispatches the named role, and
enforces stage gates. Any agent hitting an unanswerable question
returns to `tech-lead` per the escalation protocol.

### 4.1 Pre-flight — readiness triage

Runs **before** the scaffold exists. `tech-lead` inspects
`<src-path>` at a glance to decide whether a retrofit is viable;
results land in `docs/retrofit/preflight.md` once the scaffold is
present (until then, notes live in the session).

Checklist — answer each "present / absent / partial / unknown":

- [ ] **Version control.** Is `<src-path>` under git? `HEAD` clean?
      Canonical default branch? **Record `<src-path>` HEAD SHA + UTC
      timestamp** — Stage E DoR re-verifies this to detect source
      drift (anti-pattern #12). **Drift-hash recipe (binding,
      #49):**
      - Under VCS: HEAD SHA.
      - Not under VCS, or shallow / squashed / fresh-clone where
        HEAD is not meaningful:
        `find <src-path> -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum`
        (the `-type f` limits to regular files, `sort -z` makes the
        ordering deterministic across filesystems, the chained
        sha256sum collapses to a single 64-char hash). Note in
        `preflight.md` if falling back from a meaningless HEAD.
- [ ] **License.** Declared? Compatible with the target license
      decided in Step 2?
- [ ] **Build / run reproducibility.** Dependency manifest, lockfile,
      build README? If none, flag as risk R-0001 for Stage D.
- [ ] **Test suite.** Test dir? CI config (`.github/workflows/`,
      `.gitlab-ci.yml`, `Jenkinsfile`)? Current pass/fail state?
- [ ] **Documentation.** `README.md`, `ARCHITECTURE.md`, ADRs,
      `CHANGELOG.md`?
- [ ] **Secrets / PII / credentials.** In-repo secrets, `.env`
      files, tokens in history? If yes, Stage E scrubs to
      `<scratch-path>` (do not carry to `<tgt-path>`); rotation is
      a risk.
- [ ] **Customer / employer / third-party identifying content
      (#56).** Vendor product names, customer-site codenames,
      plant/tenant identifiers, operational context strings? These
      need a **distribution-posture ruling at pre-flight, not at
      Stage D** — their Stage B disposition depends on whether the
      target ever leaves the local host. Public-target retrofits
      with identifying content require Hard-Rule-#4 customer
      approval before triage begins; a wrong call is expensive to
      undo (git-history rewrite).
- [ ] **Size.** Rough LoC + file count (pacing input).
- [ ] **Open issues.** External tracker in use? How many open?
      Stage F migrates these.
- [ ] **Team charter-equivalent.** README / CONTRIBUTING /
      CODE_OF_CONDUCT / mission statement? Seeds Stage D.

Pre-flight go / no-go:

- **Go** — proceed to Stage A.
- **No-go, fixable** — surfaced blocker the customer can remove
  (e.g., source not under VCS; needs `git init` and a snapshot
  commit). `tech-lead` returns with the specific blocker; pre-flight
  resumes after.
- **No-go, blocking** — source too fragmented or IP posture too
  unclear to triage. `tech-lead` escalates for scope reduction.

### 4.2 Stage A — `onboarding-auditor` inventory

Mandate: a zero-context walk of `<src-path>` producing
`<tgt-path>/docs/retrofit/A-inventory.md`.

Contents:

- **Tree summary** — directories, file counts, sizes, file-type
  breakdown.
- **Detected tooling** — languages, frameworks, build systems, test
  frameworks, CI configs, linters, formatters, lock managers.
- **Evidence of conventions** — style configs (`.editorconfig`,
  `.prettierrc`, `.rustfmt.toml`, `ruff.toml`), branching hints
  (`main` vs `master`, `develop`, `gitflow`), review-process hints
  (CODEOWNERS, PR templates, branch protection if discoverable).
- **Doc artifacts** — `README.md`, `ARCHITECTURE.md`, ADRs,
  changelogs, runbooks, anything customer-facing.
- **Friction log** — things that confused the auditor on a cold
  read. Candidates for `CHARTER` open-questions or `LESSONS.md`.
- **Ambiguous artifacts** — unclear authorship / license /
  provenance. Input to Stage B.
- **Suspicious artifacts** — vendored third-party code, generated
  files, binaries, apparent secrets. Input to Stage B.
- **Identifying-content candidates (binding, #81)** — regex sweep
  for *universal* identifying classes (not customer-specific known
  strings). Output a per-hit / per-line table: path, line, matched
  class, excerpt, proposed disposition. **Aggregate verdicts (e.g.,
  "all 192.168.* hits are examples") are forbidden** because they
  hide bad hits among benign ones. Also write
  `docs/retrofit/regex-commands.md` with the exact commands / tool
  configuration used: patterns, include/exclude globs, binary-file
  handling, generated/vendor directory policy, date, agent. Starter
  classes:

  ```text
  IPv4 private ranges: 10.x.x.x, 172.16-31.x.x, 192.168.x.x
  IPv6 literals
  DDNS hostnames: ddns.net, dyndns.org, no-ip.com, duckdns.org
  Cloud hostnames: amazonaws.com, azurewebsites.net,
    googleusercontent.com, cloudfront.net, fly.dev, vercel.app,
    netlify.app, run.app, scw.cloud, linode.com,
    digitaloceanspaces.com
  MAC addresses
  Email addresses
  Common token prefixes: AKIA, glpat-, ghp_, github_pat_, xoxb-
  UUIDs used as service identifiers
  ```

  This set is a floor, not a complete secret scanner.
  `onboarding-auditor` is deliberately zero-context and must not
  receive customer-specific personal, service-name, employer,
  tenant, or site-code patterns unless `tech-lead` documents a
  narrow exception in the dispatch brief and the pattern itself is
  non-secret and non-tribal. Customer-specific classes are added at
  Stage B by `researcher` (which has the necessary inputs). Every
  added class updates both the per-hit table and
  `regex-commands.md` so Stage E reviewers can re-run the same
  set.
- **Convention-conflict register (seed)** — rows where source
  convention differs from template default (e.g., source uses
  `master`, template references `main`; source uses `poetry`,
  template assumes `pip-tools`). **Stage A only seeds (observed
  conflict); Stage C resolves per § 7. The auditor does not
  decide.** (#42.)

The auditor does not decide what moves. Its output feeds Stages B,
C, D, F.

### 4.3 Stage B — `researcher` IP triage

Input: Stage A's ambiguous + suspicious + identifying-content lists.
Output: `<tgt-path>/docs/retrofit/B-triage.md`, populated SME
inventories, proposed `.gitignore` additions.

For each artifact, `researcher` assigns one disposition:

- **project-created** — safe to commit under the target's license.
- **external — permissive license** — may be included; cite license
  + source in the relevant `docs/sme/<domain>/INVENTORY.md` row.
- **external — restricted** — goes to `docs/sme/<domain>/local/`
  (gitignored) with an inventory row; paraphrase-and-cite only.
- **derived — substantive transformation** — may be committed as
  paraphrase with citation.
- **project-authored, distribution-restricted (#56)** — material
  the project authored but whose redistribution is limited by an
  external relationship (employer, customer, NDA, regulatory).
  Landing depends on the target's distribution posture (recorded
  at pre-flight per § 4.1):
  - **local-only** → commit as-is with a `RISKS.md` row.
  - **private-shared** (named collaborators) → as above, plus a
    `STAKEHOLDERS.md` row naming the boundary.
  - **public** → **escalate**: paraphrase-and-redact, or
    Leave-behind, at customer ruling. Hard Rule #4 fires
    (git-history rewrite is expensive).
- **unclear** — escalate to `tech-lead`, who batches for the
  customer.

`researcher` also produces the `.gitignore` delta covering any new
local-only paths.

`researcher` consumes the Stage A identifying-content table and
assigns a disposition to every hit. `researcher` is also the
default owner for customer-specific identifying classes surfaced by
pre-flight, `CUSTOMER_NOTES.md`, or SME inventories (out of scope
for zero-context `onboarding-auditor`). New identifying classes are
appended as per-hit rows, not summarized in aggregate; the exact
added regex / command is appended to `regex-commands.md`. Hits
touching auth / secrets / PII / net-endpoints trigger the
Hard-Rule-#7 early fire (§ 5).

### 4.4 Stage C — `architect` structural migration plan

Input: Stages A + B.
Output: `<tgt-path>/docs/retrofit/C-plan.md`.

The plan maps source paths to target paths with a rationale per
row, picking one of the § 6 decision-matrix outcomes.

The plan also resolves **template-vs-source structural conflicts**
per § 7. Examples:

- Source `docs/decisions/` vs template `docs/adr/` — rename to
  template (default) or ADR-pin source.
- Source default branch `master` vs template `main` — rename or
  ADR-pin.
- Source bespoke CI vs template GitHub Actions — declare which
  survives.

Decisions crossing cost / schedule / risk thresholds are arbitrated
per `CLAUDE.md` § Routing defaults (architect + PM).

### 4.5 Stage D — `project-manager` charter reconstruction

Input: Stage C plan + Stage A friction log + pre-flight notes.
Output: populated `<tgt-path>/docs/pm/` registers (CHARTER,
STAKEHOLDERS, RISKS, CHANGES, LESSONS, TEAM-CHARTER, AI-USE-POLICY).

Charter reconstruction uses three evidence sources:

1. **Git log** — `git log --all --format='%h %ad %s' --date=short`
   against `<src-path>`. Mines: inception date (first commit), major
   milestones (release tags, large merges), contributor list
   (stakeholder candidates), pace (commit cadence → project-phase
   inference).
2. **README / existing docs** — source self-description. Treated as
   customer-provided evidence (one step removed from
   `CUSTOMER_NOTES.md`). Discrepancies vs git log go to
   `OPEN_QUESTIONS.md`.
3. **Customer interview** — `tech-lead` asks what git log and
   README do not answer: intent, non-goals, end users, "done"
   definition, regulatory constraints, performance SLAs. One
   question per turn, per Step-2 protocol.

Output-specific notes:

- **`CHARTER.md`** — the **new** project's charter, informed by the
  retrofit. Not a verbatim port. Cites evidence: "Inception date
  inferred from git log `<src-path>` 2024-03-11"; "Non-goals per
  customer interview 2026-04-24".
- **`STAKEHOLDERS.md`** — contributors with authorship > N commits;
  external SMEs implied by triage (vendor code → vendor
  relationship); regulatory bodies implied by domain.
- **`RISKS.md`** — source known-issues / TODOs, plus
  retrofit-specific risks: dependency drift, license uncertainty,
  loss of tacit knowledge, secret exposure in history, tooling gaps.
- **`CHANGES.md`** — the retrofit itself as `CH-0001`.
- **`LESSONS.md`** — generalizable entries from Stage A friction
  log.
- **`TEAM-CHARTER.md`** — reconstructed from CONTRIBUTING /
  CODE_OF_CONDUCT; otherwise flagged for Step 2.
  **Inherited naming category (#54):** if `<src-path>/.claude/agents/`
  (or equivalent) exists with a coherent naming scheme:
  (a) name the inherited category and enumerate role→name mapping;
  (b) map each inherited name to a canonical role per `CLAUDE.md`
  § Agent roster — names that don't map cleanly are flagged for
  Step 2 customer decision (retire / merge / keep as custom SME);
  (c) preserve the inherited `docs/AGENT_NAMES.md` at the target
  unless the customer explicitly requests refresh. Step 3 / 3a of
  FIRST ACTIONS then becomes a **confirmation**, not a fresh
  conversation.
- **`AI-USE-POLICY.md`** — new, per template default; customer
  ratifies in Step 2.

### 4.6 Stage E — `software-engineer` execution, `code-reviewer` gate (+ conditional `security-engineer`)

Input: Stage C plan + Stage B triage + Stage D charter.
Output: moves applied to `<tgt-path>`, commit-by-commit reviewed.

Rules:

- **One plan row = one commit** (trivial moves may batch); commit
  message cites the plan row. Resist batching — retrofit queues
  accrete fast.
- `code-reviewer` reviews per commit per Hard Rule #3.
- **Stale plan-row evidence escalates (#43).** If fresh Stage E
  context contradicts a Stage B / C decision, `software-engineer`
  **halts the row and escalates to `architect`** rather than
  deciding locally. The row re-enters Stage C; Stage E resumes on
  remaining rows.
- **Scaffold baseline commit (#52).** The initial
  `scripts/scaffold.sh` output may land as a single "Initial
  scaffold — template vX.Y.Z" commit **without `code-reviewer`
  review** (mechanical template output traceable to the upstream
  tag). `code-reviewer`'s first review applies to the first
  authored commit (typically the pre-flight artefact or Stage A
  inventory).
- **Retrofit audit-artefact commits get narrowed review (#52).**
  `docs/retrofit/*` and `docs/pm/*` register commits get
  `code-reviewer` review scoped to: (a) evidence-traceability
  (every claim cites an input), (b) redaction hygiene, (c) no
  committed secrets / PII / restricted-source / customer-
  confidential text.
- **Hard-Rule-#7 rows** (auth, authorization, secrets, PII,
  network-exposed endpoints) require `security-engineer` review
  *before* `code-reviewer`, per § 5. Sign-off in
  `CUSTOMER_NOTES.md`; assurance-artefact reference in the commit
  message.
- **Identifying-content regex re-run (#81).** Before each
  public-target or private-shared Stage E commit, the implementer
  re-runs the exact regex set in `regex-commands.md` against the
  staged tree and updates the per-hit table. `security-engineer`
  and `code-reviewer` independently re-run the set for rows they
  review; do not trust an implementer's aggregate summary.
- Source-derived content needing edits was edited in
  `<scratch-path>` (§ 3 rule 1); final form lands in the commit.
- External-restricted material lands in `docs/sme/<domain>/local/`
  (gitignored); the inventory row is committed.
- Any secret found in the source is scrubbed before move; rotation
  is recorded as a risk and a Hard-Rule-#7 item.

### 4.7 Stage F — `project-manager` ticket migration (optional)

Runs if pre-flight found an external issue tracker or versioned-doc
governance (#55: contract files / decision logs where open work
lives as rows in checked-in documents).

Input: tracker export (JSON / CSV / API pull) or the contract /
decision-log files.
Output: rows in `<tgt-path>/docs/tasks/` and
`<tgt-path>/docs/OPEN_QUESTIONS.md`.

Per-row mapping:

| Source row | Target |
|---|---|
| Technical scope | `docs/tasks/T-NNNN.md` per `docs/templates/task-template.md`. Preserve source ID as `source-issue:` or `source-contract:` field. |
| Question for the customer | `docs/OPEN_QUESTIONS.md` row. |
| Bug | `docs/tasks/T-NNNN.md` tagged `type: bug`, plus `docs/pm/RISKS.md` row if severity warrants. |
| Closed in source | Archived per § 6 Leave-behind with rationale "closed in source; record preserved in `archived-tickets.md`". |
| Stale / abandoned / unclear | `docs/retrofit/archived-tickets.md` with rationale; do not carry forward. |

**Versioned-doc governance (#55).** When the source uses contract
files / decision logs *as* the tracker:

- Contract-file rows map row-for-row to `T-NNNN`, preserving source
  row ID in `source-contract:`.
- Decision-log WIP entries map by shape: technical → task; customer
  call → `OPEN_QUESTIONS.md`; risk-tagged → `RISKS.md`.
- Closed / superseded rows archive to `archived-tickets.md` with
  source IDs + one-line rationale.
- The host documents themselves (contract files, decision logs)
  migrate as regular Stage C / Stage E artefacts (typically to
  `docs/architecture/` and `docs/decisions/` or the target's
  convention). Stage F covers only the **row-by-row work-queue
  migration**, not the host-document migration.

Traceability: every `T-NNNN` originating in the source has a
`source-issue:` or `source-contract:` field citing tracker /
contract + ID.

### 4.8 Remote disposition decision (conditional)

Runs when pre-flight or Stage A found a source git remote URL.
Owned by `release-engineer` under `tech-lead`; if no
`release-engineer` is available, `tech-lead` queues the decision
record for `researcher` and routes any git mechanics to the
appropriate operator.

Before close-out, `tech-lead` asks the customer one atomic remote
disposition question with explicit options:

- **Same remote, force-push target `main` over source `main`.**
  Destructive unless the source ref is archived first. Requires
  live customer acknowledgement and a pre-retrofit tag or archive
  branch.
- **Same remote, push target to a new branch.** Preserves source
  `main`; target lives on a sibling branch until default-branch
  swap.
- **Same remote, archive source branch then push target `main`.**
  Source preserved under `legacy/main` or equivalent.
- **New remote.** Target lives in a sibling repository; source
  becomes read-only archive.
- **No remote yet.** Target stays local; revisit later.

Route the ruling to `researcher` for a verbatim `CUSTOMER_NOTES.md`
entry, cite it from `docs/retrofit/CLOSURE.md`, and do not declare
retrofit close-out complete without either a ruling or an explicit
customer-deferred note.

## 5. Stage gates

Each stage has entry (DoR) and exit (DoD). `tech-lead` checks both.
No stage begins before the previous stage's DoD is met (§ 3 rule 5).

| Stage | Entry (DoR) | Exit (DoD) |
|---|---|---|
| Pre-flight | Preconditions § 1.3 met | Pre-flight checklist complete; go/no-go recorded |
| A | Pre-flight = Go | `A-inventory.md` complete; all source directories visited; friction / ambiguous / suspicious / convention-conflict lists populated |
| B | A DoD met | Every ambiguous + suspicious row triaged; `.gitignore` delta prepared; SME inventories updated |
| C | A + B DoD met | Every artifact has a target destination or a "leave" outcome with rationale; every convention conflict resolved per § 7 |
| D | C DoD met | CHARTER, STAKEHOLDERS, RISKS, CHANGES, LESSONS populated with citations; first post-retrofit milestone defined |
| E | C + D DoD met; **`<src-path>` HEAD SHA re-verified against pre-flight record** (mismatch aborts per § 3 rule 2) | All plan rows executed and reviewed; identifying-content regex set re-run and per-hit table updated; `code-reviewer` sign-off per row; `security-engineer` sign-off on every Hard-Rule-#7 row recorded in `CUSTOMER_NOTES.md`; `OPEN_QUESTIONS.md` reflects carry-overs |
| F (if applicable) | E DoD met | Source tickets mapped per § 4.7; `archived-tickets.md` records closed + stale; `docs/tasks/` populated |
| Remote disposition (if applicable) | E DoD met; source remote URL recorded | Customer ruling recorded; remote action complete or explicitly deferred; `CLOSURE.md` cites disposition |

**Cross-stage Hard-Rule gates (binding, two-fire pattern).** Both
rules use the same shape: **early fire** to shape the Stage C plan,
**binding sign-off** at the latest pre-commit point. The two fires
together prevent (a) locking in dispositions that would later be
blocked and (b) ungated commits.

| Rule | Early fire (non-binding, shapes plan) | Binding sign-off |
|---|---|---|
| **Hard Rule #4** (safety-critical) | Any artifact whose Stage A / B evidence places it on a safety-critical path routes through `tech-lead` for live customer approval *before* Stage C assigns a decision-matrix outcome. Applies to audit-discovered rows, not only pre-flagged ones. | Customer approval routed by `tech-lead`, appended verbatim by `researcher` in `CUSTOMER_NOTES.md`, before the row's Stage E commit. |
| **Hard Rule #7** (auth / secrets / PII / net-endpoint) | When `researcher` first tags a triage row, `security-engineer` produces an advisory note appended to `B-triage.md` before Stage B closes (§ 4.3). Stage C's plan must consume it. | `security-engineer` sign-off supplied to `researcher` and appended in `CUSTOMER_NOTES.md` at Stage E *before* `code-reviewer`, alongside the Hard Rule #4 customer approval where both apply. References the relevant security-assurance artefact (per `docs/templates/security-template.md`). |

## 6. Decision matrix — per-artifact outcomes

For each artifact from Stage A, Stage C assigns one outcome.
Stage E executes.

| Outcome | When | Lands at |
|---|---|---|
| **Pull as-is** | project-created, shape matches template convention | equivalent path in `<tgt-path>` |
| **Rename + pull** | project-created, shape conflicts with template naming | template-conformant path |
| **Paraphrase + pull** | derived from external material, substantive transformation | `<tgt-path>` + citation to SME inventory row |
| **Rewrite** | project-created but no longer fit-for-purpose, or divergent enough that a fresh author is cheaper than a port | fresh artifact in `<tgt-path>`; source kept in `<scratch-path>` during E |
| **Archive local** | external-restricted | `docs/sme/<domain>/local/` (gitignored) + inventory row |
| **Leave behind** | no forward value | not moved; recorded in `<tgt-path>/docs/retrofit/left-behind.md` with one-line rationale |
| **Escalate** | triage unclear; customer call needed | held in Stage B output; `tech-lead` batches for the customer |

**Orthogonal to outcome:** a row tagged safety-critical (Hard
Rule #4) or Hard-Rule-#7 fires the corresponding § 5 cross-stage
gate regardless of outcome. "Pull as-is" on a safety-critical
artifact still needs live customer approval; "rename + pull" on an
auth module still needs `security-engineer` sign-off.

Every "Leave behind" and "Rewrite" carries a rationale so future
audits can reconstruct reasoning.

## 7. Handling pre-existing conventions that conflict with template defaults

Existing projects ship with conventions (style, branching, review
process, layout) that may collide with template defaults.

**Default: migrate to template convention.** Template conventions are
chosen to be portable and standards-aligned; preserving per-project
drift erodes the framework's value. Automatic-migration examples:
default branch `master` → `main` (unless tooling hard-codes
`master`; then escalate to architect); `docs/decisions/` →
`docs/adr/` (v0.13.0 Three-Path ADR shape); bespoke commit-message
format → Conventional Commits (unless source has CI checks
enforcing the old format that are themselves being kept).

**Exception: pin source convention via ADR.** If migration is
expensive (team-trained, external tooling depends on it, regulatory
requirement), pin via an ADR under `<tgt-path>/docs/adr/` using the
v0.13.0 Three-Path template (Minimalist = migrate to default;
Scalable = pin + bridge tooling; Creative = hybrid). Customer signs
off; ADR cross-references from `docs/INDEX.md` and from the
convention's home (e.g., CONTRIBUTING.md if branching).

**Guardrails (#44, binding):**

1. **Cost citation required.** Every pinning ADR MUST cite the
   specific migration cost (team-training hours, tooling cost,
   regulatory dependency). Costs are auditable; preferences are
   not. ADRs without a cost citation are **rejected at Stage C** —
   `architect` returns the row for re-decision.
2. **Cap on pinned exceptions.** More than 3 pinned-convention
   ADRs in a single retrofit → `architect` MUST write a meta-ADR
   asking whether the template is wrong for this domain rather
   than accreting exceptions. The meta-ADR either escalates
   upstream (`docs/ISSUE_FILING.md`) or documents why the project
   should fork its conventions.

**Conflicts requiring escalation (not ADR-able).** Some conflicts
are safety invariants, not design choices:

- Template Hard Rules (`CLAUDE.md` § Hard rules) may not be
  overridden by source convention (e.g., a source review process
  without a required reviewer still adopts Hard Rule #3).
- Template IP policy may not be weakened (e.g., a source habit of
  committing quoted standards text still paraphrases-and-cites).

These are recorded in `docs/retrofit/convention-conflicts.md` with
the resolution (always template default) and brief rationale.

## 8. IP triage protocol

Governed by `docs/IP_POLICY.md`. Retrofit-specific notes:

- **Default is external.** Any artifact without clear
  project-authored provenance is external until proven
  project-created. `git log` from `<src-path>` showing in-project
  authorship is sufficient proof; absence of log info (fresh clone,
  squashed history) is not.
- **Restricted-source clauses.** Where the source contains
  materials with explicit prohibitions (e.g., "NO AI TRAINING"),
  `researcher` records the clause in the inventory and applies
  paraphrase-and-cite. Transient in-context reading is permitted
  per the narrow interpretation (customer ruling 2026-04-23);
  persistent embedding is not.
- **Derivative work.** A target version of a source derivative must
  be a **substantive transformation** and cite the source by
  inventory row ID. Line-for-line translation / reformatting does
  not count.
- **Secrets in history.** Git history that contains committed
  secrets is never carried forward. Target gets a fresh history
  (Stage E commits against the scaffolded `git init`). Rotation of
  the exposed secret is a Stage D risk.

### 8.1 Nested sibling git repositories (issue #53)

If `<src-path>` contains nested git repositories excluded from
`<src-path>`'s tracking (typically `.gitignore` + a documented
boundary invariant — the "meta-repo + sibling-fork" pattern),
treat each nested repo as an **out-of-scope artefact**:

- **Pre-flight (§ 4.1)** records nested-repo paths, each nested
  HEAD SHA (or content-hash recipe per #49 if not under VCS), and
  the source's declared exclusion rationale. Stage E drift-check
  re-verifies all recorded HEADs.
- **Stage A (§ 4.2)** does not walk into nested repos. Presence
  and exclusion are one line in `A-inventory.md`; contents are not
  inventoried.
- **Stage B (§ 4.3)** triages each nested repo as a single
  artefact with its own license + provenance; lands as an SME
  inventory row.
- **Stage C (§ 4.4)** decides whether the target preserves the
  nesting or flattens it. **Default: preserve** — the source's
  boundary choice was deliberate.
- **Stage E (§ 4.6)** moves the `.gitignore` entry covering the
  nesting into the target; the nested repo itself is **not
  moved**. The customer moves / re-clones it out-of-band after the
  retrofit completes.

## 9. Migration of existing issues / tickets

Handled by Stage F (§ 4.7). Covers GitHub Issues, GitLab Issues,
Jira, Linear, Shortcut, Trello, ad-hoc TODO files, **and
contract-file / decision-log governance** (versioned-doc shape —
see § 4.7 "Versioned-doc governance").

Flow notes beyond § 4.7:

1. Pre-flight detects the tracker and records access method
   (export path, API token, URL).
2. Stage E completes before Stage F begins (no parallel churn).
3. PM pulls a dump and applies the § 4.7 row mapping.
4. Source-issue IDs are preserved as cross-references; they are
   **not** new task IDs. New IDs allocate sequentially from
   `T-0001`.
5. If the source used issue labels (`bug`, `enhancement`, etc.),
   PM proposes a label taxonomy for `<tgt-path>` informed by
   source usage; customer ratifies.
6. Closed and stale items are archived in `archived-tickets.md`
   with source IDs and a one-line rationale. They are **not**
   deleted from the source tracker — the source tracker is
   read-only here; the customer may close it out-of-band
   post-retrofit.

## 10. Register population — summary

| Register | Populated by | Source evidence |
|---|---|---|
| `CUSTOMER_NOTES.md` | `researcher` | Verbatim customer answers during the retrofit conversation |
| `docs/OPEN_QUESTIONS.md` | `tech-lead` | Questions surfaced by any stage |
| `docs/pm/CHARTER.md` | `project-manager` | Git log + README + customer interview (Stage D) |
| `docs/pm/STAKEHOLDERS.md` | `project-manager` | Git log authorship + triage findings |
| `docs/pm/RISKS.md` | `project-manager` | Known-issues, TODOs, triage, pre-flight |
| `docs/pm/CHANGES.md` | `project-manager` | Retrofit logged as `CH-0001` |
| `docs/pm/LESSONS.md` | `project-manager` | Stage A friction log (generalizable entries) |
| `docs/pm/TEAM-CHARTER.md` | `project-manager` | CONTRIBUTING + CODE_OF_CONDUCT + interview |
| `docs/pm/AI-USE-POLICY.md` | `project-manager` | Customer ratification in Step 2 |
| `docs/sme/<domain>/INVENTORY.md` | `researcher` | Stage B triage |
| `docs/tasks/T-NNNN.md` | `project-manager` | Stage F (source tracker) |
| `docs/retrofit/*` | various | See § 11 |

## 11. `docs/retrofit/` directory

Created inside `<tgt-path>` at retrofit start. Holds the audit
trail for the retrofit itself.

```
docs/retrofit/
├── preflight.md              # pre-flight readiness triage
├── A-inventory.md            # Stage A output
├── B-triage.md               # Stage B output
├── C-plan.md                 # Stage C output
├── regex-commands.md         # durable identifying-content regex set
├── left-behind.md            # artifacts not moved, with rationale
├── convention-conflicts.md   # § 7 conflict register
├── archived-tickets.md       # Stage F closed + stale source tickets
└── CLOSURE.md                # close-out summary, including remote disposition
```

The directory is committed. It is the retrofit's durable record for
future audits and for a possible rollback decision.

`CLOSURE.md` must include: final source SHA / drift hash checked at
Stage E start, identifying-content regex re-run evidence from
`regex-commands.md`, Stage-gate checklist status, outstanding
carry-over questions, remote disposition (§ 4.8), rollback pointer,
and customer sign-off or explicit deferred-close rationale.

## 12. Rollback plan

A retrofit can stall or fail. The plan is deliberately minimal.

**Stall signals** that warrant rollback consideration:

- A stage DoD cannot be met (source too fragmented / under-documented
  / IP-encumbered).
- **Customer-decision pace lags (#40, agent-observable).** More than
  **3** rows in `docs/OPEN_QUESTIONS.md` with `answerer: customer`
  and `status: open` for more than **5** days (UTC). N=3, M=5 are
  project-tunable defaults; record any override in
  `docs/pm/LESSONS.md`. (An agent can count; an agent cannot assess
  "pace" qualitatively.)
- Pre-flight findings were wrong in material ways (e.g., "source has
  tests" was recorded but Stage A finds none).
- Stage C plan grows past the point where the customer still thinks
  the retrofit is cheaper than a green rewrite.

When any two hold, `tech-lead` raises: **continue, pivot, or roll
back?**

**Continue** (default if tractable). `tech-lead` re-scopes the
remaining stages (drops Stage F, archives more as leave-behind, etc.)
and reports the reduction for sign-off.

**Pivot** — switch from retrofit to **green rewrite guided by the
source as reference**. Mechanism: `<tgt-path>` starts clean (revert
all Stage E commits); `<src-path>` becomes a read-only reference.
Stage D populations are kept (charter, risks, lessons remain
valuable even if no code is ported). `CLOSURE.md` records the pivot
including remote disposition and regex re-run status if any
source-derived material reached the target.

**Artifact-survival list on pivot (#41).** **Survive:**
`docs/retrofit/preflight.md`, `A-inventory.md`, `B-triage.md`,
`C-plan.md` (historical record, not a forward manifest); all
`docs/pm/*` Stage D outputs; SME inventories; any `docs/adr/`
authored during the retrofit. **Reverted: Stage E commits only** —
the migration moves themselves. The list prevents silent loss
during pivot.

**Roll back** — when no viable forward path remains:

1. **Write-before-delete (binding).** Before `<tgt-path>` is
   deleted, `tech-lead` finalizes
   `<tgt-path>/docs/retrofit/CLOSURE.md` with a "why rolled back"
   section naming the stall signals that fired, the stage at which
   the retrofit stopped, remote disposition, and
   identifying-content regex status. `project-manager` copies
   generalizable lessons from Stage D `LESSONS.md` and the
   friction log into a standalone carry-out file — **default
   path (#47):
   `<tgt-path>/../retrofit-lessons-YYYY-MM-DD.md`**, a sibling of
   the doomed target in the parent directory the customer has
   already chosen. The customer may redirect before the write, but
   the default requires no decision. Without this step, rollback
   destroys the audit trail the retrofit spent five stages
   building.
2. `<tgt-path>` is deleted (`rm -rf <tgt-path>` — reversibility per
   § 2.2 is why this is cheap).
3. `<src-path>` is unaffected (source-freeze was binding).
4. The customer and `tech-lead` meet to decide next steps:
   smaller-scope retrofit of a subset, pivot to green rewrite with
   a fresh scaffold, or abandon template adoption entirely.
5. Lessons are recorded as an upstream issue so the playbook can
   grow (per `docs/ISSUE_FILING.md` if the project opted in).

Rollback is a valid outcome, not a failure-mode-to-avoid. A
rolled-back retrofit that produced a clean inventory, solid triage,
and charter has produced real value even if no code moved —
*provided step 1 preserves that value before deletion*.

## 13. Anti-patterns

1. **Bulk copy** (`cp -r <src> <tgt>`, delete-what-doesn't-belong).
   Skips audit + triage; imports unknown IP.
2. **Pre-filling registers before Stage A.** Charter from customer
   description alone, before the audit. Source almost always
   contradicts description; charter wrong on day one.
3. **Running stages out of order.** Decisions on incomplete inputs.
4. **Editing in-tree under `<src-path>`.** Violates § 3 rule 1; use
   `<scratch-path>`.
5. **Skipping Stage E commit granularity.** Batching twenty moves
   into one commit makes review unreliable and rollback
   impractical.
6. **Silent Leave-behind.** Dropping artifacts with no
   `left-behind.md` entry. Future reader cannot tell whether
   considered-and-rejected or missed.
7. **Treating Stage A as a copy list.** Auditor produces inventory,
   not a manifest. Move decisions are Stage C.
8. **Invoking `scripts/repair-in-place.sh` against a populated
   source tree.** Out of scope; see § 2.3.
9. **Migrating source conventions by default.** Opposite of § 7;
   migrate to template defaults unless ADR pins source.
10. **Keeping secrets in history.** § 8 — fresh history, rotate
    exposed secrets, log as risk.
11. **Mid-stage abandonment without a § 12 decision.** A retrofit
    that halts without `tech-lead` invoking § 12 leaves
    `<tgt-path>` inconsistent with no audit-trail disposition.
    Silence is not an option.
12. **Undetected source drift.** Source-freeze (§ 3 rule 2) is
    *declared* at pre-flight but not *verified* at Stage E start
    unless the SHA recorded at pre-flight is re-checked. Failing
    to perform the check is the anti-pattern, not the drift
    itself.
13. **Stale Stage D approvals invoked at Stage E.** Customer
    approvals attach to specific Stage C plan rows. New Stage E
    context requiring an unruled-on decision escalates fresh for
    live approval (Hard Rule #4).
14. **Treating unratified escalations as ratified.** Stage B's
    "Escalate" outcome is parked until the customer rules. Acting
    on an escalated row because rollback is awkward or the
    schedule is tight violates Hard Rule #1 (tech-lead is the
    channel) and Hard Rule #4 (approval must be live). Halt the
    row and return to `tech-lead`.

## 14. Exit criteria / Definition of Done

Retrofit is complete when **all** are true:

- [ ] Pre-flight checklist filed at `docs/retrofit/preflight.md`
      with go decision recorded.
- [ ] Stage A inventory closed (every source directory walked;
      `A-inventory.md`).
- [ ] Stage B triage closed (every ambiguous / suspicious artifact
      has an outcome; `.gitignore` delta applied; SME inventories
      populated).
- [ ] Stage C plan closed (every artifact has a destination or a
      "leave" outcome with rationale; every convention conflict
      resolved per § 7).
- [ ] Stage D registers updated with citations (CHARTER,
      STAKEHOLDERS, RISKS, CHANGES, LESSONS, TEAM-CHARTER,
      AI-USE-POLICY).
- [ ] Stage E moves executed and reviewed (one `code-reviewer`
      sign-off per row or batch); identifying-content regex re-runs
      from `regex-commands.md` completed and per-hit table updated.
- [ ] **Every Hard-Rule-#7 row has `security-engineer` sign-off**
      supplied to `researcher` and appended in `CUSTOMER_NOTES.md`
      with reference to the relevant security assurance artefact
      (§ 5).
- [ ] **Every safety-critical row has live customer approval (Hard
      Rule #4)** obtained by `tech-lead`, routed to `researcher`,
      appended verbatim in `CUSTOMER_NOTES.md` — dated, no cached
      approval, no agent-only path.
- [ ] Stage F (if applicable) complete: source tickets mapped to
      `docs/tasks/` + `docs/OPEN_QUESTIONS.md`;
      `archived-tickets.md` filed.
- [ ] First post-retrofit milestone defined in
      `CHARTER.md § Milestones` with an exit criterion.
- [ ] `OPEN_QUESTIONS.md` reflects any remaining customer calls
      the retrofit surfaced.
- [ ] `tech-lead` writes `docs/retrofit/CLOSURE.md` summarizing
      what moved, what was left, the next milestone, retrofit
      duration (for `LESSONS.md` generalization),
      identifying-content regex re-run evidence, and the remote
      disposition decision (§ 4.8).
- [ ] **`docs/INDEX.md` cross-links to `docs/retrofit/CLOSURE.md`**
      so future sessions discover the retrofit trail.
- [ ] **`TEMPLATE_VERSION` integrity check passes** — file matches
      the scaffold-time stamp exactly (SemVer + git SHA + date; no
      drift, no hand-edit). The retrofit populates the project; it
      does not change the template version.
- [ ] **Customer sign-off on retrofit completion** recorded in
      `CUSTOMER_NOTES.md` as a distinct entry dated to the
      retrofit's close. The retrofit sets the project's foundation;
      this sign-off is a Hard-Rule-#4-adjacent event and is not
      subsumed by per-row approvals gathered during Stages C–E.
- [ ] Step 2 Definition of Done (`CLAUDE.md`) is satisfied using
      retrofit findings as evidence; `tech-lead` can now dispatch
      the first post-retrofit work subagent.

## 15. Related artifacts

- `docs/TEMPLATE_UPGRADE.md` § Scaffolding a new project —
  scaffold.sh, the precondition.
- `docs/IP_POLICY.md` — governing rules for § 8.
- `CLAUDE.md` § Hard rules — bindings referenced by § 3 rules 6, 7;
  § 7.
- `ROADMAP.md` — v0.13.0 roll-up referencing this playbook.
- `scripts/scaffold.sh` — required pre-step.
- `scripts/repair-in-place.sh` — **not** a retrofit tool; see § 2.3.
- `scripts/upgrade.sh` — orthogonal operation (template-version
  bump inside an already-scaffolded project).
- `.claude/agents/onboarding-auditor.md` — Stage A executor.
- `.claude/agents/researcher.md` — Stage B executor.
- `.claude/agents/architect.md` — Stage C executor.
- `.claude/agents/project-manager.md` — Stages D + F executor.
- `.claude/agents/software-engineer.md` — Stage E executor.
- `.claude/agents/code-reviewer.md` — Stage E gate (all rows).
- `.claude/agents/security-engineer.md` — Stage E gate
  (Hard-Rule-#7 rows: auth, secrets, PII, network endpoints) per
  § 5.
- `docs/templates/security-template.md` — security assurance
  artefact shape referenced by § 5 sign-offs.
- `docs/sme/INVENTORY-template.md` — inventory row shape.
- `docs/templates/task-template.md` — Stage F task shape.
- `docs/templates/adr-template.md` (v0.13.0 Three-Path) — § 7 ADR
  shape.
- `docs/ISSUE_FILING.md` — how to file upstream issues for playbook
  gaps.
- Upstream issue #3 — tracking issue for this playbook.
- Customer ruling 2026-04-23 — `CUSTOMER_NOTES.md` § "Retrofit
  adoption flow" — pinned scaffold-first flow.

## 16. Change log

| Date | Author | Note |
|---|---|---|
| 2026-04-24 | tech-lead | DRAFT (project-local) rewritten against `/ultraplan`-spec scope; adds pre-flight, Path-A-vs-B decision, § 7 convention conflicts, § 4.7 + § 9 ticket migration, § 12 rollback, § 10 register summary, § 11 `docs/retrofit/` shape. Pinned to v0.13.0. |
| 2026-04-24 | tech-lead | Revision pass on blocking `code-reviewer` + `architect` findings: § 2.4 interstitial cases (B4); § 3 extended with Hard-Rule-#7 binding and clarified Hard-Rule-#4 for audit-discovered safety-critical (B1); § 4 / § 5 / § 6 name `security-engineer` as conditional Stage E gate (B1); § 12.4 mandates write-before-delete of carry-out lessons (B5); § 13 gains 4 anti-patterns (B3); § 14 DoD adds customer sign-off, `TEMPLATE_VERSION` check, INDEX cross-link, sign-off checkboxes (B2); § 15 cross-refs. Six non-blocking findings filed as v0.13.1 issues. |
| 2026-04-24 | tech-lead | Second-round review: architect items 2 and 5 accepted, 4 declined. **Item 5 (SHA-capture gap):** § 4.1 mandates HEAD-SHA + UTC capture; § 5 Stage E DoR re-verifies (mismatch aborts). Gives anti-pattern #12 a concrete input. **Item 2 (Hard-Rule-#7 two-fire asymmetry):** § 3 / § 4.3 / § 5 reformatted as two-fire pattern mirroring Hard Rule #4 (Stage B advisory + Stage E binding sign-off). **Item 4 (Stage G):** declined per customer; simpler-wins-on-ties (customer sign-off stays as DoD checkbox owned by `tech-lead` inline); filed as future consideration (#48). Non-blocking #46, #47 filed. |
| 2026-04-25 | tech-lead | **v0.16.0 revision pass** — 16 deferred issues closed: §1.2 N→1 deferred-reshape (#45); §1.3 absorbed Step 0/1 (#51); §2.4 retrofit-and-upgrade simultaneously (#46); §4.1 no-VCS hash recipe (#49) + customer-confidential pre-flight row (#56); §4.2 seeds-vs-resolves (#42); §4.3 Hard-Rule-#7 wording split (#50) + project-authored-distribution-restricted disposition (#56); §4.5 inherited naming category (#54); §4.6 stale-plan-row escalation (#43) + scaffold-baseline + audit-artefact commit rules (#52); §4.7 + §9 versioned-doc governance (#55); §7 cost-citation + cap guardrails (#44); new §8.1 nested sibling git repos (#53); §12 agent-observable customer-pace stall signal (#40); §12 explicit artifact-survival list on pivot (#41); §12 default carry-out path (#47). |
| 2026-05-15 | tech-writer | Token-economization compression pass (customer ruling Q5). Reductions: Hard-Rule-#4/#7 two-fire pattern consolidated into a single § 5 cross-stage gates table (was repeated 4× in §§ 3, 4.3, 4.6, 5, 6, 14); § 2.2 Path-A rationale condensed from four paragraphs to one + bullets; § 2.4 interstitial cases moved to table; § 7 sub-sections (7.1–7.3) collapsed into a single flat section; § 12 sub-sections (12.1–12.4) flattened; § 13 anti-patterns tightened to single-line entries; § 4.7 mapping moved to table; change-log entries trimmed. No content removed; cross-references preserved. |
