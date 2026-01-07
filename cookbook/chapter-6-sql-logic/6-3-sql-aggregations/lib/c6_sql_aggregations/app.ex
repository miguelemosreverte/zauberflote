
defmodule C6SqlAggregations.Application do
  use Shared.App.Runner, port: 4403

  init_sql """
    CREATE TABLE IF NOT EXISTS sales (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      category TEXT,
      amount REAL
    );
  """
end

defmodule C6SqlAggregations.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/sales" do
    DB.list(:sales, order: "id DESC")
  end

  get "/report" do
    DB.all("SELECT category, COUNT(*) as count, SUM(amount) as total, AVG(amount) as average FROM sales GROUP BY category ORDER BY total DESC")
  end

  post "/sales", args: [category: :string, amount: :float] do
    validate category != "", "category required"
    validate amount > 0, "amount must be > 0"
    DB.create(:sales, %{category: category, amount: amount})
    ok()
  end
end