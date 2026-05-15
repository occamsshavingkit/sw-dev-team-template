# Code Review — FW-ADR-0018 (transitional rc bridging)

**Reviewer:** code-reviewer
**Target:** `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0018-transitional-rc-bridging.md` (1047 lines, `status: proposed`)
**Date:** 2026-05-15
**Mode:** IEEE 1028 § 5 technical review of an architectural work product against ADR-0015 / 0016 / 0017 / 0010 and customer ruling S (2026-05-15).

> **Provenance note (transcription):** The dispatching code-reviewer session's tool-policy prohibited writing report `.md` files and required inline return to the parent. Substantive review completed by `code-reviewer`; this file was transcribed verbatim by tech-lead as tool-bridge to restore on-disk audit consistency with peer review reports. Authorship and judgment stay with `code-reviewer` (commit trailer reflects this).

## Net judgment

**REJECTED.** Structural defect: the chosen rc name (`v1.0.0-rc14`) collides with an already-shipped, semantically-unrelated migration file (`migrations/v1.0.0-rc14.sh`, FW-ADR-0014 preservation-prune, present on `main` since PR #197 / 2026-05-15 13:39 UTC, 117 lines). The ADR's Interface Decision § 1 explicitly considered and rejected `v1.0.0-rc15`/`v1.0.0-bridge` — but did so with the wrong premise. The text claims "`v1.0.0-rc13` was already consumed by FW-ADR-0013's now-superseded rc-to-rc pre-bootstrap migration" yet is silent on the rc14 file that **also already exists**. This is not a rename quibble; it is the binding identifier of the bridging migration in five other places in the ADR (§§ 3, 4, 5, 7, 9, Implementation notes, Links), and it transitively breaks the FW-ADR-0017 § 5 idempotency contract the ADR itself cites at line 322 ("a migration file's identity is its filename; reusing it as a different body confuses re-runs").

Two other defects (Findings C-2, C-3) compound this: the idempotency rationale in §§ 4–5 has an internal contradiction the architect introduces and then partially walks back, and the FW-ADR-0019 sequencing creates a deadlock against the customer's own "dogfood before rc" rule.

Substance of the migration sequence (§ 3) is otherwise sound. The architecture-level decision is correct; the operational pin needs another pass.

## Counts

- Critical: **3**
- Warnings: **5**
- Suggestions: **4**
- Observations (non-blocking): **3**

## Critical findings

### C-1 — rc-numbering collision is unresolved. Priority 3, load-bearing.

**Where:** § 1 "Transitional rc name and version stamp" (lines 312–348); echoed at § 3 line 385 (`migrations/v1.0.0-rc14.sh`), § 4 line 525 (`v1.0.0-rc14.sh: no-op (already applied)`), § 5 line 611 (same), § 7 throughout, § 9 line 773, Implementation notes § Piece 3 line 908, Links line 1019.

**Evidence:** `ls migrations/` shows `v1.0.0-rc14.sh` already on disk (4073 bytes, 117 lines, FW-ADR-0014 preservation-prune migration, dated 2026-05-15 13:39). The file's body (lines 1–117) is the opt-in `.template-customizations` prune dry-run/apply migration — wholly unrelated to bridging.

**Why the ADR's § 1 rationale fails:**

1. The ADR text addresses only the rc13 prior-use case, not the rc14 prior-use case that is the actual collision. The rc14 file is invisible to the rationale.
2. The cited principle "monotonic rc numbers, no skips, no rebrands" is consistent with **`v1.0.0-rc15`**, not with reusing `v1.0.0-rc14`. The clean rule is "next-unclaimed semver." rc14 is claimed.
3. The ADR's own line 322 cites FW-ADR-0017 § 5: "a migration file's identity is its filename; reusing it as a different body confuses re-runs." Overwriting `migrations/v1.0.0-rc14.sh` with a different body is the exact violation that line warns against.
4. The "delete the existing rc14.sh and replace its body" path would silently corrupt the audit trail for any downstream that has already run the existing rc14 preservation-prune (the idempotency detector for that migration would not even fire on the new body — different no-op signature, different semantics).

**Required change:** rename to `v1.0.0-rc15` everywhere in the ADR. Update the version-stamp behaviour in § 1 (`template.version` advances to `"v1.0.0-rc15"` at sync exit). Update § 9's mapping table title and the post-bridge sync narrative. Update all six echo sites listed above. Note that audit-cleanup of the inert `migrations/v1.0.0-rc13.sh` and the existing `v1.0.0-rc14.sh` is correctly FW-ADR-0019 territory and should be cross-referenced from § 8 with that boundary made explicit (the rc15 bridging migration does NOT touch rc13.sh / rc14.sh on disk; they remain as historic migration files that no-op on already-past projects per FW-ADR-0017 § 5).

**Severity reasoning:** This is the rc that has to "stick the landing" per the customer-strategic frame. Shipping rc14 over an existing rc14 is the kind of upgrade-class regression the entire foundation-ADR series exists to prevent. Reject-and-rework, not amend-without-CR.

---

### C-2 — Idempotency detector has two contradictory binding rules in §§ 4 and 5.

**Where:** § 4 lines 522–532 (the "binding" detection rule); § 5 lines 599–617 (the "refined idempotency detection (binding)" rule).

**Evidence:** § 4 declares the binding rule as **state-file presence alone**:

```
if [[ -f "$PROJECT_ROOT/TEMPLATE_STATE.json" ]]; then
    if jq -e '.schema_version | startswith("1.")' ...; then
        echo "v1.0.0-rc14.sh: no-op (already applied)" >&2
        return 0
    fi
fi
```

§ 5 then declares a **different** binding rule — the triplet (state-file valid + stub sha256 match + legacy file absence):

```
if [[ $state_file_valid -eq 0 ]] && \
   [[ "$stub_installed" == "$expected_stub_sha" ]] && \
   [[ ! -f TEMPLATE_VERSION ]]; then
    echo "v1.0.0-rc14.sh: no-op (already applied)" >&2
```

Both are labelled "binding." § 4 then narrates an edge case where its own rule produces the wrong answer (lines 540–547: state file present + legacy files present = "detection rule triggers ... so re-runs no-op. The legacy files remain on disk as orphans"). § 5 calls that out and "refines" the rule. The result is an ADR that pins two incompatible binding detectors.

**Why this matters for the priority-2 question:**

The reviewer was asked: "is the triplet sufficient for all partial-completion states?" The triplet in § 5 is correct for the partial states the architect enumerates:

- (b)-done, (c)-not-done: state file valid + stub sha **does not match** → not-no-op → re-run continues from (c). Correct.
- (c)-done, (d)-not-done: state file valid + stub sha matches + legacy file **present** → not-no-op → re-run continues from (d). Correct.
- (a)..(d)-all-done: triplet matches → no-op. Correct.

So § 5 is the right detector. But § 4 is left contradicting it, and the ADR has not deleted § 4's detector or marked it superseded. A future reader implementing from § 4 alone would ship the wrong detector.

**Required change:** delete or downgrade § 4's code-block detector to a "naive shape — see § 5 for the binding refinement" note, OR merge § 4's body into § 5 and keep only the § 5 detector as binding. Pick one. Same-document contradiction on a binding rule is a structural defect.

**Additional partial-state the triplet does NOT cover:** state file written + stub installed + legacy files **partially** removed (e.g., `TEMPLATE_VERSION` gone, `TEMPLATE_MANIFEST.lock` still present, `.template-customizations` still present). The § 5 detector checks `! -f TEMPLATE_VERSION` only. The detector should check **all three** legacy files absent (or extend the triplet to a quad). Otherwise, a crash during § 3(d) between the three `rm` calls leaves the detector in an ambiguous state.

---

### C-3 — FW-ADR-0019 sequencing creates a deadlock against the customer's "dogfood before rc" rule for any rc-X.1 follow-up.

**Where:** § 8 lines 710–737 + § Verification line 866 (failure signal — pre-bootstrap-class regression).

**Evidence:** The ADR says (paraphrasing § 8) FW-ADR-0019 is blocked until rc14 ships AND at least one downstream PASSes dogfood against it. Combined with § Consequences line 810–814 ("the LAST pre-bootstrap MUST be perfect ... If rc14 ships with a broken pre-bootstrap, the fix vehicle is 'yet another in-tree rc' — contradicting this ADR's 'LAST' commitment"), this is set up as an aspirational constraint with no enforcement mechanism.

But here is the actual deadlock: suppose rc15 (after C-1 renumber) ships, runs against one downstream, fails on baseline N+1. The customer's "dogfood before rc" rule (binding, 2026-05-15) requires dogfood-vs-rc15.1 PASS before rc15.1 cuts. But rc15.1 IS another in-tree pre-bootstrap rc. The ADR's "LAST" commitment is structurally not enforceable — the framework's escape hatch is exactly the path the ADR says cannot exist.

**Why this is critical, not merely uncomfortable:** the customer's `feedback_dogfood_before_meta_bump` and `feedback_dogfood_needs_tui_check` memory entries are explicit that script-level PASS is necessary but not sufficient (AI-TUI interaction must also pass). The 12-fixture extended dogfood gate in § 7 is the right floor, but the ADR does not address what happens when the gate catches a defect AFTER tag cut (i.e., a downstream finds a real-world fixture the 12-fixture harness didn't cover). The Verification § "Failure signal — pre-bootstrap-class regression" line says "Routes to `architect` for re-review" — without specifying whether that re-review can cut another in-tree rc or must somehow be solved without one.

**Required change:** either (a) accept explicitly that a "rc15.1" pre-bootstrap follow-up is permitted under the same dogfood gate if rc15 ships broken — at which point the "LAST" framing weakens to "intended-LAST, escape hatch documented," and FW-ADR-0019 stays blocked until the rc15 lineage actually lands clean; or (b) define the conditions under which the customer would accept post-tag-cut remediation by means OTHER than another in-tree rc (e.g., upstream-side runner-only fix, with operators re-running the existing rc15 against an updated runner). Option (a) is the honest framing; option (b) is the design choice the ADR currently elides. Pick one and write it.

## Warnings

### W-1 — Source-baseline range § 2 silently excludes the `1.1.0.sh` legacy file. Operator-error-friendly behaviour needed.

**Where:** § 2 lines 350–373; corroborated by `ls migrations/` showing `1.1.0.sh` present (un-prefixed, 1541 bytes, 2026-05-06).

The text mentions `1.1.0.sh` parenthetically ("plus the legacy un-prefixed `1.1.0.sh` which is a misnomer for a pre-v0.13.0 migration") but does not specify the refusal behaviour for a project whose `TEMPLATE_VERSION` line 1 happens to read `1.1.0` (un-prefixed semver). The detection rule "if `TEMPLATE_VERSION` line 1 parses to a semver < v0.13.0, refuse" implicitly handles this — `1.1.0` parses to `< 0.13.0` if the `v` prefix is normalised — but the ADR doesn't say which semver parser, and bash's natural string comparison would say `1.1.0 > 0.13.0`. The error message text should explicitly handle the un-prefixed case ("`TEMPLATE_VERSION` line 1 is missing the `v` prefix" → reformat-then-retry guidance).

### W-2 — Pre-bootstrap inheritance line range is wrong.

**Where:** § 3(a) line 405 "inherit `migrations/v0.14.0.sh:42-200+` atomic-rename pattern verbatim"; echoed at § Implementation notes line 909 (same range), § Links line 1027 (same).

**Evidence:** `wc -l migrations/v0.14.0.sh` returns 334. The "42-200+" range is plausible as the pre-bootstrap block (line 42 is the `WORKDIR_NEW:?` guard immediately preceding the pre-bootstrap comment block; the function definitions start at line 62). But "200+" is hand-wavy; the actual end of the pre-bootstrap-relevant code likely runs further. The `software-engineer` implementing from this ADR should be told the precise end line (e.g., "lines 42–<exact-end>") or, better, the named function set (`prebootstrap_sha`, `prebootstrap_decide`, and the matrix-execution block). Hand-waved ranges in implementation notes routinely produce verbatim-copy bugs.

### W-3 — Atomic-rename ordering in § 3 step (c) has a subtle correctness claim that needs validation.

**Where:** § 3(c) lines 444–471, especially 449–462 ("the rc14 in-tree `scripts/upgrade.sh` ... was already pre-bootstrapped in step (a) ... The migration body atomic-replaces `scripts/upgrade.sh` ONE MORE TIME ... the running rc14 `scripts/upgrade.sh` keeps reading its unlinked inode while the new stub takes the path").

This relies on bash holding the open fd on the unlinked inode across **two** atomic-renames on the same path (the (a) rename and the (c) rename) within the same process lifetime. The (a) rename runs in pre-bootstrap context, before the bridging migration's body starts. The (c) rename runs from inside the bridging migration body, which was sourced by the in-tree `scripts/upgrade.sh`. Both work in isolation; the chained-rename + fd-survival claim should be validated on the test bench before SE implementation locks in. The ADR correctly flags this at Implementation notes line 944 ("SE verifies on the test bench"), but the ADR's prose treats the chained pattern as obviously-correct rather than test-bench-required. Tone it down.

### W-4 — Dogfood gate criterion: § 7's "9/9" / "11/11" / "12/12" framing drifts. Pick one.

**Where:** § 7 lines 652–708, § Verification line 843 ("dogfood-vs-rc14 = 9/9 PASS (extended to 11/11 + 1 force-coverage = 12/12) before tag cut").

The ADR mixes three counts. Best read: the existing 9 fixtures + 2 added baselines (v0.14.0, v0.15.0) + 1 `SWDT_PREBOOTSTRAP_FORCE` coverage fixture = 12 total. State that arithmetic once in § 7 and reference it from § Verification. The customer's question framing ("Is '12/12 PASS' the right shape, or should some fixtures be allowed to FAIL with documented reasons") deserves an explicit answer in the ADR rather than being elided. Recommend: 12/12 PASS is the floor; any FAIL blocks the cut UNLESS the failing fixture corresponds to a customer-acknowledged out-of-scope baseline (pre-v0.13.0 refusal cases per § 2) AND the refusal is the expected behaviour. Document the carve-out criterion in § 7.

### W-5 — § Verification "Success signal D" wording understates the partial-state coverage.

**Where:** § Verification lines 855–859.

The signal only names ONE partial state (mid-step (b) crash). The ADR's own § 5 enumerates four partial-failure modes. § Verification should list at least the (b)-done-(c)-not-done and (c)-done-(d)-not-done cases explicitly, because those are the cases C-2's refined detector exists to handle. As written, signal D could pass with a detector that only covers the (b)-mid case and misses the (c)-(d) cases.

## Suggestions

### S-1 — Over-cap is real and concentrated.

ADR is 1047 lines vs ~600 cap. The architect's self-noted "§§ 3 / 5 / Implementation notes could shed ~400 lines" is correct. Specifically:

- § 3 step (a) is ~30 lines of prose that could be replaced by "see FW-ADR-0010 § X for the 3-SHA decision matrix; this bridging migration's pre-bootstrap block invokes the same matrix against the bootstrap-critical fileset {`scripts/upgrade.sh`, `scripts/lib/*.sh`} as `migrations/v0.14.0.sh` lines 42-<end>."
- § 5 has the duplicated-detector body that should collapse per C-2.
- § Implementation notes "Piece 3" overlaps § 3 substantially. Cut the overlap, keep "Piece 3" as a one-paragraph pointer back to § 3.

Per CLAUDE.md guidance to flag style-guide issues by reference rather than re-litigating: ADR template cap is in `docs/templates/adr-template.md`. Cite that, then trim.

### S-2 — The "Option M / Option S" relabel against the customer's "S" framing is correct but confusingly worded.

§ Option S "Cons" lines 246–254 explain that "architect's M = customer's S at the FW-ADR-0015-level." This is correct, but reads as a defensive footnote. Move it up to the top of § Considered options as a single italicised sentence: "Note: this ADR's M/S/C labelling is at its own granularity; the customer's 2026-05-15 'S' ruling on the migration path corresponds to this ADR's Option M." Then the rest of the section reads cleanly.

### S-3 — Add a one-line "what this means for the FW-ADR-0014 preservation-prune migration" note.

The existing `migrations/v1.0.0-rc14.sh` (after rename per C-1) continues to exist as a project-version migration that runs when source-baseline projects upgrade through v1.0.0-rc14. After the rename to rc15-bridging, the rc14-prune migration is one of the legacy in-tree migrations that the bridging migration's source-baseline range § 2 implicitly covers (a project at v1.0.0-rc13 upgrading via the rc15-bridge will see rc14-prune and then rc15-bridge run in that order, per FW-ADR-0017 file-keyed discovery). State this explicitly in § 3 or in a new "Interaction with existing migrations" subsection.

### S-4 — Cross-link to `feedback_dogfood_needs_tui_check` is correct but should be promoted from § 7 bullet to a binding constraint.

§ 7 line 685 ("AI-TUI interaction check (per the `feedback_dogfood_needs_tui_check` memory)") references customer feedback that explicitly upgraded "script-level PASS catches only script regressions; AI-TUI session interaction must also be verified before meta bump." The ADR treats this as one criterion among seven for PASS. Given the customer's binding framing, AI-TUI PASS should be a separate gate alongside the script-level 12/12 — i.e., 12/12 script PASS AND ≥1 AI-TUI session PASS against a representative post-bridge fixture.

## Observations (non-blocking)

### O-1 — Hard Rule #8 boundary: clean.

The ADR is pure design; no production code in the ADR body. Implementation notes correctly route the three pieces (stub, runner, bridging migration) to `software-engineer`, with `qa-engineer` on tests, `tech-writer` on release notes, `security-engineer` on pre-bootstrap atomic-rename review. Hand-off ownership is correctly described.

### O-2 — Three-Path Rule: honestly compared given customer pre-selection.

§ Considered options does compare alternatives substantively. Option S's cons are real (curl-bash culture cost, two-source-of-truth re-emergence). Option C's cons are real (operator cost, git history loss). The architect did not strawman the rejected options. The customer's "S" pre-selection (at FW-ADR-0015 level) is correctly noted as endorsing the chosen path, not as a circumvention of the Three-Path discipline.

### O-3 — Rollback story (§ 6): honest.

The "git history is your rollback" framing is correctly identified as a deliberate trade-off, with the rationale (information-preserving inverse exists but maintenance burden unjustified for one-time event) made explicit. The framing matches the "upgrade is always buggy" + "transitional rc is a one-way door" strategic frame. Acceptable.

## What must change for approval

1. **C-1 fix (rc-numbering collision):** rename `v1.0.0-rc14` to `v1.0.0-rc15` across all six echo sites in the ADR. Add an explicit clause in § 1 stating that `migrations/v1.0.0-rc14.sh` (FW-ADR-0014 prune migration) and `migrations/v1.0.0-rc13.sh` (FW-ADR-0013 rc-to-rc pre-bootstrap) remain on disk untouched; their disposition is FW-ADR-0019 territory.
2. **C-2 fix (detector contradiction):** delete or downgrade § 4's naive detector; keep § 5's triplet as the single binding detector; extend the triplet to check all three legacy files absent (not just `TEMPLATE_VERSION`).
3. **C-3 fix (rc-X.1 deadlock):** add explicit "if rc15 ships broken, the framework's escape hatch is rc15.1 under the same 12/12 + AI-TUI dogfood gate, and FW-ADR-0019 stays blocked until rc15 lineage lands clean" — or equivalent honest alternative.
4. **W-2 fix (pre-bootstrap line range):** name the exact functions / line ranges in `v0.14.0.sh` to clone, not "42-200+".
5. **W-4 fix (12/12 arithmetic):** state the count once, derive everywhere else from that statement.

The remaining warnings and suggestions are amend-without-re-CR if (1)–(5) above are addressed in a single revision pass.

## Disposition

**REJECTED.** Return to architect for revision pass on the five required-change items. Re-submit for CR after revision. Estimated revision effort: ~half a day for the architect (the rename is mechanical; C-2 / C-3 are surgical; the structural surface of § 3 is sound and stays).

## Specific answer to priority-3 question (rc-numbering collision)

The architect addressed only the rc13 collision (lines 318–323) and missed the rc14 collision. The current `migrations/v1.0.0-rc14.sh` is the FW-ADR-0014 preservation-prune migration (117 lines, 2026-05-15 13:39 ctime), entirely unrelated to bridging. The architect's "monotonic rc numbers, no skips, no rebrands" principle, applied consistently, yields `v1.0.0-rc15` — that is the right answer. The rc14 oversight is not a typo; it is a process gap (the architect did not run `ls migrations/` against the proposed name). Audit-cleanup of `v1.0.0-rc13.sh` and `v1.0.0-rc14.sh` is correctly FW-ADR-0019 territory and should be cross-referenced from § 8.

---

**Files referenced (absolute paths):**

- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0018-transitional-rc-bridging.md` (target of review)
- `/home/quackdcs/SWEProj/sw-dev-team-template/migrations/v1.0.0-rc14.sh` (the collision — existing FW-ADR-0014 prune migration, 117 lines)
- `/home/quackdcs/SWEProj/sw-dev-team-template/migrations/v1.0.0-rc13.sh` (existing FW-ADR-0013 rc-to-rc pre-bootstrap, 273 lines)
- `/home/quackdcs/SWEProj/sw-dev-team-template/migrations/v0.14.0.sh` (pre-bootstrap reference implementation, 334 lines total; W-2 evidence)
- `/home/quackdcs/SWEProj/sw-dev-team-template/CUSTOMER_NOTES.md` lines 296–321 (customer's "S" ruling)
- `/home/quackdcs/SWEProj/sw-dev-team-template/docs/pm/dogfood-2026-05-15-results.md` (the 0/9 PASS data this rc must dissolve)

---

# Re-CR pass — 2026-05-15 (post-revision)

**Net judgment: APPROVED-WITH-CHANGES (non-blocking).** Status stays `accepted`. Architect amends Fresh-1 + Fresh-2 in the deferred S-1 housekeeping pass; no re-CR.

> **Provenance note (transcription):** Re-CR session returned findings inline; tech-lead transcribed verbatim.

## Counts

- Critical resolved: 3/3 (C-1, C-2, C-3 all applied at primary sites)
- Warnings resolved: 5/5 from the prior pass (W-2 + W-4 verified; W-1 / W-3 / W-5 were non-blocking deferrals)
- Fresh findings: 2 non-blocking

## Required-change verification

- **C-1 (rc14 → rc15 rename):** APPLIED. Six echo sites renamed. § 1 names both rc13 + rc14 prior-use cases. The rc13/rc14 references at lines 326-327, 343-344, 543-550 read correctly as collision evidence + FW-ADR-0017 file-keyed-discovery ordering note, not as the bridging rc name.
- **C-2 (detector contradiction):** APPLIED. § 4 detector explicitly downgraded with inline `# NAIVE — do not implement this form` comment + binding clause. § 5 is single binding source. Quad form checks all three legacy files absent.
- **C-3 (intended-LAST + escape hatch):** APPLIED at § 8. "Intended-LAST" framing explicit; rc15.1 named as binding escape hatch under same 12/12 + AI-TUI dogfood gate; FW-ADR-0019 blocked until "rc15 lineage" lands clean. **But:** reframe not propagated to upstream sections — see Fresh-1.
- **W-2 (pre-bootstrap line range):** APPLIED. "lines 42-262 plus named function set" at all three sites. Line 262 verified as precise end of proceed-list atomic-install in v0.14.0.sh (334 lines total; 263+ is manifest synthesis, semantically distinct).
- **W-4 (12/12 single arithmetic):** APPLIED. § 7 has single arithmetic block (9+2+1=12); all other sites consistently reference 12/12. Carve-out criterion for refusal-as-expected fixtures documented.

## Fresh findings

### Fresh-1 — C-3 reframe is structurally incomplete; four upstream sites still encode the original deadlock framing. Non-blocking.

**Where:**
- § Context line 97: "It is the LAST in-tree rc the framework will cut; no further rc-cliffs follow."
- § Decision drivers lines 132-144: "LAST in-tree rc" header + "LAST pre-bootstrap class instance" header, with lines 142-144 framing rc15.1 as a contradiction.
- § Consequences-Negative lines 871-875: "The LAST pre-bootstrap MUST be perfect. ... contradicting this ADR's 'LAST' commitment."
- Minor: line 1090 in Links calls v0.14.0.sh's pattern "LAST instance of the pre-bootstrap class" without the lineage qualifier.

**Why it matters:** § 8's binding clause asserts LAST of the rc15 *lineage*, not of the tag in isolation. Four upstream sites still assert LAST of the tag in isolation. A reader reaching § 8 only after § Context / § Decision drivers / § Consequences will see framing inverted between sections.

**Recommended fix:** in the same housekeeping pass as S-1 trim, replace the absolute "LAST" claims at lines 97-98, 132-144, 871-875, 1090 with "intended-LAST (rc15 lineage); see § 8 for escape hatch" wording, OR trim the deadlock-narration sentences in § Decision drivers and § Consequences-Negative entirely now that § 8 carries the binding clause.

### Fresh-2 — § Status "Consulted" line 70 has stale "9-fixture acceptance harness" wording. Non-blocking, trivial.

Should read "12-fixture acceptance harness shape" or "extended 12-fixture acceptance harness shape" to match W-4's standardized arithmetic.

## Structural sanity

- Status field: `status: accepted` in frontmatter; § Status block has both `Proposed: 2026-05-15` and `Accepted: 2026-05-15`. Two stamps same day is internally consistent.
- Line count (1117 vs ~600 cap): S-1 trim deferred. Fresh-1 fix net-reduces lines in §§ Decision drivers and Consequences-Negative.
- Hard Rule #8 boundary: ADR remains pure design.
- FW-ADR-0017 § 5 idempotency contract: honored — rc13.sh and rc14.sh remain on disk untouched per § 1's interaction clause.

## Disposition

**APPROVED-WITH-CHANGES (non-blocking).** Status stays `accepted`. Chain proceeds to FW-ADR-0019. Architect folds Fresh-1 + Fresh-2 fixes into deferred S-1 housekeeping pass; no re-CR required.
