# PMBOK 8 Gap Analysis — Pass 2

Supersedes `sw-dev-team-template/docs/audits/pmbok-8-gap-analysis.md`
(pass-1; stub, 1 line). This pass-2 audit is grounded in the actual
PMBOK 8 text via `pdftotext -layout` extraction of LIB-0001.

## 0. Method note

- **Primary source.** `/home/quackdcs/SWEProj/docs/library/local/pmbok.txt`
  (20,882 lines, ~1.3 MB), extracted from LIB-0001 (PMI PMBOK Guide,
  Eighth Edition) using `pdftotext -layout`. Same IP status as the
  PDF; gitignored under `docs/library/local/`.
- **Page mapping.** The .txt preserves form-feed characters (0x0C)
  as page breaks; 385 form-feeds → 386 printed pages. PDF page
  numbers below are the printed numbers shown in the .txt margins
  (e.g., `Appendix X3 ... 237` at line 17515 = PDF page 237).
- **Line ranges actually read.**
  - 1–200 (copyright, LOC metadata, preface)
  - 200–660 (TOC through List of Figures/Tables)
  - 660–760 (Section 1 Introduction of The Standard)
  - 1900–2250 (§2.5 Project Management Roles)
  - 2700–3300 (§3.5–§3.8 principles including Sustainability)
  - 4900–5100 (§2.1 Governance performance domain)
  - 5400–5650 (§2.1.6.4–§2.1.6.6 Manage Project Execution / Quality
    Assurance / Project Knowledge)
  - 7020–7270 (§2.3 Schedule domain tailoring)
  - 7400–7550 (§2.4 Finance domain key concepts)
  - 8300–8800 (§2.5 Stakeholders interactions; §2.6 Resources)
  - 17000–17500 (Appendix X1 contributors, Appendix X2 PMO)
  - 17500–17920 (Appendix X3 Artificial Intelligence, full)
  - 17920–18300 (Appendix X4 Procurement, §X4.1–§X4.8.2)

### Resolved LIB-0001 edition/date metadata (Kindle-2025 vs
paperback-2026 ambiguity)

Read from copyright page (lines 27–108 of the .txt):

| Field | Value |
|---|---|
| Edition | Eighth Edition |
| Publisher | Project Management Institute, Inc., Newtown Square, PA |
| Copyright | ©2025 Project Management Institute, Inc. |
| LOC description date | "Newtown Square, Pennsylvania : Project Management Institute, [2025]" |
| ISBN (paperback) | 978-1-62825-829-5 |
| ISBN (ebook) | 978-1-62825-830-1 |
| ANSI designation | ANSI/PMI 99-001-2025 |
| LCCN (print) | 2025036269 |
| LCCN (ebook) | 2025036270 |
| Notable | Explicit "NO AI TRAINING" clause on the copyright page (lines 89–92) |

**Resolution.** LIB-0001 is the 2025 Eighth Edition regardless of
retailer listing date (Amazon Kindle/paperback variance is an
imprint/printing artefact, not an edition change). Any "2026" date
in the library inventory is stale and should be corrected to 2025.
Update `docs/library/INVENTORY.md` for LIB-0001 accordingly.

**IP note.** The copyright page explicitly prohibits use of the
publication to train generative AI. This audit paraphrases and
cites; it does not commit passages of the source text beyond
quotation fragments under 15 words.

## 1. PMBOK 8 structure verified from TOC

PMBOK 8 physically ships as two bound documents between the same
covers: *The Standard for Project Management* (PMBOK principles-
based standard, §1–§4) and *A Guide to the Project Management Body
of Knowledge* (the Guide proper, §1–§5 plus appendices).

### 1.1 Six Principles (The Standard, §3)

Verified against TOC (lines 294–325):

1. Adopt a Holistic View (§3.3, p. 38)
2. Focus on Value (§3.4, p. 40)
3. Embed Quality Into Processes and Deliverables (§3.5, p. 43)
4. Be an Accountable Leader (§3.6, p. 46)
5. Integrate Sustainability Within All Project Areas (§3.7, p. 48)
6. Build an Empowered Culture (§3.8, p. 53)

Preface (line 202) confirms this is a community-driven refinement
from the previous edition's 12 principles to six. Detail on the
refinement in Appendix X5.4 (p. 257; TOC line 466).

### 1.2 Seven Performance Domains (the Guide, §2)

Verified against TOC (lines 358–408):

1. Governance (§2.1, p. 10)
2. Scope (§2.2, p. 35)
3. Schedule (§2.3, p. 47)
4. Finance (§2.4, p. 58)
5. Stakeholders (§2.5, p. 67)
6. Resources (§2.6, p. 79)
7. Risk (§2.7, p. 92)

### 1.3 Five Focus Areas (The Standard, §4.5)

Verified against TOC (lines 338–343):

1. Initiating (§4.5.1, p. 70)
2. Planning (§4.5.2, p. 70)
3. Executing (§4.5.3, p. 72)
4. Monitoring and Controlling (§4.5.4, p. 72)
5. Closing (§4.5.5, p. 72)

Preface (lines 211–220) confirms these are the reimagining of the
prior-edition Process Groups as Focus Areas.

### 1.4 Process count

Preface (line 238) states "40 nonprescriptive processes". The
Guide places processes inside the seven performance domains; TOC
(§2.1–§2.7 sub-sections ".6 Processes" or ".2 Processes") plus
Appendix §4 Inputs and Outputs (TOC line 424, p. 113) is the
registry. Pass-2 does not enumerate every process individually;
it treats the count as authoritative per the Preface.

### 1.5 Appendices (X1–X5)

Verified against TOC (lines 431–466):

| # | Title | Page |
|---|---|---|
| X1 | Contributors and Reviewers | 217 |
| X2 | Project Management Offices | 233 |
| X3 | Artificial Intelligence | 237 |
| X4 | Procurement | 245 |
| X5 | Evolution of the PMBOK® Guide | 255 |

Plus References (p. 261), Bibliography (p. 263), Glossary (p. 265),
Index (p. 277).

## 2. Gap analysis tables

Legend: **P1** = material gap affecting routine project work; **P2**
= meaningful but not urgent; **P3** = cosmetic or optional;
**Partial** = framework mentions the concept but misses PMBOK 8
breadth.

### 2.1 Principles × roster / templates

| Principle | Coverage in `project-manager.md` + templates | Status | Notes |
|---|---|---|---|
| Adopt a Holistic View | Implicit in artifact set (charter, stakeholders, risks) | OK | Not explicitly named. P3 to call out. |
| Focus on Value | No "value" / "benefits" section in CHARTER; no benefits-realization artifact | **Partial** | CHARTER §1 is "Purpose and justification", not value proposition. PMBOK 8 §2.4 Finance domain centers value maximization, ROI, intangible value (p. 59, lines 7406–7410). P2. |
| Embed Quality Into Processes and Deliverables | PM delegates quality to `qa-engineer` (agent §42 of PM agent) | OK | Delegation is correct; PMBOK 8 §2.1.6.5 Manage Quality Assurance is at the integrated level, not domain-owned. P3. |
| Be an Accountable Leader | Not explicit | OK | Leadership tone implicit throughout; no gap. P3. |
| **Integrate Sustainability Within All Project Areas** | **No artifact, no risk category, no charter section** | **P1 gap** | PMBOK 8 §3.7 (pp. 48–52, lines 2918–3153) is a first-class principle touching every domain. ESG is referenced once in passing in §2.5.2 (line 2146) via the Sponsor role. No sustainability KPI slot in CHARTER; no "sustainability" row option in RISKS category enum (line 19 of RISKS-template: "schedule / cost / technical / external / safety / compliance / people / other"); no sustainability review cadence in LESSONS. |
| Build an Empowered Culture | Not named; roster itself embodies shared leadership | OK | P3. |

### 2.2 Performance Domains × roster / templates

| Domain | Coverage | Status | Notes |
|---|---|---|---|
| Governance | CHARTER §8 "Project manager and authority", §9 "Sponsor"; escalation protocol in PM agent | **Partial** | PMBOK 8 §2.1 (pp. 10–35, lines 4900–5100+) distinguishes structured vs self-governed models, requires target metrics + signaling + feedback mechanisms (§2.1.3, lines 4952–4977). Neither CHARTER nor a separate GOVERNANCE artifact captures this triad. P2. |
| Scope | Handled in PM agent responsibilities line 45; requirements-template separately | OK | Integrated via `docs/templates/requirements-template.md`. P3. |
| Schedule | SCHEDULE-template.md | OK | Covers milestone list, critical path, baseline, variance. Consistent with PMBOK 8 §2.3. P3. |
| **Finance** | COST-template.md covers cost/effort, reserves implicit | **Partial** | PMBOK 8 §2.4 Finance (pp. 58–67, lines 7400+) is broader than cost: funding sources, CapEx/OpEx distinction (line 7421), contingency vs management reserve (lines 7458–7473), value maximization + ROI/IRR indicators (lines 7406–7410), benefits realization. COST-template has no reserves field, no CapEx/OpEx distinction, no benefits/ROI section. P2. |
| Stakeholders | STAKEHOLDERS-template.md | **Partial** | Covers identification, assessment, classification, engagement plan. PMBOK 8 §2.5 uses a *stakeholder engagement assessment matrix* (Figure 5-23, p. 200; cited in Monitor Communications tools line 8331) — the "current vs target engagement" grid (unaware / resistant / neutral / supportive / leading). Template has the column but no matrix artifact / no gap-tracking. P2. |
| **Resources** | No template; PM agent line 49 mentions "resource coordination" | **P1 gap** | PMBOK 8 §2.6 (pp. 79–92, lines 8433+) covers human + physical + virtual resources, five distinct processes (Plan Resource Management, Estimate Resources, Acquire Resources, Lead the Team, Monitor and Control Resourcing). **Team charter** is an explicit output of Plan Resource Management (line 8574) and an input to Lead the Team (line 8771). No `RESOURCES.md` template, no `TEAM-CHARTER.md` template. P1 given that multi-agent projects are exactly the case where team norms should be explicit. |
| Risk | RISKS-template.md | OK | Scoring, response, trigger, review cadence all present. Add sustainability as category (see §2.1 above). P3. |

### 2.3 Appendices × roster / templates

| Appendix | Coverage | Status | Notes |
|---|---|---|---|
| X1 Contributors | N/A — informational | OK | — |
| X2 PMOs | Not addressed; template has no PMO-role stance | P3 | Most downstream projects have no PMO; PM agent + `tech-lead` fill the role. Optional mention in agent docs. |
| **X3 Artificial Intelligence** | Not addressed | **P1 gap** | Appendix X3 (pp. 237–244, lines 17515–17917) defines three adoption strategies (Automation / Assistance / Augmentation, lines 17571–17598), use-case table per performance domain (Table X3-1, lines 17642–17812), and six ethical factors (Bias, Privacy, Accountability, Reliability, Safety, Transparency, Copyright, Sustainability; lines 17621–17869). **The entire template is an AI-mediated workflow** yet no artifact records AI-use policy, bias-mitigation, accountability for AI outputs, copyright/IP position on AI-generated content, or sustainability cost of AI requests (line 17868). This gap is P1 given the template's own premise. Note also the source's "NO AI TRAINING" clause — an IP policy constraint the framework should explicitly honor in `CLAUDE.md` IP policy section. |
| **X4 Procurement** | PM agent line 75 mentions `release-engineer`; no procurement template | **Partial** | Appendix X4 (pp. 245–254, lines 17919–18300+) covers make-or-buy (§X4.3), procurement strategy (§X4.4), bid documents RFI/RFP/RFQ (§X4.5), source selection methods (§X4.6, six methods), source selection criteria (§X4.7 including **sustainability credentials of the supplier** line 18169), four fundamental contract types (§X4.8.1: fixed-price, cost-reimbursable, T&M, target-cost), and five emerging trends (§X4.8.2: agile contracting, smart contracts, outcome-based, sustainable contracting, collaborative). Procurement is NOT a separate performance domain per PMBOK 8 (line 17933 explicitly) but **is** relevant to software projects that use vendor services, cloud platforms, subcontractors, or external SMEs. No template; no guidance when `tech-lead` encounters a vendor decision. P2. |
| X5 Evolution | Documented as history | OK | Informational; useful for explaining why 12→6 principles to customers who knew prior editions. P3. |

### 2.4 Net new gaps vs pass-1

Pass-1 was a stub. This pass-2 confirms pass-1's claimed gaps where
they are consistent with the source, and adds:

- **Team Charter as distinct PMBOK 8 artifact** (line 8574, output
  of Plan Resource Management; line 8771, input to Lead the Team).
  Not covered in any current template. P1.
- **Contingency vs management reserve** distinction missing from
  COST-template (lines 7458–7473). P2.
- **CapEx / OpEx funding distinction** missing from COST-template
  (line 7421). P2.
- **Stakeholder engagement assessment matrix** as a standalone
  artifact (not just a column in STAKEHOLDERS-template). P2.
- **Governance metrics triad** (target metrics / signaling /
  feedback) missing from CHARTER. P2.
- **AI-use policy** artifact missing entirely. P1.
- **IP-policy clash**: PMBOK 8 copyright page explicitly forbids use
  to train generative AI. `CLAUDE.md` § IP policy should note this
  for LIB-0001 and any future PMI-sourced Tier-1 standards. P1 for
  `researcher`; P2 for roster as a whole.

## 3. Template drift in `docs/templates/pm/*.md`

File:line recommendations (do not edit; this is an audit).

### 3.1 `CHARTER-template.md`

- **Line 9–11 §1 Purpose and justification.** Add or rename "Value
  proposition" sub-section; PMBOK 8 §2.4 Finance treats value
  maximization as primary (lines 7406–7410). Benefits realization
  not equivalent to "purpose".
- **Line 28–31 §4 High-level risks.** Note that sustainability is
  a PMBOK 8 risk category (§2.7 via §3.7 principle).
- **Line 43–45 §7 Stakeholders.** Pointer to engagement-assessment
  matrix, not only the register.
- **Missing section: Governance model.** Add a §8.x sub-section
  capturing target metrics / signaling mechanism / feedback
  mechanism per PMBOK 8 §2.1.3 (lines 4952–4977).
- **Missing section: Sustainability considerations.** Per PMBOK 8
  §3.7.1 (line 3006), sustainability KPIs "may be included in the
  project scope statement, project charter, business case".

### 3.2 `RISKS-template.md`

- **Line 19 category enum** `"schedule / cost / technical / external
  / safety / compliance / people / other"` → add `sustainability`
  and `AI-use`.
- **Line 14 impact note.** PMBOK 8 §2.7.1 classification supports
  risk taxonomies richer than probability × impact (Figure 2-46,
  p. 93); optional. P3.

### 3.3 `STAKEHOLDERS-template.md`

- **Line 15–17 Assessment.** The "Engagement target" column maps
  to PMBOK 8 stakeholder engagement assessment matrix (unaware /
  resistant / neutral / supportive / leading) — correct. Add
  sibling column `Engagement current` so the gap is visible. The
  matrix artifact itself (current-vs-target) is not produced;
  recommend adding a §4 "Engagement matrix" rendering instruction.

### 3.4 `SCHEDULE-template.md`

- Minor: PMBOK 8 §2.3.3 tailoring distinguishes predictive /
  adaptive / hybrid life cycles (lines 7188–7212). Template is
  predictive-flavored (baseline / variance / critical path). Add
  optional sections for adaptive (velocity, iteration burndown,
  backlog refinement) and hybrid. P2.

### 3.5 `COST-template.md`

- **Line 7–12 §1 Basis.** Add explicit unit for **reserves**:
  contingency reserve (known-unknowns) separately from management
  reserve (unknown-unknowns) per §2.4.1 (lines 7458–7473).
- **Add funding type row.** CapEx / OpEx distinction per line 7421.
- **Add §6 Benefits / ROI / IRR** for projects where financial
  return is the value metric. Optional section; skip for grant-
  funded or internal-effort projects.

### 3.6 `CHANGES-template.md`

- OK as shipped. PMBOK 8 §2.1.6.7 "Assess and Implement Changes"
  (Figure 2-10) matches the template's approach.
- Optional P3: add a "Dimension" row for `sustainability` and for
  `AI-use-policy`.

### 3.7 `LESSONS-template.md`

- **Line 30 Category enum** `"schedule / cost / quality / technical
  / people / process / customer / tooling / external"` → add
  `sustainability` and `AI-use`.
- OK otherwise; continuous capture matches PMBOK 8 §2.1.6.6 Manage
  Project Knowledge (lines 5586–5649).

### 3.8 Missing templates

- **`RESOURCES-template.md`** — new. Cover Plan Resource Management,
  Estimate Resources, Acquire Resources. Output references
  `TEAM-CHARTER.md`.
- **`TEAM-CHARTER-template.md`** — new. PMBOK 8 identifies team
  charter as output of Plan Resource Management (line 8574) and
  input to Lead the Team (line 8771). Contents: team values and
  agreements, decision-making process, conflict-resolution process,
  meeting guidelines, communication norms. Maps naturally to
  multi-agent workflows (`docs/AGENT_NAMES.md`, escalation protocol).
- **`AI-USE-POLICY-template.md`** — new. Per Appendix X3 §X3.3
  (lines 17615–17881). Covers scope of AI use (automation /
  assistance / augmentation per task class); bias mitigation;
  privacy / data classification; accountability (which human signs
  off); reliability (validation of AI output); copyright (including
  source-material restrictions — note PMBOK 8 copyright page AI-
  training clause); sustainability cost of AI requests.
- **`PROCUREMENT-template.md`** — optional, new. For projects that
  use vendor services. Covers make-or-buy analysis, selection
  method, contract type. Skip for internal-only projects.
- **`BENEFITS-template.md`** — optional, new. For projects whose
  charter authorizes benefits realization beyond delivery.

## 4. Recommended changes (recommend only; no edits here)

### 4.1 `.claude/agents/project-manager.md`

| Priority | Change |
|---|---|
| P1 | Add to the PMBOK artifact table (line 18) rows for Team Charter (Planning) and AI Use Policy (cross-cutting, initiating). |
| P1 | Add to Responsibilities (line 42): "Sustainability integration across scope / schedule / cost / risk per PMBOK 8 §3.7." |
| P1 | Add to Responsibilities: "AI-use policy stewardship — see Appendix X3 ethical factors (bias, privacy, accountability, reliability, safety, transparency, copyright, sustainability)." |
| P2 | Governance sub-responsibility: record target metrics + signaling + feedback mechanisms per PMBOK 8 §2.1.3 in CHARTER. |
| P2 | Finance sub-responsibility: value maximization + benefits realization, not only cost control. |
| P2 | Procurement sub-responsibility reference Appendix X4 when the project uses external vendors; do not create a Procurement performance domain (PMBOK 8 §X4.1 explicitly does not). |
| P3 | Cite PMBOK 8 as "ANSI/PMI 99-001-2025" where applicable. |

### 4.2 Templates (priority-ordered)

| Priority | File | Change |
|---|---|---|
| P1 | new `TEAM-CHARTER-template.md` | Per §3.8 above. |
| P1 | new `RESOURCES-template.md` | Per §3.8 above. |
| P1 | new `AI-USE-POLICY-template.md` | Per §3.8 above. Tie to `CLAUDE.md` IP policy. |
| P1 | `CHARTER-template.md` | Add §11 Sustainability considerations; rework §1 to include value proposition. |
| P1 | `RISKS-template.md` line 19 | Add `sustainability` and `AI-use` categories. |
| P2 | `COST-template.md` | Reserves (contingency / management) split; CapEx/OpEx; optional benefits/ROI section. |
| P2 | `CHARTER-template.md` | Governance model sub-section (target metrics / signaling / feedback). |
| P2 | `STAKEHOLDERS-template.md` | Engagement-matrix rendering instruction. |
| P2 | `SCHEDULE-template.md` | Optional adaptive / hybrid sections. |
| P2 | new `PROCUREMENT-template.md` | Per §3.8 above. |
| P3 | `LESSONS-template.md` line 30 | Expand category enum. |
| P3 | `CHANGES-template.md` | Add dimensions. |

### 4.3 `CLAUDE.md` / IP policy

| Priority | Change |
|---|---|
| P1 | Add to IP-policy section: PMBOK 8 copyright page (LIB-0001) explicitly prohibits use of the source to train generative AI. `researcher` and all agents must paraphrase; no fine-tune / train / embedding-for-retrieval that persists the source text. |
| P2 | `SW_DEV_ROLE_TAXONOMY.md` references should be updated to reflect PMBOK 8 structure (6 Principles, 7 Performance Domains, 5 Focus Areas) where it currently reflects earlier editions. Cross-referenced with the separately-flagged SWEBOK v3→v4 upgrade audit. |

### 4.4 Library inventory

| Priority | Change |
|---|---|
| P1 | `docs/library/INVENTORY.md` LIB-0001 row: publication year = 2025 (not 2026); ISBN 978-1-62825-829-5 (paperback) / 978-1-62825-830-1 (ebook); ANSI/PMI 99-001-2025. |

## 5. Sources

All from `/home/quackdcs/SWEProj/docs/library/local/pmbok.txt`
(extraction of LIB-0001).

| Claim | .txt line(s) | PDF page |
|---|---|---|
| Eighth Edition, 2025 copyright | 1–108 | i (copyright page) |
| ISBN 978-1-62825-829-5 paperback | 59, 69 | iv |
| ANSI/PMI 99-001-2025 | 15 | cover |
| "NO AI TRAINING" clause | 89–92 | iv |
| Six principles refinement from twelve | 201–208 | viii |
| Five Focus Areas replacing Process Groups | 211–220 | viii |
| 40 processes | 236–239 | ix |
| Seven performance domains (TOC) | 358–408 | xiv–xv |
| Principle 5 Sustainability (§3.7) | 318–321, 2918–3153 | xii, 48–52 |
| Sustainability KPIs in charter/business case | 3006 | 50 |
| Sustainability Pyramid (Figure 3-7) | 2953–2970 | 49 |
| Governance metrics triad (§2.1.3) | 4952–4977 | 13 |
| Structured vs self-governed models (Figure 2-1) | 4915–4945 | 12 |
| Finance value maximization / ROI / IRR | 7406–7410 | 59 |
| CapEx vs OpEx | 7421 | 59 |
| Contingency vs management reserve | 7458–7473 | 60 |
| Stakeholders ↔ Finance interaction | 8388–8391 | 77 |
| Resources domain processes (five) | 8500–8550 | 80 |
| Team charter as output of Plan Resource Management | 8574 | 81 |
| Team charter as input to Lead the Team | 8771 | 85 |
| Appendix X3 AI header | 17515–17516 | 237 |
| Automation / Assistance / Augmentation strategies | 17571–17598 | 238 |
| X3.3 ethical factors (bias, privacy, accountability, reliability, safety, transparency, copyright, sustainability) | 17621–17869 | 239–243 |
| PMI Infinity / suggested resources | 17884–17909 | 244 |
| Appendix X4 header and procurement-not-a-domain | 17919–17940 | 245 |
| Make-or-buy (§X4.3) | 17999–18015 | 246 |
| RFI / RFP / RFQ (§X4.5) | 18064–18069 | 248 |
| Six source-selection methods (§X4.6) | 18116–18144 | 249 |
| Sustainability credentials of supplier (§X4.7) | 18169 | 250 |
| Four fundamental contract types (§X4.8.1) | 18214–18247 | 251 |
| Five emerging trends (§X4.8.2: agile / smart / outcome-based / sustainable / collaborative) | 18267–18284 | 252 |

No web sources consulted. No substitution of source material.
