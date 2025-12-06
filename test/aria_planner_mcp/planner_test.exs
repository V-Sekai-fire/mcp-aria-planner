# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.PlannerTest do
  use ExUnit.Case
  alias AriaPlannerMcp.Planner

  describe "validate/3" do
    test "validates domain and problem" do
      domain = %{
        "nodes" => [
          %{
            "id" => "node1",
            "operation" => "math/add"
          }
        ]
      }

      problem = %{
        "initial_state" => %{
          "variables" => %{}
        },
        "goals" => ["goal1"]
      }

      assert {:ok, result} = Planner.validate(domain, problem)
      assert Map.has_key?(result, "valid")
    end

    test "detects missing initial_state" do
      domain = %{"nodes" => []}
      problem = %{"goals" => []}

      assert {:ok, result} = Planner.validate(domain, problem)
      assert Map.get(result, "valid") == false
    end
  end

  describe "solve/3" do
    test "solves a planning problem" do
      domain = %{
        "nodes" => [
          %{
            "id" => "node1",
            "operation" => "math/add"
          }
        ]
      }

      problem = %{
        "initial_state" => %{
          "variables" => %{}
        },
        "goals" => ["goal1"]
      }

      assert {:ok, solution} = Planner.solve(domain, problem)
      assert Map.has_key?(solution, :domain)
      assert Map.has_key?(solution, :goals)
      assert Map.has_key?(solution, :steps)
    end
  end
end

