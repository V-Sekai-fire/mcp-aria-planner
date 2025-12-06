# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule Mix.Tasks.Mcp.Server do
  @moduledoc """
  Mix task to run the Aria Planner MCP server.
  
  Usage:
      mix mcp.server
  """

  use Mix.Task

  @shortdoc "Runs the Aria Planner MCP server"

  @impl Mix.Task
  def run(_args) do
    # Start the application
    Application.ensure_all_started(:aria_planner_mcp)
    
    # Keep the process alive
    Process.sleep(:infinity)
  end
end

