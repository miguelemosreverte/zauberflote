
defmodule C4Idempotency.MixProject do
  use Mix.Project

  def project do
    [app: :c4_2_idempotency, version: "0.1.0", elixir: "~> 1.14", start_permanent: Mix.env() == :prod, deps: deps()]
  end

  def application do
    [extra_applications: [:logger], mod: {C4Idempotency.Application, []}]
  end

  defp deps do
    [
      {:zauberflote, path: "../../../backend"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:cors_plug, "~> 3.0"},
      {:exqlite, "~> 0.34"}
    ]
  end
end
