defmodule Express.Mixfile do
  use Mix.Project

  @description """
  Library for sending push notifications.
  Supports Apple APNS (with either ssl certificate or JWT) and Google FCM services.
  """

  def project do
    [
      app: :express,
      version: "1.2.2",
      elixir: "~> 1.4",
      name: "Express",
      description: @description,
      package: package(),
      deps: deps(),
      source_url: "https://github.com/madeinussr/express",
      docs: [extras: ["README.md"]],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod
    ]
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
      {:exop, "~> 0.4.6"},
      {:mock, "~> 0.2.0", only: :test},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.16", only: [:dev, :test, :docs]},
      {:timex, "~> 3.1"},
      {:joken, "~> 1.4"},
      {:gen_stage, "~> 0.12"}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Andrey Chernykh"],
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/madeinussr/express"}
    ]
  end
end
