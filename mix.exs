defmodule Bookk.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/rwillians/bookk"

  @description """
  Bookk provides the building block to build ledger-based double-entry
  bookkeeping solutions for accounting.
  """

  def project do
    [
      app: :bookk,
      version: @version,
      description: @description,
      source_url: @github,
      # homepage_url: @github,
      elixir: ">= 1.14.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [debug_info: Mix.env() == :dev],
      build_embedded: Mix.env() not in [:dev, :test],
      aliases: aliases(),
      package: package(),
      docs: [
        main: "Bookk",
        logo: "logo.png",
        source_ref: "v#{@version}",
        extras: ["README.md", "LICENSE"]
      ],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :apps_direct,
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ]
    ]
  end

  def aliases do
    [
      "test.perf": ["test test/perf.exs"]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: ["test.perf": :test]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.1.0", only: :test},
      {:benchee_html, "~> 1.0.0", only: :test},
      {:ex_doc, "~> 0.30.9", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ~w(lib mix.exs .formatter.exs README.md LICENSE),
      maintainers: ["Rafael Willians"],
      licenses: ["MIT"],
      links: %{
        GitHub: @github,
        Changelog: "#{@github}/releases"
      }
    ]
  end
end
