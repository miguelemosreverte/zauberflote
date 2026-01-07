defmodule CounterApp.Application do
  use Shared.App.Runner, port: 5001
end

defmodule CounterApp.Router do
  use Shared.App

  # No backend needed - pure client-side state!
  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end
end
