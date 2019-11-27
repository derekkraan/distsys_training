defmodule Crdt.AddRemoveSet do
  @behaviour Crdt.CrdtModule

  def new(), do: []

  def merge(_, _), do: []
  def read(_), do: []

  def add(_, _), do: []
  def remove(_, _), do: []
end
