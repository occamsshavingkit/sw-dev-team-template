# Software Development Role Taxonomy — External Benchmark Reference

<!-- TOC -->

- [§1 Methodology + source list](#1-methodology--source-list)
  - [Retrieval strategy](#retrieval-strategy)
  - [Source-authority tiers](#source-authority-tiers)
  - [Global sources](#global-sources)
- [§2 Per-role canonical definitions](#2-per-role-canonical-definitions)
  - [2.1 Software engineer / developer (implementation)](#21-software-engineer--developer-implementation)
  - [2.2 QA engineer / test engineer (quality assurance)](#22-qa-engineer--test-engineer-quality-assurance)
  - [2.3 Site reliability engineer / performance engineer (production behavior, optimization)](#23-site-reliability-engineer--performance-engineer-production-behavior-optimization)
    - [2.3a Site Reliability Engineer (SRE)](#23a-site-reliability-engineer-sre)
    - [2.3b Performance engineer](#23b-performance-engineer)
  - [2.4 Software architect / technical lead (structural decisions)](#24-software-architect--technical-lead-structural-decisions)
    - [2.4a Software architect](#24a-software-architect)
    - [2.4b Tech lead (technical lead within a delivery team)](#24b-tech-lead-technical-lead-within-a-delivery-team)
  - [2.4c Security engineer (software security ownership)](#24c-security-engineer-software-security-ownership)
  - [2.5 Technical writer / documentation engineer (prose artifacts)](#25-technical-writer--documentation-engineer-prose-artifacts)
  - [2.6 Domain SME / principal engineer (domain authority)](#26-domain-sme--principal-engineer-domain-authority)
  - [2.7 Code reviewer / auditor (drift detection, traceability)](#27-code-reviewer--auditor-drift-detection-traceability)
  - [2.8 Release engineer / build engineer (build-infra, toolchain)](#28-release-engineer--build-engineer-build-infra-toolchain)
  - [2.9 Product / project planner (scope, phase planning, where distinct from architect)](#29-product--project-planner-scope-phase-planning-where-distinct-from-architect)
- [§3 Cross-role boundary heatmap](#3-cross-role-boundary-heatmap)
  - [Key overlap / conflict zones](#key-overlap--conflict-zones)
  - [Industry-framework resolution patterns](#industry-framework-resolution-patterns)
- [§4 Mapping-crosswalk scaffold (per-project; populated downstream)](#4-mapping-crosswalk-scaffold-per-project-populated-downstream)
- [§5 Known gaps in this taxonomy](#5-known-gaps-in-this-taxonomy)

<!-- /TOC -->

**Purpose:** External benchmark reference for any audit of
`.claude/agents/*.md` against industry-canonical role definitions.
Provides those definitions for the SW-dev roles the template maps onto,
drawn from authoritative sources (IEEE/ISO/IEC standards, vendor-neutral
skills frameworks, body-of-knowledge guides).

**Status:** Binding reference (per `CLAUDE.md` § "Binding references").
Generic / industry-canonical role vocabulary — every agent and every human
contributor MUST use these role definitions in these senses.
**Maintained by:** `researcher` + `architect` + `tech-lead` consensus.
Disagreement is resolved by amending this file, not by diverging in practice.
**First retrieved:** 2026-04-18.
**Explicit non-goal:** mapping these canonical roles onto a specific
project's named teammates. That mapping is per-project audit output and
lives in the downstream project, not here. §4 is a scaffold only.

---

## §1 Methodology + source list

### Retrieval strategy
Web research 2026-04-18 targeting:
- Canonical BoK/standards bodies: SWEBOK (IEEE), ISO/IEC/IEEE 12207, IEEE 1028, PMI PMBOK, ISTQB.
- Vendor-neutral skills frameworks: SFIA v9.
- High-signal industry references: Google SRE book, Google Engineering Practices (eng-practices), staffeng.com (Will Larson).
- U.S. government taxonomy: BLS Occupational Outlook Handbook (OOH), O*NET.

For each canonical role below, cited sources are listed under "Sources" with
URL and retrieval date. Where sources disagree (architect scope, staff engineer
archetypes, QA-vs-SWE test ownership), disagreement is flagged in the
"Ambiguities" subsection — not resolved.

### Source-authority tiers
- **Tier-1 (standards/BoK)**: SWEBOK v3, ISO/IEC/IEEE 12207:2017, IEEE 1028-2008, PMBOK, ISTQB Foundation/Advanced syllabi, SFIA v9. Authoritative by publication.
- **Tier-2 (high-reputation vendor-neutral)**: Google SRE book (O'Reilly), Google eng-practices, staffeng.com, BLS OOH, Wikipedia for well-cross-referenced articles.
- **Tier-3 (industry-consensus community)**: InfoWorld, Atlassian blog, Thoughtworks, BMC, DevOpsSchool, Indeed. Useful for role-boundary discussion but not authoritative when disagreement exists.

Every canonical role below has at least one Tier-1 or Tier-2 citation. Tier-3
sources used only to characterize *ambiguities* (industry debate), not definitions.

### Global sources

| Source | URL | Retrieved |
|---|---|---|
| SWEBOK v3 Guide (IEEE CS) | https://www.computer.org/education/bodies-of-knowledge/software-engineering | 2026-04-18 |
| ISO/IEC/IEEE 12207:2017 | https://www.iso.org/standard/63712.html | 2026-04-18 |
| IEEE 1028-2008 Std for SW Reviews and Audits | https://standards.ieee.org/ieee/1028/4402/ | 2026-04-18 |
| SFIA v9 (Skills Framework for the Information Age) | https://sfia-online.org/en | 2026-04-18 |
| Google SRE Book | https://sre.google/books/ | 2026-04-18 |
| Google Engineering Practices — Code Review | https://google.github.io/eng-practices/review/ | 2026-04-18 |
| StaffEng (Will Larson) — Staff Archetypes | https://staffeng.com/guides/staff-archetypes/ | 2026-04-18 |
| PMI PMBOK Guide (reference) | https://www.pmi.org/ | 2026-04-18 |
| ISTQB Certified Tester Scheme | https://istqb.org/certifications/ | 2026-04-18 |
| Technical Writer — BLS OOH | https://www.bls.gov/ooh/media-and-communication/technical-writers.htm | 2026-04-18 |
| Performance Engineering — Wikipedia | https://en.wikipedia.org/wiki/Performance_engineering | 2026-04-18 |
| Release Engineering — Wikipedia | https://en.wikipedia.org/wiki/Release_engineering | 2026-04-18 |
| Site Reliability Engineering — Wikipedia | https://en.wikipedia.org/wiki/Site_reliability_engineering | 2026-04-18 |

---

## §2 Per-role canonical definitions

### 2.1 Software engineer / developer (implementation)

**Canonical definition.** SWEBOK v3 frames "software engineering" as a
discipline of 15 Knowledge Areas; the practitioner who owns the core
construction KA is the software engineer. The KA "Software Construction"
covers coding, verification, debugging, and integration — the implementation
core of the role. SWEBOK treats testing, design, requirements, and maintenance
as adjacent but separately-owned KAs.

**SFIA mapping.** SFIA v9 places this role under the "Development and
implementation" category, skill "Programming/Software Development," levels
typically 2–5 (Assist → Ensure) for regular engineers, 6+ for senior ICs.

**Canonical sub-responsibilities** (SWEBOK KA "Software Construction" +
ISO/IEC/IEEE 12207 Implementation Process):
- Translate design into working code
- Unit testing and construction-phase verification
- Debugging
- Integration of components
- Performance / reliability tuning *within the constructed unit*
- Technical-debt reduction within owned scope

**Ambiguities and industry debates.**
- **Test ownership**: SWEBOK places "Software Testing" as a distinct KA with its own practitioners (see §2.2), but industry practice splits between (a) "SWE writes tests, dedicated QA is separate" (common in SRE-influenced shops) and (b) "SWE writes unit tests, QA owns integration/system/acceptance" (common in enterprise). SWEBOK does not mandate either split.
- **Architect-vs-SWE scope**: SWEBOK KA "Software Design" is separate from "Software Construction." Whether one person owns both is organizational, not standardized. Some sources (see §2.4) treat architect as a distinct role; others treat it as a seniority level of SWE.
- **"Full-stack" or "DevOps" SWE**: modern practice often collapses SWE + release-engineer + operations into one role (DevOps). Not in SWEBOK v3 (2013-era), widely accepted in SFIA v9.

**Sources.**
- SWEBOK v3, Knowledge Area "Software Construction" — https://www.computer.org/education/bodies-of-knowledge/software-engineering (retrieved 2026-04-18).
- ISO/IEC/IEEE 12207:2017 "Implementation process" — https://www.iso.org/standard/63712.html (retrieved 2026-04-18).
- SFIA v9 skill "Programming/software development" — https://sfia-online.org/en (retrieved 2026-04-18).

---

### 2.2 QA engineer / test engineer (quality assurance)

**Canonical definition.** Two distinct but related industry roles:

- **Test engineer / tester** — per ISTQB Foundation-Level syllabus, a specialist
  in designing, executing, and reporting on tests. ISTQB's Certified Tester
  Scheme formalizes this role with tiered certifications: Foundation, Advanced
  (Test Analyst CTAL-TA, Test Manager CTAL-TM, Test Automation Engineer
  CTAL-TAE), and Specialist.

- **QA engineer** — broader-scope role owning *process-level* quality, not just
  test execution. Responsibilities include process evaluation, test-strategy
  design, coverage measurement, and quality-system management across the SDLC.

**SWEBOK mapping.** SWEBOK KA "Software Testing" (primary) and KA "Software
Quality" (broader). Testing KA scopes techniques, levels, measures; Quality KA
scopes process and culture.

**ISO/IEC mapping.** ISO/IEC/IEEE 12207:2017 "Verification process" and
"Validation process" are the life-cycle processes that QA/test engineers
execute.

**Canonical sub-responsibilities.**

Test engineer (ISTQB Foundation-Level):
- Test-case design from requirements and design
- Test execution and result recording
- Defect identification, isolation, reporting
- Regression test maintenance
- Test automation (CTAL-TAE adds: automation architecture, test-code maintenance)

QA engineer (ISTQB Advanced-Level Test Manager + SWEBOK KA "Software Quality"):
- Test strategy and planning
- Quality metrics definition and tracking
- Process audit and improvement
- Risk-based test prioritization
- Test team coordination (CTAL-TM)

**Ambiguities and industry debates.**
- **Tester vs QA** — industry often uses these interchangeably despite the
  distinct ISTQB definitions. Smaller shops may have one role covering both;
  larger shops separate.
- **SWE-write-their-own-tests**: Google-style engineering practices have SWEs
  write most unit and integration tests, with dedicated SETs (Software Engineer
  in Test) for framework and harness work. ISTQB's role model assumes a
  dedicated test function — these are compatible perspectives but yield
  different org charts.
- **QA vs SRE overlap**: in shops with mature SRE, production monitoring and
  reliability testing can shift from QA to SRE (see §2.3). Boundary is
  organization-specific.

**Sources.**
- ISTQB Certified Tester Scheme — https://istqb.org/certifications/ (retrieved 2026-04-18).
- ISTQB Advanced Level Test Manager (CTAL-TM) — https://istqb.org/certifications/certified-tester-advanced-level-test-manager/ (retrieved 2026-04-18).
- ISTQB Advanced Level Test Automation Engineer (CTAL-TAE) — https://istqb.org/certifications/certified-tester-advanced-level-test-automation-engineering-ctal-tae-v2-0/ (retrieved 2026-04-18).
- SWEBOK v3 KAs "Software Testing" and "Software Quality" — https://www.computer.org/education/bodies-of-knowledge/software-engineering (retrieved 2026-04-18).
- ISO/IEC/IEEE 12207:2017 "Verification" and "Validation" processes — https://www.iso.org/standard/63712.html (retrieved 2026-04-18).

---

### 2.3 Site reliability engineer / performance engineer (production behavior, optimization)

These are **two distinct industry roles** with partial overlap. This section
covers both under the canonical-role umbrella "production behavior and
optimization."

#### 2.3a Site Reliability Engineer (SRE)

**Canonical definition.** From Google's SRE book (Beyer et al., O'Reilly 2016),
the canonical source: "SRE is what happens when you ask a software engineer to
design an operations team." SRE is a specific *operations discipline* that
applies software-engineering practices to operational work.

**Canonical sub-responsibilities** (SRE book Part II "Principles" chapters 3–6):
- Service-level objective (SLO) definition and error-budget management
- System reliability, availability, and performance monitoring
- Change management and release operations
- Incident response, on-call, postmortem culture
- Capacity planning
- Automation to reduce manual toil (50%-toil-ceiling is a canonical SRE norm)
- Emergency response during production incidents

**SFIA mapping.** SFIA v9 skill "Availability management" + "Capacity
management" + "Release and deployment" — SRE spans multiple SFIA skills rather
than having a single dedicated entry.

**SWEBOK V4 mapping.** V4 introduces KA "Software Engineering
Operations" (ch. 6), split into three process groups: Operations
Planning (§2), Operations Delivery (§3), Operations Control (§4).
This template assigns **Planning + Control** to `sre` and
**Delivery** to `release-engineer`; DevSecOps is a three-way
handshake with `security-engineer`. V3 did not have this KA;
operations were implicit in KA "Software Maintenance."

#### 2.3b Performance engineer

**Canonical definition.** From Wikipedia "Performance engineering" (well
cross-referenced to academic sources): "systems engineering discipline that
encompasses the set of roles, skills, activities, practices, tools, and
deliverables applied at every phase of the systems development life cycle
which ensures that a solution will be designed, implemented, and operationally
supported to meet the non-functional requirements for performance."

**Canonical sub-responsibilities** (per Wikipedia + Gatling/Splunk industry references):
- Non-functional requirement elicitation (throughput, latency, scalability, efficiency)
- Performance test design and execution
- Profiling and bottleneck analysis
- Capacity modeling
- Performance tuning across architecture, code, and infrastructure
- Early-lifecycle performance budgeting (shift-left)

**SFIA mapping.** SFIA v9 skill "Performance testing" (PETE) and "Capacity
management" (CPMG), each typically at levels 4–5.

**Ambiguities and industry debates — SRE vs Performance Engineer.**

- **Lifecycle phase**: performance engineers traditionally engage *pre-release*
  (design/dev/test), SREs engage *post-release* (production operations).
  Shift-left practice compresses this distinction.
- **Operational responsibility**: SREs carry production pager; performance
  engineers traditionally do not. Some orgs merge the two; others keep strict
  separation.
- **Who owns performance budgets**: SREs own production SLOs; performance
  engineers own pre-production performance budgets. Friction is common when
  both exist.
- **"Perf eng ⊂ SRE" vs "Perf eng ⊄ SRE"**: no industry consensus. Some shops
  roll performance engineering into the SRE function; others keep a specialist
  perf-eng role; others eliminate the dedicated role and push performance work
  to SWEs and SREs.

**Sources.**
- Google SRE Book, Chapters 1 (Introduction), 3 (Embracing Risk), 4 (SLOs) — https://sre.google/sre-book/table-of-contents/ (retrieved 2026-04-18).
- SRE book preface — https://sre.google/sre-book/preface/ (retrieved 2026-04-18).
- Site reliability engineering — Wikipedia — https://en.wikipedia.org/wiki/Site_reliability_engineering (retrieved 2026-04-18).
- Performance engineering — Wikipedia — https://en.wikipedia.org/wiki/Performance_engineering (retrieved 2026-04-18).
- "What is an SRE?" — InfoWorld — https://www.infoworld.com/article/2257232/what-is-an-sre-the-vital-role-of-the-site-reliability-engineer.html (retrieved 2026-04-18) — Tier-3, used only for ambiguity characterization.

---

### 2.4 Software architect / technical lead (structural decisions)

**Canonical definition.** SWEBOK v3 treats architecture as part of KA "Software
Design" but names no specific role. Industry distinguishes at least three
adjacent roles whose scopes overlap and whose boundaries are strongly
organization-dependent:

- **Software architect** — owner of structural/system-design decisions and
  long-term technical strategy. Works above the individual-feature level.
- **Technical lead ("tech lead")** — owner of day-to-day engineering execution
  within a team. Embedded in delivery; focuses on implementation guidance,
  mentoring, sprint-level architecture.
- **Staff engineer** — senior IC *level* (not a single role), with multiple
  archetypes per staffeng.com.

#### 2.4a Software architect

Canonical sub-responsibilities (SWEBOK KA "Software Design" +
industry consensus):
- Define and communicate software architecture
- System-decomposition and component-interface design
- Cross-cutting concerns (security, data, integration patterns)
- Technology-stack and platform selection
- Long-term technical strategy
- Architecture review gatekeeping

#### 2.4b Tech lead (technical lead within a delivery team)

Canonical sub-responsibilities (industry consensus; Vendavo, Full
Scale). In this framework, `tech-lead.md` also carries orchestration
+ sole-human-interface duties not generic to the industry role —
see `CLAUDE.md` § "Escalation protocol" for that layer.
- Day-to-day team technical guidance
- Sprint-level design and code-review leadership
- Team mentoring and onboarding
- Delivery commitment at a team scope
- Partnership with PM/EM on planning

**Canonical sub-responsibilities — Staff Engineer** (staffeng.com "Staff
Archetypes"):
Four canonical archetypes per Will Larson:
- **Tech Lead** — partners with engineering manager to guide execution of a team.
- **Architect** — responsible for a critical technical domain's direction.
- **Solver** — deep dives into complex problems that don't fit team structures.
- **Right Hand** — extends executive leadership's reach on critical initiatives.

Staff-engineer is explicitly described on staffeng.com as "a level, not a
specific role" — a person at Staff level may be operating in any of the four
archetypes above.

**Ambiguities and industry debates.**
- **Architect vs Principal Engineer** — in many orgs these are peer roles with
  different emphases (architect = design authority; principal = broad
  technical leadership); in others they are synonyms or one is absent. No
  canonical resolution.
- **Tech Lead vs Staff Engineer Tech-Lead archetype** — staffeng.com
  acknowledges that "Tech Lead" can be a role at any senior level; the archetype
  naming clash is real.
- **Architect as IC vs management-track** — some orgs put architects on the
  management track; others maintain architect as a pure IC role. SFIA v9
  treats architecture as a skill applicable to any level 5+.
- **"Ivory tower" critique** — Thoughtworks-lineage practice and many agile
  shops reject detached architect roles, preferring embedded tech leads who
  own both design and execution. SWEBOK and SFIA are neutral on this debate.

**Sources.**
- SWEBOK v3 KA "Software Design" — https://www.computer.org/education/bodies-of-knowledge/software-engineering (retrieved 2026-04-18).
- StaffEng — Staff Archetypes (Will Larson) — https://staffeng.com/guides/staff-archetypes/ (retrieved 2026-04-18).
- StaffEng FAQ — https://staffeng.com/faq/ (retrieved 2026-04-18).
- Vendavo Engineering — "Technical Lead vs Software Architect" — https://engineering.vendavo.com/technical-lead-vs-software-architect-09621ec39f00 (retrieved 2026-04-18) — Tier-3, used for ambiguity characterization.
- SFIA v9 skills "Systems design" / "Solution architecture" — https://sfia-online.org/en (retrieved 2026-04-18).

---

### 2.4c Security engineer (software security ownership)

**Canonical definition.** Per SWEBOK V4 ch. 13 "Software Security" —
a Knowledge Area newly introduced in V4 (absent from SWEBOK v3, which
treated security as a cross-cutting concern with no named owner). The
security engineer owns the security engineering discipline as a
standalone role: threat modelling, security requirements,
SDL / DevSecOps coordination, vulnerability management, SBOM
stewardship, and security assurance.

SFIA v9 recognises adjacent skills (SCTY — Information Security,
VUAS — Vulnerability Assessment, SFEN — Security Engineering) but
does not package them under a single named role; SWEBOK V4 does.
Industry-common role names: *Application Security Engineer*
("AppSec Engineer"), *Product Security Engineer*, *DevSecOps
Engineer*, *Security Architect*. This taxonomy picks
`security-engineer` for naming consistency with `software-engineer`,
`release-engineer`, `qa-engineer`.

**Canonical sub-responsibilities** (SWEBOK V4 ch. 13 §§1–6):

- Security fundamentals and taxonomy stewardship.
- Security-requirements engineering (§4.1).
- Secure design (§4.2) and security patterns (§4.3), joint with the
  software architect.
- Construction controls and secure coding practices (§4.4),
  advisory to the software engineer and the code reviewer.
- Security testing plan (§4.5), joint with the QA engineer.
- Vulnerability management policy (§4.6) and SBOM stewardship.
- Security assurance case before release (shape per
  `docs/templates/security-template.md`, grounded in ISO/IEC
  15026-2:2022 — not a named SWEBOK sub-section); customer
  sign-off recorded by `tech-lead`.
- ML-security touchpoints (§6.3) and ML-testing coordination with
  QA (SWEBOK V4 ch. 5 §7).

**Scope boundary: standards discipline vs customer-domain
compliance.** The security engineer owns the standards-grounded
discipline (SWEBOK V4 ch. 13, ISO/IEC 27001:2022, NIST SSDF, OWASP
ASVS). Customer-domain regulatory interpretation (HIPAA / GDPR /
PCI-DSS / HITRUST / site-specific compliance) is `sme-<domain>`
territory or escalates to the customer via `tech-lead`. The
distinction mirrors the `researcher` vs `sme-<domain>` split from
the template glossary.

**Sources.**

- SWEBOK V4 ch. 13 "Software Security" — library row LIB-0002.
- ISO/IEC 27001:2022 — Information Security Management Systems.
- NIST SP 800-218 Secure Software Development Framework (SSDF).
- OWASP ASVS; CWE / CAPEC taxonomies.
- IEEE CS / ACM Software Engineering Code of Ethics (SWEBOK V4
  ch. 14 §1.7.6 Professional Liability).

### 2.5 Technical writer / documentation engineer (prose artifacts)

**Canonical definition.** Two distinct industry roles:

- **Technical writer** — per U.S. BLS Occupational Outlook Handbook (OOH,
  SOC 27-3042.00): "Technical writers, also called technical communicators,
  prepare instruction manuals, how-to guides, journal articles, and other
  supporting documents to communicate complex and technical information more
  easily." In software specifically: API docs, SDK docs, user manuals,
  platform docs.

- **Documentation engineer** — broader, more strategic role focused on
  *documentation-as-system*: knowledge-base orchestration, tooling, automation,
  and developer-experience for docs. Typically requires practical coding
  ability. Industry references (ClickHelp, Passo.uno) position doc eng as a
  role above senior tech writer, with team-orchestration scope.

**SFIA mapping.** SFIA v9 skill "Content authoring" (INCA) and "Information
content publishing" (ICPM) at levels 3–5.

**Canonical sub-responsibilities — Technical writer.**
- Gather information from SMEs and engineers
- Author user documentation, API references, how-to guides
- Maintain documentation for accuracy against shipping product
- Edit for clarity and consistency
- Use documentation tools (DITA, Markdown, AsciiDoc, MkDocs, Sphinx, etc.)

**Canonical sub-responsibilities — Documentation engineer.**
- Documentation-system architecture (docs-as-code pipelines, toolchain)
- Content strategy across product lines
- Style guide authoring and enforcement
- Automation (API-doc extraction, changelog generation, link-check)
- Coordination of a tech-writer team
- Developer-experience measurement for docs

**Ambiguities and industry debates.**
- **Writer-engineer collaboration model**: "writer embedded in eng team" vs
  "writer in marketing/comms" vs "writer in DX team" — different orgs place
  this role under different management chains.
- **Doc engineer vs senior tech writer**: industry sources (ClickHelp, Passo)
  position these as distinct; many orgs treat them as the same.
- **AI-generated docs**: emerging practice; no canonical consensus on whether
  this eliminates or transforms the role.

**Sources.**
- U.S. Bureau of Labor Statistics Occupational Outlook Handbook — "Technical Writers" — https://www.bls.gov/ooh/media-and-communication/technical-writers.htm (retrieved 2026-04-18).
- O*NET OnLine — 27-3042.00 Technical Writers — https://www.onetonline.org/link/summary/27-3042.00 (retrieved 2026-04-18).
- "Who Is a Documentation Engineer?" — ClickHelp blog — https://clickhelp.com/clickhelp-technical-writing-blog/who-is-a-documentation-engineer/ (retrieved 2026-04-18) — Tier-3.
- "Why I became a Documentation Engineer" — Passo.uno — https://passo.uno/what-is-a-documentation-engineer/ (retrieved 2026-04-18) — Tier-3.

---

### 2.6 Domain SME / principal engineer (domain authority)

**Canonical definition.** Per Wikipedia "Subject-matter expert" (cross-referenced
to multiple industry sources): "A subject-matter expert (SME) is a person who
has accumulated great expertise in a particular field or topic, which expertise
is reflected by the person's degree, licensure, and/or years' occupational
experience in the subject."

In software development specifically, two distinct flavors of SME:
- **Domain SME** — expert in the *problem domain* the software serves (e.g.,
  accounting, medicine, manufacturing, industrial automation). Often not a
  software engineer; advises the development team on domain correctness.
- **Technical SME / Principal Engineer** — expert in a *technical* domain
  within software (e.g., distributed systems, cryptography, compiler theory).
  Advises on correctness of technical decisions within that domain.

**Canonical sub-responsibilities — Domain SME** (per U.S. DOE definition and
Wikipedia):
- Define domain requirements and correctness criteria
- Review specifications and output for domain conformance
- Train and onboard development team on domain concepts
- Act as escalation oracle for domain questions
- Validate user-facing documentation
- Typically does not write code

**Canonical sub-responsibilities — Principal Engineer** (SFIA v9 + industry
consensus):
- Depth expertise in a technical specialty
- Research-and-evaluate novel approaches
- Technical authority within the specialty
- Cross-team consultation and review
- Mentorship of senior engineers
- Input to long-range technical strategy (shared with architects)

**Ambiguities and industry debates.**
- **SME terminology**: widely used but non-standardized. Wikipedia flags that
  "domain expert" and "SME" are often synonymous but "domain expert" more often
  implies non-software-engineering expertise whereas "SME" is broader.
- **Principal Engineer vs Architect** — see §2.4. These roles overlap heavily
  in many orgs.
- **SME authority scope**: whether SME rulings are binding or advisory is
  organization-specific. No standard framework mandates binding SME authority.
- **SME vs Tech Lead conflict**: when a domain SME disagrees with a tech lead's
  implementation choice, resolution is organization-specific (tech lead wins,
  SME wins, architect arbitrates, product owner decides).

**Sources.**
- Subject-matter expert — Wikipedia — https://en.wikipedia.org/wiki/Subject-matter_expert (retrieved 2026-04-18).
- U.S. Department of Energy definition of SME — https://www.directives.doe.gov/terms_definitions/subject-matter-expert-sme (retrieved 2026-04-18).
- "Subject Matter Expertise in Software Development" — Computools — https://computools.com/role-of-subject-matter-expert-in-business-software-development/ (retrieved 2026-04-18) — Tier-3.
- SFIA v9 skill "Specialist advice" (TECH) — https://sfia-online.org/en (retrieved 2026-04-18).

---

### 2.7 Code reviewer / auditor (drift detection, traceability)

**Canonical definition.** Two related but distinct industry roles / activities:

- **Code reviewer** — per Google Engineering Practices (Google eng-practices,
  publicly published): an engineer who reviews change-lists (CLs, pull
  requests, merge requests) for quality, correctness, and codebase-health
  impact before merge. In Google-style review, this is a rotating
  responsibility of all engineers rather than a fixed role.

- **Software auditor** — per IEEE 1028-2008 (IEEE Standard for Software
  Reviews and Audits): a role defined explicitly in the standard, assigned to
  evaluate software artifacts and processes against documented requirements,
  plans, and standards. Distinct from reviewer in both scope and authority.

**IEEE 1028 review taxonomy.** Five formal types:
1. **Management review** — monitors progress against plan, evaluates status.
2. **Technical review** — evaluates artifact against plan, specifications.
3. **Inspection** — formal defect-detection review with assigned roles
   (inspection leader, recorder, reader, author, inspector).
4. **Walk-through** — author-led informal review.
5. **Audit** — independent evaluation for conformance with requirements,
   plans, standards, contracts.

Auditors in IEEE 1028 audits must be independent of the product development
team — this is a binding standard-level requirement.

**Canonical sub-responsibilities — Code reviewer** (Google eng-practices):
- Review CL/PR within reasonable turnaround (Google guideline: ~1 business day)
- Assess functionality, complexity, tests, naming, style, comments,
  documentation, and design
- Balance "point out problems" vs "provide direct guidance" — Google prefers
  the former for learning
- Ensure overall codebase health does not decrease
- Own responsibility for code they approve

**Canonical sub-responsibilities — Auditor** (IEEE 1028-2008 §8):
- Independent evaluation of software products and processes
- Conformance check against contract, plans, standards, regulations
- Formal audit reporting: findings, classifications, recommendations
- Traceability assessment (do artifacts trace from requirements to code?)
- Drift / deviation detection between spec and implementation

**Ambiguities and industry debates.**
- **Reviewer independence requirement**: Google-style review treats every
  engineer as a potential reviewer of every change — no independence mandate.
  IEEE 1028 audits require independence. These are *different activities*,
  not a contradiction: routine code review ≠ audit.
- **Is code review a role?**: Google treats it as a rotating activity; other
  orgs designate specific senior engineers as "lead reviewers" for a codebase.
  Both patterns are industry-accepted.
- **Reviewer vs Approver**: some orgs separate "reviewer comments" from
  "approval authority" (e.g., CODEOWNERS in GitHub). SWEBOK and IEEE 1028 do
  not mandate this split.
- **Audit cadence**: IEEE 1028 does not mandate frequency — organizational.
- **Trust relationship**: whether auditor findings are binding or advisory is
  organization- and regulation-specific.

**Sources.**
- IEEE 1028-2008 Standard for Software Reviews and Audits — https://standards.ieee.org/ieee/1028/4402/ (retrieved 2026-04-18).
- IEEE 1028-2008 PDF (1997 predecessor) — http://profs.etsmtl.ca/claporte/english/enseignement/cmu_sqa/travaux/TP_Reviews/IEEE%201028-2002%20-%20Software%20Reviews.pdf (retrieved 2026-04-18).
- Google Engineering Practices — Code Review — https://google.github.io/eng-practices/review/ (retrieved 2026-04-18).
- Google Eng Practices — "The Standard of Code Review" — https://google.github.io/eng-practices/review/reviewer/standard.html (retrieved 2026-04-18).
- SWEBOK v3 KA "Software Quality" (which references review and audit as processes) — https://www.computer.org/education/bodies-of-knowledge/software-engineering (retrieved 2026-04-18).

---

### 2.8 Release engineer / build engineer (build-infra, toolchain)

**Canonical definition.** Per Wikipedia "Release engineering" (cross-referenced
to industry sources): "a sub-discipline in software engineering concerned with
the compilation, assembly, and delivery of source code into finished products
or other software components."

Industry distinguishes (with variable rigor) three related roles:

- **Build engineer** — owner of the build system, compilation pipeline,
  dependency management, and toolchain configuration.
- **Release engineer** — owner of the release pipeline end-to-end: tagging,
  packaging, deployment orchestration, release management, change control.
- **DevOps engineer** — broader scope: CI/CD platform, infrastructure-as-code,
  observability, shared tooling for multiple teams.

The three overlap heavily; in most contemporary orgs they collapse into one or
two roles, commonly labeled "DevOps engineer" or "platform engineer."

**SFIA mapping.** SFIA v9 skills "Systems integration" (SINT), "Release and
deployment" (RELM), "Configuration management" (CFMG), "Build management"
(BUMG) — release engineering spans multiple SFIA skills.

**SWEBOK V4 mapping.** V4 anchors release-engineer work in two KAs:
**Software Configuration Management** (ch. 8) — primary canonical
anchor — and **Software Engineering Operations** (ch. 6 §3
Operations Delivery) — the IaC / PaC, deployment pipeline, release
gating, and rollback automation responsibilities. Planning and
Control of operations (§§2, 4) live with `sre`.

**Canonical sub-responsibilities — Release engineer** (Wikipedia; industry
consensus):
- Build-pipeline architecture and maintenance
- Version control workflow (branching strategy, merge policy)
- Package assembly and artifact management
- Release tagging and changelog generation
- Deployment orchestration across environments
- Reproducibility of historical builds
- Compliance-evidence generation (SBOM, provenance, signing)

**Canonical sub-responsibilities — Build engineer** (industry; DevOpsSchool,
DistantJob):
- Build-tool configuration (Make, CMake, Bazel, setuptools, etc.)
- Dependency resolution and lock-file maintenance
- Compiler/toolchain version management
- Build-performance optimization
- Cross-platform build portability

**Canonical sub-responsibilities — DevOps engineer** (Atlassian, BMC):
- CI/CD pipeline end-to-end
- Infrastructure-as-code (Terraform, Pulumi, Ansible)
- Container orchestration (Kubernetes, etc.)
- Observability tooling
- Collaboration-platform ownership (GitHub Actions, GitLab CI, etc.)
- DORA metrics tracking (deploy freq, lead time, MTTR, change-fail rate)

**Ambiguities and industry debates.**
- **Collapse of roles**: modern practice often merges build + release + DevOps
  into one "DevOps engineer" or "platform engineer" role. Historical
  distinction per Wikipedia Release Engineering article is more rigorous than
  current practice.
- **"Platform engineer" rebrand**: some orgs have recently rebranded DevOps
  functions as "platform engineering" to emphasize internal-developer-platform
  product-orientation. No canonical standard resolves this terminology.
- **Release engineer vs SRE**: some production release duties overlap with SRE
  on-call. Split is org-specific.

**Sources.**
- Release engineering — Wikipedia — https://en.wikipedia.org/wiki/Release_engineering (retrieved 2026-04-18).
- "Build and Release Engineer vs DevOps Engineer" — DistantJob — https://distantjob.com/blog/build-and-release-engineer/ (retrieved 2026-04-18) — Tier-3.
- "What is a DevOps Engineer?" — Atlassian — https://www.atlassian.com/devops/what-is-devops/devops-engineer (retrieved 2026-04-18) — Tier-3.
- "DevOps Job Titles, Roles, & Responsibilities" — BMC — https://www.bmc.com/blogs/devops-titles-roles-responsibilities/ (retrieved 2026-04-18) — Tier-3.
- SFIA v9 skills RELM / BUMG / CFMG / SINT — https://sfia-online.org/en (retrieved 2026-04-18).

---

### 2.9 Product / project planner (scope, phase planning, where distinct from architect)

**Canonical definition.** Two distinct industry roles, neither of which is
SWE-technical:

- **Project manager** — per PMI PMBOK Guide: "the person assigned by the
  performing organization to lead the team that is responsible for achieving
  the project objectives." PM owns schedule, budget, scope, risk, stakeholder
  comms.

- **Product manager** — owner of *what to build* and *why*, often distinct
  from *how*. Owns product roadmap, feature prioritization, market/user
  research. PMBOK does not directly define this role; it is defined more by
  industry practice than standards.

**Distinction from software architect (§2.4).** Architect decides *how*, PM
decides *what* / *when*. In mature orgs these are separate individuals; in
smaller orgs one person can hold both.

**SFIA mapping.** SFIA v9 skills "Project management" (PRMG) and "Product
management" (PROD) are distinct, typically level 4+ for full ownership.

**Canonical sub-responsibilities — Project manager** (PMBOK):
- Project management plan creation and maintenance
- Scope, schedule, cost, quality, risk management
- Resource allocation and team coordination
- Stakeholder communication
- Change control
- Lessons-learned capture
- Risk management

**Canonical sub-responsibilities — Product manager** (industry consensus):
- Product vision and strategy
- Roadmap planning
- Requirement elicitation and prioritization (with users and stakeholders)
- Feature definition (what to build)
- Market research and competitive analysis
- Cross-functional alignment (eng, design, marketing)

**Ambiguities and industry debates.**
- **PM = Project or Product?** — the "PM" abbreviation overloaded across both
  roles causes frequent confusion. Explicitly disambiguating (PrM/Proj/PdM) is
  industry-variable.
- **Scrum Master vs Project Manager** — Agile practice often replaces the
  classical PM with a Scrum Master (facilitator, not accountable for delivery)
  + Product Owner (owns product backlog, not full product strategy). PMBOK
  6+ acknowledges agile approaches but retains PM as a role.
- **Planner vs Architect** — in some orgs the architect owns phase planning
  because structural decisions are phased. In others the PM owns phase
  planning because it's a schedule question. Organizational.
- **Standalone "planner" role**: rarely a distinct title outside defense,
  construction, and regulated industries. In commercial software typically
  subsumed under PM, product owner, or tech lead.

**Sources.**
- PMI PMBOK Guide (various editions, 6th/7th in current wide use) — https://www.pmi.org/ (retrieved 2026-04-18).
- "Duties of the Effective Project Manager" — PMI — https://www.pmi.org/learning/library/duties-effective-project-manager-5117 (retrieved 2026-04-18).
- "Project managers' responsibilities" — PMI — https://www.pmi.org/learning/library/strategy-alignment-management-of-projects-9935 (retrieved 2026-04-18).
- SFIA v9 skills PRMG (Project management) and PROD (Product management) — https://sfia-online.org/en (retrieved 2026-04-18).
- ISO/IEC/IEEE 12207:2017 "Project planning process" and "Project assessment and control process" — https://www.iso.org/standard/63712.html (retrieved 2026-04-18).

---

## §3 Cross-role boundary heatmap

Matrix of canonical-role pairs and common industry overlap / conflict zones.
Populated from §2 ambiguity sub-sections; shows where industry disagrees about
ownership.

**Legend:**
- **HIGH** overlap: roles routinely collapsed into one person or contest
  responsibility openly in industry debate.
- **MED** overlap: frequently overlap in some org structures; distinct in others.
- **LOW** overlap: distinct in almost all industry references; conflict rare.

| | SWE | QA/Test | SRE/Perf | Arch/TL | Tech Writer | SME | Reviewer | Release Eng | Planner |
|---|---|---|---|---|---|---|---|---|---|
| **SWE** | — | MED | MED | HIGH | LOW | LOW | HIGH | MED | LOW |
| **QA/Test** | MED | — | MED | LOW | LOW | LOW | MED | LOW | LOW |
| **SRE/Perf** | MED | MED | — | MED | LOW | LOW | LOW | HIGH | LOW |
| **Arch/TL** | HIGH | LOW | MED | — | LOW | MED | MED | MED | MED |
| **Tech Writer** | LOW | LOW | LOW | LOW | — | MED | LOW | LOW | LOW |
| **SME** | LOW | LOW | LOW | MED | MED | — | MED | LOW | MED |
| **Reviewer** | HIGH | MED | LOW | MED | LOW | MED | — | LOW | LOW |
| **Release Eng** | MED | LOW | HIGH | MED | LOW | LOW | LOW | — | MED |
| **Planner** | LOW | LOW | LOW | MED | LOW | MED | LOW | MED | — |

### Key overlap / conflict zones

**HIGH overlaps (most prone to organizational ambiguity):**

1. **SWE ↔ Architect/TL** — the "who owns design vs implementation" debate.
   Industry consensus: design/implementation are adjacent SWEBOK KAs; whether
   a role performs both is organizational. In smaller teams collapse is
   normal; in larger teams separation is normal.

2. **SWE ↔ Code Reviewer** — in Google-style practice every SWE is a reviewer;
   dedicated reviewer role is absent. In heavier-process shops a "lead
   reviewer" or CODEOWNERS designation exists. IEEE 1028 inspection roles are
   formal but rarely used in modern agile practice.

3. **SRE/Perf ↔ Release Engineer** — production release duties straddle both.
   Some orgs collapse all into "DevOps"; others maintain distinct SRE,
   release, and perf specialties.

**MED overlaps (frequently organization-dependent):**

4. **SWE ↔ QA/Test** — SWEs routinely write unit tests; dedicated QA/test
   engineers typically own integration/system/acceptance test. Split varies
   by shop.

5. **Architect ↔ SME / Principal Engineer** — architects own *software-side*
   design; principal engineers own *technical-domain* depth; domain SMEs own
   *problem-domain* expertise. Overlap on cross-cutting technical decisions
   that require both structural and deep-specialist judgment.

6. **Reviewer ↔ Auditor / SME** — under IEEE 1028, reviewer and auditor are
   separate roles; in practice a senior SME often acts as both routine
   reviewer and formal auditor for their domain.

7. **Planner ↔ Architect** — phase planning can be owned by either; no
   canonical rule. Depends on whether the phase boundary is driven by
   structural constraints (architect owns) or schedule constraints (PM owns).

**LOW overlaps (roles rarely confused):**

8. **Tech Writer ↔ almost anyone** — role is usually clearly distinct; closest
   overlap is with SME when the writer is embedded in eng team and develops
   domain depth.

9. **QA ↔ Architect** — these roles rarely overlap in industry references;
   QA/test is typically orthogonal to architectural ownership.

### Industry-framework resolution patterns

Where sources agree on resolution:
- **SWEBOK v3** treats all KAs as separate but silent on role-binding. Neutral.
- **ISO/IEC/IEEE 12207** defines *processes*, not roles, and explicitly
  allows organizations to bind processes to any role structure.
- **SFIA v9** treats skills and levels independently; a single person can hold
  multiple skills at different levels. Most pluralist of the frameworks.
- **PMBOK** is domain-focused on PM; silent on technical role boundaries.

Where sources disagree:
- **Google SRE book** advocates a clear SRE-vs-SWE separation with explicit
  error-budget contracts. Google eng-practices advocates SWE-owned code review.
  Together: Google's model clusters roles by *responsibility contract*, not by
  skill set.
- **StaffEng / Will Larson** explicitly rejects fixed role boundaries at Staff
  level, defining archetypes instead of roles.
- **Thoughtworks / agile-lineage practice** rejects detached architect and PM
  roles as anti-patterns in most modern contexts — preferring embedded tech
  leads and product owners.

**No framework resolves all boundaries.** The audit cannot rely on a single
framework; cross-referencing against multiple is load-bearing.

---

## §4 Mapping-crosswalk scaffold (per-project; populated downstream)

This table is a **scaffold**, not a populated mapping. It enumerates the
canonical roles defined in §2 and leaves a column for downstream projects
to fill in their own teammate names.

The right-most column ("Per-project teammate") is **not owned by the
upstream template**. Each downstream project records its mapping in
`docs/AGENT_NAMES.md` (per CLAUDE.md Step 3 — agent naming). A project
that keeps canonical role names leaves that column at the canonical role
file (e.g., `software-engineer`); a project that names its teammates
(Muppets, composers, etc.) records the chosen name there.

The first three columns are the binding upstream content: canonical
role identifier, primary standards source, and one-line responsibility
summary. Those do not change per project; they change only when this
taxonomy file changes.

| Canonical Role (§2) | Primary Source | Key Sub-responsibilities (one-line) | Per-project teammate (downstream fills) |
|---|---|---|---|
| 2.1 Software Engineer / Developer | SWEBOK v3 KA "Software Construction"; ISO 12207 Implementation process | Translate design → code; unit test; debug; integrate | *(downstream)* |
| 2.2a Test Engineer | ISTQB Foundation-Level | Design/execute tests; defect reporting; automation | *(downstream)* |
| 2.2b QA Engineer | ISTQB CTAL-TM; SWEBOK KA "Software Quality" | Test strategy; quality metrics; process improvement | *(downstream)* |
| 2.3a SRE | Google SRE Book | SLOs; error budgets; incident response; capacity | *(downstream)* |
| 2.3b Performance Engineer | Wikipedia Performance engineering; SFIA PETE | Non-functional requirements; perf test; profiling; tuning | *(downstream)* |
| 2.4a Software Architect | SWEBOK KA "Software Design" | System decomposition; long-term strategy; cross-cutting concerns | *(downstream)* |
| 2.4b Tech Lead | staffeng.com archetypes | Day-to-day team guidance; sprint design; mentoring | *(downstream)* |
| 2.4c Staff Engineer (archetype-based) | staffeng.com | Level, not role; 4 archetypes (TL/Arch/Solver/Right Hand) | *(downstream)* |
| 2.5a Technical Writer | BLS OOH 27-3042.00 | User docs; API refs; how-tos | *(downstream)* |
| 2.5b Documentation Engineer | ClickHelp/Passo (Tier-3 only) | Doc-system arch; toolchain; team coord | *(downstream)* |
| 2.6a Domain SME | Wikipedia SME; DOE definition | Domain oracle; requirement validation; correctness authority | *(downstream)* |
| 2.6b Principal Engineer | SFIA v9 "Specialist advice" | Depth in technical specialty; research; cross-team consult | *(downstream)* |
| 2.7a Code Reviewer | Google eng-practices | CL/PR review; codebase health; balance guide/correct | *(downstream)* |
| 2.7b Auditor | IEEE 1028-2008 §8 | Independent evaluation; conformance check; formal audit report | *(downstream)* |
| 2.8a Build Engineer | Wikipedia Release Engineering (inferred) | Build-system arch; toolchain; deps; compile-pipeline | *(downstream)* |
| 2.8b Release Engineer | Wikipedia Release Engineering | Release pipeline; tagging; packaging; reproducibility | *(downstream)* |
| 2.8c DevOps Engineer | Atlassian / BMC (Tier-3) | CI/CD; IaC; observability; DORA metrics | *(downstream)* |
| 2.9a Project Manager | PMI PMBOK | Schedule; budget; scope; risk; stakeholder comms | *(downstream)* |
| 2.9b Product Manager | Industry consensus (no Tier-1) | Vision; roadmap; prioritization; market research | *(downstream)* |

**Notes for downstream-project fill:**
- Canonical roles that are *levels* rather than *roles* (Staff Engineer per
  staffeng.com) may map to multiple project teammates or to none.
- Canonical roles with weak standards backing (Documentation Engineer, DevOps
  Engineer, Product Manager) should be weighted less authoritatively than
  Tier-1-source-backed roles.
- A downstream project may legitimately have one teammate spanning multiple
  canonical roles (e.g., a combined Planner + Architect). That is not a drift
  finding per se; the project's own audit should note whether the
  split/combination matches industry patterns and whether the agent's `.md`
  accurately describes the combined scope.
- Project-specific custom gates or roles that have no direct canonical-role
  parallel in the taxonomy above should be flagged as project-specific.
  Closest industry analogue for an adversarial-review gate is "devil's
  advocate review" under IEEE 1028 inspection (§2.7 "inspector" subset);
  closest analogue for a style/quality gate is the "design review" practice
  in SWEBOK KA "Software Design" plus the style-guide enforcement portion of
  §2.5b Documentation Engineer. If neither maps cleanly, treat the gate as
  project-specific rather than claiming canonical-role authority.

---

## §5 Known gaps in this taxonomy

Explicit flags for any downstream audit that uses this taxonomy as a
benchmark:

1. **No single industry framework covers all canonical roles.** SWEBOK covers
   core SWE work; ISTQB covers test; Google SRE book covers SRE; IEEE 1028
   covers review/audit; PMBOK covers PM; no umbrella framework exists. Cross-
   referencing is load-bearing.

2. **"Product manager" lacks Tier-1 sources.** Industry practice is strong but
   no IEEE/ISO/PMI standard defines PM canonically. SFIA v9 "Product
   management" (PROD) is the closest Tier-2.

3. **"Documentation engineer" is a Tier-3-only role.** BLS recognizes
   "technical writer"; documentation engineer is a newer industry role without
   standards-level definition.

4. **Role-boundary debates are not resolved by any single framework.** §3
   heatmap documents overlaps but industry has no canonical resolution. Audit
   findings on a project's role overlaps should not cite "industry agrees on
   X" where X is under genuine debate — §3 enumerates the debates.

5. **Project-specific gates may have no canonical role analogue.** A
   downstream project that introduces custom review/quality gates beyond the
   §2 roles should treat them as project-specific rather than canonical;
   §4's notes give the closest industry analogues.

6. **The "researcher / librarian" role used in this template is custom.**
   Closest industry analogues are technical writer (author role) and SME
   (domain authority role), but neither captures a research-librarian scope
   (retrieves and cites Tier-1 sources, does not adjudicate). Treat as a
   template-specific role not covered by a single Tier-1 source.
