
defmodule C6LogicIdempotent.Application do
  use Shared.App.Runner, port: 4420

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total REAL
    );
    CREATE TABLE IF NOT EXISTS idempotency (
      key TEXT PRIMARY KEY,
      order_id INTEGER,
      amount REAL
    );
  """
end

defmodule C6LogicIdempotent.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/orders" do
    DB.list(:orders, order: "id DESC")
  end

  post "/orders", args: [total: :float] do
    validate total > 0, "total required"
    id = DB.create(:orders, %{total: total})
    ok %{id: id}
  end

  post "/orders/:id/discount", args: [id: :int, amount: :float] do
    key = get_req_header(conn, "idempotency-key") |> List.first() || halt(422, "idempotency-key required")
    validate amount > 0, "amount required"
    
    transaction(fn ->
      case DB.one(:idempotency, where: [key: key]) do
        nil ->
          DB.update!(:orders, id, dec: [total: amount])
          DB.create(:idempotency, %{key: key, order_id: id, amount: amount})
          ok %{status: "applied"}
        existing ->
          ok %{status: "cached", cached: existing}
      end
    end)
  end
end