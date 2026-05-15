# Security Assurance — <project or subsystem>

Shape per SWEBOK V4 ch. 13 "Software Security" (library row LIB-0002).
Owned by `security-engineer`. One instance per security-boundary-worth
subsystem, or one project-wide instance for smaller projects.

## 1. Scope and threat model

- **Assets.** What we are protecting; classification.
- **Actors.** Legitimate users, administrators, adversary classes.
- **Threats.** STRIDE / LINDDUN / attack-tree as appropriate.
  Reference the subsystem's ADR if one exists.
- **Trust boundaries.** Network, process, data, user-role.
- **Out-of-scope.** Explicit list; note what defends each out-of-
  scope item (customer environment, upstream service, etc.).

## 2. Security requirements (SWEBOK V4 ch. 13 §4.1 Security Requirements)

Traceable to `docs/requirements.md` rows.

| ID | Requirement | Category (AuthN / AuthZ / Confidentiality / Integrity / Availability / Non-repudiation / Auditability) | Linked req ID |
|---|---|---|---|

## 3. Design patterns applied (SWEBOK V4 ch. 13 §§4.2 Security Design and 4.3 Security Patterns)

Named security patterns used (defense-in-depth, least privilege,
secure-by-default, etc.) and where in the architecture they apply.
Cross-reference ADRs.

## 4. Construction controls (SWEBOK V4 ch. 13 §4.4 Construction for Security)

- Secure coding standards followed.
- Input validation approach.
- Output encoding strategy.
- Secrets management.
- Dependency policy (allowlists, version pinning, update cadence).

## 5. Security testing plan (SWEBOK V4 ch. 13 §4.5 Security Testing)

Ties to `qa-engineer` and the project's test plan.

- Static analysis (SAST) tools and cadence.
- Dynamic analysis (DAST / fuzzing) scope.
- Penetration testing scope and cadence.
- ML-security testing if applicable (adversarial input,
  training-data poisoning, membership inference — SWEBOK V4 ch. 13
  §6.3, ch. 5 §7).

## 6. Vulnerability management (SWEBOK V4 ch. 13 §4.6 Vulnerability Management)

- Advisory-feed sources monitored.
- Triage SLA (CVSS-score-banded response times).
- Patch / upgrade decision process.
- Disclosure / coordinated-disclosure policy.

## 7. SBOM and supply chain

- SBOM generation tool and format (SPDX / CycloneDX).
- Dependency scan integration in the pipeline.
- Supply-chain attack coverage (typosquatting, dependency
  confusion, compromised maintainers, build-tool integrity).

## 8. Assurance case and sign-off

Shape per ISO/IEC 15026-2:2022 "Systems and software assurance —
Assurance case." Not a named sub-section of SWEBOK V4 ch. 13, but
draws the §§4.1–4.6 outputs together for release.

- Claim: the subsystem meets its security requirements.
- Evidence: pointers to test results (§5), review records,
  SBOM (§7), vulnerability status (§6) at release.
- Sign-off: customer approval recorded in `CUSTOMER_NOTES.md` via
  `tech-lead` before a security-sensitive release ships
  (CLAUDE.md Hard Rule #7).

## 9. References

- SWEBOK V4 ch. 13 (library row LIB-0002).
- ISO/IEC 27001:2022 — Information Security Management Systems.
- NIST SP 800-218 Secure Software Development Framework (SSDF).
- OWASP Application Security Verification Standard (ASVS).
- CWE / CAPEC taxonomies.
- Project-specific: relevant ADRs; `CUSTOMER_NOTES.md` entries;
  compliance regime (HIPAA / GDPR / PCI-DSS / etc.) via
  `sme-<domain>` or customer.
