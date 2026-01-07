defmodule CalcApp.Application do
  use Shared.App.Runner, port: 5005
end

defmodule CalcApp.Router do
  use Shared.App

  get "/" do
    conn |> put_resp_header("cache-control", "no-store") |> send_file(200, "priv/static/index.html")
  end
end
