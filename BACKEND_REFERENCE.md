# Backend Reference Guide (Elixir/Zauberflote)

A comprehensive guide to the Zauberflote backend framework - from simple CRUD to advanced SQL patterns and Elixir techniques.

> **Tip:** Links like `[See example →](#chapter:3-1-auth-basic)` will navigate to that chapter in the cookbook.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Application Setup](#application-setup)
3. [Routing & HTTP](#routing--http)
4. [Database Operations](#database-operations)
5. [SQL Patterns](#sql-patterns)
6. [Validation & Error Handling](#validation--error-handling)
7. [Authentication](#authentication)
8. [Transactions](#transactions)
9. [Advanced Elixir Patterns](#advanced-elixir-patterns)
10. [Complete Examples](#complete-examples)

---

## Quick Start

### Minimal Application

```elixir
# lib/my_app/application.ex
defmodule MyApp.Application do
  use Shared.App.Runner, port: 4000

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );
  """
end

# lib/my_app/router.ex
defmodule MyApp.Router do
  use Shared.App

  get "/items" do
    DB.list(:items)
  end

  post "/items", args: [name: :string] do
    validate name != "", "Name is required"
    id = DB.create(:items, %{name: name})
    created(%{id: id, name: name})
  end

  delete "/items/:id", args: [id: :int] do
    DB.delete!(:items, id)
    ok()
  end
end
```

### mix.exs

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [app: :my_app, version: "0.1.0", elixir: "~> 1.14",
     start_permanent: Mix.env() == :prod, deps: deps()]
  end

  def application do
    [extra_applications: [:logger], mod: {MyApp.Application, []}]
  end

  defp deps do
    [
      {:zauberflote, "~> 1.0"},  # or path: "../backend" for local
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:cors_plug, "~> 3.0"},
      {:exqlite, "~> 0.34"}
    ]
  end
end
```

---

## Application Setup

### Basic Setup

```elixir
defmodule MyApp.Application do
  use Shared.App.Runner, port: 4000
end
```

### With Options

```elixir
defmodule MyApp.Application do
  use Shared.App.Runner,
    port: 4000,
    children: [MyApp.CacheServer, MyApp.Scheduler],
    cowboy_opts: [compress: true]

  init_sql """
    -- Multiple statements supported
    CREATE TABLE IF NOT EXISTS users (...);
    CREATE TABLE IF NOT EXISTS posts (...);

    -- Seed data
    INSERT OR IGNORE INTO users (id, name) VALUES (1, 'Admin');
  """

  # Multiple init_sql blocks are accumulated
  init_sql """
    CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id);
  """
end
```

### Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `port` | integer | 4000 | HTTP server port |
| `children` | list | [] | Additional supervision tree children |
| `cowboy_opts` | keyword list | [] | Cowboy HTTP server options |

---

## Routing & HTTP

### Route Definitions

```elixir
defmodule MyApp.Router do
  use Shared.App

  # Root route
  get do
    conn |> send_file(200, "priv/static/index.html")
  end

  # Path routes
  get "/api/items" do
    DB.list(:items)
  end

  # With parameters
  get "/api/items/:id", args: [id: :int] do
    DB.get!(:items, id)
  end

  # POST with body args
  post "/api/items", args: [name: :string, price: :float] do
    validate name != "", "Name required"
    validate price > 0, "Price must be positive"
    id = DB.create(:items, %{name: name, price: price})
    created(%{id: id})
  end

  # PUT/PATCH
  put "/api/items/:id", args: [id: :int, name: :string] do
    DB.update!(:items, id, %{name: name})
    ok()
  end

  # DELETE
  delete "/api/items/:id", args: [id: :int] do
    DB.delete!(:items, id)
    ok()
  end
end
```

### Parameter Types

```elixir
args: [
  name: :string,     # Trimmed string
  age: :int,         # Integer (also :integer)
  price: :float,     # Float
  data: :any         # Raw value (no parsing)
]
```

### Resource Scoping

```elixir
resource "/api/users" do
  get do
    DB.list(:users)
  end

  get "/:id", args: [id: :int] do
    DB.get!(:users, id)
  end

  post args: [name: :string, email: :string] do
    id = DB.create(:users, %{name: name, email: email})
    created(%{id: id})
  end

  put "/:id", args: [id: :int, name: :string] do
    DB.update!(:users, id, %{name: name})
    ok()
  end

  delete "/:id", args: [id: :int] do
    DB.delete!(:users, id)
    ok()
  end
end
```

### Return Value Handling

```elixir
# Success responses
ok()                      # 200 {"data": {"ok": true}}
ok(%{message: "Done"})    # 200 {"data": {"message": "Done"}}
created(%{id: 1})         # 201 {"data": {"id": 1}}
%{name: "item"}           # 200 {"data": {"name": "item"}}
[%{id: 1}, %{id: 2}]      # 200 {"data": [{...}, {...}]}

# Error responses
halt(400, "Bad request")           # 400 {"error": {"message": "Bad request"}}
halt(401, "Unauthorized")          # 401 {"error": {"message": "Unauthorized"}}
halt(403, "Forbidden")             # 403 {"error": {"message": "Forbidden"}}
halt(404, "Not found")             # 404 {"error": {"message": "Not found"}}
{:error, :conflict}                # 409 {"error": {"message": "already exists"}}
{:error, 422, "Invalid data"}      # 422 {"error": {"message": "Invalid data"}}
nil                                # 404 {"error": {"message": "not found"}}
```

### Direct Conn Access

```elixir
get "/download" do
  conn
  |> put_resp_header("content-type", "text/csv")
  |> put_resp_header("content-disposition", "attachment; filename=data.csv")
  |> send_resp(200, "col1,col2\nval1,val2")
end

get "/redirect" do
  conn
  |> put_resp_header("location", "/new-path")
  |> send_resp(302, "")
end
```

### Headers Access

```elixir
post "/api/action" do
  # Get single header
  token = get_req_header(conn, "authorization") |> List.first()

  # Get with default
  tenant = get_req_header(conn, "x-tenant-id") |> List.first() || "default"

  # Multiple headers
  [content_type | _] = get_req_header(conn, "content-type")

  ok(%{tenant: tenant})
end
```

---

## Database Operations

### DB Module (High-Level API)

#### Query Operations

```elixir
# Get all rows
DB.list(:users)
DB.all(:users)  # alias

# With options
DB.list(:users, order: "name ASC")
DB.list(:users, order: "created_at DESC", limit: 10)
DB.list(:users, limit: 10, offset: 20)
DB.list(:users, where: [status: "active"])
DB.list(:users, where: [status: "active"], order: "name", limit: 5)

# Get single row
DB.get(:users, 1)           # Returns nil if not found
DB.get!(:users, 1)          # Raises/halts if not found

# With WHERE clause
DB.one(:users, where: [email: "test@example.com"])
DB.one!(:users, where: [username: "admin"])

# Count
DB.count(:users)
DB.count(:users, where: [status: "active"])

# Exists check
DB.exists?(:users, email: "test@example.com")
```

#### WHERE Clause Operators

```elixir
# Equality (default)
where: [status: "active"]           # status = 'active'
where: [user_id: 5]                 # user_id = 5

# LIKE pattern
where: [name: {:like, "%john%"}]    # name LIKE '%john%'
where: [email: {:like, "%@gmail.com"}]

# Comparison
where: [price: {:gte, 10.0}]        # price >= 10.0
where: [price: {:lte, 100.0}]       # price <= 100.0
where: [quantity: {:gt, 0}]         # quantity > 0
where: [quantity: {:lt, 100}]       # quantity < 100

# Multiple conditions (AND)
where: [status: "active", role: "admin"]  # status = 'active' AND role = 'admin'
```

#### Write Operations

```elixir
# Create
id = DB.create(:users, %{name: "John", email: "john@example.com"})

# Update by ID
DB.update!(:users, id, %{name: "John Doe"})

# Update with WHERE
DB.update_where!(:users, [status: "pending"], %{status: "active"})

# Increment/Decrement
DB.update!(:accounts, id, inc: [balance: 100])
DB.update!(:accounts, id, dec: [balance: 50])

# Delete
DB.delete!(:users, id)
DB.delete_where!(:sessions, [expired: true])
```

### Shared.DB Module (Low-Level API)

For raw SQL queries:

```elixir
# Within route (connection already open)
Shared.DB.with_db(fn db ->
  # Execute without return value
  Shared.DB.exec(db, "UPDATE users SET last_login = ? WHERE id = ?",
    [DateTime.utc_now() |> DateTime.to_iso8601(), user_id])

  # Query returning list of lists
  rows = Shared.DB.all(db, "SELECT id, name FROM users WHERE status = ?", ["active"])
  # [[1, "John"], [2, "Jane"]]

  # Query returning list of maps
  users = Shared.DB.all_maps(db, "SELECT * FROM users WHERE role = ?", ["admin"])
  # [%{id: 1, name: "John", role: "admin"}, ...]

  # Single row
  user = Shared.DB.one_map(db, "SELECT * FROM users WHERE id = ?", [id])
  # %{id: 1, name: "John"} or nil

  # Insert with conflict handling
  case Shared.DB.insert(db, :users, %{email: email, name: name}) do
    {:ok, id} -> {:ok, id}
    {:error, :conflict} -> {:error, "Email already exists"}
  end
end)
```

---

## SQL Patterns

[See examples: 6-1-sql-basics →](#chapter:6-1-sql-basics) | [6-2-sql-filters →](#chapter:6-2-sql-filters) | [6-3-sql-aggregations →](#chapter:6-3-sql-aggregations) | [6-4-sql-joins →](#chapter:6-4-sql-joins)

### Table Creation

```elixir
init_sql """
  -- Basic table
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    email TEXT UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );

  -- With foreign key
  CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    body TEXT,
    status TEXT DEFAULT 'draft',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
  );

  -- Junction table (many-to-many)
  CREATE TABLE IF NOT EXISTS post_tags (
    post_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (post_id, tag_id),
    FOREIGN KEY (post_id) REFERENCES posts(id),
    FOREIGN KEY (tag_id) REFERENCES tags(id)
  );

  -- With indexes
  CREATE INDEX IF NOT EXISTS idx_posts_user ON posts(user_id);
  CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);
"""
```

### Basic Queries

```elixir
# Simple SELECT
DB.all("SELECT * FROM users ORDER BY name")

# With WHERE
DB.all("SELECT * FROM users WHERE status = ?", ["active"])

# With LIMIT/OFFSET
DB.all("SELECT * FROM items LIMIT ? OFFSET ?", [limit, offset])

# Specific columns
DB.all("SELECT id, name, email FROM users")
```

### Filtering with LIKE

```elixir
get "/search", args: [q: :string] do
  if q != "" do
    DB.all("""
      SELECT * FROM products
      WHERE name LIKE ? OR description LIKE ?
      ORDER BY name
    """, ["%#{q}%", "%#{q}%"])
  else
    DB.list(:products, order: "name")
  end
end
```

### Aggregations

```elixir
# COUNT
DB.one("SELECT COUNT(*) as total FROM orders", [])
# %{total: 42}

# SUM, AVG, MIN, MAX
DB.one("""
  SELECT
    COUNT(*) as count,
    SUM(amount) as total,
    AVG(amount) as average,
    MIN(amount) as min,
    MAX(amount) as max
  FROM orders
  WHERE status = ?
""", ["completed"])

# GROUP BY
DB.all("""
  SELECT category, COUNT(*) as count, SUM(price) as total
  FROM products
  GROUP BY category
  ORDER BY total DESC
""")

# GROUP BY with HAVING
DB.all("""
  SELECT user_id, COUNT(*) as order_count
  FROM orders
  GROUP BY user_id
  HAVING COUNT(*) > 5
""")
```

### Joins

```elixir
# INNER JOIN
DB.all("""
  SELECT p.*, u.name as author_name
  FROM posts p
  JOIN users u ON u.id = p.user_id
  ORDER BY p.created_at DESC
""")

# LEFT JOIN
DB.all("""
  SELECT u.*, COUNT(p.id) as post_count
  FROM users u
  LEFT JOIN posts p ON p.user_id = u.id
  GROUP BY u.id
""")

# Multiple JOINs
DB.all("""
  SELECT
    o.id,
    o.total,
    u.name as customer,
    GROUP_CONCAT(p.name) as products
  FROM orders o
  JOIN users u ON u.id = o.user_id
  JOIN order_items oi ON oi.order_id = o.id
  JOIN products p ON p.id = oi.product_id
  GROUP BY o.id
  ORDER BY o.created_at DESC
""")

# Self JOIN (hierarchy)
DB.all("""
  SELECT
    e.name as employee,
    m.name as manager
  FROM employees e
  LEFT JOIN employees m ON m.id = e.manager_id
""")
```

### GROUP_CONCAT for Tags/Categories

```elixir
get "/posts_with_tags" do
  DB.all("""
    SELECT
      p.id,
      p.title,
      GROUP_CONCAT(t.name, ', ') as tags
    FROM posts p
    LEFT JOIN post_tags pt ON pt.post_id = p.id
    LEFT JOIN tags t ON t.id = pt.tag_id
    GROUP BY p.id
  """)
  |> Enum.map(fn post ->
    Map.update(post, :tags, [], fn tags ->
      if tags, do: String.split(tags, ", ", trim: true), else: []
    end)
  end)
end
```

### Window Functions

[See example: 6-8-sql-windows →](#chapter:6-8-sql-windows)

```elixir
# RANK within groups
DB.all("""
  SELECT
    category,
    name,
    price,
    RANK() OVER (PARTITION BY category ORDER BY price DESC) as price_rank
  FROM products
""")

# Running total
DB.all("""
  SELECT
    date,
    amount,
    SUM(amount) OVER (ORDER BY date) as running_total
  FROM transactions
""")

# ROW_NUMBER for pagination
DB.all("""
  SELECT * FROM (
    SELECT
      *,
      ROW_NUMBER() OVER (ORDER BY created_at DESC) as row_num
    FROM posts
  )
  WHERE row_num BETWEEN ? AND ?
""", [offset + 1, offset + limit])
```

### Recursive CTE (Hierarchies)

[See example: 9-1-org-chart →](#chapter:9-1-org-chart)

```elixir
# Organization chart
get "/org_chart" do
  DB.all("""
    WITH RECURSIVE org AS (
      -- Base case: top-level (no manager)
      SELECT id, name, manager_id, 0 as depth
      FROM employees
      WHERE manager_id IS NULL

      UNION ALL

      -- Recursive case
      SELECT e.id, e.name, e.manager_id, org.depth + 1
      FROM employees e
      JOIN org ON org.id = e.manager_id
    )
    SELECT * FROM org ORDER BY depth, name
  """)
end

# Category tree
get "/category_tree/:id", args: [id: :int] do
  DB.all("""
    WITH RECURSIVE tree AS (
      SELECT id, name, parent_id, name as path
      FROM categories
      WHERE id = ?

      UNION ALL

      SELECT c.id, c.name, c.parent_id, tree.path || ' > ' || c.name
      FROM categories c
      JOIN tree ON tree.id = c.parent_id
    )
    SELECT * FROM tree
  """, [id])
end
```

### Views

[See example: 6-7-sql-views →](#chapter:6-7-sql-views)

```elixir
init_sql """
  CREATE VIEW IF NOT EXISTS order_summary AS
  SELECT
    o.id,
    o.user_id,
    u.name as customer,
    o.status,
    o.created_at,
    COALESCE(SUM(oi.quantity * oi.price), 0) as total
  FROM orders o
  JOIN users u ON u.id = o.user_id
  LEFT JOIN order_items oi ON oi.order_id = o.id
  GROUP BY o.id;
"""

# Use like a table
get "/orders/summary" do
  DB.all("SELECT * FROM order_summary ORDER BY created_at DESC")
end
```

### Full-Text Search (FTS5)

[See example: 9-3-fuzzy-search →](#chapter:9-3-fuzzy-search)

```elixir
init_sql """
  CREATE VIRTUAL TABLE IF NOT EXISTS posts_fts USING fts5(
    title,
    body,
    content='posts',
    content_rowid='id'
  );

  -- Populate FTS index
  INSERT INTO posts_fts(rowid, title, body)
  SELECT id, title, body FROM posts;
"""

get "/search", args: [q: :string] do
  validate q != "", "Query required"
  DB.all("""
    SELECT p.*
    FROM posts p
    JOIN posts_fts fts ON fts.rowid = p.id
    WHERE posts_fts MATCH ?
    ORDER BY rank
  """, [q <> "*"])  # Wildcard for prefix matching
end
```

### Date/Time Queries

```elixir
# SQLite date functions
DB.all("""
  SELECT *
  FROM events
  WHERE date(start_time) = date('now')
""")

# Last 7 days
DB.all("""
  SELECT *
  FROM orders
  WHERE created_at >= datetime('now', '-7 days')
""")

# Group by date
DB.all("""
  SELECT
    date(created_at) as day,
    COUNT(*) as count,
    SUM(amount) as total
  FROM transactions
  WHERE created_at >= date('now', '-30 days')
  GROUP BY date(created_at)
  ORDER BY day
""")

# Format date
DB.all("""
  SELECT
    strftime('%Y-%m', created_at) as month,
    COUNT(*) as orders
  FROM orders
  GROUP BY strftime('%Y-%m', created_at)
""")
```

---

## Validation & Error Handling

[See example: 4-1-validation →](#chapter:4-1-validation)

### Validation

```elixir
post "/users", args: [name: :string, email: :string, age: :int] do
  # Basic validation
  validate name != "", "Name is required"
  validate String.length(name) >= 2, "Name must be at least 2 characters"

  # Email validation
  validate email != "", "Email is required"
  validate String.contains?(email, "@"), "Invalid email format"

  # Numeric validation
  validate age >= 18, "Must be 18 or older"
  validate age <= 120, "Invalid age"

  # Uniqueness check
  validate !DB.exists?(:users, email: email), "Email already taken"

  id = DB.create(:users, %{name: name, email: email, age: age})
  created(%{id: id})
end
```

### Explicit Halting

```elixir
post "/admin/action" do
  role = get_req_header(conn, "x-role") |> List.first()

  # Explicit halt
  if role != "admin" do
    halt(403, "Admin access required")
  end

  # Continue with action
  perform_admin_action()
  ok()
end
```

### Conditional Responses

```elixir
post "/transfer", args: [from: :int, to: :int, amount: :float] do
  from_account = DB.get!(:accounts, from)
  to_account = DB.get!(:accounts, to)

  cond do
    from_account.balance < amount ->
      halt(400, "Insufficient balance")

    from == to ->
      halt(400, "Cannot transfer to same account")

    amount <= 0 ->
      halt(400, "Amount must be positive")

    true ->
      # Perform transfer
      transaction(fn ->
        DB.update!(:accounts, from, dec: [balance: amount])
        DB.update!(:accounts, to, inc: [balance: amount])
        ok(%{new_balance: from_account.balance - amount})
      end)
  end
end
```

---

## Authentication

[See examples: 3-1-auth-basic →](#chapter:3-1-auth-basic) | [3-2-auth-api-key →](#chapter:3-2-auth-api-key) | [3-3-auth-jwt →](#chapter:3-3-auth-jwt) | [3-4-auth-cookie →](#chapter:3-4-auth-cookie) | [3-5-auth-roles →](#chapter:3-5-auth-roles)

### Basic Authentication

```elixir
post "/login", args: [username: :string, password: :string] do
  user = DB.one(:users, where: [username: username, password: password])
  validate user != nil, "Invalid credentials"

  ok(%{user: %{id: user.id, username: user.username, role: user.role}})
end
```

### API Key Authentication

```elixir
defp require_api_key(conn) do
  key = get_req_header(conn, "x-api-key") |> List.first()
  validate key != nil, "API key required"

  api_key = DB.one(:api_keys, where: [key: key, active: true])
  validate api_key != nil, "Invalid API key"

  {conn, api_key}
end

get "/api/data" do
  {conn, _key} = require_api_key(conn)
  DB.list(:data)
end
```

### JWT Authentication

```elixir
@secret "your-secret-key"

defp generate_jwt(user) do
  header = %{alg: "HS256", typ: "JWT"}
  payload = %{
    sub: user.id,
    role: user.role,
    exp: System.system_time(:second) + 3600  # 1 hour
  }

  header_b64 = Base.url_encode64(Jason.encode!(header), padding: false)
  payload_b64 = Base.url_encode64(Jason.encode!(payload), padding: false)
  signature = :crypto.mac(:hmac, :sha256, @secret, "#{header_b64}.#{payload_b64}")
                |> Base.url_encode64(padding: false)

  "#{header_b64}.#{payload_b64}.#{signature}"
end

defp verify_jwt(token) do
  [header_b64, payload_b64, signature] = String.split(token, ".")
  expected_sig = :crypto.mac(:hmac, :sha256, @secret, "#{header_b64}.#{payload_b64}")
                  |> Base.url_encode64(padding: false)

  if signature == expected_sig do
    payload = Base.url_decode64!(payload_b64, padding: false) |> Jason.decode!()
    if payload["exp"] > System.system_time(:second) do
      {:ok, payload}
    else
      {:error, "Token expired"}
    end
  else
    {:error, "Invalid signature"}
  end
end

post "/auth/login", args: [username: :string, password: :string] do
  user = DB.one(:users, where: [username: username, password: password])
  validate user != nil, "Invalid credentials"

  token = generate_jwt(user)
  ok(%{token: token, user: user})
end

get "/api/protected" do
  auth = get_req_header(conn, "authorization") |> List.first() || ""
  token = String.replace_prefix(auth, "Bearer ", "")

  case verify_jwt(token) do
    {:ok, payload} -> ok(%{user_id: payload["sub"], role: payload["role"]})
    {:error, msg} -> halt(401, msg)
  end
end
```

### Role-Based Access Control

```elixir
defp require_role(conn, required_role) do
  role = get_req_header(conn, "x-role") |> List.first() || "guest"

  roles_hierarchy = %{
    "admin" => 3,
    "manager" => 2,
    "user" => 1,
    "guest" => 0
  }

  user_level = Map.get(roles_hierarchy, role, 0)
  required_level = Map.get(roles_hierarchy, required_role, 0)

  validate user_level >= required_level, "Insufficient permissions"
  role
end

get "/admin/users" do
  require_role(conn, "admin")
  DB.list(:users)
end

post "/manager/approve/:id", args: [id: :int] do
  require_role(conn, "manager")
  DB.update!(:requests, id, %{status: "approved"})
  ok()
end
```

### Multi-Tenant Isolation

[See example: 5-8-multi-tenant →](#chapter:5-8-multi-tenant)

```elixir
defp current_tenant(conn) do
  tenant = get_req_header(conn, "x-tenant-id") |> List.first()
  validate tenant != nil, "X-Tenant-ID header required"
  tenant
end

get "/items" do
  tenant = current_tenant(conn)
  DB.list(:items, where: [tenant_id: tenant])
end

post "/items", args: [name: :string] do
  tenant = current_tenant(conn)
  id = DB.create(:items, %{name: name, tenant_id: tenant})
  created(%{id: id})
end
```

---

## Transactions

[See examples: 4-3-transactions →](#chapter:4-3-transactions) | [6-6-sql-transactions →](#chapter:6-6-sql-transactions)

### Basic Transaction

```elixir
post "/transfer", args: [from: :int, to: :int, amount: :float] do
  transaction(fn ->
    from_acc = DB.get!(:accounts, from)
    validate from_acc.balance >= amount, "Insufficient funds"

    DB.update!(:accounts, from, dec: [balance: amount])
    DB.update!(:accounts, to, inc: [balance: amount])

    # Log the transaction
    DB.create(:ledger, %{
      from_account: from,
      to_account: to,
      amount: amount,
      timestamp: System.system_time(:second)
    })

    ok(%{success: true, new_balance: from_acc.balance - amount})
  end)
end
```

### Transaction with Rollback

```elixir
post "/order", args: [items: :any] do
  transaction(fn ->
    # Create order
    order_id = DB.create(:orders, %{
      status: "pending",
      created_at: System.system_time(:second)
    })

    # Reserve stock for each item
    Enum.each(items, fn item ->
      stock = DB.one!(:stock, where: [sku: item["sku"]])
      validate stock.quantity >= item["qty"], "Insufficient stock for #{item["sku"]}"

      DB.update_where!(:stock, [sku: item["sku"]], dec: [quantity: item["qty"]])
      DB.create(:order_items, %{
        order_id: order_id,
        sku: item["sku"],
        quantity: item["qty"],
        price: stock.price
      })
    end)

    DB.update!(:orders, order_id, %{status: "confirmed"})
    created(%{order_id: order_id})
  end)
end
```

### Compensation Pattern (Saga)

```elixir
post "/book_trip", args: [user_id: :int, flight_id: :int, hotel_id: :int] do
  # Book flight
  flight_booking = book_flight(user_id, flight_id)

  case book_hotel(user_id, hotel_id) do
    {:ok, hotel_booking} ->
      # Both succeeded
      ok(%{flight: flight_booking, hotel: hotel_booking})

    {:error, reason} ->
      # Hotel failed, compensate by canceling flight
      cancel_flight(flight_booking.id)
      halt(400, "Hotel booking failed: #{reason}")
  end
end

defp book_flight(user_id, flight_id) do
  id = DB.create(:flight_bookings, %{user_id: user_id, flight_id: flight_id, status: "confirmed"})
  %{id: id}
end

defp book_hotel(user_id, hotel_id) do
  hotel = DB.get(:hotels, hotel_id)
  if hotel && hotel.available_rooms > 0 do
    DB.update!(:hotels, hotel_id, dec: [available_rooms: 1])
    {:ok, %{id: DB.create(:hotel_bookings, %{user_id: user_id, hotel_id: hotel_id})}}
  else
    {:error, "No rooms available"}
  end
end

defp cancel_flight(booking_id) do
  DB.update!(:flight_bookings, booking_id, %{status: "cancelled"})
end
```

---

## Advanced Elixir Patterns

### ETS Caching

[See example: 4-6-caching →](#chapter:4-6-caching)

```elixir
defmodule MyApp.Cache do
  @table :app_cache
  @ttl 60  # seconds

  def child_spec(_), do: %{id: __MODULE__, start: {__MODULE__, :start_link, []}}

  def start_link do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, value, timestamp}] ->
        if System.system_time(:second) - timestamp <= @ttl do
          {:ok, value}
        else
          :expired
        end
      [] ->
        :miss
    end
  end

  def put(key, value) do
    :ets.insert(@table, {key, value, System.system_time(:second)})
  end

  def delete(key), do: :ets.delete(@table, key)
  def clear, do: :ets.delete_all_objects(@table)
end

# Usage in router
get "/expensive" do
  case MyApp.Cache.get(:expensive_data) do
    {:ok, data} ->
      Map.put(data, :cached, true)
    _ ->
      data = compute_expensive_data()
      MyApp.Cache.put(:expensive_data, data)
      Map.put(data, :cached, false)
  end
end
```

### GenServer for Scheduled Tasks

[See example: 5-5-scheduler →](#chapter:5-5-scheduler)

```elixir
defmodule MyApp.Scheduler do
  use GenServer

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Perform scheduled task
    Shared.DB.with_db(fn db ->
      Shared.DB.exec(db, """
        UPDATE sessions SET expired = 1
        WHERE created_at < datetime('now', '-1 hour')
      """)
    end)

    schedule_work()
    {:noreply, state}
  end

  defp schedule_work do
    Process.send_after(self(), :work, :timer.minutes(5))
  end
end

# Add to application children
use Shared.App.Runner, port: 4000, children: [MyApp.Scheduler]
```

### GenServer State Machine

```elixir
defmodule MyApp.OrderProcessor do
  use GenServer

  # Client API
  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def process(order_id), do: GenServer.cast(__MODULE__, {:process, order_id})
  def status(order_id), do: GenServer.call(__MODULE__, {:status, order_id})

  # Server callbacks
  def init(_), do: {:ok, %{orders: %{}}}

  def handle_cast({:process, order_id}, state) do
    # Start async processing
    Task.start(fn -> process_order(order_id) end)
    {:noreply, put_in(state, [:orders, order_id], :processing)}
  end

  def handle_call({:status, order_id}, _from, state) do
    {:reply, Map.get(state.orders, order_id, :unknown), state}
  end

  defp process_order(order_id) do
    # Simulate processing steps
    Process.sleep(1000)
    update_order_status(order_id, "validated")

    Process.sleep(2000)
    update_order_status(order_id, "shipped")
  end

  defp update_order_status(order_id, status) do
    Shared.DB.with_db(fn db ->
      Shared.DB.exec(db, "UPDATE orders SET status = ? WHERE id = ?", [status, order_id])
    end)
  end
end
```

### Background Jobs with Task

[See example: 4-5-jobs →](#chapter:4-5-jobs)

```elixir
post "/jobs", args: [data: :any] do
  job_id = DB.create(:jobs, %{
    data: Jason.encode!(data),
    status: "queued",
    created_at: System.system_time(:second)
  })

  # Fire and forget
  Task.start(fn ->
    Process.sleep(5000)  # Simulate work
    result = process_job(data)

    Shared.DB.with_db(fn db ->
      Shared.DB.exec(db, """
        UPDATE jobs SET status = ?, result = ?, completed_at = ?
        WHERE id = ?
      """, ["completed", Jason.encode!(result), System.system_time(:second), job_id])
    end)
  end)

  created(%{job_id: job_id, status: "queued"})
end

get "/jobs/:id", args: [id: :int] do
  job = DB.get!(:jobs, id)
  %{
    id: job.id,
    status: job.status,
    result: if(job.result, do: Jason.decode!(job.result), else: nil),
    created_at: job.created_at,
    completed_at: job.completed_at
  }
end
```

### Webhook Signature Verification

[See example: 5-4-webhooks →](#chapter:5-4-webhooks)

```elixir
@webhook_secret "your-webhook-secret"

# Custom body reader to preserve raw body
defmodule MyApp.BodyReader do
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} ->
        {:ok, body, Plug.Conn.assign(conn, :raw_body, body)}
      other ->
        other
    end
  end
end

# In router
use Shared.Web, body_reader: {MyApp.BodyReader, :read_body, []}

post "/webhooks/receive" do
  signature = get_req_header(conn, "x-signature") |> List.first() || ""
  raw_body = conn.assigns[:raw_body] || Jason.encode!(conn.body_params)

  expected = :crypto.mac(:hmac, :sha256, @webhook_secret, raw_body)
              |> Base.encode16(case: :lower)

  validate signature == expected, "Invalid signature"

  # Process webhook
  DB.create(:webhook_events, %{
    payload: raw_body,
    received_at: System.system_time(:second)
  })

  ok()
end
```

### Rate Limiting with ETS

```elixir
defmodule MyApp.RateLimiter do
  @table :rate_limits
  @limit 100
  @window 60  # seconds

  def check(key) do
    now = System.system_time(:second)
    window_start = now - @window

    case :ets.lookup(@table, key) do
      [{^key, count, timestamp}] when timestamp >= window_start ->
        if count >= @limit do
          {:error, :rate_limited}
        else
          :ets.insert(@table, {key, count + 1, timestamp})
          {:ok, @limit - count - 1}
        end
      _ ->
        :ets.insert(@table, {key, 1, now})
        {:ok, @limit - 1}
    end
  end
end

# In router
post "/api/action" do
  ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

  case MyApp.RateLimiter.check(ip) do
    {:ok, remaining} ->
      conn = put_resp_header(conn, "x-ratelimit-remaining", to_string(remaining))
      # Continue with action
      ok()
    {:error, :rate_limited} ->
      halt(429, "Rate limit exceeded")
  end
end
```

### Idempotency Keys

[See example: 4-2-idempotency →](#chapter:4-2-idempotency)

```elixir
post "/payments", args: [amount: :float] do
  idempotency_key = get_req_header(conn, "idempotency-key") |> List.first()
  validate idempotency_key != nil, "Idempotency-Key header required"

  # Check for existing request
  existing = DB.one(:idempotency, where: [key: idempotency_key])

  if existing do
    # Return cached response
    Jason.decode!(existing.response) |> Map.put(:cached, true)
  else
    # Process new request
    result = process_payment(amount)

    # Store for future deduplication
    DB.create(:idempotency, %{
      key: idempotency_key,
      response: Jason.encode!(result),
      created_at: System.system_time(:second)
    })

    result
  end
end
```

### File Upload & Processing

[See example: 4-8-uploads →](#chapter:4-8-uploads)

```elixir
plug Plug.Static, at: "/uploads", from: "uploads"

post "/upload" do
  case conn.params["file"] do
    %Plug.Upload{filename: name, path: temp_path, content_type: content_type} ->
      # Validate file type
      validate content_type in ["image/jpeg", "image/png", "application/pdf"],
        "Invalid file type"

      # Validate file size
      %{size: size} = File.stat!(temp_path)
      validate size <= 10_000_000, "File too large (max 10MB)"

      # Generate unique filename
      ext = Path.extname(name)
      stored_name = "#{:crypto.strong_rand_bytes(16) |> Base.encode16()}#{ext}"

      # Ensure upload directory exists
      File.mkdir_p!("uploads")

      # Copy file
      dest_path = Path.join("uploads", stored_name)
      File.cp!(temp_path, dest_path)

      # Store metadata
      id = DB.create(:files, %{
        original_name: name,
        stored_name: stored_name,
        content_type: content_type,
        size: size,
        uploaded_at: System.system_time(:second)
      })

      created(%{
        id: id,
        filename: name,
        url: "/uploads/#{stored_name}",
        size: size
      })

    _ ->
      halt(400, "No file uploaded")
  end
end
```

### CSV Export

```elixir
get "/export/csv" do
  data = DB.list(:orders, order: "created_at DESC")

  csv = [
    # Header row
    ["ID", "Customer", "Total", "Status", "Date"],
    # Data rows
    Enum.map(data, fn row ->
      [row.id, row.customer_name, row.total, row.status, row.created_at]
    end)
  ]
  |> List.flatten()
  |> Enum.map(fn row -> Enum.join(row, ",") end)
  |> Enum.join("\n")

  conn
  |> put_resp_header("content-type", "text/csv")
  |> put_resp_header("content-disposition", "attachment; filename=orders.csv")
  |> send_resp(200, csv)
end
```

---

## Complete Examples

### Example 1: E-Commerce API

```elixir
defmodule ECommerce.Application do
  use Shared.App.Runner, port: 4000

  init_sql """
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      stock INTEGER DEFAULT 0,
      category TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      status TEXT DEFAULT 'pending',
      total REAL DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      product_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      price REAL NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (product_id) REFERENCES products(id)
    );
  """
end

defmodule ECommerce.Router do
  use Shared.App

  # Products CRUD
  resource "/products" do
    get do
      DB.list(:products, order: "name")
    end

    get "/:id", args: [id: :int] do
      DB.get!(:products, id)
    end

    post args: [name: :string, price: :float, stock: :int, category: :string] do
      validate name != "", "Name required"
      validate price > 0, "Price must be positive"
      id = DB.create(:products, %{name: name, price: price, stock: stock, category: category})
      created(%{id: id})
    end
  end

  # Search with filters
  get "/products/search", args: [q: :string, category: :string, min_price: :float, max_price: :float] do
    conditions = []
    params = []

    sql = "SELECT * FROM products WHERE 1=1"

    sql = if q != "" do
      params = params ++ ["%#{q}%"]
      sql <> " AND name LIKE ?"
    else
      sql
    end

    sql = if category != "" do
      params = params ++ [category]
      sql <> " AND category = ?"
    else
      sql
    end

    sql = if min_price > 0 do
      params = params ++ [min_price]
      sql <> " AND price >= ?"
    else
      sql
    end

    sql = if max_price > 0 do
      params = params ++ [max_price]
      sql <> " AND price <= ?"
    else
      sql
    end

    DB.all(sql <> " ORDER BY name", params)
  end

  # Create order
  post "/orders", args: [items: :any] do
    validate is_list(items) && length(items) > 0, "Items required"

    transaction(fn ->
      order_id = DB.create(:orders, %{status: "pending"})
      total = 0.0

      total = Enum.reduce(items, 0.0, fn item, acc ->
        product = DB.get!(:products, item["product_id"])
        validate product.stock >= item["quantity"], "Insufficient stock for #{product.name}"

        DB.update!(:products, product.id, dec: [stock: item["quantity"]])
        DB.create(:order_items, %{
          order_id: order_id,
          product_id: product.id,
          quantity: item["quantity"],
          price: product.price
        })

        acc + (product.price * item["quantity"])
      end)

      DB.update!(:orders, order_id, %{total: total, status: "confirmed"})
      created(%{order_id: order_id, total: total})
    end)
  end

  # Order details with items
  get "/orders/:id", args: [id: :int] do
    order = DB.get!(:orders, id)
    items = DB.all("""
      SELECT oi.*, p.name as product_name
      FROM order_items oi
      JOIN products p ON p.id = oi.product_id
      WHERE oi.order_id = ?
    """, [id])

    Map.put(order, :items, items)
  end
end
```

### Example 2: Authentication System

```elixir
defmodule Auth.Application do
  use Shared.App.Runner, port: 4000

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      role TEXT DEFAULT 'user',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      token TEXT UNIQUE NOT NULL,
      expires_at INTEGER NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    );

    INSERT OR IGNORE INTO users (id, username, password_hash, role)
    VALUES (1, 'admin', 'admin123', 'admin');
  """
end

defmodule Auth.Router do
  use Shared.App

  @token_ttl 3600  # 1 hour

  post "/register", args: [username: :string, password: :string] do
    validate username != "", "Username required"
    validate String.length(password) >= 6, "Password must be at least 6 characters"
    validate !DB.exists?(:users, username: username), "Username already taken"

    id = DB.create(:users, %{username: username, password_hash: password})
    created(%{id: id, username: username})
  end

  post "/login", args: [username: :string, password: :string] do
    user = DB.one(:users, where: [username: username, password_hash: password])
    validate user != nil, "Invalid credentials"

    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()
    expires_at = System.system_time(:second) + @token_ttl

    DB.create(:sessions, %{user_id: user.id, token: token, expires_at: expires_at})

    ok(%{
      token: token,
      expires_at: expires_at,
      user: %{id: user.id, username: user.username, role: user.role}
    })
  end

  post "/logout" do
    token = get_req_header(conn, "authorization")
            |> List.first()
            |> to_string()
            |> String.replace_prefix("Bearer ", "")

    if token != "" do
      DB.delete_where!(:sessions, [token: token])
    end

    ok()
  end

  # Protected endpoint
  get "/me" do
    user = authenticate!(conn)
    ok(%{id: user.id, username: user.username, role: user.role})
  end

  # Admin only
  get "/admin/users" do
    user = authenticate!(conn)
    validate user.role == "admin", "Admin access required"
    DB.list(:users)
  end

  defp authenticate!(conn) do
    token = get_req_header(conn, "authorization")
            |> List.first()
            |> to_string()
            |> String.replace_prefix("Bearer ", "")

    validate token != "", "Authorization required"

    session = DB.one(:sessions, where: [token: token])
    validate session != nil, "Invalid token"
    validate session.expires_at > System.system_time(:second), "Token expired"

    DB.get!(:users, session.user_id)
  end
end
```

---

## Quick Reference

### Route Macros

| Macro | Description |
|-------|-------------|
| `get "/path"` | GET request |
| `post "/path"` | POST request |
| `put "/path"` | PUT request |
| `delete "/path"` | DELETE request |
| `resource "/path"` | Group related routes |

### DB Methods

| Method | Description |
|--------|-------------|
| `DB.list(table)` | Get all rows |
| `DB.get(table, id)` | Get by ID (nil if not found) |
| `DB.get!(table, id)` | Get by ID (halts if not found) |
| `DB.one(table, where: [...])` | Get single row by condition |
| `DB.count(table)` | Count rows |
| `DB.exists?(table, [...])` | Check existence |
| `DB.create(table, %{...})` | Insert row, return ID |
| `DB.update!(table, id, %{...})` | Update by ID |
| `DB.delete!(table, id)` | Delete by ID |

### Response Helpers

| Helper | HTTP Status |
|--------|-------------|
| `ok()` | 200 |
| `ok(data)` | 200 |
| `created(data)` | 201 |
| `halt(code, msg)` | code |
| `validate(cond, msg)` | 400 on failure |

### WHERE Operators

| Operator | SQL |
|----------|-----|
| `[field: value]` | `field = value` |
| `[field: {:like, "%x%"}]` | `field LIKE '%x%'` |
| `[field: {:gte, n}]` | `field >= n` |
| `[field: {:lte, n}]` | `field <= n` |
| `[field: {:gt, n}]` | `field > n` |
| `[field: {:lt, n}]` | `field < n` |

---

*Last updated: January 2026*
