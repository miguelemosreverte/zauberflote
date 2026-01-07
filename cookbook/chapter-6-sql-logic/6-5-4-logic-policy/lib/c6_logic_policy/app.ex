
defmodule C6LogicPolicy.Application do
  use Shared.App.Runner, port: 4414

  init_sql """
    CREATE TABLE IF NOT EXISTS requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL,
      status TEXT
    );
  """
end

defmodule C6LogicPolicy.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/requests" do
    DB.list(:requests, order: "id DESC")
  end

  post "/requests", args: [amount: :float] do
    validate amount > 0, "amount required"
    DB.create(:requests, %{amount: amount, status: "pending"})
    ok()
  end

  post "/requests/:id/approve", args: [id: :int] do
    role = get_req_header(conn, "x-role") |> List.first() || "user"
    transaction(fn ->
      req = DB.get!(:requests, id)
      validate req.status != "approved", "already approved"
      validate req.amount <= 100 or role == "admin", "admin required"
      
      DB.update!(:requests, id, status: "approved")
      ok()
    end)
  end
end