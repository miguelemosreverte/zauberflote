
defmodule AuthCookie.Sessions do
  use Agent
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def put(sid, user), do: Agent.update(__MODULE__, &Map.put(&1, sid, user))
  def get(sid), do: Agent.get(__MODULE__, &Map.get(&1, sid))
  def delete(sid), do: Agent.update(__MODULE__, &Map.delete(&1, sid))
end

defmodule AuthCookie.Application do
  use Shared.App.Runner, 
    port: 4104,
    children: [AuthCookie.Sessions]

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
  """
end

defmodule AuthCookie.Router do
  use Shared.App
  alias AuthCookie.Sessions

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  post "/auth/login", args: [user: :string, pass: :string] do
    if DB.exists?(:users, username: user, password: pass) do
      sid = Base.encode16(:crypto.strong_rand_bytes(12))
      Sessions.put(sid, user)
      conn
      |> put_resp_cookie("sid", sid, http_only: true, same_site: "Lax")
      |> ok(%{ok: true, user: user})
    else
      halt 401, "invalid credentials"
    end
  end

  post "/auth/logout" do
    sid = conn.cookies["sid"]
    if sid, do: Sessions.delete(sid)
    conn
    |> delete_resp_cookie("sid")
    |> ok(%{ok: true})
  end

  get "/protected" do
    sid = conn.cookies["sid"]
    case sid && Sessions.get(sid) do
      nil -> halt 401, "session required"
      user -> ok %{message: "hello #{user}"}
    end
  end
end