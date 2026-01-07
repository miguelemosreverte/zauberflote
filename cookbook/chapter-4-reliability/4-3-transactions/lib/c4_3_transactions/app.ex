
defmodule C4Transactions.Application do
  use Shared.App.Runner, port: 4203

  init_sql """
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY,
      balance REAL NOT NULL DEFAULT 0
    );
    INSERT OR IGNORE INTO accounts (id, balance) VALUES (1, 1000);
    INSERT OR IGNORE INTO accounts (id, balance) VALUES (2, 0);
  """
end

defmodule C4Transactions.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/accounts" do
    DB.list(:accounts)
  end

  post "/transfer", args: [amount: :float, from: :int, to: :int] do
    validate amount > 0, "amount must be > 0"

    transaction(fn ->
      acc = DB.get!(:accounts, from)
      validate acc.balance >= amount, "insufficient funds"
      
      DB.update!(:accounts, from, dec: [balance: amount])
      DB.update!(:accounts, to, inc: [balance: amount])
      ok()
    end)
  end
end