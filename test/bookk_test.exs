defmodule BookkTest do
  use ExUnit.Case
  doctest Bookk

  test "greets the world" do
    assert Bookk.hello() == :world
  end
end
