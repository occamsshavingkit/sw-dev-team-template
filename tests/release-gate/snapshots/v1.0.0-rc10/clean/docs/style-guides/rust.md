# Rust style guide — seed

Seed file. Projects may extend; changes propose via
`architect` + `software-engineer` consensus and land with a row in
`docs/pm/CHANGES.md`.

## Baseline standards

- **Rust API Guidelines** — `https://rust-lang.github.io/api-guidelines/`.
- **Rust Style Guide** (rustfmt default) — binding baseline.

## Required toolchain

| Tool | Role | Config |
|---|---|---|
| `rustfmt` | formatter | default settings; `rustfmt.toml` override with reason |
| `clippy` | lint | `#![deny(clippy::pedantic)]` new crates; `#![warn(clippy::all)]` minimum |
| `cargo test` | test runner | see `docs/templates/qa/unit-test-plan-template.md` |
| `cargo audit` / `cargo deny` | dependency policy | CI-gated |

CI enforces `cargo fmt --check`, `cargo clippy -- -D warnings`,
`cargo test`, `cargo audit` on every PR.

## Style points

- **Ownership first.** Prefer borrows over clones; `Cow<str>` for
  conditional ownership; only clone when the profiler says so.
- **Errors with `Result`**, not panics. Library code returns
  `Result<T, E>`; panics only for "impossible" invariants (document
  the invariant).
- **`thiserror` for library errors**; `anyhow` acceptable in
  binaries / integration code.
- **`#[must_use]` on methods whose return value is meaningful** —
  protects callers from silently discarding `Result` / `Option`
  values.
- **Unsafe** — every `unsafe` block has a `// SAFETY:` comment
  explaining the invariant it upholds. No `unsafe` without a
  reviewed ADR.
- **Async** — Tokio or async-std, pick one per project; document
  in the architecture doc. No mixing.

## Anti-patterns

- `.unwrap()` / `.expect()` outside of tests or proven-impossible
  branches.
- `Box<dyn Error>` on public library API (use concrete error type).
- Long `Vec<Box<dyn Trait>>` hierarchies where an enum would do.
- Re-exporting private types through public API by accident.

## References

- Rust API Guidelines https://rust-lang.github.io/api-guidelines/
- Rust Style Guide https://doc.rust-lang.org/stable/style-guide/
- Rustonomicon (unsafe) https://doc.rust-lang.org/nomicon/
- Clippy lint list https://rust-lang.github.io/rust-clippy/master/
