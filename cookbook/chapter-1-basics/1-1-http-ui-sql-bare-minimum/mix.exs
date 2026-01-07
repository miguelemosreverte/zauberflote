defmodule EnvelopeApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :envelope_app,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {EnvelopeApp.Application, []}
    ]
  end

  defp deps do
    [
      {:zauberflote, path: "../../../backend"}
    ]
  end
end