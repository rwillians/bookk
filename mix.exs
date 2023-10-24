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

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
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
