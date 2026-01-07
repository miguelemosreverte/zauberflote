# 5.8 Multi-tenant Scoping

Port: 4308

Endpoints:
- GET `/items` (requires `X-Tenant-ID`)
- POST `/items` (requires `X-Tenant-ID`)

Run:

```bash
mix deps.get
mix run --no-halt
```
