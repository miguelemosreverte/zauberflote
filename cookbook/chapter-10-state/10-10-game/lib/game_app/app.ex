defmodule GameApp.Application do
  use Shared.App.Runner, port: 5010
end

defmodule GameApp.Router do
  use Shared.App

  get "/" do
    conn |> put_resp_header("cache-control", "no-store") |> send_file(200, "priv/static/index.html")
  end
end
