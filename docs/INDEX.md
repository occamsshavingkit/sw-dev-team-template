# Docs Index

Two indexes, one dispatcher.

Per FW-ADR-0006 / FW-ADR-0007 follow-up (issue #66): the docs index
is split so framework-shipped content and project-authored content
don't collide on every upgrade. This file is the dispatcher; the
real content lives in two siblings.

| Index | Owner | Upgrade behaviour |
|---|---|---|
| [`INDEX-FRAMEWORK.md`](INDEX-FRAMEWORK.md) | Template | Replaced by upstream on every `scripts/upgrade.sh`. Project never edits. Lists shipped framework files (scripts, agent contracts, templates, framework ADRs). |
| [`INDEX-PROJECT.md`](INDEX-PROJECT.md) | Project | Listed in `.template-customizations` from scaffold time. Project edits freely (per-project ADRs, retrofit logs, research surveys, friction reports, audits, anything else under `docs/`). Never overwritten by upgrade. |

This `INDEX.md` is itself project-owned (added to
`.template-customizations` at scaffold). Replace this dispatcher
text with whatever shape suits your project — but keep links to
both siblings so a fresh reader can find each.
