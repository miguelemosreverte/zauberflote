defmodule CartApp.Application do
  use Shared.App.Runner, port: 5002
end

defmodule CartApp.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end
end
