# SWEBOK V4 gap analysis vs current agent roster — Pass 2

**Audit date:** 2026-04-23
**Auditor:** researcher (via tech-lead)
**Book:** LIB-0002 — SWEBOK Guide V4.0a (IEEE CS, released Sept 2025;
ed. Hironori Washizaki, Waseda University, IEEE CS 2025 President).
**Supersedes:** `sw-dev-team-template/docs/audits/swebok-v4-gap-analysis.md`
(pass 1; blocked on PDF access, rested on KA-level web summaries).

---

## §0 Method note

Pass 1 was blocked because `Read` rejected the PDF (no poppler on the
session host). For pass 2, `tech-lead` pre-extracted the PDF to
`/home/quackdcs/SWEProj/docs/library/local/swebok-v4.txt` with
`pdftotext -layout`. 21,342 lines, 1.6 MB, 410 form-feed characters →
411 pages (consistent with the printed book).

All citations in this pass are to **LIB-0002 + PDF page N** (the V4 book
uses per-chapter page numbers like "6-1", "13-1"; I cite those as they
appear in the source). Line ranges below are from the .txt file and
are listed in §5 so a reviewer can re-open the exact passages I read.

No web substitution was used for factual claims. Where a pass-1
finding rested on a web summary, pass 2 either (a) confirms it from the
.txt, (b) revises it, or (c) rejects it.

IP policy per CLAUDE.md: paraphrase only, no verbatim >15 words, .txt
lives under `docs/library/local/` (gitignored) alongside the PDF.

### Lines actually read (summary — see §5 for the mapping to PDF pages)

- TOC: .txt lines 1–1014 (PDF pp. v–xxiv).
- Forewords: .txt 1100–1199.
- Ch. 6 Software Engineering Operations: .txt 7517–8100+ (PDF pp. 6-1
  through 6-end; chapter continues past the body I sampled).
- Ch. 13 Software Security: located and sampled (see §2.1).
- Ch. 14 Software Engineering Professional Practice: located and
  sampled (see §2.3).
- Ch. 7 Maintenance and Ch. 15 Economics: TOC-level (pp. 7-1, 15-1).

---

## §1 V4 Knowledge Area inventory (verified against the TOC)

Verified from the .txt Table of Contents (lines 69–1014).
**18 KAs confirmed.** Three are net-new vs V3 (Architecture split from
Design; Software Engineering Operations; Software Security).

| # | V4 KA title (as printed) | Ch. | First PDF page | .txt line of TOC entry |
|---|---|---|---|---|
| 1 | Software Requirements | 1 | 1-1 | 89 |
| 2 | Software Architecture | 2 | 2-1 | 149 |
| 3 | Software Design | 3 | 3-1 | 184 |
| 4 | Software Construction | 4 | 4-1 | 236 |
| 5 | Software Testing | 5 | 5-1 | 290 |
| 6 | Software Engineering Operations | 6 | 6-1 | 412 |
| 7 | Software Maintenance | 7 | 7-1 | 459 |
| 8 | Software Configuration Management | 8 | 8-1 | 508 |
| 9 | Software Engineering Management | 9 | 9-1 | 559 |
| 10 | Software Engineering Process | 10 | 10-1 | 602 |
| 11 | Software Engineering Models and Methods | 11 | 11-1 | 633 |
| 12 | Software Quality | 12 | 12-1 | 659 |
| 13 | Software Security | 13 | 13-1 | 696 |
| 14 | Software Engineering Professional Practice | 14 | 14-1 | 732 |
| 15 | Software Engineering Economics | 15 | 15-1 | 779 |
| 16 | Computing Foundations | 16 | 16-1 | 856 |
| 17 | Mathematical Foundations | 17 | 17-1 | 935 |
| 18 | Engineering Foundations | 18 | 18-1 | 977 |

Appendices A (KA Description Specifications), B (IEEE/ISO/IEC
Standards supporting SWEBOK) follow. Appendix A confirms the
editorial contract that each KA uses a common structure
(breakdown-of-topics + matrix of topics vs. reference material +
further readings + references).

**Change from pass 1:** pass 1's KA list was correct at 18, matching
what was retrieved from the IEEE CS landing page. Pass 2 confirms it
from the source directly, with chapter-level page anchors usable for
later citation.

---

## §2 Gaps — confirmed / revised / rejected

### §2.1 Gap (pass-1 G2.1) — Software Security as its own KA: **CONFIRMED, upgraded**

**Source (.txt lines read):** 13500–13580 (ch. 13 breakdown figure,
Fundamentals, Security Management); chapter spans PDF pp. 13-1 to
13-8 per TOC (lines 696–729).

**What V4 says (paraphrased).** Ch. 13 Software Security is a new KA
with six top-level sections: Fundamentals (Software Security /
Information Security / Cybersecurity), Security Management and
Organization (Capability Maturity Model, ISMS per ISO/IEC 27001:2022,
Agile Practice for Software Security), Software Security Engineering
and Processes (Secure Development Life Cycle, Common Criteria),
Security Engineering for Software Systems (Requirements, Design,
Patterns, Construction, Testing, Vulnerability Management), Software
Security Tools (vulnerability-checking, penetration-testing), and
Domain-Specific Security (Container/Cloud, IoT, Machine-Learning
applications). The KA explicitly names **DevSecOps** as an emerging
discipline integrating security throughout the life cycle
(PDF p. 13-3; .txt ~13574).

**Confirmed gap vs roster.** No agent owns this KA. `architect.md`
lists security only as a cross-cutting concern (line 14: "fault
handling, observability hooks, configuration surface, upgrade/
migration path, safety-critical vs non-critical separation"); security
is implicit, not named. `code-reviewer.md`, `qa-engineer.md`,
`release-engineer.md` — none mandate a security pass, threat model,
vulnerability-management policy, or DevSecOps artefact.

**Severity.** **P1.** Pass-1 finding holds; pass-2 upgrades it from
"missing binding" to "missing binding + missing artefact class".
V4 expects a SDLC-integrated security stream with discoverable
artefacts (threat model, security requirements, security test plan,
vuln-management record, SBOM review). Today's roster produces none
of these by default.

**Recommended fix (recommend, do not edit).**
- Add `security-engineer.md` to the standard roster (or, if policy
  prefers, a standing `sme-security.md` scaffold path in CLAUDE.md).
- Name owner for: threat modelling at design-review time; security
  requirements review against the Software Requirements KA; a security
  assurance case or equivalent before release; vulnerability-management
  policy; SBOM review and response to advisory feeds.
- Add hard-rule entry to CLAUDE.md: "No release touching
  authentication, authorization, secrets, PII, or network-exposed
  endpoints ships without `security-engineer` sign-off recorded in
  `CUSTOMER_NOTES.md`."
- Add `docs/templates/security-template.md` shaped after ch. 13
  sections 3–4.

---

### §2.2 Gap (pass-1 G2.2) — Software Engineering Operations KA: **CONFIRMED, clarified**

**Source (.txt lines read):** 7517–8100 (most of ch. 6, including
Fundamentals, Breakdown figure 6.1, Operations Planning through §2.6
Safety/Security, Delivery §3.1–3.4, Control topics). Chapter spans
PDF pp. 6-1 to 6-15 per TOC (lines 412–456).

**What V4 says (paraphrased).**
- V4 defines **software engineering operations** as the activities to
  deploy, operate, and support a software application while preserving
  integrity and stability (PDF p. 6-1; .txt ~7563).
- Names **two roles**: *operations engineer* (develops operations
  services exposed as APIs) and *software engineer* (consumes those
  services to deploy/manage applications). PDF p. 6-3; .txt ~7647.
- Explicitly **distinguishes** Platform Engineering and SRE inside
  the KA (PDF p. 6-3; .txt 7622–7635): Platform Engineering builds
  self-service capabilities; SRE monitors/automates/improves ops with
  respect to availability, performance, latency, security; SRE also
  owns change management, emergency response, capacity planning.
- Primary standards referenced: ISO/IEC/IEEE 20000-1 (ops service
  management), ISO/IEC/IEEE 12207:2017 (operation process),
  ISO/IEC/IEEE 32675:2022 (DevOps). .txt 7746–7752, 7862–7864.
- Three main process groups: Operations Planning, Operations Delivery,
  Operations Control (Figure 6.2, .txt 7706–7722).
- Operations-Planning topics include: Operations Plan / CONOPS,
  Supplier Management, Dev + Operational Environments, Availability /
  Continuity / SLAs, Capacity Management, Backup/DR/Failover, Data
  Safety/Security/Integrity.
- Operations-Delivery topics include: Operational Testing / V&V /
  Acceptance, Deployment/Release Engineering (canary, feature toggles,
  rollback-on-signal), Rollback and Data Migration, Problem Resolution.
- Operations-Control topics include: Incident Management, Change
  Management, Monitor/Measure/Track/Review, Operations Support,
  Service Reporting.
- **DevSecOps** named as the security-integrated evolution of DevOps
  (.txt 7976–7984).

**Confirmed gap vs roster.** V4 ch. 6 is coherent and owns more
ground than our split between `sre.md` and `release-engineer.md`.
Specifically:
- **Operations Plan / CONOPS** — no agent owns this deliverable.
- **Supplier management for ops services (IaaS/PaaS/cloud)** — not
  named in any agent.
- **Dev + Operational Environments coherence ("single source of
  truth", IaC)** — `release-engineer.md` touches CI config; no agent
  names IaC or PaC explicitly.
- **DevSecOps** — unmentioned anywhere.
- **Backup / DR / Failover planning** — absent.
- SRE and Release-Engineer agents cite taxonomy §2.3 / §2.8 (built
  on v3) rather than V4 ch. 6. Citation drift.

**Revision from pass 1.** Pass 1 called this P2 with a light fix
("document the sre ↔ release-engineer split"). Pass 2 finds V4 more
prescriptive than pass 1 assumed — the KA specifies deliverables
(Operations Plan, CONOPS, capacity plan, DR plan) the current roster
does not produce. **Upgrade to P1 on deliverables, P2 on routing.**

**Recommended fix (recommend, do not edit).**
- Add `docs/templates/operations-plan-template.md` shaped after
  V4 ch. 6 §2 (Operations Planning).
- Expand `sre.md` to cite V4 ch. 6 as primary KA anchor and add
  responsibility for CONOPS / capacity plan / DR plan (currently
  implicit in SRE industry practice; now explicit per V4).
- Expand `release-engineer.md` to cite V4 ch. 6 §3 (Deployment/
  Release Engineering) and explicitly name IaC / PaC / rollback
  automation.
- Add routing rule in CLAUDE.md: SRE owns Operations Planning +
  Operations Control; Release-Engineer owns Operations Delivery;
  conflicts arbitrated by architect.
- DevSecOps ownership: shared between SRE, Release-Engineer, and the
  new Security-Engineer (if adopted per §2.1 above).

---

### §2.3 Gap (pass-1 G2.3) — Professional Practice KA: **CONFIRMED**

**Source (.txt lines read):** 13942–14200 (ch. 14 intro, §1.1
Accreditation/Certification/Licensing, §1.2 Codes of Ethics, §1.3
Professional Societies, §1.4 Standards, §1.5 Economic Impact, §1.6
Employment Contracts). Chapter spans PDF pp. 14-1 to 14-14 per TOC
(lines 732–776).

**What V4 says (paraphrased).**
- Ch. 14 KA covers three top-level sections: Professionalism, Group
  Dynamics and Psychology, Communication Skills (Figure 14.1 at
  .txt ~14006).
- Names the binding codes: **ACM Code of Ethics and Professional
  Conduct (2018)**, **IEEE Code of Ethics (2020 revision, originally
  1912)**, **IFIP Code of Ethics (2021, adapted from ACM)**, plus the
  1999 joint **IEEE CS/ACM Software Engineering Code of Ethics and
  Professional Practices** (.txt 14135–14146).
- Names the certification standard: **ISO/IEC 24773-4** for software
  engineering certification (.txt 14100–14108).
- Lists violation modes (concealing inadequate work, disclosing
  confidential info, failing to disclose risks, failing to give
  credit) and associated penalties (.txt 14150–14160).
- Requires software engineers to "commit themselves to making … a
  beneficial and respected profession" and adhere to the ten
  principles of the IEEE Code of Ethics 2020 (.txt 14162–14171).
- Legal issues covered: Standards, Trademarks, Patents, Copyrights,
  Trade Secrets, Professional Liability, Legal Requirements, Trade
  Compliance, Cybercrime, Data Privacy (TOC lines 745–755).
- Group Dynamics topics: team dynamics, individual cognition,
  complexity, stakeholder interaction, uncertainty/ambiguity, equity/
  diversity/inclusivity (TOC lines 758–765).

**Confirmed gap vs roster.** Pass 1 finding holds. No agent file
mentions ethics, licensure, professional society, or Code-of-Ethics
obligations. `docs/glossary/ENGINEERING.md` covers IP policy (which
maps to V4 ch. 14 §1.7.3/§1.7.4/§1.7.5) but does not bind agents to
a named code of ethics.

**Severity.** **P2** (as pass 1). Not P1 because no artefact is
blocked, but it is the KA most commonly cited in audit and
regulatory contexts, and the customer-safety hard rules in CLAUDE.md
(safety sign-off, no-surprise-to-customer) are *de facto* aligned
with ch. 14 §1.7.6 "Professional Liability" without saying so.

**Recommended fix (recommend, do not edit).**
- Add Professional Practice entry to `docs/glossary/ENGINEERING.md`
  binding agents by reference to the joint IEEE CS/ACM 1999 Software
  Engineering Code of Ethics plus the IEEE Code of Ethics 2020 (8 +
  10 principles respectively).
- Add an "ethics review" note to `code-reviewer.md` for any change
  that touches user safety, data privacy, or professional-liability
  surface.
- No new agent needed.

---

### §2.4 Gap (pass-1 G2.4) — Architecture split from Design: **CONFIRMED (citation drift)**

**Source (.txt):** TOC lines 149–181 (ch. 2 Software Architecture)
and 184–234 (ch. 3 Software Design).

**What V4 says (paraphrased).** V4 ch. 2 is a standalone KA with its
own Fundamentals ("The Senses of Architecture", Stakeholders and
Concerns, Uses of Architecture), Description (Views/Viewpoints per
ISO/IEC/IEEE 42010 vocabulary, Patterns/Styles/Reference
Architectures, ADLs/Frameworks, Architecture as Significant
Decisions), Process (Architecture in Context, Architectural Design,
Practices/Methods/Tactics, Architecting in the Large), and Evaluation
(Goodness, Reasoning, Reviews, Metrics). Ch. 3 Software Design keeps
design-principles, design-qualities, recording-methods, strategies,
and quality-analysis.

**Confirmed gap vs roster.** `architect.md` line 8 cites "SWEBOK v3
KA 'Software Design'"; SW_DEV_ROLE_TAXONOMY.md §2.4a cites v3 KA
"Software Design". Under V4 the primary anchor is ch. 2 Architecture
with ch. 3 Design secondary.

**Severity.** **P3** (as pass 1). Wording drift only; `architect.md`
scope already covers what V4 calls Architecture.

**Recommended fix.** Update `architect.md` line 8 to cite "SWEBOK V4
KA 'Software Architecture' (ch. 2), with 'Software Design' (ch. 3) as
adjacent." Update `SW_DEV_ROLE_TAXONOMY.md` §2.4a similarly.

`[pass-2b]` Body read of Ch. 2 §1 and Ch. 3 §1 confirms V4 intro
(PDF p. 2-1) explicitly "creates a software architecture knowledge
area, separate from the Software Design KA" and Ch. 3 §1 delegates
architectural design back to Ch. 2. Precise citation now available
— see §6.3. Severity unchanged (P3).

---

### §2.5 Gap (pass-1 G2.5) — AI/ML integration: **REVISED — partially confirmed, concrete locations identified**

**Source (.txt):** TOC line 922 (ch. 16 §9 "Artificial Intelligence
and Machine Learning" on PDF p. 16-25 with sub-sections Reasoning,
Learning, Models, Perception/Problem-Solving, NLP, "AI and Software
Engineering"); TOC line 726 (ch. 13 §6.3 "Security for Machine
Learning-Based Application" on PDF p. 13-6); TOC line 402 (ch. 5 §7
"Testing of and Testing Through Emerging Technologies" on PDF p.
5-26, including §7.1 Testing of Emerging Technologies and §7.2
Testing Through Emerging Technologies).

**What V4 says (paraphrased).** AI/ML lives in three concrete
locations, not as a single cross-cutting stream: (a) Computing
Foundations ch. 16 §9 introduces AI/ML at a foundational level and
includes "AI and Software Engineering" sub-section (§9.6); (b)
Software Security ch. 13 §6.3 gives ML-specific security concerns;
(c) Software Testing ch. 5 §7 covers testing of ML-based systems and
the use of ML for testing. V4 does **not** introduce an ML-ops KA.

**Confirmed gap vs roster.** Pass 1 called AI/ML "cross-cutting;
specific sections not verified." Pass 2 confirms AI/ML is addressed
but localised, not cross-cutting. Our roster has:
- No ML-specific testing guidance in `qa-engineer.md`.
- No ML-specific security guidance (would belong to the proposed
  security-engineer per §2.1).
- No agent owns model versioning, training-data lineage, or
  inference-drift monitoring — but V4 itself does not demand these
  as KA-level deliverables.

**Severity.** **P3** (revised down from P2). The gap is narrower
than pass 1 feared: V4 does not require an ML-engineer role; it
requires ML *awareness* inside existing KAs.

**Recommended fix.**
- Add ML-testing note to `qa-engineer.md` citing V4 ch. 5 §7.
- If/when `security-engineer.md` is created per §2.1, include ML
  security per V4 ch. 13 §6.3.
- Defer a dedicated ML-agent decision until a project actually
  builds ML-based software; then create `sme-ml.md` per-project.

`[pass-2b]` Body read of Ch. 5 §7 confirms a three-aspect framework
for ML testing: **required conditions** (correctness, robustness,
security, privacy), **ML/DL items** (data / learning program /
framework as possible fault locations), **testing activities**
(test-case generation, test-oracle identification, adequacy
criteria), with offline (cross-validation) and online (post-
deployment) phases. The `qa-engineer.md` note should cite this
framework explicitly, not just "see §7." Body read of Ch. 16 §9.6
"AI and Software Engineering" also names **AI for SE** (using
AI/ML in QA activities: defect prediction, test-case generation,
vulnerability analysis) — this is a hook for `qa-engineer.md` and
`code-reviewer.md` even on non-ML SUTs. Severity unchanged (P3).
See §6.4 and §6.5.

---

### §2.6 Gap (pass-1 "Maintenance partial"): **CONFIRMED**

**Source (.txt):** TOC lines 459–505 (ch. 7 Software Maintenance).
Key sub-topics: Categories (corrective, adaptive, perfective,
preventive), Key Issues (limited understanding, testing, impact
analysis, maintainability, alignment with organizational objectives,
staffing, process, supplier management, organizational aspects),
Costs (incl. **technical-debt cost estimation**), Measurement,
Processes, Techniques (Program Comprehension, Reengineering, Reverse
Engineering, **Continuous Integration/Delivery/Testing/Deployment**,
Visualizing Maintenance).

**Confirmed gap vs roster.** Pass 1 flagged "software-engineer + sre
(implicit)". Pass 2 confirms: no agent explicitly owns the
Maintenance KA. `software-engineer.md` owns Construction, not
Maintenance. `release-engineer.md` owns CI/CD plumbing, not
maintenance process. Technical-debt estimation (§2.3.1) is
orphaned.

**Severity.** **P2**. Missing ownership for a KA that runs the
majority of the software life-cycle cost (V4 reiterates this at ch. 7
§1.4 "Majority of Maintenance Costs", TOC line 466).

**Recommended fix.**
- Either widen `software-engineer.md` to cite V4 ch. 7 as secondary
  anchor (after Construction) and own maintenance-mode work, **or**
  create a separate `maintenance-engineer.md`. Industry does not
  have a clean canonical role for this; widening `software-engineer`
  is lower-cost.
- Add technical-debt tracking to `project-manager.md` per V4
  ch. 7 §2.3.1.

`[pass-2b]` Body read of Ch. 7 confirms the gap survives. V4
§2.2.5 "Organizational Aspects of Maintenance" (PDF p. 7-9)
explicitly presents **both** ownership models (single-team-agile
and separate-maintenance-function) with pros/cons and leaves the
choice to the organization — it does not prescribe one. Our roster
has no agent picking or documenting this decision. Additional fix:
require the project to record its maintenance arrangement in
`CUSTOMER_NOTES.md` at project start. Also: V4 names **six**
maintenance categories (corrective / preventive / adaptive /
additive / perfective / emergency), wider than the classic four;
any maintenance template should adopt the six-category set. Add
§2.2.4 Supplier Management (SLA, single-source / multi-sourcing /
XaaS) as a named sub-responsibility. Severity unchanged (P2). See
§6.1.

---

### §2.7 Gap (pass-1 "Economics partial"): **CONFIRMED**

**Source (.txt):** TOC lines 779–853 (ch. 15 Software Engineering
Economics). Ten top-level sections including Fundamentals,
Engineering Decision-Making Process, For-Profit / Nonprofit / Present
Economy / Multiple-Attribute Decision-Making, Intangible Assets,
Estimation (expert judgment, analogy, decomposition, parametric,
multiple estimates), Practical Considerations (Business Case,
Multi-Currency, Systems Thinking).

**Confirmed gap vs roster.** `project-manager.md` is PMBOK-aligned
(schedule/cost/risk/stakeholder/change/lessons). It does not
explicitly cover the engineering-economics decision-making framework
V4 specifies — business case, benefit-cost analysis, break-even,
estimation techniques as a named discipline.

**Severity.** **P3**. Low because PMBOK shadow-covers most of this.
Pass-1 severity holds.

**Recommended fix.** Add V4 ch. 15 as secondary anchor in
`project-manager.md`. Add business-case + estimation-method mention
to `docs/templates/phase-template.md` gate-review section.

`[pass-2b] **Severity upgraded to P2.**` Body read of Ch. 15
shows the PMBOK-overlap assumption was too generous. PMBOK does
not cover: (1) MARR / IRR as *decision thresholds* for project
acceptance; (2) time-value-of-money mechanics (PW / FW / AE /
equivalence) as the basis for comparing technical alternatives;
(3) V4's seven-step engineering-decision process;
(4) decision-under-risk vs. decision-under-uncertainty technique
families (Laplace / Maximin / Maximax / Hurwicz / Minimax Regret);
(5) replacement-decision framing with sunk cost + salvage value;
(6) intangible-asset valuation cross-referenced to SFIA. These
are SWEBOK-distinct content. The fix should escalate accordingly:
cite ch. 15 as a first-class secondary anchor for
`project-manager.md` (not just a footnote), and require
build-vs-buy / refactor-vs-rewrite / architecture-tradeoff
decisions to produce a ch.15-shaped decision record. See §6.2.

---

### §2.8 New gap surfaced by pass-2 — Supplier / Cloud-Services management

**Source (.txt):** ch. 6 §2.1.2 Supplier Management (.txt 7877–7900);
ch. 7 §2.2.4 Supplier Management (TOC line 483).

V4 names supplier management explicitly in both Operations (ch. 6)
and Maintenance (ch. 7). With IaaS/PaaS/SaaS dependencies, this is a
non-trivial responsibility. No agent currently owns vendor/supplier
management as a named discipline. **P3** — add to `project-manager.md`
responsibilities or create a routing rule; recommend not a new agent.

---

### §2.9 New gap surfaced by pass-2 — ISO/IEC 27001:2022 ISMS reference not in glossary

**Source (.txt):** ch. 13 §2.2 (.txt 13560–13579) explicitly names
ISO/IEC 27001:2022 as the ISMS reference standard. Our
`docs/glossary/ENGINEERING.md` and taxonomy reference SWEBOK, IEEE
1028, 12207, 29148, 42010 — but not 27001. If §2.1 (security agent)
is adopted, 27001 needs to be cited. **P3** follow-on.

---

## §3 Citation drift in the repo

Direct comparison of "SWEBOK v3" references in the repo against V4's
current chapter numbering:

| File:line | Current cite | V4 correct cite | Severity |
|---|---|---|---|
| `.claude/agents/architect.md:8` | "SWEBOK v3 KA 'Software Design'" | SWEBOK V4 ch. 2 'Software Architecture' (primary; §1–§4, PDF pp. 2-1 ff.) + ch. 3 'Software Design' (secondary; §1.4 principles, §3 qualities, §4 recording, PDF pp. 3-1 ff.) `[pass-2b]` | P3 |
| `.claude/agents/sre.md:8` | "Canonical role §2.3" (taxonomy-only, no SWEBOK cite) | Should additionally cite V4 ch. 6 'Software Engineering Operations' §§2, 4 | P2 |
| `.claude/agents/release-engineer.md:8` | "Canonical role §2.8" (taxonomy-only) | Should additionally cite V4 ch. 6 §3 'Operations Delivery' + ch. 8 'Software Configuration Management' | P2 |
| `.claude/agents/software-engineer.md` | (cites Construction) | Add V4 ch. 7 'Software Maintenance' as secondary if widened per §2.6 | P2 |
| `.claude/agents/qa-engineer.md` | (cites Testing + Quality) | Add reference to V4 ch. 5 §7 for ML testing — cite the three-aspect framework (conditions / items / activities) and cross-reference ch. 16 §9.6 "AI for SE" for AI-assisted testing `[pass-2b]` | P3 |
| `.claude/agents/code-reviewer.md` | IEEE 1028-2008 | OK — not drift; ch. 12 §3.4.5 reaffirms technical reviews / audits | — |
| `SW_DEV_ROLE_TAXONOMY.md:30–35` | Source-authority tier names SWEBOK v3 | Replace with SWEBOK V4 (keeping v3 as historical reference) | P2 |
| `SW_DEV_ROLE_TAXONOMY.md` §2.4a | v3 KA "Software Design" | V4 KA "Software Architecture" (ch. 2) | P3 |
| `SW_DEV_ROLE_TAXONOMY.md` §2.1 | v3 KA "Software Construction" | V4 KA "Software Construction" (ch. 4) — chapter-number update only | P3 |
| `CLAUDE.md` glossary + hard-rules sections | SWEBOK cited generally | Add "V4 (2025)" as current reference version | P3 |

Not drift but missing: no file references **V4 ch. 13 Software
Security** or **V4 ch. 14 Professional Practice** anywhere.

---

## §4 Recommended roster / doc changes

**P1 (blocking on first security-sensitive work):**
1. Create `.claude/agents/security-engineer.md` (or policy decision:
   use per-project `sme-security.md`). Owner of V4 ch. 13. Add hard
   rule in CLAUDE.md. (§2.1)
2. Add `docs/templates/operations-plan-template.md` shaped after V4
   ch. 6. (§2.2)

**P2 (do before next project scaffold):**
3. Widen `sre.md` to cite V4 ch. 6 primary-anchor and add CONOPS /
   capacity / DR responsibilities. (§2.2)
4. Widen `release-engineer.md` to cite V4 ch. 6 §3 and name IaC/PaC
   explicitly. (§2.2)
5. Add Professional-Practice binding to
   `docs/glossary/ENGINEERING.md`: IEEE CS/ACM 1999 SE Code of Ethics
   + IEEE Code of Ethics 2020. (§2.3)
6. Widen `software-engineer.md` to cite V4 ch. 7 (Maintenance) as
   secondary anchor; add technical-debt tracking to
   `project-manager.md`. (§2.6)
7. Update `SW_DEV_ROLE_TAXONOMY.md` source-authority table to name
   SWEBOK V4 as current (keep v3 listed as historical). (§3)

**P3 (bundle into next template version bump):**
8. Update `architect.md` to cite V4 ch. 2 + ch. 3. (§2.4)
9. ML-testing note in `qa-engineer.md` citing V4 ch. 5 §7. (§2.5)
10. Economics / business-case addition to `project-manager.md` citing
    V4 ch. 15. (§2.7)
11. Supplier-management responsibility in `project-manager.md`
    citing V4 ch. 6 §2.1.2 + ch. 7 §2.2.4. (§2.8)
12. ISO/IEC 27001:2022 glossary entry. (§2.9)
13. Sweep all `SW_DEV_ROLE_TAXONOMY.md` KA references to cite V4
    chapter numbers. (§3)

Nothing in this section is an edit instruction — `tech-lead` +
`architect` to triage and dispatch.

---

## §5 Sources — .txt line ranges read, with PDF-page cross-reference

All from **LIB-0002** (SWEBOK Guide V4.0a, IEEE CS 2025, ed.
Washizaki). .txt file:
`/home/quackdcs/SWEProj/docs/library/local/swebok-v4.txt`, 21,342
lines, extracted from the PDF with `pdftotext -layout`.

| .txt lines | Content | PDF page(s) |
|---|---|---|
| 1–68 | Title / colophon / copyright / staff | i–iv |
| 69–1014 | Table of Contents (full, all 18 chapters + appendices A, B) | v–xxiv |
| 1100–1199 | Forewords (V4 intro, 2014 intro, 2004 intro) | xxv–xxvii |
| 7500–7520 | End of ch. 5 References; start of ch. 6 title page | 5-33, 6-1 |
| 7522–7610 | Ch. 6 Acronyms + Intro + Figure 6.1 breakdown | 6-1 to 6-2 |
| 7612–7700 | Ch. 6 §1 Fundamentals, Operations Engineer vs SWE roles, Platform Eng vs SRE | 6-3 to 6-4 |
| 7700–7800 | Ch. 6 §2.1 Operations Plan + Supplier Mgmt; §1.3 Installation; §1.4 Scripting; §1.5 Testing/Troubleshooting | 6-4 to 6-6 |
| 7800–7900 | Ch. 6 §2 Planning in full; §2.1.1 CONOPS; §2.1.2 Supplier Mgmt | 6-6 to 6-8 |
| 7900–8000 | Ch. 6 §2.2–§2.6 Environments, Availability/Continuity, Capacity, Backup/DR, Safety/Security/DevSecOps | 6-8 to 6-10 |
| 8000–8080 | Ch. 6 §3 Operations Delivery (Testing/V&V, Deployment/Release, Rollback, Problem Resolution) | 6-10 to 6-11 |
| 13500–13580 | Ch. 13 Security: Figure 13.1 breakdown; Cybersecurity; Security Mgmt & Org; CMM; ISMS (ISO/IEC 27001:2022) | 13-1 to 13-3 |
| 13942–14010 | Ch. 14 Professional Practice: Acronyms, Intro, Figure 14.1 breakdown | 14-1 to 14-2 |
| 14100–14200 | Ch. 14 §1.1 Accreditation/Cert/Licensing (ISO/IEC 24773-4); §1.2 Codes of Ethics (ACM 2018, IEEE 2020, IFIP 2021, IEEE CS/ACM 1999); §1.3 Professional Societies; §1.4 Standards; §1.5 Economic Impact; §1.6 Employment Contracts | 14-3 to 14-5 |

No web fetches were performed for factual claims in this pass. The
IEEE CS landing page and Wikipedia references from pass 1 were
superseded by the source text.

---

## §6 Targeted re-read addenda (2026-04-23, pass-2b)

Five chapters sampled at TOC-only during pass-2 were re-read at body
level per customer request. Findings and P-level movements recorded
here; inline edits in §2.x and §3 are tagged `[pass-2b]`.

### §6.1 Ch. 7 Software Maintenance — body read

**.txt lines read:** 8380–8800 (Figure 7.1 breakdown; §1.1–§1.6
Fundamentals incl. Categories; §2.1.1–§2.1.4 Technical Issues; §2.2.1
Alignment with Org Objectives; §2.2.2 Staffing; §2.2.3 Process;
§2.2.4 Supplier Management; §2.2.5 Organizational Aspects of
Maintenance; start of §2.3 Costs / Technical Debt). PDF pp. 7-2
through 7-9.

**Scope paraphrase.**
- Anchor standard: ISO/IEC/IEEE 14764 (named at PDF p. 7-2).
- Categories (per Figure 7.2, PDF p. 7-4): six — **corrective,
  preventive, adaptive, additive, perfective, emergency**. V4 adds
  *additive* (new functions/features at relatively large scope) as
  distinct from *perfective* (enhancement/refactor/doc improvement);
  *emergency* is flagged as unscheduled interim to corrective. This
  is wider than the classic four-category (corrective/adaptive/
  perfective/preventive) model that pass-2 cited from the TOC.
- **Ownership guidance — explicitly in-scope.** §2.2.5
  "Organizational Aspects of Maintenance" (PDF p. 7-9) names the
  two canonical arrangements: **Agile / single-team model** (the
  developer is also the maintainer) and **separate maintenance
  function** (different team takes over in operation). V4 lists
  pros and cons of each (knowledge loss, staff morale,
  documentation quality, handoff friction) and concludes the
  decision "should be made on a case-by-case basis." It further
  requires the organization to "delegate the maintenance tasks to
  an experienced group or person and keep quality documentation."
- §2.2.2 Staffing: names maintainer morale, staff turnover, and
  "recognizing and valuing the contribution of maintainers" as
  explicit management concerns.
- §2.2.4 Supplier Management: names outsourcing models
  (single-source, multi-sourcing, XaaS) and requires SLA and
  communications infrastructure.
- Technical debt: §2.1.4 Maintainability and §2.3.1 "Technical Debt
  Cost Estimation" (start visible at PDF p. 7-9). V4 requires three
  investigation areas (code quality vs. relevance, alignment with
  org objectives, process loss), named explicitly.
- Relation to Ch. 6 Operations: §1.2 (PDF p. 7-2) says maintenance
  "shares knowledge and tools with software development and
  software operation and also has its own processes and
  techniques." Maintenance is distinct from Operations but overlaps;
  V4 does not merge them.

**Audit movement.** The pass-2 §2.6 finding ("Missing ownership,
P2") **survives and strengthens**. V4 ch. 7 §2.2.5 does **not**
pick one ownership model — it names both and leaves the choice to
the organization. So our gap is not "V4 says X and we do Y"; it is
"V4 requires the organization to *pick one and document it*, and
our roster has no agent picking or documenting." Severity stays
**P2**; the recommended fix should be reframed:

- Not just "widen `software-engineer.md` to cite ch. 7" but
  additionally **require the project to record its maintenance
  arrangement** (single-team vs. separate) as a `CUSTOMER_NOTES.md`
  decision at project start, per V4 ch. 7 §2.2.5.
- Update category taxonomy in any maintenance template to six
  categories (corrective / preventive / adaptive / **additive** /
  perfective / emergency) to match V4, not the classic four.

### §6.2 Ch. 15 Software Engineering Economics — body read

**.txt lines read:** 14733–15300 (Intro; §1 Fundamentals §1.1
Proposals through §1.8 Business Model; §2 Engineering Decision-
Making Process §2.1–§2.7; §3 For-Profit Decision-Making §3.1–§3.4;
partial §3 continuation). PDF pp. 15-1 through 15-9.

**Scope paraphrase.**
- V4 defines engineering economics as "applied microeconomics" and
  "the science of choice, not the science of money" (PDF p. 15-1).
- §1 Fundamentals adds: **Proposals** (a single course of action;
  binary choice), **Cash Flow** (instance + stream + diagram),
  **Time-Value of Money**, **Equivalence**, **Bases for Comparison**
  (present worth, future worth, annual equivalent, IRR, discounted
  payback), **Alternatives** (including the **do-nothing
  alternative** as a standard consideration), **Intangible Assets**
  (explicitly citing SFIA category Strategy and Architecture —
  subcategory Business strategy and planning, for valuation and
  knowledge management), and **Business Model** (Drucker's four
  questions).
- §2 Engineering Decision-Making Process: a seven-step
  **decision-making process** (process overview → understand the
  real problem via 5-Whys → identify all reasonable technically
  feasible solutions → define selection criteria → evaluate each
  alternative → select preferred alternative → monitor
  performance). §2.6 names **decision-under-risk** techniques
  (expected value, Monte Carlo, decision trees) and
  **decision-under-uncertainty** techniques (Laplace, Maximin,
  Maximax, Hurwicz, Minimax Regret).
- §3 For-Profit Decision-Making: **MARR** (Minimum Acceptable Rate
  of Return) as opportunity cost; Economic Life / minimum-cost
  lifetime; Planning Horizon; Replacement Decisions (sunk cost,
  salvage value).
- TOC confirms further sections (nonprofit, present economy,
  multiple-attribute, intangibles identification, estimation,
  practical considerations / business case / multi-currency /
  systems thinking) on PDF pp. 15-10 through 15-22. Not read at
  body level.

**PMBOK overlap assessment (customer's specific question).**
- **PMBOK covers** generic cost management (plan/estimate/budget/
  control costs, EVM, earned-value performance), risk analysis
  structure, and stakeholder/value considerations.
- **PMBOK does not cover (or covers only generically)** what V4
  ch. 15 calls out as distinct engineering-economics content:
  1. MARR and IRR as *decision criteria* (PMBOK discusses cost
     control, not project-acceptance investment thresholds).
  2. Time-value-of-money mechanics (present worth / future worth /
     equivalence) as the *basis for comparison* between technical
     alternatives.
  3. The seven-step engineering decision-making process (PMBOK's
     decision-making lives in procurement and change control, not
     as a named engineering-economic discipline).
  4. Decision-making-under-risk vs. under-uncertainty
     (Laplace / Maximin / Hurwicz / Minimax Regret are not PMBOK
     content).
  5. Replacement decisions with sunk cost + salvage value framing.
  6. Intangible-asset valuation linked to business model
     (cross-referenced to SFIA, not PMBOK).
  7. Engineering-economic treatment of "do-nothing alternative" as
     standard.

**Audit movement.** Pass-2 §2.7 had this at **P3** on the grounds
that PMBOK shadow-covers most of it. Deeper read shows the overlap
is thinner than assumed — items 1, 2, 3, 4, 6 above are
not-shadowed by PMBOK and are distinctive SWEBOK V4 content.
**Movement: P3 → P2.** Narrow upgrade; the gap is "project-manager
currently cites PMBOK only and will not produce engineering-
economic analyses on decisions like build-vs-buy, refactor-vs-
rewrite, or architecture-tradeoff selection." Tagged
`[pass-2b]` in §2.7 and §3.

### §6.3 Ch. 2 Architecture + Ch. 3 Design — intro/§1 read

**.txt lines read:** Ch. 2 lines 3103–3200 (Acronyms, Introduction,
Breakdown section header); 3200–3500 sampled for §1 Fundamentals
and §2 Description through §3 Process. PDF pp. 2-1 through 2-11.
Ch. 3 lines 3918–4090 (Acronyms, Introduction, Breakdown, §1.1
Design Thinking through §1.4 Design Principles). PDF pp. 3-1
through 3-5.

**Ch. 2 scope paraphrase.**
- Ch. 2 intro (PDF p. 2-1, .txt ~3134): V4 "creates a software
  architecture knowledge area, separate from the Software Design
  KA, because of the significant interest and growth of the
  discipline since the 1990s."
- §1 Fundamentals (5 sub-topics): The Senses of Architecture
  (discipline / process / outcome), Stakeholders and Concerns,
  Uses of Architecture. §1.1 explicitly says software architecture
  "is also considered part of Software Design; generally considered
  a multistage process" of architectural → high-level → detailed
  stages; "this chapter focuses on architecting and architectural
  design."
- §2 Architecture Description (PDF p. 2-4 onwards): views /
  viewpoints per ISO/IEC/IEEE 42010; architectural styles &
  patterns; reference architectures; ADLs + frameworks (AUTOSAR,
  UAF, RM-ODP); "architecture as significant decisions" with ADR
  and architectural technical debt.
- §3 Software Architecture Process: architecture in context;
  architectural design (analysis / synthesis / evaluation); Architecting
  in the Large.
- §4 Software Architecture Evaluation: "Goodness"; Reasoning about
  Architectures; Reviews (incl. ATAM / SAAM / QAW).

**Ch. 3 scope paraphrase.**
- Intro (PDF p. 3-1, .txt ~3952): Design has three stages —
  architectural design, high-level design, detailed design —
  where "architectural design is a part of architecting, discussed
  in the Software Architecture KA." Design uses the term in four
  senses: discipline / processes / result / life-cycle stage.
- §1 Fundamentals (§1.1 Design Thinking, §1.2 Context, §1.3 Key
  Issues, §1.4 Software Design Principles — abstraction,
  separation of concerns, modularization, encapsulation / info
  hiding, separation of interface from implementation, coupling,
  cohesion, uniformity, completeness, verifiability).
- §2 Design Processes: high-level design, detailed design.
- §3 Design Qualities: concurrency, control/event handling, data
  persistence, distribution, errors/exception/fault tolerance,
  integration/interoperability, assurance/security/safety,
  variability.
- §4 Recording Designs (MBD, structural descriptions, behavioral
  descriptions, patterns, DSLs, rationale).
- §5 Strategies and Methods (function-oriented / data-centered /
  OO / user-centered / component-based / event-driven / AOP /
  constraint-based / domain-driven).
- §6 Analysis and Evaluation.

**Division of labour (important for our architect agent).** V4
explicitly says: Ch. 2 owns *architectural design* and architecting
as a discipline; Ch. 3 owns *high-level* and *detailed* design
stages, design principles, design qualities, recording, strategies.
Ch. 3's §1 begins by delegating architectural design to Ch. 2.

**Audit movement.** Pass-2 §2.4 called this P3 "wording drift
only." Body read confirms that: our `architect.md` scope covers
what V4 calls architecture. Severity stays **P3**. Precise citation
fix for `architect.md`:

- Primary anchor: **SWEBOK V4 Ch. 2 Software Architecture** (PDF
  pp. 2-1 ff.), specifically §1 Fundamentals, §2 Description, §3
  Process, §4 Evaluation.
- Secondary anchor: **SWEBOK V4 Ch. 3 Software Design** (PDF pp.
  3-1 ff.), specifically §1.4 Design Principles, §3 Design
  Qualities, §4 Recording Designs.

Tagged `[pass-2b]` in §2.4 and in §3 row for `architect.md:8`.

### §6.4 Ch. 5 §7 — ML testing (and ML for testing) — body read

**.txt lines read:** 7100–7240 (§7 Testing of and Testing Through
Emerging Technologies; §7.1 Testing of Emerging Technologies incl.
AI/ML/DL, blockchain, cloud, concurrent/distributed; §7.2 Testing
Through Emerging Technologies incl. ML for testing, blockchain for
testing, cloud for testing, simulation / HIL, crowdsourcing). PDF
pp. 5-26 through 5-29.

**Scope paraphrase.**
- §7 exists and is clearly labeled. It distinguishes testing **of**
  emerging tech (subject-under-test uses AI/ML/blockchain/cloud)
  from testing **through** emerging tech (using AI/ML/blockchain/
  cloud/simulation/crowdsourcing as means of testing).
- §7.1 ML testing names three aspects to consider: **required
  conditions** (correctness, robustness, security, privacy); **the
  ML/DL items** (bug may live in data, in the learning program, or
  in the framework); **the testing activities** (test-case
  generation, **test-oracle identification**, test-case adequacy
  criteria). Offline (cross-validation) + online (post-deployment,
  analyzing generated data) testing named.
- §7.2 names the use of ML in test design, the **test-oracle
  problem**, test-case evaluation, prioritization, mutation testing
  automation. Explicitly: "From a DevOps perspective, AI/ML/DL
  solutions can be used in SUT automation authoring and execution
  phases of test cases."

**Audit movement.** Pass-2 §2.5 had this at P3 (revised down from
P2). Body confirms §7 is concrete and substantive — three-aspect
framework, oracle problem, offline-vs-online split are concrete
guidance that a QA process can adopt. Severity stays **P3** for
roster scope (we don't build ML systems today) but pass-2b
strengthens the recommended fix: when `qa-engineer.md` gets the
ML-testing note, cite the three-aspect framework (conditions /
items / activities) rather than just "see V4 ch. 5 §7."

Tagged `[pass-2b]` in §2.5.

### §6.5 Ch. 16 §9 — AI/ML foundations — body read

**.txt lines read:** 17340–17490 (§9 Artificial Intelligence and
Machine Learning intro; §9.1 Reasoning; §9.2 Learning; §9.3
Models; §9.4 Perception and Problem-Solving; §9.5 Natural Language
Processing; §9.6 AI and Software Engineering). PDF pp. 16-25
through 16-28.

**Scope paraphrase.**
- §9 is positioned as foundational ("Computing Foundations KA"),
  not operational. Gives definitions of AI / ML / DL and an
  ideal-AI framing (indistinguishable from human).
- §9.1 Reasoning: deductive, inductive, abductive, common-sense,
  monotonic, non-monotonic, plus metalevel / procedural numeric /
  formal.
- §9.2 Learning: supervised, unsupervised, semi-supervised,
  reinforcement, plus dimensionality-reduction / self-learning /
  feature-learning / sparse-learning / anomaly-detection / robot
  learning.
- §9.3 Models: Linear Regression, Logistic Regression, ANN,
  Decision Tree, Naïve Bayes, SVM, Random Forest, plus LDA / LVQ /
  KNN.
- §9.4 Perception & Problem-Solving: Type I (narrow task),
  Type II (reactive), Type III (self-aware); sensor-data
  pipeline.
- §9.5 NLP: voice, slang, pronunciation awareness.
- **§9.6 AI and Software Engineering — the section most directly
  relevant to our roster.** Names two directions:
  - **AI for SE** — using AI/ML/DL *within* SE activities
    (defect prediction, test-case generation, vulnerability
    analysis, process assessment). "Aims to establish efficient
    ways of building high-quality software systems by replicating
    human developers' behavior" (PDF p. 16-28).
  - **SE for AI** — the engineering of AI systems themselves.
    Called out as requiring "interdisciplinary collaborative teams
    of data scientists and software engineers, software evolution
    focusing on large and changing datasets, and ethics and equity
    requirements engineering." ML software design patterns named
    as an emerging formalization.

**Audit movement.** Pass-2 §2.5 confirmed location of §9 from the
TOC but not the content. Body read confirms §9 is a **foundations
chapter**, not a methods chapter — it gives software engineers
vocabulary (types of reasoning, types of learning, types of
models) rather than prescriptive process. Severity stays **P3**:
V4 does not demand a "ML-engineer" role; it demands vocabulary
awareness across the roster. However, §9.6 "AI for SE" is a hook
that could meaningfully affect `qa-engineer.md` (defect prediction
/ test generation) and `code-reviewer.md` (vulnerability analysis)
even without building an ML system, by using ML-assisted tooling.
Recommended fix refinement: the ML-testing note in `qa-engineer.md`
(§2.5) should cross-reference §9.6 "AI for SE" so the direction
(AI-assisted tooling for testing) is on the agent's radar even in
non-ML-SUT projects.

Tagged `[pass-2b]` in §2.5.

### §6.6 Summary of P-level movements

| Section | Before | After | Direction |
|---|---|---|---|
| §2.4 Architecture split | P3 | P3 | unchanged; citation precision added |
| §2.5 AI/ML integration | P3 | P3 | unchanged; fix tightened (three-aspect ML-testing framework + AI-for-SE hook) |
| §2.6 Maintenance ownership | P2 | P2 | **survives**; fix reframed — V4 requires the project to *choose and document* ownership, not just assign it |
| §2.7 Economics | P3 | **P2** | **upgraded**; PMBOK shadow-coverage narrower than pass-2 assumed (MARR, time-value, decision-under-risk/-uncertainty, replacement decisions, intangible-asset valuation are SWEBOK-only) |
| §6.1 Ch. 7 six-category taxonomy | (new) | informational | additive + emergency added vs. classic four-category model |

### §6.7 Maintenance ownership — does the gap survive?

**Yes.** V4 ch. 7 §2.2.5 does not legislate one ownership model; it
names two (single-team-agile vs. separate-maintenance-function),
lists pros and cons of each, and requires the organization to
choose and document. Our roster has no agent choosing or
documenting this. The pass-2 P2 finding stands; the pass-2b fix
adds "record the maintenance arrangement in `CUSTOMER_NOTES.md` at
project start" as a concrete artefact.

