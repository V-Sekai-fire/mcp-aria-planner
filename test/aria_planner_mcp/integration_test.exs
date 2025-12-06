# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.IntegrationTest do
  use ExUnit.Case
  alias AriaPlannerMcp.Planner

  @moduletag :integration

  describe "end-to-end planning scenario" do
    test "validates and solves a simple planning problem" do
      # Define a simple domain in glTF KHR_interactivity format
      domain = %{
        "nodes" => [
          %{
            "id" => "action1",
            "operation" => "action/move"
          },
          %{
            "id" => "goal1",
            "operation" => "goal/reach"
          }
        ]
      }

      # Define a simple problem
      problem = %{
        "initial_state" => %{
          "variables" => %{
            "agent.position" => [0, 0, 0]
          }
        },
        "goals" => [
          %{
            "type" => "reach",
            "target" => [10, 10, 0]
          }
        ]
      }

      # Validate
      assert {:ok, validation} = Planner.validate(domain, problem)
      assert Map.get(validation, "valid") == true

      # Solve
      assert {:ok, solution} = Planner.solve(domain, problem)
      assert Map.has_key?(solution, :steps)
    end
  end
end

