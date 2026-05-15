# Code-reviewer report — FW-ADR-0016 (TEMPLATE_STATE.json schema)

**Artefact:** `docs/adr/fw-adr-0016-template-state-json-schema.md` (~820 lines, status `proposed`)
**Reviewer:** code-reviewer (IEEE 1028 § 5 technical review against FW-ADR-0015 foundation + customer rulings 2026-05-15)
**Date:** 2026-05-15
**Net judgment:** **APPROVED-WITH-CHANGES** — 0 blocking, 9 non-blocking (NB-1 through NB-9)

The schema design is sound. It satisfies the FW-ADR-0015 foundation, honours
all four 2026-05-15 customer rulings (stub, migration path S, air-gap out
of scope, TLS + checksum floor), and dissolves the FW-ADR-0014 Q1 race by
construction. The architect may flip `status: proposed` → `accepted` and
proceed to FW-ADR-0017. NB items are amendments the architect can apply
without re-engaging code-review.

---

## Scope verified

- ADR text read in full (820 lines).
- Foundation ADR re-read: `docs/adr/fw-adr-0015-upgrade-orchestrator-stub-model.md`
  (NB-2 TOFU, NB-4 re-pin path, sub-100-line stub budget, exit codes 10/11/12).
- Inherited contract read: `docs/adr/fw-adr-0002-upgrade-content-verification.md`
  (manifest-primary verification, scaffold-time self-verify, JSONL schema
  stability commitment).
- Partial-supersession target read: `docs/adr/fw-adr-0014-preservation-vs-manifest.md`
  (Q1 retires; Q2 two-phase exit moves into runner unchanged).
- Customer rulings cross-referenced: `CUSTOMER_NOTES.md` L256 (stub), L296 (S),
  L323 (air-gap out of scope), L348 (TLS + checksum). All four properly
  cited in the ADR's Links section.
- Current implementation surveyed: `scripts/lib/manifest.sh` (manifest_ship_files
  already excludes preserve-list paths by construction — the FW-ADR-0014 Q1
  race the new schema retires is real and well-understood).
- Existing fixtures verified: `tests/release-gate/snapshots/v1.0.0-rc12/`
  contains `clean`, `with-customizations`, `with-accepted-local` — the three
  legacy-state shapes the migration function must handle. ADR's reference at
  line 803-806 is accurate.
- Note: `TEMPLATE_MANIFEST.lock` is absent from the template repo root
  (template doesn't manifest itself); the file referenced in the dispatch
  brief is the downstream-project artefact, not a template-repo artefact.
  No correction needed in the ADR.

---

## Walk against review priorities

### Priority 1 — Three-Path Rule conformance

**Finding: sound.** §"Considered options" (lines 137-265) gives all three
options honest pros/cons. Option S (lines 190-225) is not strawmanned —
it is described as the path forward IF the dogfood evidence had argued
differently, and the rejection grounds at lines 210-225 are evidence-based
(the runtime gate's signal-to-noise drop). Option C (lines 227-264) is
likewise treated seriously — its rejection cites the customer's
pin-persistence ruling (L348), not architect preference. The decision
outcome at lines 266-280 cites BOTH structural reasons (single source of
truth) AND the customer ruling, not a circular foreshadow. The Three-Path
Rule is honoured in shape and in substance.

### Priority 2 — Schema completeness vs minimalism

**Finding: sound on top-level fields; minor surfaces flagged.**
Top-level fields `schema_version`, `template`, `runner_pin`, `paths` are
exactly the right four. The `runner_pin` substructure (lines 301-306,
436-446) is correctly minimal — only `target_ref`, `runner_sha256`,
`pinned_at`, `pinned_by`. There is NO `gpg_signature`, NO `cosign_bundle`,
NO `posture_floor` field, NO scaffolding for stronger postures the customer
did not authorize. This matches customer ruling L348 ("TLS and checksum
will be plenty") exactly — the schema does not over-specify against a
future posture that has not been agreed.

- **NB-1:** `pinned_by` enum (lines 442-446) carries two values: `tofu` and
  `explicit`. The set is closed and sufficient for FW-ADR-0015 NB-2 + NB-4.
  However, the ADR does not mark the enum CLOSED in the validator-rejection
  list at lines 418-426. A `pinned_by="manual"` or `pinned_by="ci"` typo
  should be rejected by the schema, not silently accepted as an opaque
  string. Add `pinned_by` outside the {tofu, explicit} set to the rejection
  list.
- **NB-2:** `template.version` is described as "a label" (line 333) while
  `template.ref` is "the identity" (line 333). Acceptable, but the migration
  function (lines 497-499) sources `template.version` from
  `TEMPLATE_VERSION` line 1 and `template.ref` from line 2 — the current
  three-line stamp's semver / SHA / date order. The ADR does not pin which
  format `template.version` must hold (semver? rc tag? branch name?). For
  schema v1.0.0, a free string is fine, but a future MINOR may want to
  validate it. Worth a one-line note that v1.0.0 leaves `template.version`
  unvalidated by intent.

### Priority 3 — Path class enum closed

**Finding: sound; the three values are sufficient AND correctly invalidate
the FW-ADR-0014 Q1 race.** The enum `managed | customised | project-owned`
(lines 379-383) is genuinely a closed three-value set. The key claim — that
two-source-of-truth becomes syntactically impossible (lines 96-100, 623-624)
— holds: a path's row carries `class` and `hash` together; the manifest-
vs-preserve-list disagreement that FW-ADR-0014 Q1 had to arbitrate at
runtime is now structurally precluded by the schema. The ADR's invalidation
of FW-ADR-0014 Q1 at lines 277-280 + 700-712 is correct.

`project-owned` being opt-in in v1.0.0 (lines 393-399) is the right call —
the migration function (line 511) explicitly does NOT synthesise these
rows, keeping the migration deterministic and bounded. The promotion path
to required (line 397-399) is a MINOR bump per the schema-version semantics,
which is correct.

- **NB-3:** The class transition matrix at lines 385-391 documents
  `managed → customised` as a deliberate operator action (deferred to
  FW-ADR-0018) and `customised → managed` as not supported in v1.x.
  Missing: `managed → project-owned` and `customised → project-owned`
  transitions. These will arise when an operator renames or repurposes
  a previously-template-shipped path. The omission is benign for v1.0.0
  (the migration function doesn't synthesise `project-owned`), but
  FW-ADR-0018's transition mechanic should explicitly state whether
  these are supported. Worth a one-line forward-reference.

### Priority 4 — Migration function correctness

**Finding: classification rules are correct; one edge case missing.**

The three classification rules (lines 497-513) are exhaustive over the
declarative inputs:

- Manifest-present, preserve-absent → `managed`. ✓
- Preserve-present (regardless of manifest) → `customised`, with explicit
  conflict-resolution: customised wins on collision (lines 503-508). This
  correctly cements the "customisation overrides manifest" rule that
  `docs/framework-project-boundary.md` already commits to.
- `project-owned` NOT synthesised (line 511) — correct; the migration
  cannot infer intent from a walk of the tree.

Failure modes at lines 524-540 cover three of the four important edge
cases the dispatch brief raised:

- `TEMPLATE_VERSION` missing/malformed: abort, no synthesis (line 525-527).
- `TEMPLATE_MANIFEST.lock` missing: write customised-only rows; let the
  next sync re-bake managed rows (line 528-533). Sound; mirrors
  FW-ADR-0002's pre-v0.14.0 self-heal pattern.
- `.template-customizations` missing: write managed-only rows (line 534-536).
- Path collision: customised wins, no warning (line 538-540).

- **NB-4:** The brief raised "project with corrupted `.template-customizations`"
  as a fourth edge case. The ADR does not explicitly address it. The current
  `.template-customizations` format is line-oriented paths plus `#` comments
  plus blank lines (per the ADR's line 490 description). Corruption shapes:
  paths with embedded whitespace; paths with shell metacharacters; UTF-8
  BOMs; CRLF line endings; entries that are themselves directories not
  files. The migration function shape is silent on whether these are
  tolerated (skip with warn?) or fatal (abort like malformed `TEMPLATE_VERSION`?).
  Pick a posture and pin it. Recommendation: tolerate-with-WARN for
  comment/blank/BOM/CRLF noise; abort for unparseable lines that look
  like paths but aren't. This matters because the migration runs ONCE per
  downstream during the FW-ADR-0018 bridge — failing it loses operator
  trust unrecoverably.

- **NB-5:** Idempotency invariant at lines 515-522 says re-running the
  migration is a no-op if `TEMPLATE_STATE.json` exists. But: what if both
  the new file AND the legacy trio exist AND they disagree? Line 518-520
  defers this to FW-ADR-0018 ("the bridging-rc behaviour"). Reasonable
  scope, but the ADR's idempotency guarantee implicitly depends on
  FW-ADR-0018 cleanly resolving the both-present case. Worth a one-line
  note that idempotency in this ADR's scope is single-input-class; the
  bridging-rc owns the dual-input-class semantics.

### Priority 5 — Schema-version semantics

**Finding: sound, with one ambiguity flagged.** The semver interpretation
at lines 349-373 is correct for a JSON schema:

- Major-newer → reject (line 357-358). ✓ — forward-incompat is fatal.
- Major-older → accept with WARN + migration (line 359-361). ✓ — backward-
  compat via migration function.
- Minor bumps add fields, readers tolerate unknown (line 362-364). ✓ —
  standard JSON-schema additive evolution.
- Patch reserved for docs (line 365-366). ✓ — wire-format-stable.

The MAJOR-reject / MINOR-WARN bounds are stated AND have an enforcement
hook (the validator). The runner carries `SUPPORTED_SCHEMA_MAJOR=1` (line 766)
as the binding constant. This is genuinely enforced at runtime, not just
documentation.

- **NB-6:** Line 365-366 says PATCH bumps are "reserved for documentation
  / clarification changes that do not alter the wire format." This is
  fine but the ADR does not say what readers do with a PATCH mismatch
  (newer or older). Implicitly: accept silently. Worth one explicit
  sentence — readers MUST NOT WARN on PATCH-only differences. Otherwise
  some implementer will read "MAJOR reject, MINOR WARN" and infer "PATCH
  WARN" by analogy.

### Priority 6 — Lifecycle invariants

**Finding: sound; lock scope is correct.** The sync-session step order
(lines 589-602) is binding and well-shaped:

1. Acquire flock (line 591).
2. Read + validate state file (lines 592-593).
3. Perform sync (line 594-595).
4. Compute new state + validate (lines 596-597) — the programmer-error
   guard.
5. Atomic rename (line 598).
6. Phase-B verification (lines 599-600) — FW-ADR-0014 Q2 inherits cleanly.
7. Release flock (line 601).

The lock scope IS the entire sync (acquire at step 1, release at step 7),
not just the write. This is correct — the read-validate-sync-rewrite cycle
must be serialised; two concurrent runners would otherwise read the same
pre-state, sync independently, and the second's rename would clobber the
first's work. The ADR gets this right.

Atomic-write semantics at lines 578-587 are standard `tmp + fsync + rename`
within the same directory for atomic-rename guarantees on POSIX. The crash-
recovery story at lines 583-587 is the correct one: rename atomicity
guarantees the old state survives a mid-write crash; the lockfile +
post-sync verification (FW-ADR-0014 Q2) catches the post-rename, pre-
completion crash. Sound.

Stub's own re-pin invocation (FW-ADR-0015 NB-4 `--refresh-pin`) cooperates
fine: it goes through the runner, which acquires the same flock. The stub
itself never writes the state file (line 568-572: "only the runner writes
`TEMPLATE_STATE.json`"). No race.

### Priority 7 — Runner-pin lifecycle

**Finding: sound, matches customer ruling L348.** The four lifecycle rules
(lines 449-465) implement FW-ADR-0015 NB-2 (TOFU) and NB-4 (re-pin) cleanly:

- First-ever upgrade: pin absent, then recorded with `pinned_by="tofu"`.
- Same target_ref: must match; mismatch → exit 10 (stub-owned, per
  FW-ADR-0015 line 444-450).
- Different target_ref: TOFU applies again, single `runner_pin` overwritten
  in place.
- Operator `--refresh-pin`: written with `pinned_by="explicit"`.

The audit-trail decision (lines 467-474) — current pin only, history via
`git log TEMPLATE_STATE.json` — is acceptable per customer ruling L348
("TLS and checksum will be plenty"). Adding an in-file pin history would
re-introduce the multi-source-of-truth class this whole ADR exists to
retire, which is precisely the rejection ground the ADR cites (line 473-474).
The reasoning is structurally sound and matches the customer's posture.

- **NB-7:** The `--refresh-pin` CLI surface is named in FW-ADR-0015 NB-4
  and re-named here at line 456 ("`scripts/upgrade.sh --refresh-pin <target>`").
  The FW-ADR-0015 stub freeze table (table at line 347 of FW-ADR-0015) does
  NOT include `--refresh-pin`. The current FW-ADR-0015 status review treats
  `--refresh-pin` as a runner-owned flag forwarded by the stub per the
  unknown-flag-forwards rule. That works, but FW-ADR-0016 should explicitly
  state which layer owns `--refresh-pin` semantics: the stub (in which case
  the stub's frozen surface must be amended via foundational-ADR change) or
  the runner (in which case the stub forwards and the runner parses).
  Recommendation: runner-owned, document in FW-ADR-0015-impl /
  FW-ADR-0016-impl as a runner CLI surface, not stub.

### Priority 8 — Schema validation contract

**Finding: shipping the schema file is correct; validator pickup needs one
clarification.** §"Schema validation contract" (lines 542-565) commits to a
machine-readable schema at `docs/schemas/template-state.schema.json` and
makes validation failure a fatal runner error. This is the right call — the
ADR's rejection of "schema-as-prose-only" at lines 564-566 is correctly
grounded: a missing machine validator preserves exactly the silent-drift
failure mode this ADR exists to retire.

Validator pickup order in §"Implementation notes" (lines 747-751) lists
jq → python3 jsonschema → refuse. This is reasonable but has a subtle gap:

- **NB-8:** "jq-based validation if the schema can be expressed" (line 747-748)
  is qualified — jq is not a JSON Schema validator natively. The ADR's
  implementation note authorises a "small validator helper" but does not
  pin whether the helper is bash + jq filter expressions OR an external
  pure-bash JSON-schema implementation OR an embedded jq library. Pinning
  this matters because the runner's JSON-parser dependency footprint is
  the ONE new runtime cost FW-ADR-0015 took on (line 134-135). Suggestion:
  document that schema-version (semver string), enum (path class,
  pinned_by), and length/charset (sha256, sha-1 ref) checks are
  jq-expressible; structural checks (required fields, unique paths) need
  the python3 jsonschema fallback when jq is the only available tool.
  Refusing-when-neither-present is correct but the failure mode message
  needs to name BOTH dependencies, not just one.

### Priority 9 — Backwards-compat read window

**Finding: cutover criterion is clean.** §"Backwards-compat read window"
(lines 604-617) is unambiguous: the transitional rc (FW-ADR-0018) is the
ONLY release that reads both legacy and new layouts. The bridging-rc
synthesises the new file and atomically removes the legacy trio. Post-bridge
runners read only `TEMPLATE_STATE.json`. The §"Implementation notes" at
lines 769-771 reinforces this binding for the runner ("No backwards-compat
read of the legacy trio in the runner. Only the bridging-rc's migration
body reads them.").

The single-rc bridging window is consistent with customer ruling L296
("S" — one transitional rc bridges existing downstreams) and forecloses
the trap of indefinite dual-read maintenance.

### Priority 10 — Hard Rule #8 boundary

**Finding: clean.** The ADR describes a contract and a migration shape;
it does NOT write code. The §"Implementation notes for software-engineer"
section (lines 730-787) explicitly scopes work to SE and reuses existing
primitives (`safe_write`, `flock`) rather than inventing new ones. The
schema file itself (`docs/schemas/template-state.schema.json`) is named
as an SE deliverable, not authored in the ADR (line 561-563: "this ADR
specifies the content (the prose above), not the JSON Schema body").

Hard Rule #8 is honoured. Architect describes the contract; SE implements.

### Priority 11 — Open questions surfaced

**Finding: framed atomically per Hard Rule #11.** The ADR carries no
inline "Open question" section heading, but four implicit deferrals
surface that are correctly atomic when read as queue candidates:

1. v2.0 schema-upgrade semantics (lines 366-371, 656-659) — deferred to
   future FW-ADR-NNNN. One axis: when does v2.0 ship?
2. `project-owned` mode promotion (lines 393-399) — deferred to future
   MINOR. One axis: do we require project-owned rows in v1.x.0?
3. Pin-history surface (lines 467-474) — already-decided (git log only;
   in-file history rejected). Not an open question, a closed one.
4. Lockfile location (line 759-764) — already-decided (`.template-state.lock`
   at project root, gitignored). Not an open question, a closed one.

Items 1 and 2 are correctly framed atomically — each is a single decision
axis. Tech-lead can queue them in `docs/OPEN_QUESTIONS.md` without rewording.

- **NB-9:** Items 3 and 4 read as open in the dispatch brief but are
  actually closed by this ADR. Worth confirming with the architect that
  no follow-up queue entry is needed; the ADR's prose already commits.

---

## Blocking findings

**None.**

The schema is correctly minimal, the path class enum genuinely invalidates
the FW-ADR-0014 Q1 race by construction, the migration function is well-
shaped with correct classification rules, the schema-version semantics are
both stated AND enforced, and the lifecycle invariants (flock scope,
atomic-write, validator-as-gate) are sound. Customer rulings L256 / L296 /
L323 / L348 are all honoured. Hard Rule #8 is respected.

---

## Non-blocking findings (architect may amend without re-CR)

| ID  | Finding | Location | Suggested fix |
|-----|---------|----------|---------------|
| NB-1 | `pinned_by` enum not in validator-rejection list | Lines 418-426 vs 442-446 | Add to rejection list: "A `runner_pin.pinned_by` value outside {`tofu`, `explicit`}." |
| NB-2 | `template.version` format unvalidated in v1.0.0 (acceptable but undocumented) | Lines 333-334 | One sentence: "v1.0.0 leaves `template.version` as a free string by intent; a future MINOR may add format validation." |
| NB-3 | `managed → project-owned` and `customised → project-owned` transitions unspecified | Lines 385-391 | Forward-reference: "Class transitions involving `project-owned` are deferred to FW-ADR-0018's transition mechanic." |
| NB-4 | Corrupted `.template-customizations` not explicitly addressed in migration failure modes | Lines 524-540 | Add a fifth bullet: "Malformed `.template-customizations` entries (embedded whitespace, shell metacharacters, BOM, CRLF): tolerate-with-WARN for comment/blank/BOM/CRLF noise; abort for unparseable lines that look like paths but aren't." |
| NB-5 | Idempotency on dual-input-class (new file + legacy trio both present) deferred to FW-ADR-0018 without explicit note | Lines 515-522 | One sentence: "Idempotency in this ADR's scope is single-input-class. The dual-input-class state (both new file and legacy trio present) is FW-ADR-0018's bridging-rc concern." |
| NB-6 | PATCH-mismatch reader behaviour implicit | Lines 365-366 | Add: "Readers MUST NOT WARN on PATCH-only differences." |
| NB-7 | `--refresh-pin` CLI ownership (stub vs runner) ambiguous | Line 456 | Pin runner-owned in FW-ADR-0016 prose; defer mechanics to FW-ADR-0015-impl / FW-ADR-0016-impl. |
| NB-8 | Validator-helper shape and dependency-absent error message under-specified | Lines 542-565, 747-751 | Document jq-expressible vs jsonschema-required checks; name both dependencies in the refusal message. |
| NB-9 | Confirm pin-history and lockfile-location questions are CLOSED (not queued) | Lines 467-474, 759-764 | Architect confirms with tech-lead that no `docs/OPEN_QUESTIONS.md` queue entries are needed for these two; the ADR's prose commits. |

None of the nine items requires re-engaging code-reviewer after amendment.

---

## Net judgment

**APPROVED-WITH-CHANGES (non-blocking).**

The schema is the right shape: minimal top-level fields, closed path-class
enum, structural invalidation of the FW-ADR-0014 Q1 race, runner-pin
lifecycle matching the customer's TLS-and-checksum security floor, and a
migration function that handles the three legacy-state shapes the fixtures
already represent. The validator-as-gate posture is the right answer to
"how do we prevent silent state drift" — it pins the failure mode this
ADR exists to retire as detectable, not silently tolerated.

The nine NB items are documentation-shape tightening. None alter the
schema, the migration function, or the lifecycle invariants.

---

## Recommended next steps

1. **Architect flips `status: proposed` → `status: accepted`** with date
   `2026-05-15`. Apply NB-1 through NB-9 either pre-flip (preferred) or
   as a follow-up touch-up commit; architect discretion under
   "APPROVED-WITH-CHANGES — non-blocking."
2. **Architect pins the literal status-line wording for FW-ADR-0014** at
   acceptance time (per FW-ADR-0015's NB-5 + this ADR's lines 714-720),
   so the partial-supersession is searchable from the FW-ADR-0014 side.
3. **Architect proceeds to FW-ADR-0017** (file-keyed migration discovery)
   per the ADR's stated sequencing (lines 671-674). FW-ADR-0017 builds
   on `template.ref` + `paths[].source_ref` from this schema.
4. **`security-engineer` review of §"Runner-pin lifecycle"** (lines 428-474)
   per FW-ADR-0015's binding-gate clause. The customer's L348 floor is
   set; security-engineer may surface stronger posture without a fresh
   foundational ADR per FW-ADR-0015 lines 439-440.
5. **`software-engineer` does NOT begin implementation** until the
   FW-ADR-0015 → 0016 → 0017 → 0018 sequence closes. The
   §"Implementation notes for software-engineer" (lines 730-787) is
   informational scoping, not authorisation.
6. **`qa-engineer` consulted** for the success-signal A/B/C/D/E test
   plan (lines 686-716) when implementation work opens.
