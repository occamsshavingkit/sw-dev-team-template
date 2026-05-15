# FW-ADR-0017 Review — File-keyed migration discovery

**Mode:** Technical review (IEEE 1028 § 5) against the ADR template + parent ADRs (FW-ADR-0015, FW-ADR-0016) + conceptual-mistake report.

**Net judgment: APPROVED-WITH-CHANGES.** The structural choice (Option M, file-keyed) dissolves the rc13 catch-22 by construction and aligns with FW-ADR-0015's runner-is-current-by-construction principle. The Three-Path Rule is honest. Most interface decisions are tight. Two interface ambiguities and one minor inconsistency need amendment before architect flips status. None are structural; architect can amend without re-CR.

**Counts:** Critical 0, Warnings 4, Suggestions 5.

> **Provenance note (transcription):** The dispatching code-reviewer session's tool-policy prohibited writing report `.md` files and instructed direct text return to the parent. The substantive review was completed by `code-reviewer`; this file was transcribed verbatim by tech-lead as tool-bridge to restore on-disk audit consistency with the FW-ADR-0015 and FW-ADR-0016 review reports. Authorship and judgment stay with `code-reviewer` (commit trailer reflects this).

---

## Critical

None.

---

## Warnings

### W1 — § 8 eligibility vs § 1 parse-fail behaviour: contradiction on the WARN signal

§ 1 step 4 (line 303): "If parsing fails, the file is NOT eligible for discovery and the runner emits a `WARN` line naming the file and the parse failure".

§ 8 (lines 514-526): the eligibility list says "Filename parses to semver: per § 1" — i.e., parse-fail = not eligible. But § 8 is silent on whether parse-fail emits a WARN.

The § 1 table (line 314) says `TEMPLATE.sh` → "no (skip silently — § 8)" — explicit silent-skip. Line 316 says `v1.0.0.5.sh` (malformed) → "no (WARN)". So the rule is: `TEMPLATE.sh` is the only silent skip; everything else that fails parsing emits WARN.

But § 8 line 525 says "Unreadable files emit WARN and are skipped" — implying readable-but-unparseable also has a defined signal. The two sections agree in practice but the WARN-vs-silent dichotomy is split across them. Worse, § 8 line 520 lists "Not the scaffold: filename is not exactly `TEMPLATE.sh`" as an eligibility check — and § 8 does not say what happens to non-`TEMPLATE.sh` files that match `v*.sh` but fail § 1 parsing. The reader has to cross-reference § 1 step 4.

**Fix:** Add to § 8 an explicit "When discovery rejects a file" sub-list:
- `TEMPLATE.sh` exact match → silent skip
- Filename matches `v*.sh` or `[0-9]*.sh` but parse fails → WARN
- Unreadable → WARN
- Not a regular file (directory, FIFO, device) → silent skip
- Doesn't match either filename pattern → not enumerated at all (find never sees it)

This is a clarification, not a semantic change.

### W2 — Range-bound idempotency claim doesn't quite hold under the bounds defined

§ 2 (line 334): "A migration whose parsed semver equals the project's current `template.version` does NOT re-run."

§ 5 (lines 441-449) says re-runs ARE common in dogfood loops because "the source bound does not advance between dogfood passes against the same fixture". That's correct: a dogfood loop holds source bound constant and runs each in-range migration on every pass — by design, with idempotency contract as the cover.

But the § 2 wording "does NOT re-run" is loose: it does not re-run **on a subsequent upgrade after `template.version` has advanced past it**. It absolutely does re-run on every dogfood pass against the same source bound. The ADR knows this (§ 5) but a casual reader of § 2 will infer the wrong invariant.

**Fix:** Reword § 2 line 339-342:

> "A migration whose parsed semver equals the project's current `template.version` does NOT re-run **after that version is recorded as the source bound**; it already ran in the upgrade that advanced the source to its version. Within a dogfood loop where the source bound is held constant, in-range migrations re-run on every pass — see § 5 for the idempotency contract that covers this."

### W3 — Q-F-0017-1 (MIN_SUPPORTED_VERSION carrier): the ADR pre-decides while marking the question open

§ 9 (lines 558-561):

> "The framework's `MIN_SUPPORTED_VERSION` is recorded in the runner's `VERSION` file (new sibling line, "min_supported: <semver>", or — at SE's discretion — a sibling `MIN_SUPPORTED_VERSION` file at runner root)."

But Q-F-0017-1 (line 795-800) names this exact question as open, says architect leans separate-file. The "at SE's discretion" framing inside § 9 contradicts both: it punts a binding interface decision to SE, while § "Open questions" routes it to the customer.

The architect's own reasoning in Q-F-0017-1 (line 799-800) is right: a separate file is cleaner. The `VERSION` file's existing format (one-line semver) is consumed by the version-check helper; bolting a `key: value` line onto it forces every existing reader to skip-or-parse non-semver content. A separate `MIN_SUPPORTED_VERSION` file is a one-line semver file parallel to `VERSION` — same parser, same shape, zero coupling.

**Fix:** Either close the question in this ADR (architect's lean is sound, customer authorisation for this granularity is overkill given § "Implementation notes" already commits to runner-side parse logic), or remove the "at SE's discretion" clause in § 9 and leave the carrier strictly unpinned until Q-F-0017-1 closes. Pick one. Current text says both.

**On Q-F-0017-1 itself:** separate sibling file is the cleaner choice. `VERSION` is a single-purpose one-line semver consumed by an existing parser path; widening it to a multi-line `key: value` shape is a public-format change that ripples beyond the runner. A new sibling `MIN_SUPPORTED_VERSION` containing a bare semver is parallel to `VERSION` in shape, has no co-evolution risk, and is trivially testable in isolation. The architect's lean is correct. Recommendation: pre-close Q-F-0017-1 as `separate sibling file`; if customer review of that pre-close is required by Hard Rule #4 (cross-cutting framework change), route via tech-lead but flag it as a low-stakes confirmation, not a foundational ruling.

### W4 — Partial-state recovery under § 4 migration-failure semantics is under-specified

§ 4 (lines 397-405) is good on the runner's behaviour (abort, no state-write, exit non-zero, stderr names the failing migration + position + ran-set + did-not-run set). Operator recovery is "fix the migration body or fix the project tree, then re-run; the already-applied migrations re-run; their idempotency contract covers the re-run" (line 401-405).

The gap: the **applied migrations have mutated the project tree but the source-bound did NOT advance** (§ 4.2: "Do NOT write `TEMPLATE_STATE.json`"). So on re-run, the discovery set is identical to the first run (same source bound, same target). The already-applied migrations re-discover, re-run, and idempotency catches them. **That's correct, but it depends critically on `template.version` not advancing mid-chain.** The ADR should state that invariant explicitly: the source bound advances ONLY at successful end-of-chain, not per-migration.

Why this matters: if a future implementer reads § 4 and thinks "let's record incremental progress in TEMPLATE_STATE.json after each migration to avoid re-running them on retry", they will reintroduce the partial-state-recovery problem the current design dissolves. The "all-or-nothing source-bound advance" invariant is load-bearing and currently implicit.

**Fix:** Add a binding sentence to § 4, e.g.:

> "**Source-bound invariant:** `TEMPLATE_STATE.json.template.version` advances only on full-chain success. Mid-chain failures leave the source bound at its pre-upgrade value, ensuring the next upgrade re-discovers every migration in the original range and the idempotency contract (§ 5) handles the re-run."

---

## Suggestions

### S1 — § 1 parse table missing a row for the most likely future ambiguity

The table (lines 308-316) covers `v1.0.0-rc14.sh`, `1.1.0.sh`, malformed 4-segment, etc. It omits two realistic shapes:

- `v1.0.0-rc14+build.sh` — semver build-metadata. Does it parse? Per SemVer 2.0 build metadata is parsed but ignored for ordering. Does the runner accept or reject?
- `v1.0.0-rc.14.sh` (dotted pre-release identifier, not concatenated `rc14`) — legitimate semver, different ordering rules. Won't sort identically to `v1.0.0-rc14.sh`.

Neither is in the current tree. Both are plausible future authoring mistakes. The table should either include them as explicit rows or § 1 should say "build metadata and dotted pre-release identifiers are accepted per SemVer 2.0 § 9 / § 11" with a note that the existing convention uses concatenated `rcNN`.

### S2 — § 3 ordering examples missing a numeric-vs-alphanumeric boundary case

§ 3 (line 376) gives `v1.0.0-beta1 < v1.0.0-rc1`. SemVer 2.0 § 11.4.4 says pure-numeric identifiers have lower precedence than alphanumeric. So `v1.0.0-1` (pure numeric pre-release) < `v1.0.0-alpha`. That's not in the example list. The framework is unlikely to ship a `v1.0.0-1.sh` migration, but the self-test the ADR cites (`--self-test-semver`) should cover it. Add an example row or note that the self-test is the authority.

### S3 — § 7 discovery-log shape is good; add a machine-readable mode flag

The format (lines 492-506) is operator-readable. `qa-engineer`'s acceptance harness greps it (line 508-511). Grepping a human-formatted log is brittle. Suggest adding `--discovery-log-json` (or pinning to the implementation-ADR) so QA's assertion harness consumes structured data, not parsed prose. Optional; the current shape is sufficient for v1.0.0 acceptance.

### S4 — § 10 import contract: missing prohibition on shell-state mutation

The "MUST NOT" list (lines 603-622) covers sourcing other migrations, mutating `TEMPLATE_STATE.json`, network, daemons, out-of-tree IO. It does not explicitly forbid:

- `set +e` / `set +u` toggles that leak past the migration's end
- Trap installation that survives the migration's bash invocation
- `export`s of environment variables consumed by later migrations (cross-migration coupling via env)

These are all variants of the "cross-migration dependency" prohibition already stated (line 605-608), but a SE reading the list literally might miss them. Worth a "and any state mutation that outlives the migration's bash process" catch-all.

### S5 — Verification signal D (idempotency on re-run) implicit assumption about logging

Signal D (lines 705-709): "the second run's discovery log shows the same set as the first, and every migration emits its no-op signature."

The ADR says migrations should "produce minimal stdout" on no-op (§ 5 line 425) but does not define a "no-op signature" anywhere. Signal D references a thing that does not exist as a contract. Either define a no-op signature pattern (e.g., "migrations emit `<filename>: no-op` to stderr on idempotent re-entry"), or weaken signal D to "the second run completes successfully with no state mutation."

---

## Priority-by-priority disposition

| # | Priority | Status |
|---|---|---|
| 1 | Three-Path Rule | PASS — honest M/S/C; Option S explicitly names "preserves two parallel enumerations" as the failure pattern; Option C concedes its idempotency-relaxation is illusory. Not strawmen. |
| 2 | Filename → semver parse rule | PASS w/ W1 + S1 — table is complete for current tree; clarification on WARN signal split between § 1 and § 8 needed. |
| 3 | Range semantics | PASS w/ W2 — bounds are correct (half-open low / closed high); idempotency-vs-dogfood wording needs tightening. |
| 4 | Semver pre-release ordering | PASS w/ S2 — primary cases covered, numeric-vs-alphanumeric edge case missing. |
| 5 | Migration failure semantics | PASS w/ W4 — runner behaviour is well-pinned; source-bound-advance-on-success-only invariant needs to be explicit. |
| 6 | Idempotency guidance | PASS — positive-signal-detection is called out (line 436-439); the "negative-evidence breaks under hand-applied partial migration" rationale is sound. |
| 7 | TEMPLATE_VERSION fallback | PASS — three-case resolution in § 6 (lines 454-462) covers post-bridge, pre-bridge, scaffold-fresh; bridge-window only-moment-both-coexist is named. |
| 8 | Verification logging | PASS w/ S3 — shape useful; JSON mode would harden QA. |
| 9 | Migration retirement | PASS — unset = `0.0.0` (line 572-576) is safe default; advancement is operator-controlled per customer ruling on single-user posture; cleanup-batch path is documented. |
| 10 | Import contract | PASS w/ S4 — surface clean; catch-all on shell-state mutation would harden it. |
| 11 | Q-F-0017-1 | See W3 — ADR contradicts itself; recommendation is separate sibling file, pre-close in this ADR. |
| 12 | Hard Rule #8 boundary | PASS — pure design ADR, no production code, no scripts. Implementation explicitly deferred to FW-ADR-0017-impl (lines 783-787). |

---

## Disposition

**APPROVED-WITH-CHANGES.**

Architect amends:
- W1: § 8 explicit reject-table
- W2: § 2 reword on idempotency under dogfood
- W3: close Q-F-0017-1 (recommend separate file) AND remove "at SE's discretion" from § 9, OR leave § 9 unpinned until customer rules
- W4: § 4 source-bound-advance invariant statement

Suggestions S1–S5 are non-blocking; architect picks up at discretion or defers to impl-ADR. No re-CR; architect amends and flips status to accepted.

---

## Q-F-0017-1 comment (explicit, per dispatch brief)

**Recommendation: separate sibling file `MIN_SUPPORTED_VERSION` at runner root.**

Reasons:
- `VERSION` is currently a single-purpose, one-line semver file consumed by an existing parser. Widening it to a key: value multi-line shape changes a public format that has more readers than just the migration-retirement check.
- A sibling `MIN_SUPPORTED_VERSION` file containing a bare semver is structurally parallel to `VERSION` — same parser shape, zero co-evolution risk, trivially testable in isolation.
- Operator readability: `cat MIN_SUPPORTED_VERSION` answers the question directly; `grep '^min_supported' VERSION || echo "0.0.0"` is the same answer with more shell.
- The "two files instead of one" cost is negligible at runner root; the cost the framework keeps trying to retire is two-sources-of-truth about the *same* fact. Source bound and retirement bound are different facts.

This is a low-stakes architecture call. The architect's lean (separate file) is sound. Customer authorisation for this granularity may not be required given § "Implementation notes" already commits to runner-side parse logic; if Hard Rule #4 requires customer authorisation as a framework-managed file shape, route via tech-lead as a low-stakes confirmation, not a foundational decision.

---

**Files read for this review:**
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0017-file-keyed-migration-discovery.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0016-template-state-json-schema.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`
- `/home/quackdcs/SWEProj/sw-dev-team-template/migrations/` (directory listing)
