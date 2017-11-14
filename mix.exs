defmodule Enamel.Mixfile do
  use Mix.Project

  def project do
    [
      app: :enamel,
      version: "0.1.0",
      elixir: "~> 1.3",
      start_permanent: Mix.env == :prod,
      deps: deps(),

      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        "coveralls": :test,
        "coveralls.html": :test,
        "test": :test,
      ],
      docs: docs(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: "https://github.com/synepis/enamel",
      extras: ["README.md"],
      # assets: ["assets"],
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:erlsom, "~> 1.4", only: :test},
      {:excoveralls, "~> 0.4", only: :test},
      {:ex_doc, "~> 0.18.1", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end
end
