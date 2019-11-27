defmodule Crdt.GCounter do
  @behaviour Crdt.CrdtModule

  def new do
    %{}
  end

  def merge(c1, c2) do
    Map.merge(c1, c2, fn _key, v1, v2 -> Enum.max([v1, v2]) end)
  end

  def increment(counter, key) do
    Map.update(counter, key, 1, &(&1 + 1))
  end

  def read(counter) do
    Enum.reduce(Map.values(counter), 0, &(&1 + &2))
  end
end
