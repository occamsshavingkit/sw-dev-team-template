# Code-reviewer report — FW-ADR-0015 (upgrade orchestrator stub model)

**Artefact:** `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md` (770 lines, status `proposed`)
**Reviewer:** code-reviewer (IEEE 1028 § 5 technical review against ADR + customer rulings)
**Date:** 2026-05-15
**Net judgment:** **APPROVED-WITH-CHANGES** — 0 blocking, 7 non-blocking (NB-1 through NB-7)

The ADR is sound on its central claim and disposes of the four prior failure
classes by construction. The architect may flip `status: proposed` →
`accepted` and proceed to FW-ADR-0016. NB items are amendments the architect
can apply without re-engaging code-review; none gate the status flip.

---

## Scope verified

- ADR text read in full (770 lines).
- Paired companion reports read: `docs/pm/upgrade-flow-conceptual-mistake-2026-05-15.md`
  (architect), `docs/pm/upgrade-flow-process-debt-2026-05-15.md`
  (process-auditor). Both converge on the orchestrator-self-mutation root
  cause; the ADR's prose tracks both faithfully.
- Customer rulings read: `CUSTOMER_NOTES.md` entries at L256, L296, L323,
  L348 (out-of-tree stub; migration path S; air-gap out of scope; TLS +
  checksum security floor). All four are captured verbatim or by faithful
  paraphrase in the ADR.
- Superseded ADRs surveyed: `fw-adr-0010-pre-bootstrap-local-edit-safety.md`
  (full supersession claim), `fw-adr-0013-rc-to-rc-pre-bootstrap.md` (full
  supersession claim), `fw-adr-0014-preservation-vs-manifest.md` (partial,
  Q1 only).
- Current `scripts/upgrade.sh` CLI surface enumerated against the ADR's
  proposed stub surface (the `--resolve` and `--self-test-semver` flags
  surface in NB-1 below).
- Existing dogfood consumers of `scripts/upgrade.sh` audited
  (`scripts/smoke-test.sh` + `scripts/scaffold.sh`).

---

## Walk against review priorities

### Priority 1 — soundness of the conceptual frame

**Finding: sound.** §"Context and problem statement" (lines 70-106) identifies
the orchestrator-self-mutation pattern precisely and traces it through the
four 2026-05 fixes. The framing "ship the new driver via the old driver's
migration runner, on the theory that the old driver will reach the migration
runner before its sync loop touches `upgrade.sh`" (lines 95-98) names the
root cause exactly as both companion reports do. §"Decision outcome" (lines
295-310) does not argue backwards from a desired conclusion — it explicitly
calls out that Option S "preserves the conceptual mistake the dogfood
evidence identified; 'smarter discovery within the same model' was tried
in PR #186 and the failure pattern survived." That is the structural
argument, not a preference one.

### Priority 2 — stub CLI surface frozen across v1.x

**Finding: sound on the framework concept; one omission flagged.** The
frozen surface (lines 330-337) is genuinely minimal: `--target`, `--dry-run`,
`--verify`, `--help`/`-h`, `--no-verify`, `--`. The §"Forbidden in the stub"
clause (lines 339-344) and the sub-100-line hard budget (lines 346-350) are
the right locks. **However: see NB-1 below — `--resolve` and
`--self-test-semver` are documented as live flags in the current
`scripts/upgrade.sh` usage block (lines 33-67) and are exercised by
`scripts/smoke-test.sh:462`.** The §"Backward-compat shim contract" (lines
462-471) generically asserts these flags "MUST" forward to the runner
verbatim, but they are not named in the freeze table. The omission is
documentation-shape, not a structural defect: per the forbidden-list and
the unknown-flag-forwards rule (line 341), they ARE handled — but a future
reader will look at the freeze table first, miss the back-compat clause,
and assume `--resolve` was dropped.

### Priority 3 — fetch protocol soundness

**Finding: sound on the high points; three edge cases flagged.**
- TLS + checksum-pinning baseline matches customer ruling 2026-05-15 L348
  ("TLS and checksum will be plenty"). Captured at lines 410-433.
- Exit codes 10 (integrity) / 11 (network) / 12 (runner-not-found) are
  cleanly separated from runner-owned 0/1/2 (lines 452-460). Code 13+ is
  reserved (line 460), which is correct future-proofing.
- **NB-2:** First-observation pinning (lines 414-418): the ADR says
  "Cross-ref upgrades... accept the fetched runner unconditionally on the
  first run and pin the observed checksum for future runs against that
  ref." This is reasonable in steady state but creates a TOFU
  (trust-on-first-use) window — if the upstream has been compromised at
  the moment of first observation against a new ref, the operator pins
  the bad checksum. Acceptable given the customer's threat-model floor,
  but worth naming explicitly under "Negative / trade-offs accepted" so a
  future reviewer doesn't mistake it for an oversight.
- **NB-3:** Runner-exits-with-unknown-code edge case (raised in priority 3
  of the dispatch brief): the ADR does not address what the stub does
  when the runner exits with a code outside the documented namespace.
  Per line 376 ("The stub `exec`s the runner with all forwarded
  arguments. The stub does not survive the exec") the answer is implicitly
  "the stub is already gone — the runner's code is the process's code."
  This is the correct behaviour but it is not stated, and a careless
  reader of the failure-modes table (lines 444-450) could conclude the
  stub interprets exit codes 3-9 (which line 459 marks as "reserved").
- **NB-4:** Legitimate-checksum-mismatch recovery (raised in priority 3
  of the dispatch brief): if upstream legitimately re-publishes a runner
  at a moving ref (`main`, `--target <branch>`), the pinned checksum from
  the prior run will mismatch. The stub refuses with exit 10. The ADR
  documents `--no-verify` as the escape hatch (line 448), but does not
  document the "expected behaviour: bump the pin" workflow. Operators
  hitting this in practice will need a documented re-pin path; otherwise
  they'll learn to `--no-verify` reflexively and the pin becomes
  ceremonial. This is an operator-UX issue, not a design defect; the ADR
  can name it in §"Failure modes and operator recovery" without altering
  the model.

### Priority 4 — supersession completeness

**Finding: full supersession claims (FW-ADR-0010, FW-ADR-0013) are
correct; partial supersession (FW-ADR-0014) is correctly scoped.**
- FW-ADR-0010 (pre-bootstrap local-edit safety): the entire pre-bootstrap
  concept derives from the orchestrator-self-mutation problem the stub
  model dissolves. The 3-SHA matrix, the block artefact, the
  `SWDT_PREBOOTSTRAP_FORCE` env var, and the `Gate=pre-bootstrap` audit
  rows are all artefacts of "the old driver protecting itself from being
  overwritten." Once the runner is fetched fresh per invocation and the
  stub does not self-mutate, the entire concept is moot. The ADR claims
  this at lines 597-605 and the claim holds.
- FW-ADR-0013 (rc-to-rc pre-bootstrap via cloned migration): same root.
  The cloned `migrations/v1.0.0-rc13.sh` is unreachable because discovery
  walks `git tag -l 'v*'`. File-keyed discovery (FW-ADR-0017) plus the
  stub model retire the entire class. Claim at lines 606-612 holds.
- FW-ADR-0014 (preservation vs manifest): partial supersession at Q1 is
  correctly scoped. The two-source-of-truth problem dissolves once
  `TEMPLATE_STATE.json` (FW-ADR-0016) carries per-path declarations
  alongside the manifest; the §"divergence-only AND
  manifest-respecting" rule becomes a declaration class, not a runtime
  gate. The Q2 (two-phase exit) survives unchanged inside the runner.
  ADR claims this at lines 615-628; the claim holds. **NB-5:** the
  ADR says "FW-ADR-0014's status becomes `partially superseded by
  FW-ADR-0015 (Q1 only); Q2 survives` once FW-ADR-0016 lands." The
  status-flip prose for FW-ADR-0014 itself (which currently reads
  `status: accepted, 2026-05-15`) is not specified — the architect
  should pin the literal status-line wording when FW-ADR-0016 ships, so
  the partial-supersession is searchable from the FW-ADR-0014 side.

### Priority 5 — migration path forward

**Finding: FW-ADR-0015 does not pin choices that constrain FW-ADR-0018's
design space.** §"Migration path forward" (lines 575-592) names the
dependency on FW-ADR-0018 ("one transitional rc bridges existing
downstreams onto the stub model") without specifying the bridging-rc's
content or operator UX. The single binding clause — "the bridge rc is
the last `upgrade.sh` the framework ships in the v1.x line" (line 589)
— is a structural commitment, not an implementation pin; FW-ADR-0018
retains full design freedom on the bridging mechanics. The stub's
backward-compat shim contract (lines 463-481) accepts the legacy flag
set and env-var pass-through, which is precisely the right interface
seam for the bridging rc to write into.

### Priority 6 — open questions surfaced

**Finding: the two open questions named in the ADR's text were resolved
2026-05-15 (`CUSTOMER_NOTES.md` L323, L348) and the ADR's prose still
treats them as open in two spots:**
- Line 199 ("Open question routed to `sre` + customer") — air-gap
  question is closed (out of scope per L323).
- Lines 446 + 688 ("documented offline-mode path (open question;
  FW-ADR-0015-followup)" and "Routes to `sre` + customer for the air-gap
  question (open at ADR-acceptance time)") — same.
- Lines 199-202, 431-433 — security-posture review is named as the
  binding gate, but the customer ruling at L348 sets the floor at "TLS
  and checksum will be plenty"; the ADR correctly preserves
  `security-engineer` review as the gate while the floor is set.

**NB-6:** before the status flip, the architect should reconcile lines
199, 446, and 688 against L323 / L348 — the open-question framing in
the ADR is now stale. The §"Verification" failure signal "operator
filings report network-dependency as a blocker for a downstream
population segment the framework did not know about" (lines 685-688)
is still correct as a forward-looking failure signal (the customer's
ruling that "the only current user of this template is me" means the
population could grow); the staleness is purely in the
question-still-open framing.

**No new open decision axes surfaced.** The remaining unknowns
(specific fetch mechanism — curl vs git-archive; tempfile vs
`bash -c "$(curl ...)"` pattern) are correctly scoped as
`software-engineer`-owned implementation choices.

### Priority 7 — risks not yet named

Three risks worth naming explicitly (not blocking; documentation-shape):

- **NB-7a — Existing downstreams that DON'T run the transitional rc.**
  The dispatch brief raised this; the ADR does not name it. Customer's
  ruling that "the only current user of this template is me" (L329)
  bounds the operational impact today, but the ADR is a foundational
  artefact and will outlive that fact. If a downstream skips the
  transitional rc and tries to jump from v1.0.0-rc11 directly to
  v1.1.0+, the stub-model upgrade path is unreachable. FW-ADR-0019
  (pre-bootstrap retirement) presumably documents the deprecation tail
  for the pre-bootstrap force-env, but the "skipped the bridge" case
  is a distinct failure mode worth a sentence in §"Migration path
  forward" or in FW-ADR-0018.
- **NB-7b — Stub-format v2.0 migration story.** The ADR commits the
  stub CLI surface frozen across v1.x (line 324) and says "changes
  require a new foundational ADR." That is the right freeze. But when
  v2.0 lands and the stub format itself needs to evolve, the same
  conceptual mistake the ADR identifies (the orchestrator can't
  upgrade itself) applies to the stub. The ADR's implicit answer is
  presumably "the stub is so minimal that operators can swap it
  manually via the retrofit one-liner" (line 449), but this is not
  stated. A sentence at line 350 or in §"Consequences" would close
  this loop.
- **NB-7c — Runner ever calling back into the stub.** The ADR is
  silent on this. The model implies the answer is "no" (the stub
  `exec`s the runner and is gone), but for completeness: future
  features that the architect might be tempted to surface in the stub
  (a `--version` flag reporting the stub's own version, a
  `--self-update` flag triggering a stub-retrofit one-liner) would
  re-introduce the dual-role problem. The line-budget and forbidden
  list (lines 339-350) are the structural defence. Worth a one-line
  note that these temptations are exactly the failure mode the budget
  defends against.

### Priority 8 — process audit invitations

**C-2 (destroy-state + re-scaffold from latest as a sanctioned escape
valve).** The ADR does not explicitly address C-2 from the
process-auditor's report. The stub model implicitly provides an
escape valve via the retrofit one-liner (line 449: "Re-install the
stub via the retrofit path (FW-ADR-0018). The retrofit path is a
single curl one-liner that writes the stub atomically.") This is
not equivalent to "destroy-state and re-scaffold from latest" —
the retrofit preserves project state; C-2 contemplated discarding
it. The ADR's answer to C-2 is implicitly "no, project state is
preserved through the bridging rc," but C-2 is a customer-call
question still routed to the customer through `tech-lead`. The ADR
does not need to resolve C-2; it does need to NOT preclude the
customer's answer being "yes, offer destroy-state as a sanctioned
path." The ADR does not preclude it; `TEMPLATE_STATE.json` could
be deleted and `scripts/scaffold.sh` re-run for a clean re-scaffold
under the stub model just as easily as today.

**Rc-cadence + migration-retirement questions** are correctly
scoped to FW-ADR-0019 and out of scope here.

---

## Blocking findings

**None.**

The ADR identifies the right root cause, proposes a model that
dissolves rather than relocates the failure pattern, honours all
four 2026-05-15 customer rulings, correctly scopes its superseded
ADRs, leaves FW-ADR-0018 design-room, and includes a verification
section with concrete success/failure signals (lines 656-691). The
sub-100-line stub budget plus the §"Forbidden in the stub" clause
are the right structural locks to keep the orchestration logic
from leaking back into the project tree.

---

## Non-blocking findings (architect may amend without re-CR)

| ID  | Finding | Location | Suggested fix |
|-----|---------|----------|---------------|
| NB-1 | Freeze table omits `--resolve` and `--self-test-semver`; back-compat clause covers them but the freeze table is the first thing a future reader sees | Lines 330-337 vs current `scripts/upgrade.sh:33-67` | Add a footnote under the freeze table: "Legacy flags (`--resolve`, `--self-test-semver`) forward verbatim to the runner per the backward-compat shim contract; they are not part of the stub's frozen surface." |
| NB-2 | TOFU window on first-observation checksum pinning is implicit | Lines 414-418 | Add one sentence to §"Negative / trade-offs accepted" naming the TOFU posture as an accepted cost; matches the customer's "TLS and checksum will be plenty" floor. |
| NB-3 | Stub behaviour on runner exit codes 3-9 (currently "reserved") is implicit | Lines 452-460 | Add to the exit-code namespace block: "The stub does not interpret runner exit codes; whatever the runner exits with, the process exits with. Codes 3-9 are reserved at the framework level for future runner-owned use, not for the stub." |
| NB-4 | Legitimate-checksum-mismatch operator-recovery flow undocumented | Lines 444-450 | Add a row to the failure-modes table: "Legitimate runner update (upstream re-published at moving ref) → exit 10 → operator updates pin in `TEMPLATE_STATE.json` (mechanics: FW-ADR-0016 / FW-ADR-0015-impl)." |
| NB-5 | FW-ADR-0014 status-line wording after FW-ADR-0016 lands is unspecified | Lines 615-628 | Pin the literal status-line wording for FW-ADR-0014 (e.g., `status: accepted (Q2 active); Q1 superseded by FW-ADR-0015 / FW-ADR-0016, 2026-MM-DD`) so the supersession is searchable from both sides. |
| NB-6 | Air-gap and security-posture questions framed as "open" though customer ruled 2026-05-15 | Lines 199, 446, 688 | Replace open-question framing with ruled-and-scoped framing per `CUSTOMER_NOTES.md` L323 / L348; preserve the forward-looking failure signal at lines 685-688. |
| NB-7 | Three risks not named: (a) downstreams skipping the bridging rc; (b) stub-format v2.0 migration story; (c) runner-calls-back-into-stub temptation | §"Negative / trade-offs accepted" and §"Migration path forward" | One sentence per risk in the relevant section. Each is documentation-shape, not structural. |

None of the seven items requires re-engaging `code-reviewer` after
the amendment. Architect's discretion on whether to amend pre-flip
or defer to a follow-up touch-up.

---

## Net judgment

**APPROVED-WITH-CHANGES (non-blocking).**

The architecture pivot is sound. FW-ADR-0015 correctly identifies the
orchestrator-self-mutation root cause, proposes a model that dissolves
it by construction (rather than relocating it as Option S would have
done), and honours the customer's strategic frame
("upgrade is always buggy" → quality bar maximal) by reducing the
upgrade-flow surface area rather than adding to it. The frozen stub
CLI surface plus sub-100-line budget plus forbidden-list together
constitute a structural lock that future orchestration logic cannot
quietly leak past without tripping the line-budget signal — which
the §"Verification" section correctly names as a hard failure signal
(lines 681-684).

The seven NB items are amendments the architect can apply to tighten
the ADR's documentation without altering its model. None gate the
status flip.

---

## Recommended next steps

1. **Architect flips `status: proposed` → `status: accepted`** with date
   `2026-05-15`. Apply NB-1 through NB-7 either pre-flip (preferred) or
   as a follow-up touch-up commit; either is within architect's
   discretion under "APPROVED-WITH-CHANGES — non-blocking."
2. **Architect proceeds to FW-ADR-0016** (TEMPLATE_STATE.json schema)
   per the ADR's stated sequencing (lines 568-573). FW-ADR-0016 must
   close before FW-ADR-0017 opens; FW-ADR-0018 must close before any
   implementation work begins.
3. **`security-engineer` review of §"Integrity verification posture"**
   (lines 397-440) remains the binding gate on FW-ADR-0015-impl per
   line 436 ("`security-engineer` review is the binding gate on this
   section before the implementation ADR ships"). Customer ruling
   L348 sets the floor at TLS + checksum; security-engineer may
   surface a stronger posture without a fresh foundational ADR per
   line 439-440.
4. **`software-engineer` does NOT begin implementation** until the
   FW-ADR-0015 → 0016 → 0017 → 0018 sequence closes; the ADR's
   §"Implementation notes for software-engineer" (lines 693-733) is
   informational scoping, not an implementation authorisation.
