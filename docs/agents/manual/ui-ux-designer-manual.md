# ui-ux-designer — manual (rationale, examples, history)

**Canonical contract**: [.claude/agents/ui-ux-designer.md](../../../.claude/agents/ui-ux-designer.md)
**Generated runtime contract**: [docs/runtime/agents/ui-ux-designer.md](../../runtime/agents/ui-ux-designer.md)
**Classification**: canonical (manual; rationale companion)

This manual carries accesslint usage procedures, WCAG citation format,
design-feedback synthesis guidance, and historical context for the
`ui-ux-designer` role. Role added in issue #301 (customer ruling Q-0030).

## Taxonomy source

Canonical role §2.10. Primary Tier-1 source: SFIA v9.

- **HCEV** (Human Factors): user research, interaction design, usability
  evaluation.
- **ACCS** (Accessibility): WCAG conformance, inclusive design, audit
  and remediation.

BLS OOH does not cover UX/UI designer as a distinct occupation. SFIA v9
is the closest Tier-1 source; treat BLS 15-1299 ("Computer Occupations,
All Other") as a Tier-2 fallback for compensation/classification purposes
only.

## accesslint MCP integration

### Choosing the right audit tool

| Situation | Tool | Notes |
|---|---|---|
| Live URL available | `mcp__accesslint__audit_live` | Preferred; auto-launches Chrome minimized. No manual setup needed. |
| Browser MCP session available and existing session needed | `mcp__accesslint__audit_browser_script` + `mcp__accesslint__audit_browser_collect` | Two-step: inject script, then collect. Use only when the user's existing browser session is required. |
| No live URL, no browser, static artifacts only | WCAG-annotated manual review | See § "Static artifact review" below. |

For live-URL audits, use `mcp__accesslint__audit_live` as the default.
The browser-script pair is the fallback for when a browser MCP is
available and the user explicitly needs their existing session.

### Reading a violation report

Each violation entry from accesslint typically includes:

- **Rule ID** — maps to a WCAG success criterion (e.g., `color-contrast`
  → WCAG 1.4.3).
- **Impact** — `critical`, `serious`, `moderate`, `minor`.
- **Description** — what accesslint detected.
- **Browser hint** (optional) — a follow-up action to inspect in a
  browser. When present, use available browser tools (screenshot,
  inspect) to gather more context before writing the recommendation.

Raw accesslint output is not the deliverable. Every violation must be
synthesized into a design recommendation before returning to `tech-lead`.

### React components without a running app

When the brief targets `.jsx` or `.tsx` components and no running
application is available, use the `audit-react-component` prompt
pattern rather than a live-URL audit. See accesslint documentation for
the current prompt shape.

## WCAG citation format

Every design recommendation must cite the relevant WCAG criterion.
Use this format:

> **WCAG \<version\> \<criterion number\> \<criterion name\> (Level \<A/AA/AAA\>):**
> \<one-sentence description of what the criterion requires\>

Example:

> **WCAG 2.1 1.4.3 Contrast (Minimum) (Level AA):**
> Text and images of text must have a contrast ratio of at least 4.5:1,
> except for large text (3:1), incidental text, or logotypes.

When the finding maps to WCAG 2.2, cite 2.2. When it maps to a
criterion that is identical across 2.1 and 2.2, cite the version the
project has targeted (record the target version in `CUSTOMER_NOTES.md`
at project start if accessibility is in scope).

## Design-feedback synthesis structure

Each finding in the output follows this structure:

```
### <Short title of finding>

**WCAG criterion:** <version + number + name + level>
**accesslint rule:** <rule ID, if automated>
**Impact:** <critical | serious | moderate | minor | manual review>

**Observed issue:**
<One paragraph describing what was found. Quote the specific element
or interaction pattern. If from a static artifact, describe the
artifact and the specific element.>

**Recommended change:**
<One or more concrete, actionable design changes. Name the component
or pattern. Do not prescribe implementation — describe the desired
design outcome.>

**Acceptance criterion:**
<Observable, testable condition that confirms the issue is resolved.>
```

Never return findings as a flat list of accesslint JSON. Always use
this structure, even for a single finding.

## Static artifact review

When no live URL and no browser session are available:

1. List every artifact provided in the brief (screenshots, wireframes,
   HTML files, design specs).
2. For each artifact, walk WCAG 2.1/2.2 criteria relevant to the
   artifact type (visual artifacts: perceivable criteria 1.1–1.4;
   interactive wireframes: operable criteria 2.1–2.5; any written
   spec: understandable criteria 3.1–3.3).
3. Flag any criterion that cannot be evaluated from the artifact
   (e.g., keyboard navigation cannot be assessed from a screenshot)
   as `not assessable from static artifact — requires live review`.
4. Produce recommendations for everything that can be assessed.

Do not return empty output. Every brief has a reviewable artifact,
even if it is a description of intended behavior.

## Relationship to other roles

- **`software-engineer`** implements design artifacts. `ui-ux-designer`
  does not write production code. Pass designs as Markdown specs or
  annotated wireframes; let `software-engineer` own the implementation.
- **`code-reviewer`** reviews the implementation for conformance to the
  design spec.
- **`security-engineer`** handles security implications of UI flows
  (auth UI, PII exposure in forms). Route those concerns there; do not
  absorb security scope.
- **`sre`** handles performance implications of design choices (heavy
  assets, animation cost). Route those concerns there.
