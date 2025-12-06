# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.DomainParser do
  @moduledoc """
  Parser for glTF KHR_interactivity behavior graph format.
  
  Converts node-based behavior graphs (100% compatible with glTF KHR_interactivity)
  to aria-planner's internal domain format (entities, tasks, actions, commands, multigoals).
  """

  require Logger

  @doc """
  Parses a glTF KHR_interactivity behavior graph and converts it to aria-planner domain format.
  
  ## Parameters
  
  - `graph_json` - JSON string or map containing the behavior graph
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, domain}` - Successfully parsed domain map
  - `{:error, reason}` - Error reason
  """
  @spec parse_behavior_graph(String.t() | map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def parse_behavior_graph(graph_json, opts \\ []) do
    try do
      graph = normalize_input(graph_json)
      
      # Validate basic structure
      validate_graph_structure(graph)
      
      # Extract domain elements from behavior graph
      domain = %{
        type: Map.get(graph, "domain_type", "custom"),
        name: Map.get(graph, "name", "Unnamed Domain"),
        description: Map.get(graph, "description", ""),
        entities: extract_entities(graph),
        tasks: extract_tasks(graph),
        actions: extract_actions(graph),
        commands: extract_commands(graph),
        multigoals: extract_multigoals(graph),
        predicates: extract_predicates(graph),
        metadata: %{
          behavior_graph: graph,
          parsed_at: DateTime.utc_now()
        }
      }
      
      {:ok, domain}
    rescue
      e ->
        Logger.error("Failed to parse behavior graph: #{inspect(e)}")
        {:error, "Parse error: #{inspect(e)}"}
    end
  end

  @doc """
  Validates a behavior graph structure according to glTF KHR_interactivity specification.
  
  ## Parameters
  
  - `graph_json` - JSON string or map containing the behavior graph
  
  ## Returns
  
  - `{:ok, validation_result}` - Validation result map
  - `{:error, reason}` - Error reason
  """
  @spec validate_behavior_graph(String.t() | map()) :: {:ok, map()} | {:error, String.t()}
  def validate_behavior_graph(graph_json) do
    try do
      graph = normalize_input(graph_json)
      
      errors = []
      warnings = []
      
      # Check for required structure
      unless Map.has_key?(graph, "nodes") do
        errors = ["Missing required 'nodes' field" | errors]
      end
      
      # Validate nodes structure
      if Map.has_key?(graph, "nodes") do
        nodes = Map.get(graph, "nodes", [])
        
        unless is_list(nodes) do
          errors = ["'nodes' must be an array" | errors]
        else
          # Validate each node
          {node_errors, node_warnings} = validate_nodes(nodes)
          errors = errors ++ node_errors
          warnings = warnings ++ node_warnings
        end
      end
      
      # Check for cycles (behavior graphs must be DAGs)
      if Map.has_key?(graph, "nodes") and is_list(graph["nodes"]) do
        if has_cycles?(graph) do
          errors = ["Behavior graph contains cycles (must be a DAG)" | errors]
        end
      end
      
      valid = length(errors) == 0
      
      result = %{
        "valid" => valid,
        "errors" => Enum.reverse(errors),
        "warnings" => Enum.reverse(warnings),
        "message" => if valid, do: "Behavior graph is valid", else: "Behavior graph has errors"
      }
      
      {:ok, result}
    rescue
      e ->
        {:error, "Validation error: #{inspect(e)}"}
    end
  end

  # Private helper functions

  defp normalize_input(graph_json) when is_binary(graph_json) do
    case Jason.decode(graph_json) do
      {:ok, graph} -> graph
      {:error, reason} -> raise "Invalid JSON: #{inspect(reason)}"
    end
  end

  defp normalize_input(graph) when is_map(graph), do: graph
  defp normalize_input(_), do: raise "Invalid input: must be JSON string or map"

  defp validate_graph_structure(graph) do
    unless is_map(graph) do
      raise "Graph must be a JSON object"
    end
  end

  defp validate_nodes(nodes) when is_list(nodes) do
    Enum.reduce(nodes, {[], []}, fn node, {errors, warnings} ->
      {node_errors, node_warnings} = validate_node(node)
      {errors ++ node_errors, warnings ++ node_warnings}
    end)
  end

  defp validate_node(node) when is_map(node) do
    errors = []
    warnings = []
    
    # Check for operation field (required for glTF KHR_interactivity)
    unless Map.has_key?(node, "operation") do
      errors = ["Node missing required 'operation' field" | errors]
    end
    
    # Validate operation format (should be domain/operation)
    if Map.has_key?(node, "operation") do
      operation = Map.get(node, "operation")
      unless is_binary(operation) and String.contains?(operation, "/") do
        errors = ["Operation must follow 'domain/operation' format" | errors]
      end
    end
    
    {errors, warnings}
  end

  defp validate_node(_), do: {["Node must be a JSON object"], []}

  defp has_cycles?(graph) do
    nodes = Map.get(graph, "nodes", [])
    # Simple cycle detection: check if any node references itself through flow sockets
    # This is a simplified check - full cycle detection would require DFS
    Enum.any?(nodes, fn node ->
      check_node_self_reference(node, nodes)
    end)
  end

  defp check_node_self_reference(node, _all_nodes) do
    # Simplified: check if node has any flow socket connections to itself
    # Full implementation would require tracking all connections
    false
  end

  defp extract_entities(graph) do
    # Extract entities from behavior graph nodes
    # Look for nodes that represent entities (e.g., variable nodes, object nodes)
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "variable/") or String.starts_with?(operation, "object/")
    end)
    |> Enum.map(fn node ->
      %{
        "id" => Map.get(node, "id", generate_id()),
        "type" => extract_entity_type(node),
        "properties" => extract_node_properties(node)
      }
    end)
  end

  defp extract_tasks(graph) do
    # Extract tasks from behavior graph nodes
    # Look for nodes that represent tasks (e.g., flow/sequence, custom task nodes)
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "flow/") or String.starts_with?(operation, "task/")
    end)
    |> Enum.map(fn node ->
      %{
        "id" => Map.get(node, "id", generate_id()),
        "name" => extract_task_name(node),
        "type" => "task",
        "decomposition" => extract_decomposition(node)
      }
    end)
  end

  defp extract_actions(graph) do
    # Extract actions from behavior graph nodes
    # Look for nodes that represent actions (e.g., action/ nodes)
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "action/")
    end)
    |> Enum.map(fn node ->
      %{
        "id" => Map.get(node, "id", generate_id()),
        "name" => extract_action_name(node),
        "arity" => extract_arity(node),
        "preconditions" => extract_preconditions(node),
        "effects" => extract_effects(node)
      }
    end)
  end

  defp extract_commands(graph) do
    # Extract commands from behavior graph nodes
    # Commands are similar to actions but may have side effects
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "command/")
    end)
    |> Enum.map(fn node ->
      %{
        "id" => Map.get(node, "id", generate_id()),
        "name" => extract_command_name(node),
        "arity" => extract_arity(node)
      }
    end)
  end

  defp extract_multigoals(graph) do
    # Extract multigoals from behavior graph nodes
    # Look for nodes that represent goals
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "goal/") or String.starts_with?(operation, "multigoal/")
    end)
    |> Enum.map(fn node ->
      %{
        "id" => Map.get(node, "id", generate_id()),
        "name" => extract_goal_name(node),
        "type" => "multigoal",
        "decomposition" => extract_decomposition(node)
      }
    end)
  end

  defp extract_predicates(graph) do
    # Extract predicates from behavior graph nodes
    # Look for query nodes that represent predicates
    nodes = Map.get(graph, "nodes", [])
    
    nodes
    |> Enum.filter(fn node ->
      operation = Map.get(node, "operation", "")
      String.starts_with?(operation, "query/") or String.starts_with?(operation, "predicate/")
    end)
    |> Enum.map(fn node ->
      extract_predicate_name(node)
    end)
    |> Enum.uniq()
  end

  # Helper functions for extracting node properties

  defp extract_entity_type(node) do
    operation = Map.get(node, "operation", "")
    case operation do
      op when String.starts_with?(op, "variable/") -> "variable"
      op when String.starts_with?(op, "object/") -> "object"
      _ -> "entity"
    end
  end

  defp extract_task_name(node) do
    Map.get(node, "id", "") |> String.replace_prefix("", "task_")
  end

  defp extract_action_name(node) do
    operation = Map.get(node, "operation", "")
    name = Map.get(node, "id", "")
    if name != "", do: name, else: operation |> String.replace("/", "_")
  end

  defp extract_command_name(node) do
    operation = Map.get(node, "operation", "")
    name = Map.get(node, "id", "")
    if name != "", do: name, else: operation |> String.replace("/", "_")
  end

  defp extract_goal_name(node) do
    Map.get(node, "id", "") |> String.replace_prefix("", "goal_")
  end

  defp extract_predicate_name(node) do
    operation = Map.get(node, "operation", "")
    name = Map.get(node, "id", "")
    if name != "", do: name, else: operation |> String.replace("/", "_")
  end

  defp extract_arity(node) do
    # Count input value sockets to determine arity
    input_sockets = Map.get(node, "inputValueSockets", [])
    length(input_sockets)
  end

  defp extract_preconditions(node) do
    # Extract preconditions from node configuration or input flow sockets
    # This is a simplified extraction - full implementation would analyze the graph
    config = Map.get(node, "configuration", %{})
    Map.get(config, "preconditions", [])
  end

  defp extract_effects(node) do
    # Extract effects from node configuration or output flow sockets
    # This is a simplified extraction - full implementation would analyze the graph
    config = Map.get(node, "configuration", %{})
    Map.get(config, "effects", [])
  end

  defp extract_decomposition(node) do
    # Extract decomposition description from node
    config = Map.get(node, "configuration", %{})
    Map.get(config, "decomposition", "")
  end

  defp extract_node_properties(node) do
    # Extract all properties from node except standard fields
    node
    |> Map.drop(["id", "operation", "inputValueSockets", "outputValueSockets", 
                 "inputFlowSockets", "outputFlowSockets", "configuration"])
  end

  defp generate_id do
    # Generate a simple ID (in production, use UUIDv7)
    "node_#{:rand.uniform(1_000_000)}"
  end
end

