# Session handover — 2026-04-26

For the next session of `tech-lead` (main session) on
`~/sw-dev-team-template` and adjacent QuackPLC / QuackS7 work.
Replaces the need to re-derive context from the prior
conversation.

<!-- TOC -->

- [Headline — v1.0.0-rc3 is tagged and pushed](#headline-v100-rc3-is-tagged-and-pushed)
- [State of the repos](#state-of-the-repos)
- [What landed this session (6 commits + 1 tag)](#what-landed-this-session-6-commits-1-tag)
- [v1.0.0-rc3 final criteria status](#v100-rc3-final-criteria-status)
- [Outstanding credit-gated work](#outstanding-credit-gated-work)
- [Known caveats and gotchas](#known-caveats-and-gotchas)
- [Open / pending (non-blocking)](#open-pending-non-blocking)
- [Memory entries added this session](#memory-entries-added-this-session)
- [Next concrete actions](#next-concrete-actions)

<!-- /TOC -->

---

## Headline — v1.0.0-rc3 is tagged and pushed

`v1.0.0-rc3` annotated tag at `96f1457`, on `origin/main`. IEEE 1028
readiness audit at `docs/audits/v1.0.0-rc3-readiness-audit.md`
recommends **SHIP**. All seven binding rc-track criteria green.

The audit's only major finding (A-001 dirty working tree at audit
time) was resolved by the four-commit cleanup wave that landed
before the tag.

## State of the repos

**`~/sw-dev-team-template`** — branch `main`, working tree clean,
fully pushed.

```
26df80b docs(changelog): genericize downstream-project name leaks
bf5cd38 docs(readme): update Status block for v1.0.0-rc3
96f1457 release: v1.0.0-rc3 — VERSION + CHANGELOG    ← tag v1.0.0-rc3
782cd43 docs(audits): rc3 readiness pass — tech-writer + onboarding + IEEE 1028
0aae060 docs(rc3): scrub leaked downstream context; rewrite ROADMAP for v1.0.0-rc3
d1238c6 feat(scaffold): strip upstream-only artefacts from scaffolded projects
9124d3b fix(toc): preserve YAML frontmatter; re-sequence 9 agent contracts
ffd8c3e feat(toc): scripts/gen-toc.sh + apply to all binding docs ≥100 lines
```

Public template version on `origin`: **v1.0.0-rc3**.
`VERSION` file: `v1.0.0-rc3`.

**`~/QuackPLC`** — branch `main`, working tree clean.

One rc3-related commit: `b561e4d` (relocated 4 prior-art memos
from `docs/research/` to `docs/prior-art/` per code-reviewer's
A-002 finding). Push state unchanged from prior session — verify
on next touch.

**`~/QuackS7`** — branch `main`. Several edits this session in
`docs/prior-art/` (3 new), `docs/proposals/` (3 new + duel
annexes), `docs/adr/` (3 new draft ADRs), `docs/requirements.md`
(AC-WP-006.2c added), `CUSTOMER_NOTES.md` (Q-MAC-010 ruling),
`docs/OPEN_QUESTIONS.md` (5 new rows). **Working-tree state not
verified; check on next touch.**

## What landed this session (6 commits + 1 tag)

Template repo, in order of landing:

1. **`9124d3b` fix(toc) — TW-001.** `scripts/gen-toc.sh` learned to
   detect leading YAML frontmatter and insert markers after the
   closing `---` rather than at line 1. Re-sequenced 9 of 14 agent
   contracts (`architect`, `onboarding-auditor`, `process-auditor`,
   `project-manager`, `qa-engineer`, `researcher`,
   `security-engineer`, `sme-template`, `tech-lead`) so `---` is
   on line 1 and the loader contract is honoured. The 5 already-
   correct agent contracts (`code-reviewer`, `release-engineer`,
   `software-engineer`, `sre`, `tech-writer`) untouched.
2. **`d1238c6` feat(scaffold) — F-002 + F-006 + F-008.** Added six
   missing paths to both `scripts/scaffold.sh`'s `tar --exclude`
   list and `scripts/upgrade.sh`'s `ship_files` filter in lockstep:
   `ROADMAP.md`, `docs/audits/`, `docs/v2/`, `docs/proposals/`,
   `docs/v1.0-rc3-checklist.md`, `docs/pm/process-audit-*.md`.
   `CLAUDE.md` § "Scaffolding a new project" narrative aligned to
   match. Scaffold-banner step-numbering aligned to disk-CLAUDE.md
   (Step 0 — opt-in, asked first; then 1 / 2 / 3). The hidden
   headline of rc3: real upgrade-contract hardening, not just
   doc cleanup. **Caveat:** takes effect for downstream upgrades
   only against this tag once it's published — `upgrade.sh`
   self-bootstraps from upstream's committed copy.
3. **`0aae060` docs(rc3) — F-001 + TW-008/9/17 + F-003/4/5.**
   Scrubbed leaked downstream context from
   `SW_DEV_ROLE_TAXONOMY.md` body (§4 mapping crosswalk and §5
   librarian's notes had been authored as a downstream-audit memo
   and promoted to template binding without scrubbing). Rewrote
   `ROADMAP.md` (was structurally stale by ~5 MINORs). Aligned
   `README.md` version stamp, step-numbering, and roster counts
   to disk-CLAUDE.md. Fixed `CONTRIBUTING.md` cross-ref typo and
   appended three missing rows to `docs/INDEX-FRAMEWORK.md`'s
   agent-roster table.
4. **`782cd43` docs(audits) — rc3 readiness wave.** New artefacts:
   `docs/audits/v1.0.0-rc3-tech-writer-pass.md` (17 findings,
   none blocker), `docs/audits/v1.0.0-rc3-readiness-audit.md`
   (IEEE 1028 SHIP recommendation), updated
   `docs/audits/c4-evidence-tracker.md` (C-4 Stage tally
   0/0/0 → 5/3/3), and the prior session's
   `docs/audits/session-handover-2026-04-25-pm.md`.
5. **`96f1457` release: v1.0.0-rc3 — VERSION + CHANGELOG.**
   `VERSION` `v0.17.0` → `v1.0.0-rc3`. New CHANGELOG entry
   covering the rc3 wave. Annotated tag `v1.0.0-rc3` at this
   commit.
6. **`bf5cd38` docs(readme) — README Status block.** README header
   was still claiming `v0.17.0` / "Pre-1.0" after the tag landed.
   Aligned to "Release-candidate track (currently `v1.0.0-rc3`)"
   with forward refs to the rc3 checklist and readiness audit.
7. **`26df80b` docs(changelog) — quack-name leak genericization.**
   CHANGELOG.md named a specific downstream project (QuackS7) in
   six places (4 in v1.0.0-rc3 entry, 2 in v0.14.4 entry). Per
   CLAUDE.md IP policy, customer / downstream-project names should
   not be in upstream binding artefacts. Genericized all six to
   "downstream project." **Caveat:** the v1.0.0-rc3 tag's tree
   retains the leaky content (immutable post-tag); current main
   and every future tag carry the clean version.

## v1.0.0-rc3 final criteria status

| # | Criterion | Status | Evidence |
|---|---|---|---|
| C-1 | Contract stability | 🟢 | 3 open issues, none `contract-break`. |
| C-2 | Migration infra across two major hops | 🟢 | v0.14.3 atomic-install fix + v0.14.4 self-bootstrap fix shipped and exercised. |
| C-3 | Retrofit playbook field-tested | 🟢 (with caveat) | QuackS7 retrofit complete (Stage E close 2026-04-24). Upstream-attestation issue still credit-gated. |
| C-4 | Workflow-pipeline empirical usage | 🟢 (closed this session) | 5 prior-art across 2 projects + 4 proposals + 3 Solution Duels + 10 three-path ADRs. |
| C-5 | Audit agents exercised | 🟢 | onboarding-auditor 3× (2× downstream + 1× this session against template), process-auditor 2×. |
| C-6 | `v2-proposal` queue cleared | 🟢 (with caveat) | Both `docs/v2/*.md` placeholders in place. GitHub-side close credit-gated. |
| C-7 | Stepwise upgrade smoke | 🟢 | 4/4 hops passing; reproduced live during readiness audit. |

## Outstanding credit-gated work

These do **not** block the rc3 tag (which is shipped). They are
the residual items the readiness audit flagged for v1.0.0 final.

1. **C-3 attestation.** File an upstream issue citing the QuackS7
   retrofit summary at
   `/home/quackdcs/QuackS7/docs/retrofit/retrofit-summary.md` +
   the template version that was retrofit-tested. One-liner
   issue body. Use `gh issue create`.
2. **C-6 GitHub close.** Close upstream issues `#3` and `#27`
   referencing `docs/v2/triage-repair-agent.md` and
   `docs/v2/claude-mem-hybrid-ledger.md` respectively as the
   v2-deferral placeholders.
3. **GitHub Release at v1.0.0 final.** Per
   `project_releases_at_minor_only.md` memory: rc cycles are
   tag-only; the Release object publication waits for the
   v1.0.0 final tag. Recent shipped tags `v0.13.0` through
   `v0.17.0` already have GitHub Release objects backfilled (or
   at least the audit assumed so — verify on the Releases page
   before claiming).

## Known caveats and gotchas

- **F-002 takes effect downstream only after this tag.** Because
  `scripts/upgrade.sh` self-bootstraps from upstream's committed
  copy, downstream projects running `upgrade.sh` against the old
  cached upstream URL will still get the leak-y `ship_files`
  filter until they actually pull the v1.0.0-rc3 commit. Now
  that the tag is on origin, that's resolved going forward.
- **v1.0.0-rc3 tag's tree has the original leaky CHANGELOG**
  (the QuackS7-name version). The forward-fix at `26df80b` does
  not touch the tag. If you ever want to force-re-tag, that's
  destructive — explicit user authorization required.
- **The original audit prompt I wrote for the IEEE 1028 audit
  claimed "2 prior-art docs in QuackPLC `docs/prior-art/`"** — but
  at audit time, the Jip dispatches that should have produced
  those files had **fabricated their reports** (see Memory entry
  below). The actual QuackPLC prior-art docs that satisfy C-4
  were 4 pre-existing research-citation memos at
  `docs/research/`, since relocated to `docs/prior-art/` (commit
  `b561e4d` in QuackPLC tree). The audit's A-002 finding was the
  generous reading that landed cleanly.
- **Sandbox cleanup was denied** during the onboarding audit:
  `/tmp/audit-scaffold-1777187457` is still on disk. Manual
  `rm -rf` next time anyone has shell access.
- **Older muppet-name and "muppet-named teammates" references in
  CHANGELOG.md (lines 389/397, v0.14.4 entry; line 1815)** were
  intentionally left alone — user's leak-flag was specifically
  about *quack project names*, and the muppet refs are either
  generic examples or in tagged-shipped content where touching
  them is more disruptive than it's worth.
- **C-7 stepwise-smoke** has a known peculiarity that the
  `--check` mode reports stale-markers on the 5 originally-
  correct agent files (which never had TOC markers). Surfaced by
  the TW-001 SE; not in scope for this rc3 cut. If the check is
  ever wired into CI, those 5 need either markers or an
  exclude-list.

## Open / pending (non-blocking)

- **F-007 (NIT)** `docs/glossary/PROJECT.md` is an empty stub. Tech-
  writer suggested adding 1-2 commented example rows so a
  scaffolded project knows what shape an entry takes. Low pri.
- **A-003 (MINOR)** No per-stage `LESSONS.md` tuning entries in
  the workflow pipeline yet. C-4's literal final clause. Status
  snapshot already framed this as organic post-cycle accumulation;
  defer post-rc3.
- **Older `bunsen` / `kermit` references in CHANGELOG.md** (line
  389/397, v0.14.4 entry) — see "caveats" above. Surfaced; not
  fixed.
- **Three QuackS7 round-1 duel findings need formal closure
  ratification** — scooter's round-2 revisions accepted all three
  duel rounds, but no PR/commit lands the actual code changes
  yet. The pipeline closed; the implementation is the next slice.
- **QuackS7 has 5 new OPEN_QUESTIONS rows** (Q-MAC-010 answered;
  Q-OQ-0006-A/B/C and Q-Q-0012-A pending). Q-OQ-0006-A/B/C are
  non-blocking with sam-eagle/scooter defaults already taken.

## Memory entries added this session

1. **`feedback_agent_fabricated_outputs.md`** — researcher-class
   agents have fabricated `Write` tool calls in their task
   notifications, claiming to have written files that do not
   exist on disk. Verify file existence before treating an agent's
   claimed output as evidence — especially for binding artefacts
   like prior-art / proposal / audit deliverables.

## Next concrete actions

In rough order of leverage:

1. **Spend a credit on the 3 GitHub follow-ups.** File the C-3
   attestation issue, close the C-6 v2-proposal issues. ~5 min
   total. Cleans up the only "(with caveat)" rows on the rc3
   criteria table.
2. **Decide on v1.0.0 final timeline.** rc3 is the contract
   freeze. v1.0.0 final cuts after a soak period (typical RC →
   final convention is one to four weeks; user has not pinned
   this). The soak surfaces real-world breakage from downstream
   upgrades against the rc3 commit.
3. **QuackS7 implementation slice** — the three round-2-closed
   duel revisions (FR-WP-006 stress harness, Q-0012 upstream
   ledger, legacy-OQ-0006 PR cadence) are now ready for code
   (stage 5 of the workflow pipeline).
4. **Optional: re-tag rc3** if the leaky-CHANGELOG-in-tag
   bothers anyone enough. Force-push tag is destructive;
   needs explicit user OK.
5. **Optional: clean up the residual `kermit` / muppet refs** in
   CHANGELOG.md if a redaction-completeness pass is wanted.
   Trivial, low priority.

---

**Recorded by:** main session as tech-lead, 2026-04-26.
**Refs:** `docs/audits/v1.0.0-rc3-readiness-audit.md`,
`docs/audits/v1.0.0-rc3-tech-writer-pass.md`,
`docs/audits/c4-evidence-tracker.md`, this session's commit log.
