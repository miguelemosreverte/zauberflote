
defmodule C4Observability.MetricsServer do
  @table :c4_metrics

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :worker, restart: :permanent}
  end

  def start_link(_), do: init()
  def init do
    try do
      :ets.new(@table, [:named_table, :set, :public])
    rescue
      ArgumentError -> :ok
    end
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end
  def inc(key), do: :ets.update_counter(@table, key, {2, 1}, {key, 0})
  def all do
    :ets.tab2list(@table)
    |> Enum.map(fn {k, c} -> %{metric: to_string(k), count: c} end)
  end
end

defmodule C4Observability.Application do
  use Shared.App.Runner, 
    port: 4207,
    children: [C4Observability.MetricsServer]

  init_sql """
    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      total REAL NOT NULL
    );
  """
end

defmodule C4Observability.Router do
  use Shared.App
  alias C4Observability.MetricsServer, as: Metrics

  plug :track_metrics

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/orders" do
    DB.list(:orders)
  end

  post "/orders", args: [total: :float] do
    validate total > 0, "total must be > 0"
    DB.create(:orders, %{total: total})
    ok()
  end

  get "/metrics" do
    Metrics.all()
  end

  defp track_metrics(conn, _opts) do
    register_before_send(conn, fn c ->
      Metrics.inc(:requests_total)
      Metrics.inc("status_#{c.status}")
      c
    end)
  end
end