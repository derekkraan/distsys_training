defmodule Crdt.MixProject do
  use Mix.Project

  def project do
    [
      app: :crdt,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Crdt.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:local_cluster, "~> 1.1"},
      {:schism, "~> 1.0"}
    ]
  end

  def aliases do
    [
      test: ["test --no-start --seed 0 --trace --max-failures 1"]
    ]
  end
end
