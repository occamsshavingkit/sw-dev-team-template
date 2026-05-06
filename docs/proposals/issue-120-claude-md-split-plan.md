# Issue #120 — CLAUDE.md section-extraction plan

Owner: architect (plan only). Executor: tech-writer.
Source: `/home/quackdcs/SWEProj/sw-dev-team-template/CLAUDE.md` —
926 lines, ~46.7k chars (over Claude Code's 40k performance threshold).

## 1. Current state — section size table

Line ranges from the live file (TOC at L3–36); chars approximated at
~50/line for prose, denser for tables.

| § | Heading | Lines | Approx chars |
|---|---|---|---|
| A | Header + TOC + intro | 1–46 | 1.4k |
| B | The human is the customer | 47–67 | 1.0k |
| C | Escalation protocol (strict) | 68–98 | 1.6k |
| D | Memory and orchestration tooling | 99–138 | 2.2k |
| E | Scaffolding a new project | 139–169 | 1.5k |
| F | Template version check + upgrade | 170–241 | 3.5k |
| F2 | Per-version migrations | 242–259 | 0.9k |
| G | Framework / project boundary | 260–294 | 2.0k |
| H | FIRST ACTIONS preamble | 295–305 | 0.5k |
| H0 | Step 0 — Issue-feedback opt-in | 306–333 | 1.5k |
| H1 | Step 1 — Skill packs | 334–428 | 4.5k |
| H2 | Step 2 — Project scoping + SME discovery | 429–514 | 4.4k |
| H3 | Step 3 + Step 3a — Agent naming | 515–558 | 2.2k |
| I | Template version stamp | 559–571 | 0.5k |
| J | Agent roster | 572–591 | 1.6k |
| K | Creating an SME agent + SME scope | 592–667 | 3.6k |
| L | Agent-teams panel | 668–687 | 1.0k |
| M | Tech-lead is the main-session persona | 688–725 | 2.0k |
| N | Routing defaults + Operations KA | 726–757 | 1.6k |
| O | Binding references | 758–774 | 0.7k |
| P | Standard document templates | 775–797 | 1.0k |
| Q | IP policy | 798–848 | 2.7k |
| R | Time-based cadences | 849–870 | 1.0k |
| S | Hard rules (10 rules) | 871–920 | 3.3k |
| T | Taxonomy discipline | 921–926 | 0.3k |

## 2. Extraction list

Ordered by char savings. Each row notes divergence from issue #120
where applicable.

| § | Move to | Savings | Rationale / divergence |
|---|---|---|---|
| H1 Skill packs | `docs/FIRST_ACTIONS.md` | ~4.5k | Session-1-only menu; verified 2026-04-21, drifts. |
| H2 Step 2 scoping + DoD | `docs/FIRST_ACTIONS.md` | ~4.4k | Session-1-only; long DoD checklist. |
| F+F2 Upgrade + migrations | `docs/TEMPLATE_UPGRADE.md` | ~4.4k | Maintenance ops, not per-session. Merge per issue. |
| K Creating SME + scope | merge into existing `docs/sme/CONTRACT.md` | ~3.6k | **Divergence:** CONTRACT.md already covers § 2.1/2.2/2.3 modes verbatim; it does NOT yet carry the procedural "copying sme-template.md" creation steps from CLAUDE.md L592–602 — fold those into CONTRACT.md § 4 (currently 5 lines pointing back to CLAUDE.md). One-way merge; do not duplicate. |
| H0 Step 0 opt-in | `docs/FIRST_ACTIONS.md` | ~1.5k | Session-1 atomic question. |
| Q IP policy | `docs/IP_POLICY.md` | ~2.7k | Stable governance doc; rarely-changing reference. |
| D Memory + orchestration | `docs/MEMORY_POLICY.md` | ~2.2k | Cross-refs FW-ADR-0001. |
| H3+3a Agent naming | `docs/FIRST_ACTIONS.md` | ~2.2k | Session-1-only Q&A flow. |
| G Framework / project boundary | leave in entrypoint *or* `docs/FRAMEWORK_BOUNDARY.md` | (~2.0k) | **Divergence from issue (issue did not list it):** `docs/framework-project-boundary.md` already exists and is the canonical home. Replace § G in CLAUDE.md with a 3-line pointer; net ~1.7k saved. |
| E Scaffolding | `docs/TEMPLATE_UPGRADE.md` (same file as F) | ~1.5k | **Divergence:** issue did not propose moving E. Scaffolding and upgrade are the same audience (template maintainers, not per-session readers); co-locate. |
| H preamble | stays w/ Step links inline | — | Replace § H with one-line pointer to `docs/FIRST_ACTIONS.md`. |
| R Time-based cadences | `docs/MEMORY_POLICY.md` (rename to `docs/SESSION_SEMANTICS.md`?) | ~1.0k | **Open question, see §5.** Short, important, not session-1-only — but tightly coupled to "no background scheduler" theme that overlaps with memory's session-anchored model. Suggest co-locate. |
| L Agent-teams panel | `docs/FIRST_ACTIONS.md` § "Harness notes" or new `docs/HARNESS_NOTES.md` | ~1.0k | **Open question, see §5.** Codex-vs-Claude harness specifics. |

**Total savings target: ~28–30k.** Conservative.

**Kept in entrypoint (per issue + per architect judgment):**
- A header/TOC/intro, B customer, C escalation, I version stamp,
  J agent roster, M tech-lead-is-main-session, N routing + Ops KA,
  O binding references, P standard doc templates, S Hard rules
  (load-bearing — explicitly required), T taxonomy discipline.

## 3. Residual entrypoint

Projected: ~16–18k chars, ~340 lines. Comfortable margin under the
40k threshold; ample room for future Hard-Rule additions.

Residual section order (preserved):
1. Header/TOC/intro
2. Customer
3. Escalation protocol
4. Pointer block: FIRST ACTIONS / TEMPLATE_UPGRADE / MEMORY_POLICY /
   IP_POLICY / FRAMEWORK_BOUNDARY / SME CONTRACT (one paragraph,
   one-line each)
5. Template version stamp
6. Agent roster
7. Agent-teams panel *(if not extracted — see §5)*
8. Tech-lead is the main-session persona (binding)
9. Routing defaults + Operations KA
10. Binding references
11. Standard document templates
12. Time-based cadences *(if not extracted — see §5)*
13. **Hard rules** (10 rules — load-bearing, never moved)
14. Taxonomy discipline

## 4. Cross-reference plan

Pointer block (single new section in CLAUDE.md, replacing extracted
content), shape:

> ## Extracted references
> Detailed procedures live in dedicated docs to keep this entrypoint
> small. Read these when the situation matches:
> - **Session-1 setup** (Steps 0–3a, skill packs, scoping, naming):
>   `docs/FIRST_ACTIONS.md`
> - **Template scaffold + upgrade + per-version migrations**:
>   `docs/TEMPLATE_UPGRADE.md`
> - **Memory layer + orchestration-framework stance**:
>   `docs/MEMORY_POLICY.md` (cross-refs `docs/adr/fw-adr-0001-...`)
> - **IP policy** (copyright, restricted-source clauses, AI-training
>   scope): `docs/IP_POLICY.md`
> - **Framework / project boundary** (downstream path ownership):
>   `docs/framework-project-boundary.md`
> - **SME contract** (modes, creation, researcher interaction):
>   `docs/sme/CONTRACT.md`

Per-extracted-doc front-matter: each gets a 1-line "Source: extracted
from `CLAUDE.md` v1.x.0 per issue #120" header so future readers
trace provenance.

**AGENTS.md parallel updates required:**
- AGENTS.md L14 reading-order list cites `CLAUDE.md` only. Add
  `docs/FIRST_ACTIONS.md` and `docs/MEMORY_POLICY.md` as recommended
  follow-on reads after `CLAUDE.md` for Codex sessions that hit
  those topics. Charter is unchanged: AGENTS.md still treats
  CLAUDE.md as the binding contract entrypoint.
- AGENTS.md L31 framework-managed-files list: add the five new
  `docs/*.md` files (they are framework-shipped).
- AGENTS.md L79 + L177 cite `CLAUDE.md` Hard Rule #8 — **no change
  needed**, Hard Rules stay in entrypoint.

**Inbound links from other framework docs that may need updating
(tech-writer to grep before executing):**
- `.claude/agents/tech-lead.md` and `.claude/agents/researcher.md`
  reference § "Memory and orchestration tooling" and § "Escalation
  protocol" — escalation stays; memory pointers must be redirected
  to `docs/MEMORY_POLICY.md`.
- `.claude/agents/sme-template.md` references CLAUDE.md § "SME
  scope" — redirect to `docs/sme/CONTRACT.md` § 2.
- ADR FW-0001 — confirm bidirectional link with new MEMORY_POLICY.md.
- `docs/INDEX-FRAMEWORK.md` — add the five new files to the index.
- `scripts/version-check.sh` and `scripts/upgrade.sh` — confirm no
  line-number-dependent grep against CLAUDE.md (unlikely but check).

## 5. Risks / open questions

To resolve before tech-writer executes:

1. **Time-based cadences (R) — extract or keep?** It's short (~1k)
   and read by every PM agent, not just session-1. My recommendation:
   keep in CLAUDE.md (cheap to retain, expensive to forget).
2. **Agent-teams panel (L) — extract to a Codex-vs-Claude harness
   doc?** Issue #120 didn't propose this. The Codex adapter rule at
   L682–686 mixes harness specifics with naming policy. Recommend:
   keep in CLAUDE.md for now; revisit if a third harness ever lands.
3. **Hard Rule #10 (L909–919)** is dense — 11 lines on
   product-vs-framework separation. Customer may prefer to compress
   to a one-liner pointer to `docs/framework-project-boundary.md`.
   Surface this; do not act unilaterally — Hard Rules are
   load-bearing.
4. **Framework / project boundary (G)** — confirm that
   `docs/framework-project-boundary.md` already covers everything
   in CLAUDE.md L260–294. If yes, replace with pointer; if no,
   tech-writer must merge missing content first.
5. **SME extraction merge direction.** CONTRACT.md is the canonical
   home; CLAUDE.md L592–667 partially duplicates. Tech-writer must
   diff carefully and ensure no content is lost in the one-way
   merge.

## 6. Versioning impact

Issue #120 proposes MINOR (v1.1.0). **Push back: this should ride
post-1.0.0.**

Reasoning:
- Project is at v1.0.0-rc7 mid-cycle. v1.0.0 final ships are
  imminent (per memory: GitHub Releases at MINOR boundaries only).
- This is a structural reshuffle of binding documents. Shipping it
  inside an rc cycle risks destabilizing rc7's audit surface.
- File contents do not change semantically — only locations. Hard
  Rules, escalation, customer model, taxonomy discipline are
  byte-equivalent. So the change is **non-breaking** for downstream
  projects that read CLAUDE.md as a whole.
- However, downstream tools / agents that hard-link to specific
  `CLAUDE.md` anchors (e.g., `#sme-scope-...`) will break. That
  argues MINOR, not PATCH.

**Recommendation:** ship as **v1.1.0**, AFTER v1.0.0 final cuts.
Add to the migration set at `migrations/1.1.0.sh` to update any
known downstream references (no-op for projects without such
references; idempotent).

If the customer wants this in v1.0.0 final, the cull does not block
rc7 on technical grounds — but it widens the audit surface during a
stabilization phase, which is the reason to defer.

---

End plan. ~680 words.
