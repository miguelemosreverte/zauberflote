# 4.2 Idempotency & Retries

Port: 4202

Endpoints:
- POST `/charge` (requires `Idempotency-Key` header)

Run:

```bash
mix deps.get
mix run --no-halt
```
