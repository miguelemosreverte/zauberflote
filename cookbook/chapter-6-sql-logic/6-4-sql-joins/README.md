# 6.4 Joins (1:N + M:N)

Port: 4404

Endpoints:
- GET `/authors`
- POST `/authors`
- GET `/books`
- POST `/books`
- POST `/books/:id/tags`
- GET `/books_with_tags`

Run:

```bash
mix deps.get
mix run --no-halt
```
