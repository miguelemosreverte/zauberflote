defmodule Shared.App.Runner do
  defmacro __using__(opts) do
    port = Keyword.get(opts, :port, 4000)
    children = Keyword.get(opts, :children, [])
    cowboy_opts = Keyword.get(opts, :cowboy_opts, []) |> Macro.escape()
    quote do
      use Application
      import Shared.App.Runner, only: [init_sql: 1]
      Module.register_attribute(__MODULE__, :init_sql_statements, accumulate: true)
      Module.put_attribute(__MODULE__, :shared_runner_port, unquote(port))
      Module.put_attribute(__MODULE__, :shared_runner_children, unquote(children))
      Module.put_attribute(__MODULE__, :shared_runner_cowboy_opts, unquote(cowboy_opts))
      @before_compile Shared.App.Runner
    end
  end

  defmacro __before_compile__(env) do
    port = Module.get_attribute(env.module, :shared_runner_port)
    children = Module.get_attribute(env.module, :shared_runner_children)
    cowboy_opts = Module.get_attribute(env.module, :shared_runner_cowboy_opts)
    quote do
      def start(_type, _args) do
        if @init_sql_statements != [] do
          Shared.DB.with_db(fn db -> 
            Enum.each(Enum.reverse(@init_sql_statements), fn sql -> 
              sql |> String.split(";") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "--"))) |> Enum.each(fn s -> Shared.DB.exec(db, s) end)
            end)
          end)
        end
        router = to_string(__MODULE__) |> String.replace(~r/Application$/, "Router") |> String.to_existing_atom()
        children = unquote(children) ++ [{Plug.Cowboy, scheme: :http, plug: router, options: Keyword.merge([port: unquote(port), ip: {0, 0, 0, 0}], unquote(cowboy_opts))}]
        require Logger; Logger.info("🪄 Zauberflöte: Live Development Mode (Source: backend/lib)")
        Supervisor.start_link(children, strategy: :one_for_one, name: __MODULE__.Supervisor)
      end
    end
  end

  defmacro init_sql(sql), do: quote(do: @init_sql_statements unquote(sql))
end