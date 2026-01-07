
defmodule C4Caching.CacheServer do
  @table :c4_cache
  @ttl 5

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :worker, restart: :permanent}
  end

  def start_link(_), do: init()
  def init do
    try do
      :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    rescue
      ArgumentError -> :ok
    end
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end

  def get(key) do
    case :ets.lookup(@table, key) do
      [{^key, val, ts}] ->
        age = System.system_time(:second) - ts
        if age <= @ttl, do: {:ok, val, age}, else: :expired
      _ -> :miss
    end
  end

  def put(key, val), do: :ets.insert(@table, {key, val, System.system_time(:second)})
  def clear, do: :ets.delete_all_objects(@table)
end

defmodule C4Caching.Application do
  use Shared.App.Runner, 
    port: 4206,
    children: [C4Caching.CacheServer]

  init_sql """
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      amount REAL NOT NULL
    );
  """
end

defmodule C4Caching.Router do
  use Shared.App
  alias C4Caching.CacheServer, as: Cache

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/events" do
    DB.list(:events, order: "id DESC")
  end

  post "/events", args: [amount: :float] do
    validate amount != 0, "amount must be non-zero"
    DB.create(:events, %{amount: amount})
    Cache.clear()
    ok()
  end

  get "/summary" do
    case Cache.get(:summary) do
      {:ok, val, age} ->
        ok Map.merge(val, %{cached: true, age_seconds: age})
      _ ->
        val = compute_summary()
        Cache.put(:summary, val)
        ok Map.merge(val, %{cached: false, age_seconds: 0})
    end
  end

  defp compute_summary do
    %{
      total: DB.one("SELECT SUM(amount) FROM events", default: [0]) |> Map.values() |> List.first(),
      count: DB.count(:events)
    }
  end
end