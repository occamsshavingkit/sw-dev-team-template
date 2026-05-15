# schemas/

JSON Schemas that validate canonical agent contracts, the model-routing configuration, and frontmatter on generated artifacts (FR-022, FR-023). Classification: **canonical** — schemas are the machine-checked contract; changes require review and a corresponding test-fixture update. Primary consumer: `scripts/lint-agent-contracts.sh`. One schema per artifact kind; name files after the artifact they validate (e.g., `agent-contract.schema.json`).
