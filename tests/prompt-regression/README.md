# tests/prompt-regression/

YAML fixtures plus a `run.sh` harness that exercise agent behavioral cases against the runtime contracts. Classification: **canonical** — fixtures define the observable-behavior contract and are reviewed alongside the agent edits that change them. Layout: one YAML file per agent per behavioral case, named `<agent>-<case>.yaml`. Consumer: CI workflow `agent-contract-check.yml`. Reference: FR-024 (spec.md), R-11 (research.md).
