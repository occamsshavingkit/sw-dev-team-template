---
name: security-template
description: ISO/IEC 15026-2:2022 assurance-case-shaped security assessment template, grounded in SWEBOK V4 ch. 13 §§4.1-4.6, for per-artefact or per-release Hard Rule #7 sign-off.
template_class: security-assurance
---


# Security Assurance Assessment — <artefact / subsystem / release>

<!-- TOC -->

- [1. Identification](#1-identification)
- [2. Scope and method](#2-scope-and-method)
- [3. Threat model](#3-threat-model)
- [4. Assurance claim](#4-assurance-claim)
- [5. Argument and evidence](#5-argument-and-evidence)
  - [5.1 Security requirements](#51-security-requirements)
  - [5.2 Security design](#52-security-design)
  - [5.3 Security patterns](#53-security-patterns)
  - [5.4 Construction for security](#54-construction-for-security)
  - [5.5 Security testing](#55-security-testing)
  - [5.6 Vulnerability management](#56-vulnerability-management)
- [6. SBOM and supply chain](#6-sbom-and-supply-chain)
- [7. Findings register](#7-findings-register)
- [8. Residual risk](#8-residual-risk)
- [9. Unverified assumptions](#9-unverified-assumptions)
- [10. Security-boundary vs. discipline-control determination](#10-security-boundary-vs-discipline-control-determination)
- [11. Sign-off decision](#11-sign-off-decision)
- [12. Record of sign-off](#12-record-of-sign-off)
- [13. References](#13-references)

<!-- /TOC -->

Shaped as an assurance case per ISO/IEC 15026-2:2022 ("Systems and
software assurance — Assurance case"), paraphrased: a top-level
**claim** about the artefact's security posture, an **argument**
connecting **evidence** to that claim, and the **assumptions** and
**residual risk** that bound how far the argument can be trusted. The
evidence-gathering activities in § 5 map one-to-one onto SWEBOK V4
ch. 13 "Software Security" §§4.1–4.6 (library row LIB-0002) — each
subsection below carries its source § number in its heading so the
mapping CLAUDE.md Hard Rule #7 cites is traceable at a glance.

Owned by `security-engineer`. One instance per security-boundary-worth
subsystem, per artefact under Hard Rule #7 review, or one project-wide
instance for smaller projects. This is the artefact CLAUDE.md Hard
Rule #7 requires a sign-off to reference.

**Where filled instances live.** `docs/security/<subject>-assessment.md`,
one file per assessed artefact or release. That directory does not
exist in a fresh scaffold checkout — the first filled instance creates
it. `<subject>` is a short, stable, kebab-case token for the artefact
(e.g., `opencode-hook-bridge`); reuse the same token across successive
assessments of the same artefact so findings can be cross-referenced.

Terms are binding per `docs/glossary/ENGINEERING.md` and
`docs/glossary/PROJECT.md`. Content is paraphrased per project IP
policy; no verbatim standard text appears in this file (CLAUDE.md
Hard Rule #5).

---

## 1. Identification

<!-- Author-guidance: this section anchors the whole assessment to a
     reproducible point in time. An assessment with a vague "as of
     the current branch" identification cannot be re-verified later
     and cannot support a defensible sign-off. -->

- **Artefact / subsystem / release assessed:** <name and one-line description>
- **Version / commit / tag assessed:** <git SHA or release tag — exact, not "latest">
- **Repository and path(s) in scope:** <repo, top-level paths>
- **Assessor:** `security-engineer` (named session/agent if relevant)
- **Date of assessment:** YYYY-MM-DD
- **Trigger:** <the Hard Rule #7 category that required this
  assessment — authentication / authorization / secrets / PII /
  network-exposed endpoint — and the task or ADR that introduced it>
- **Supersedes:** <prior assessment file, if this is a re-assessment
  of the same artefact after remediation, or "none">

---

## 2. Scope and method

<!-- Author-guidance: state plainly what was reviewed, what was
     deliberately excluded, and how the review was performed. A
     static-only review and a review that included runtime testing
     support different strength of claim in § 4 — do not let § 4 imply
     more confidence than § 2 supports. This distinction has caught
     real bugs before: a static-only review of the OpenCode hook
     bridge could not observe actual process privilege at runtime, and
     naming that gap in § 9 is what led to the runtime spike that
     found a real privilege-escalation defect. Do not skip this
     lesson by leaving the method vague. -->

**In scope.** <files, components, interfaces, trust boundaries examined>

**Out of scope.** <what was deliberately not reviewed, and why —
"out of scope because reviewed by a separate assessment", "out of
scope because upstream/vendor-owned", "out of scope: no time in this
pass" are all acceptable if stated, not omitted>

**Method.** One or both of:
- **Static review** — reading code, configuration, IaC, and
  documentation without executing the artefact. State the tools used
  (linters, SAST) if any.
- **Runtime testing** — exercising the artefact under representative
  or adversarial conditions and observing actual behavior (process
  privilege, network calls, data written, error handling).

If the assessment is **static-only**, state explicitly what that
method cannot verify (actual runtime privilege, actual data flow
under load, timing-dependent behavior, environment-inheritance
effects) and carry those gaps forward into § 9 Unverified assumptions.
Do not let § 4's claim imply runtime confidence that only a static
review does not support.

---

## 3. Threat model

<!-- Author-guidance: this is the foundation the rest of the
     assessment reasons from — do the threat model before writing the
     claim in § 4. Threat modelling is not a scope restatement; it is
     the exercise of asking, for each asset and trust boundary, who
     could act against it and from what position. A worked example:
     during the OpenCode hook-bridge assessment, the assessment's most
     valuable findings came from asking who could influence a
     trust-sensitive field passed into the bridge (the hook's declared
     agent type) and from what position in the system — that question,
     not a restatement of what files were in scope, is what surfaced a
     real privilege-escalation risk. Do the same kind of reasoning
     here: for every trust boundary named below, ask who sits on each
     side of it and what they could do if the boundary did not hold. -->

**Assets.** What is being protected by this artefact, and its
classification (public / internal / confidential / regulated, per
project data-classification policy if one exists).

**Actors.** Legitimate users, administrators/operators, and adversary
classes relevant to this artefact (e.g., unauthenticated network
caller, authenticated-but-untrusted caller, compromised dependency,
compromised upstream component, insider).

**Trust boundaries.** Every point where data or control crosses from
one trust level to another — network boundary, process boundary, data
boundary, user-role boundary. For each boundary, name what enforces
it (see § 10 for whether that enforcement is a hard boundary or a
discipline control).

**Threats.** Enumerate threats per trust boundary using a structured
method appropriate to the artefact — STRIDE, LINDDUN, or an
attack-tree are all acceptable; name which one was used. Reference the
artefact's governing ADR if one exists.

**Compensating controls for out-of-scope items.** For each item
excluded in § 2's "Out of scope", state what defends it even though
this assessment did not review it directly (customer environment,
upstream service's own security posture, a separate assessment, etc.).
An out-of-scope item with no stated compensating control is an
unstated risk, not a resolved one.

---

## 4. Assurance claim

<!-- Author-guidance: one sentence, third person, falsifiable. Not
     "the system is secure" — state the specific property being
     claimed, scoped to what § 2 actually covered. Example shape:
     "Static review of <artefact> at <commit> found no violation of
     <specific security requirement(s)> within the stated scope;
     this claim does not extend to runtime behavior, which was not
     exercised (see § 9)." -->

**Claim.** <one sentence — the specific security property being
asserted, scoped to § 2's method and § 3's threat model>

---

## 5. Argument and evidence

The evidence supporting or undermining § 4's claim, organized by the
SWEBOK V4 ch. 13 §§4.1–4.6 activities that generated it. Each
subsection states what was found, not just what was checked — an
empty subsection with no findings is a claim in itself and should say
so explicitly ("no gaps found in this pass") rather than being left
blank. Findings surfaced by any subsection get an ID and move into
§ 7; do not leave findings embedded only in prose here.

### 5.1 Security requirements

<!-- SWEBOK V4 ch. 13 §4.1 Security Requirements, paraphrased. -->

Traceable to `docs/requirements.md` `NFR-COMP-NNNN` / security-tagged
rows, where they exist. If no formal security requirement was written
for this artefact, state that and treat this section as a gap.

| ID | Requirement | Category (AuthN / AuthZ / Confidentiality / Integrity / Availability / Non-repudiation / Auditability) | Linked req ID | Status |
|---|---|---|---|---|

### 5.2 Security design

<!-- SWEBOK V4 ch. 13 §4.2 Security Design, paraphrased. -->

How the threats named in § 3 are designed against — the structural
choices (isolation, validation boundaries, fail-closed defaults,
privilege separation) rather than named patterns (those go in § 5.3)
or line-level controls (§ 5.4). Cross-reference the governing ADR(s).

### 5.3 Security patterns

<!-- SWEBOK V4 ch. 13 §4.3 Security Patterns, paraphrased. -->

Named, reusable security patterns applied (defense-in-depth, least
privilege, secure-by-default, fail-closed, complete mediation, etc.)
and where in the architecture each one applies.

### 5.4 Construction for security

<!-- SWEBOK V4 ch. 13 §4.4 Construction for Security, paraphrased. -->

- Secure coding standards followed.
- Input validation approach.
- Output encoding strategy.
- Secrets management.
- Dependency policy (allowlists, version pinning, update cadence).

### 5.5 Security testing

<!-- SWEBOK V4 ch. 13 §4.5 Security Testing, paraphrased. -->

Ties to `qa-engineer` and the project's test plan. State what was
actually run for *this* assessment, not the project's general
testing capability.

- Static analysis (SAST) — tool, cadence, and what this run found.
- Dynamic analysis (DAST / fuzzing) — scope and what this run found.
- Penetration testing — scope and cadence, if performed.
- ML-security testing, if applicable (adversarial input,
  training-data poisoning, membership inference).

### 5.6 Vulnerability management

<!-- SWEBOK V4 ch. 13 §4.6 Vulnerability Management, paraphrased. -->

- Advisory-feed sources monitored.
- Triage SLA (severity-banded response times).
- Patch / upgrade decision process.
- Disclosure / coordinated-disclosure policy.

SBOM and broader supply-chain exposure are a distinct, first-class
concern — see § 6, not folded in here.

---

## 6. SBOM and supply chain

<!-- Author-guidance: this is deliberately its own section, not a
     bullet inside § 5.6. SBOM generation and supply-chain exposure
     are an explicit `security-engineer` responsibility and need a
     directly answerable "did we do this" surface, not a passing
     mention buried in vulnerability management. -->

- **SBOM.** Generation tool and format (SPDX / CycloneDX) for this
  artefact, if produced; where the generated SBOM is stored or
  published.
- **Dependency scanning.** Integration point in the build/deploy
  pipeline; what triggers a scan; what blocks a release.
- **Supply-chain exposure considered.** Typosquatting, dependency
  confusion, compromised maintainers, compromised or tampered build
  tooling. State which of these were explicitly considered for this
  artefact and which were not.

---

## 7. Findings register

<!-- Author-guidance: every finding gets a stable ID so it can be
     tracked to closure across commits and across re-assessments of
     the same artefact. Choose a short subject token once per artefact
     (e.g., the `<subject>` from the filename) and prefix every finding
     ID with it: `SEC-<TOKEN>-NNNN`. Never reuse a number, even after
     closure. A finding that recurs after being marked Closed gets a
     new ID that references the old one — do not reopen. Severity
     scale is project-defined; record which scale is in use (a
     CVSS-based band is common practice) rather than assuming the
     reader knows it. -->

**Severity scale in use:** <name the scale, e.g. "CVSS v3.1 base score
bands: Critical ≥9.0, High 7.0–8.9, Medium 4.0–6.9, Low 0.1–3.9,
Informational — no exploitability">

| ID | Severity | Description | Location (file/component) | Status | Owner | Target closure |
|---|---|---|---|---|---|---|
| SEC-\<TOKEN\>-0001 | <Critical/High/Medium/Low/Informational> | <one line> | <path or interface> | Open / In progress / Closed | <agent> | <commit, date, or "next release"> |

A finding with no owner or no target closure is not yet actionable —
resolve those two fields before this section is considered complete.

---

## 8. Residual risk

<!-- Author-guidance: risk that remains *even if every finding above
     is closed* — inherent exposure the design or the environment
     accepts rather than eliminates. Distinct from § 7: findings are
     defects to fix; residual risk is exposure the team knowingly
     carries. Every row needs an explicit acceptance — silence is not
     acceptance. -->

| ID | Description | Likelihood | Impact | Accepted by | Mitigation (if partial) |
|---|---|---|---|---|---|
| RR-\<TOKEN\>-0001 | <e.g., a compromised upstream dependency could still reach this path via X> | L/M/H | L/M/H | <customer via `tech-lead`, per Hard Rule #4/#7, recorded in `CUSTOMER_NOTES.md`> | <partial control, or "none"> |

---

## 9. Unverified assumptions

<!-- Author-guidance: this is the section most likely to matter later.
     Name every trust assumption this assessment relied on but could
     not independently confirm within its stated § 2 method and scope
     — especially assumptions about *runtime* behavior when the method
     was static-only. A named unverified assumption is a legitimate,
     honest assessment output; a silently-assumed one is a latent gap
     that surfaces as an incident. If an assumption is load-bearing
     for § 4's claim, say so and recommend the follow-up (e.g., a
     runtime spike, a `sre` load test, an external audit) that would
     verify it. -->

| ID | Assumption | Why it could not be verified in this pass | Consequence if false | Recommended follow-up |
|---|---|---|---|---|
| UA-\<TOKEN\>-0001 | <e.g., the bridge process drops the privilege it claims to drop before executing untrusted input> | <e.g., static review only; no runtime observation of process privilege> | <e.g., privilege escalation via untrusted hook input> | <e.g., runtime spike under `sre`/`software-engineer`> |

---

## 10. Security-boundary vs. discipline-control determination

<!-- Author-guidance: this is a forced, single, plain-language call —
     do not hedge it into ambiguity. A "security boundary" is enforced
     by a mechanism that holds even against a compromised or malicious
     component on the other side of it (process isolation, cryptographic
     verification, OS-level permission enforcement). A "discipline
     control" relies on convention, code review, configuration
     correctness, or good-faith cooperation of the components involved
     — it stops mistakes, not a determined adversary or a compromised
     dependency. Overclaiming a discipline control as a security
     boundary is the failure mode this section exists to prevent: a
     clean-sounding sign-off that overstates what was actually
     verified is worse than an honest "discipline control, not a hard
     boundary" determination, because it misleads whoever relies on it
     next. -->

**Determination:** ☐ Security boundary &nbsp;&nbsp; ☐ Discipline
control &nbsp;&nbsp; ☐ Mixed (state which parts are which)

**Rationale.** <one paragraph: what mechanism, if any, would hold even
if the component on the other side were compromised or malicious? If
the answer is "none — it depends on the code doing what it says",
this is a discipline control, and that should be stated without
softening.>

---

## 11. Sign-off decision

<!-- Author-guidance: use exactly one of the three values below —
     no other wording. "SIGN-OFF WITH CONDITIONS" requires every
     condition to be a specific, trackable ID from § 7, § 8, or § 9
     (not a vague "monitor this"). "WITHHOLD" is a valid and expected
     outcome, not a failure of the assessment. -->

**Decision:** SIGN-OFF | SIGN-OFF WITH CONDITIONS | WITHHOLD

**Assessor:** `security-engineer`
**Date:** YYYY-MM-DD

**Conditions (if SIGN-OFF WITH CONDITIONS):**

| Condition | Linked ID (§7/§8/§9) | Must be resolved by |
|---|---|---|
| <e.g., close finding before next release touching this path> | SEC-\<TOKEN\>-0001 | <release / date> |

**Reason for WITHHOLD (if applicable):** <what would need to change to
move to SIGN-OFF or SIGN-OFF WITH CONDITIONS>

---

## 12. Record of sign-off

Per CLAUDE.md Hard Rule #7, this sign-off does not take effect until
it is recorded in `CUSTOMER_NOTES.md`, alongside the customer approval
required by Hard Rule #4. `librarian` writes the `CUSTOMER_NOTES.md`
entry; `tech-lead` obtains and relays the customer approval. The
`CUSTOMER_NOTES.md` entry references this file's path and § 11's
decision verbatim (SIGN-OFF / SIGN-OFF WITH CONDITIONS / WITHHOLD).

- **`CUSTOMER_NOTES.md` entry date:** YYYY-MM-DD
- **This assessment file:** `docs/security/<subject>-assessment.md`

---

## 13. References

- SWEBOK V4 ch. 13 "Software Security" (library row LIB-0002),
  §§4.1–4.6.
- ISO/IEC 15026-2:2022 — Systems and software assurance — Assurance
  case.
- ISO/IEC 27001:2022 — Information Security Management Systems.
- NIST SP 800-218 Secure Software Development Framework (SSDF).
- OWASP Application Security Verification Standard (ASVS).
- CWE / CAPEC taxonomies.
- Project-specific: relevant ADRs; `CUSTOMER_NOTES.md` entries;
  compliance regime (HIPAA / GDPR / PCI-DSS / etc.) via
  `sme-<domain>` or customer.
