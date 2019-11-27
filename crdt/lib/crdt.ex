defmodule Crdt do
  use GenServer

  def child_spec(options) do
    name = Keyword.get(options, :name)
    %{id: name, start: {__MODULE__, :start_link, [options]}}
  end

  def start_link(options) do
    name = Keyword.get(options, :name)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def init(options) do
    crdt_module = Keyword.get(options, :crdt_module)
    name = Keyword.get(options, :name)

    {:ok, %{crdt_module: crdt_module, crdt_state: crdt_module.new(), name: name}}
  end

  def mutate(crdt, operation, arguments) do
    GenServer.call(crdt, {:mutate, operation, arguments})
  end

  def read(crdt) do
    GenServer.call(crdt, :read)
  end

  def handle_call({:mutate, operation, arguments}, _from, state) do
    new_crdt_state = apply(state.crdt_module, operation, [state.crdt_state] ++ arguments)

    {:reply, :ok, %{state | crdt_state: new_crdt_state}}
  end

  def handle_call(:read, _from, state) do
    output = state.crdt_module.read(state.crdt_state)
    {:reply, output, state}
  end
end
