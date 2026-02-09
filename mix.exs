defmodule App.MixProject do
  use Mix.Project

  def project do
    [
      app: :relix,
      version: "1.0.0",
      elixir: "~> 1.18",
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

  defp deps do
    []
  end
end
