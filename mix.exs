defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :relix,
      version: "1.0.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: [main_module: CLI]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Relix.Application, []}
    ]
  end

  def cli do
    [preferred_envs: ["relix.watch": :dev]]
  end

  defp deps do
    [
      {:file_system, "~> 1.0"}
    ]
  end
end
