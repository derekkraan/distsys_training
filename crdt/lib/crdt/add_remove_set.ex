defmodule Crdt.AddRemoveSet do
  @behaviour Crdt.CrdtModule

  def new(), do: [[], []]

  def merge([a1, r1], [a2, r2]) do
    [Enum.uniq(a1 ++ a2), Enum.uniq(r1 ++ r2)]
  end

  def read([a, r]) do
    a -- r
  end

  def add([a, r], item) do
    [a ++ [item], r]
  end

  def remove([a, r], item) do
    [a, r ++ [item]]
  end
end
