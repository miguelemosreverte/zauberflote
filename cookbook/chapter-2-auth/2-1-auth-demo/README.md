# 2.1 Auth Demo

Port: 4021

A complete authentication demo with login, registration, and task management.

## Features

- **User Registration** - Create new accounts with username/password
- **User Login** - Authenticate and receive user session
- **Role-based Display** - Admin vs User roles shown in UI
- **Task Management** - Full CRUD with status workflow (pending → in_progress → completed)
- **User Assignment** - Assign tasks to users with dropdown populated from API

## Demo Accounts

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | admin |
| alice | alice123 | user |
| bob | bob123 | user |

## Run

```bash
mix deps.get
mix run --no-halt
```

Open `http://localhost:4021`.

## Files

- `lib/c2_auth_demo/app.ex` - Backend: Application + Router
- `priv/static/index.html` - Frontend: Login/Register + Task Manager UI
