# Chapter 2: Authentication

This chapter demonstrates user authentication patterns including registration, login, and session management.

## Examples

| Example | Port | Description |
|---------|------|-------------|
| [2-1-auth-demo](./2-1-auth-demo) | 4021 | Complete auth flow with task management |

## Key Concepts

- **Registration** - Creating new user accounts with validation
- **Login** - Authenticating users and returning session data
- **Session Management** - Client-side session storage with localStorage
- **Role-based UI** - Displaying different content based on user roles
- **Protected Actions** - Task management requiring authentication

## Quick Start

```bash
cd 2-1-auth-demo
mix deps.get
mix run --no-halt
```

Then open http://localhost:4021 and login with:
- `admin` / `admin123` (admin role)
- `alice` / `alice123` (user role)
