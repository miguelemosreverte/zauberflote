defmodule SharedTest do
  use ExUnit.Case
  # Simple test to verify the library is loadable
  test "library is loadable" do
    assert is_list(Shared.Utils.__info__(:functions))
  end
end