# 6.5.10 Idempotent Commands

Port: 4420

Endpoints:
- GET `/orders`
- POST `/orders`
- POST `/orders/:id/discount` (header `Idempotency-Key`)

Run:

```bash
mix deps.get
mix run --no-halt
```
