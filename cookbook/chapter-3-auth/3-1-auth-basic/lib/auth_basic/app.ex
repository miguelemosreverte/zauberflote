
defmodule AuthBasic.Application do
  use Shared.App.Runner, port: 4101

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
    INSERT OR IGNORE INTO users (username, password) VALUES ('user', 'user123');
  """
end

defmodule AuthBasic.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/protected" do
    case basic_auth(conn) do
      {:ok, user} -> ok %{message: "hello #{user}"}
      _ -> halt 401, "basic auth required"
    end
  end

  defp basic_auth(conn) do
    case get_req_header(conn, "authorization") do
      ["Basic " <> encoded] ->
        with {:ok, decoded} <- Base.decode64(encoded),
             [user, pass] <- String.split(decoded, ":", parts: 2),
             true <- valid_user?(user, pass) do
          {:ok, user}
        else
          _ -> :error
        end
      _ -> :error
    end
  end

  defp valid_user?(user, pass) do
    # Check DB for user matching username and password
    DB.exists?(:users, username: user, password: pass)
  end
end
