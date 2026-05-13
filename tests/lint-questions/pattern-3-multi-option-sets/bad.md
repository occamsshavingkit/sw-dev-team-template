# Bad fixture — pattern 3, multiple independent option sets near a question

Two option tables flanking a customer question:

| Storage | Notes |
| --- | --- |
| Redis | fast, ephemeral |
| Postgres | durable |

Which storage and which expiry should we use?

| Expiry | Notes |
| --- | --- |
| 30m | tight |
| 24h | loose |
