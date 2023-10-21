defmodule Bookk.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github "https://github.com/rwillians/bookk"

  def project do
    [
      app: :bookk,
      version: @version,
      elixir: ">= 1.14.0",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [debug_info: Mix.env() == :dev],
      build_embedded: Mix.env() not in [:dev, :test],
      start_permanent: Mix.env() not in [:dev, :test],
      package: package(),
      source_url: @github,
      docs: [source_ref: "v#{@version}", main: "Bookk"],
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
      #
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    [
      description: "A basic double-entry bookkeeping accounting library.",
      files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Rafael Willians"],
      licenses: ["MIT"],
      links: %{
        Changelog: "#{@github}/blob/master/CHANGELOG.md",
        GitHub: @github
      }
    ]
  end
end
