
defmodule C4Validation.Application do
  use Shared.App.Runner, port: 4201

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      price REAL NOT NULL
    );
  """
end

defmodule C4Validation.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  resource "/items" do
    get do
      DB.list(:items)
    end

    post args: [name: :string, price: :float] do
      validate name != "", "name is required"
      validate price > 0, "price must be > 0"
      
      id = DB.create(:items, name: name, price: price)
      created %{id: id, name: name, price: price}
    end
  end
end