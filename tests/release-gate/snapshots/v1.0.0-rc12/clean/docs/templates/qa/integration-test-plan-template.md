# Integration Test Plan — <project or subsystem>

Shape per ISTQB "Integration testing" + IEEE 829 Level Test Plan.
Owned by `qa-engineer`; inputs from `architect` on interface
boundaries.

## 1. Scope

- Integrations in scope (component-to-component, service-to-service,
  service-to-external).
- Integration approach: big-bang / top-down / bottom-up / sandwich /
  continuous.

## 2. Interfaces under test

| Interface | From | To | Contract | Test depth |
|---|---|---|---|---|
| | | | OpenAPI / schema / wire format | shallow / deep |

## 3. Stubs, drivers, virtual services

- External services stubbed for hermetic testing.
- Contract tests (Pact-style) pin the contract in both directions.

## 4. Test data

Shared fixtures for cross-component scenarios. No production data.

## 5. Entry / exit criteria

- **Entry:** unit tests passing on all integrated components;
  contracts defined.
- **Exit:** integration tests green; no known contract violations;
  coverage target on interface paths.

## 6. Defect flow

Interface defect → joint triage `qa-engineer` + `architect` → fix
owner assigned → re-test.

## 7. Traceability

Tests cite the interface contract version (commit / tag) and the
requirement rows exercised.

## 8. References

- ISTQB Foundation Level Syllabus.
- `docs/templates/qa/test-strategy-template.md`.
- Contract docs (OpenAPI / AsyncAPI / Protobuf / ADR-referenced).
