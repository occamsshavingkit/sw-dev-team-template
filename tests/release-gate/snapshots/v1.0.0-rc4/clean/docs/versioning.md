# Versioning policy

The template is versioned under **SemVer 2.0.0**
([https://semver.org/](https://semver.org/)) on the template
artifact — `MAJOR.MINOR.PATCH`. This file states what the version
number is claiming and when the template returns to a `v1.0.0-rc`
track.

**Normative reference.** Semantic Versioning 2.0.0,
<https://semver.org/spec/v2.0.0.html>. All version-number semantics
in this document (MAJOR / MINOR / PATCH, pre-release tags, `0.y.z`
initial-development rules) are as defined there.

## Current track: 0.y.z

As of `v0.10.0` (2026-04-20), the template is on the `0.y.z`
track. Under SemVer, `0.y` explicitly permits breaking changes in
minor bumps; `0.y.z` signals "still forming, public contract is
not yet stable." This matches reality: the Gate-3 engagement is
continuing to surface contract-level issues, and at least two
pending themes (terminology rename; memory architecture) are
breaking.

- `0.y` → `0.(y+1)` is allowed to break downstream stamps.
  Migration scripts still ship (`migrations/0.(y+1).0.sh`).
- `0.y.z` → `0.y.(z+1)` is PATCH semantics as usual.
- Breaking changes in a PATCH are not permitted even on the
  `0.y` track.

## History of the track change

`v1.0.0-rc1` (2026-04-19) and `v1.0.0-rc2` (2026-04-19) were cut
on a `v1.0.0-rc` track. Gate-3 engagement then surfaced
issues #4–#29 against those two tags, several of which are
contract-breaking. Rather than compress breaking changes into
multiple MAJOR bumps (`v2.0.0`, `v3.0.0`, …) while the contract
is still being discovered, the template returned to `0.y.z` at
`v0.10.0`. The two `rc` tags remain in git history as a marker.

## Criteria for returning to `v1.0.0-rc`

The template returns to a `v1.0.0-rc` track when **all** of the
following are true. Until then, continue iterating on `0.y.z`.

1. **No open contract-breaking themes.** Every breaking change the
   team knows about has either shipped (and downstream migrations
   are in place) or been explicitly dropped with a recorded
   rationale. Specifically: the terminology-rename question
   (upstream #15) and the memory-architecture decision (upstream
   #16 / #17 / #27 and `V2_ROADMAP.md` §5.5) are resolved.
2. **Two independent downstream engagements pass Gate 3.** One
   engagement has already surfaced issues #4–#29. A second
   independent engagement runs end-to-end without surfacing a new
   rc-class issue. (Gate 3 in the release plan tracks this.)
3. **All rc-cycle issues are resolved or explicitly deferred**
   with recorded rationale (Gate 4).
4. **Agent roster is stable.** No pending agent additions,
   removals, or tool-grant audits. The `tools:` frontmatter on
   every agent has been audited against declared escalation
   behaviour (issue #11, #14).
5. **Scaffold + upgrade + retrofit are all implemented and
   covered by smoke tests.** Retrofit (`V2_ROADMAP.md` §1) ships
   before `v1.0.0` because the third adoption door is part of
   the public contract.

When these are met, the next minor cut may be labelled
`v1.0.0-rc1` (fresh rc numbering) and the Gate sequence resumes
from there.

## What `v1.0.0` means when it finally cuts

`v1.0.0` is a promise:

- The binding-file list (`AGENTS.md`, `CLAUDE.md`,
  `SW_DEV_ROLE_TAXONOMY.md`, `docs/glossary/*.md`,
  `docs/agent-health-contract.md`, all templates under
  `docs/templates/`) will not be renamed,
  removed, or substantively reshaped without a MAJOR bump.
- The agent-roster shape — file names under `.claude/agents/`,
  tool grants, escalation contract — is backward-compatible within
  a MAJOR.
- `scaffold.sh`, `upgrade.sh`, and `retrofit.sh` CLI contracts are
  stable within a MAJOR.
- Downstream projects stamped at any `v1.x` release can upgrade
  to any later `v1.y` without manual intervention beyond
  `upgrade.sh` (and the migration scripts it runs).

Anything that would violate these promises is a MAJOR change and
gets a `v2.0.0` cut, with a migration path.

## Downstream implications of the track change

- Downstream projects stamped at `v1.0.0-rc1` or `v1.0.0-rc2`
  restamp to `v0.10.0` on their next `upgrade.sh` run. No content
  migration; the rc2 → 0.10.0 transition is purely a version
  label change.
- Any documentation or issue body that cites `v1.0.0-rc2` remains
  valid as a point-in-time reference; those citations are not
  edited retroactively.
- Issues filed going forward against `v0.10.x` use the new stamp.
