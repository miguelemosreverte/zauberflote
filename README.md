# Zauberflöte (The Magic Flute) 🪄

A modular framework and cookbook for high-performance Elixir backends and beautiful, reactive UIs.

[![Hex.pm](https://img.shields.io/hexpm/v/zauberflote.svg)](https://hex.pm/packages/zauberflote)
[![NPM](https://img.shields.io/npm/v/zauberflote.svg)](https://www.npmjs.com/package/zauberflote)

## Side-by-Side Magic ⚡️

Zauberflöte allows you to define your entire backend API and frontend UI in a few lines of declarative code.

### Backend (Elixir DSL)
```elixir
resource "/income" do
  get do
    DB.get(:income, 1) || %{amount: 0}
  end

  post "/add", args: [amount: :float] do
    validate amount > 0, "Positive amount required"
    DB.update!(:income, 1, inc: [amount: amount])
  end
end
```

### Frontend (Reactive JS)
```javascript
ui.app("My App")
  .section("Income")
    .read("/income")
    .list("$ {{amount}}")
    .action("Add").post("/income/add")
      .field("amount", 100, "number").end()
  .mount();
```

---

## Repository Structure

- **/backend**: Core Elixir utilities and the declarative `Shared.App` DSL. (Hex: `zauberflote`)
- **/ui**: Lightweight reactive JS library for rapid UI prototyping. (NPM: `zauberflote`)
- **/cookbook**: A collection of production-ready examples organized by chapters.

## Live Cookbook

This repository includes a dynamic **Cookbook Portal** that launches all examples simultaneously.

### Cookbook Chapters

| Chapter | Topic | Subchapters |
|---------|-------|-------------|
| 1 | Getting Started | Hello World, Environment, First App |
| 2 | Declarative UI | Templates, Cards, Charts, Custom Views |
| 3 | Backend DSL | Resources, Validation, Guards |
| 4 | Reliability | Transactions, Pagination, Jobs, Caching |
| 5 | Realtime | WebSockets, HTTP Clients, Webhooks |
| 6 | Auth & Security | JWT, Sessions, RBAC |
| 7 | Testing | Unit, Integration, Mocking |
| 8 | Deployment | Docker, Releases, CI/CD |
| 9 | Ingenuity | Smart UI Components, Showcases |
| **10** | **Client State Mastery** | Counter, Shopping Cart, Wizard, Todo, Calculator, Filters, Tabs, Theme Switcher, Undo/Redo, Tic-Tac-Toe |

Chapter 10 focuses entirely on client-side state management patterns using `ui.js`, demonstrating the power of `.local()`, `.set()`, `.adjust()`, `.store()`, `.customView()`, and `.onRender()` without requiring backend calls.

### Starting the environment

**Development Mode (Default):**
Uses local source code from `/backend` and `/ui` for live reflection.
```bash
./start.sh
```

**Production Mode:**
Uses official packages from Hex.pm and NPM registries.
```bash
./start.sh --prod
```

📍 **Access the Portal:** [http://localhost:1990](http://localhost:1990)

## Publishing

Publishing is automated via GitHub Actions. You can trigger it manually in the Actions tab or by pushing a new tag.

### Manual Local Publish

```bash
cd backend && ./publish_local.sh --bump
cd ui && ./publish_local.sh --bump
```

---

*“Die Zauberflöte” - Engineering magic for the modern web.*