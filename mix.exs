defmodule Torex.Mixfile do
  use Mix.Project

  def project do
    [
      app: :torex,
      version: "0.1.0",
      elixir: "~> 1.5.1",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir connector to Tor network",
      package: package()
    ]
  end

  defp package do
    [
      maintainers: ["Alex Filatov"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/alexfilatov/torex"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: apps(Mix.env()), mod: {Torex, []}]
  end

  defp apps(:prod) do
    [:logger, :poison, :httpoison]
  end

  defp apps(:dev) do
    apps(:prod) ++ [:remix]
  end

  defp apps(:test) do
    apps(:dev) ++ []
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 3.1.0"},
      {:httpoison, "~> 0.13.0"},
      {:remix, "~> 0.0.2"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
