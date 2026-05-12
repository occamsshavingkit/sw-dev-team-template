# Resources Register — <project name>

PMBOK 8 Planning / Monitoring artifact (Performance Domain §2.6 —
Resources). Owned by `project-manager`. Tracks human, physical, and
virtual resources across the five processes PMBOK 8 §2.6 names:
Plan Resource Management, Estimate Resources, Acquire Resources,
Lead the Team, Monitor and Control Resourcing.

The roster and team norms live in `docs/pm/TEAM-CHARTER.md` —
this file tracks *allocation, quantity, and contention*.

## 1. Human resources

| Role | Named person / agent | Allocation % by milestone | Skills needed | Skills available | Gap / acquisition plan |
|---|---|---|---|---|---|

Pointer to `docs/pm/TEAM-CHARTER.md` §1 for roster metadata.
Allocation rows here must reconcile with the schedule in
`docs/pm/SCHEDULE.md`.

## 2. Physical resources

| Resource | Quantity needed | Quantity available | Lead time | Source / vendor | Cost (ref `COST.md`) |
|---|---|---|---|---|---|

Hardware (test benches, lab equipment, PLCs for automation projects),
facilities, physical infrastructure. Include acquisition lead time
— long-lead items drive schedule.

## 3. Virtual resources

| Resource | Quota / seats | Current usage | Headroom | Renewal / expiry | Owner |
|---|---|---|---|---|---|

Cloud quotas (compute, storage, egress), SaaS seats, API rate
limits, service-tier caps, domain names, certificates. The
resources downstream projects run out of first, typically with no
warning.

## 4. Estimation method

Reference PMBOK 8 §2.6.2 Estimate Resources. Cite the estimation
technique used for each resource class:

| Resource class | Technique | Notes |
|---|---|---|
| Human | e.g., expert judgment / analogy / parametric / decomposition | |
| Physical | | |
| Virtual | | |

## 5. Acquisition log

Append-only record of resource acquisitions.

| Date | Resource | Requested by | Acquired from | Cost | Ref (`CHANGES.md` row) |
|---|---|---|---|---|---|

## 6. Monitoring and control

- **Utilization review cadence.** Session-anchored, run-once (see
  CLAUDE.md § "Time-based cadences"). Human allocation reviewed
  at milestone close; virtual-resource quotas reviewed in the
  first session of each calendar week for any resource with
  < 30 % headroom.
- **Contention escalation.** Resource contention (two tasks need
  the same resource in overlapping windows, quota approaching
  limit, certificate expiring) surfaces to `tech-lead` who either
  re-prioritizes or relays to the customer.

## 7. References

- `docs/pm/TEAM-CHARTER.md` — team roster, values, norms.
- `docs/pm/SCHEDULE.md` — human allocation over time.
- `docs/pm/COST.md` — cost basis for resources.
- `docs/operations-plan.md` (if present) — overlaps on virtual-
  resource / supplier-management scope.
- PMBOK 8 §2.6 — Resources Performance Domain (library row
  LIB-0001).
