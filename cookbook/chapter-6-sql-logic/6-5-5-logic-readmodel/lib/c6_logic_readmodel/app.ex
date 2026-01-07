
defmodule C6LogicReadModel.Application do
  use Shared.App.Runner, port: 4415

  init_sql """
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      account TEXT,
      delta REAL
    );
  """
end

defmodule C6LogicReadModel.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/events" do
    DB.list(:events, order: "id DESC")
  end

  post "/events", args: [account: :string, delta: :float] do
    validate account != "", "account required"
    DB.create(:events, %{account: account, delta: delta})
    ok()
  end

  get "/balances" do
    DB.all("SELECT account, SUM(delta) as balance FROM events GROUP BY account")
  end
end