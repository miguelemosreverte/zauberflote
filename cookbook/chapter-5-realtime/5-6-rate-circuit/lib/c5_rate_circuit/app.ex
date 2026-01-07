
defmodule C5RateCircuit.RateServer do
  @table :c5_rate
  @limit 5
  @window 60
  def start_link(_), do: init()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
  def init do
    try do :ets.new(@table, [:named_table, :set, :public]) rescue ArgumentError -> :ok end
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end
  def allow?(key) do
    now = System.system_time(:second)
    case :ets.lookup(@table, key) do
      [{^key, count, start}] when now - start <= @window ->
        if count < @limit do
          :ets.insert(@table, {key, count + 1, start})
          {true, @limit - (count + 1)}
        else
          {false, 0}
        end
      _ ->
        :ets.insert(@table, {key, 1, now})
        {true, @limit - 1}
    end
  end
end

defmodule C5RateCircuit.CircuitServer do
  @table :c5_circuit
  @open_after 2
  @open_seconds 5
  def start_link(_), do: init()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
  def init do
    try do :ets.new(@table, [:named_table, :set, :public]) rescue ArgumentError -> :ok end
    :ets.insert(@table, {:state, :closed, 0, 0})
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end
  def status do
    case :ets.lookup(@table, :state) do
      [{:state, state, failures, opened_at}] -> %{state: state, failures: failures, opened_at: opened_at}
      _ -> %{state: :closed, failures: 0, opened_at: 0}
    end
  end
  def allow? do
    %{state: state, opened_at: opened_at} = status()
    if state == :open and System.system_time(:second) - opened_at < @open_seconds do
      {:error, :open}
    else
      :ok
    end
  end
  def success, do: :ets.insert(@table, {:state, :closed, 0, 0})
  def failure do
    %{failures: failures} = status()
    new_failures = failures + 1
    if new_failures >= @open_after do
      :ets.insert(@table, {:state, :open, new_failures, System.system_time(:second)})
    else
      :ets.insert(@table, {:state, :closed, new_failures, 0})
    end
  end
end

defmodule C5RateCircuit.Application do
  use Shared.App.Runner, 
    port: 4306,
    children: [C5RateCircuit.RateServer, C5RateCircuit.CircuitServer]
end

defmodule C5RateCircuit.Router do
  use Shared.App
  alias C5RateCircuit.RateServer, as: Rate
  alias C5RateCircuit.CircuitServer, as: Circuit

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/protected" do
    key = get_req_header(conn, "x-client") |> List.first() || "anon"
    case Rate.allow?(key) do
      {true, rem} -> ok %{remaining: rem}
      {false, _} -> halt 429, "rate limit exceeded"
    end
  end

  post "/proxy" do
    case Circuit.allow?() do
      {:error, :open} -> halt 503, "circuit open"
      :ok ->
        case :httpc.request('http://localhost:4399/flaky') do
          {:ok, {{_, 200, _}, _, body}} ->
            Circuit.success()
            ok %{ok: true, body: Jason.decode!(body)}
          _ ->
            Circuit.failure()
            halt 502, "upstream error"
        end
    end
  end

  get "/circuit", do: Circuit.status()
end