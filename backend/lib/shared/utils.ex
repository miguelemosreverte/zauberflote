defmodule Shared.Utils do
  def parse_int(v, d \\ 0)
  def parse_int(nil, d), do: d
  def parse_int(v, d), do: (case Integer.parse(to_string(v)) do {n, _} -> n; _ -> d end)
  def parse_amount(v) when is_number(v), do: v
  def parse_amount(v), do: (case Float.parse(to_string(v)) do {n, _} -> n; _ -> 0 end)
end

