
defmodule C6SqlViews.Application do
  use Shared.App.Runner, port: 4407

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      customer TEXT
    );
    CREATE TABLE IF NOT EXISTS line_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      name TEXT,
      price REAL
    );
    DROP VIEW IF EXISTS order_totals;
    CREATE VIEW order_totals AS
      SELECT o.id as order_id, o.customer, COUNT(li.id) as item_count, COALESCE(SUM(li.price), 0) as total
      FROM orders o
      LEFT JOIN line_items li ON li.order_id = o.id
      GROUP BY o.id;
  """
end

defmodule C6SqlViews.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/orders" do
    DB.list(:orders, order: "id DESC")
  end

  get "/totals" do
    DB.list(:order_totals, order: "order_id DESC")
  end

  post "/orders", args: [customer: :string] do
    validate customer != "", "customer required"
    DB.create(:orders, %{customer: customer})
    ok()
  end

  post "/items", args: [order_id: :int, name: :string, price: :float] do
    validate order_id > 0 and name != "" and price > 0, "invalid input"
    DB.create(:line_items, %{order_id: order_id, name: name, price: price})
    ok()
  end
end