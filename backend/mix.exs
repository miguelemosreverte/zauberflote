defmodule Shared.MixProject do
  use Mix.Project

  def project do
    [
      app: :zauberflote,
      version: "1.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      description: "Core utilities and DSL for the working examples book.",
      package: [
        licenses: ["ISC"],
        links: %{}
      ],
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:exqlite, "~> 0.34"},
      {:cors_plug, "~> 3.0"},
      {:plug, "~> 1.14"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
end
