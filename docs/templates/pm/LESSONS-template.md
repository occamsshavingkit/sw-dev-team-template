---
name: lessons-template
description: PMBOK Closing lessons-learned template captured continuously plus synthesised at every milestone.
template_class: lessons
---


# Lessons Learned — <project name>

PMBOK Closing artifact **captured continuously**, not only at closure.
Owned by `project-manager`. A running journal plus a synthesis at
every milestone.

## Journal

Append one entry per lesson. Do not delete — if a later entry
contradicts an earlier one, cross-link and mark the earlier one
"superseded".

```
### <YYYY-MM-DD> — <one-line headline>

**Context.** What was happening, what we were trying to do.

**Event.** What actually occurred, observable.

**What went well.**

**What did not.**

**Contributing factors.** Not blame — causal factors, process gaps,
tooling gaps, knowledge gaps, communication gaps.

**Recommendation.** Concrete, actionable change (process, tool,
template, training, check). Name who should own adopting it.

**Category.** schedule / cost / quality / technical / people /
process / customer / tooling / external / sustainability / AI-use.

**References.** Links to `OPEN_QUESTIONS.md` rows, ADRs, commits,
incidents, `CHANGES.md` rows if the lesson led to a change.
```

## Milestone syntheses

At each milestone, `project-manager` summarizes the journal entries
since the last synthesis into:

- Top 3 things that worked.
- Top 3 things to fix.
- Changes made to process / templates / roster as a result (with
  cross-reference to `CHANGES.md` rows).

## Final synthesis

At project closure, consolidate the milestone syntheses into a
single-page project retrospective. File the retrospective back into
the template repository's corpus (if retained) so future projects
benefit.
