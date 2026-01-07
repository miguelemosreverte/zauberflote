defmodule FilterApp.Application do
  use Shared.App.Runner, port: 5006
end

defmodule FilterApp.Router do
  use Shared.App

  get "/" do
    conn |> put_resp_header("cache-control", "no-store") |> send_file(200, "priv/static/index.html")
  end
end
