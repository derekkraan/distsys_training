defmodule Crdt.GrowSet do
  @behaviour Crdt.CrdtModule

  def new(), do: []

  def merge(s1, s2) do
    (s1 ++ s2) |> Enum.uniq()
  end

  def read(s) do
    s
  end

  def add(s, item) do
    [item | s]
  end
end
