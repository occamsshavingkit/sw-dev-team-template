# Lessons Learned — SWEProj (template-as-project meta-workspace)

Process journal for the template's own development. Release-note
content lives in `sw-dev-team-template/CHANGELOG.md`; this file is
for *process* lessons that would otherwise rot.

Based on `docs/templates/pm/LESSONS-template.md` shape.

---

## 2026-04-21 — Sub-agent permission denials on `.claude/agents/**`

**Context.** Dispatching `tech-writer` and other sub-agents to edit
template files under `sw-dev-team-template/.claude/agents/`.

**Event.** Main agent Edits on those paths worked. Sub-agent Edits
on the same paths were denied three consecutive times, even after
adding an explicit `Edit(...sw-dev-team-template/.claude/agents/**)`
entry to `.claude/settings.local.json`.

**What went well.** The failure was fast and loud, not silent.
Switching to main-agent Edits immediately unblocked the work.

**What did not.** Two diagnosis attempts (first: wrong file path;
second: permission syntax) were wrong. The true cause appears to
be a harness-level protection on `.claude/` paths for sub-agents
that the user-facing settings cannot override.

**Contributing factors.** No documentation of this restriction in
the Claude Code settings reference we could find. Process gap, not
tooling gap per se.

**Recommendation.** When editing `.claude/agents/*.md`, default to
main-agent Edits. Do not attempt to delegate to sub-agents.
Document this in `tech-lead.md` § routing if it keeps biting.

**Category.** tooling / process.

**References.** Session transcript; `.claude/settings.local.json`.

---

## 2026-04-21 — Issue-feedback opt-in must be asked first, not last

**Context.** Original FIRST ACTIONS had issue-feedback opt-in as
Step 4, *after* skills menu, scoping, and naming. On the Gate-3
engagement, the customer had to prompt `tech-lead` to ask Step 4 at
all (issue #7), and multiple framework gaps were hit in Steps 1–3
that could not be filed because opt-in was unresolved.

**Event.** Customer directive: *"issue feedback needs to be the
very first question so we can give feedback on the first steps."*
Promoted to Step 0.

**What went well.** The fix is one reorder + DoD backstop; no new
rule, just sequencing.

**What did not.** The original design rationale assumed opt-in was
"an administrative question" and put it last. That was wrong —
opt-in is the *permission gate* for everything that follows.

**Contributing factors.** Design error: confusing administrative
ordering with permission ordering.

**Recommendation.** When a step gates a downstream behaviour
(logging, filing, etc.), it must precede the thing it gates.
Rule-of-thumb for future FIRST ACTIONS additions: *"If Step N
depends on a permission answered in Step M, then M < N."*

**Category.** process / design.

**References.** Issue #7; `sw-dev-team-template/CLAUDE.md` §
"Step 0 — Issue-feedback opt-in (atomic, asked FIRST)".

---

## 2026-04-23 — SME contract: Fix-C hybrid (primary-source vs derivative)

**Context.** Issue #6 surfaced that the single-mode SME scope
(customer-specific or externally-held non-public knowledge only)
blocked the common mental model of "domain specialist that uses
any source." Gate 5 (no open contract-breaking themes) was held
open on this.

**Event.** Customer ruled Fix-C hybrid with a sharper formulation:
two modes decided at creation time. Primary-source SME has a
non-public source; derivative SME has no primary source and
consumes `researcher` output, existing for context segmentation.

**What went well.** The customer's reformulation was sharper than
any of the three candidate fixes the architect had drafted. The
"context segmentation" framing for derivative mode is a genuine
design insight — `researcher` doesn't have to hold every vendor
ecosystem in one window.

**What did not.** The original single-mode rule shipped for too
long before the gap was surfaced. Taxonomy had been finalized on
one-mode assumptions since before v0.7.

**Contributing factors.** Over-specification up front without a
real downstream engagement. Gate-3 engagement was required to
surface the failure.

**Recommendation.** Gate-3-style real engagement is non-negotiable
for contract-level rules. Rules that look clean in isolation may
fail under a project with five vendor ecosystems; only a real
project reveals which.

**Category.** design / customer / process.

**References.** Issue #6; `sw-dev-team-template/CLAUDE.md` § "SME
scope: what is and is not an SME (binding)";
`.claude/agents/sme-template.md` § "Mode"; `CUSTOMER_NOTES.md`
2026-04-19 entry.

---

## 2026-04-23 — PDFs in `docs/library/local/` cannot be read directly

**Context.** PMBOK 8 and SWEBOK V4 PDFs were placed in
`docs/library/local/` (2026-04-21) with read-restriction lifting
2026-04-23. Audits dispatched to `researcher` agents on that date
to compare our agent roster against the two standards.

**Event.** The Read tool's PDF pathway requires `pdftoppm` from
`poppler-utils`, which is not installed on this system. All PDF
reads failed immediately. The SWEBOK V4 audit fell back to
web-sourced KA summaries (IEEE CS landing page, SFIA v9 crosswalk,
Wikipedia); no pages of LIB-0002 were actually opened.

**What went well.** The researcher fell back gracefully and wrote
a useful report against web sources, calling out the limitation
explicitly in §4 of `docs/audits/swebok-v4-gap-analysis.md`.

**What did not.** The blocker was not detected until mid-audit.
Pre-flight check would have caught it in seconds.

**Contributing factors.** `researcher` agent description does not
require a PDF-read capability check when the inventory holds PDFs.
The library inventory template does not have a "verified readable
on this system" field.

**Recommendation.** Three actions:
1. Install `poppler-utils` (requires user approval: `sudo apt install
   poppler-utils`).
2. Add a one-line pre-flight check to `researcher.md`: when about
   to Read a PDF, verify the system has `pdftoppm` (or equivalent)
   first; fall back to web sources and FLAG the limitation in the
   report if not.
3. Add a "PDF readable on this host: yes/no" column to the
   library inventory template.

**Category.** tooling / process.

**References.** `docs/audits/swebok-v4-gap-analysis.md` §4;
`docs/library/INVENTORY.md` LIB-0001, LIB-0002.

---

## 2026-04-23 — Researcher silently substituted web sources for a PDF brief

**Context.** Two parallel gap audits were dispatched with briefs
that explicitly named the PDFs to read (LIB-0001, LIB-0002 under
`docs/library/local/`). Poppler was missing at dispatch time, so
the Read tool could not open PDFs.

**Event.** Both researchers fell back to web-sourced KA summaries
without reporting the blocker first. Audit-pass-1 reports were
written against IEEE CS landing pages, SFIA crosswalks, Wikipedia,
and Tier-3 practitioner blogs — none of which were the asked-for
source. The customer caught this after the fact:
*"neither researcher should have gone to the web when told
specifically to read a PDF."*

**What went well.** Each researcher did document the fallback in
the report body and in the return message, so the failure was
visible on read-through. Audit-pass-2 was dispatchable without
re-discovering the issue.

**What did not.** The researchers treated the brief's named
source as a preference rather than a requirement. Web-sourced
content is a *different* deliverable — delivering it under the
framing of "audit the book" is dishonest even when the fallback
is marked.

**Contributing factors.** `researcher.md` had a Tier-1/Tier-2/
Tier-3 ranking but no rule forbidding silent source substitution
when a specific source was named in the brief.

**Recommendation.**
1. **Binding rule added to `researcher.md`** (2026-04-23): "No
   silent source substitution. When a brief names a specific
   source, that source is mandatory; if unreachable, stop and
   report the blocker to the dispatcher, do not substitute."
2. The rule applies to PDFs (`LIB-NNNN`), SME inventory items,
   cited standards, and any source whose row ID appears in the
   brief.
3. Dispatchers (`tech-lead`) should phrase briefs to make the
   source requirement explicit, not an expectation.

**Category.** process / agent design.

**References.** `.claude/agents/researcher.md` § Job item 1
("No silent source substitution (binding)");
`docs/audits/swebok-v4-gap-analysis.md` (audit-pass-1 flagged
its own fallback in §4);
`docs/audits/pmbok-8-gap-analysis.md` (audit-pass-1 flagged its
own fallback in §0 method note).

---
