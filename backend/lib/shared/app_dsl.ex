defmodule Shared.App.DSL do
  defmacro get(do: b), do: quote(do: route(:get, "/", [], do: unquote(b)))
  defmacro get(p, do: b), do: if(is_binary(p), do: quote(do: route(:get, unquote(p), [], do: unquote(b))), else: quote(do: route(:get, "/", unquote(p), do: unquote(b))))
  defmacro get(p, a, do: b), do: quote(do: route(:get, unquote(p), unquote(a), do: unquote(b)))
  defmacro post(do: b), do: quote(do: route(:post, "/", [], do: unquote(b)))
  defmacro post(p, do: b), do: if(is_binary(p), do: quote(do: route(:post, unquote(p), [], do: unquote(b))), else: quote(do: route(:post, "/", unquote(p), do: unquote(b))))
  defmacro post(p, a, do: b), do: quote(do: route(:post, unquote(p), unquote(a), do: unquote(b)))
  defmacro put(do: b), do: quote(do: route(:put, "/", [], do: unquote(b)))
  defmacro put(p, do: b), do: if(is_binary(p), do: quote(do: route(:put, unquote(p), [], do: unquote(b))), else: quote(do: route(:put, "/", unquote(p), do: unquote(b))))
  defmacro put(p, a, do: b), do: quote(do: route(:put, unquote(p), unquote(a), do: unquote(b)))
  defmacro delete(do: b), do: quote(do: route(:delete, "/", [], do: unquote(b)))
  defmacro delete(p, do: b), do: if(is_binary(p), do: quote(do: route(:delete, unquote(p), [], do: unquote(b))), else: quote(do: route(:delete, "/", unquote(p), do: unquote(b))))
  defmacro delete(p, a, do: b), do: quote(do: route(:delete, unquote(p), unquote(a), do: unquote(b)))

  defmacro resource(path, do: block) do
    module = __CALLER__.module
    old = Module.get_attribute(module, :shared_scopes) || []
    Module.put_attribute(module, :shared_scopes, old ++ [path])
    
    quote do
      unquote(block)
      Module.put_attribute(__MODULE__, :shared_scopes, unquote(old))
    end
  end

  defmacro route(method, path, params, do: block) do
    method_atom = method |> to_string() |> String.downcase() |> String.to_atom()
    scopes = Module.get_attribute(__CALLER__.module, :shared_scopes) || []
    full_path = "/" <> ((scopes ++ [path]) |> Enum.map(&to_string/1) |> Enum.map(&String.trim(&1, "/")) |> Enum.reject(&(&1 == "")) |> Enum.join("/"))
    args = if Keyword.keyword?(params) and Keyword.has_key?(params, :args), do: Keyword.get(params, :args), else: params
    bindings = Enum.map(args, fn {k, t} -> quote do var!(unquote(Macro.var(k, nil))) = Shared.App.DSL.parse_param(unquote(t), Map.get(var!(conn).params, to_string(unquote(k)))) end end)
    quote do
      match unquote(full_path), via: unquote(method_atom) do
        unquote_splicing(bindings)
        result = try do Shared.DB.with_db(fn db -> Process.put(:shared_db_conn, db); try do unquote(block) after Process.delete(:shared_db_conn) end end) catch {:halt, c, m} -> {:error, c, m} end
        case result do
          {:ok, d} -> Shared.JSON.ok(var!(conn), d)
          {:created, d} -> Shared.JSON.created(var!(conn), d)
          {:error, :conflict} -> Shared.JSON.error(var!(conn), 409, "already exists")
          {:error, c, m} when is_integer(c) -> Shared.JSON.error(var!(conn), c, m)
          {:error, m} -> Shared.JSON.error(var!(conn), 500, m)
          c = %Plug.Conn{} -> c
          %{} = d -> Shared.JSON.ok(var!(conn), d)
          l when is_list(l) -> Shared.JSON.ok(var!(conn), l)
          nil -> Shared.JSON.error(var!(conn), 404, "not found")
          _ -> Shared.JSON.error(var!(conn), 500, "internal error")
        end
      end
    end
  end

  def parse_param(type, value) do
    case type do
      :int -> Shared.Utils.parse_int(value)
      :integer -> Shared.Utils.parse_int(value)
      :float -> Shared.Utils.parse_amount(value)
      :string -> to_string(value || "") |> String.trim()
      _ -> value
    end
  end
  def validate(condition, message \\ "validation failed"), do: if(!condition, do: throw({:halt, 422, message}))
  def halt(code, message), do: throw({:halt, code, message})
  def ok(data \\ %{ok: true}), do: {:ok, data}
  def ok(conn, data), do: Shared.JSON.ok(conn, data)
  def created(data), do: {:created, data}
  def created(conn, data), do: Shared.JSON.created(conn, data)
  def transaction(fun), do: Shared.DB.tx(Shared.App.DB.get_db(), fun)
end
