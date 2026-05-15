# TypeScript style guide — seed

Seed file. Projects may extend; changes propose via
`architect` + `software-engineer` consensus and land with a row in
`docs/pm/CHANGES.md`.

## Baseline standards

- **TypeScript handbook** — language semantics.
- **tsconfig strict mode** — binding baseline. `strict: true` plus
  `noUncheckedIndexedAccess`, `noImplicitOverride`,
  `exactOptionalPropertyTypes`, `noFallthroughCasesInSwitch`.

## Required toolchain

| Tool | Role | Config |
|---|---|---|
| `tsc --noEmit` | type check | `tsconfig.json` strict |
| `eslint` + `@typescript-eslint` | lint | `.eslintrc` with recommended-type-checked |
| `prettier` | formatter | 80-col default; override with reason |
| `vitest` (or `jest`) | test runner | see `docs/templates/qa/unit-test-plan-template.md` |

CI enforces `tsc --noEmit`, `eslint --max-warnings 0`,
`prettier --check` on every PR.

## Style points

- **No `any`** — prefer `unknown` and narrow. `any` requires a
  line comment with justification.
- **No non-null assertion `!`** on public surface; acceptable
  locally after a verified guard.
- **Discriminated unions** over enums for state modelling.
- **`readonly`** on fields that don't mutate; `readonly T[]` /
  `ReadonlyArray<T>` for immutable inputs.
- **Exhaustiveness checks** — `const _: never = x` pattern at
  switch defaults.
- **Async** — `async / await`; no bare-Promise pyramids; never
  swallow rejections (`.catch(() => {})` without logging is a
  bug).
- **React / Vue / Svelte** specific style: defer to project-level
  supplement; don't pollute the baseline.

## Anti-patterns

- `Object` and `Function` types (use specific types).
- Type assertions (`as X`) where a type guard would work.
- Default exports (harder to refactor than named).
- Mutable module-level state.

## References

- TypeScript handbook https://www.typescriptlang.org/docs/handbook/
- `typescript-eslint` rules https://typescript-eslint.io/rules/
- Google TypeScript Style Guide (Tier-2)
  https://google.github.io/styleguide/tsguide.html
