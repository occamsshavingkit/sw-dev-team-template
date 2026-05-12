# Prompt Archive

This directory may store full prompt text only when a compact hash entry in `docs/pm/TOKEN_LEDGER.md` is insufficient for audit or regression review.

## Archive Rule

Archive full prompts only when one of these applies:

- Prompt-regression evidence needs exact text.
- A review gate needs traceability beyond the prompt class and hash.
- A compact ledger entry would hide material scope, authority, or routing risk.

Do not archive routine prompts by default.

## Ledger Linkage

Each archived prompt must have a matching row in `docs/pm/TOKEN_LEDGER.md`.

The ledger row records the prompt hash, prompt class, budget, actual usage when known, and notes pointing to the archived prompt file when full text is retained.

The archived prompt file must include the same hash so reviewers can match the file back to the compact ledger row.
