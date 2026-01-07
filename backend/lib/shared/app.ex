defmodule Shared.App do
  defmacro __using__(opts) do
    quote do
      use Shared.Web, unquote(opts)
      import Plug.Router, except: [get: 2, get: 3, post: 2, post: 3, put: 2, put: 3, delete: 2, delete: 3, patch: 2, patch: 3, options: 2, options: 3, head: 2, head: 3]
      import Shared.App.DSL
      import Shared.Utils
      alias Shared.App.DB, as: DB
      @before_compile Shared.App
    end
  end

  defmacro __before_compile__(_) do
    quote do
      import Plug.Router
      match _, [] do
        index = "priv/static/index.html"
        if File.exists?(index) do
          var!(conn)
          |> put_resp_header("content-type", "text/html")
          |> send_file(200, index)
        else
          Shared.JSON.error(var!(conn), 404, "not found")
        end
      end
    end
  end
end
