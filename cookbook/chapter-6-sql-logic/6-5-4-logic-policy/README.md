# 6.5.4 Policy Checks

Port: 4414

Endpoints:
- GET `/requests`
- POST `/requests`
- POST `/requests/:id/approve` (header `X-Role`)

Run:

```bash
mix deps.get
mix run --no-halt
```
