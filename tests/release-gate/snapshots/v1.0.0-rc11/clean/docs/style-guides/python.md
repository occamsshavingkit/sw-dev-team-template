# Python style guide — seed

Seed file. Projects may extend; changes propose via
`architect` + `software-engineer` consensus and land with a row in
`docs/pm/CHANGES.md`.

## Baseline standards

- **PEP 8** — Style Guide for Python Code. Binding baseline.
- **PEP 257** — Docstring Conventions.
- **PEP 484** + PEP 585 / 604 — Type hints (modern syntax
  required: `list[int]`, `X | None`, not `List[int]` / `Optional[X]`).

## Required toolchain

| Tool | Role | Config |
|---|---|---|
| `ruff` | lint + import-sort | `pyproject.toml` `[tool.ruff]` |
| `ruff format` (or `black`) | formatter | 88-column default; override only with reason |
| `mypy` (or `pyright`) | static type check | strict mode on new code; gradual on legacy |
| `pytest` | test runner | see `docs/templates/qa/unit-test-plan-template.md` |

CI enforces `ruff check`, `ruff format --check`, and
`mypy --strict` on every PR — see `release-engineer`'s pipeline.

## Style points (beyond PEP 8)

- **Type hints required** on public functions / methods / class
  attributes. Private helpers at author's discretion.
- **f-strings** for formatting; no `%`-formatting; `.format()` only
  where dynamic template strings are needed.
- **Pathlib** over `os.path` for new code.
- **Exceptions** — raise specific exception types; never bare
  `except:`; prefer `except SpecificError` over `except Exception`.
- **Logging** — standard `logging` module; no `print` in library
  code; structured logging encouraged (JSON formatter in prod).

## Anti-patterns

- Mutable default arguments.
- Global state that crosses module boundaries.
- Try / except that silently swallows errors.
- Dynamic `**kwargs` on public API surface (use explicit args).

## References

- PEP 8 https://peps.python.org/pep-0008/
- PEP 257 https://peps.python.org/pep-0257/
- PEP 484 https://peps.python.org/pep-0484/
- Ruff docs https://docs.astral.sh/ruff/
- Google Python Style Guide (supplementary, Tier-2)
  https://google.github.io/styleguide/pyguide.html
