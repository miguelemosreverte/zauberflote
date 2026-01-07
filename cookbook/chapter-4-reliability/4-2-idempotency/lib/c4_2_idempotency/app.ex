
defmodule C4Idempotency.Application do
  use Shared.App.Runner, port: 4202

  init_sql """
    CREATE TABLE IF NOT EXISTS idempotency (
      key TEXT PRIMARY KEY,
      response TEXT NOT NULL
    );
  """
end

defmodule C4Idempotency.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  post "/charge", args: [amount: :float] do
    key = get_req_header(conn, "idempotency-key") |> List.first() |> to_string() |> String.trim()
    validate key != "", "idempotency-key required"

    case DB.one(:idempotency, where: [key: key]) do
      nil ->
        resp = %{charge_id: "ch_" <> Base.encode16(:crypto.strong_rand_bytes(4)), amount: amount}
        DB.create(:idempotency, %{key: key, response: Jason.encode!(resp)})
        Map.put(resp, :source, :new)
      
      row ->
        # row: [key, response]
        json = Enum.at(row, 1)
        Jason.decode!(json)
        |> Enum.into(%{})
        |> Map.put(:source, :cached)
    end
  end
end