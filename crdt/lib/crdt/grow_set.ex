defmodule Crdt.GrowSet do
  @behaviour Crdt.CrdtModule

  def new(), do: []

  def merge(s1, s2) do
    []
  end

  def read(s) do
    []
  end

  def add(s, item) do
    []
  end
end
