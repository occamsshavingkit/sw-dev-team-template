## Template version

v1.1.1
SHA 2984c6890046c48c577b7cd3ba3b4d344622b526

## Where

- `docs/FIRST_ACTIONS.md` § Steps 0–3a — project setup produces no
  integrity-level declaration
- `docs/workflow-pipeline.md` — trigger-threshold escape hatch
  exists but no project-level formalism dial
- `docs/templates/` — no tailoring template present
- `CLAUDE.md` § "Standard document templates" — no tailoring
  template listed

## What happened

A project doing typical application work with no safety-critical,
regulated, or high-integrity requirements was subject to full
IEEE 1028 review ceremony, ISTQB test-doc requirements, and
ISO 12207 phase-gate artifacts. The `process-auditor` agent flagged
"ceremony without payoff" on every audit pass. No framework
mechanism existed to declare the project's integrity level at setup
and rationally waive inapplicable ceremony. Teams either followed
all ceremony (expensive) or informally skipped steps (undocumented
deviation).

Provenance: surfaced in a Gemini external review of the team design
(2026-06-02), triaged against framework reality by `tech-lead`.
`docs/workflow-pipeline.md` itself acknowledges "heavy ceremony
kills trivial work" without providing a structural remedy.

## Why it is a gap

ISO/IEC/IEEE 12207:2017 §4.6.2 and ISO/IEC 15026-2:2022 both
support tailored conformance by integrity level. PMBOK explicitly
provides for project-specific process tailoring. Applying the same
ceremony floor to a prototype and a safety-critical system violates
the spirit of all three standards. The framework inherits ceremony
from those standards but does not expose their tailoring provisions,
making the choice between "over-engineered" and "undocumented
deviation" unavoidable.

## Suggested fix

Add `docs/templates/pm/tailoring-template.md` covering:
- Project integrity-level declaration (e.g., low / medium / high /
  safety-critical) with selection criteria.
- Per-integrity-level table of which formal processes are followed,
  which are waived, and the rationale for each waiver.
- Sign-off fields for `project-manager`, `architect`, and
  `qa-engineer`.

Wire the template into `docs/FIRST_ACTIONS.md` Step 0 or Step 1 so
every new project produces a `docs/pm/TAILORING.md` before any
development work begins. Cross-reference from
`docs/workflow-pipeline.md` § "Trigger threshold" so the
trigger-threshold escape hatch and the project-level tailoring doc
are used together rather than as alternatives.
