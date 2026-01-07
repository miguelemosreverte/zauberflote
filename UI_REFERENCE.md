# UI Reference Guide (ui.js)

A comprehensive guide to the Zauberflote UI framework - from simple displays to complex interactive applications.

> **Tip:** Links like `[See example →](#chapter:2-1-auth-demo)` will navigate to that chapter in the cookbook.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Core Concepts](#core-concepts)
3. [Display Modes](#display-modes)
4. [Actions & Forms](#actions--forms)
5. [Field Types](#field-types)
6. [State Management](#state-management)
7. [Client-Side State Patterns](#client-side-state-patterns)
8. [Authentication](#authentication)
9. [Pagination & Filtering](#pagination--filtering)
10. [Advanced Features](#advanced-features)
11. [Extending the UI](#extending-the-ui)
12. [Complete Examples](#complete-examples)

---

## Quick Start

### Minimal Example

```html
<!doctype html>
<html>
<head>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body>
  <div id="app"></div>
  <script type="module">
    import ui from "https://unpkg.com/zauberflote@1.0.2/src/ui.js";

    ui.app("My App")
      .section("Items")
        .read("/items")
        .list("{{name}}")
        .end()
      .mount();
  </script>
</body>
</html>
```

### Local Development

```html
<script type="module">
  import ui from "/ui.js";  // Served by backend

  ui.app("Development App")
    .section("Data")
      .read("/api/data")
      .list("{{field}}")
      .end()
    .mount();
</script>
```

---

## Core Concepts

### Builder Pattern

The UI uses a fluent builder pattern. Each method returns a builder, allowing method chaining:

```javascript
ui.app("Title")           // Returns AppBuilder
  .section("Section")     // Returns SectionBuilder
    .read("/endpoint")    // Returns SectionBuilder
    .list("{{field}}")    // Returns SectionBuilder
    .end()                // Returns AppBuilder
  .mount();               // Renders to DOM
```

### Template Syntax

Use `{{field}}` to interpolate data:

```javascript
// Simple field
.list("{{name}}")

// Multiple fields
.list("{{name}} - {{status}}")

// Nested access
.list("{{user.name}}")

// With HTML
.list("<strong>{{title}}</strong> by {{author}}")
```

---

## Display Modes

### 1. Simple List

Display array data as cards:

```javascript
.section("Users")
  .read("/users")
  .list("{{name}} ({{email}})")
  .end()
```

### 2. Styled List with CSS Classes

```javascript
.list(`
  <div class="flex justify-between items-center">
    <span class="font-bold">{{name}}</span>
    <span class="text-sm text-gray-500">{{created_at}}</span>
  </div>
`)
```

### 3. Table View

Automatically renders all fields as table columns:

```javascript
.section("Products")
  .read("/products")
  .template("table")
  .end()
```

### 4. KPI Cards

Display metrics at the top of a section:

```javascript
.section("Dashboard")
  .read("/stats")
  .kpis([
    { label: "Total", path: "total" },
    { label: "Active", path: "active" },
    { label: "Revenue", path: "revenue" }
  ])
  .end()
```

**Computed KPIs:**

```javascript
.kpis([
  { label: "Total", compute: d => d.length },
  { label: "Pending", compute: d => d.filter(x => x.status === "pending").length },
  { label: "Completed", compute: d => d.filter(x => x.status === "done").length }
])
```

### 5. JSON View

Display raw JSON with syntax highlighting:

```javascript
.section("API Response")
  .read("/api/debug")
  .jsonView("data")
  .end()
```

### 6. Text Block

Display plain text:

```javascript
.section("Description")
  .textBlock("This is static text content")
  .end()

// Or from API
.section("Notes")
  .read("/notes/1")
  .textBlock(null, "content")  // Display 'content' field
  .end()
```

### 7. Markdown

Render markdown content:

```javascript
.section("Documentation")
  .read("/docs/readme")
  .markdown(null, "body")
  .end()
```

### 8. Raw HTML

Insert custom HTML:

```javascript
.section("Custom")
  .html('<div class="my-custom-element">Content</div>')
  .end()
```

---

## Actions & Forms

### Section-Level Actions

Add action buttons to a section:

```javascript
.section("Create User")
  .action("Add User")
    .post("/users")
    .fields({
      name: { type: "text", placeholder: "Enter name" },
      email: { type: "email", placeholder: "Enter email" }
    })
    .refreshAll()
    .end()
  .end()
```

### Row-Level Actions

Add action buttons to each list item:

```javascript
.section("Tasks")
  .read("/tasks")
  .list("{{title}} - {{status}}")
  .rowAction("Complete")
    .post("/tasks/{{id}}/complete")
    .refreshAll()
    .end()
  .rowAction("Delete")
    .del("/tasks/{{id}}")
    .confirm("Are you sure?")
    .refreshAll()
    .end()
  .end()
```

### HTTP Methods

```javascript
.action("Create").post("/endpoint")    // POST request
.action("Update").put("/endpoint")     // PUT request
.action("Remove").del("/endpoint")     // DELETE request
.action("Fetch").get("/endpoint")      // GET request
.action("Upload").upload("/endpoint")  // Multipart upload
```

### Confirmation Dialog

```javascript
.rowAction("Delete")
  .del("/items/{{id}}")
  .confirm("Delete this item?")
  .refreshAll()
  .end()
```

### Refresh After Action

```javascript
// Refresh entire app
.refreshAll()

// Default: only refreshes current section if it has .read()
```

---

## Field Types

### All Supported Types

```javascript
.fields({
  // Text inputs
  name: { type: "text", placeholder: "Name" },
  bio: { type: "textarea", rows: 4 },

  // Numbers
  age: { type: "number", value: 18 },
  price: { type: "range", min: 0, max: 100 },

  // Date/Time
  birthdate: { type: "date" },
  meeting: { type: "datetime-local" },
  alarm: { type: "time" },

  // Selection
  status: {
    type: "select",
    options: [
      { value: "active", label: "Active" },
      { value: "inactive", label: "Inactive" }
    ]
  },

  // Boolean
  active: { type: "checkbox" },

  // Specialized
  email: { type: "email" },
  password: { type: "password" },
  phone: { type: "tel" },
  website: { type: "url" },
  color: { type: "color" },

  // File [See example: 4-8-uploads →](#chapter:4-8-uploads)
  document: { type: "file" },

  // Hidden
  user_id: { type: "hidden", value: "{{store.userId}}" }
})
```

### Dynamic Select Options

**From store:**

```javascript
// First, load data into store
.section("Load Users")
  .read("/users")
  .store({ users: "data" })
  .hidden()
  .end()

// Then use in a select
.section("Assign Task")
  .action("Assign")
    .post("/tasks")
    .fields({
      user_id: {
        type: "select",
        label: "Assign to",
        optionsFrom: {
          store: "users",
          value: "id",
          label: "name"
        }
      }
    })
    .end()
  .end()
```

### Default Values

```javascript
.fields({
  status: { type: "select", value: "pending", options: [...] },
  priority: { type: "number", value: 1 },
  date: { type: "date", value: "2024-01-01" }
})
```

---

## State Management

### Global Store

The store is shared across all sections:

```javascript
// Save API response to store
.section("Users")
  .read("/users")
  .store({ users: "data" })
  .end()

// Use stored data elsewhere
.section("User Count")
  .storeView("users", "Total: {{length}}")
  .end()
```

### Extract from Response

```javascript
.action("Login")
  .post("/login")
  .fields({
    username: { type: "text" },
    password: { type: "password" }
  })
  .store({
    token: "data.token",        // Extract nested value
    userId: "data.user.id",
    role: "data.user.role"
  })
  .end()
```

### Set Store Values Directly

```javascript
.action("Set Page")
  .local()  // No HTTP request
  .set({ currentPage: 1 })
  .end()

// With template
.action("Next Page")
  .local()
  .adjust("currentPage", 1)  // Increment by 1
  .end()
```

### Adjust Numeric Values

```javascript
// Increment
.adjust("page", 1)

// Decrement with floor
.adjust("page", -1, 1)  // Won't go below 1

// Decrement balance
.adjust("credits", -10, 0)  // Won't go below 0
```

---

## Client-Side State Patterns

**Chapter 10** showcases pure client-side state management without backend calls. These patterns are perfect for:
- Offline-first applications
- Complex UI interactions
- Prototyping before backend implementation
- State that doesn't need persistence

### Key Concepts

**Single Section = Single Store**: Each section has its own store. To share state across UI elements, use a single section with `.customView()` and `.onRender()`.

**Refresh Pattern**: After modifying store values, dispatch a refresh event:
```javascript
window.dispatchEvent(new CustomEvent('ui:refresh:sectionId'));
```

### 1. Counter Pattern

[See example: 10-1-counter →](#chapter:10-1-counter)

Simple increment/decrement with `.local()`, `.adjust()`, and `.set()`:

```javascript
.section("Counter")
  .id("counter")
  .query({ count: 0 })
  .customView(({ store }) => `
    <div class="text-6xl font-bold text-center">${store.count}</div>
  `)
  .action("+1").local().adjust("count", 1).refreshAll().end()
  .action("-1").local().adjust("count", -1, 0).refreshAll().end()
  .action("Reset").local().set({ count: 0 }).refreshAll().end()
  .end()
```

### 2. Shopping Cart Pattern

[See example: 10-2-shopping-cart →](#chapter:10-2-shopping-cart)

Managing arrays with add/remove/update operations:

```javascript
.section("Cart")
  .id("cart")
  .query({ products: [...], cart: [] })
  .customView(({ store }) => {
    // Render products and cart items
    return `<div>...</div>`;
  })
  .onRender(({ store, element }) => {
    element.querySelector('.add-btn').addEventListener('click', () => {
      store.cart.push({ ...product, qty: 1 });
      store.cart = [...store.cart];  // Trigger reactivity
      window.dispatchEvent(new CustomEvent('ui:refresh:cart'));
    });
  })
  .end()
```

### 3. Multi-Step Wizard Pattern

[See example: 10-3-wizard →](#chapter:10-3-wizard)

Conditional rendering based on step state:

```javascript
.section("Wizard")
  .id("wizard")
  .query({ step: 1, name: "", email: "", plan: "basic" })
  .customView(({ store }) => {
    if (store.step === 1) {
      return `<input name="name" value="${store.name}" />`;
    }
    if (store.step === 2) {
      return `<select name="plan">...</select>`;
    }
    return `<div>Review: ${store.name} - ${store.plan}</div>`;
  })
  .onRender(({ store, element }) => {
    element.querySelector('.next-btn')?.addEventListener('click', () => {
      store.step++;
      window.dispatchEvent(new CustomEvent('ui:refresh:wizard'));
    });
  })
  .end()
```

### 4. Todo List Pattern

[See example: 10-4-todo-list →](#chapter:10-4-todo-list)

CRUD operations with filtering:

```javascript
.section("Todos")
  .id("todos")
  .query({ todos: [], filter: "all", nextId: 1 })
  .customView(({ store }) => {
    const filtered = store.todos.filter(t =>
      store.filter === "all" ? true :
      store.filter === "active" ? !t.done : t.done
    );
    return `...`;
  })
  .onRender(({ store, element }) => {
    // Add todo
    element.querySelector('#add-btn').addEventListener('click', () => {
      store.todos.push({ id: store.nextId++, text: "...", done: false });
      store.todos = [...store.todos];
      window.dispatchEvent(new CustomEvent('ui:refresh:todos'));
    });

    // Toggle checkbox
    element.querySelectorAll('.todo-check').forEach(cb => {
      cb.addEventListener('change', (e) => {
        const todo = store.todos.find(t => t.id === id);
        if (todo) todo.done = e.target.checked;
        store.todos = [...store.todos];
        window.dispatchEvent(new CustomEvent('ui:refresh:todos'));
      });
    });
  })
  .end()
```

### 5. Calculator Pattern

[See example: 10-5-calculator →](#chapter:10-5-calculator)

Accumulator pattern with operation state:

```javascript
.section("Calculator")
  .id("calc")
  .query({ display: "0", operator: null, operand: null, memory: 0 })
  .customView(({ store }) => `
    <div class="display">${store.display}</div>
    <div class="keypad">...</div>
  `)
  .onRender(({ store, element }) => {
    element.querySelectorAll('.calc-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const key = btn.dataset.key;
        // Handle digits, operators, equals...
        window.dispatchEvent(new CustomEvent('ui:refresh:calc'));
      });
    });
  })
  .end()
```

### 6. Client-Side Filters Pattern

[See example: 10-6-filters →](#chapter:10-6-filters)

Filter and sort data without backend calls:

```javascript
.section("Catalog")
  .id("catalog")
  .query({ products: [...], search: "", category: "all", sortBy: "name" })
  .customView(({ store }) => {
    let filtered = store.products
      .filter(p => p.name.toLowerCase().includes(store.search.toLowerCase()))
      .filter(p => store.category === "all" || p.category === store.category);

    filtered.sort((a, b) => a[store.sortBy].localeCompare(b[store.sortBy]));

    return `<table>...</table>`;
  })
  .end()
```

### 7. Undo/Redo Pattern

[See example: 10-9-undo-redo →](#chapter:10-9-undo-redo)

State history stack:

```javascript
.section("Canvas")
  .id("canvas")
  .query({ shapes: [], history: ['[]'], historyIndex: 0 })
  .customView(({ store }) => `...`)
  .onRender(({ store, element }) => {
    const saveHistory = () => {
      store.history = store.history.slice(0, store.historyIndex + 1);
      store.history.push(JSON.stringify(store.shapes));
      store.historyIndex = store.history.length - 1;
    };

    // Undo
    element.querySelector('.undo-btn').addEventListener('click', () => {
      if (store.historyIndex > 0) {
        store.historyIndex--;
        store.shapes = JSON.parse(store.history[store.historyIndex]);
        window.dispatchEvent(new CustomEvent('ui:refresh:canvas'));
      }
    });
  })
  .end()
```

### 8. Game State Pattern

[See example: 10-10-game →](#chapter:10-10-game)

Complex state with win detection:

```javascript
.section("Tic-Tac-Toe")
  .id("board")
  .query({ board: Array(9).fill(null), turn: 'X', winner: null, scores: { X: 0, O: 0 } })
  .customView(({ store }) => {
    const checkWinner = (board) => { /* win detection logic */ };
    return `<div class="grid grid-cols-3">...</div>`;
  })
  .onRender(({ store, element }) => {
    element.querySelectorAll('.cell').forEach(cell => {
      cell.addEventListener('click', () => {
        if (store.winner || store.board[i]) return;
        store.board[i] = store.turn;
        store.board = [...store.board];

        const result = checkWinner(store.board);
        if (result) {
          store.winner = result.winner;
          store.scores[result.winner]++;
        } else {
          store.turn = store.turn === 'X' ? 'O' : 'X';
        }
        window.dispatchEvent(new CustomEvent('ui:refresh:board'));
      });
    });
  })
  .end()
```

### Chapter 10 Index

| Pattern | Chapter | Key Concepts |
|---------|---------|--------------|
| Counter | [10-1-counter](#chapter:10-1-counter) | `.local()`, `.adjust()`, `.set()` |
| Shopping Cart | [10-2-shopping-cart](#chapter:10-2-shopping-cart) | Array mutations, computed totals |
| Wizard | [10-3-wizard](#chapter:10-3-wizard) | Step navigation, conditional forms |
| Todo List | [10-4-todo-list](#chapter:10-4-todo-list) | CRUD, filtering, checkbox state |
| Calculator | [10-5-calculator](#chapter:10-5-calculator) | Accumulator, operator chaining |
| Filters | [10-6-filters](#chapter:10-6-filters) | Client-side search/sort |
| Tabs | [10-7-tabs](#chapter:10-7-tabs) | Conditional content |
| Theme | [10-8-theme](#chapter:10-8-theme) | CSS variables, persistence |
| Undo/Redo | [10-9-undo-redo](#chapter:10-9-undo-redo) | History stack |
| Game | [10-10-game](#chapter:10-10-game) | Win detection, score tracking |

---

## Authentication

[See example: 2-1-auth-demo →](#chapter:2-1-auth-demo) | [9-13-auth-demo →](#chapter:9-13-auth-demo)

### Bearer Token

```javascript
.action("Fetch Protected Data")
  .get("/api/protected")
  .bearer("token")  // Uses store.token
  .end()
```

### Basic Auth

```javascript
.action("Login")
  .get("/api/auth")
  .basic("username", "password")  // Uses store.username and store.password
  .end()
```

### Custom Headers

```javascript
.action("API Call")
  .post("/api/endpoint")
  .headers({
    "X-API-Key": "{{apiKey}}",
    "X-Tenant-ID": "{{tenantId}}"
  })
  .end()
```

### Headers from Store

```javascript
.action("Authenticated Request")
  .get("/api/data")
  .headersFrom({
    "Authorization": "authToken",  // Uses store.authToken
    "X-User-ID": "userId"
  })
  .end()
```

### Cookies (CORS)

```javascript
.action("With Cookies")
  .post("/api/session")
  .creds()  // Include credentials
  .end()
```

---

## Pagination & Filtering

[See example: 4-4-pagination →](#chapter:4-4-pagination)

### Basic Pagination

```javascript
.section("Items")
  .read("/items")
  .fields({
    page: { type: "number", value: 1 },
    limit: { type: "select", value: 10, options: [10, 25, 50, 100] }
  })
  .query({ page: "page", limit: "limit" })  // /items?page=1&limit=10
  .list("{{name}}")
  .meta("Showing {{limit}} of {{total}} items")
  .end()
```

### Search with Filters

```javascript
.section("Products")
  .read("/products")
  .fields({
    q: { type: "text", placeholder: "Search..." },
    category: {
      type: "select",
      options: [
        { value: "", label: "All Categories" },
        { value: "electronics", label: "Electronics" },
        { value: "clothing", label: "Clothing" }
      ]
    },
    order: {
      type: "select",
      value: "asc",
      options: [
        { value: "asc", label: "Price: Low to High" },
        { value: "desc", label: "Price: High to Low" }
      ]
    }
  })
  .query({ q: "q", category: "category", order: "order" })
  .list("{{name}} - ${{price}}")
  .end()
```

### Pagination Controls

```javascript
.section("Paginated Data")
  .read("/data")
  .store({ currentPage: 1, pageSize: 10 })

  // Previous page
  .action("Previous")
    .local()
    .adjust("currentPage", -1, 1)
    .refreshAll()
    .end()

  // Next page
  .action("Next")
    .local()
    .adjust("currentPage", 1)
    .refreshAll()
    .end()

  .query({ page: "{{currentPage}}", limit: "{{pageSize}}" })
  .listFrom("data.items")
  .meta("Page {{currentPage}} of {{totalPages}}")
  .end()
```

---

## Advanced Features

### 1. Smart Mocking (Offline Fallback)

Show placeholder data when backend is unavailable:

```javascript
.section("Products")
  .read("/products")
  .mock(() => [
    { id: 1, name: "Demo Product 1", price: 9.99 },
    { id: 2, name: "Demo Product 2", price: 19.99 }
  ])
  .list("{{name}} - ${{price}}")
  .end()
```

**With dynamic mock data:**

```javascript
.mock(() => ({
  items: Array.from({ length: 5 }, (_, i) => ({
    id: i + 1,
    name: `Item ${i + 1}`,
    status: ["pending", "active", "done"][i % 3]
  })),
  total: 5
}))
```

### 2. Custom Render Functions

Full control over rendering:

```javascript
.section("Custom View")
  .read("/data")
  .customView(({ data, store }) => {
    return `
      <div class="grid grid-cols-3 gap-4">
        ${data.map(item => `
          <div class="p-4 border rounded">
            <h3 class="font-bold">${item.name}</h3>
            <p class="text-gray-600">${item.description}</p>
          </div>
        `).join('')}
      </div>
    `;
  })
  .end()
```

### 3. Lifecycle Hooks (Charts, Maps)

[See example: 7-1-visualizations →](#chapter:7-1-visualizations)

Execute code after render:

```javascript
.section("Sales Chart")
  .read("/sales")
  .html('<canvas id="salesChart"></canvas>')
  .onRender(({ data, element }) => {
    new Chart(element.querySelector('#salesChart'), {
      type: 'bar',
      data: {
        labels: data.map(d => d.month),
        datasets: [{
          label: 'Sales',
          data: data.map(d => d.amount)
        }]
      }
    });
  })
  .end()
```

**Load external libraries:**

```javascript
ui.loadScript('https://cdn.jsdelivr.net/npm/chart.js').then(() => {
  ui.app("Charts")
    .section("My Chart")
      .read("/data")
      .html('<canvas id="chart"></canvas>')
      .onRender(({ data, element }) => {
        new Chart(element.querySelector('#chart'), {/* config */});
      })
      .end()
    .mount();
});
```

### 4. WebSocket Real-Time Updates

[See example: 5-1-ws-server →](#chapter:5-1-ws-server)

```javascript
.section("Live Messages")
  .websocket({
    url: "ws://localhost:4000/ws",
    autoConnect: true,
    history: "/messages",  // Optional: load history
    pollHistory: 5000      // Optional: poll every 5s
  })
  .end()
```

**With multiple test clients:**

```javascript
.websocket({
  url: "ws://localhost:4000/ws",
  clients: [
    { label: "Alice", name: "alice", message: "Hello!" },
    { label: "Bob", name: "bob", message: "Hi there!" }
  ]
})
```

### 5. Download Links

```javascript
.section("Reports")
  .read("/reports")
  .list("{{name}}")
  .links([
    { label: "Download PDF", href: "/reports/{{id}}/pdf", target: "_blank" },
    { label: "Export CSV", href: "/reports/{{id}}/csv" }
  ])
  .end()
```

### 6. Groups & Layout

**Grid layout:**

```javascript
ui.app("Dashboard")
  .group("Stats")
    .grid(3)  // 3 columns
    .section("Users").read("/stats/users").kpis([...]).end()
    .section("Sales").read("/stats/sales").kpis([...]).end()
    .section("Orders").read("/stats/orders").kpis([...]).end()
    .end()
  .mount();
```

**Sticky sidebar:**

```javascript
.group("Sidebar")
  .sticky({ top: "16px", maxHeight: "600px", width: "300px" })
  .section("Filters")
    .fields({ ... })
    .end()
  .end()
```

### 7. Custom Action Handlers

Full control over request/response:

```javascript
.action("Complex Action")
  .custom(async ({ body, request, store, output, setFooter }) => {
    // Custom logic
    const response = await request('/api/process', {
      method: 'POST',
      body: JSON.stringify({ ...body, extra: store.extraData })
    });

    // Custom output
    output(`<div class="text-green-600">Success: ${response.message}</div>`);

    // Update footer
    setFooter({ timestamp: new Date().toISOString() });
  })
  .end()
```

### 8. Inline Row Editing

```javascript
.section("Editable List")
  .read("/items")
  .list("{{name}}")
  .rowField("status", {
    type: "select",
    options: ["pending", "active", "done"]
  })
  .rowAction("Save")
    .put("/items/{{id}}")
    .refreshAll()
    .end()
  .end()
```

---

## Extending the UI

### Pattern 1: Conditional Sections

```javascript
const currentUser = JSON.parse(localStorage.getItem('user'));

const app = ui.app("Dashboard");

if (currentUser) {
  app.section("Welcome")
    .html(`<p>Welcome, ${currentUser.name}!</p>`)
    .end();
}

if (currentUser?.role === "admin") {
  app.section("Admin Panel")
    .read("/admin/stats")
    .kpis([...])
    .end();
}

app.mount();
```

### Pattern 2: Dynamic Sections from Config

```javascript
const dashboardConfig = [
  { title: "Users", endpoint: "/users", fields: ["name", "email"] },
  { title: "Products", endpoint: "/products", fields: ["name", "price"] },
  { title: "Orders", endpoint: "/orders", fields: ["id", "status"] }
];

const app = ui.app("Dynamic Dashboard");

dashboardConfig.forEach(config => {
  app.section(config.title)
    .read(config.endpoint)
    .list(config.fields.map(f => `{{${f}}}`).join(" - "))
    .end();
});

app.mount();
```

### Pattern 3: Reusable Section Builders

```javascript
function addCrudSection(app, name, endpoint) {
  return app
    .section(`Create ${name}`)
      .action("Add")
        .post(endpoint)
        .fields({ name: { type: "text" } })
        .refreshAll()
        .end()
      .end()
    .section(name)
      .read(endpoint)
      .list("{{name}}")
      .rowAction("Edit")
        .put(`${endpoint}/{{id}}`)
        .fields({ name: { type: "text", value: "{{name}}" } })
        .refreshAll()
        .end()
      .rowAction("Delete")
        .del(`${endpoint}/{{id}}`)
        .confirm("Delete?")
        .refreshAll()
        .end()
      .end();
}

const app = ui.app("CRUD App");
addCrudSection(app, "Users", "/users");
addCrudSection(app, "Products", "/products");
app.mount();
```

### Pattern 4: Multi-Step Wizards

```javascript
// Track step in store
.section("Wizard")
  .store({ step: 1 })
  .end()

.section("Step 1")
  .storeView("step", "{{step === 1 ? 'visible' : 'hidden'}}")
  .action("Next")
    .local()
    .set({ step: 2 })
    .end()
  .end()

.section("Step 2")
  .action("Submit")
    .post("/wizard/complete")
    .end()
  .end()
```

### Pattern 5: Error Handling

```javascript
.action("Submit")
  .post("/api/action")
  .fields({ ... })
  .store({
    lastError: "error.message",
    lastResult: "data"
  })
  .end()

.section("Status")
  .storeView("lastError", '<span class="text-red-600">{{lastError}}</span>')
  .storeView("lastResult", '<span class="text-green-600">Success!</span>')
  .end()
```

---

## Complete Examples

### Example 1: Task Manager with Auth

```javascript
const currentUser = JSON.parse(localStorage.getItem('user'));

if (currentUser) {
  ui.app("Task Manager")
    .section("Create Task")
      .read("/users").store({ users: "data" }).hidden()
      .action("Add Task")
        .post("/tasks")
        .fields({
          title: { type: "text", placeholder: "Task title..." },
          priority: {
            type: "select",
            value: 2,
            options: [
              { value: 1, label: "Low" },
              { value: 2, label: "Medium" },
              { value: 3, label: "High" }
            ]
          },
          user_id: {
            type: "select",
            label: "Assign to",
            optionsFrom: { store: "users", value: "id", label: "username" }
          }
        })
        .refreshAll()
        .end()
      .end()

    .section("Tasks")
      .read("/tasks")
      .kpis([
        { label: "Total", compute: d => d.length },
        { label: "Pending", compute: d => d.filter(t => t.status === "pending").length },
        { label: "Done", compute: d => d.filter(t => t.status === "done").length }
      ])
      .list(`
        <div class="flex justify-between">
          <span class="font-medium">{{title}}</span>
          <span class="text-sm">{{status}}</span>
        </div>
      `)
      .rowAction("Complete").post("/tasks/{{id}}/complete").refreshAll().end()
      .rowAction("Delete").del("/tasks/{{id}}").confirm("Delete?").refreshAll().end()
      .end()

    .mount();
}
```

### Example 2: E-Commerce Dashboard

```javascript
ui.app("E-Commerce Dashboard")
  .group("Overview")
    .grid(4)
    .section("Revenue").read("/stats").kpis([{ label: "$", path: "revenue" }]).end()
    .section("Orders").read("/stats").kpis([{ label: "#", path: "orders" }]).end()
    .section("Customers").read("/stats").kpis([{ label: "#", path: "customers" }]).end()
    .section("Products").read("/stats").kpis([{ label: "#", path: "products" }]).end()
    .end()

  .section("Recent Orders")
    .read("/orders?limit=10")
    .template("table")
    .rowAction("View").get("/orders/{{id}}").end()
    .rowAction("Ship").post("/orders/{{id}}/ship").confirm("Ship order?").refreshAll().end()
    .end()

  .section("Product Search")
    .fields({
      q: { type: "text", placeholder: "Search products..." },
      category: { type: "select", options: ["All", "Electronics", "Clothing", "Books"] }
    })
    .read("/products")
    .query({ q: "q", category: "category" })
    .list("{{name}} - ${{price}}")
    .end()

  .mount();
```

### Example 3: Real-Time Chat

```javascript
ui.app("Chat Room")
  .section("Messages")
    .websocket({
      url: "ws://localhost:4000/ws",
      autoConnect: true,
      history: "/messages",
      clients: [
        { label: "Send as Alice", name: "Alice" },
        { label: "Send as Bob", name: "Bob" }
      ]
    })
    .end()

  .mount();
```

### Example 4: Analytics with Charts

```javascript
ui.loadScript('https://cdn.jsdelivr.net/npm/chart.js').then(() => {
  ui.app("Analytics")
    .section("Sales Trend")
      .read("/analytics/sales")
      .html('<canvas id="salesChart" style="max-height: 300px;"></canvas>')
      .onRender(({ data, element }) => {
        new Chart(element.querySelector('#salesChart'), {
          type: 'line',
          data: {
            labels: data.map(d => d.date),
            datasets: [{
              label: 'Sales',
              data: data.map(d => d.amount),
              borderColor: 'rgb(75, 192, 192)',
              tension: 0.1
            }]
          }
        });
      })
      .end()

    .section("Category Distribution")
      .read("/analytics/categories")
      .html('<canvas id="pieChart" style="max-height: 300px;"></canvas>')
      .onRender(({ data, element }) => {
        new Chart(element.querySelector('#pieChart'), {
          type: 'pie',
          data: {
            labels: data.map(d => d.category),
            datasets: [{
              data: data.map(d => d.count),
              backgroundColor: ['#f87171', '#60a5fa', '#34d399', '#fbbf24']
            }]
          }
        });
      })
      .end()

    .mount();
});
```

---

## Error Handling & Debugging

The framework provides helpful error messages when methods don't exist:

```
[ui.js] SectionBuilder has no method "fakeMethod"

Available methods:
  read, list, template, kpis, action, rowAction, store, ...

Chain (last 5 calls):
  .section("Test")
  .read("/data")
  .list("{{name}}")
  .fakeMethod() <- ERROR HERE

Did you mean: "fields"?
```

### Common Mistakes

1. **Forgetting `.end()`**: Each builder must return to parent
2. **Wrong template syntax**: Use `{{field}}` not `{field}` or `${field}`
3. **Missing `.refreshAll()`**: Actions won't update UI without it
4. **Store path issues**: Use `"data.field"` not `"data['field']"`

---

## Method Reference

| Builder | Method | Description |
|---------|--------|-------------|
| AppBuilder | `.section(title)` | Create section |
| AppBuilder | `.group(title)` | Create group |
| AppBuilder | `.blurb(text)` | Subtitle |
| AppBuilder | `.mount()` | Render |
| SectionBuilder | `.read(path)` | Fetch data |
| SectionBuilder | `.list(template)` | Card list |
| SectionBuilder | `.template("table")` | Table view |
| SectionBuilder | `.kpis([...])` | KPI cards |
| SectionBuilder | `.action(label)` | Add button |
| SectionBuilder | `.rowAction(label)` | Per-row button |
| SectionBuilder | `.fields({...})` | Input fields |
| SectionBuilder | `.store({...})` | Save to store |
| SectionBuilder | `.query({...})` | Query params |
| SectionBuilder | `.mock(fn)` | Offline fallback |
| SectionBuilder | `.customView(fn)` | Custom render |
| SectionBuilder | `.onRender(fn)` | After render hook |
| SectionBuilder | `.websocket({...})` | Real-time |
| SectionBuilder | `.end()` | Return to parent |
| ActionBuilder | `.post(path)` | POST request |
| ActionBuilder | `.get(path)` | GET request |
| ActionBuilder | `.put(path)` | PUT request |
| ActionBuilder | `.del(path)` | DELETE request |
| ActionBuilder | `.fields({...})` | Form fields |
| ActionBuilder | `.store({...})` | Extract response |
| ActionBuilder | `.set({...})` | Set store values |
| ActionBuilder | `.adjust(key, delta)` | Increment/decrement |
| ActionBuilder | `.bearer(key)` | Bearer auth |
| ActionBuilder | `.basic(user, pass)` | Basic auth |
| ActionBuilder | `.headers({...})` | Custom headers |
| ActionBuilder | `.confirm(msg)` | Confirmation |
| ActionBuilder | `.refreshAll()` | Refresh app |
| ActionBuilder | `.local()` | No HTTP request |
| ActionBuilder | `.custom(fn)` | Custom handler |
| ActionBuilder | `.end()` | Return to parent |

---

*Last updated: January 2026*
