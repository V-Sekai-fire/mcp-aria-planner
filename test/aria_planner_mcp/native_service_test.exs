# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.NativeServiceTest do
  use ExUnit.Case
  alias AriaPlannerMcp.NativeService

  setup do
    # Start NativeService for testing
    {:ok, pid} = start_supervised({NativeService, []})
    %{service: pid}
  end

  describe "handle_initialize/2" do
    test "initializes with default protocol version" do
      params = %{}
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_initialize(params, state)
      assert Map.get(response, :protocolVersion) == "2025-06-18"
      assert Map.get(response, :serverInfo) == %{
        name: "Aria Planner MCP Server",
        version: "1.0.0"
      }
      assert Map.has_key?(response, :capabilities)
    end

    test "initializes with custom protocol version" do
      params = %{"protocolVersion" => "2024-11-05"}
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_initialize(params, state)
      assert Map.get(response, :protocolVersion) == "2024-11-05"
    end
  end

  describe "handle_tool_call/3 - aria_planner_validate" do
    test "validates domain and problem successfully" do
      args = %{
        "domain_definition" => %{
          "nodes" => [
            %{
              "id" => "node1",
              "operation" => "math/add"
            }
          ]
        },
        "problem_definition" => %{
          "initial_state" => %{
            "variables" => %{}
          },
          "goals" => ["goal1"]
        }
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      assert Map.has_key?(response, "content")
      assert length(response["content"]) == 1
      
      content_item = List.first(response["content"])
      assert Map.get(content_item, "type") == "text"
      
      # Parse JSON response
      validation_result = Jason.decode!(content_item["text"])
      assert Map.get(validation_result, "valid") == true
    end

    test "returns error for missing domain_definition" do
      args = %{
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        }
      }
      state = %{}

      assert {:error, error_msg, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      assert String.contains?(error_msg, "domain_definition")
    end

    test "returns error for missing problem_definition" do
      args = %{
        "domain_definition" => %{"nodes" => []}
      }
      state = %{}

      assert {:error, error_msg, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      assert String.contains?(error_msg, "problem_definition")
    end

    test "handles invalid domain gracefully" do
      args = %{
        "domain_definition" => %{},  # Missing nodes
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        }
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      content_item = List.first(response["content"])
      validation_result = Jason.decode!(content_item["text"])
      # Should still return a validation result (may be invalid)
      assert Map.has_key?(validation_result, "valid")
    end

    test "handles non-map args" do
      args = "invalid"
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      content_item = List.first(response["content"])
      validation_result = Jason.decode!(content_item["text"])
      assert Map.get(validation_result, "valid") == false
    end

    test "handles options parameter" do
      args = %{
        "domain_definition" => %{"nodes" => []},
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        },
        "options" => %{"custom_option" => "value"}
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      assert Map.has_key?(response, "content")
    end
  end

  describe "handle_tool_call/3 - aria_planner_solve" do
    test "solves planning problem successfully" do
      args = %{
        "domain_definition" => %{
          "nodes" => [
            %{
              "id" => "node1",
              "operation" => "math/add"
            }
          ]
        },
        "problem_definition" => %{
          "initial_state" => %{
            "variables" => %{}
          },
          "goals" => ["goal1"]
        }
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      assert Map.has_key?(response, "content")
      assert length(response["content"]) == 1
      
      content_item = List.first(response["content"])
      assert Map.get(content_item, "type") == "text"
      
      # Parse JSON response
      solution = Jason.decode!(content_item["text"])
      assert Map.has_key?(solution, "domain")
      assert Map.has_key?(solution, "goals")
      assert Map.has_key?(solution, "steps")
    end

    test "returns error for missing domain_definition" do
      args = %{
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        }
      }
      state = %{}

      assert {:error, error_msg, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      assert String.contains?(error_msg, "domain_definition")
    end

    test "returns error for missing problem_definition" do
      args = %{
        "domain_definition" => %{"nodes" => []}
      }
      state = %{}

      assert {:error, error_msg, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      assert String.contains?(error_msg, "problem_definition")
    end

    test "handles options parameter" do
      args = %{
        "domain_definition" => %{"nodes" => []},
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        },
        "options" => %{"custom_option" => "value"}
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      assert Map.has_key?(response, "content")
    end

    test "handles non-map args" do
      args = "invalid"
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      content_item = List.first(response["content"])
      solution = Jason.decode!(content_item["text"])
      assert Map.has_key?(solution, "domain")
    end
  end

  describe "handle_tool_call/3 - unknown tool" do
    test "returns error for unknown tool" do
      args = %{}
      state = %{}

      assert {:error, error_msg, _new_state} = NativeService.handle_tool_call("unknown_tool", args, state)
      assert String.contains?(error_msg, "not found")
    end
  end

  describe "state management" do
    test "preserves state across tool calls" do
      args = %{
        "domain_definition" => %{"nodes" => []},
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        }
      }
      initial_state = %{call_count: 0}

      assert {:ok, _response1, state1} = NativeService.handle_tool_call("aria_planner_validate", args, initial_state)
      assert {:ok, _response2, state2} = NativeService.handle_tool_call("aria_planner_validate", args, state1)
      
      # State should be preserved (though NativeService doesn't modify it currently)
      assert state1 == initial_state
      assert state2 == state1
    end
  end

  describe "JSON encoding edge cases" do
    test "handles complex nested structures" do
      args = %{
        "domain_definition" => %{
          "nodes" => [
            %{
              "id" => "node1",
              "operation" => "math/add",
              "configuration" => %{
                "nested" => %{
                  "deep" => %{
                    "value" => 42
                  }
                }
              }
            }
          ]
        },
        "problem_definition" => %{
          "initial_state" => %{
            "variables" => %{
              "complex" => %{
                "array" => [1, 2, 3],
                "nested" => %{"key" => "value"}
              }
            }
          },
          "goals" => [
            %{"type" => "complex", "data" => %{"nested" => true}}
          ]
        }
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_validate", args, state)
      content_item = List.first(response["content"])
      # Should successfully encode complex structures
      validation_result = Jason.decode!(content_item["text"])
      assert Map.has_key?(validation_result, "valid")
    end

    test "handles atom keys in response" do
      # This tests the normalize_for_json function
      args = %{
        "domain_definition" => %{"nodes" => []},
        "problem_definition" => %{
          "initial_state" => %{},
          "goals" => []
        }
      }
      state = %{}

      assert {:ok, response, _new_state} = NativeService.handle_tool_call("aria_planner_solve", args, state)
      content_item = List.first(response["content"])
      # Should successfully decode even if original had atom keys
      solution = Jason.decode!(content_item["text"])
      assert is_map(solution)
    end
  end
end

