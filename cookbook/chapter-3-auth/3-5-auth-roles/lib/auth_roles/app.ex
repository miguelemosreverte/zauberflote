
defmodule AuthRoles.Sessions do
  use Agent
  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)
  def put(sid, user, role), do: Agent.update(__MODULE__, &Map.put(&1, sid, %{user: user, role: role}))
  def get(sid), do: Agent.get(__MODULE__, &Map.get(&1, sid))
  def delete(sid), do: Agent.update(__MODULE__, &Map.delete(&1, sid))
end

defmodule AuthRoles.Application do
  use Shared.App.Runner, 
    port: 4105,
    children: [AuthRoles.Sessions]

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password, role) VALUES ('admin', 'admin123', 'admin');
    INSERT OR IGNORE INTO users (username, password, role) VALUES ('user', 'user123', 'user');
  """
end

defmodule AuthRoles.Router do
  use Shared.App
  alias AuthRoles.Sessions

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  post "/auth/login", args: [user: :string, pass: :string] do
    case DB.one(:users, where: [username: user, password: pass]) do
      nil -> halt 401, "invalid credentials"
      row ->
        # row: [id, username, password, role]
        role = Enum.at(row, 3)
        sid = Base.encode16(:crypto.strong_rand_bytes(12))
        Sessions.put(sid, user, role)
        conn
        |> put_resp_cookie("sid", sid, http_only: true, same_site: "Lax")
        |> ok(%{user: user, role: role})
    end
  end

  get "/me" do
    case auth_session(conn) do
      {:ok, sess} -> ok sess
      _ -> halt 401, "not logged in"
    end
  end

  get "/admin" do
    case auth_session(conn) do
      {:ok, %{role: "admin"}} -> ok %{message: "admin ok"}
      {:ok, _} -> halt 403, "admin only"
      _ -> halt 401, "login required"
    end
  end

  get "/user" do
    case auth_session(conn) do
      {:ok, _} -> ok %{message: "user ok"}
      _ -> halt 401, "login required"
    end
  end

  defp auth_session(conn) do
    sid = conn.cookies["sid"]
    case sid && Sessions.get(sid) do
      nil -> :error
      sess -> {:ok, sess}
    end
  end
end