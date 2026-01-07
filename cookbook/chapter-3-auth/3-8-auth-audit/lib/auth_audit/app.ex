
defmodule AuthAudit.Application do
  use Shared.App.Runner, port: 4108

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS audit (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event TEXT NOT NULL,
      user TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
  """
end

defmodule AuthAudit.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  post "/auth/login", args: [user: :string, pass: :string] do
    ts = DateTime.utc_now() |> DateTime.to_iso8601()
    
    if DB.exists?(:users, username: user, password: pass) do
      DB.create(:audit, event: "login", user: user, created_at: ts)
      ok()
    else
      DB.create(:audit, event: "login_failed", user: user, created_at: ts)
      halt 401, "invalid credentials"
    end
  end

  get "/audit" do
    DB.list(:audit, order: :id)
  end
end