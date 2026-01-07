
defmodule AuthApikey.Application do
  use Shared.App.Runner, port: 4102

  init_sql """
    CREATE TABLE IF NOT EXISTS keys (id INTEGER PRIMARY KEY, value TEXT NOT NULL);
    INSERT OR IGNORE INTO keys (value) VALUES ('key-123');
    INSERT OR IGNORE INTO keys (value) VALUES ('key-456');
  """
end

defmodule AuthApikey.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/protected" do
    case api_key(conn) do
      {:ok, key} -> ok %{message: "hello", key: key}
      _ -> halt 401, "api key required"
    end
  end

  defp api_key(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> key] ->
        if DB.exists?(:keys, value: key), do: {:ok, key}, else: :error
      _ -> :error
    end
  end
end