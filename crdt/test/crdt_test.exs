defmodule CrdtTest do
  use ExUnit.Case
  doctest Crdt

  test "greets the world" do
    assert Crdt.hello() == :world
  end
end
