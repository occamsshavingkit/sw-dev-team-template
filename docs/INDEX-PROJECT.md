# Project Docs Index

Project-authored content. Edit freely. This file is project-owned —
listed in `.template-customizations` from scaffold time, so
`scripts/upgrade.sh` never overwrites it.

For framework-shipped files (scripts, agent contracts, standard
templates, framework ADRs), see
[`INDEX-FRAMEWORK.md`](INDEX-FRAMEWORK.md). It updates with every
upgrade and you don't need to maintain it.

For path ownership and review splitting in a downstream repository,
see [`framework-project-boundary.md`](framework-project-boundary.md).
Use that boundary before asking review tools to inspect product work
when template-upgrade files are also dirty.

Add sections below as the project grows. Common ones:

## `docs/adr/` (project-authored ADRs)

Project ADRs use the bare `ADR-NNNN` namespace; framework ADRs use
the `FW-ADR-NNNN` namespace (per FW-ADR-0007 / issue #67). The two
do not collide.

| File | Decision |
|---|---|
| <!-- e.g. `docs/adr/0001-some-project-decision.md` --> | <!-- one-line summary --> |

## `docs/pm/` (project-manager artefacts)

| File | Purpose |
|---|---|
| <!-- e.g. `docs/pm/CHARTER.md` --> | <!-- once filled --> |

## `docs/sme/<domain>/` (per-domain SME inventories)

| File | Purpose |
|---|---|
| <!-- e.g. `docs/sme/brewing/INVENTORY.md` --> | <!-- once present --> |

<!-- Add other project-specific sections as needed:
     research/, audits/, retrofit/, qa-findings/, notes/, etc. -->
