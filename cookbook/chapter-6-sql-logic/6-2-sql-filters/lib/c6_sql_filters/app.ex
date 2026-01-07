
defmodule C6SqlFilters.Application do
  use Shared.App.Runner, port: 4402

  init_sql """
    CREATE TABLE IF NOT EXISTS products (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      category TEXT,
      price REAL
    );
    -- Seed some data
    INSERT OR REPLACE INTO products (id, name, category, price) VALUES (1, 'Phone', 'Electronics', 699.0);
    INSERT OR REPLACE INTO products (id, name, category, price) VALUES (2, 'Laptop', 'Electronics', 1299.0);
    INSERT OR REPLACE INTO products (id, name, category, price) VALUES (3, 'Shirt', 'Apparel', 25.0);
  """
end

defmodule C6SqlFilters.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/products", args: [q: :string, category: :string, min: :float, max: :float, sort: :string, order: :string, limit: :int, offset: :int] do
    limit = if limit <= 0, do: 10, else: limit
    sort_col = if sort in ["name", "category", "price"], do: sort, else: "price"
    order_dir = if String.downcase(order) == "desc", do: "DESC", else: "ASC"
    
    where = []
    where = if q != "", do: where ++ [name: {:like, "%#{q}%"}], else: where
    where = if category != "", do: where ++ [category: category], else: where
    where = if min > 0, do: where ++ [price: {:gte, min}], else: where
    where = if max > 0, do: where ++ [price: {:lte, max}], else: where
    
    %{
      items: DB.list(:products, where: where, order: "#{sort_col} #{order_dir}", limit: limit, offset: offset),
      total: DB.count(:products, where: where),
      limit: limit,
      offset: offset
    }
  end
end