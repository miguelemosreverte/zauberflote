
defmodule C5Exports.Application do
  use Shared.App.Runner, port: 4307

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      price REAL
    );
    INSERT OR IGNORE INTO items (id, name, price) VALUES (1, 'Book', 25.0);
    INSERT OR IGNORE INTO items (id, name, price) VALUES (2, 'Pen', 1.5);
  """
end

defmodule C5Exports.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/items" do
    DB.list(:items)
  end

  get "/export.json" do
    data = DB.list(:items)
    conn
    |> put_resp_header("content-disposition", "attachment; filename=items.json")
    |> ok(data)
  end

  get "/export.csv" do
    data = DB.list(:items)
    headers = ["id", "name", "price"]
    csv = [headers | Enum.map(data, fn row -> [row.id, row.name, row.price] end)]
          |> Enum.map(&Enum.join(&1, ","))
          |> Enum.join("\n")
    
    conn
    |> put_resp_header("content-disposition", "attachment; filename=items.csv")
    |> put_resp_content_type("text/csv")
    |> send_resp(200, csv)
  end
end