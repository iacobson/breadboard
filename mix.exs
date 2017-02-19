defmodule Breadboard.Mixfile do
  use Mix.Project

  def project do
    [app: :breadboard,
     version: "0.1.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [extra_applications: [:logger],
     mod: {Breadboard, []}]
  end

  defp deps do
    [{:elixir_ale, "~> 0.5.7", only: [:prod], runtime: false}]
  end
end
