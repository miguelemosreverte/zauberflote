
defmodule C5HttpClient.Application do
  use Shared.App.Runner, port: 4303
end

defmodule C5HttpClient.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  post "/fetch", args: [retries: :int] do
    retries = if retries <= 0, do: 3, else: retries
    {result, attempts} = fetch_with_retries(retries)
    case result do
      {:ok, body} -> ok %{attempts: attempts, body: body}
      {:error, reason} -> halt 502, "failed after #{attempts} attempts: #{reason}"
    end
  end

  post "/reset" do
    _ = :httpc.request(:post, {'http://localhost:4399/flaky/reset', [], 'application/json', ''}, [], [])
    ok()
  end

  defp fetch_with_retries(max), do: do_fetch(1, max)
  defp do_fetch(att, max) do
    case :httpc.request('http://localhost:4399/flaky') do
      {:ok, {{_, 200, _}, _, body}} -> {{:ok, Jason.decode!(body)}, att}
      _ when att < max -> 
        Process.sleep(200)
        do_fetch(att + 1, max)
      {:ok, {{_, s, _}, _, _}} -> {{:error, "status #{s}"}, att}
      {:error, r} -> {{:error, inspect(r)}, att}
    end
  end
end