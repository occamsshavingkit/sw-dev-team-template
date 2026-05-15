# CUSTOMER_NOTES.md

Append-only log of customer-originated facts: domain truths, requirements,
acceptance criteria, and rulings relayed by `tech-lead`. Maintained by
`researcher`.

**Rules:**
- Append only. Never rewrite or delete past entries.
- Record customer answers verbatim. Paraphrase only in the surrounding
  framing, not in the quoted text.
- One entry per topic. If a later answer supersedes an earlier one, add a
  new entry and cross-reference the superseded one.
- If an entry is ambiguous on re-read, do not reinterpret — `tech-lead`
  must take the clarification back to the customer.

**Entry template:**

```
## YYYY-MM-DD — <short topic> (turn: <docs/intake-log.md turn id, or "pre-intake">)

**Question (from <agent>, relayed by tech-lead):**
> <verbatim question>

**Customer answer (verbatim):**
> <verbatim response>

**Supersedes:** <date + topic of prior entry, if any>
**Recorded by:** researcher
```

---

<!-- Entries begin below this line. First entry will typically be the
     Step-2 project charter + SME plan from the CLAUDE.md first-action flow. -->

## Security sign-off — M7 self-improvement loop (2026-05-13)

`security-engineer` reviewed the M7 self-improvement loop per Hard Rule #7
(authentication / authorization / secrets / PII / network-exposed paths).

**Verdict**: PASS-WITH-RESIDUAL-RISK.

**In scope**: `.github/workflows/improve-template.yml`, the three hardened
CI workflows (`.github/workflows/agent-contract-check.yml`,
`.github/workflows/question-lint.yml`,
`.github/workflows/template-contract-smoke.yml`),
`scripts/setup-github-labels.sh`, `docs/IP_POLICY.md`,
`.github/ISSUE_TEMPLATE/framework-gap.yml`,
`tests/workflows/test-improve-template-logic.sh`.

**Findings**:

1. **Trigger surface — `improve-template.yml` lines 3-14**: `workflow_dispatch`
   only, no `schedule:` / `push:` / `pull_request:` triggers. Manual
   invocation only; `dry_run` defaults to `true`. Minimal attack surface.

2. **Permissions block — lines 16-23**: scoped to `contents: write`,
   `pull-requests: write`, `issues: write`. No `actions:`, `packages:`,
   `id-token:`, `deployments:`, `repository-projects:`, `security-events:`,
   or `statuses:` grants. The three hardened workflows
   (`agent-contract-check.yml` line 20-21, `question-lint.yml` line 19-20,
   `template-contract-smoke.yml` line 18-19) all specify
   `permissions: contents: read` — strict read-only as required.

3. **Pinned action and tool versions**: every workflow uses
   `actions/checkout@v4` and `actions/setup-python@v5` (not `@main`,
   `@latest`, or any floating SHA), and `pipx install check-jsonschema==0.37.2`
   is pinned to the same exact version in all four workflows.

4. **Branch model — lines 148, 156-160**: PR branches are
   `feat/improve/issue-<N>-<UTC-timestamp>`, base is `main`, draft PRs
   only, no auto-merge. The workflow opens a draft PR; the customer
   reviews + marks ready-for-review + merges. The "never push to main"
   guarantee depends on branch protection being enabled on `main` — see
   R-5.

5. **Size cap — lines 90-109**: enforces `wc -l < /tmp/proposal.diff` ≤ 400
   and `grep -c '^diff --git'` ≤ 10 BEFORE the protected-files check and
   BEFORE the PR-open step. Note: the cap counts ALL lines in the diff
   file (headers + context + +/-), so the effective gate is stricter than
   "added+removed lines" in R-3. This is safer, not weaker; no change
   recommended.

6. **Protected-files / customer-truth regex — lines 116-117**: the regex
   covers 10 of the 11 FR-027 protected-files entries
   (`CLAUDE.md`, `AGENTS.md`, `VERSION`, `TEMPLATE_MANIFEST.lock`,
   `.claude/agents/`, `docs/adr/`, `docs/framework-project-boundary.md`,
   `docs/model-routing-guidelines.md`, `.github/workflows/`, `migrations/`)
   and all 3 customer-truth entries (`CUSTOMER_NOTES.md`,
   `docs/OPEN_QUESTIONS.md`, `docs/intake-log.md`). The eleventh FR-027
   anchor — "any file containing a Hard Rule" — is content-based and
   NOT covered by the path regex. 28 files in the current tree reference
   "Hard Rule" (e.g. `docs/FIRST_ACTIONS.md`, `docs/workflow-pipeline.md`,
   `docs/MEMORY_POLICY.md`, `docs/TEMPLATE_UPGRADE.md`, `README.md`,
   `CHANGELOG.md`); only those already on the path allowlist are blocked.
   See R-8 below.

7. **Paired-proposal escape valve — lines 124, 129**: protected /
   customer-truth paths are blocked unless the SAME diff also contains
   a `docs/proposals/.+\.md$` entry. Logic matches FR-027.

8. **Pre-flight drift checks — lines 61-67**: `lint-agent-contracts.sh`
   + `compile-runtime-agents.sh --verify` + `--reproducibility-check`
   run BEFORE the propose step. Drift on the canonical layer aborts the
   workflow before any PR machinery runs.

9. **Placeholder propose step — lines 71-88**: emits an empty
   `/tmp/proposal.diff` and a placeholder echo. No `requests`, `httpx`,
   `openai`, `anthropic`, `google-genai`, or other HTTP-client imports.
   No `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or other secret references
   anywhere in the workflow. No outbound network egress beyond `gh issue
   list` / `gh issue create` / `gh pr create` / `git push` against
   `GITHUB_TOKEN`-scoped operations. Confirms M7 ships safely without
   any LLM surface. See R-6.

10. **`setup-github-labels.sh` — script body**: idempotent (lines 124-134
    skip on existing labels); `--dry-run` mode (lines 115-121) emits
    `would-create:` lines and explicitly does NOT call `gh label list`
    or `gh label create` (lines 101-103 guard the prefetch on dry-run).
    Hard `set -eu`, REPO env-var precondition (lines 72-76),
    gh-binary precondition (lines 65-69), POSIX `sh` shebang. Test against
    a wrong remote possible if operator skips `--dry-run`; see R-7.

11. **`docs/IP_POLICY.md` — lines 67-89**: the four mandatory items are
    enumerated and explicitly marked "cannot be relaxed locally". The
    per-repo extension marker (lines 92-109) follows the canonical
    two-section shape with placeholder examples only (`Customer XYZ`,
    `Vendor ACME`, `Project ACME`). No real customer / vendor names.

12. **`.github/ISSUE_TEMPLATE/framework-gap.yml` — lines 68-76**: the
    required redaction-confirm checkbox cites all four mandatory items
    verbatim and is marked `required: true`. The `template-version`
    field (lines 20-26) is required, enabling upstream issue
    triage to the scaffolded SHA.

13. **`tests/workflows/test-improve-template-logic.sh`**: the test
    mirrors the workflow's size_cap_check and protected_check verbatim
    (lines 29-66) and runs against 7 fixtures with the SC-010 expected
    outcomes (lines 106-112). The SYNC NOTE (lines 12-18) flags the
    co-edit requirement between the test and the workflow.

**Residual risks** (recorded in `docs/pm/RISKS.md`):

- R-5: Branch protection on `main` is an external GitHub setting; the
  workflow itself opens draft PRs to feature branches, but the final
  "never push to main" guarantee depends on `main` having branch
  protection enabled with at least one required reviewer and "Restrict
  pushes" turned on. The customer / operator MUST enable branch
  protection on `main` before any first real (non-dry-run) invocation
  of `improve-template.yml`.

- R-6: The M7 propose step is a placeholder; when wired to a real LLM
  in Phase-3+, the security review MUST re-run to assess (a) the API-key
  surface and secret-handling pattern, (b) data egress to a third-party
  model including which fields of an issue body are sent, (c)
  prompt-injection risk if framework-gap issue bodies (potentially
  attacker-controlled in an open-source repo) are fed to the LLM
  verbatim, (d) handling of model-returned diffs that may attempt to
  bypass the size / protected-files checks via deliberately crafted
  output. The current placeholder is safe; the future LLM wiring is
  out-of-scope-for-now and gated.

- R-7: `setup-github-labels.sh` writes to the GitHub remote on
  actualization; idempotent but the customer must verify with
  `--dry-run` first.

- R-8: FR-027's "any file containing a Hard Rule" clause is
  content-based; the workflow's path regex enforces only the
  explicit-path entries. Files such as `docs/FIRST_ACTIONS.md`,
  `docs/workflow-pipeline.md`, `docs/MEMORY_POLICY.md`,
  `docs/TEMPLATE_UPGRADE.md`, `README.md`, and `CHANGELOG.md` reference
  Hard Rules but are NOT path-blocked. Mitigation routes (any of):
  add a content-grep step (`grep -l "Hard Rule"` over the changed
  set), broaden the regex to include those known files, or rely on
  `code-reviewer` human review of every draft PR. For M7 the human-
  review gate is the active mitigation; record as a known limitation
  for the Phase-3+ LLM wire-up review.

- R-9: `workflow_dispatch` inputs (`issue_number`, `dry_run`) flow
  into shell via env vars and then into `gh` commands. The current
  flow uses `${ISSUE_NUMBER:-}` quoted and writes to `$GITHUB_OUTPUT`
  via `echo "issue=${ISSUE_NUMBER}" >> "$GITHUB_OUTPUT"`. An attacker
  with `workflow_dispatch` permission (i.e. someone already with write
  access on the repo) could supply a multi-line `issue_number` to
  inject extra `$GITHUB_OUTPUT` rows. Blast radius is limited because
  invocation requires repo write access, but a defensive numeric
  validator (`case "$ISSUE_NUMBER" in ''|*[!0-9]*) exit 2 ;; esac`)
  in the "Identify target issue" step is a low-cost hardening.
  Recorded as a non-blocking observation; pick up at Phase-3+
  LLM-wire-up review.

**Sign-off**: `security-engineer`, 2026-05-13.

## 2026-05-15 — dogfood-before-rc sequencing ruling (turn: pre-intake)

**Question (from tech-lead, framed back to customer during dogfood-blocker triage):**
> Should we cut a new rc (rc13 / rc12.1) that bundles the dogfood-blocker
> fixes, then run the dogfood harness AGAINST that new rc?

**Customer answer (verbatim):**
> "no, we dogfood before cutting an rcX. that is why we made the dogfood scripts."

**Implication (paraphrase, not customer text):**
The canonical pre-release sequence is:
1. Fixes land on `main` (after `code-reviewer` review per Hard Rule #3).
2. The dogfood harness runs against `main` via
   `scripts/upgrade.sh --target main` (untagged-target feature, PR #186).
3. Only after the dogfood harness PASSes against `main` is the rc tag cut.
4. The tag's commit is the same SHA that passed dogfood — no post-tag
   content drift.
5. A smoke dogfood vs the cut tag confirms identity, then the meta-pointer
   bumps.

**Cross-refs:** PR #186 (untagged-target feature in `scripts/upgrade.sh`);
auto-memory entries `feedback_dogfood_before_meta_bump.md` and
`feedback_dogfood_needs_tui_check.md`;
`docs/pm/dogfood-2026-05-15-results.md` (trigger for this ruling).

**Supersedes:** none (codifies the dogfood-before-cut discipline previously
recorded only in auto-memory).
**Recorded by:** researcher

## 2026-05-15 — v1.0.0-final blocker frame: upgrade-flow reliability (turn: pre-intake)

**Question (from tech-lead, during the same dogfood-blocker triage):**
> What is the strategic blocker to cutting v1.0.0 (final, non-rc)?

**Customer answer (verbatim):**
> "the big blocker to going to v1.0.0 in my view is that the upgrade is always buggy."

**Implication (paraphrase, not customer text):**
v1.0.0 final ships when the upgrade flow is no longer the recurring source
of regressions. This is a strategic stance — a quality bar, not a numeric
criterion ("zero bugs ever"). Concretely:
- Continued upgrade-flow regressions = more rc cycles, not a v1.0.0 cut.
- Architects considering rc12 → rc13 changes weigh upgrade-flow risk as a
  first-class quality attribute.
- Readiness signal: cumulative coverage from the dogfood harness against
  representative downstreams stabilises — multiple rc-to-rc cycles pass
  dogfood without surfacing new upgrade-class bugs.

**Triggering observation (paraphrase):** The 2026-05-15 dogfood surfaced
three fresh upgrade-class bugs (alpha/scaffold rc2→rc12 self-overwrite;
beta/scaffold v0.13→rc12 manifest drift; the dogfood driver itself
crashing on real symlink shapes).

**Cross-refs:** Q-0017 (rc8 self-overwrite ruling); FW-ADR-0013 (rc-to-rc
pre-bootstrap, proposed 2026-05-15); forthcoming FW-ADR-0014
(preservation-vs-manifest, in flight via architect-b4);
`docs/pm/dogfood-2026-05-15-results.md`.

**Supersedes:** none (first explicit customer framing of the v1.0.0-final
blocker).
**Recorded by:** researcher

## 2026-05-15 — out-of-tree orchestrator (upgrade-flow foundation) (turn: pre-intake — to be reconciled with docs/intake-log.md)

**Question (from tech-lead, relayed):**
> Should `scripts/upgrade.sh` on a downstream project become a stable stub that fetches a fresh runner per invocation (out-of-tree orchestrator), or stay as a project-shipped file the framework keeps trying to harden against self-mutation (in-tree, strictly-weaker fallback path)?

**Customer answer (verbatim):**
> "yes, let's make it a stub."

**Implication (paraphrase, not customer text):**
The framework's upgrade flow architecture pivots. Foundation work
proceeds as FW-ADR-0015 (forthcoming). The stub is sub-100 lines,
stable across the v1.x line, project-owned; its only job is fetch +
exec the upstream runner. The runner is fresh per invocation, knows
the full target's migration set by file presence (not tag
enumeration), and writes `TEMPLATE_STATE.json` (consolidates
`TEMPLATE_VERSION` + `TEMPLATE_MANIFEST.lock` + `.template-customizations`).

**Context (paraphrase, not customer text):** Architect + process-auditor
independently converged on the same conceptual mistake (per
`docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md` and
`docs/pm/upgrade-flow-process-debt-2026-05-15.md`): `scripts/upgrade.sh`
is treated as a project-shipped file when structurally it's a runtime
the project hosts. Every recurring upgrade-class failure
(self-overwrite, pre-bootstrap-as-workaround, --target fragmentation,
manifest-vs-preserve-list race, rc-cliff accumulation) traces to this
conflation.

**Cross-refs:** Q-0019 (foundation question, blocks all follow-up ADRs);
forthcoming FW-ADR-0015 / 0016 / 0017 / 0018 / 0019 per architect's
outline in `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`.
Supersedes FW-ADR-0013 (rc-to-rc pre-bootstrap; the cliff that ADR
addressed dissolves under the stub model). Modifies FW-ADR-0014
(preservation-vs-manifest; folds into `TEMPLATE_STATE.json` schema, no
separate gate needed).

**Supersedes:** none (first ruling on the stub-vs-in-tree foundation
question; supersession of FW-ADR-0013 / modification of FW-ADR-0014
is at the ADR layer, not the customer-notes layer).
**Recorded by:** researcher

## 2026-05-15 — migration path for currently-deployed downstreams = Option S (turn: pre-intake — to be reconciled with docs/intake-log.md)

**Question (from tech-lead, relayed):**
> How should we fix previous versions (downstreams already on rc2..rc12 with the in-tree self-mutating `upgrade.sh`)? Three architect-outlined paths: M (one-time hand retrofit), S (transitional runner / "last in-tree upgrade"), C (vNext MAJOR scaffold-fresh).

**Customer answer (verbatim):**
> "S"

**Implication (paraphrase, not customer text):**
One more in-tree rc gets cut. Its `upgrade.sh` has the special job of
installing the new stub + synthesizing `TEMPLATE_STATE.json` in place
during that rc's migration. After that rc, all future upgrades use the
stub-fetches-runner path. The transitional rc still needs
pre-bootstrap-class machinery to handle sources at rc8 or older (no
FW-ADR-0010 bootstrap support yet); for sources at rc11+ the transition
is clean.

**Cross-refs:** Q-0020 (queued by architect); forthcoming FW-ADR-0018.
Pre-bootstrap class retires AFTER the S transitional rc lands
(FW-ADR-0019). Customer's standing dogfood-before-rc rule still applies
— the transitional rc must PASS dogfood vs `main` (or vs the
transitional ref) before its tag is cut.

**Supersedes:** none (first ruling on the deployed-downstream migration
path).
**Recorded by:** researcher

## 2026-05-15 — air-gapped operators out of scope for FW-ADR-0015 (turn: pre-intake — to be reconciled with docs/intake-log.md)

**Question (from architect, relayed by tech-lead):**
> Does the framework's downstream population include operators on segmented networks where `curl https://github.com/...` at upgrade time is not allowed? If yes, offline-mode design (pre-fetched runner archive + `SWDT_PRESTAGED_RUNNER` path, OR internal-mirror URL via `SWDT_UPSTREAM_URL`) becomes a hard requirement on FW-ADR-0015-impl rather than a documentation footnote.

**Customer answer (verbatim):**
> "air gapped operators will have to figure it out on their own. the only current user of this template is me."

**Implication (paraphrase, not customer text):**
FW-ADR-0015 implementation targets the online / GitHub-reachable case
as the baseline. Offline-mode patterns (pre-fetched archive, internal
mirror) get a documentation footnote noting they're
operator-implementable but not framework-supported. Network failure
during runner fetch is operator-actionable per the stub's failure-mode
contract. `SWDT_UPSTREAM_URL` still functions for operators who want
to point at a private mirror — that's a separate axis from air-gap
support.

**Cross-refs:** FW-ADR-0015 (forthcoming acceptance pass); Q-0021
(architect's queued question, now answered).

**Supersedes:** none (first ruling on the air-gap / offline-mode
scope question).
**Recorded by:** researcher

## 2026-05-15 — security posture floor for runner fetch: TLS + checksum sufficient (turn: pre-intake — to be reconciled with docs/intake-log.md)

**Question (from architect, relayed by tech-lead):**
> Is TLS + per-ref checksum pinning in `TEMPLATE_STATE.json` an acceptable minimum-viable security posture for the network-fetched runner, or does the framework want a stronger posture (GPG / cosign signature on the runner) before any stub ships?

**Customer answer (verbatim):**
> "TLS and checksum will be plenty."

**Implication (paraphrase, not customer text):**
FW-ADR-0015's proposed baseline accepted. Stub verifies runner
integrity via TLS (curl's default for HTTPS URLs) + per-ref SHA-256
checksum recorded in `TEMPLATE_STATE.json`. First-observation pinning.
`--no-verify` is the development opt-out with WARN log. GPG / cosign /
signed-manifest gating deferred — not blocking the stub ship.
`security-engineer` still reviews FW-ADR-0015 implementation before
code lands, but the design floor is set.

**Cross-refs:** FW-ADR-0015 (forthcoming acceptance pass); Q-0022
(architect's queued question, now answered); `security-engineer` is
still the gating reviewer on the integrity-verification section per
FW-ADR-0015's binding interface decisions.

**Supersedes:** none (first ruling on the runner-fetch security-posture
floor).
**Recorded by:** researcher
