defmodule Crdt.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Crdt, name: Crdt.GCounter, crdt_module: Crdt.GCounter},
      {Crdt, name: Crdt.GrowSet, crdt_module: Crdt.GrowSet},
      {Crdt, name: Crdt.AddRemoveSet, crdt_module: Crdt.AddRemoveSet}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Crdt.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
