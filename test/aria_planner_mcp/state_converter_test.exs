# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.StateConverterTest do
  use ExUnit.Case
  alias AriaPlannerMcp.StateConverter

  describe "graph_to_aria_state/2" do
    test "converts graph state to aria state" do
      graph_state = %{
        "variables" => %{
          "entity1.attribute1" => 10,
          "entity2.attribute2" => "value"
        },
        "currentTime" => "2025-01-01T00:00:00Z"
      }

      assert {:ok, aria_state} = StateConverter.graph_to_aria_state(graph_state)
      assert Map.has_key?(aria_state, :facts)
      assert Map.has_key?(aria_state, :current_time)
    end

    test "handles empty variables" do
      graph_state = %{
        "variables" => %{},
        "currentTime" => "2025-01-01T00:00:00Z"
      }

      assert {:ok, aria_state} = StateConverter.graph_to_aria_state(graph_state)
      assert aria_state.facts == %{}
    end
  end

  describe "aria_state_to_graph/2" do
    test "converts aria state to graph state" do
      aria_state = %{
        current_time: ~U[2025-01-01 00:00:00Z],
        facts: %{
          "entity1" => %{attribute1: 10},
          "entity2" => %{attribute2: "value"}
        }
      }

      assert {:ok, graph_state} = StateConverter.aria_state_to_graph(aria_state)
      assert Map.has_key?(graph_state, "variables")
      assert Map.has_key?(graph_state, "currentTime")
    end
  end

  describe "convert_initial_state/2" do
    test "converts graph format initial state" do
      initial_state = %{
        "variables" => %{"var1" => 10},
        "currentTime" => "2025-01-01T00:00:00Z"
      }

      assert {:ok, _} = StateConverter.convert_initial_state(initial_state)
    end

    test "validates aria format initial state" do
      initial_state = %{
        current_time: ~U[2025-01-01 00:00:00Z],
        facts: %{}
      }

      assert {:ok, _} = StateConverter.convert_initial_state(initial_state)
    end
  end
end

