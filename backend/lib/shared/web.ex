defmodule Shared.Web do
  defmacro __using__(opts) do
    body_reader = Keyword.get(opts, :body_reader)
    quote do
      use Plug.Router
      use Plug.ErrorHandler
      import Plug.Conn
      plug CORSPlug
      plug Plug.Static, at: "/", from: "priv/static"
      plug Plug.RequestId
      plug Plug.Logger
      plug :fetch_query_params
      plug :fetch_cookies
      plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json], json_decoder: Jason, body_reader: unquote(body_reader) || {Shared.Web, :default_body_reader, []}
      plug :match
      plug :dispatch
      def handle_errors(conn, %{kind: _, reason: r, stack: _}), do: Shared.JSON.error(conn, conn.status || 500, "server_error: #{inspect(r)}")
    end
  end
  def default_body_reader(conn, opts), do: Plug.Conn.read_body(conn, opts)
end
