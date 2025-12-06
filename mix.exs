# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.MixProject do
  use Mix.Project

  def project do
    [
      app: :aria_planner_mcp,
      version: "1.0.0-dev",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps(),
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs"
      ],
      test_coverage: [
        summary: [threshold: 70],
        ignore_modules: [
          AriaPlannerMcp.NativeService,
          Mix.Tasks.Mcp.Server,
          AriaPlannerMcp.HttpPlugWrapper,
          AriaPlannerMcp.HttpServer,
          AriaPlannerMcp.Router
        ]
      ]
    ]
  end

  def application do
    [
      mod: {AriaPlannerMcp.Application, []},
      applications: [:logger, :ex_mcp, :jason, :plug_cowboy, :briefly]
    ]
  end

  defp deps do
    [
      {:ex_mcp, git: "https://github.com/fire/ex_mcp.git", branch: "master"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.7"},
      {:briefly, "~> 0.4"},
      {:aria_planner, git: "https://github.com/V-Sekai-fire/aria-planner.git"},
      {:aria_math, git: "https://github.com/V-Sekai-fire/aria-math.git"},
      {:aria_gltf, git: "https://github.com/V-Sekai-fire/aria-gltf.git"},
      {:dialyxir, "~> 1.4.6", only: [:dev], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  defp releases do
    [
      aria_planner_mcp: [
        include_executables_for: [:unix],
        applications: [aria_planner_mcp: :permanent]
      ]
    ]
  end
end

