# Chapter 5 Aux Service

Port: 4399

Endpoints:
- GET `/ping`
- GET `/data`
- GET `/flaky`
- POST `/flaky/reset`
- POST `/webhook`
- GET `/webhook/log`
- WS `/ws`

Run:

```bash
mix deps.get
mix run --no-halt
```
