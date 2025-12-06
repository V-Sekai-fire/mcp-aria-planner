# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.IntegrationTest do
  use ExUnit.Case
  alias AriaPlannerMcp.NativeService

  @moduletag :integration

  setup do
    # Start NativeService for integration testing
    {:ok, pid} = start_supervised({NativeService, []})
    %{service: pid}
  end

  describe "end-to-end MCP tool scenario" do
    test "validates and solves a simple planning problem via MCP tools" do
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

      # Test via MCP tool - validate
      validate_args = %{
        "domain_definition" => domain,
        "problem_definition" => problem
      }
      
      assert {:ok, validate_response, _state} = NativeService.handle_tool_call("aria_planner_validate", validate_args, %{})
      validation_json = List.first(validate_response["content"])["text"]
      validation_result = Jason.decode!(validation_json)
      assert Map.get(validation_result, "valid") == true

      # Test via MCP tool - solve
      solve_args = %{
        "domain_definition" => domain,
        "problem_definition" => problem
      }
      
      assert {:ok, solve_response, _state} = NativeService.handle_tool_call("aria_planner_solve", solve_args, %{})
      solution_json = List.first(solve_response["content"])["text"]
      solution = Jason.decode!(solution_json)
      assert Map.has_key?(solution, "steps")
      assert Map.has_key?(solution, "domain")
      assert Map.has_key?(solution, "goals")
    end

    test "handles complete MCP workflow with initialize" do
      # Initialize
      assert {:ok, init_response, init_state} = NativeService.handle_initialize(%{}, %{})
      assert Map.get(init_response, :protocolVersion) == "2025-06-18"

      # Validate
      domain = %{"nodes" => [%{"id" => "n1", "operation" => "math/add"}]}
      problem = %{"initial_state" => %{}, "goals" => []}
      
      validate_args = %{
        "domain_definition" => domain,
        "problem_definition" => problem
      }
      
      assert {:ok, _validate_response, validate_state} = 
        NativeService.handle_tool_call("aria_planner_validate", validate_args, init_state)

      # Solve
      solve_args = %{
        "domain_definition" => domain,
        "problem_definition" => problem
      }
      
      assert {:ok, _solve_response, _solve_state} = 
        NativeService.handle_tool_call("aria_planner_solve", solve_args, validate_state)
    end
  end
end

