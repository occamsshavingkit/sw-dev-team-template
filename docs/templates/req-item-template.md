# Requirement — <ID> — <one-line title>

One file per requirement per FW-ADR-0004. Each requirement satisfies
the nine characteristics in ISO/IEC/IEEE 29148 § 5.2 (`LIB-0010`):
necessary, implementation-free, unambiguous, consistent, complete,
singular, feasible, traceable, verifiable.

Lives at `docs/req/<ID>.md`. Index entry at `docs/requirements.md`
§ 4 (FR) or § 5 (NFR).

Stewarded by `researcher` for numbering + traceability;
`tech-lead` writes content from customer intake.

---

## Identification

- **ID:** FR-NNNN | NFR-NNNN
- **Type:** Functional | Non-Functional (quality attribute)
- **Title:**
- **Priority:** Must | Should | Could | Won't (MoSCoW)
- **Status:** Draft | Approved | Implemented | Verified | Deprecated
- **Date created:** YYYY-MM-DD
- **Date approved:** YYYY-MM-DD

## Statement

Single sentence. Use the canonical form for the requirement type.

For functional:
> The system shall <action> <object> when <trigger> [under <condition>].

For non-functional (quality attribute):
> Under <context>, when <stimulus>, the system shall <response>
> measured by <response measure>.

## Rationale

One paragraph. Why this requirement exists. The stakeholder need
or regulatory driver behind it.

## Source

- **Stakeholder / regulation / decision:** named source
- **Reference:** `CUSTOMER_NOTES.md` entry, ADR, prior requirement
- **Date captured:**

## Acceptance criteria

Each criterion observable and checkable.

- AC-1: <condition>
- AC-2: <condition>

## Verification

- **Method:** Test | Review | Demonstration | Analysis
- **Test ID(s):** T-NNNN (links to `docs/tests/` artefact)
- **Review reference:** review record link
- **Verified date:** YYYY-MM-DD

## Dependencies

- **Depends on:** other requirement IDs / ADRs
- **Conflicts with:** any contradictory requirement

## Change log

| Date | Change | Who |
|---|---|---|
