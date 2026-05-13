# Framework / Project Boundary

This template lives inside each downstream repository so agents can
operate there, but the template is not the product. Treat the working
tree as three layers with different owners and review paths.

## Documentation Authority

Every artifact in this repository is canonical, generated, or ephemeral.
Manual mirrors of shared content are prohibited: if two files need the same content, one MUST be generated from the other, link to the other, or be removed in favor of the other.
Generated artifacts MUST identify their canonical inputs and be reproducible by documented tooling before they are used as operational guidance.

This policy is FR-014 + M4.1 in `specs/006-template-improvement-program/spec.md` and resolves the Constitution III source-authority requirement.

## Path ownership

| Layer | Owner | Typical paths | Default handling |
|---|---|---|---|
| Framework-managed / template-upgrade files | Upstream `sw-dev-team-template` | `CLAUDE.md`, `AGENTS.md`, shipped `.claude/agents/*.md`, `scripts/`, `migrations/`, `docs/templates/`, `docs/INDEX-FRAMEWORK.md`, `docs/adr/fw-adr-*.md`, template versioning docs, rc stabilization docs, final checklist docs, scaffold / upgrade scripts, `TEMPLATE_MANIFEST.lock` | Change only during an explicit template upgrade or framework-maintenance task. Otherwise file an upstream issue. |
| Project-filled registers | Downstream project, by named steward | `CUSTOMER_NOTES.md`, `docs/OPEN_QUESTIONS.md`, `docs/AGENT_NAMES.md`, `docs/pm/*.md`, `docs/glossary/PROJECT.md`, `.claude/agents/*-local.md`, `.template-customizations`, `TEMPLATE_VERSION` | Edit through the owning role and keep with the project work that changed the facts. |
| Project-owned product files | Downstream project | Product source, tests, build config, deployment config, `README.md`, product requirements, project ADRs `docs/adr/[0-9][0-9][0-9][0-9]-*.md`, `docs/INDEX-PROJECT.md`, domain docs, runbooks | Normal product work. Review without framework churn. |

When ownership is unclear in a scaffolded project, check
`TEMPLATE_MANIFEST.lock`: paths listed there are shipped by the
template unless `.template-customizations` intentionally removes them
from upgrade control. Project-created paths are project-owned by
default.

## Release and version artifact scope

Before a release-engineer audit or release fix writes anything in a
downstream project, classify each release / version artifact as one of:

- **Downstream product artifact:** product CI, packaging, deployment,
  rollback, changelog, product version file, product release notes, and
  product-owned runtime configuration.
- **Project-filled template register:** `TEMPLATE_VERSION` records the
  upstream template version used by that downstream project. It changes
  during scaffold or template upgrade flows, not during ordinary
  product release audits.
- **Upstream framework / template artifact:** template versioning docs,
  rc stabilization docs, scaffold scripts, upgrade scripts, shipped
  agent contracts, templates, manifests, migrations, and other paths
  shipped by `sw-dev-team-template`.

Product-only release audits may inspect framework artifacts only to
avoid mixing scopes. They must not edit `TEMPLATE_VERSION`, template
versioning docs, rc stabilization docs, final checklist docs,
scaffold / upgrade scripts, or other framework-managed files unless the
customer explicitly asks for template upgrade or framework-maintenance
work in the current task.

If a product-only release audit finds a framework defect, leave the
downstream copy unchanged and file or queue an upstream issue through
`docs/ISSUE_FILING.md`, subject to issue-feedback opt-in.

## Review guidance

For a product review, exclude framework-managed paths unless the task
explicitly includes template maintenance. A practical product-review
diff is:

```sh
git diff -- . \
  ':(exclude)CLAUDE.md' \
  ':(exclude)AGENTS.md' \
  ':(exclude).claude/agents/**' \
  ':(exclude)scripts/**' \
  ':(exclude)migrations/**' \
  ':(exclude)docs/templates/**' \
  ':(exclude)docs/INDEX-FRAMEWORK.md' \
  ':(exclude)docs/adr/fw-adr-*.md' \
  ':(exclude)docs/v*-stabilization.md' \
  ':(exclude)docs/v*-checklist.md' \
  ':(exclude)TEMPLATE_MANIFEST.lock'
```

If a review tool does not support path filters, stage or commit the
product work separately first, then ask the tool to review that commit
or PR. Do not ask for "all uncommitted changes" review when a template
upgrade or framework edit is also present.

## Commit and PR split

Use separate commits, and usually separate PRs, for these work types:

- **Product work:** source, tests, product docs, project ADRs, and the
  register updates needed to support that product change.
- **Template upgrade:** output from `scripts/upgrade.sh`, including
  framework-managed file updates, `TEMPLATE_VERSION`, and
  `TEMPLATE_MANIFEST.lock`.
- **Framework maintenance:** local changes intended to be proposed
  upstream to `sw-dev-team-template`.

If a product task reveals a framework bug, do not mix the fix into the
product commit. File it upstream through `docs/ISSUE_FILING.md`, or
start a separate framework-maintenance branch if the customer
explicitly authorizes local framework work.

Before closing a product-only audit or fix, check the diff for
framework-managed files. Any accidental framework-file edit blocks
completion until it is split into an authorized template /
framework-maintenance task or removed without disturbing unrelated
work.

## Downstream framework gaps

When a downstream project finds a missing or wrong template rule,
agent instruction, script behavior, or document shape, the default is:

1. Finish or protect the product work without editing the framework
   file locally.
2. File the framework gap upstream using `docs/ISSUE_FILING.md`,
   subject to the project's issue-feedback opt-in.
3. Keep only project-specific adaptations in project-owned places such
   as `.claude/agents/*-local.md`, `.template-customizations`, project
   ADRs, or project docs.

Local framework edits are allowed only when the customer explicitly
authorizes template upgrade or framework-maintenance work for the
current task. Record that authorization in the Turn Ledger or task log.
