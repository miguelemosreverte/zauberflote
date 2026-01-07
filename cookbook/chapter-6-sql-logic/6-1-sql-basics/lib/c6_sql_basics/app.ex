
defmodule C6SqlBasics.Application do
  use Shared.App.Runner, port: 4401

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      price REAL
    );
  """
end

defmodule C6SqlBasics.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/items" do
    DB.list(:items, order: "id DESC")
  end

  post "/items", args: [name: :string, price: :float] do
    validate name != "", "name required"
    validate price > 0, "price must be > 0"
    DB.create(:items, %{name: name, price: price})
    ok()
  end
end