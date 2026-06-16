---
name: sa-v1.5.2-authoring-guard
description: Security assurance artefact for v1.5.1/v1.5.2 template changes — subcall-budget guard and authoring-guard agent_type/SME-path update.
status: signed-off-with-conditions-met
date: 2026-06-16
security_engineer: security-engineer
customer_signoff_date: 2026-06-16
---

# Security Assurance — Template v1.5.2 Authoring Guard (+ v1.5.1 Subcall Budget)

Shape per `docs/templates/security-template.md`.  
SWEBOK V4 ch. 13 "Software Security" (library row LIB-0002).  
ISO/IEC 15026-2:2022 assurance-case structure applied in §8.

**Reviewed by:** `security-engineer`  
**Verdict:** SIGN-OFF-WITH-CONDITIONS — conditions satisfied by accepted residuals documented herein and customer sign-off recorded 2026-06-16 in `CUSTOMER_NOTES.md`.  
**Hard Rule #7 coverage:** changes touch an internal authorization control; sign-off required and given.

---

## 1. Scope and threat model

### Assets

| Asset | Classification | Notes |
|---|---|---|
| Workflow integrity of the tech-lead orchestration boundary | Internal — team-process control | Enforced by Hard Rule #8 (CLAUDE.md). The guard prevents the main tech-lead session from directly authoring specialist-owned artefacts. |
| Agent-framework hook execution chain | Internal — orchestration infrastructure | `PreToolUse` hooks in `.claude/settings.json`; runs before every Write / Edit / Bash tool call in the main session. |

### Actors

| Actor | Trust level | Notes |
|---|---|---|
| Claude Code harness | Trusted | Constructs hook event JSON; controls `agent_type` / `subagent_role` in the top-level payload. |
| Main session (tech-lead) | Constrained | Subject of the guard; can set `SWDT_AGENT_PUSH` env and write to `ALLOW_EXACT` paths. |
| Named specialist subagents | Trusted for their role | Identified via `agent_type` / `subagent_role` in hook events or `ANTIGRAVITY_CONVERSATION_ID` + `active-dispatches.json`. |
| Operator (customer) | Trusted | Controls env vars (`SWDT_AGENT_PUSH`, `SWDT_SUBCALL_BUDGET`, `ANTIGRAVITY_CONVERSATION_ID`). |

### Threats (STRIDE)

| STRIDE category | Threat | Guard response |
|---|---|---|
| **Spoofing** | Main session claims to be a specialist (via `agent_type`) to write off-allow-list paths. | `agent_type` is harness-set in the top-level hook event, not injected from model `tool_input`. `_validate_role` rejects `"tech-lead"` explicitly and all unrecognised values (fail-closed). See accepted residual AR-1. |
| **Tampering** | Tech-lead authors a production artefact (script, ADR, test) directly, bypassing specialist-routing requirement. | `_evaluate_paths` + `_decide_for_command` deny off-allow-list writes; deny payload names the owning specialist. |
| **Repudiation** | Escape-hatch use (SWDT_AGENT_PUSH / agent_type override) is unlogged. | `_audit_override` writes a timestamped line to stderr for every permitted override. |
| **Elevation of privilege** | Tech-lead widens its own allow-list via `SWDT_AGENT_PUSH=tech-lead`. | `_validate_role` (lines 734–754) explicitly rejects `"tech-lead"` before the canonical-roles check. Inline and env-var forms both blocked; tested in the tightening#2 suite. |
| **Elevation of privilege** | Two-step Antigravity bypass via `active-dispatches.json`. | Accepted residual AR-2; see §8. |

### Trust boundaries

- **Harness / hook boundary:** The Claude Code harness feeds hook events via stdin. The guard trusts the harness to correctly populate (or omit) `agent_type` for each session type. This trust assumption is explicit in accepted residual AR-1.
- **Project directory boundary:** `CLAUDE_PROJECT_DIR` defines the scope of HR-8. Absolute paths outside this directory are explicitly out-of-scope (issues #205, #206); `_is_outside_project` + `_is_harness_path` short-circuit before allow-list checks.
- **Env-var boundary:** `SWDT_AGENT_PUSH` and `SWDT_SUBCALL_BUDGET` are operator-controlled env vars, not model-output-controllable.

### Out of scope

- Customer-domain auth/authz (HIPAA, PCI-DSS, GDPR) — not applicable to this agent-framework tooling.
- Network-exposed endpoints — none; this is a local hook.
- `CUSTOMER_NOTES.md` write control — governed by the separate `customer-notes-guard.py` (runs before this hook per FW-ADR-0012 ordering invariant).

---

## 2. Security requirements (SWEBOK V4 ch. 13 §4.1)

Traceable to Hard Rule #8 (CLAUDE.md) and FW-ADR-0012.

| ID | Requirement | Category | Source |
|---|---|---|---|
| SR-01 | Tech-lead main session must not write production artefacts outside the enumerated allow-list. | AuthZ | CLAUDE.md Hard Rule #8; FW-ADR-0012 §Allow-list specification |
| SR-02 | Specialist-role identity carried in hook events must be validated against the canonical role set; `tech-lead` self-identification must be rejected. | AuthZ / Integrity | FW-ADR-0012 §Escape-hatch semantics |
| SR-03 | Override use (escape-hatch, agent_type bypass) must be logged to stderr for auditability. | Auditability | FW-ADR-0012; `_audit_override` |
| SR-04 | Guard must fail-closed on unrecognised callers; fail-open only on parse-level errors where the harness cannot construct a valid event. | AuthZ | FW-ADR-0012 |
| SR-05 | SME scaffold paths (`.claude/agents/sme-*.md`, `docs/sme/**`) must be writable by tech-lead for per-project SME creation. | AuthZ | CLAUDE.md §Agent roster; `docs/sme/CONTRACT.md` |
| SR-06 | Subcall spawn budget must be enforced per session; operator may raise the budget via `SWDT_SUBCALL_BUDGET`. | Availability | CLAUDE.md agent-teams panel; subcall-limit-guard |

---

## 3. Design patterns applied (SWEBOK V4 ch. 13 §§4.2, 4.3)

| Pattern | Application |
|---|---|
| **Allowlist (positive security model)** | `ALLOW_EXACT` + `ALLOW_GLOBS_SHALLOW` + `ALLOW_GLOBS_RECURSIVE` enumerate exactly what tech-lead may write. Everything else is denied by default. |
| **Defense-in-depth** | Three-pronged enforcement: (1) this PreToolUse hook (primary preventive), (2) FW-ADR-0011 trailer convention (audit), (3) `scripts/lint-routing.sh` (durable-artefact lint). |
| **Least privilege** | Tech-lead's write surface is the minimum required for orchestration artefacts; specialist outputs route to owning agents. |
| **Fail-closed** | Unrecognised role values, invalid JSON parse (non-harness-originated), and missing `tool_input` all result in deny or silent proceed (no widening). |
| **Explicit trust hierarchy** | Harness-set fields (`agent_type`, `subagent_role`) are trusted over any model-injectable path; model can only reach `tool_input`, which is governed by path/command scanning. |
| **Non-repudiation via audit log** | Every escape-hatch activation writes `source=role override permitted write to path` to stderr. |

Cross-reference: FW-ADR-0012 (`docs/adr/fw-adr-0012-tech-lead-authoring-guard.md`).

---

## 4. Construction controls (SWEBOK V4 ch. 13 §4.4)

**Secure coding standards:**
- Role validation centralised in `scripts/hooks/lib/roles.py`; no inline frozenset duplication.
- `_validate_role` explicitly rejects `"tech-lead"` before the canonical-roles check (code-reviewer tightening #2).
- `os.path.normpath` applied before all glob comparisons to neutralise `..`-traversal in path inputs.
- Exception handling in `_load_customer_notes_guard`, `_active_dispatch_subagent_role`, and subcall I/O uses narrow except-with-log (not broad silent swallow, per Codacy PR #173 requirement).

**Input validation:**
- Hook event JSON validated for dict type; `tool_input` validated for dict type before path extraction.
- Per-field type checks on `agent_type` / `subagent_role` (`isinstance(role, str)`).
- Path normalisation (`_normalise`) applied to all candidate paths before allow-list comparison.
- Role values validated through `_validate_role` regardless of source (env, inline, `agent_type`, `subagent_role`, `active-dispatches.json`).

**Output encoding:** Deny payload is `json.dumps()`-serialised; no user-controlled string is interpolated into the decision JSON without being the deny-reason message (which is internal-facing only).

**Secrets management:** No secrets in scope. `SWDT_AGENT_PUSH` is an internal workflow token, not a credential.

**Dependency policy:** Standard library only (`json`, `os`, `pathlib`, `re`, `fnmatch`, `sys`, `importlib`). No third-party dependencies.

---

## 5. Security testing plan (SWEBOK V4 ch. 13 §4.5)

**Static analysis:** Code reviewed by `security-engineer` and `code-reviewer` per Hard Rule #3. No external SAST tool run on this patch (hook is stdlib-only Python; no dependency surface).

**Unit/integration test suite (primary evidence):**
- `tests/hooks/test-tech-lead-authoring-guard.sh` — comprehensive behaviour coverage. Covers:
  - Allow-list exact and glob paths (proceed).
  - Off-list paths with specialist routing hints (deny).
  - SWDT_AGENT_PUSH escape-hatch (all four forms: env, inline, `export`, after-`&&` denial).
  - Bash write-pattern detection (redirect, tee multi-target, sed -i, heredoc, open() positional and kwarg mode, pathlib write methods).
  - CUSTOMER_NOTES.md deferral.
  - Fail-open on malformed input (four cases).
  - Regression suite (Codacy PR #173, issues #175–#180, #184, #205–#208).
  - **New in v1.5.2:** `agent_type` allow (specialist), `agent_type` deny (invalid role, tech-lead), `subagent_role` alias, and `active-dispatches.json` Antigravity auto-bypass (including unmapped and invalid-role denial cases).
  - **New in v1.5.2:** SME allow-list entries (`.claude/agents/sme-brewing.md`, `docs/sme/brewing/notes.md`).
- `tests/hooks/test-subcall-limit-guard.sh` (new in v1.5.1/v1.5.2) — covers default budget initialisation, env override, exhaustion denial, reset, deny-message content, invalid/zero/negative `SWDT_SUBCALL_BUDGET` fallback.

**Dynamic / penetration testing:** Not applicable to this internal hook (no network surface, no user-facing authentication).

**ML-security:** Not applicable.

---

## 6. Vulnerability management (SWEBOK V4 ch. 13 §4.6)

No third-party dependencies; CVE/advisory monitoring not applicable to this component. 

Framework-level vulnerability management: upstream issues filed at `occamsshavingkit/sw-dev-team-template`; template SBOM (§7) covers the hook scripts and their standard-library imports.

---

## 7. SBOM and supply chain

**Components in scope for this patch:**

| File | Type | Dependencies |
|---|---|---|
| `scripts/hooks/tech-lead-authoring-guard.py` | Python 3.x script | stdlib only: `fnmatch`, `importlib.util`, `json`, `os`, `pathlib`, `re`, `sys` |
| `scripts/hooks/subcall-limit-guard.py` | Python 3.x script | stdlib only: `json`, `os`, `sys`, `pathlib` |
| `scripts/hooks/subcall-limit-reset.py` | Python 3.x script | stdlib only: `json`, `os`, `sys`, `pathlib` |
| `scripts/hooks/lib/roles.py` | Python 3.x module | stdlib only: `re` |

No external package manager entries. Supply-chain attack surface: nil (no PyPI / npm / gem dependencies in these files).

Full framework SBOM generation: `release-engineer` via the scaffold build pipeline (out of scope for this patch-level artefact).

---

## 8. Assurance case and sign-off (ISO/IEC 15026-2:2022)

### Claim

The `tech-lead-authoring-guard.py` hook, as shipped in template v1.5.2, correctly enforces Hard Rule #8 (SWEBOK V4 ch. 13 §4.1 AuthZ requirement SR-01) for the following change set:
- Recognition of `agent_type` as the canonical Claude Code caller-identity field (with `subagent_role` retained as a compatibility alias).
- Preservation of the Google Antigravity `active-dispatches.json` fallback.
- Continued denial of `tech-lead` main-session off-allow-list writes and unknown-main-session callers.
- Addition of an allow-list for SME scaffold paths (`.claude/agents/sme-*.md`, `.claude/agents/sme-*-local.md`, `docs/sme/**`).

The `subcall-limit-guard.py` + `subcall-limit-reset.py` (v1.5.1) correctly enforce a configurable spawn-budget cap (SR-06); the guard is a resource-management control, not an authorization gate, and its fail-open on I/O errors is appropriate.

### Evidence

| Evidence item | Location | Status |
|---|---|---|
| Authoring-guard test suite (95+ cases) | `tests/hooks/test-tech-lead-authoring-guard.sh` | Passes |
| Subcall-limit test suite | `tests/hooks/test-subcall-limit-guard.sh` | Passes |
| Code review | `code-reviewer` sign-off recorded in dispatch log | Complete |
| Security review | This document | Complete |
| Mirror parity | scaffold ↔ meta copies confirmed byte-identical | Confirmed 2026-06-16 |
| FW-ADR-0012 | `docs/adr/fw-adr-0012-tech-lead-authoring-guard.md` | Accepted 2026-05-14 |

### Accepted residuals

#### AR-1 — Harness-trust assumption on `agent_type`

**Description:** `_event_subagent_role` (lines 808–827 of `scripts/hooks/tech-lead-authoring-guard.py`) reads `agent_type` and `subagent_role` from the top-level hook event dict. The guard's effectiveness for the `agent_type` bypass path depends on the Claude Code harness NOT populating `agent_type` with a canonical specialist role name in main-session PreToolUse events.

**Why this is safe:** In Claude Code's PreToolUse hook architecture, the hook JSON is constructed by the harness from tool-call metadata and session context. The model can only inject into `tool_input`; top-level event fields are harness-controlled. A main-session tech-lead cannot place a specialist role name into `agent_type` via its tool call content. `_validate_role` (lines 734–754) adds a second gate, explicitly rejecting `"tech-lead"` and all unrecognised values.

**Residual risk:** If the Claude Code harness changes to populate `agent_type` from a model-controllable source in a future version, or if an undocumented edge case exists today, the bypass gate could be defeated. This is a harness-implementation assumption, not a code invariant in this hook.

**Accepted:** Customer accepted 2026-06-16. CUSTOMER_NOTES.md entry appended by librarian same date.

**Monitoring:** Re-evaluate when upgrading to a new major version of Claude Code if the hook event schema changes.

---

#### AR-2 — Antigravity two-step bypass via `active-dispatches.json` (pre-existing)

**Description:** `docs/pm/active-dispatches.json` is on `ALLOW_EXACT` (line 41 of `tech-lead-authoring-guard.py`), meaning tech-lead can write to it directly. In an Antigravity harness environment where `ANTIGRAVITY_CONVERSATION_ID` is set, tech-lead could write its own conversation ID mapped to a canonical specialist role (e.g. `"software-engineer"`) and trigger `_active_dispatch_subagent_role` (lines 830–857) to bypass the off-allow-list write denial for an off-list path.

**Why accepted:**
1. `_validate_role` still blocks any `"tech-lead"` self-mapping.
2. This two-step path pre-dates v1.5.2 (`active-dispatches.json` was already on `ALLOW_EXACT`).
3. `SWDT_AGENT_PUSH=<role>` already provides a simpler, explicit, single-step equivalent bypass accepted in FW-ADR-0012 §Escape-hatch semantics.
4. The guard's threat model is **accidental HR-8 violations**, not an adversarial main session. A main session deliberately constructing a two-step bypass is outside the designed threat scope.

**Accepted:** Customer accepted 2026-06-16. CUSTOMER_NOTES.md entry appended by librarian same date.

---

### Non-blocking follow-ups (recommended future cleanups)

These do not affect the sign-off; record for the next scheduled cleanup pass.

| ID | Finding | Severity | Recommendation |
|---|---|---|---|
| FU-1 | `fnmatch.fnmatchcase` allows `*` to match `/`, so `.claude/agents/sme-foo/bar.md` matches `.claude/agents/sme-*.md`. Tech-lead can write `.md` files to subdirectories under `sme-*/`, not only flat files in `.claude/agents/`. Not exploitable outside the SME namespace (normpath blocks traversal). | LOW | Accept as-is (SME subdirs are a reasonable scope), or tighten by asserting the normalised path contains no second `/` after `.claude/agents/sme-`. File upstream issue against `scripts/hooks/tech-lead-authoring-guard.py`. |
| FU-2 | `_CNG` (result of `_load_customer_notes_guard()` at line 108) is assigned but never referenced after that line. The vendored write-pattern helpers are reimplemented directly in the file; the import is vestigial and produces a dead module load on every hook invocation. | INFORMATIONAL | Remove the `_load_customer_notes_guard()` call and `_CNG` assignment in a future cleanup PR. No security impact. |

### Sign-off record

**Security-engineer sign-off:** SIGN-OFF-WITH-CONDITIONS — conditions satisfied by accepted residuals AR-1 and AR-2 documented above; no code changes required.

**Customer sign-off:** Approved 2026-06-16. Verbatim customer response: "Approve & ship". Recorded in `CUSTOMER_NOTES.md` by librarian. Per CLAUDE.md Hard Rule #7 this sign-off is required and is on record.

**Release gate:** This artefact satisfies the Hard Rule #7 pre-release requirement for changes touching an authorization control. Cite this document path in the release commit message.

---

## 9. References

- SWEBOK V4 ch. 13 "Software Security" (library row LIB-0002) — primary normative reference.
- ISO/IEC 15026-2:2022 "Systems and software assurance — Assurance case" — §8 structure.
- ISO/IEC 27001:2022 control A.8.28 (Secure coding) — construction controls §4.
- CLAUDE.md Hard Rule #8 (tech-lead authoring boundary) and Hard Rule #7 (security-sensitive release sign-off).
- `docs/adr/fw-adr-0012-tech-lead-authoring-guard.md` — authoritative design record for this control.
- `scripts/hooks/tech-lead-authoring-guard.py` — primary implementation, v1.5.2.
- `scripts/hooks/subcall-limit-guard.py` + `subcall-limit-reset.py` — subcall-budget control, v1.5.1.
- `tests/hooks/test-tech-lead-authoring-guard.sh` — primary test evidence.
- `tests/hooks/test-subcall-limit-guard.sh` — subcall test evidence.
- `CUSTOMER_NOTES.md` — customer sign-off entry, 2026-06-16.
