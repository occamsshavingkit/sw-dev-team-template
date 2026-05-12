# Cached SW-dev reference repos — survey for v0.14.0

**Date.** 2026-04-25
**Author.** `researcher` (Sam Eagle)
**Trigger.** None (pure survey; no adoption in this turn).
**Corpus.** 14 README/template files at `/tmp/sw-dev-survey/` pre-staged
by `tech-lead` from `quackplc@plc-test:~/ref/sw-dev/`. PDFs from
`References_Books/` and `software-development-books/` are **not** staged
(intentional — those are book *indexes* only; the books themselves are
copyright-restricted).
**Scope.** Identify ideas that materially reduce **token usage** and
**repeated work** for v0.14.0 of `sw-dev-team-template`. Survey only —
no adoption.
**IP discipline.** All borrow-candidates evaluated below are CC0 1.0
unless noted; no copyrighted PDF content from the cached book corpora
was opened.

---

## Executive summary — top 5 recommendations

The corpus's structural value is concentrated in **`jam01/SDD-Template`
and `jam01/SRS-Template`** (both CC0 1.0, freely paraphrasable). Their
"bare" template variants and per-requirement / per-view file shape
directly address v0.14.0's token-economy goal. The
`awesome-design-patterns` and `software-development-books` corpora are
overwhelmingly Tier-3 *content references* (design-pattern catalogs,
textbook indexes) with little direct bearing on the template's plumbing
— they are useful as future paraphrase sources for `architect` /
`software-engineer` agents, not as v0.14.0 plumbing changes.

1. **(A) Ship lean variants of `requirements-template.md` and
   `architecture-template.md` alongside the guided ones.** Pattern from
   jam01 (`srs-template-bare.md` ↔ `srs-template.md`,
   `sdd-template-bare.md` ↔ `sdd-template.md`). Estimated savings:
   ~40–60 % per template instantiation when guidance prose isn't
   needed (i.e., once a project's authors are fluent). Estimated work:
   one new file per template, ~2 hours.
2. **(B) Adopt the per-requirement / per-view breakout pattern as an
   optional workflow in v0.14.0.** jam01's
   `req-template.md` + `req-template-bare.md` and
   `view-template.md` + `view-template-bare.md` model. Lets a project
   keep `docs/requirements.md` as a thin index and put each FR-NNNN /
   NFR-NNNN in `docs/requirements/FR-NNNN.md`. Saves tokens because
   agents load only the requirement(s) relevant to the task instead
   of the monolithic doc. Estimated work: two new templates +
   workflow note in `requirements-template.md` § Tailoring,
   ~3 hours.
3. **(B) Extract the binding paraphrase content of LIB-0009 / LIB-0010
   (already in our agent contracts) into a single
   `docs/standards/paraphrase-cards.md` keyed by clause.** Each clause
   gets one paragraph cited by row ID + clause number. Agent contracts
   then drop their inline paraphrase and link to the card. Eliminates
   duplicate content between `architect.md`, `qa-engineer.md`,
   `software-engineer.md`, etc. — current pattern repeats the same
   IEEE 1012 / 1028 / 1016 framing across multiple agent files.
   Estimated savings: ~5–10 KB across `.claude/agents/` files,
   loaded per-spawn. Estimated work: one new file, edits to ~6 agent
   contracts, ~4 hours.
4. **(A) Adopt MADR's optional-section discipline in
   `docs/templates/adr-template.md`.** MADR (CC0 + MIT dual) names
   *required* (Context+Problem, Considered Options, Decision Outcome)
   and *optional* (Drivers, Consequences, Confirmation, Pros/Cons,
   More Info) sections. A "required-only" ADR is ~400–600 tokens vs
   the full ~1,200–1,800. Our current ADR template doesn't make this
   split explicit; making it explicit lets `architect` ship a thin
   ADR for low-stakes decisions without violating the binding shape.
   Estimated work: edit one template, ~30 min.
5. **(C) Add four MIT/CC0 reference rows to `docs/library/INVENTORY.md`
   (LIB-0015 through LIB-0018):** `donnemartin/system-design-primer`
   (MIT), `jam01/SDD-Template` (CC0), `jam01/SRS-Template` (CC0),
   `adr.github.io/madr` (MIT+CC0). All four are URL-only references
   (no PDF), citable by `architect` / `researcher` for paraphrase-
   friendly distillation. Estimated work: 4 inventory rows, ~30 min.

A note on what we are **not** recommending: the awesome-list pattern
catalogs (`microservices.io`, `martinfowler.com/eaaCatalog`,
`enterpriseintegrationpatterns.com`, `martinfowler.com/articles/
patterns-of-distributed-systems/`) are all individually copyrighted
("All rights reserved"), with no stated reuse policy. They remain
valid *paraphrase sources* citable from agent contracts when an
`architect` reaches for one, but they are not v0.14.0 template
plumbing. No new agent should be created for them; `researcher`
cites on demand.

---

## URL triage

**Total URLs extracted from corpus.** ~145 (the bulk from
`awesome-design-patterns/README.md`).

| Bucket | Count | Notes |
|---|---|---|
| HIGH (v0.14.0-relevant) | 14 | curated below; ≤ 25 cap not approached |
| MEDIUM (paraphrase candidates for future agent citations) | ~50 | pattern catalogs, distributed-systems references; not v0.14.0 plumbing |
| LOW (book Amazon links, language-specific pattern repos, off-topic) | ~80 | not relevant to template plumbing or repeated work |

Coverage: 14 + 50 + 80 = 144 of ~145 ≈ ≥ 99 %. Adequate per the ≥ 80 %
target.

### HIGH list (with disposition)

| # | URL | Source file | 1-line context | Fetched? | Disposition |
|---|---|---|---|---|---|
| 1 | https://github.com/jam01/SDD-Template | SDD-Template/README.md, SRS-Template/README.md | the SDD template repo itself | yes | **borrow** structural ideas (CC0); LIB-0016 candidate |
| 2 | https://github.com/jam01/SRS-Template | SRS-Template/README.md, SDD-Template/README.md | the SRS template repo itself | yes | **borrow** structural ideas (CC0); LIB-0017 candidate |
| 3 | https://adr.github.io/madr/ | SDD-Template/README.md ("Related Projects") | MADR ADR pattern | yes | **align** our `adr-template.md` w/ required-vs-optional split; LIB-0018 candidate |
| 4 | https://github.com/donnemartin/system-design-primer | awesome-design-patterns/README.md | MIT-licensed system-design checklist | yes | **paraphrase source** for `architect`; LIB-0015 candidate |
| 5 | https://12factor.net | awesome-design-patterns/README.md | 12-factor app methodology | yes | paraphrase source for `architect` / `sre`; site copyright reserved |
| 6 | https://microservices.io/patterns | awesome-design-patterns/README.md | Chris Richardson microservice patterns | yes | citation-only (© All rights reserved) |
| 7 | https://martinfowler.com/articles/patterns-of-distributed-systems/ | awesome-design-patterns/README.md | Unmesh Joshi distributed-systems patterns | yes | citation-only (© Martin Fowler) |
| 8 | https://www.enterpriseintegrationpatterns.com/patterns/messaging/toc.html | awesome-design-patterns/README.md | Hohpe-Woolf integration patterns | yes | citation-only (© All rights reserved) |
| 9 | https://martinfowler.com/eaaCatalog | awesome-design-patterns/README.md | PoEAA catalog | yes | citation-only (© Martin Fowler, no stated license) |
| 10 | https://martinfowler.com/eaaDev/uiArchs.html | awesome-design-patterns/README.md | GUI architectures essay | yes | citation-only (© Martin Fowler, no stated license) |
| 11 | https://github.com/sindresorhus/awesome | awesome-design-patterns/README.md | meta-awesome list | yes | inspiration for "good index file" criteria |
| 12 | https://patterns.innersourcecommons.org/ | awesome-design-patterns/README.md | InnerSource patterns (CC BY-SA 4.0) | yes | shape inspiration for problem/forces/solutions micro-template |
| 13 | https://raw.githubusercontent.com/jam01/SDD-Template/main/LICENSE | (constructed) | LICENSE verbatim | DEAD (404) | corroborated via README — CC0 1.0; not a substitution since the README itself is the authoritative copyright declaration the template ships with |
| 14 | https://raw.githubusercontent.com/jam01/SRS-Template/main/LICENSE | (constructed) | LICENSE verbatim | DEAD (404) | same — README declares CC0 1.0 |

DEAD URLs (#13, #14) were replaced with **the same authoritative
declaration** in the upstream README, not a substitute source — the
licensing claim used here is the project's own README text. If
`tech-lead` wants the LICENSE file verbatim, raise as a "need: file
at `quackplc@plc-test:~/ref/sw-dev/SDD-Template/LICENSE`" line for
the next dispatch.

### MEDIUM (sample)

Pattern catalogs the corpus indexes — `refactoring.guru`,
`sourcemaking.com`, `oodesign.com`, `system-design-primer` chapters,
`reactivedesignpatterns.com`, `cloudcomputingpatterns.org`, AWS / Azure
/ GCP cloud-pattern docs, `k8spatterns.io`, `cdkpatterns.com`,
`12factor.net`, `dzone.com/articles/...`, `iluwatar/java-design-patterns`,
language-specific GoF implementations (Python / Go / Rust / Kotlin /
Swift / TypeScript). All useful as Tier-2 / Tier-3 paraphrase sources
when `architect` or `software-engineer` needs a canonical pattern
name; **none** drive v0.14.0 template changes.

### LOW (sample)

Amazon book links (`Effective Java`, `Head First Design Patterns`,
GoF, `Object Design Style Guide`, etc.), language-specific
small-population pattern repos, off-topic awesome-list links, and
publisher product pages (Manning, Packt, O'Reilly). Off-scope for
template plumbing.

---

## WebFetch evaluations

### `github.com/jam01/SDD-Template` — CC0 1.0, freely borrowable

Confirmed CC0 in README. The repo ships **four files** for SDDs:
guided full (`sdd-template.md`), guided bare
(`sdd-template-bare.md`), guided per-view (`view-template.md`), and
bare per-view (`view-template-bare.md`). The "bare" pattern is the
most useful borrow — same headings, comments instead of guidance
prose. Our `architecture-template.md` is currently guidance-rich
(~190 lines); a bare variant would land at ~70 lines.

### `github.com/jam01/SRS-Template` — CC0 1.0, freely borrowable

Confirmed CC0. Same four-file shape (full / bare / per-req full /
per-req bare). Notable feature ours lacks: a dedicated **AI/ML
section** (3.6) covering model spec / data management / guardrails /
ethics / human-in-the-loop / lifecycle. For projects that ship ML
features, this is a meaningful gap; we could either fold it into
`requirements-template.md` § 5 (NFRs) under a new ISO/IEC 25010
characteristic, or keep it as an optional § 5.10 "AI/ML
requirements" subsection (paraphrased; cite jam01 row ID).
Recommendation deferred — adoption requires an ADR.

### `adr.github.io/madr/` — dual MIT + CC0

MADR's required-vs-optional split (3 required sections, 5 optional)
matches the pattern v0.14.0 wants: minimum-viable artifact for
low-stakes decisions, full artifact for architecturally significant
ones. Token budget: 400–600 (minimal) vs 1,200–1,800 (full).
Required: Context and Problem Statement, Considered Options,
Decision Outcome. Optional: Drivers, Consequences, Confirmation,
Pros/Cons, More Information. We already partly do this in our ADR
template; making the split *explicit* in the template header
prevents `architect` from over-spending tokens on routine ADRs.

### `donnemartin/system-design-primer` — MIT

MIT-licensed, paraphrase-friendly. Top-level chapters (Performance
vs Scalability, CAP, Caching, Load Balancing, DNS/CDN, Database
families, Async/Message-Queue patterns, Communication protocols,
Security, Calculations appendix). Useful as a single-source
**checklist** that `architect` can paraphrase into a project's
quality-attribute scenarios in `architecture-template.md` § 11.

### `12factor.net` — © Salesforce, all rights reserved

The 12 factors themselves are widely cited and stable — paraphrase-
safe in agent contracts so long as we cite the URL. No template
change recommended; useful as one of `architect`'s default checklist
items for any web-service project.

### `microservices.io` (Chris Richardson)

Comprehensive pattern catalog. © reserved. Citation-only — name
the pattern, link the URL, do not duplicate prose. Same posture as
Fowler's catalogs.

### `martinfowler.com/articles/patterns-of-distributed-systems/`

32 named distributed-systems patterns by Unmesh Joshi (Lamport
Clock, Paxos, Two-Phase Commit, Write-Ahead Log, etc.). © Fowler;
no explicit reuse license. Citation-only.

### `enterpriseintegrationpatterns.com` (Hohpe / Woolf)

Canonical EIP pattern set. © reserved. Citation-only.

### `martinfowler.com/eaaCatalog` and `eaaDev/uiArchs.html`

PoEAA catalog and GUI architectures (MVC / MVP / Humble View /
Application Model). © Fowler. Citation-only — paraphrase the
pattern *name and shape* in agent contracts; never copy prose.

### `github.com/sindresorhus/awesome` — CC0 1.0

Useful for the **"good awesome list" criteria** themselves: only
genuinely-recommended items, explain *why*, consistent shape,
contribution guidelines. We could apply these criteria to our own
`docs/library/INVENTORY.md` and `docs/sme/<domain>/INVENTORY.md` —
mostly we already do, but the "explain why each item belongs"
discipline is worth tightening.

### `patterns.innersourcecommons.org/` — CC BY-SA 4.0

Pattern shape: Title, Problem Statement, Context, Forces,
Solutions. CC BY-SA is **share-alike**, so direct paraphrase into
our (currently MIT) template carries a license-virality risk. Use
as inspiration only, not as a paste source.

---

## Template comparison — external (jam01 MSDD/MSRS) vs project

### `sdd-template.md` (jam01 MSDD) vs `architecture-template.md` (ours)

| Aspect | jam01 MSDD | Ours | Note |
|---|---|---|---|
| Standards alignment | IEEE 1016-2009 + ISO/IEC/IEEE 42010:2011 | IEEE 1016-2009 + ISO/IEC/IEEE 42010:2022 + arc42 + C4 | Ours is more layered; jam01 stays closer to 1016 |
| Viewpoint catalog | 15 named viewpoints (Context/Composition/Logical/Physical/Structure/Dependency/Information/Interface/Interaction/Algorithm/State Dynamics/Concurrency/Patterns/Deployment/Resources) | maps 1016 § 5.2-5.13 viewpoints onto C4 / arc42 sections | jam01's flat 15-viewpoint table is more *discoverable*; ours is more *integrated* |
| Bare variant | yes (`sdd-template-bare.md`, ~118 lines, comments only) | no | **gap** |
| Per-view breakout | yes (`view-template.md` + bare) | no — view content lives inline in our § 5/6/7 | **gap** for projects with many views |
| Decision capture | inline § 4 + MADR pointer | external ADR index + ADR template | similar, ours more decoupled |
| License | CC0 1.0 | template MIT, downstreams pick own | compatible — paraphrase OK |
| Token weight (filled) | ~270 lines guided / ~118 lines bare | ~190 lines guided | ours sits between; a bare variant ~70 lines is achievable |

**Structural ideas ours lacks (worth borrowing):**
- A flat per-viewpoint table early in the doc that lists *which*
  viewpoints this project actually uses (vs the implicit mapping in
  ours). Would let `architect` declare "this project uses Context +
  Composition + Deployment; the rest are omitted with rationale."
- Dedicated **per-view file** option (`docs/design/views/<id>.md`)
  for projects with many views, keeping the main doc as an index.

**Leaner shape that would reduce token cost:**
- A bare `architecture-template-bare.md` matching the section
  hierarchy with HTML-comment guidance instead of prose. Estimated
  savings: ~50 % per instantiation.

### `srs-template.md` (jam01 MSRS) vs `requirements-template.md` (ours)

| Aspect | jam01 MSRS | Ours | Note |
|---|---|---|---|
| Standards alignment | IEEE 830 + ISO/IEC/IEEE 29148 | ISO/IEC/IEEE 29148:2018 (with 2011 paraphrase via LIB-0010) | ours is current edition |
| Information-item shape | single SRS shape | StRS / SyRS / SRS three-shape per 29148 § 9 | ours is more rigorous |
| Requirement template | dedicated `req-template.md` + bare | inline FR/NFR sections with example shape | **gap** — we don't ship a per-req file template |
| AI/ML section | yes — § 3.6 (model spec, data, guardrails, ethics, HITL, lifecycle) | no — would land in NFRs | **gap** for ML-bearing projects |
| Quality-attribute organization | Quality of Service / Compliance / Design&Implementation / AI-ML | ISO/IEC 25010 characteristics | jam01 is more workflow-oriented, ours is more standards-orthodox |
| Bare variant | yes (`srs-template-bare.md`, ~187 lines) | no | **gap** |
| Verification matrix | inline § 4 | inline § 7 | similar |
| License | CC0 1.0 | MIT downstream-pick | compatible |
| Token weight (filled) | ~423 lines guided / ~187 lines bare | ~236 lines guided | ours leaner-guided, but no bare variant |

**Structural ideas ours lacks (worth borrowing):**
- Per-requirement file pattern with status front-matter (`status:
  draft / proposed / deferred / planned / in-progress / blocked /
  passed / failed / waived` + `date:`). Status-front-matter is a
  small token cost up front but saves a lot of context-switching
  when an agent only needs to know whether FR-NNNN is in-progress
  or shipped.
- AI/ML requirements section as a first-class category, not folded
  under NFRs.
- Workflow-oriented requirement-AREA codes (jam01 uses
  `REQ-FUNC-001`, `REQ-PERF-003`, `REQ-SEC-007`, ...) vs our
  `FR-NNNN` / `NFR-NNNN`. jam01's scheme is more self-describing
  but breaks `qa-engineer`'s existing trace links — not a v0.14.0
  candidate without an ADR + migration script.

**Leaner shape that would reduce token cost:**
- Bare `requirements-template-bare.md` matching section hierarchy
  with comment guidance.
- Per-req file template (`docs/templates/requirement-item-template.md`
  or similar) so projects with many FRs don't load a monolithic doc
  to read one requirement.

---

## Three-theme recommendations

### A. Token-usage reduction

| Rec | Action | Path | Estimated savings | Effort |
|---|---|---|---|---|
| A1 | Add bare variant of `architecture-template.md` | `docs/templates/architecture-template-bare.md` (new) | ~50 % per instantiation when guidance prose isn't needed | ~2 h |
| A2 | Add bare variant of `requirements-template.md` | `docs/templates/requirements-template-bare.md` (new) | ~50 % per instantiation | ~2 h |
| A3 | Make required-vs-optional split explicit in ADR template (MADR-style) | `docs/templates/adr-template.md` (edit) | ~60 % per low-stakes ADR | ~30 min |
| A4 | Add status front-matter to per-requirement / per-task files (planned + adopted in workflow-redesign) | `docs/templates/req-item-template.md` (new), task-template (edit) | reduces re-reads by exposing status without loading full body | ~2 h |
| A5 | Trim duplicate IEEE 1012/1028/1016 paraphrase from `.claude/agents/*.md` into a single card file referenced by ID | `docs/standards/paraphrase-cards.md` (new), agent contracts (edit) | ~5–10 KB across agent contracts × per-spawn | ~4 h |

### B. Repeated-work elimination

| Rec | Action | Path | Why it eliminates repeated work | Effort |
|---|---|---|---|---|
| B1 | Per-requirement file workflow option | `docs/templates/req-item-template.md` (new) + workflow note in `requirements-template.md` § Tailoring | agents load only the FR(s) they need, not the monolithic doc | ~3 h |
| B2 | Per-view file workflow option for SDD/architecture | `docs/templates/architecture-view-template.md` (new) + workflow note in `architecture-template.md` | same — load only the view relevant to the task | ~3 h |
| B3 | Standards paraphrase-card file (B = also shared catalog) | `docs/standards/paraphrase-cards.md` (new) | one-and-only-one paraphrase per IEEE/ISO clause, cited by row ID, eliminating drift across `architect.md` / `qa-engineer.md` / `code-reviewer.md` / `software-engineer.md` / `release-engineer.md` | ~4 h |
| B4 | Apply "explain why each item belongs" rule to `INVENTORY.md` rows that lack it | `docs/library/INVENTORY.md`, `docs/sme/<domain>/INVENTORY.md` (edits) | future agents see the "why" without re-reading the source — the why-line is the whole point of an inventory entry | ~2 h |
| B5 | Externalize the project's "scoping question seed" workflow into a single questionnaire file (already partly in templates) | review `docs/templates/scoping-questions-template.md` | avoid re-asking same scoping questions on each new project | ~1 h to audit, no template change unless gap found |

### C. Reference adoption candidates (new INVENTORY rows)

Each row below is a candidate row for `docs/library/INVENTORY.md`
(LIB-0015+) or for citation in agent contracts. None require
committing the source; all are URL-based.

| Proposed row ID | Title | URL | Role(s) that would cite | Copyright concern |
|---|---|---|---|---|
| LIB-0015 | The System Design Primer (donnemartin) | https://github.com/donnemartin/system-design-primer | `architect` (quality-attribute checklists), `sre` (caching / async / scalability) | MIT — paraphrase OK with attribution |
| LIB-0016 | Markdown Software Design Description (MSDD) — jam01 | https://github.com/jam01/SDD-Template | `architect` (viewpoint vocabulary), `tech-writer` (lean SDD shape) | CC0 1.0 — unrestricted |
| LIB-0017 | Markdown Software Requirements Specification (MSRS) — jam01 | https://github.com/jam01/SRS-Template | `tech-lead`, `researcher` (SRS shape), AI/ML projects (3.6 section) | CC0 1.0 — unrestricted |
| LIB-0018 | Markdown Architecture Decision Records (MADR) | https://adr.github.io/madr/ | `architect` (ADR shape, required-vs-optional discipline) | dual MIT + CC0 1.0 — unrestricted |
| LIB-0019 (optional) | The Twelve-Factor App | https://12factor.net | `architect`, `sre`, `release-engineer` | © Salesforce; paraphrase + URL citation only |
| LIB-0020 (optional) | Microservices Patterns (Richardson) | https://microservices.io/patterns | `architect`, when project chooses microservices | © all rights reserved; cite-only |
| LIB-0021 (optional) | Patterns of Distributed Systems (Joshi / Fowler) | https://martinfowler.com/articles/patterns-of-distributed-systems/ | `architect`, `sre` | © Fowler, no stated license; cite-only |
| LIB-0022 (optional) | Enterprise Integration Patterns (Hohpe/Woolf) | https://www.enterpriseintegrationpatterns.com/ | `architect`, when project does messaging/integration | © all rights reserved; cite-only |
| LIB-0023 (optional) | Patterns of Enterprise Application Architecture (Fowler) | https://martinfowler.com/eaaCatalog/ | `architect`, `software-engineer` | © Fowler, no stated license; cite-only |

LIB-0015–LIB-0018 are the v0.14.0 priority adds. The remaining rows
are nice-to-have; gate on actual project need.

---

## Open questions / gaps for `tech-lead`

1. **Adoption gate.** Items A1–A5 / B1–B5 are template-shape changes;
   they require an ADR and customer sign-off before landing. Do you
   want one omnibus v0.14.0 ADR or one ADR per recommendation? Memory-
   note `feedback_simpler_wins_on_ties` argues for fewer artifacts
   when the structural form is debated; suggest one omnibus.
2. **AI/ML requirements section.** The jam01 MSRS § 3.6 is genuinely
   missing from our requirements template. The customer's profile
   (PLC / brewing automation) suggests AI/ML requirements aren't on
   the immediate horizon, but the template ships to other projects.
   Decision: fold into v0.14.0 or defer to a later release?
3. **License-virality on InnerSource patterns.** CC BY-SA 4.0
   share-alike could infect downstream projects if patterns are
   pasted. Recommend "inspire, don't paste" rule in template
   contributor docs. Need explicit policy?
4. **DEAD URLs (#13, #14 above).** Both LICENSE-file 404s. The
   README's CC0 declaration is itself binding (it's part of the
   template the maintainer ships), so this is corroboration, not
   substitution. If `tech-lead` wants the LICENSE files verbatim,
   raise as a "need: file at `quackplc@plc-test:~/ref/sw-dev/SDD-
   Template/LICENSE` and `~/ref/sw-dev/SRS-Template/LICENSE`" line for
   the next dispatch.
5. **`References_Books/` and `software-development-books/` PDFs.**
   These were correctly **not** pre-staged. Each book is individually
   copyrighted (publisher PDFs, Z-Library mirrors, Anna's-Archive
   mirrors). Survey did not open any of them. If a future project
   needs paraphrase from `Clean Architecture`, `Designing Data
   Intensive Applications`, `Software Engineering at Google`,
   `Building Secure and Reliable Systems`, etc., it should follow
   the same pattern as LIB-0001 / LIB-0002 (purchase or institutional
   access; do not commit). No v0.14.0 action needed.
6. **`software-development-books/` "Vibe Coding" entry.** Sole title
   is `Beyond Vibe Coding: From Coder to AI-Era Developer (Addy
   Osmani)`. Marketing-leaning, but Osmani has a track record on
   Chrome/web tooling. Not v0.14.0-relevant; flag for future
   consideration if customer shows interest in AI-pair-programming
   workflows.

---

## Provenance and method

- **Corpus location.** `/tmp/sw-dev-survey/` (pre-staged 2026-04-25).
- **Files read.** All 14 corpus files (`awesome-design-patterns/
  README.md`, `awesome-design-patterns/contributing.md`,
  `References_Books/README.md`,
  `software-development-books/README.md`, four
  `SDD-Template/*.md`, four `SRS-Template/*.md`,
  `SRS-Template/req-template.md`, `req-template-bare.md`).
- **WebFetches performed.** 11 successful, 2 DEAD (LICENSE files).
- **Existing project files read for cross-cut.**
  `docs/templates/architecture-template.md`,
  `docs/templates/requirements-template.md`,
  `docs/library/INVENTORY.md`, `docs/AGENT_NAMES.md`.
- **No silent substitution.** DEAD LICENSE URLs corroborated against
  the upstream README (the same maintainer's own license declaration
  in the template they distribute), not via WebSearch for a third-
  party authority.
- **No copyrighted PDF content opened.** All cached book corpora
  remained closed. All paraphrase in this survey is from CC0 / MIT
  / public-page sources cited inline.
- **IP discipline.** Per `CLAUDE.md` § "IP policy (non-negotiable)"
  and the `researcher.md` § "Cite hygiene for restricted sources."
