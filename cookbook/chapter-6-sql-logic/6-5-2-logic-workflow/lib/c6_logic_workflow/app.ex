
defmodule C6LogicWorkflow.Application do
  use Shared.App.Runner, port: 4412

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      item TEXT,
      status TEXT
    );
  """
end

defmodule C6LogicWorkflow.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/orders" do
    DB.list(:orders, order: "id DESC")
  end

  post "/orders", args: [item: :string] do
    validate item != "", "item required"
    id = DB.create(:orders, %{item: item, status: "created"})
    %{id: id, item: item, status: "created"}
  end

  post "/orders/:id/pay", args: [id: :int] do
    transaction(fn ->
      order = DB.get!(:orders, id)
      validate order.status == "created", "invalid state"
      DB.update!(:orders, id, status: "paid")
      DB.get!(:orders, id)
    end)
  end

  post "/orders/:id/ship", args: [id: :int] do
    transaction(fn ->
      order = DB.get!(:orders, id)
      validate order.status == "paid", "invalid state"
      DB.update!(:orders, id, status: "shipped")
      DB.get!(:orders, id)
    end)
  end
end