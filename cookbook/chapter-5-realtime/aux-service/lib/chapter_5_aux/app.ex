
defmodule Chapter5Aux.Application do
  use Application

  def start(_type, _args) do
    Chapter5Aux.State.init()
    children = [
      {Plug.Cowboy, scheme: :http, plug: Chapter5Aux.Router, options: [port: 4399, dispatch: dispatch()]}
    ]
    Supervisor.start_link(children, strategy: :one_for_one, name: Chapter5Aux.Supervisor)
  end

  defp dispatch do
    [
      {:_, [
        {"/ws", Chapter5Aux.WSHandler, []},
        {:_, Plug.Cowboy.Handler, {Chapter5Aux.Router, []}}
      ]}
    ]
  end
end

defmodule Chapter5Aux.State do
  @table :chapter5_aux_state

  def init do
    :ets.new(@table, [:named_table, :set, :public, read_concurrency: true])
    :ets.insert(@table, {:flaky_count, 0})
    :ets.insert(@table, {:webhooks, []})
    :ok
  rescue
    ArgumentError -> :ok
  end

  def incr_flaky do
    :ets.update_counter(@table, :flaky_count, {2, 1}, {:flaky_count, 0})
  end

  def reset_flaky do
    :ets.insert(@table, {:flaky_count, 0})
  end

  def add_webhook(payload) do
    list = get_webhooks()
    :ets.insert(@table, {:webhooks, [payload | list]})
  end

  def get_webhooks do
    case :ets.lookup(@table, :webhooks) do
      [{:webhooks, list}] -> list
      _ -> []
    end
  end
end

defmodule Chapter5Aux.JSON do
  defdelegate ok(conn, data), to: Shared.JSON
  defdelegate error(conn, status, message), to: Shared.JSON
end

defmodule Chapter5Aux.Router do
  use Plug.Router
  use Plug.ErrorHandler
  import Plug.Conn

  alias Chapter5Aux.{JSON, State}

  plug CORSPlug
  plug Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason
  plug :match
  plug :dispatch

  get "/ping" do
    JSON.ok(conn, %{ok: true})
  end

  get "/data" do
    JSON.ok(conn, %{message: "Hello from aux", items: [1, 2, 3]})
  end

  get "/flaky" do
    count = State.incr_flaky()
    if count <= 2 do
      JSON.error(conn, 500, "temporary failure")
    else
      JSON.ok(conn, %{ok: true, attempts: count})
    end
  end

  post "/flaky/reset" do
    State.reset_flaky()
    JSON.ok(conn, %{ok: true})
  end

  post "/webhook" do
    payload = conn.body_params
    State.add_webhook(%{payload: payload, received_at: System.system_time(:second)})
    JSON.ok(conn, %{ok: true})
  end

  get "/webhook/log" do
    JSON.ok(conn, Enum.reverse(State.get_webhooks()))
  end

  match _ do
    JSON.error(conn, 404, "not found")
  end

  def handle_errors(conn, %{kind: _kind, reason: reason, stack: _stack}) do
    JSON.error(conn, conn.status || 500, "server_error: #{inspect(reason)}")
  end
end

defmodule Chapter5Aux.WSHandler do
  @behaviour :cowboy_websocket

  def init(req, _state) do
    {:cowboy_websocket, req, %{}} 
  end

  def websocket_init(state) do
    {:ok, state}
  end

  def websocket_handle({:text, msg}, state) do
    reply = "ack:" <> msg
    {:reply, {:text, reply}, state}
  end

  def websocket_handle(_frame, state), do: {:ok, state}

  def websocket_info(_info, state), do: {:ok, state}

  def terminate(_reason, _req, _state), do: :ok
end
