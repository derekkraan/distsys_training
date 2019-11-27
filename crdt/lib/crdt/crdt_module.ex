defmodule Crdt.CrdtModule do
  @type t :: any()

  @callback new :: t()

  @callback merge(t(), t()) :: t()

  @callback read(t()) :: any()
end
