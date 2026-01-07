defmodule Shared.DB do
  @default_path "app.db"

  def with_db(fun), do: with_db(@default_path, fun)

  def with_db(path, fun) do
    case open(path) do
      {:ok, conn} ->
        try do
          fun.(conn)
        after
          close(conn)
        end
      {:error, :no_driver} ->
        fun.(nil)
    end
  end

  defp open(path) do
    if Code.ensure_loaded?(Exqlite.Sqlite3) and function_exported?(Exqlite.Sqlite3, :open, 1) do
      Exqlite.Sqlite3.open(path)
    else
      {:error, :no_driver}
    end
  end

  defp close(conn) do
    if function_exported?(Exqlite.Sqlite3, :close, 1) do
      Exqlite.Sqlite3.close(conn)
    else
      :ok
    end
  end

  defp db_mod do
    if Code.ensure_loaded?(Exqlite.Sqlite3) do
      Exqlite.Sqlite3
    else
      raise "Exqlite module not found"
    end
  end

  def exec(conn, sql, params \\ []) do
    mod = db_mod()
    if params == [] do
      case mod.execute(conn, sql) do
        :ok -> :ok
        {:error, r} -> raise "SQLite error: #{inspect(r)}"
      end
    else
      {:ok, stmt} = mod.prepare(conn, sql)
      try do
        :ok = mod.bind(stmt, params)
        case mod.step(conn, stmt) do
          :done -> :ok
          {:error, r} -> raise "SQLite error: #{inspect(r)}"
          _ -> :ok
        end
      after
        mod.release(conn, stmt)
      end
    end
  end

  def one(conn, sql, params \\ []) do
    mod = db_mod()
    {:ok, stmt} = mod.prepare(conn, sql)
    try do
      :ok = mod.bind(stmt, params)
      case mod.step(conn, stmt) do
        :done -> nil
        {:row, values} -> values
        {:error, r} -> raise "SQLite error: #{inspect(r)}"
      end
    after
      mod.release(conn, stmt)
    end
  end

  def all(conn, sql, params \\ []) do
    mod = db_mod()
    {:ok, stmt} = mod.prepare(conn, sql)
    try do
      :ok = mod.bind(stmt, params)
      {:ok, rows} = mod.fetch_all(conn, stmt)
      rows
    after
      mod.release(conn, stmt)
    end
  end

  def all_maps(conn, sql, params \\ []) do
    mod = db_mod()
    {:ok, stmt} = mod.prepare(conn, sql)
    try do
      :ok = mod.bind(stmt, params)
      {:ok, columns} = mod.columns(conn, stmt)
      {:ok, rows} = mod.fetch_all(conn, stmt)
      Enum.map(rows, fn row ->
        Enum.zip(Enum.map(columns, &String.to_atom/1), row) |> Map.new()
      end)
    after
      mod.release(conn, stmt)
    end
  end

  def one_map(conn, sql, params \\ []) do
    mod = db_mod()
    {:ok, stmt} = mod.prepare(conn, sql)
    try do
      :ok = mod.bind(stmt, params)
      {:ok, columns} = mod.columns(conn, stmt)
      case mod.step(conn, stmt) do
        {:row, row} -> Enum.zip(Enum.map(columns, &String.to_atom/1), row) |> Map.new()
        _ -> nil
      end
    after
      mod.release(conn, stmt)
    end
  end

  def tx(conn, fun) do
    exec(conn, "BEGIN")
    try do
      res = fun.()
      exec(conn, "COMMIT")
      res
    rescue
      e -> exec(conn, "ROLLBACK"); reraise e, __STACKTRACE__
    end
  end

  def insert(conn, table, params) do
    keys = Map.keys(params); vals = Map.values(params)
    placeholders = Enum.map(keys, fn _ -> "?" end) |> Enum.join(", ")
    sql = "INSERT INTO #{table} (#{Enum.join(keys, ", ")}) VALUES (#{placeholders})"
    try do
      exec(conn, sql, vals)
      [id] = one(conn, "SELECT last_insert_rowid()")
      {:ok, id}
    rescue
      e -> 
        msg = Exception.message(e)
        if String.contains?(msg, "UNIQUE"), do: {:error, :conflict}, else: reraise(e, __STACKTRACE__)
    end
  end

  def delete(conn, table, id), do: exec(conn, "DELETE FROM #{table} WHERE id = ?", [id])
end
