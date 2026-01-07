
defmodule AuthJwt.Application do
  use Shared.App.Runner, port: 4103

  init_sql """
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    );
    INSERT OR IGNORE INTO users (username, password) VALUES ('admin', 'admin123');
  """
end

defmodule AuthJwt.JWT do
  @secret "dev-secret"

  def encode(payload) do
    header = %{"alg" => "HS256", "typ" => "JWT"}
    segments = [header, payload] |> Enum.map(&json64/1)
    sig = sign(Enum.join(segments, "."))
    Enum.join(segments ++ [sig], ".")
  end

  def verify(token) do
    with [h, p, s] <- String.split(token, "."),
         ^s <- sign(h <> "." <> p) do
      {:ok, decode64(p)}
    else
      _ -> {:error, :invalid}
    end
  end

  defp sign(data) do
    :crypto.mac(:hmac, :sha256, @secret, data)
    |> Base.url_encode64(padding: false)
  end

  defp json64(map), do: map |> Jason.encode!() |> Base.url_encode64(padding: false)
  defp decode64(seg), do: seg |> Base.url_decode64!(padding: false) |> Jason.decode!()
end

defmodule AuthJwt.Router do
  use Shared.App
  alias AuthJwt.JWT

  get "/" do
    conn |> put_resp_header("cache-control", "no-store") |> send_file(200, "priv/static/index.html")
  end

  post "/auth/login", args: [user: :string, pass: :string] do
    if DB.exists?(:users, username: user, password: pass) do
      ok %{token: JWT.encode(%{"sub" => user})}
    else
      halt 401, "invalid credentials"
    end
  end

  get "/protected" do
    case bearer(conn) do
      {:ok, claims} -> ok %{message: "hello", claims: claims}
      _ -> halt 401, "jwt required"
    end
  end

  defp bearer(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> JWT.verify(token)
      _ -> :error
    end
  end
end