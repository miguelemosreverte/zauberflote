
defmodule C4Pagination.Application do
  use Shared.App.Runner, port: 4204

  init_sql """
    CREATE TABLE IF NOT EXISTS items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    );
    -- Seed data for testing pagination
    INSERT INTO items (name) 
    SELECT 'Item ' || id FROM (
      WITH RECURSIVE t(id) AS (SELECT 1 UNION ALL SELECT id+1 FROM t WHERE id < 50) 
      SELECT id FROM t
    ) 
    WHERE (SELECT COUNT(*) FROM items) < 10;
  """
end

defmodule C4Pagination.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/items", args: [q: :string, limit: :int, offset: :int, order: :string] do
    limit = if limit <= 0, do: 10, else: limit
    order_val = if String.downcase(order) == "desc", do: "DESC", else: "ASC"
    where = if q != "", do: [name: {:like, "%#{q}%"}], else: []
    
    %{
      items: DB.list(:items, where: where, limit: limit, offset: offset, order: "id #{order_val}"),
      total: DB.count(:items, where: where),
      limit: limit,
      offset: offset,
      order: order_val
    }
  end
end