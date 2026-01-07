
defmodule C6LogicCompensation.Application do
  use Shared.App.Runner, port: 4419

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item TEXT,
      status TEXT
    );
    CREATE TABLE IF NOT EXISTS payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER,
      status TEXT
    );
  """
end

defmodule C6LogicCompensation.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/orders" do
    DB.list(:orders, order: "id DESC")
  end

  get "/payments" do
    DB.list(:payments, order: "id DESC")
  end

  post "/orders", args: [item: :string] do
    validate item != "", "item required"
    transaction(fn ->
      id = DB.create(:orders, %{item: item, status: "created"})
      DB.create(:payments, %{order_id: id, status: "paid"})
      ok %{id: id}
    end)
  end

  post "/orders/:id/ship", args: [id: :int, fail: :any] do
    transaction(fn ->
      order = DB.get!(:orders, id)
      validate order.status not in ["failed", "shipped"], "already finalized"
      
      if fail do
        DB.update!(:orders, id, status: "failed")
        DB.update_where!(:payments, [order_id: id], status: "refunded")
        ok %{status: "failed (refunded)"}
      else
        DB.update!(:orders, id, status: "shipped")
        ok %{status: "shipped"}
      end
    end)
  end
end