
defmodule C6LogicCross.Application do
  use Shared.App.Runner, port: 4413

  init_sql """
    CREATE TABLE IF NOT EXISTS stock (
      sku TEXT PRIMARY KEY,
      qty INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS reservations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sku TEXT,
      qty INTEGER,
      status TEXT
    );
  """
end

defmodule C6LogicCross.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/stock" do
    DB.list(:stock, order: "sku ASC")
  end

  post "/stock", args: [sku: :string, qty: :int] do
    validate sku != "" and qty >= 0
    DB.exec("INSERT INTO stock (sku, qty) VALUES (?, ?) ON CONFLICT(sku) DO UPDATE SET qty = excluded.qty", [sku, qty])
    ok %{sku: sku, qty: qty}
  end

  get "/reservations" do
    DB.list(:reservations, order: "id DESC")
  end

  post "/reserve", args: [sku: :string, qty: :int] do
    validate sku != "" and qty > 0
    transaction(fn ->
      stock = DB.one(:stock, where: [sku: sku])
      validate stock, "sku not found"
      validate stock.qty >= qty, "insufficient stock"
      
      DB.update_where!(:stock, [sku: sku], dec: [qty: qty])
      id = DB.create(:reservations, %{sku: sku, qty: qty, status: "reserved"})
      ok %{id: id, sku: sku, qty: qty, status: "reserved"}
    end)
  end
end