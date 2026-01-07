
defmodule C5WsServer.Connections do
  @table :c5_ws_conns
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
    try do
      :ets.new(@table, [:named_table, :set, :public])
    rescue
      ArgumentError -> :ok
    end
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end
  def add(pid), do: :ets.insert(@table, {pid, true})
  def remove(pid), do: :ets.delete(@table, pid)
  def broadcast(msg) do
    for {pid, _} <- :ets.tab2list(@table) do
      send(pid, {:broadcast, msg})
    end
  end
end

defmodule C5WsServer.State do
  @table :c5_ws_messages
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
    try do
      :ets.new(@table, [:named_table, :bag, :public, read_concurrency: true])
    rescue
      ArgumentError -> :ok
    end
    {:ok, spawn(fn -> Process.sleep(:infinity) end)}
  end
  def add(msg), do: :ets.insert(@table, {System.system_time(:millisecond), msg})
  def all do
    :ets.tab2list(@table)
    |> Enum.sort_by(fn {ts, _} -> ts end, :desc)
    |> Enum.map(fn {ts, m} -> %{at: ts, message: m} end)
  end
end

defmodule C5WsServer.Application do
  use Shared.App.Runner, 
    port: 4301,
    children: [C5WsServer.Connections, C5WsServer.State],
    cowboy_opts: [dispatch: [
      {:_, [
        {"/ws", C5WsServer.WSHandler, []},
        {:_, Plug.Cowboy.Handler, {C5WsServer.Router, []}}
      ]}
    ]]
end

defmodule C5WsServer.Router do
  use Shared.App

  get "/" do
    conn
    |> put_resp_header("cache-control", "no-store")
    |> send_file(200, "priv/static/index.html")
  end

  get "/messages" do
    C5WsServer.State.all()
  end
end

defmodule C5WsServer.WSHandler do
  @behaviour :cowboy_websocket
  def init(req, _state), do: {:cowboy_websocket, req, %{}} 
  def websocket_init(state) do
    C5WsServer.Connections.add(self())
    {:ok, state}
  end
  def websocket_handle({:text, msg}, state) do
    C5WsServer.State.add(msg)
    C5WsServer.Connections.broadcast(msg)
    {:ok, state}
  end
  def websocket_handle(_frame, state), do: {:ok, state}
  def websocket_info({:broadcast, msg}, state), do: {:reply, {:text, msg}, state}
  def websocket_info(_info, state), do: {:ok, state}
  def terminate(_reason, _req, _state) do
    C5WsServer.Connections.remove(self())
    :ok
  end
end