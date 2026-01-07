
defmodule C5Scheduler.Ticker do
  use GenServer
  def start_link(_), do: GenServer.start_link(__MODULE__, %{enabled: true}, name: __MODULE__)
  def init(state) do
    :timer.send_interval(2000, :tick)
    {:ok, state}
  end
  def handle_info(:tick, %{enabled: true} = state) do
    Shared.DB.with_db(fn db -> 
      Shared.DB.exec(db, "INSERT INTO ticks (source, created_at) VALUES (?, ?)", ["auto", System.system_time(:second)])
    end)
    {:noreply, state}
  end
  def handle_info(:tick, state), do: {:noreply, state}
  def enable, do: GenServer.cast(__MODULE__, {:set, true})
  def disable, do: GenServer.cast(__MODULE__, {:set, false})
  def status, do: GenServer.call(__MODULE__, :get)
  def handle_cast({:set, v}, s), do: {:noreply, %{s | enabled: v}}
  def handle_call(:get, _, s), do: {:reply, s.enabled, s}
end

defmodule C5Scheduler.Application do
  use Shared.App.Runner, 
    port: 4305,
    children: [C5Scheduler.Ticker]

  init_sql """
    CREATE TABLE IF NOT EXISTS ticks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT,
      created_at INTEGER
    );
  """
end

defmodule C5Scheduler.Router do
  use Shared.App
  alias C5Scheduler.Ticker

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/ticks" do
    DB.list(:ticks, order: "id DESC", limit: 50)
  end

  get "/status" do
    ok %{enabled: Ticker.status()}
  end

  post "/control", args: [enabled: :any] do
    if enabled, do: Ticker.enable(), else: Ticker.disable()
    ok %{enabled: enabled}
  end
end