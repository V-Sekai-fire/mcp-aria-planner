# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.DomainParserTest do
  use ExUnit.Case
  alias AriaPlannerMcp.DomainParser

  describe "parse_behavior_graph/2" do
    test "parses a simple behavior graph" do
      graph = %{
        "nodes" => [
          %{
            "id" => "node1",
            "operation" => "math/add"
          }
        ]
      }

      assert {:ok, domain} = DomainParser.parse_behavior_graph(graph)
      assert Map.has_key?(domain, :type)
      assert Map.has_key?(domain, :entities)
      assert Map.has_key?(domain, :tasks)
      assert Map.has_key?(domain, :actions)
    end

    test "handles JSON string input" do
      graph_json = Jason.encode!(%{
        "nodes" => [
          %{
            "id" => "node1",
            "operation" => "flow/sequence"
          }
        ]
      })

      assert {:ok, domain} = DomainParser.parse_behavior_graph(graph_json)
      assert is_map(domain)
    end

    test "returns error for invalid input" do
      assert {:error, _} = DomainParser.parse_behavior_graph("invalid json")
    end
  end

  describe "validate_behavior_graph/1" do
    test "validates a valid behavior graph" do
      graph = %{
        "nodes" => [
          %{
            "id" => "node1",
            "operation" => "math/add"
          }
        ]
      }

      assert {:ok, result} = DomainParser.validate_behavior_graph(graph)
      assert Map.get(result, "valid") == true
    end

    test "detects missing nodes field" do
      graph = %{}

      assert {:ok, result} = DomainParser.validate_behavior_graph(graph)
      assert Map.get(result, "valid") == false
      assert length(Map.get(result, "errors", [])) > 0
    end

    test "detects invalid node structure" do
      graph = %{
        "nodes" => [
          %{}  # Missing operation field
        ]
      }

      assert {:ok, result} = DomainParser.validate_behavior_graph(graph)
      assert Map.get(result, "valid") == false
    end
  end
end

