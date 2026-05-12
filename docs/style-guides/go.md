# Go style guide — seed

Seed file. Projects may extend; changes propose via
`architect` + `software-engineer` consensus and land with a row in
`docs/pm/CHANGES.md`.

## Baseline standards

- **Effective Go** — `https://go.dev/doc/effective_go`.
- **Go Code Review Comments** — `https://github.com/golang/go/wiki/CodeReviewComments`.
- **Uber Go Style Guide** (Tier-2 supplement) —
  `https://github.com/uber-go/guide/blob/master/style.md`.

## Required toolchain

| Tool | Role | Config |
|---|---|---|
| `gofmt` / `goimports` | formatter | defaults |
| `go vet` | static check | CI-gated |
| `staticcheck` (honnef.co) | extended lint | CI-gated |
| `golangci-lint` | meta-linter | `.golangci.yml` with recommended linters |
| `go test -race` | test runner | race detector on in CI |

CI enforces `gofmt -l` == empty, `go vet`, `staticcheck`,
`golangci-lint run`, `go test -race ./...` on every PR.

## Style points

- **Error handling.** `if err != nil { return … }` at every call
  site; wrap with `fmt.Errorf("context: %w", err)` to preserve
  chain; sentinel errors via `errors.Is` / `errors.As`.
- **Interfaces at the consumer** (small, defined where used), not
  a giant `interfaces.go` at package root.
- **Context.** `context.Context` is the first parameter on any
  function that performs I/O or may cancel. Never store a
  context in a struct.
- **Concurrency.** Goroutines started must have a documented exit
  path. No goroutine leaks — if `context` cancels, the goroutine
  must observe and return.
- **`any`** — prefer concrete types; use generics for genuine
  polymorphism (since 1.18).
- **Logging** — `log/slog` (1.21+); no `log.Fatal` in library
  code; return the error.

## Anti-patterns

- Empty `interface{}` (`any`) in public API signatures.
- Silent panics (always `recover()` with a log in goroutines).
- Init ordering dependencies between packages (`init()` abuse).
- Unexported struct fields used by another package via reflection.

## References

- Effective Go https://go.dev/doc/effective_go
- Go Code Review Comments
  https://github.com/golang/go/wiki/CodeReviewComments
- Go Proverbs https://go-proverbs.github.io/
- Uber Go Style Guide
  https://github.com/uber-go/guide/blob/master/style.md
