defmodule Shared.JSON do
  import Plug.Conn
  def ok(conn, data), do: send_json(conn, 200, %{data: data})
  def created(conn, data), do: send_json(conn, 201, %{data: data})
  def error(conn, status, msg), do: send_json(conn, status, %{error: %{message: msg}})
  defp send_json(conn, status, body) do
    conn |> put_resp_content_type("application/json") |> send_resp(status, Jason.encode!(body))
  end
end
