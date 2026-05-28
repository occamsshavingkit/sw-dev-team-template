# CODE REVIEW — FW-ADR-0019 (proposed, trigger-gated)

**ADR:** `/home/quackdcs/SWEProj/sw-dev-team-template/docs/adr/fw-adr-0019-pre-bootstrap-retirement.md`
**Review mode:** IEEE 1028 § 5 technical review against ADR chain (FW-ADR-0010, 0013, 0015–0018) and customer rulings 2026-05-14 / 2026-05-15.
**Scope:** design soundness only; status stays `proposed` per § 1 trigger gate.

> **Provenance note (transcription):** The dispatching code-reviewer session returned findings inline; tech-lead transcribed verbatim to preserve on-disk audit consistency with peer review reports. Authorship and judgment stay with `code-reviewer`.

---

## Net judgment

**APPROVED-WITH-CHANGES.** The design is sound, the Three-Path is honest, the supersession and ordering preserve audit-trail integrity, and Hard Rule #8 is respected (pure design, no code surface authored). Three items need correction before the trigger fires, and one is a one-line addendum to capture an architect-deferred soak question that the customer may want to weigh in on. None of the changes is structural.

---

## Findings

### Critical (block trigger flip until fixed)

**C-1.** § 1(a) cites a fixture count ("12/12") that may drift if rc15.1 extends the harness per FW-ADR-0018 § 8 escape-hatch. Pin to "the FW-ADR-0018 § 7 dogfood harness PASS for the rc15.N tag (count authoritative in § 7, not pinned here)."

**C-2.** § 7 step 1 ordering is operationally wrong — status flip must NOT precede the cleanup commits. Recovery procedure (§ Verification Failure-signal) only makes sense if status flip is the LAST commit. Reorder § 7 so status flip is LAST (after § 7 step 6 doc cleanup). Sequencing-rationale paragraph needs corresponding rewrite.

### Warnings

**W-1.** § 1(c) no-soak default papers over a real signal-collection question. A single bridged downstream confirms the bridge ran; it does not confirm post-bridge stability of the stub-fetch flow. Queue atomic question for customer: "After bridging confirms, should FW-ADR-0019 cleanup wait N days of post-bridge runner activity (suggested: 7 days), or flip immediately?" Add a post-bridge-instability case to § Verification failure-signal.

**W-2.** § 6 audit-log header update under-specifies parser back-compat. FW-ADR-0010 § "Audit-log surface" committed to: rows with empty `Gate` cell MUST be treated as `pre-release` for pre-2026-05-14 back-compat. § 6 should explicitly preserve that rule AND add "historical `pre-bootstrap` rows are valid and read-only; new rows MUST be `pre-release`."

**W-3.** § Verification Success signal C grep is over-permissive. Specify exact grep invocation: `grep -rIn 'SWDT_PREBOOTSTRAP_FORCE' --exclude-dir=.git` with deterministic expected file-list output. Same shape for `.template-prebootstrap-blocked.json`. Makes verification reproducible by software-engineer and qa-engineer.

### Suggestions

**S-1.** § 5 "no auto-removal" trade-off framing is one-sided. Acknowledge the alternative's merit (self-terminating deprecation). Add: "Auto-remove would self-terminate the deprecation cleanly; we accept the operator-action cost in exchange for evidence preservation."

**S-2.** § 4 WARN message contents need a project-version-anchor. Embed running framework version (`v1.x.y`) so operator bug reports cite the exact runner version that emitted the WARN.

**S-3.** § 2 "removal-safe condition" lacks a sunset. Suggest: "If 12 months pass after the rc15 lineage tag with no operator-bridge confirmation, the architect re-opens FW-ADR-0019 to re-examine the removal-safe condition."

**S-4.** § Verification Failure-signal — pre-bootstrap pattern resurfaces: a future re-introduction proposal supersedes FW-ADR-0015 AND FW-ADR-0019 (not just 0015). Add FW-ADR-0019 to the supersession set in that sentence.

**S-5.** § Implementation notes Piece 2 mis-orders the ADR status edits. Once C-2 is fixed (status flip is LAST commit), Piece 2's edit order should match § 7's revised ordering: FW-ADR-0010 + FW-ADR-0013 status edits land BEFORE the FW-ADR-0019 status flip.

---

## Item-by-item disposition against task brief priorities

| # | Priority | Verdict |
|---|---|---|
| 1 | Trigger condition § 1 sufficient? | **Sufficient with C-1 fix.** "At least one downstream" meaningful at single-operator scale; no-soak default defensible but architect should queue W-1 question for customer. |
| 2 | Removal ordering § 7 safe? | **Not safe as written. See C-2 — reorder so status flip is LAST.** |
| 3 | Deprecation curve §§ 4–5 length sufficient? | **Yes.** Stage 1 through v1.x is conventional; Stage 2 at v2.0.0 final is the right boundary. |
| 4 | `.template-prebootstrap-blocked.json` no-auto-removal trade-off honest? | **Defensible, with S-1 polish.** |
| 5 | Audit-log column Gate retention? | **Correct.** W-2 needed for parser back-compat clarity. |
| 6 | FW-ADR-0010/0013 status transitions correct? | **Correct.** `superseded by FW-ADR-0015 / FW-ADR-0019` is the right pointer pair. |
| 7 | Status field stays `proposed`? | **Confirmed correct.** Trigger-gated. |
| 8 | Three-Path Rule honest? | **Yes.** No fake-third-option pattern. |
| 9 | Verification grep sufficient? | **No — see W-3.** Needs exact invocation + expected output. |
| 10 | Hard Rule #8 boundary? | **Confirmed.** Pure design. |

---

## Conformance statement (IEEE 1028 § 5.6 shape)

The proposed ADR conforms to MADR 3.0 + the project's Three-Path Rule template, to the supersession contracts of FW-ADR-0010 / 0013, to the dependency framing in FW-ADR-0018 § 8, and to the customer rulings recorded for the rc12→rc15 lineage. The three Critical/Warning items (C-1, C-2, W-1) are correctness defects in design specificity, not structural defects. With those resolved, FW-ADR-0019 is ready to remain in `proposed` indefinitely until the trigger fires, and ready for the architect to flip via the cleanup PR (with § 7 reordered per C-2) when it does.

## Counts

- Critical: 2
- Warnings: 3
- Suggestions: 5
- Total findings: 10
