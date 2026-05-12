# Unit Test Plan — <project or subsystem>

Shape per ISTQB Foundation "Component testing" + IEEE 829 Level
Test Plan. Owned jointly by `software-engineer` (writes the tests)
and `qa-engineer` (defines coverage expectations).

## 1. Scope

- Modules / files in scope.
- Units explicitly excluded (UI, hardware-coupled, IaC).

## 2. Entry / exit criteria

- **Entry:** unit exists; public interface is stable enough to test.
- **Exit:** coverage targets met (§4); all tests green in CI.

## 3. Test design approach

- **Specification-based** (black-box) — equivalence partitioning,
  boundary-value, decision-table.
- **Structure-based** (white-box) — statement / branch / MC-DC
  coverage targets.
- **Experience-based** — error guessing on high-risk units only.

## 4. Coverage targets

| Unit class | Coverage | Type | Rationale |
|---|---|---|---|
| Safety-critical | ≥ 95 % branch | structure-based | CLAUDE.md Hard Rule #2 |
| Core business logic | ≥ 80 % branch | specification + structure | default |
| Boilerplate / generated | n/a | — | exempt with reason |

## 5. Test data

In-repo fixtures, no production data. Record path under
`tests/fixtures/` or language-idiomatic equivalent.

## 6. Tools

- Framework (pytest / vitest / cargo test / go test / bats).
- Coverage reporter.
- Mutation testing (optional) for high-assurance modules.

## 7. Defect flow

Unit test failure on a previously-green unit → treat as incident;
fix before adding more tests. Every new bug fix adds a unit test
that would have caught it.

## 8. Traceability

Each test names the requirement ID it exercises (in the test
docstring or per-test metadata). Requirements live in
`docs/requirements.md`.

## 9. References

- ISTQB Foundation Level Syllabus.
- `docs/templates/qa/test-strategy-template.md`.
- SWEBOK V4 ch. 5 "Software Testing" §§2–3.
