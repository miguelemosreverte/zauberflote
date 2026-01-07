defmodule C5WsClient.MixProject do
  use Mix.Project

  def project do
    [app: :c5_2_ws_client, version: "0.1.0", elixir: "~> 1.14", start_permanent: Mix.env() == :prod, deps: deps()]
  end

  def application do
    [extra_applications: [:logger], mod: {C5WsClient.Application, []}]
  end

  defp deps do
    [
      {:zauberflote, path: "../../../backend"},
      {:plug_cowboy, "~> 2.7"},
      {:jason, "~> 1.4"},
      {:cors_plug, "~> 3.0"}
    ]
  end
end
