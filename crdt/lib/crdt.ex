defmodule Crdt do
  use GenServer

  @tick_interval 20

  def child_spec(options) do
    name = Keyword.get(options, :name)
    %{id: name, start: {__MODULE__, :start_link, [options]}}
  end

  def start_link(options) do
    name = Keyword.get(options, :name)
    GenServer.start_link(__MODULE__, options, name: name)
  end

  def init(options) do
    send_tick()
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

  def reset(crdt) do
    GenServer.call(crdt, :reset)
  end

  defp send_tick() do
    Process.send_after(self(), :tick, @tick_interval)
  end

  def handle_info(:tick, state) do
    case Node.list() do
      [] ->
        nil

      nodes ->
        send({state.name, Enum.random(nodes)}, {:synchronize, state.crdt_state})
    end

    send_tick()

    {:noreply, state}
  end

  def handle_info({:synchronize, remote_crdt_state}, state) do
    new_crdt_state = state.crdt_module.merge(state.crdt_state, remote_crdt_state)

    {:noreply, %{state | crdt_state: new_crdt_state}}
  end

  def handle_call(:reset, _from, state) do
    {:reply, :ok, %{state | crdt_state: state.crdt_module.new()}}
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
