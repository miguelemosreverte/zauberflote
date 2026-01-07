defmodule Shared.App.DB do
  def get_db, do: Process.get(:shared_db_conn) || raise "No DB connection"
  def exec(s, p \\ []), do: Shared.DB.exec(get_db(), s, p)
  def one(q, o \\ []) do
    if is_binary(q) do
      params = if Keyword.keyword?(o), do: Keyword.get(o, :params, []), else: o
      default = if Keyword.keyword?(o), do: Keyword.get(o, :default), else: nil
      Shared.DB.one_map(get_db(), q, params) || default
    else
      where = Keyword.get(o, :where, [])
      {conds, vals} = build_where(where)
      Shared.DB.one_map(get_db(), "SELECT * FROM #{q} WHERE #{conds} LIMIT 1", vals)
    end
  end
  def one!(q, o \\ []), do: one(q, o) || throw({:halt, 404, "not found"})
  def all(q, o \\ []) do
    if is_binary(q) do
      Shared.DB.all_maps(get_db(), q, o)
    else
      {conds, vals} = build_where(Keyword.get(o, :where, []))
      sql = "SELECT * FROM #{q} WHERE #{conds} ORDER BY #{Keyword.get(o, :order, "id")}"
      sql = if l = Keyword.get(o, :limit), do: sql <> " LIMIT #{l}", else: sql
      sql = if of = Keyword.get(o, :offset), do: sql <> " OFFSET #{of}", else: sql
      Shared.DB.all_maps(get_db(), sql, vals)
    end
  end
  def list(t, o \\ []), do: all(t, o)
  def get(t, id), do: Shared.DB.one_map(get_db(), "SELECT * FROM #{t} WHERE id = ?", [id])
  def get!(t, id), do: get(t, id) || throw({:halt, 404, "not found"})
  def count(t, o \\ []) do
    {conds, vals} = build_where(Keyword.get(o, :where, []))
    case Shared.DB.one(get_db(), "SELECT COUNT(*) FROM #{t} WHERE #{conds}", vals) do [c] -> c; _ -> 0 end
  end
  def create(t, p) do
    case Shared.DB.insert(get_db(), t, p) do
      {:ok, id} -> id
      {:error, :conflict} -> throw({:halt, 409, "already exists"})
    end
  end
  def update!(t, id, c) do
    {sets, ps} = build_sets(c)
    Shared.DB.exec(get_db(), "UPDATE #{t} SET #{Enum.join(sets, ", ")} WHERE id = ?", ps ++ [id])
    id
  end
  def update_where!(t, w, c) do
    {sets, svs} = build_sets(c)
    {conds, wvs} = build_where(w)
    Shared.DB.exec(get_db(), "UPDATE #{t} SET #{Enum.join(sets, ", ")} WHERE #{conds}", svs ++ wvs)
  end
  def delete!(t, id), do: Shared.DB.delete(get_db(), t, id)
  def delete_where!(t, w) do
    {conds, vals} = build_where(w)
    Shared.DB.exec(get_db(), "DELETE FROM #{t} WHERE #{conds}", vals)
  end
  def exists?(t, w), do: count(t, [where: w]) > 0
  defp build_where([]), do: {"1=1", []}
  defp build_where(w) do
    Enum.reduce(w, {[], []}, fn
      {k, {:like, v}}, {p, vs} -> {p ++ ["#{k} LIKE ?"], vs ++ [v]}
      {k, {:gte, v}}, {p, vs} -> {p ++ ["#{k} >= ?"], vs ++ [v]}
      {k, {:lte, v}}, {p, vs} -> {p ++ ["#{k} <= ?"], vs ++ [v]}
      {k, v}, {p, vs} -> {p ++ ["#{k} = ?"], vs ++ [v]}
    end) |> then(fn {p, v} -> {Enum.join(p, " AND "), v} end)
  end
  defp build_sets(c) do
    Enum.reduce(c, {[], []}, fn 
      {:inc, fs}, {s, p} -> {s ++ Enum.map(fs, fn {k, _} -> "#{k} = #{k} + ?" end), p ++ Keyword.values(fs)}
      {:dec, fs}, {s, p} -> {s ++ Enum.map(fs, fn {k, _} -> "#{k} = #{k} - ?" end), p ++ Keyword.values(fs)}
      {k, v}, {s, p} -> {s ++ ["#{k} = ?"], p ++ [v]}
    end)
  end
end
