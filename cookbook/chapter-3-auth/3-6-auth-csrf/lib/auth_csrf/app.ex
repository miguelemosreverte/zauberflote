
defmodule AuthCsrf.Sessions do
  use Agent
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def put(sid, user), do: Agent.update(__MODULE__, &Map.put(&1, sid, %{user: user, csrf: new_csrf()}))
  def get(sid), do: Agent.get(__MODULE__, &Map.get(&1, sid))
  defp new_csrf, do: Base.encode16(:crypto.strong_rand_bytes(12))
end

defmodule AuthCsrf.Application do
  use Shared.App.Runner, 
    port: 4106,
    children: [AuthCsrf.Sessions]

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
  """
end

defmodule AuthCsrf.Router do
  use Shared.App
  alias AuthCsrf.Sessions

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

  get "/csrf" do
    case get_auth_session(conn) do
      {:ok, %{csrf: token}} -> ok %{token: token}
      _ -> halt 401, "login required"
    end
  end

  post "/protected" do
    case get_auth_session(conn) do
      {:ok, %{csrf: token}} ->
        case get_req_header(conn, "x-csrf-token") do
          [^token] -> ok()
          _ -> halt 403, "csrf token required"
        end
      _ -> halt 401, "login required"
    end
  end

  defp get_auth_session(conn) do
    sid = conn.cookies["sid"]
    case sid && Sessions.get(sid) do
      nil -> :error
      sess -> {:ok, sess}
    end
  end
end