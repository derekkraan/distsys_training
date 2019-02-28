defmodule Margarine.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    :pg2.create(:margarine)

    children = [
      Margarine.Storage,
      Margarine.Cache,
      Margarine.Pg2,
      Plug.Cowboy.child_spec(scheme: :http, plug: Margarine.Router, options: [port: port()])
    ]

    opts = [strategy: :one_for_one, name: Margarine.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp port, do: String.to_integer(System.get_env("PORT") || "4000")
end
