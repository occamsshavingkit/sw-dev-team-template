# Retrofit Playbook — adopting `sw-dev-team-template` into an existing codebase

<!-- TOC -->

- [1. Scope and pinned flow](#1-scope-and-pinned-flow)
  - [1.1 In scope](#11-in-scope)
  - [1.2 Out of scope](#12-out-of-scope)
  - [1.3 Preconditions (binding)](#13-preconditions-binding)
- [2. Decision record — scaffold-first vs in-place (pinned)](#2-decision-record-scaffold-first-vs-in-place-pinned)
  - [2.1 The three adoption paths](#21-the-three-adoption-paths)
  - [2.2 Side-by-side vs in-place — the explicit ruling](#22-side-by-side-vs-in-place-the-explicit-ruling)
  - [2.3 `scripts/repair-in-place.sh` is not a retrofit tool](#23-scriptsrepair-in-placesh-is-not-a-retrofit-tool)
  - [2.4 Interstitial cases](#24-interstitial-cases)
- [3. Hard rules specific to retrofit](#3-hard-rules-specific-to-retrofit)
- [4. Roles and stage order](#4-roles-and-stage-order)
  - [4.1 Pre-flight — readiness triage](#41-pre-flight-readiness-triage)
  - [4.2 Stage A — `onboarding-auditor` inventory](#42-stage-a-onboarding-auditor-inventory)
  - [4.3 Stage B — `researcher` IP triage](#43-stage-b-researcher-ip-triage)
  - [4.4 Stage C — `architect` structural migration plan](#44-stage-c-architect-structural-migration-plan)
  - [4.5 Stage D — `project-manager` charter reconstruction](#45-stage-d-project-manager-charter-reconstruction)
  - [4.6 Stage E — `software-engineer` execution, `code-reviewer` gate (+ conditional `security-engineer`)](#46-stage-e-software-engineer-execution-code-reviewer-gate-conditional-security-engineer)
  - [4.7 Stage F — `project-manager` ticket migration (optional)](#47-stage-f-project-manager-ticket-migration-optional)
  - [4.8 Remote disposition decision (conditional)](#48-remote-disposition-decision-conditional)
- [5. Stage gates](#5-stage-gates)
- [6. Decision matrix — per-artifact outcomes](#6-decision-matrix-per-artifact-outcomes)
- [7. Handling pre-existing conventions that conflict with template defaults](#7-handling-pre-existing-conventions-that-conflict-with-template-defaults)
  - [7.1 Default: migrate to template conventions](#71-default-migrate-to-template-conventions)
  - [7.2 Exception: pin source convention via ADR](#72-exception-pin-source-convention-via-adr)
  - [7.3 Conflicts requiring escalation (not ADR-able)](#73-conflicts-requiring-escalation-not-adr-able)
- [8. IP triage protocol](#8-ip-triage-protocol)
  - [8.1 Nested sibling git repositories (issue #53)](#81-nested-sibling-git-repositories-issue-53)
- [9. Migration of existing issues / tickets](#9-migration-of-existing-issues-tickets)
- [10. Register population — summary](#10-register-population-summary)
- [11. `docs/retrofit/` directory](#11-docsretrofit-directory)
- [12. Rollback plan](#12-rollback-plan)
  - [12.1 Stall detection](#121-stall-detection)
  - [12.2 Continue](#122-continue)
  - [12.3 Pivot](#123-pivot)
  - [12.4 Roll back](#124-roll-back)
- [13. Anti-patterns](#13-anti-patterns)
- [14. Exit criteria / Definition of Done](#14-exit-criteria-definition-of-done)
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

> **Not a script.** Retrofit is an **agent workflow** driven by
> the contents of the source project. A script would assume a
> fixed shape; real source projects do not have one. See
> `scripts/scaffold.sh`, `scripts/repair-in-place.sh`, and
> `scripts/upgrade.sh` for the three script-covered cases — this
> playbook covers the fourth (existing-codebase adoption) and is
> deliberately not scripted.

---

## 1. Scope and pinned flow

### 1.1 In scope

- Adopting `sw-dev-team-template` into an **existing, non-scaffolded
  codebase** (`<src-path>`) by producing a **fresh scaffold**
  (`<tgt-path>`) and migrating `<src-path>`'s contents across on
  an audit-driven basis.
- Populating the target's registers (`CUSTOMER_NOTES.md`,
  `docs/pm/CHARTER.md`, `docs/pm/RISKS.md`, `docs/OPEN_QUESTIONS.md`,
  `docs/tasks/`, SME inventories) from evidence in `<src-path>`.
- Migrating the source's existing issue / ticket inventory into
  `docs/tasks/` and `docs/OPEN_QUESTIONS.md`.
- Recording the retrofit itself as PMBOK change `CH-0001` in
  `docs/pm/CHANGES.md`.

### 1.2 Out of scope

- **Multi-source retrofit** (N→1). Deferred. If needed, run the
  playbook sequentially per source with merges recorded as ADRs.
  N→1 will need three reshapes before it is properly supported,
  targeted at v0.16+ (issue #45):
  (a) per-source `docs/retrofit/src-N/` subdirectories so artefacts
      don't collide;
  (b) a CHARTER-inception-date tie-breaker rule for git-log
      inference across multiple sources (earliest / customer-
      declared / latest — pick one);
  (c) `CHANGES.md` numbering convention `CH-0001` … `CH-000N`
      with cross-referencing.
  Until those reshape, sequential-per-source is best-effort only.
- **Retrofit-in-place** (convert `<src-path>` itself into a
  template-shaped project). See § 2 for the decision record that
  rules this path out by default.
- **Concurrent work on the source during the retrofit.** Source is
  frozen (§ 3.2); customer has agreed not to resume source-side
  work after the retrofit completes.

### 1.3 Preconditions (binding)

Before the playbook starts:

- `<src-path>` exists and is readable.
- Customer has stated the source path to `tech-lead` and confirmed
  source-freeze.
- `scripts/scaffold.sh <tgt-path> "<project-display-name>"` has
  produced `<tgt-path>` with `TEMPLATE_VERSION` stamped.
- FIRST ACTIONS Step 0 (issue-feedback opt-in) and Step 1
  (skill-pack menu) have run in `<tgt-path>`, **OR** the retrofit
  absorbs them as the first actions of pre-flight (issue #51).
  In the absorbed case: tech-lead asks Step 0 atomically (once,
  when idle) at session start; Step 1's skill-pack menu is
  **deferred until after pre-flight's go/no-go** so a tangential
  menu doesn't stall the retrofit. Existing-codebase customers
  invoking retrofit before they have a mental model of FIRST
  ACTIONS is the typical case; this absorption path is the
  ergonomic default.
- Step 2 scoping has begun in `<tgt-path>` but has **not** closed
  — the retrofit feeds Step 2's Definition-of-Done fields
  (CHARTER, SME classification, first milestone) with evidence
  from `<src-path>`, so closing Step 2 before the retrofit has
  produced its findings is a sequencing error.

## 2. Decision record — scaffold-first vs in-place (pinned)

### 2.1 The three adoption paths

The template supports four adjacent operations:

| Path | Script / playbook | When to pick |
|---|---|---|
| Fresh project | `scripts/scaffold.sh` | Greenfield; no existing code |
| Unzipped template | `scripts/repair-in-place.sh` | User unpacked the template archive *into* their empty project dir, wants it normalized |
| Upgrade | `scripts/upgrade.sh` | Existing scaffolded project wants a newer template version |
| **Retrofit (this playbook)** | *agent workflow* | **Existing, non-scaffolded codebase wants to adopt the template** |

### 2.2 Side-by-side vs in-place — the explicit ruling

Two mechanically plausible approaches to retrofit:

- **A. Scaffold into a sibling directory (`<tgt-path>` ≠ `<src-path>`),
   selectively merge**. Source is read-only; target is built fresh;
   agents discover source state and migrate artifacts across on the
   basis of audit + triage. **This playbook covers Path A.**
- **B. In-place retrofit (run `scripts/repair-in-place.sh`-like
   operation on `<src-path>` itself)**. Converts the existing
   codebase into a template-shaped project by laying scaffolded
   files into the source tree.

**Customer ruling 2026-04-23:** Path A is the pinned default.
Verbatim rationale from `CUSTOMER_NOTES.md`:

> "The user scaffolds an empty directory then asks to migrate the
> project from its original directory. The agents have to figure
> out what is there and how they migrate it."

Why Path A over Path B:

1. **Reversibility.** Path A leaves `<src-path>` untouched until
   the retrofit completes (and after, per § 3.2). A failed retrofit
   is a `rm -rf <tgt-path>` away from the original state. Path B
   overwrites source history and layout; a failed in-place retrofit
   needs `git reset --hard` against whatever state existed before
   the scaffold was layered on, and that state is often not tagged.
2. **No file-shape collisions.** Path A lets `architect` rewrite
   layout cleanly (template conventions are authored into a new
   tree). Path B produces a hybrid where template files and source
   files coexist; any file the template ships at the same path as
   an existing source file forces an immediate merge decision
   before the team even has a charter.
3. **Audit-first is legible.** Path A forces `onboarding-auditor`
   to produce an inventory before anything moves. Path B tends to
   skip audit in favor of "just run the scaffold, see what breaks."
4. **IP triage stays clean.** Path A's `researcher` sees a
   single, uncontaminated source tree during triage. Path B mixes
   template-shipped files into the triage surface, so the
   "external vs project-created" call becomes harder.

Path B is not supported. If a user insists on in-place retrofit:

- Explain the ruling above.
- If they still insist, record it as an ADR under `<tgt-path>/docs/adr/`
  superseding this playbook's default; proceed **only** after the
  ADR is in place and the customer has signed off on losing
  reversibility.

### 2.3 `scripts/repair-in-place.sh` is not a retrofit tool

`scripts/repair-in-place.sh` exists for a narrower case: a user
unzipped the template tarball *into* an otherwise-empty project
directory and needs the scaffold normalized (TEMPLATE_VERSION
stamped, registers reset). It is not a general in-place retrofit.
Do not invoke it against a populated source tree — it will not
audit, will not triage, and will not preserve source content.

### 2.4 Interstitial cases

Some projects arrive in shapes that are not cleanly "fresh",
"unzipped", "upgrade", or "retrofit". Route as follows:

- **Half-scaffolded, Step 2 abandoned** — `scripts/scaffold.sh`
  ran successfully but the Step 2 scoping conversation never
  closed (no `CHARTER.md`, empty registers). **Resume Step 2;
  do not retrofit.** Nothing has accreted that would invalidate
  the scaffold's clean state.
- **Scaffold hand-edited with source code** — the scaffold ran,
  the customer then hand-edited the tree (dropped code files in,
  wrote partial docs, committed against the scaffold). **Treat
  the hand-edited scaffold as `<src-path>` and retrofit it into
  a fresh `<tgt-path>` — a recursive retrofit.** The hand-edited
  scaffold has lost the clean state; the retrofit re-establishes
  it via audit. Do not attempt to "continue from where the
  scaffold left off"; that path has no audit trail.
- **External codebase imported into a scaffold tree** — customer
  ran `scripts/scaffold.sh`, then copied / extracted / git-
  subtree-merged an external codebase *into* the scaffolded
  directory. This is Path B (§ 2.2) in disguise. **Extract the
  imported code to a sibling scratch directory, delete the
  scaffold, re-run `scripts/scaffold.sh` to a fresh target, then
  retrofit normally with the sibling as `<src-path>`.** Do not
  attempt to separate template files from source files in-tree
  — the triage surface is too mixed.
- **Partial upgrade in progress** — `scripts/upgrade.sh` was
  interrupted mid-run on an existing project. This is an upgrade
  concern, not a retrofit concern. Resolve via the upgrade path
  (`--dry-run` + per-file conflict resolution) before considering
  retrofit.
- **Scaffold at older `TEMPLATE_VERSION`, hand-edited and drifted**
  — customer wants both retrofit and upgrade in one motion (issue
  #46). Retrofit uses the fresh target's scaffolded
  `TEMPLATE_VERSION` (the newest); the upgrade from old→new is
  implicit. Do not attempt retrofit and upgrade in separate passes;
  one retrofit produces a clean result at the latest version. If
  the customer specifically wants the retrofit to preserve the
  *old* `TEMPLATE_VERSION`, record it as an ADR (usual reason:
  deferred upgrade that will run as a separate `scripts/upgrade.sh`
  motion later).

If the customer's project shape does not match any of the above
and does not match § 2.1's four paths, `tech-lead` escalates
before proceeding — there may be a template gap to file upstream
(`docs/ISSUE_FILING.md`).

## 3. Hard rules specific to retrofit

1. **Source is read-only.** No agent writes to `<src-path>`. If a
   source artifact needs transformation (format conversion, de-PII,
   secret scrubbing, etc.), **copy to a scratch path**
   `<scratch-path>` and edit there. `<scratch-path>` is the only
   location where source-derived content may be edited before
   ingestion into `<tgt-path>`.
2. **Source is frozen during and after the retrofit.** Customer
   has agreed not to edit `<src-path>` during the retrofit and
   will not return to it afterward. Concurrent edits abort the
   retrofit; post-retrofit edits fork the project and invalidate
   the CHARTER.
3. **No bulk copy.** `cp -r` from `<src-path>` to `<tgt-path>` is
   prohibited. Every artifact that moves is selected by an agent
   with a cited rationale.
4. **IP triage gates every move.** Any artifact flagged as
   external (or derived from external) goes through `researcher`'s
   IP triage (§ 8) before landing in `<tgt-path>`. Default
   assumption: external unless proven project-created.
5. **Stage order is non-negotiable.** Pre-flight → A → B → C →
   D → E (§ 4). No stage begins before the previous stage's exit
   criteria are met (§ 5).
6. **Hard Rule #3 still applies.** No commits to `<tgt-path>`
   without `code-reviewer` review.
7. **Hard Rule #4 still applies — and the audit can *discover*
   safety-critical surface.** Any retrofit decision touching
   safety-critical, irreversible, or customer-flagged critical
   logic requires live customer approval obtained by `tech-lead`.
   In retrofit, Stage A can surface safety-critical semantics
   the customer did not flag at pre-flight. **Any artifact whose
   Stage A / Stage B evidence places it on a safety-critical path
   routes through Hard Rule #4 before Stage C assigns a decision-
   matrix outcome**, regardless of which outcome (pull as-is,
   rewrite, etc.) would otherwise be picked. `tech-lead` obtains
   the live approval; `researcher` appends it verbatim to
   `CUSTOMER_NOTES.md`.
8. **Hard Rule #7 still applies — two-fire pattern mirroring
   Hard Rule #4.** Any retrofit row touching authentication,
   authorization, secrets, PII, or network-exposed endpoints
   triggers `security-engineer` involvement at **two** points,
   not one:
   - **(a) Stage B triage advisory (early fire).** When
     `researcher` first tags a triage row as auth / secrets /
     PII / net-endpoint, `security-engineer` is looped in to
     produce a short advisory note (license-compatibility
     concerns, committed-secret rotation cost, endpoint-
     exposure implications, restrictive-redistribution risks).
     Advisory is appended to `docs/retrofit/B-triage.md` and
     becomes an input to the Stage C plan. This fire is
     *non-binding*; it surfaces the concern early enough that
     Stage C can encode the right disposition rather than
     locking in a disposition that `security-engineer` would
     later have to block.
   - **(b) Stage E binding sign-off.** Before `code-reviewer`
     reviews a Hard-Rule-#7 plan row at Stage E,
     `security-engineer` signs off in `CUSTOMER_NOTES.md`
     alongside the Hard Rule #4 customer approval. The sign-off
     references the relevant security assurance artefact per
     `docs/templates/security-template.md`.

   This two-fire pattern mirrors Hard Rule #4 (surfaced at
   audit, bound at commit): surface early so the plan is right,
   bind at the latest pre-commit point so the gate is
   authoritative.
9. **Registers take evidence over description.** When the
   customer's mental model of the source conflicts with what the
   source actually contains, registers reflect what is there —
   not what the customer said. Discrepancies become
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

`tech-lead` orchestrates transitions, dispatches the named role,
and enforces stage gates. Any agent hitting an unanswerable
question returns to `tech-lead` per the escalation protocol.

### 4.1 Pre-flight — readiness triage

Runs **before** the scaffold even exists. `tech-lead` inspects
`<src-path>` at a glance to decide whether a retrofit is viable,
and records the answers in `docs/retrofit/preflight.md` (directory
created inside `<tgt-path>` once scaffolded; until then, notes
live in the session and are written after scaffold).

Pre-flight checklist — answer each with "present / absent /
partial / unknown":

- [ ] **Version control.** Is `<src-path>` under git (or other VCS)?
      Is `HEAD` clean? Is there a default branch the customer
      considers canonical? **Record `<src-path>` HEAD SHA + UTC
      timestamp into `docs/retrofit/preflight.md`** — Stage E
      DoR re-verifies this to detect source drift (anti-pattern
      #12). If not under VCS, retrofit is viable but (a) the
      drift check falls back to a content-hash snapshot, and
      (b) registers carry a "no prior history" risk. **Drift-hash
      recipe (binding, issue #49):**
      - Under VCS: HEAD SHA (above).
      - Not under VCS: output of
        `find <src-path> -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum`
        (the `-type f` limits to regular files, `sort -z` makes the
        ordering deterministic across filesystems, and the chained
        sha256sum collapses the manifest to a single 64-char hash
        that fits cleanly in `preflight.md`).
      - Under VCS but `.git` is shallow / squashed / fresh-clone
        and HEAD is not meaningful: fall back to the non-VCS
        recipe and note why in `preflight.md`.
- [ ] **License.** Does `<src-path>` declare a license? Is it
      compatible with the project's intended disposition (target
      license decided in Step 2 scoping)?
- [ ] **Build / run reproducibility.** Is there a dependency
      manifest (`package.json`, `Cargo.toml`, `pyproject.toml`,
      `go.mod`, etc.)? A lockfile? A README that describes how to
      build? If none, flag as risk R-0001 for Stage D.
- [ ] **Test suite.** Is there a test directory? A CI config
      (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`)?
      What is the current pass/fail state if reproducible?
- [ ] **Documentation.** Is there a `README.md`? An `ARCHITECTURE.md`
      or equivalent? An ADR directory? A `CHANGELOG.md`?
- [ ] **Secrets / PII / credentials.** Are there any obvious
      in-repo secrets? `.env` files checked in? API tokens in
      history? If yes, Stage E must handle them (scrub to
      `<scratch-path>`; do not carry to `<tgt-path>`; consider
      rotation as a risk item).
- [ ] **Customer / employer / third-party identifying content
      (issue #56).** Are there vendor product names, customer-site
      codenames, plant/tenant identifiers, or operational context
      strings that would identify a customer or employer the
      project is embedded in? These need a **distribution-posture
      ruling at pre-flight, not at Stage D** — their Stage B
      triage disposition depends on whether the target repo will
      ever leave the local host. Public-target retrofits with
      identifying content require Hard-Rule-#4 customer approval
      before triage begins; a wrong call is expensive to undo
      (git history rewrite).
- [ ] **Size.** Rough LoC + file count. A retrofit for a 10-file
      project and a 10 000-file project need different pacing.
- [ ] **Open issues.** Is there a GitHub/GitLab/Jira issue tracker
      in use? How many open issues? Stage F will migrate these
      into `docs/tasks/` + `docs/OPEN_QUESTIONS.md`.
- [ ] **Team charter-equivalent.** Does `<src-path>` have any
      existing governance document (README, CONTRIBUTING,
      CODE_OF_CONDUCT, mission statement)? These seed Stage D's
      charter reconstruction.

Pre-flight go / no-go:

- **Go** — proceed to Stage A.
- **No-go, fixable** — pre-flight surfaced a blocker the customer
  can remove (e.g., "source is not under VCS; customer needs to
  `git init` and commit a snapshot first"). `tech-lead` returns
  to the customer with the specific blocker and the pre-flight
  resumes after.
- **No-go, blocking** — source is too fragmented, or IP posture is
  so unclear that no triage is possible without customer rulings
  first. `tech-lead` escalates to the customer for scope
  reduction.

### 4.2 Stage A — `onboarding-auditor` inventory

Mandate: a zero-context walk of `<src-path>` producing a single
report at `<tgt-path>/docs/retrofit/A-inventory.md`.

Contents:

- **Tree summary** — directories, file counts, rough sizes, file-
  type breakdown.
- **Detected tooling** — languages, frameworks, build systems,
  test frameworks, CI configs, linters, formatters, lock managers.
- **Evidence of conventions** — style configs (`.editorconfig`,
  `.prettierrc`, `.rustfmt.toml`, `ruff.toml`, etc.), branching
  model hints (`main` vs `master`, presence of `develop`, `gitflow`
  traces), review process hints (CODEOWNERS, PR template, branch
  protection rules if discoverable).
- **Doc artifacts found** — `README.md`, `ARCHITECTURE.md`, ADRs,
  changelogs, runbooks, anything customer-facing.
- **Friction log** — things that confused the auditor on a cold
  read. Each entry is a candidate for `CHARTER` open-questions or
  `LESSONS.md`.
- **Ambiguous artifacts** — files whose authorship / license /
  provenance is not obvious. Input to Stage B.
- **Suspicious artifacts** — vendored third-party code, generated
  files, binaries, apparent secrets. Input to Stage B.
- **Identifying-content candidates (binding, issue #81)** — run a
  regex sweep against the source tree for universal identifying
  classes, not customer-specific known strings. Output a per-hit and
  per-line table: path, line, matched class, excerpt, proposed
  disposition. Aggregate verdicts such as "all 192.168.* hits are
  examples" are forbidden because they hide bad hits among benign
  ones. Also write `docs/retrofit/regex-commands.md` with the exact
  commands or tool configuration used: regex patterns, include/exclude
  globs, binary-file handling, generated/vendor directory policy, and
  the date / agent that ran the sweep. Starter classes:

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

  The Stage A regex set is a floor, not a complete secret scanner.
  `onboarding-auditor` is deliberately zero-context and must not be
  given customer-specific personal, service-name, employer, tenant, or
  site-code patterns unless `tech-lead` documents a narrow exception
  in the dispatch brief and the pattern itself is non-secret and
  non-tribal. The normal source for customer-specific patterns is
  Stage B: `researcher`, with access to pre-flight notes,
  `CUSTOMER_NOTES.md`, and SME inventories, may add those classes.
  Every added class updates both the per-hit table and
  `regex-commands.md` so Stage E reviewers can re-run the same set.
- **Convention-conflict register (seed)** — where the source's
  conventions differ from template defaults (see § 7 for the
  handling protocol). Example rows: "source uses `master`, template
  docs reference `main`"; "source uses `poetry`, template docs
  assume `pip-tools`". **Stage A seeds rows (observed conflict);
  Stage C resolves them (migrate-to-template-default or
  pin-source-via-ADR per § 7). The auditor does not decide.**
  (Issue #42.)

The auditor does not decide what moves. Its output is input to
Stages B, C, D, F.

### 4.3 Stage B — `researcher` IP triage

Input: Stage A's ambiguous + suspicious lists.
Output: `<tgt-path>/docs/retrofit/B-triage.md`, populated SME
inventories, proposed `.gitignore` additions.

For each listed artifact, `researcher` assigns one of:

- **project-created** — safe to commit under the target's license.
- **external — permissive license** — may be included; cite
  license + source in the relevant `docs/sme/<domain>/INVENTORY.md`
  row.
- **external — restricted** — goes to `docs/sme/<domain>/local/`
  (gitignored) with an inventory row; paraphrase-and-cite only.
- **derived — substantive transformation** — may be committed as
  paraphrase with citation.
- **unclear** — escalate to `tech-lead`, who batches for the
  customer.

`researcher` also produces the `.gitignore` delta covering any
new local-only paths.

`researcher` consumes the Stage A identifying-content table and
assigns a disposition to every hit. `researcher` is also the default
owner for customer-specific identifying classes surfaced by pre-flight,
`CUSTOMER_NOTES.md`, or SME inventories, because those inputs are out
of scope for the zero-context `onboarding-auditor`. Any new identifying
class found during Stage B is appended as a new per-hit row, not
summarized in an aggregate note. The exact added regex / command is
appended to `docs/retrofit/regex-commands.md`. Hits that touch auth /
secrets / PII / network endpoints trigger the Hard-Rule-#7 early fire
below.

**Hard-Rule-#7 early fire.** (Binding obligation, per issue #50:
`researcher` MUST loop in `security-engineer` when a triage row is
tagged auth / secrets / PII / net-endpoint. The advisory produced
at Stage B is **non-binding** and does not gate Stage B closure;
the binding Hard-Rule-#7 sign-off is at Stage E.) Either from
Stage A suspicious-list carry-over or newly surfaced during
`researcher`'s own review, the loop-in produces an advisory note
that appends to `B-triage.md`, flagging concerns the Stage C plan
must encode (license-compatibility of auth libraries, committed-
secret rotation cost, endpoint-exposure implications, restrictive-
redistribution risks). Surfacing at Stage B prevents Stage C from
locking in dispositions that `security-engineer` would later have
to block; the binding sign-off lives at Stage E (§ 4.6 / § 3
rule 8).

**New triage disposition (issue #56): project-authored,
distribution-restricted.** Material the project authored but whose
redistribution is limited by an external relationship (employer,
customer, NDA, regulatory). Landing depends on the target's
distribution posture (recorded at pre-flight per § 4.1):
- target is **local-only** → commit as-is with a `RISKS.md` row
  capturing the restriction.
- target is **private-shared** (named collaborators) → as above,
  plus a `STAKEHOLDERS.md` row naming the boundary.
- target is **public** (any) → **escalate**: paraphrase-and-
  redact, or Leave-behind, at customer ruling. Hard Rule #4 fires
  (live customer approval) — git-history rewrite is expensive.

### 4.4 Stage C — `architect` structural migration plan

Input: Stages A + B.
Output: `<tgt-path>/docs/retrofit/C-plan.md`.

The plan maps source paths to target paths with a rationale per
row. Every row picks one of the § 6 decision-matrix outcomes.

The plan also resolves **template-vs-source structural conflicts**
— cases where the template ships a file or convention that
collides with the source's existing shape. See § 7 for the
conflict-handling protocol. Examples:

- Source has `docs/decisions/`; template has `docs/adr/`.
  Architect picks: rename source to template convention (default),
  or record an ADR pinning the source convention.
- Source has `master` as default branch; template docs reference
  `main`. Architect recommends the rename, or records an ADR pinning
  `master`.
- Source has a bespoke CI system; template assumes GitHub Actions.
  Architect declares which survives.

Decisions that cross cost / schedule / risk thresholds are
arbitrated per `CLAUDE.md` § Routing defaults (architect + PM).

### 4.5 Stage D — `project-manager` charter reconstruction

Input: Stage C plan + Stage A friction log + Pre-flight notes.
Output: populated `<tgt-path>/docs/pm/CHARTER.md`,
`STAKEHOLDERS.md`, `RISKS.md`, `CHANGES.md`, `LESSONS.md`,
`TEAM-CHARTER.md`, `AI-USE-POLICY.md`.

Charter reconstruction uses three evidence sources:

1. **Git log** — `git log --all --format='%h %ad %s' --date=short`
   against `<src-path>`. Produces a dated activity timeline; PM
   mines it for: inception date (first commit), major milestones
   (release tags, large merges), contributor list (stakeholder
   candidates), pace (commit cadence → project-phase inference).
2. **README / existing docs** — the source's self-description.
   Treated as customer-provided evidence (one step removed from
   CUSTOMER_NOTES.md). Discrepancies between README and git log
   go to OPEN_QUESTIONS.md.
3. **Customer interview** — `tech-lead` asks what the git log and
   README do not answer: intent, non-goals, who the end users are,
   what "done" looks like, regulatory constraints, performance
   SLAs. One question per turn, per Step-2 protocol.

Output-specific notes:

- **`CHARTER.md`** — the **new** project's charter, informed by
  the retrofit. Not a verbatim port of any source document. Cites
  its evidence: "Inception date inferred from git log
  `<src-path>` 2024-03-11"; "Non-goals per customer interview
  2026-04-24".
- **`STAKEHOLDERS.md`** — contributors from `git log` with
  authorship > N commits, external SMEs implied by triage (e.g.,
  vendor-specific code implies a vendor relationship), regulatory
  bodies implied by domain.
- **`RISKS.md`** — carry-overs from source known-issues / TODOs,
  plus retrofit-specific risks: dependency drift, license
  uncertainty, loss of tacit knowledge, secret exposure in history
  (if pre-flight found any), tooling gaps.
- **`CHANGES.md`** — the retrofit itself as `CH-0001`.
- **`LESSONS.md`** — anything from Stage A's friction log that
  generalizes.
- **`TEAM-CHARTER.md`** — reconstructed if possible from
  CONTRIBUTING / CODE_OF_CONDUCT; otherwise flagged for Step 2
  follow-up. **Inherited naming category (issue #54):** if
  `<src-path>/.claude/agents/` (or equivalent team-roster
  directory) exists and encodes a coherent naming scheme,
  reconstruct `TEAM-CHARTER.md` to:
  (a) name the inherited category and enumerate the existing
      role→name mapping;
  (b) map each inherited name to a canonical role per
      `CLAUDE.md` § Agent roster — inherited names that don't
      map cleanly are flagged for Step 2 customer decision
      (retire / merge / keep as custom SME);
  (c) preserve the inherited `docs/AGENT_NAMES.md` at the
      target unless the customer explicitly requests refresh.
  Step 3 / Step 3a of FIRST ACTIONS is then a **confirmation**,
  not a fresh conversation: tech-lead presents the inherited
  category and mapping; customer confirms or requests refresh.
- **`AI-USE-POLICY.md`** — new, per template default; customer
  ratifies in Step 2.

### 4.6 Stage E — `software-engineer` execution, `code-reviewer` gate (+ conditional `security-engineer`)

Input: Stage C plan + Stage B triage + Stage D charter.
Output: moves applied to `<tgt-path>`, commit-by-commit reviewed.

Rules:

- Each plan row = its own commit (trivial moves may batch).
  Commit message cites the plan row.
- `code-reviewer` reviews per commit per Hard Rule #3. Retrofits
  accrete queue fast; resist batching.
- **Stale plan-row evidence escalates (issue #43).** If fresh
  context at Stage E suggests a Stage B / C decision was wrong
  (e.g., a row's ambiguity was resolved at Stage B but new
  evidence contradicts the resolution), `software-engineer`
  **halts the row and escalates to `architect`** rather than
  deciding locally. The row re-enters Stage C for re-planning;
  Stage E resumes on the remaining rows in the meantime.
- **Scaffold baseline commit (issue #52).** The initial
  `scripts/scaffold.sh` output may be committed as a single
  "Initial scaffold — template vX.Y.Z" commit **without
  code-reviewer review**, on the basis that the content is
  mechanical template output traceable to the upstream template
  tag. `code-reviewer`'s first review applies to the first
  authored commit in the target repo (typically the pre-flight
  artefact or the Stage A inventory).
- **Retrofit audit-artefact commits are subject to Hard Rule #3,
  with narrowed scope (issue #52).** `docs/retrofit/*` and
  `docs/pm/*` register commits get `code-reviewer` review with
  scope narrowed to: (a) evidence-traceability (every claim cites
  an input), (b) redaction hygiene, (c) no committed secrets / PII
  / restricted-source / customer-confidential text. This is not a
  code review in the narrow sense, but the rule still applies.
- **`security-engineer` reviews before `code-reviewer` on any
  plan row flagged Hard-Rule-#7** (auth, authorization, secrets,
  PII, network-exposed endpoints), per § 3 rule 8. Sign-off is
  recorded in `CUSTOMER_NOTES.md`; the reference to the security
  assurance artefact is noted in the commit message.
- **Identifying-content regex re-run (issue #81).** Before each
  public-target or private-shared Stage E commit, the implementer
  re-runs the exact Stage A / B regex set recorded in
  `docs/retrofit/regex-commands.md` against the staged tree and
  updates the per-hit table. `security-engineer` and `code-reviewer`
  independently re-run the same set for rows they review; they do not
  trust the implementer's aggregate summary.
- Source-derived content needing edits was edited in
  `<scratch-path>` (Hard Rule § 3.1). Final form lands in the
  commit.
- External-restricted material lands in
  `docs/sme/<domain>/local/` (gitignored); the inventory row is
  committed.
- Any secret found in the source is scrubbed before move;
  rotation is recorded as a risk and as a Hard-Rule-#7 item.

### 4.7 Stage F — `project-manager` ticket migration (optional)

Runs if pre-flight found an external issue tracker in use.

Input: source issue tracker export (JSON / CSV / GitHub API pull).
Output: rows in `<tgt-path>/docs/tasks/` and
`<tgt-path>/docs/OPEN_QUESTIONS.md`.

Mapping:

- Source issue with **technical scope** → `docs/tasks/T-NNNN.md`
  shaped per `docs/templates/task-template.md`. Preserve the
  source issue ID as a cross-reference field.
- Source issue that is a **question for the customer** →
  `docs/OPEN_QUESTIONS.md` row.
- Source issue that is a **bug** → `docs/tasks/T-NNNN.md` tagged
  `type: bug`, plus a `docs/pm/RISKS.md` row if severity warrants.
- Source issue that is **closed** → archived per § 6 Leave-behind
  with rationale "closed in source; record preserved in
  `docs/retrofit/archived-tickets.md`".
- Source issue that is **stale / abandoned / unclear** →
  `docs/retrofit/archived-tickets.md` with rationale; do not carry
  forward.

**Versioned-doc governance (issue #55).** If `<src-path>` governs
via versioned documents (contract files, decision logs, spec
zips) rather than an external tracker, Stage F treats the contract
file(s) / decision log(s) as the tracker:

- Each open row in a contract-style doc maps to one
  `docs/tasks/T-NNNN.md`, preserving the source row ID as a
  `source-contract:` field.
- Decision-log WIP entries map per their own shape: technical →
  task; customer call → `docs/OPEN_QUESTIONS.md`; risk-tagged →
  `docs/pm/RISKS.md`.
- Closed / superseded rows archive to
  `docs/retrofit/archived-tickets.md` with their source IDs and a
  one-line rationale.
- The source's contract file(s) and decision log(s) are themselves
  migrated as regular Stage C / Stage E artefacts (typically to
  `docs/architecture/` and `docs/decisions/` or the target's
  convention). Stage F only covers the **row-by-row work-queue
  migration**, not the host-document migration.

Stage F preserves traceability: every `T-NNNN` that originated
in the source has a `source-issue:` or `source-contract:` field
citing tracker / contract + ID.

### 4.8 Remote disposition decision (conditional)

Runs when pre-flight or Stage A found a source git remote URL.
Owned by `release-engineer` under `tech-lead`; if no
`release-engineer` is available, `tech-lead` queues the decision
record for `researcher` and routes any git mechanics to the
appropriate operator.

Before close-out, `tech-lead` asks the customer one atomic remote
disposition question with explicit options:

- **Same remote, force-push target `main` over source `main`.**
  Destructive unless the source ref is archived first. Requires live
  customer acknowledgement and a pre-retrofit tag or archive branch.
- **Same remote, push target to a new branch.** Preserves source
  `main`; target lives on a sibling branch until default-branch swap.
- **Same remote, archive source branch then push target `main`.**
  Preserves source under `legacy/main` or equivalent, then promotes
  target.
- **New remote.** Target lives in a sibling repository; source becomes
  read-only archive.
- **No remote yet.** Target stays local; revisit later.

Route the ruling to `researcher` for a verbatim `CUSTOMER_NOTES.md`
entry, cite it from `docs/retrofit/CLOSURE.md`, and do not declare
retrofit close-out complete without either a ruling or an explicit
customer-deferred note.

## 5. Stage gates

Each stage has entry (DoR) and exit (DoD). `tech-lead` checks both.

| Stage | Entry (DoR) | Exit (DoD) |
|---|---|---|
| Pre-flight | Preconditions § 1.3 met | Pre-flight checklist complete; go/no-go recorded |
| A | Pre-flight = Go | `A-inventory.md` complete; all source directories visited; friction / ambiguous / suspicious / convention-conflict lists populated |
| B | A DoD met | Every row in ambiguous + suspicious has a triage outcome; `.gitignore` delta prepared; SME inventories updated |
| C | A + B DoD met | Every artifact has a target destination or a "leave" outcome with rationale; every convention conflict resolved (either migrate-to-template-default or pin-source-via-ADR) |
| D | C DoD met | CHARTER, STAKEHOLDERS, RISKS, CHANGES, LESSONS populated with citations; first post-retrofit milestone defined |
| E | C + D DoD met; **`<src-path>` HEAD SHA re-verified against pre-flight record** (mismatch aborts per § 3.2) | All plan rows executed and reviewed; identifying-content regex set re-run and per-hit table updated; `code-reviewer` sign-off per row; `security-engineer` sign-off on every Hard-Rule-#7 row recorded in `CUSTOMER_NOTES.md`; `OPEN_QUESTIONS.md` reflects carry-overs |
| F (if applicable) | E DoD met | Source tickets mapped per § 4.7; `archived-tickets.md` records closed + stale; `docs/tasks/` populated |
| Remote disposition (if applicable) | E DoD met; source remote URL recorded | Customer ruling recorded; remote action complete or explicitly deferred; `CLOSURE.md` cites disposition |

No stage begins before the previous stage's DoD is met (Hard Rule § 3.5).

**Cross-stage Hard-Rule gates (binding).** Independent of stage
DoD, two gates fire on any row they apply to. Both follow the
same two-fire pattern: surface early (to shape the plan), bind
at the latest pre-commit point (to make the gate authoritative).

- **Hard Rule #4 gate.**
  - *Early fire:* any artifact whose Stage A / B evidence
    places it on a safety-critical path routes through
    `tech-lead` for live customer approval *before* Stage C
    assigns a decision-matrix outcome. Applies to rows where
    "safety-critical" emerges from the audit, not only rows
    the customer pre-flagged.
  - *Binding sign-off:* customer approval routed by `tech-lead`
    and appended verbatim by `researcher` in `CUSTOMER_NOTES.md`
    before the row's Stage E commit.

- **Hard Rule #7 gate.**
  - *Early fire:* any artifact tagged auth / secrets / PII /
    net-endpoint at Stage B triggers a `security-engineer`
    advisory note appended to `B-triage.md` before Stage B
    closes (§ 4.3). Non-binding; Stage C's plan must consume
    the advisory.
  - *Binding sign-off:* `security-engineer` reviews and supplies
    a sign-off for `researcher` to append in `CUSTOMER_NOTES.md`
    at Stage E *before*
    `code-reviewer`, alongside the Hard Rule #4 customer
    approval where both apply.

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

**Orthogonal to matrix outcome:** a row tagged safety-critical
(Hard Rule #4) or Hard-Rule-#7 fires the corresponding § 5
cross-stage gate regardless of which outcome it carries. "Pull
as-is" on a safety-critical artifact still needs live customer
approval; "rename + pull" on an auth module still needs
`security-engineer` sign-off.

Every "Leave behind" and "Rewrite" carries a rationale so future
audits can reconstruct reasoning.

## 7. Handling pre-existing conventions that conflict with template defaults

Existing projects ship with conventions (style, branching, review
process, directory layout) that may collide with template
defaults. The rule is:

### 7.1 Default: migrate to template conventions

For each conflict, the default is **migrate the source to the
template convention**. Rationale: template conventions are chosen
to be portable across projects and standards-aligned; preserving
per-project convention drift erodes the framework's value.

Examples of automatic migration:

- Default branch `master` → `main` (unless there is tooling that
  hard-codes `master`; then escalate to architect).
- Convention `docs/decisions/` → `docs/adr/` using the template's
  v0.13.0 Three-Path ADR shape.
- Bespoke commit-message format → Conventional Commits (if the
  template default) unless the source has CI checks enforcing the
  old format that are themselves being kept.

### 7.2 Exception: pin source convention via ADR

If migrating a source convention is expensive (team-trained-on-it,
external tooling depends on it, regulatory requirement), the
**source convention may be pinned** by writing an ADR under
`<tgt-path>/docs/adr/` using the v0.13.0 Three-Path template:

- **Minimalist option** — migrate to template default.
- **Scalable option** — pin source convention; add tooling to
  bridge to template expectations.
- **Creative option** — hybrid that satisfies both (named even if
  rejected, per Three-Path rule).

Customer signs off on the chosen option. The ADR links from
`docs/INDEX.md` and is cross-referenced from the convention's
home (e.g., CONTRIBUTING.md if branching convention).

**Guardrails (issue #44, binding):**

1. **Cost citation required.** Every § 7.2 pinning ADR MUST cite
   the specific migration cost justifying the pin: team-training
   hours, tooling cost, regulatory dependency. Costs are
   auditable; preferences are not. ADRs without a cost citation
   are **rejected at Stage C** — `architect` returns the row for
   re-decision (migrate-to-default or supply the cost).
2. **Cap on pinned exceptions.** If a project accumulates more
   than 3 pinned-convention ADRs in a single retrofit, `architect`
   MUST write a meta-ADR asking whether the template is wrong for
   this domain, rather than accreting exceptions. The meta-ADR
   either escalates the mismatch upstream
   (`docs/ISSUE_FILING.md`) or documents why the template is a
   genuinely poor fit and the project should fork its conventions.

### 7.3 Conflicts requiring escalation (not ADR-able)

Some conflicts are not design choices; they are safety invariants:

- Template Hard Rules (CLAUDE.md § Hard rules) may not be
  overridden by source convention. Example: if the source's
  existing review process does not require a reviewer, the
  retrofit adopts Hard Rule #3 (no commit without `code-reviewer`
  review). Full stop.
- Template IP policy may not be weakened. Example: if the source
  routinely committed quoted standards text, the retrofit
  paraphrases-and-cites per IP policy.

These are recorded in `docs/retrofit/convention-conflicts.md`
with the resolution (always template default) and a brief
rationale for audit.

## 8. IP triage protocol

Governed by `docs/IP_POLICY.md`. Retrofit-specific notes:

- **Default is external.** Any artifact without clear project-
  authored provenance is treated as external until proven
  project-created. `git log` from `<src-path>` showing in-project
  authorship is sufficient proof; absence of log info (fresh
  clone, squashed history) is not.
- **Restricted-source clauses.** Where the source contains
  materials with explicit prohibitions (e.g., "NO AI TRAINING"),
  `researcher` records the clause in the inventory and applies
  paraphrase-and-cite. Transient in-context reading is permitted
  per the narrow interpretation (customer ruling 2026-04-23);
  persistent embedding is not.
- **Derivative work.** A target version of a source derivative
  must be a **substantive transformation** and cite the source by
  inventory row ID. Line-for-line translation / reformatting does
  not count.
- **Secrets in history.** Git history that contains committed
  secrets is never carried forward. Target gets a fresh history
  (Stage E commits against the scaffolded `git init`). Rotation
  of the exposed secret is a Stage D risk.

### 8.1 Nested sibling git repositories (issue #53)

If `<src-path>` contains one or more nested git repositories that
are excluded from `<src-path>`'s git tracking (typically via
`.gitignore` and a documented boundary invariant — the
"meta-repo + sibling-fork" pattern), the retrofit treats each
nested repo as an **out-of-scope artefact**:

- **Pre-flight (§ 4.1)** records nested repo paths, each nested
  HEAD SHA (or content-hash recipe per issue #49 if the nested
  repo is not under VCS), and the source's declared rationale
  for the exclusion. Stage E drift-check re-verifies all recorded
  HEADs.
- **Stage A (§ 4.2)** does not walk into nested repos. Their
  presence and exclusion are one line in `A-inventory.md`; their
  contents are not inventoried.
- **Stage B (§ 4.3)** triages each nested repo as a single
  artefact with its own license + provenance, landing as an SME
  inventory row.
- **Stage C (§ 4.4)** decides whether the target preserves the
  nesting or flattens it. **Default: preserve** — the source's
  boundary choice was deliberate.
- **Stage E (§ 4.6)** moves the `.gitignore` entry covering the
  nesting into the target; the nested repo itself is **not
  moved** by the retrofit. The customer moves / re-clones it
  out-of-band after the retrofit completes.

## 9. Migration of existing issues / tickets

Handled by Stage F (§ 4.7). Covers GitHub Issues, GitLab Issues,
Jira, Linear, Shortcut, Trello, ad-hoc TODO files, **and
contract-file or decision-log governance** (versioned-doc shape
where open work lives as rows in checked-in documents — see § 4.7
"Versioned-doc governance").

Flow:

1. Pre-flight detects the tracker and records access method
   (export path, API token, URL).
2. Stage E completes before Stage F begins (no parallel churn).
3. PM pulls a dump. For each item, apply the § 4.7 mapping.
4. Source-issue IDs are preserved as cross-references; they are
   **not** the new task IDs. New IDs are allocated sequentially
   from `T-0001`.
5. If the source used issue labels (`bug`, `enhancement`, etc.),
   PM proposes a label taxonomy for `<tgt-path>` informed by the
   source's usage; customer ratifies.
6. Closed and stale items are archived in
   `docs/retrofit/archived-tickets.md` with their source IDs and
   a one-line rationale. They are **not** deleted from the
   source tracker — the source tracker is read-only in this
   retrofit and the customer may choose to close the source
   tracker out-of-band after the retrofit.

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

The directory is committed. It is the retrofit's durable record
for future audits and for a possible rollback decision.

`CLOSURE.md` must include: final source SHA / drift hash checked at
Stage E start, identifying-content regex re-run evidence from
`regex-commands.md`, Stage-gate checklist status, outstanding
carry-over questions, remote disposition (§ 4.8), rollback pointer,
and customer sign-off or explicit deferred-close rationale.

## 12. Rollback plan

A retrofit can stall or fail. The plan is deliberately minimal:

### 12.1 Stall detection

Stall signals that warrant rollback consideration:

- A stage DoD cannot be met because the source is too fragmented,
  too under-documented, or too IP-encumbered.
- **Customer-decision pace lags (issue #40, agent-observable).**
  More than **3** rows in `docs/OPEN_QUESTIONS.md` with
  `answerer: customer` and `status: open` for more than **5
  days** (UTC). N=3, M=5 are project-tunable defaults; record any
  override in `docs/pm/LESSONS.md`. An agent can count this; an
  agent cannot assess "pace" qualitatively.
- Pre-flight findings were wrong in material ways (e.g., "source
  has tests" was recorded but Stage A finds none).
- Stage C plan grows past the point where the customer still
  thinks the retrofit is cheaper than a green-rewrite.

When any two of these hold, `tech-lead` raises the question:
**continue, pivot, or roll back?**

### 12.2 Continue

Default if the stall is tractable. `tech-lead` re-scopes the
remaining stages (e.g., drops Stage F, archives more artifacts as
leave-behind) and reports the reduction to the customer for
sign-off.

### 12.3 Pivot

Switch from retrofit to **green rewrite guided by the source as
reference**. Mechanism: `<tgt-path>` starts clean (revert all
Stage E commits); `<src-path>` becomes a read-only reference the
team consults during green development. Register populations from
Stage D are kept (charter, risks, lessons — all valuable evidence
even if the code is not being ported). `docs/retrofit/CLOSURE.md`
records the pivot, including remote disposition and regex re-run
status if any source-derived material reached the target.

**Artifact-survival list (issue #41).** On pivot, these survive:
`docs/retrofit/preflight.md`, `A-inventory.md`, `B-triage.md`,
`C-plan.md` (kept as historical record, not as a forward
manifest); all `docs/pm/*` Stage D outputs (`CHARTER.md`,
`STAKEHOLDERS.md`, `RISKS.md`, `CHANGES.md`, `LESSONS.md`,
`TEAM-CHARTER.md`, `AI-USE-POLICY.md`); SME inventories;
any `docs/adr/` entries authored during the retrofit. **Reverted:
Stage E commits only** — the migration moves themselves. The
survival list prevents silent loss during pivot.

### 12.4 Roll back

True rollback when the retrofit has produced no viable forward
path:

1. **Write-before-delete (binding).** Before `<tgt-path>` is
   deleted, `tech-lead` finalizes
   `<tgt-path>/docs/retrofit/CLOSURE.md` with a "why
   rolled back" section naming the stall signals that fired
   (§ 12.1), the stage at which the retrofit stopped, remote
   disposition, and identifying-content regex status.
   `project-manager` copies generalizable lessons from the
   Stage D `LESSONS.md` and the retrofit's friction log into a
   standalone file the customer can carry forward — **default
   path (issue #47): `<tgt-path>/../retrofit-lessons-YYYY-MM-DD.md`**,
   a sibling of the doomed target in the parent directory the
   customer has already chosen. The customer may redirect the
   file elsewhere before the write, but the default requires no
   decision. Without this step, rollback destroys the audit
   trail the retrofit spent five stages building.
2. `<tgt-path>` is deleted (`rm -rf <tgt-path>` — reversibility
   per § 2.2 is why this is cheap).
3. `<src-path>` is unaffected (source-freeze was binding).
4. The customer and `tech-lead` meet to decide next steps: a
   smaller-scope retrofit of a subset of `<src-path>`, a pivot to
   green rewrite with a fresh scaffold, or abandon the template
   adoption entirely.
5. Lessons from the failed retrofit are recorded as an upstream
   issue so the playbook can grow (per `docs/ISSUE_FILING.md` if
   the project opted in).

Rollback is not a failure mode to avoid at all costs. It is a
valid outcome. A rolled-back retrofit that produced a clean
inventory, a solid triage, and a charter has produced real value
even if no code moved — *provided step 1 above preserves that
value before deletion*.

## 13. Anti-patterns

1. **Bulk copy.** `cp -r <src> <tgt>` and delete-what-does-not-
   belong. Skips audit, skips triage, imports unknown IP.
2. **Pre-filling registers before Stage A.** Charter from customer
   description alone, before the auditor walks the source. Source
   almost always contradicts the description on at least one
   point; charter wrong on day one.
3. **Running stages out of order.** Produces decisions on
   incomplete inputs.
4. **Editing in-tree under `<src-path>`.** Violates § 3.1. Use
   `<scratch-path>`.
5. **Skipping Stage E commit granularity.** Batching twenty moves
   into one commit because the reviewer is slow makes review
   unreliable and rollback impractical.
6. **Silent Leave-behind.** Dropping artifacts with no entry in
   `left-behind.md`. Future reader cannot tell whether considered-
   and-rejected or missed.
7. **Treating Stage A as a copy list.** Auditor produces
   inventory, not a manifest. Move decisions are Stage C.
8. **Invoking `scripts/repair-in-place.sh` against a populated
   source tree.** Out of scope for that script; see § 2.3.
9. **Migrating source conventions by default.** Opposite of § 7.1.
   Migrate to template defaults unless ADR pins source.
10. **Keeping secrets in history.** § 8 — fresh history in
    `<tgt-path>`, rotate exposed secrets, log as risk.
11. **Mid-stage abandonment without a § 12 decision.** A retrofit
    that halts after any stage without `tech-lead` invoking § 12
    (continue / pivot / roll back) leaves `<tgt-path>` in an
    inconsistent state with no audit-trail disposition. If work
    stops for any reason, § 12 fires; silence is not an option.
12. **Undetected source drift.** Source-freeze (§ 3.2) is
    *declared* at pre-flight but not *verified* at Stage E start.
    Pre-flight records `<src-path>`'s HEAD SHA + timestamp;
    Stage E re-checks before first move. A mismatch aborts the
    retrofit per § 3.2. Failing to perform this check is the
    anti-pattern, not the drift itself.
13. **Stale Stage D approvals invoked at Stage E.** Customer
    approvals gathered during Stage D attach to specific plan
    rows that existed at Stage C. If Stage E uncovers new
    context requiring a decision the customer did not rule on at
    Stage D, falling back on the Stage D approval as "already
    signed off" violates Hard Rule #4. Such a case escalates
    fresh to `tech-lead` for a live approval.
14. **Treating unratified escalations as ratified.** Stage B's
    "Escalate" outcome (§ 6) is parked until the customer rules.
    A Stage E move that acts on an escalated row as if the
    customer had approved it — because rollback would be awkward,
    or the schedule is tight — violates Hard Rule #1 (tech-lead
    is the channel) and Hard Rule #4 (approval must be live).
    The correct response is to halt the row and return to
    `tech-lead` for the pending customer call.

## 14. Exit criteria / Definition of Done

Retrofit is complete when **all** are true:

- [ ] Pre-flight checklist filed at `docs/retrofit/preflight.md`
      with go decision recorded.
- [ ] Stage A inventory closed (every source directory walked;
      report at `docs/retrofit/A-inventory.md`).
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
      from `docs/retrofit/regex-commands.md` completed and per-hit
      table updated.
- [ ] **Every Hard-Rule-#7 row has `security-engineer` sign-off**
      supplied to `researcher` and appended in `CUSTOMER_NOTES.md`
      with reference to the relevant security assurance artefact
      (§ 3 rule 8).
- [ ] **Every safety-critical row has live customer approval
      (Hard Rule #4)** obtained by `tech-lead`, routed to
      `researcher`, and appended verbatim in `CUSTOMER_NOTES.md` —
      dated, no cached approval, no agent-only path.
- [ ] Stage F (if applicable) complete: source tickets mapped to
      `docs/tasks/` + `docs/OPEN_QUESTIONS.md`;
      `archived-tickets.md` filed.
- [ ] First post-retrofit milestone defined in `CHARTER.md §
      Milestones` with an exit criterion.
- [ ] `OPEN_QUESTIONS.md` reflects any remaining customer calls
      the retrofit surfaced.
- [ ] `tech-lead` writes `docs/retrofit/CLOSURE.md`
      summarizing what moved, what was left, what the next
      milestone is, how long the retrofit took (for
      `LESSONS.md` generalization), identifying-content regex
      re-run evidence, and the remote disposition decision (§ 4.8).
- [ ] **`docs/INDEX.md` cross-links to
      `docs/retrofit/CLOSURE.md`** so future sessions
      discover the retrofit trail without having to know the
      path.
- [ ] **`TEMPLATE_VERSION` integrity check passes.** The file
      matches the scaffold-time stamp exactly (SemVer + git SHA
      + date — no drift, no hand-edit). The retrofit does not
      change the template version; it only populates the project.
- [ ] **Customer sign-off on retrofit completion** recorded in
      `CUSTOMER_NOTES.md` as a distinct entry dated to the
      retrofit's close. The retrofit sets the project's
      foundation; the sign-off is a Hard-Rule-#4-adjacent event
      and is not subsumed by any per-row approval gathered
      during Stages C–E.
- [ ] Step 2 Definition of Done (CLAUDE.md) is satisfied using
      retrofit findings as evidence; `tech-lead` can now dispatch
      the first post-retrofit work subagent.

## 15. Related artifacts

- `docs/TEMPLATE_UPGRADE.md` § Scaffolding a new project — scaffold.sh,
  the precondition.
- `docs/IP_POLICY.md` — governing rules for § 8.
- `CLAUDE.md` § Hard rules — bindings referenced by § 3.6, § 3.7,
  § 7.3.
- `ROADMAP.md` — v0.13.0 roll-up referencing this playbook.
- `scripts/scaffold.sh` — required pre-step.
- `scripts/repair-in-place.sh` — **not** a retrofit tool; see
  § 2.3.
- `scripts/upgrade.sh` — orthogonal operation (template-version
  bump inside an already-scaffolded project).
- `.claude/agents/onboarding-auditor.md` — Stage A executor.
- `.claude/agents/researcher.md` — Stage B executor.
- `.claude/agents/architect.md` — Stage C executor.
- `.claude/agents/project-manager.md` — Stages D + F executor.
- `.claude/agents/software-engineer.md` — Stage E executor.
- `.claude/agents/code-reviewer.md` — Stage E gate (all rows).
- `.claude/agents/security-engineer.md` — Stage E gate
  (Hard-Rule-#7 rows: auth, secrets, PII, network endpoints)
  per § 3 rule 8.
- `docs/templates/security-template.md` — security assurance
  artefact shape referenced by § 3 rule 8 sign-offs.
- `docs/sme/INVENTORY-template.md` — inventory row shape.
- `docs/templates/task-template.md` — Stage F task shape.
- `docs/templates/adr-template.md` (v0.13.0 Three-Path) — § 7.2
  ADR shape.
- `docs/ISSUE_FILING.md` — how to file upstream issues for
  playbook gaps.
- Upstream issue #3 — tracking issue for this playbook.
- Customer ruling 2026-04-23 — `CUSTOMER_NOTES.md` § "Retrofit
  adoption flow" — pinned scaffold-first flow.

## 16. Change log

| Date | Author | Note |
|---|---|---|
| 2026-04-24 | tech-lead | DRAFT (project-local) rewritten against `/ultraplan`-spec scope — adds pre-flight, decision record for Path A vs B, convention-conflict protocol (§ 7), ticket migration (§ 4.7, § 9), rollback plan (§ 12), register-population summary (§ 10), `docs/retrofit/` directory shape (§ 11). Pinned to v0.13.0. |
| 2026-04-24 | tech-lead | Revision pass addressing `code-reviewer` + `architect` blocking findings (see review artifacts in session record): new § 2.4 interstitial cases (B4); Hard Rules § 3 extended with #7 security binding and clarified #4 audit-discovered safety-critical (B1); § 4 stage table + Stage E + § 5 stage-gates table + § 6 decision matrix updated to name `security-engineer` as conditional Stage E gate (B1); § 12.4 rollback now mandates write-before-delete of `retrofit-summary.md` + carry-out LESSONS file (B5); § 13 gains 4 anti-patterns (mid-stage abandonment, undetected source drift, stale-Stage-D approvals, unratified-as-ratified escalations) (B3); § 14 DoD adds customer sign-off, TEMPLATE_VERSION integrity check, `docs/INDEX.md` cross-link, #7 + #4 sign-off checkboxes (B2); § 15 gains `security-engineer.md` + `security-template.md` cross-refs. Six non-blocking findings filed as v0.13.1 issues. |
| 2026-04-24 | tech-lead | Second-round review pass: architect flagged three items, two accepted (Items 2 and 5), one declined (Item 4). **Item 5 (SHA-capture completeness gap):** § 4.1 pre-flight "Version control" bullet now mandates recording `<src-path>` HEAD SHA + UTC timestamp into `preflight.md`; § 5 Stage E DoR re-verifies the SHA (mismatch aborts per § 3.2). This gives anti-pattern #12 ("undetected source drift") a concrete input to compare against. **Item 2 (Hard-Rule-#7 two-fire asymmetry):** § 3 rule 8 rewritten as a two-fire pattern mirroring Hard Rule #4 — (a) Stage B advisory fire (non-binding, shapes the Stage C plan) when `researcher` first tags an auth/secrets/PII/net-endpoint row, (b) Stage E binding sign-off unchanged. § 4.3 Stage B gains a binding "Hard-Rule-#7 early fire" paragraph. § 5 "Cross-stage Hard-Rule gates" block reformatted to show both rules using the same early-fire / binding-sign-off structure. **Item 4 (Stage G promotion):** declined per customer decision — code-reviewer's simpler-wins-on-ties argument preferred; customer-sign-off stays as DoD checkbox owned by `tech-lead` inline, filed as future consideration (#48). Non-blocking items from second round filed as #46 (§ 2.4 upgrade-during-retrofit one-liner) and #47 (`<customer-retained-path>` default). |
| 2026-04-25 | tech-lead | **v0.16.0 revision pass** addressing 16 deferred issues from the v0.13.x review batches in one motion: §1.2 N→1 deferred-reshape note (#45); §1.3 absorbed Step 0/1 path (#51); §2.4 retrofit-and-upgrade simultaneously (#46); §4.1 hash recipe for no-VCS sources (#49) + customer-confidential pre-flight row (#56); §4.2 Stage A seeds vs Stage C resolves clarification (#42); §4.3 Hard-Rule-#7 wording split (#50) + new project-authored-distribution-restricted disposition (#56); §4.5 inherited naming category path (#54); §4.6 stale plan-row escalation (#43) + scaffold-baseline + audit-artifact commit rules (#52); §4.7 + §9 versioned-doc governance (#55); §7.2 cost-citation + cap guardrails (#44); new §8.1 nested sibling git repos (#53); §12.1 agent-observable customer-pace stall signal (#40); §12.3 explicit artifact-survival list on pivot (#41); §12.4 default carry-out path for retrofit-lessons (#47). All 16 source issues closed in v0.16.0. |
