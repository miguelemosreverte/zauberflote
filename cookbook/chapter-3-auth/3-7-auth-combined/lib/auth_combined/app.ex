
defmodule AuthCombined.Sessions do
  use Agent
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def put(sid, user), do: Agent.update(__MODULE__, &Map.put(&1, sid, user))
  def get(sid), do: Agent.get(__MODULE__, &Map.get(&1, sid))
end

defmodule AuthCombined.Application do
  use Shared.App.Runner, 
    port: 4107,
    children: [AuthCombined.Sessions]

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS keys (
      id INTEGER PRIMARY KEY,
      value TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
    INSERT OR IGNORE INTO keys (value) VALUES ('key-123');
    INSERT OR IGNORE INTO keys (value) VALUES ('key-456');
  """
end

defmodule AuthCombined.Router do
  use Shared.App
  alias AuthCombined.Sessions

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
      |> ok(%{ok: true})
    else
      halt 401, "invalid credentials"
    end
  end

  get "/protected" do
    case any_auth(conn) do
      {:ok, who} -> ok %{message: "hello", who: who}
      _ -> halt 401, "auth required"
    end
  end

  defp any_auth(conn) do
    case get_api_key(conn) do
      {:ok, key} -> {:ok, "api_key:#{key}"}
      _ -> get_auth_session(conn)
    end
  end

  defp get_api_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] ->
        if DB.exists?(:keys, value: key), do: {:ok, key}, else: :error
      _ -> :error
    end
  end

  defp get_auth_session(conn) do
    sid = conn.cookies["sid"]
    case sid && Sessions.get(sid) do
      nil -> :error
      user -> {:ok, "session:#{user}"}
    end
  end
end