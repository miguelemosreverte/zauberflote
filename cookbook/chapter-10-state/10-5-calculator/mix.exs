defmodule CalcApp.MixProject do
  use Mix.Project

  def project do
    [app: :calc_app, version: "0.1.0", elixir: "~> 1.14", start_permanent: Mix.env() == :prod, deps: deps()]
  end

  def application do
    [extra_applications: [:logger], mod: {CalcApp.Application, []}]
  end

  defp deps, do: [{:zauberflote, path: "../../../backend"}]
end
