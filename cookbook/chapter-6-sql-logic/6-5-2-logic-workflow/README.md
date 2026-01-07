# 6.5.2 Multi-step Workflow

Port: 4412

Endpoints:
- GET `/orders`
- POST `/orders`
- POST `/orders/:id/pay`
- POST `/orders/:id/ship`

Run:

```bash
mix deps.get
mix run --no-halt
```
