
defmodule C5Webhooks.BodyReader do
  def read_body(conn, opts) do
    case Plug.Conn.read_body(conn, opts) do
      {:ok, body, conn} -> {:ok, body, Plug.Conn.assign(conn, :raw_body, body)}
      {:more, body, conn} -> {:more, body, Plug.Conn.assign(conn, :raw_body, body)}
    end
  end
end

defmodule C5Webhooks.Application do
  use Shared.App.Runner, port: 4304

  init_sql """
    CREATE TABLE IF NOT EXISTS webhooks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT,
      payload TEXT,
      received_at INTEGER
    );
  """
end

defmodule C5Webhooks.Router do
  use Shared.App, body_reader: {C5Webhooks.BodyReader, :read_body, []}
  @secret "chapter5_secret"

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/webhooks" do
    DB.list(:webhooks, order: "id DESC")
    |> Enum.map(fn row -> 
      Map.update!(row, :payload, &Jason.decode!/1)
    end)
  end

  post "/webhooks/receive" do
    sig = get_req_header(conn, "x-signature") |> List.first() |> to_string()
    raw = conn.assigns[:raw_body] || Jason.encode!(conn.body_params)
    
    if sig != sign(raw) do
      halt 401, "invalid signature"
    else
      DB.create(:webhooks, %{
        source: "incoming",
        payload: raw,
        received_at: System.system_time(:second)
      })
      ok()
    end
  end

  post "/webhooks/send", args: [payload: :any] do
    body = Jason.encode!(payload || %{})
    headers = [{'content-type', 'application/json'}, {'x-signature', to_charlist(sign(body))}]
    _ = :httpc.request(:post, {'http://localhost:4399/webhook', headers, 'application/json', body}, [], [])
    ok()
  end

  defp sign(body) do
    :crypto.mac(:hmac, :sha256, @secret, body)
    |> Base.encode16(case: :lower)
  end
end