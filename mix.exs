defmodule Express.Mixfile do
  use Mix.Project

  def project do
    [app: :express,
     version: "1.0.0",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     name: "Express",
     source_url: "https://github.com/madeinussr/express",
     deps: deps()]
  end

  def application do
    [extra_applications: [:logger, :poolboy],
     mod: {Express.Application, []}]
  end

  defp deps do
    [
      {:poison, "~> 3.1"},
      {:chatterbox, "~> 0.5"},
      {:poolboy, "~> 1.5"},
      {:httpoison, "~> 0.12"},
      {:exop, "~> 0.4.4"},
      {:mock, "~> 0.2.0", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: [:dev, :test, :docs]}
    ]
  end
end
