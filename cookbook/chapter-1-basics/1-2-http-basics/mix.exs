defmodule Example02HttpBasics.MixProject do
  use Mix.Project

  def project do
    [
      app: :example_02_http_basics,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Example02HttpBasics.Application, []}
    ]
  end

  defp deps do
    [
      {:zauberflote, path: "../../../backend"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:exqlite, "~> 0.34"},
      {:cors_plug, "~> 3.0"}
    ]
  end
end
