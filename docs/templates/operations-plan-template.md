---
name: operations-plan-template
description: SWEBOK V4 ch. 6 Operations Plan template; SRE-owned with release-engineer contributions.
template_class: operations-plan
---


# Operations Plan — <project name>

Shape per SWEBOK V4 ch. 6 "Software Engineering Operations" (library
row LIB-0002). One document per project deployable to a runtime.
Owned by `sre` (Operations Planning + Control per SWEBOK V4 ch. 6
§§2, 4); `release-engineer` owns Operations Delivery (ch. 6 §3) and
contributes to §§3 and 8 of this document.

## 1. CONOPS (Concept of Operations)

How the system is intended to be used in production. Scope of
operators, usage patterns, critical windows (maintenance, peak
load, regulatory reporting times), acceptable and unacceptable
degradation modes. Two-paragraph prose OK.

## 2. Supplier / vendor management (IaaS / PaaS / SaaS)

| Dependency | Vendor | Tier / SLA | Cost (ref `COST.md`) | Escalation contact | Exit / migration plan |
|---|---|---|---|---|---|

Per PMBOK 8 §X4 Procurement, suppliers feed `project-manager`'s
procurement view. Supplier-sustainability credentials per PMBOK 8
§X4.7 are captured in CHARTER §11.

## 3. Dev and operational environments

IaC / PaC source of truth lives in the repo. List environments
(dev / staging / prod, plus any customer-specific), what spins each
up, what tears it down, and the drift-detection cadence.

## 4. Availability / continuity / SLAs

- Target availability per tier.
- Error-budget policy (link to SLO doc if separate).
- Planned-maintenance windows.
- Communication plan for unplanned outages.

## 5. Capacity management

Observed-growth-based, not guessed. Ties to `docs/pm/RESOURCES.md`
virtual-resource rows and to forecast in `docs/pm/SCHEDULE.md`.

## 6. Backup / DR / failover

Pointer to `docs/dr-plan.md` (from `docs/templates/dr-plan-template.md`).

## 7. Data safety / security / integrity

Pointer to the security assurance artefact under
`docs/security/` (from `docs/templates/security-template.md`).
Operations-side concerns: backup integrity checks, access-log
retention, audit-trail preservation.

## 8. DevSecOps touchpoints

Three-way handshake between `sre`, `release-engineer`, and
`security-engineer`. Security controls in the pipeline (SAST /
DAST / SBOM / vuln scans), runtime security observability, incident
response chain.

## 9. References

- SWEBOK V4 ch. 6 "Software Engineering Operations" (LIB-0002).
- ISO/IEC/IEEE 20000-1:2018 — Service management system
  requirements.
- ISO/IEC/IEEE 12207:2017 — System life cycle processes.
- ISO/IEC/IEEE 32675:2022 — DevOps: building reliable and secure
  systems.
- Project-specific: `docs/pm/RESOURCES.md`, `docs/dr-plan.md`,
  `docs/security/*`.
