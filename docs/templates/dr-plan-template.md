# Disaster Recovery Plan — <project name>

Shape per SWEBOK V4 ch. 6 §2.5 "Backup, DR, Failover" (library row
LIB-0002). Owned by `sre`. Referenced from
`docs/operations-plan.md` §6.

## 1. Scope

- Systems covered by this plan.
- Systems explicitly out of scope (note what protects each —
  customer infrastructure, upstream service, shared-responsibility
  boundary).
- Threat classes addressed: infrastructure failure, data corruption,
  regional outage, security incident (ties to the project's security
  assurance artefact for incident-response chain).

## 2. Recovery objectives

| Tier | Systems | RTO (recovery time) | RPO (max data loss window) | Business justification |
|---|---|---|---|---|

RTO and RPO are driven by `CUSTOMER_NOTES.md` — not by industry
defaults. If the customer has not stated them, request via
`tech-lead` before committing the tier.

## 3. Backup strategy

- Cadence (full / incremental / continuous).
- Retention (operational / compliance / archival).
- Storage (on-host / off-host / off-region / off-account / off-cloud).
- Integrity verification (checksum / sample restore / full restore).
- Encryption at rest + in transit.

## 4. Failover procedure

Step-by-step runbook. Who initiates, who executes, who verifies,
who communicates. Include automation entry points (IaC / PaC
references in `release-engineer`'s pipeline).

## 5. Restore / rehearse schedule

Restore rehearsal is not optional. Cadence session-anchored,
run-once (see CLAUDE.md § "Time-based cadences"). Typical minimum:
one full restore rehearsal per quarter; one tabletop per month.

| Type | Cadence | Last exercised | Next due | Owner |
|---|---|---|---|---|

## 6. Incident-response hand-off

- To `sre` for operational recovery.
- To `security-engineer` when the incident is security-related.
- To `tech-lead` for customer communication.
- Post-incident review feeds `docs/pm/LESSONS.md`.

## 7. Post-incident review

- Timeline reconstruction.
- Contributing factors (not blame).
- What worked in this plan; what didn't.
- Changes proposed to this plan, to IaC, to monitoring, to runbooks.
- Cross-reference `docs/pm/CHANGES.md` for any change landing from
  the review.

## 8. References

- SWEBOK V4 ch. 6 §2.5 Backup / DR / Failover (LIB-0002).
- ISO/IEC 27001:2022 §A.5.29–30 (information security continuity).
- ISO 22301:2019 — Business continuity management systems.
- Project-specific: RTO / RPO per `CUSTOMER_NOTES.md`;
  `docs/operations-plan.md`; any `sme-<domain>` notes on domain-
  specific recovery expectations.
