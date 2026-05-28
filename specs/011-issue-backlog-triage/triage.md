# Issue Triage Table — 2026-05-16 snapshot

> Historical note: this table preserves the 2026-05-16 initial triage and dispatch handoff; `spec.md` status and `tasks.md` final phase now supersede its early in-flight/open statuses for rc14 completion state.

Source: `gh -R occamsshavingkit/sw-dev-team-template issue list --state open`
Baseline count: **35 open issues**
In-flight: **#203** (branch `fix/issue-203-upgrade-branch-guard`, commit `fdca007`, awaiting code-reviewer).

## Bucket priority (FR-003)

1. release-gate-upgrade-flow
2. hook-behavior
3. framework-gap
4. framework-friction
5. docs-drift
6. v2-proposal
7. other

## Bucket: release-gate-upgrade-flow (P1)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Blocks-on / Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------------------|
| 154 | version-check links to missing GitHub Release objects for rc tags              | fix-and-close     | release-engineer | minor; release-engineer creates Release objects per `project_releases_at_minor_only` memory — note: only MINOR boundaries get Release objects; rc tags should suppress the link |
| 161 | version-check reports downgrade rc10 → rc9 after successful upgrade            | fix-and-close     | software-engineer| comparator bug in `scripts/version-check.sh`; verify against `scripts/lib/semver.sh` ordering |
| 163 | v0.16.0 upgrade-path conflict on scripts/upgrade.sh (currently allowlisted)    | fix-and-close OR consolidate | software-engineer | may be obsoleted by #203 + #200; re-check after both land |
| 169 | post-upgrade advisory references migrations/v1.0.0-rc11.sh that does not exist | fix-and-close     | software-engineer| stale advisory text; check migrations directory; possibly fold into #190 |
| 171 | upgrade.sh --resolve does not consult .template-customizations                 | fix-and-close     | software-engineer| modest scope; --resolve path |
| 190 | upgrade.sh: cite migration idempotency contract at untagged-target full-walk   | fix-and-close     | software-engineer| docs-anchor inside upgrade.sh; small |
| 191 | smoke-test: add downgrade-from-untagged-to-tag regression case                 | fix-and-close     | qa-engineer      | test-only; pair with #203 PR |
| 199 | version-check.sh reads working-tree TEMPLATE_VERSION; reports "up to date"     | fix-and-close     | software-engineer| read from HEAD, not working-tree; small |
| 200 | upgrade.sh plain re-run silently reclassifies "conflict" → "accepted_local"    | fix-and-close     | software-engineer| safety-critical re-run semantics; verify with qa-engineer regression |
| 203 | upgrade.sh runs on any branch — divergence trap                                | **IN FLIGHT**     | software-engineer| branch `fix/issue-203-upgrade-branch-guard` @ `fdca007`; awaiting code-reviewer |

## Bucket: hook-behavior (P1)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 184 | hook coverage gap: pathlib.Path.write_text() / Path(...).open('w')             | fix-and-close     | software-engineer| extend `customer-notes-guard.py` regex set; mirror to `tech-lead-authoring-guard.py` vendored helpers |
| 188 | fixture-06: PID-scope stub migration filename + tag                            | fix-and-close     | qa-engineer      | fixture issue; verify against current rc13 fixture set |
| 201 | tech-lead-authoring-guard.py not wired into .claude/settings.json              | fix-and-close     | software-engineer| scaffold + upgrade-path additive merge; QuackDCS reproduction comment posted today; two follow-up bugs ride this PR |
| 202 | tech-lead authoring guard silently reverts specialist-agent writes              | fix-and-close     | software-engineer| canonical-scope inversion; needs careful reading; possibly architect involvement |
| NEW-A | tech-lead-authoring-guard fires on absolute paths outside CLAUDE_PROJECT_DIR | file-then-fix-and-close | software-engineer | observed 3× in 2026-05-16 session; HR-8 should be project-scoped, not absolute-path-scoped |
| NEW-B | tech-lead-authoring-guard fires on `> /dev/null` and likely `/dev/*` targets | file-then-fix-and-close | software-engineer | observed 2× in 2026-05-16 session; trivial allowlist for `/dev/*` |

## Bucket: framework-gap (P2)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 143 | CI guard for canonical_sha staleness on docs/runtime/agents/ + .opencode/      | fix-and-close     | release-engineer | add a CI check; rc9-era — verify still relevant under rc13 generated-agent layout |
| 144 | improve-template.yml protected-files regex misses HR-bearing files (FR-027)    | fix-and-close     | release-engineer | regex tightening; QA check |
| 145 | improve-template.yml Phase-3+ wire real LLM (security re-review required)      | defer-to-v2       | architect → release-engineer | scope is large, security-review-heavy; v2 candidate |
| 146 | scoping-questions-template still has compound seed questions (T035 didn't reach) | fix-and-close   | tech-writer      | reword seeds per atomic-question rule |
| 160 | recurring stale docs/pm/token-ledger.md lowercase clutter                      | fix-and-close     | software-engineer| add a normalization step or `.gitignore` rule |
| 165 | release-engineer manual authorship (T044 deferral)                            | fix-and-close OR defer-to-v2 | release-engineer | check current state; may have been picked up under another initiative |
| 207 | agent contracts ship with `model: inherit` — binding default-class table unenforced | fix-and-close (Part A+B+C) | release-engineer + tech-writer | NEW 2026-05-16. Part A: update 14 agent contracts × 2 trees = 28 files. Part B: CI lint check. Part C: resolve #147 first (canonical source). Rides PR-G with #147. Cross-provider: Claude frontmatter for Claude Code; binding-table class for opencode/Codex (Gemini + OpenAI both reachable per customer 2026-05-16). |

## Bucket: framework-friction (P2 / P3)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 147 | model-routing-guidelines has two overlapping per-agent tables                  | fix-and-close     | tech-writer      | merge tables; small |
| 148 | lint-questions.sh pattern-2 fires on Customer Question Gate enumeration        | fix-and-close     | software-engineer| false-positive fix in `scripts/lint-questions.sh` |
| 149 | improve-template.yml workflow_dispatch issue_number lacks numeric validator   | fix-and-close     | release-engineer | tiny; CI yaml tweak |
| 151 | researcher runtime SC-002 margin 17.2% vs 20% floor (where-safe exception)    | fix-and-close OR wontfix | researcher | judgement: trim candidate available; PM ruling needed; could be where-safe exception |
| 185 | lint-questions strip_template_prose: nested sub-bullets not suppressed         | fix-and-close     | software-engineer| regex tweak |
| 189 | tests/prompt-regression: decide tracking status for results-*.md              | needs-customer-ruling THEN fix-and-close | qa-engineer | question label; route via tech-lead Customer Question Gate |
| 194 | dogfood: stub-vs-driver flag coupling check at PR time                        | fix-and-close     | qa-engineer      | dogfood harness work |
| 195 | dogfood: force FAIL on unparseable .template-conflicts.json (jq empty probe)  | fix-and-close     | qa-engineer      | dogfood safety net; pairs with #194 |

## Bucket: docs-drift (P3)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 150 | fallback-log.jsonl create-on-first-write contract not documented at scaffold  | fix-and-close     | tech-writer      | doc patch |
| 192 | dogfood README: enumerate commonly-overlooked scrub paths                     | fix-and-close     | tech-writer      | doc patch |
| 193 | dogfood README: surface `cp -aL` symlink-dereference trade-off                | fix-and-close     | tech-writer      | doc patch |

## Bucket: v2-proposal (P3, defer)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 3   | [v2] Project triage + repair agent for retrofit adoption                       | defer-to-v2       | architect        | already v2-labeled; close-and-link to v2 surface |
| 27  | use claude-mem as template for agent memories databases                       | defer-to-v2       | architect        | v2 candidate; tied to FW-ADR-0001 stance |
| 59  | v1.0.0 RC backlog — lit review, IEEE adoption, token economy, consolidation   | wontfix-and-close (audit-then-summary) | project-manager | per Q3 / I4 cleanup: audit children vs current rc13 state; single summary close-comment as FR-005 rationale; still-relevant items file as NEW issues (outside baseline per A-009 / FR-010). NOT `consolidate` (no single surviving issue — children fan out, not collapse) |

## Bucket: other (P2)

| #   | Title (truncated)                                                              | Disposition       | Owner            | Notes |
|-----|--------------------------------------------------------------------------------|-------------------|------------------|-------|
| 136 | Project manager cadence does not keep schedule and roadmap current             | fix-and-close     | project-manager  | self-referential; PM updates its own cadence contract |

## Roll-up

| Bucket                          | Count | Disposition mix |
|--------------------------------|------:|-----------------|
| release-gate-upgrade-flow       |    10 | 9× fix-and-close, 1× IN FLIGHT |
| hook-behavior                   |     4 + 2 new = 6 | 6× fix-and-close (4 baseline + 2 to-be-filed) |
| framework-gap                   |     6 + 1 new = 7 | 6× fix-and-close (5 baseline + #207 new), 1× defer-to-v2 (candidate) |
| framework-friction              |     8 | 7× fix-and-close, 1× needs customer ruling |
| docs-drift                      |     3 | 3× fix-and-close |
| v2-proposal                     |     3 | 3× defer-to-v2 (1 splits first) |
| other                           |     1 | 1× fix-and-close |
| **Total (baseline)**            |    **35** | **+3 new findings filed: #205 #206 #207** |

## Dependency ordering (FR-003)

```
P1: release-gate-upgrade-flow ─┐
                                ├─► v1.0.0-rc14 candidate
P1: hook-behavior              ─┘
                                  │
                                  ▼
P2: framework-gap                 → rc15 candidate
                                  │
                                  ▼
P2: framework-friction            → rc15 candidate
                                  │
                                  ▼
P3: docs-drift  +  v2-proposal    → rolled in any rc; deferrals labeled now
```

## Next dispatches (planning hand-off)

The `/speckit-plan` step will draft a per-issue dispatch plan grouping where useful. Pre-grouped clusters that ride single PRs:

- **PR-A** (hook-behavior): #201 + NEW-A + NEW-B + (if scope-permissive) #184. Settings.json wiring + scope fix + `/dev/*` allowlist + pathlib detection.
- **PR-B** (version-check): #161 + #199 + #154. Single scripts/version-check.sh + lib touch.
- **PR-C** (upgrade.sh): #169 + #190 + #171 + (if not obsoleted) #163. After #203 merges.
- **PR-D** (dogfood): #194 + #195. qa-engineer.
- **PR-E** (docs-drift): #150 + #192 + #193. tech-writer.
- **PR-F** (lint-questions): #148 + #185. software-engineer.
- **PR-G** (model-routing): #147 + #207. tech-writer (table merge, Part C) + release-engineer (28 agent-contract frontmatter updates + CI lint script, Parts A+B). Single PR, three-part. Touches `.claude/agents/<role>.md` × 2 trees, `docs/model-routing-guidelines.md`, new `scripts/lint-agent-model-routing.sh` (or .py), new `.github/workflows/` entry.
- **Solo PRs**: #200 (re-run safety), #202 (canonical-scope inversion), #160, #136, #143, #144, #146, #147, #149, #151, #165, #188, #189, #191.

Total expected PR count: ~14-18.

## Out of scope for this triage

- New issues filed after 2026-05-16 (tracked separately per A-003 / FR-010).
- Any upstream issue against `occamsshavingkit/sw-dev-team-template`'s dependencies (e.g., Claude Code itself).
- Changes to FW-ADR scope or v1.0.0 release criteria beyond what these issues already cover.
