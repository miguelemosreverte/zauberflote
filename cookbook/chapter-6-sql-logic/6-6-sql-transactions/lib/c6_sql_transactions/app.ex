
defmodule C6SqlTransactions.Application do
  use Shared.App.Runner, port: 4406

  init_sql """
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY,
      balance REAL
    );
    CREATE TABLE IF NOT EXISTS ledger (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      from_id INTEGER,
      to_id INTEGER,
      amount REAL,
      created_at INTEGER
    );
    INSERT OR IGNORE INTO accounts (id, balance) VALUES (1, 1000.0);
    INSERT OR IGNORE INTO accounts (id, balance) VALUES (2, 1000.0);
  """
end

defmodule C6SqlTransactions.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/accounts" do
    DB.list(:accounts)
  end

  get "/ledger" do
    DB.list(:ledger, order: "id DESC")
  end

  post "/transfer", args: [from: :int, to: :int, amount: :float] do
    validate amount > 0, "amount must be > 0"
    validate from != to, "from and to must differ"
    
    transaction(fn ->
      acc = DB.get!(:accounts, from)
      validate acc.balance >= amount, "insufficient funds"
      
      DB.update!(:accounts, from, dec: [balance: amount])
      DB.update!(:accounts, to, inc: [balance: amount])
      DB.create(:ledger, %{
        from_id: from,
        to_id: to,
        amount: amount,
        created_at: System.system_time(:second)
      })
      ok()
    end)
  end
end