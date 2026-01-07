
defmodule C6LogicTime.Application do
  use Shared.App.Runner, port: 4416

  init_sql """
    CREATE TABLE IF NOT EXISTS subscriptions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user TEXT,
      expires_at INTEGER,
      status TEXT
    );
  """
end

defmodule C6LogicTime.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/subscriptions" do
    DB.list(:subscriptions, order: "id DESC")
  end

  post "/subscriptions", args: [user: :string, duration: :int] do
    validate user != "", "user required"
    duration = if duration <= 0, do: 60, else: duration
    expires_at = System.system_time(:second) + duration
    DB.create(:subscriptions, %{user: user, expires_at: expires_at, status: "active"})
    ok %{expires_at: expires_at}
  end

  post "/subscriptions/:id/check", args: [id: :int] do
    transaction(fn ->
      sub = DB.get!(:subscriptions, id)
      now = System.system_time(:second)
      
      if sub.expires_at < now do
        DB.update!(:subscriptions, id, status: "expired")
        ok %{status: "expired"}
      else
        ok %{status: "active"}
      end
    end)
  end
end