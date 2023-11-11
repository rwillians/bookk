defmodule Bookk.MixProject do
  use Mix.Project

  @version "0.1.3"
  @github "https://github.com/rwillians/bookk"

  @description """
  Bookk is a simple library that provides building blocks for operating journal
  entries and manipulating double-entry bookkeeping accounting ledgers.
  """

  def project do
    [
      app: :bookk,
      version: @version,
      description: @description,
      source_url: @github,
      homepage_url: @github,
      elixir: ">= 1.14.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [debug_info: Mix.env() == :dev],
      build_embedded: Mix.env() not in [:dev, :test],
      aliases: aliases(),
      package: package(),
      docs: [
        main: "readme",
        logo: "assets/hex-logo.png",
        source_ref: "v#{@version}",
        source_url: @github,
        canonical: "http://hexdocs.pm/bookk/",
        extras: ["README.md", "LICENSE"]
      ],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix],
        plt_add_deps: :apps_direct
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
      # Performance benchmark
      {:benchee, "~> 1.1.0", only: :test, runtime: false, optional: true},
      {:benchee_html, "~> 1.0.0", only: :test, runtime: false, optional: true},

      # Linter
      {:credo, "~> 1.7.0", only: [:dev, :test], runtime: false, optional: true},
      {:dialyxir, "~> 1.4.2", only: [:dev, :test], runtime: false, optional: true},

      # Docs
      {:ex_doc, "~> 0.30.9", only: [:dev, :docs], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      files: ~w(lib mix.exs .formatter.exs README.md LICENSE),
      maintainers: ["Rafael Willians"],
      contributors: ["Rafael Willians"],
      licenses: ["MIT"],
      links: %{
        GitHub: @github,
        Changelog: "#{@github}/releases"
      }
    ]
  end
end
