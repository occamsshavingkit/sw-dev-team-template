# Audit Tables: Token Economy Design Pass (Spec 016)

**Date**: 2026-05-28  
**Feature ref**: `specs/016-token-economy-design/spec.md`  
**Branch**: `016-token-economy-design`

---

## Baseline

| Role | M0 words (cap) | 80% ceiling | Current words | % of cap | Status |
|---|---:|---:|---:|---:|---|
| architect | 844 | 675 | 860 | 101.9 | above-80% |
| code-reviewer | 528 | 422 | 535 | 101.3 | above-80% |
| onboarding-auditor | 944 | 755 | 1069 | 113.2 | above-80% |
| process-auditor | 1253 | 1002 | 1481 | 118.2 | above-80% |
| project-manager | 1124 | 899 | 1410 | 125.4 | above-80% |
| qa-engineer | 1061 | 848 | 737 | 69.5 | at-or-below-80% |
| release-engineer | 689 | 551 | 797 | 115.7 | above-80% |
| researcher | 1996 | 1596 | 1508 | 75.5 | at-or-below-80% |
| security-engineer | 865 | 692 | 883 | 102.1 | above-80% |
| software-engineer | 555 | 444 | 566 | 102.0 | above-80% |
| sre | 595 | 476 | 773 | 129.9 | above-80% |
| tech-lead | 3909 | 3127 | 1462 | 37.4 | at-or-below-80% |
| tech-writer | 357 | 285 | 365 | 102.2 | above-80% |

**Notes**:

T005: tech-lead headroom = 1665 words (3127 − 1462); ≥250-word floor cleared; Half A may proceed.

T006: SC-005 thin margin — monitor (Σ Current = 12446, Σ M0 = 14720, ratio = 0.846 > 0.85). Ten of thirteen contracts are currently above their 80% ceiling; aggregate cuts must reach ≥15% of Σ M0 (~2208 words removed net). SC-005 reachable but requires substantive cuts across the above-80% contracts.

Gate 0 signed off: 2026-05-28 — architect.

---

## Proposals

| Role | Span (line range or anchor) | Tag | Before (excerpt) | After (excerpt) | Manual pointer (if `manual-echo`) | tech-writer notes | Status |
|---|---|---|---|---|---|---|---|

---

## Post-cut

| Role | M0 words (cap) | 80% ceiling | Post-cut words | % of cap | Delta words | All cuts tagged? |
|---|---:|---:|---:|---:|---:|---|

---

## Gate Sign-offs

| Gate | Reviewer | Sign-off line | Date |
|---|---|---|---|
| Gate 0 | architect | _(pending T007)_ | — |
| Gate 1 — Half A | architect | _(pending T030)_ | — |
| Gate 1 — Half B | tech-writer | _(pending T031)_ | — |
| Gate 2 | code-reviewer | _(pending T034)_ | — |
| Gate 3 | customer | _(pending T036)_ | — |
