
defmodule C5WsClient.Application do
  use Shared.App.Runner, port: 4302
end

defmodule C5WsClient.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end
end