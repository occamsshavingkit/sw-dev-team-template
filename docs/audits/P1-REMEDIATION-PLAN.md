# P1 Remediation Plan — SWEBOK V4 + PMBOK 8 Audit Pass-2

**Date:** 2026-04-23
**Author:** project-manager (with architect consulted on items 1 + 2)
**Status:** RECOMMENDATION — no files have been edited. Customer
reviews this document and selects which items to dispatch, in what
order, and with what variants. Only after customer sign-off does
`tech-lead` dispatch `architect` / `tech-writer` / `researcher` to
land the changes.

**Inputs.**
- `/home/quackdcs/SWEProj/docs/audits/swebok-v4-gap-analysis-pass2.md`
- `/home/quackdcs/SWEProj/docs/audits/pmbok-8-gap-analysis-pass2.md`

---

## §0 Summary

### P1 count

**Eight P1 items** total:

| # | Item | Audit source | Scope |
|---|---|---|---|
| 1 | Software Security ownership + artefacts | SWEBOK §2.1, §4 | Template (roster) |
| 2 | Software Engineering Operations ownership + artefacts | SWEBOK §2.2, §4 | Template (roster + new template) |
| 3 | Sustainability integration (principle #5) | PMBOK §2.1, §3.1, §3.7 | Template (templates + PM agent) |
| 4 | Team Charter template | PMBOK §2.2, §2.4, §3.8 | Template (new file) |
| 5 | Resources template + Resources performance domain coverage | PMBOK §2.2, §3.8, §4.1 | Template (new file + PM agent) |
| 6 | AI Use Policy template (Appendix X3) | PMBOK §2.3, §3.8, §4.2 | Template (new file) |
| 7 | "NO AI TRAINING" clause citation in IP policy | PMBOK §2.4, §4.3 | Template (CLAUDE.md) |
| 8 | Researcher cite-hygiene for PMI materials | PMBOK §2.4, §4.3 | Template (researcher agent) |

### Effort roll-up

| Size | Items | Hours |
|---|---|---|
| S (<1h) | 7, 8 | 1.5 |
| M (1–3h) | 3, 4, 6 | 6 |
| L (>3h) | 1, 2, 5 | 10 |

**Total: ~17h of editorial + review work** across
`architect` / `tech-writer` / `researcher` / `project-manager`. Not all
on one agent; parallelisable across 3–4 sessions.

### Template-level vs project-level

**All eight P1 items are template-level (upstream).** They modify the
`sw-dev-team-template` itself so that every future scaffolded project
inherits the fixes. Downstream projects already scaffolded pick them
up via `scripts/upgrade.sh` once the next template version is cut.

No P1 item is project-scoped to this specific project's charter.

### Proposed sequencing

1. **Customer decisions first** (items 1, 2, 5 have role-ownership
   decisions that gate the editorial work). See §Final open questions.
2. **Items 7, 8 ship first** — smallest, lowest-risk, unblock cite
   hygiene immediately.
3. **Items 3, 4, 6** — PMBOK template additions. Can be done in
   parallel once customer has decided on item 4's scope.
4. **Item 5** — depends on item 4 (Resources template refers to Team
   Charter).
5. **Items 1, 2** — depend on customer's role-ownership decision; item
   2 depends on whether item 1 creates a security agent (DevSecOps
   ownership split).
6. **Version bump + migration** — cut new `TEMPLATE_VERSION`, write
   `migrations/<new-version>.sh` if any shape changes; publish.

Dependency graph:

```
   [Q1: security agent?]---\
   [Q2: ops owner split?]---\
   [Q3: team charter scope?]-\
                              \
   7,8 ----> 3,6 ----> 4 ----> 5 ----> 1 ----> 2 ----> release
```

---

## §1 P1-1: Software Security — new binding + artefact class

### Gap
SWEBOK V4 ch. 13 is a first-class Knowledge Area (six sections incl.
DevSecOps, SDL, vulnerability management, SBOM, threat modelling). No
agent in the roster owns it; `architect.md` mentions security only as
one of many cross-cutting concerns. (SWEBOK audit §2.1, §4 item 1.)

### Decision needed from customer
**Q1.** Which ownership model does the customer prefer?
- **(a) New standing agent `security-engineer.md`** — added to the
  fixed roster alongside `sre`, `release-engineer`, etc. Best fit for
  projects that routinely handle auth, PII, or network-exposed
  endpoints. Higher template surface, more routing rules to maintain.
- **(b) Per-project SME scaffold** — add `sme-security.md` template
  pattern; `tech-lead` instantiates it only on projects where security
  is in scope. Lower baseline cost; risk that projects that should
  have security review skip it.
- **(c) Split responsibility across existing agents** — `architect`
  owns threat modelling; `code-reviewer` owns security review;
  `release-engineer` owns SBOM/vuln-mgmt; `sre` owns runtime security.
  No new agent. Cheapest, but diffuses accountability; SWEBOK V4
  ch. 13 explicitly treats security as a standalone discipline.

**Architect recommendation** (folded in): **(a) new standing agent**.
Rationale: SWEBOK V4 ch. 13's scope (threat model, SDL, assurance
case, SBOM, DevSecOps, ML-security) does not map cleanly onto any one
existing agent; distributing it across four agents creates the
ownership vacuum the audit already flagged. The template serves
multi-project reuse — even projects where security is thin benefit
from the `security-engineer` agent being on the bench and idle rather
than missing.

**Secondary decision if (a):** role name —
`security-engineer` (SWEBOK-aligned) vs `security-architect` vs
`appsec-engineer` (industry-common). Recommend `security-engineer`
for consistency with `software-engineer` / `release-engineer` naming.

### Proposed changes (assuming (a))

| File | Action | Summary |
|---|---|---|
| `.claude/agents/security-engineer.md` | **new** | See outline below. |
| `.claude/agents/architect.md` | insert | After line 16, add: "Security architecture review is owned by `security-engineer`; escalate structural security concerns there before making decisions that pre-empt them." |
| `.claude/agents/code-reviewer.md` | insert | Add hand-off: any change touching auth/authz/secrets/PII/network-exposed surface requires `security-engineer` review in addition to code review. |
| `.claude/agents/release-engineer.md` | insert | Add: SBOM generation + vuln-feed response coordinated with `security-engineer`. |
| `.claude/agents/qa-engineer.md` | insert | Reference ML-testing sub-topic per SWEBOK V4 ch. 5 §7 (ties in SWEBOK P3 item §2.5; optional here). |
| `.claude/agents/tech-lead.md` | insert | Routing table entry: security questions → `security-engineer` (not customer). |
| `CLAUDE.md` | insert | New hard rule: "No release touching authentication, authorization, secrets, PII, or network-exposed endpoints ships without `security-engineer` sign-off recorded in `CUSTOMER_NOTES.md`." (per audit §2.1 recommendation). |
| `CLAUDE.md` agent roster table (~line 225) | insert row | `security-engineer.md` — Security Engineer — SWEBOK V4 ch. 13 / taxonomy §TBD. |
| `SW_DEV_ROLE_TAXONOMY.md` | insert section | New §2.Xa "Security Engineer" with canonical definition, sub-responsibilities, heat-map row, source citation. |
| `docs/templates/security-template.md` | **new** | Threat model + security requirements + assurance case; shape from SWEBOK V4 ch. 13 §§3–4. |
| `docs/glossary/ENGINEERING.md` | insert | Bind ISO/IEC 27001:2022 as ISMS reference (audit §2.9 follow-on). |

#### Outline — `.claude/agents/security-engineer.md`

```
---
name: security-engineer
description: <SWEBOK V4 ch. 13 owner; not customer interface>
tools: Read, Grep, Glob
model: inherit
---

Security Engineer. Canonical role §TBD. SWEBOK V4 KA "Software Security" (ch. 13).

## Job
- Threat modelling (design-review time)
- Security requirements review (against Software Requirements KA)
- SDL coordination + DevSecOps touchpoints
- Vulnerability management policy + SBOM stewardship
- Security assurance case / equivalent before release
- Advisory-feed monitoring + response

## Constraints
- No production code; flag to `code-reviewer`.
- Customer-domain compliance (HIPAA / GDPR / PCI-DSS specifics) → `sme-<domain>` or customer via tech-lead.

## Interfaces
- `architect` — structural security decisions
- `code-reviewer` — security review of changes
- `release-engineer` — SBOM, vuln-mgmt, release gating
- `sre` — runtime security, incident response
- `qa-engineer` — security test plan
- `researcher` — standards (ISO 27001, OWASP, NIST) lookup

## Binding references
- SWEBOK V4 ch. 13 (primary)
- ISO/IEC 27001:2022 ISMS
- IEEE CS/ACM SE Code of Ethics (for responsible-disclosure conduct)

## Escalation format / Output format — standard project pattern.
```

#### Outline — `docs/templates/security-template.md`

```
# Security Assurance — <project>
## 1. Scope and threat model
## 2. Security requirements (mapped to SWEBOK V4 ch. 13 §4.1)
## 3. Design patterns applied (§4.2)
## 4. Construction controls (§4.3)
## 5. Security testing plan (§4.4; ties to qa-engineer)
## 6. Vulnerability management (§4.5)
## 7. SBOM + supply-chain
## 8. Assurance case / sign-off
## 9. References (ISO 27001, OWASP ASVS, NIST SSDF, etc.)
```

### Dependencies / sequencing
- Depends on customer answer to Q1.
- Unblocks first security-sensitive downstream project; no other P1
  depends on this.
- Must land before item 2 if DevSecOps ownership is split between ops
  and security.

### Effort
**L** — ~4h. New agent (1h), new template (1h), cross-agent edits
(1h), taxonomy entry + CLAUDE.md + hard rule (1h).

### Risk of not doing it
First security-sensitive project that uses this template ships without
threat model, SBOM, or vuln-mgmt policy. SWEBOK V4 treats this as
baseline; customers who audit their supplier against V4 will flag it.
Liability exposure on the ethics side (V4 ch. 14 §1.7.6 Professional
Liability) if a vulnerability ships that a named owner would have
caught.

---

## §2 P1-2: Software Engineering Operations — CONOPS / DR / supplier / IaC / PaC

### Gap
SWEBOK V4 ch. 6 names operations as a KA with three process groups
(Planning / Delivery / Control) producing deliverables currently
unowned: CONOPS, Operations Plan, capacity plan, DR plan, supplier
management, IaC/PaC artefacts. Today these are split implicitly
between `sre` and `release-engineer` with no template. (SWEBOK
audit §2.2, §4 item 2.)

### Decision needed from customer
**Q2.** How to split ownership of the three V4 process groups?
- **(a) SRE owns Planning + Control; release-engineer owns Delivery**
  — clean V4 mapping; matches the §2.2 recommendation in the audit.
  Requires widening both agents and a routing rule.
- **(b) Collapse into one `ops-engineer` role** — single owner of
  ch. 6 in full. Simpler routing; conflicts with existing split and
  with SFIA conventions.
- **(c) Keep current split, add CONOPS/DR/capacity as shared
  deliverables** — lowest disruption; leaves ownership ambiguous on
  shared items.

**Architect recommendation:** **(a)**. V4 explicitly distinguishes
Platform Engineering (self-service) from SRE (monitoring / capacity /
incident) inside the KA; our `sre` already covers SRE-side, our
`release-engineer` already covers deployment/release. The missing
artefacts (CONOPS / capacity plan / DR plan) land naturally on SRE;
IaC/PaC and rollback automation land naturally on release-engineer.
DevSecOps is a three-way handshake with `security-engineer` (item 1).

### Proposed changes (assuming (a))

| File | Action | Summary |
|---|---|---|
| `.claude/agents/sre.md` | insert | Add SWEBOK V4 ch. 6 primary-anchor citation (currently taxonomy-only, line 8). Add Responsibilities: CONOPS, Operations Plan, capacity plan, DR/failover plan, supplier mgmt for IaaS/PaaS. |
| `.claude/agents/release-engineer.md` | insert | Add SWEBOK V4 ch. 6 §3 primary-anchor citation. Add: IaC + PaC as explicit deliverables; rollback automation; Operations-Delivery group ownership. |
| `.claude/agents/architect.md` | insert | Reference: operations trade-offs (capacity / DR / failover) arbitrated by `architect` when they cross cost/schedule thresholds. |
| `CLAUDE.md` routing section | insert | Routing rule: SRE owns Operations Planning + Control; Release-Engineer owns Operations Delivery; conflicts → architect. DevSecOps ownership shared (SRE + release-engineer + security-engineer). |
| `docs/templates/operations-plan-template.md` | **new** | Shape per V4 ch. 6 §2. See outline below. |
| `docs/templates/dr-plan-template.md` | **new** | Shape per V4 ch. 6 §2.5 (Backup/DR/Failover). See outline below. |
| `SW_DEV_ROLE_TAXONOMY.md` §2.3, §2.8 | insert | Add V4 ch. 6 citation alongside existing taxonomy IDs; note 3-process-group split. |

#### Outline — `operations-plan-template.md`

```
# Operations Plan — <project>
## 1. CONOPS (Concept of Operations)
## 2. Supplier / vendor management (IaaS/PaaS/SaaS deps)
## 3. Dev and operational environments (IaC / PaC source of truth)
## 4. Availability / continuity / SLAs
## 5. Capacity management
## 6. Backup / DR / failover (pointer to `dr-plan.md`)
## 7. Data safety / security / integrity (pointer to security assurance)
## 8. DevSecOps touchpoints (pointer to security-engineer)
## 9. References (ISO/IEC/IEEE 20000-1, 12207:2017, 32675:2022)
```

#### Outline — `dr-plan-template.md`

```
# Disaster Recovery Plan — <project>
## 1. Scope (systems covered, systems explicitly out of scope)
## 2. Recovery objectives (RTO, RPO per tier)
## 3. Backup strategy (cadence, retention, storage, testing)
## 4. Failover procedure
## 5. Restore/rehearse schedule
## 6. Incident-response hand-off (to sre / security-engineer)
## 7. Post-incident review + lessons-learned feedback
```

### Dependencies / sequencing
- Depends on Q2.
- Depends partially on item 1 (if `security-engineer` exists, DevSecOps
  split is clean three-way; otherwise the template must say "security
  owned by architect + code-reviewer + sre" which is the audit's
  current-state gap).
- Must land before any downstream project that runs services
  (i.e., essentially all of them).

### Effort
**L** — ~4h. Agent widening + cross-refs (1.5h), two new templates
(1.5h), routing rules in CLAUDE.md (0.5h), taxonomy updates (0.5h).

### Risk of not doing it
Downstream projects ship to production without CONOPS, capacity plan,
or DR plan. Typical first-incident outcome: unclear who was supposed
to have the runbook. SWEBOK V4 ch. 6 is the standard an auditor will
cite.

---

## §3 P1-3: Sustainability integration (PMBOK Principle #5)

### Gap
PMBOK 8 Principle #5 "Integrate Sustainability Within All Project
Areas" (§3.7, pp. 48–52) is a first-class, cross-domain principle.
Currently: no CHARTER section, no RISKS category, no LESSONS category,
no PM-agent responsibility mention. (PMBOK audit §2.1, §4.1, §4.2.)

### Decision needed from customer
None — PMBOK 8 treats this as mandatory. Implementation is
additive-only (new sections / enum entries). No ownership trade-off.

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `docs/templates/pm/CHARTER-template.md` | insert | New §11 "Sustainability considerations" after current §10 Assumptions. Content: environmental / social / economic KPIs; tie to SDGs if project scope warrants. (Audit §3.1, citing PMBOK 8 §3.7.1 line 3006.) |
| `docs/templates/pm/CHARTER-template.md` | edit §1 | Rename to "Purpose, justification, and value proposition"; add benefits/value sub-paragraph (ties to PMBOK 8 §2.4 Finance; partially covers P2 item "Focus on Value" too). |
| `docs/templates/pm/RISKS-template.md` | edit line 19 | Category enum: add `sustainability` and `AI-use`. Current: `schedule / cost / technical / external / safety / compliance / people / other`. New: `… / sustainability / AI-use / other`. |
| `docs/templates/pm/LESSONS-template.md` | edit line 30 | Category enum: add `sustainability` and `AI-use`. |
| `.claude/agents/project-manager.md` | insert Responsibility | "Sustainability integration across scope / schedule / cost / risk per PMBOK 8 §3.7. Ensures CHARTER §11 is populated and sustainability risks flow into RISKS.md category." |
| `.claude/agents/project-manager.md` | insert Responsibility | "Milestone synthesis in LESSONS.md includes a sustainability review line." |

### Dependencies / sequencing
- Independent of other items. Can ship in parallel with 4, 6, 7, 8.
- Item 6 (AI Use Policy) cross-references the `AI-use` category enum
  being added here; sequence 3 before 6 ideally, but either order
  works.

### Effort
**M** — ~2h. Three template edits, two PM-agent insert lines, new
CHARTER section drafting.

### Risk of not doing it
PMBOK 8 compliance gap on a named principle. More concretely:
sustainability risks (cloud-spend carbon cost, supplier sustainability
credentials per PMBOK 8 §X4.7, hardware lifecycle) currently have no
home; they slip through the register entirely.

---

## §4 P1-4: Team Charter template

### Gap
PMBOK 8 names the *Team Charter* as explicit output of Plan Resource
Management (§2.6, line 8574) and input to Lead the Team (line 8771).
Not covered in any current template. Particularly relevant for
multi-agent projects where team norms should be explicit. (PMBOK
audit §2.4, §3.8.)

### Decision needed from customer
**Q3.** Scope of the Team Charter for multi-agent projects:
- **(a) Human-team focused** — values, decision-making, conflict
  resolution, meeting norms for the human side (customer + external
  SMEs + any human collaborators).
- **(b) Agent-team focused** — extends `docs/AGENT_NAMES.md` with team
  norms that apply to agent interactions (escalation discipline,
  communication cadence, handoff protocols).
- **(c) Both, in one artefact** — single TEAM-CHARTER.md covering
  human-team + agent-team norms. Recommended by PM; mirrors PMBOK 8
  intent and leverages existing escalation protocol already in
  `CLAUDE.md`.

**PM recommendation:** **(c)**. PMBOK 8's team charter is agnostic to
whether team members are human or automated; the template should
capture norms once.

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `docs/templates/pm/TEAM-CHARTER-template.md` | **new** | See outline below. |
| `.claude/agents/project-manager.md` | insert table row | Row after line 26 (current table): `Team charter \| docs/pm/TEAM-CHARTER.md \| Planning`. |
| `.claude/agents/project-manager.md` | insert template mapping | Under line 36 list: `TEAM-CHARTER-template.md → docs/pm/TEAM-CHARTER.md`. |
| `.claude/agents/project-manager.md` | insert Responsibility | "Team charter: captures team values, decision-making process, conflict resolution, communication cadence, meeting norms. Updated when team composition changes (customer onboards SMEs, new agents added, etc.)." |
| `CLAUDE.md` Step-2 DoD checklist (~line 170) | insert | Add bullet: `[ ] Team charter captured in docs/pm/TEAM-CHARTER.md`. |

#### Outline — `TEAM-CHARTER-template.md`

```
# Team Charter — <project>

PMBOK 8 Planning artifact (§2.6 Plan Resource Management output).
Owned by `project-manager`. Written during scoping; revised when
team composition changes.

## 1. Team roster
  - Human team members (customer, external SMEs)
  - Agent team members (pointer to `docs/AGENT_NAMES.md`)

## 2. Values and operating principles
  (e.g., correctness over speed; paraphrase over quotation; escalate
  on uncertainty rather than guess)

## 3. Decision-making process
  - Who decides what (customer / tech-lead / architect / project-
    manager / specialist agents)
  - Binding vs advisory rulings
  - Ties to `CLAUDE.md` hard rules

## 4. Conflict resolution
  - Agent-to-agent disagreement → tech-lead arbitrates
  - Architect-vs-PM trade-off → architect leads, PM concurs or files
    formal dissent in CHANGES.md
  - Customer-vs-agent disagreement → customer always wins; agent
    records objection in LESSONS.md

## 5. Communication norms
  - Escalation protocol (ref CLAUDE.md §Escalation)
  - Question-asking protocol (one question per turn; idle agents)
  - Channels: what goes in OPEN_QUESTIONS.md vs CUSTOMER_NOTES.md
    vs CHANGES.md vs LESSONS.md

## 6. Meeting / cadence norms
  - Session start (skill packs, version check)
  - Milestone close (PM runs agent-health check on tech-lead)
  - Retrospective cadence

## 7. Revision log
  | Date | Change | Ratified by |
```

### Dependencies / sequencing
- Depends on Q3.
- Referenced by item 5 (Resources template points at Team Charter).
  Land item 4 before item 5.

### Effort
**M** — ~2h. Template drafting is the bulk; agent + CLAUDE.md edits
are minor.

### Risk of not doing it
PMBOK 8 compliance gap on a named artefact. Operationally: team norms
stay scattered across `CLAUDE.md`, `docs/AGENT_NAMES.md`, and
`docs/agent-health-contract.md` with no single entry point;
onboarding a new human collaborator or external SME is harder.

---

## §5 P1-5: Resources template + Resources performance domain

### Gap
PMBOK 8 §2.6 Resources is one of the seven performance domains with
five processes (Plan Resource Management, Estimate Resources, Acquire
Resources, Lead the Team, Monitor and Control Resourcing). No
`RESOURCES.md` template; PM agent only mentions "resource coordination"
in passing (line 49). (PMBOK audit §2.2, §3.8, §4.1.)

### Decision needed from customer
**Q4.** Physical/virtual resource tracking scope:
- **(a) Full PMBOK 8 scope** — humans + physical (hardware, lab
  equipment, test environments) + virtual (cloud quotas, SaaS seats,
  API rate limits).
- **(b) Humans only** — rely on Operations Plan (item 2) for physical
  / virtual resources.

**PM recommendation:** **(a)**. Cloud quotas and SaaS seats are
exactly the resources downstream projects run out of first. Scope
them here rather than hoping the Ops Plan catches them.

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `docs/templates/pm/RESOURCES-template.md` | **new** | See outline below. |
| `.claude/agents/project-manager.md` | insert table row | After line 26: `Resources \| docs/pm/RESOURCES.md \| Planning / Monitoring`. |
| `.claude/agents/project-manager.md` | insert template mapping | `RESOURCES-template.md → docs/pm/RESOURCES.md`. |
| `.claude/agents/project-manager.md` | expand line 49 | Current: "Resource coordination: who is doing what this week". Expand to PMBOK 8 §2.6 five-process framing (Plan / Estimate / Acquire / Lead / Monitor). |
| `CLAUDE.md` | (no change) | Template covers it. |

#### Outline — `RESOURCES-template.md`

```
# Resources Register — <project>

PMBOK 8 Planning / Monitoring artifact (§2.6). Owned by
`project-manager`. Tracks human, physical, and virtual resources
across Plan / Estimate / Acquire / Lead / Monitor processes.

## 1. Human resources
  - Roster (pointer to TEAM-CHARTER.md §1)
  - Allocation % per milestone
  - Skills / certifications needed vs available
  - Acquisition plan (recruit / contract / customer-SME pickup)

## 2. Physical resources
  - Hardware (test benches, PLCs, lab equipment)
  - Facilities
  - Acquisition lead time

## 3. Virtual resources
  - Cloud quotas and costs (ties to COST.md funding type)
  - SaaS seats and licences
  - API rate limits + service-tier caps
  - Domain names / certificates

## 4. Estimation method
  Reference PMBOK 8 §2.6.2; cite the estimation technique used
  (expert judgment / analogy / parametric / decomposition).

## 5. Acquisition log
  | Resource | Requested | Acquired | Source | Cost |

## 6. Monitoring + control
  - Utilization review cadence
  - Contention escalation (→ tech-lead)

## 7. References
  - Team Charter (docs/pm/TEAM-CHARTER.md)
  - Operations Plan (docs/operations-plan.md)
  - Cost baseline (docs/pm/COST.md)
```

### Dependencies / sequencing
- Depends on item 4 (Team Charter) — the Resources template points at
  TEAM-CHARTER.md. Land item 4 first.
- Q4 customer answer blocks scoping.

### Effort
**L** — ~3h. Template drafting (2h), PM-agent restructure of
Responsibilities list (1h).

### Risk of not doing it
Cloud-quota / licence / rate-limit contention surfaces only in the
incident that blocks a release. No place to record "we have a 90-day
certificate expiring on X" until it has already expired.

---

## §6 P1-6: AI Use Policy template (PMBOK 8 Appendix X3)

### Gap
PMBOK 8 Appendix X3 (pp. 237–244) defines three AI-adoption
strategies (Automation / Assistance / Augmentation) and eight ethical
factors (Bias, Privacy, Accountability, Reliability, Safety,
Transparency, Copyright, Sustainability). The entire template is an
AI-mediated workflow yet no artefact records AI-use policy.
(PMBOK audit §2.3, §3.8, §4.2.)

### Decision needed from customer
**Q5.** Is AI-use policy per-project or template-default?
- **(a) Per-project instance** — every downstream project fills in its
  own `docs/pm/AI-USE-POLICY.md` from the template. Recommended.
- **(b) Template-default** — a single default AI policy ships in the
  template and projects opt in or override. Faster but less honest
  about project-specific risks.

**PM recommendation:** **(a)** — AI risk profile is genuinely
project-specific (a stats-reporting project differs from a safety-
critical PLC project).

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `docs/templates/pm/AI-USE-POLICY-template.md` | **new** | See outline below. |
| `.claude/agents/project-manager.md` | insert table row | After line 26: `AI Use Policy \| docs/pm/AI-USE-POLICY.md \| Initiating`. |
| `.claude/agents/project-manager.md` | insert template mapping | `AI-USE-POLICY-template.md → docs/pm/AI-USE-POLICY.md`. |
| `.claude/agents/project-manager.md` | insert Responsibility | "AI-use policy stewardship — per PMBOK 8 Appendix X3: document which tasks use Automation / Assistance / Augmentation strategies; address ethical factors (bias, privacy, accountability, reliability, safety, transparency, copyright, sustainability)." |
| `.claude/agents/researcher.md` | insert | Item 8 change (cite hygiene for PMI materials). |
| `CLAUDE.md` Step-4 issue-feedback section (~line 198) | insert | Reference new AI-use-policy step in scoping. |

#### Outline — `AI-USE-POLICY-template.md`

```
# AI Use Policy — <project>

PMBOK 8 Initiating artifact (Appendix X3). Owned by
`project-manager`. Ratified by customer. Referenced from CHARTER §1.

## 1. Scope of AI use
  Which tasks use which PMBOK strategy:
  - Automation (AI acts end-to-end without human step)
  - Assistance (AI proposes; human reviews each output)
  - Augmentation (AI + human iterate together)

## 2. Ethical factors (PMBOK 8 §X3.3)

### 2.1 Bias
  Known bias sources; mitigation; review cadence.

### 2.2 Privacy
  Data classification policy; what does / does not get sent to AI;
  pointer to CUSTOMER_NOTES.md for any customer-specific rule.

### 2.3 Accountability
  Named human sign-off per deliverable class. AI is never the final
  authority. Ties to CLAUDE.md hard rule #4.

### 2.4 Reliability
  Validation approach for AI output: who checks, against what, how
  often, what failure-rate is acceptable.

### 2.5 Safety
  For safety-critical work, AI is never in the decision loop; AI is
  Assistance-mode only. Ties to CLAUDE.md hard rule #2.

### 2.6 Transparency
  Log AI-generated artefacts; disclose to customer which deliverables
  were AI-mediated.

### 2.7 Copyright
  AI must not be fed training-prohibited sources (PMBOK 8 itself is
  one such source — see CLAUDE.md IP policy). AI-generated content
  ownership: check project licence; some jurisdictions do not grant
  copyright to AI-generated content.

### 2.8 Sustainability
  Environmental cost of AI usage; bias toward local/small models
  where output quality permits; log token spend.

## 3. Out-of-scope uses
  Explicit list of uses the project does NOT permit.

## 4. Review cadence
  Milestone-close review by `project-manager`.

## 5. References
  - PMBOK 8 Appendix X3 (LIB-0001)
  - SWEBOK V4 ch. 14 Professional Practice (if ethics binding is
    added per SWEBOK P2)
  - CUSTOMER_NOTES.md (project-specific overrides)
```

### Dependencies / sequencing
- Independent of other items, but cross-references:
  - Item 7 (NO AI TRAINING clause in IP policy)
  - Item 3 (`AI-use` risk category enum)
- Ships cleanest after 3 and 7 are in.

### Effort
**M** — ~2h. Template drafting is most of it; agent edits small.

### Risk of not doing it
The template's own workflow is AI-mediated; not having a policy on the
AI-mediated workflow is the most visible gap. Also: no traceable
sign-off on copyright / privacy / bias means a customer asking "how
is AI being used on my project?" has no document to hand them.

---

## §7 P1-7: "NO AI TRAINING" clause citation in IP policy

### Gap
PMBOK 8 copyright page (LIB-0001 iv, lines 89–92) carries an explicit
prohibition against using the publication to train generative AI.
`CLAUDE.md` § IP policy (lines 449–470) says "assume copyrighted" but
does not name the AI-training prohibition. Researcher handling of PMI
materials needs explicit guidance. (PMBOK audit §2.4, §4.3.)

### Decision needed from customer
None. Compliance requirement.

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `CLAUDE.md` IP policy section (after line 462) | insert | New bullet: "Some external materials carry explicit prohibitions beyond default copyright — e.g., PMI PMBOK Guide 8 (LIB-0001) copyright page prohibits use of the publication to train generative AI. `researcher` must not feed such materials into AI training, fine-tuning, or persistent embedding-for-retrieval stores. Paraphrase and cite only; keep the source text under `docs/library/local/` (gitignored)." |
| `docs/library/INVENTORY.md` LIB-0001 row | edit | Add "IP restrictions" column value: "copyright; NO AI TRAINING clause per copyright page". Correct publication year to 2025 (audit §4.4). |
| `docs/glossary/ENGINEERING.md` IP section | insert | Cross-reference the new CLAUDE.md bullet. |

### Dependencies / sequencing
- Independent. Can ship first as quick win.
- Item 6 (AI Use Policy §2.7 Copyright) references this bullet.

### Effort
**S** — ~30min. One CLAUDE.md edit, one INVENTORY row edit, one
glossary cross-ref.

### Risk of not doing it
Compliance violation with LIB-0001's explicit licence term. If
`researcher` ever feeds PMBOK 8 content into a vector store for
retrieval augmentation, it violates the terms the framework itself
accepts by owning the book.

---

## §8 P1-8: Researcher cite-hygiene for PMI materials

### Gap
PMBOK audit §2.4 flags researcher-specific handling: PMI materials
(LIB-0001 and any future PMI Tier-1 standards) require paraphrase-
only handling, short-fragment quotation limits (≤15 words per audit
convention), and citation-by-row-ID to the library inventory. Not
currently codified in `researcher.md`.

### Decision needed from customer
None. Internal policy clarification.

### Proposed changes

| File | Action | Summary |
|---|---|---|
| `.claude/agents/researcher.md` | insert | New section "Cite hygiene for restricted sources": explicit rule that PMI materials (LIB-0001, future PMI Tier-1) get paraphrase-only treatment; quotations limited to ≤15 words; citation includes library row ID + line/page anchor; no retrieval-augmentation embeddings; source text stays in `docs/library/local/` (gitignored). Cross-reference CLAUDE.md IP bullet from item 7. |
| `.claude/agents/researcher.md` | insert | Add "Source handling matrix" — small table of source types vs handling rules (paraphrase-only / short-quote-ok / full-quote-ok-with-attribution). |

### Dependencies / sequencing
- Independent, but naturally pairs with item 7. Ship together.

### Effort
**S** — ~1h. One agent-file edit, small table.

### Risk of not doing it
`researcher` handling of PMI + future restricted materials is implicit;
new researcher sessions (or agent respawns) may drop the cite-hygiene
rule without a written anchor.

---

## §Final — Open questions for `tech-lead` to raise with customer

Batched; one per row; tech-lead asks one-per-turn per the
question-asking protocol (`CLAUDE.md` Step 2).

| # | Question | Blocks | Default if customer defers |
|---|---|---|---|
| Q1 | Software-security ownership — new standing `security-engineer` agent, per-project `sme-security`, or split across existing agents? (PM + architect recommend: new standing agent.) | Item 1, indirectly item 2 (DevSecOps split) | New standing agent (recommended path) |
| Q2 | Operations-KA process-group ownership split: SRE owns Planning+Control and release-engineer owns Delivery, or a single `ops-engineer`, or keep current split with shared deliverables? (Recommend: (a) SRE+release-engineer split.) | Item 2 | (a) SRE + release-engineer split |
| Q3 | Team Charter scope: human-only, agent-only, or both? (Recommend: both, single artefact.) | Item 4, transitively item 5 | Both in single artefact |
| Q4 | Resources template scope: full PMBOK 8 (human + physical + virtual) or humans-only? (Recommend: full.) | Item 5 | Full scope |
| Q5 | AI-use policy model: per-project instance (filled from template) or template-default with overrides? (Recommend: per-project.) | Item 6 | Per-project instance |
| Q6 | Issue-feedback opt-in: this plan surfaces eight upstream template gaps. Does the customer want `tech-lead` to file these as issues against the template repo per `docs/ISSUE_FILING.md` once the fix plan is approved? | All items (batched filing) | File as a single batched issue citing TEMPLATE_VERSION |
| Q7 | Naming of new agent in item 1: `security-engineer` (SWEBOK-aligned), `security-architect`, or `appsec-engineer`? (Recommend: `security-engineer` — naming consistency.) | Item 1 | `security-engineer` |
| Q8 | Sequencing preference: ship small P1s (7, 8) first as a quick patch, then bundle larger items (1, 2, 5) into a version bump, or cut one version with everything? (Recommend: two releases — quick-win patch then version bump.) | Release plan | Two releases |

---

## Appendix — cross-reference to audit sections

| Plan item | SWEBOK audit | PMBOK audit |
|---|---|---|
| 1 Security | §2.1, §4 item 1 | — |
| 2 Operations | §2.2, §4 item 2 | — |
| 3 Sustainability | — | §2.1 principle row, §3.1, §3.2, §3.7, §4.1, §4.2 |
| 4 Team Charter | — | §2.2 Resources row, §2.4, §3.8 |
| 5 Resources | — | §2.2 Resources row, §3.8, §4.1 |
| 6 AI Use Policy | §2.5 (partial — ML awareness) | §2.3 X3 row, §2.4, §3.8, §4.2 |
| 7 NO AI TRAINING clause | — | §0 method note, §2.4, §4.3 |
| 8 Researcher cite-hygiene | — | §2.4 X3 row last paragraph, §4.3 |

No plan item exceeds the audit's explicit recommendations — every
proposed edit is traceable to a cited audit section.
