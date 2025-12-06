# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.StateConverter do
  @moduledoc """
  Converts between node-based format (glTF KHR_interactivity) and aria-math AEV format.
  
  AEV format: Attribute-Entity-Value structure used by aria-planner for state representation.
  Node-based format: glTF KHR_interactivity behavior graph format with nodes and sockets.
  """

  require Logger

  @doc """
  Converts a behavior graph state (node-based format) to aria-planner state format.
  
  ## Parameters
  
  - `graph_state` - Map containing state from behavior graph (variables, node outputs, etc.)
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, aria_state}` - Converted aria-planner state
  - `{:error, reason}` - Error reason
  """
  @spec graph_to_aria_state(map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def graph_to_aria_state(graph_state, opts \\ []) do
    try do
      # Extract variables from behavior graph state
      variables = Map.get(graph_state, "variables", %{})
      node_outputs = Map.get(graph_state, "nodeOutputs", %{})
      current_time = Map.get(graph_state, "currentTime", DateTime.utc_now())
      
      # Convert variables to AEV format (facts structure)
      facts = convert_variables_to_facts(variables)
      
      # Convert node outputs to facts
      node_facts = convert_node_outputs_to_facts(node_outputs)
      
      # Merge facts
      merged_facts = deep_merge_facts(facts, node_facts)
      
      # Build aria-planner state structure
      aria_state = %{
        current_time: normalize_time(current_time),
        timeline: Map.get(graph_state, "timeline", %{}),
        entity_capabilities: Map.get(graph_state, "entityCapabilities", %{}),
        facts: merged_facts
      }
      
      {:ok, aria_state}
    rescue
      e ->
        Logger.error("Failed to convert graph state to aria state: #{inspect(e)}")
        {:error, "Conversion error: #{inspect(e)}"}
    end
  end

  @doc """
  Converts an aria-planner state to behavior graph state format.
  
  ## Parameters
  
  - `aria_state` - Aria-planner state map
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, graph_state}` - Converted behavior graph state
  - `{:error, reason}` - Error reason
  """
  @spec aria_state_to_graph(map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def aria_state_to_graph(aria_state, opts \\ []) do
    try do
      # Convert facts to variables
      variables = convert_facts_to_variables(aria_state.facts || %{})
      
      # Build behavior graph state structure
      graph_state = %{
        "variables" => variables,
        "currentTime" => normalize_time_to_string(aria_state.current_time || DateTime.utc_now()),
        "timeline" => aria_state.timeline || %{},
        "entityCapabilities" => aria_state.entity_capabilities || %{},
        "nodeOutputs" => %{} # Node outputs are computed during execution
      }
      
      {:ok, graph_state}
    rescue
      e ->
        Logger.error("Failed to convert aria state to graph state: #{inspect(e)}")
        {:error, "Conversion error: #{inspect(e)}"}
    end
  end

  @doc """
  Converts initial state from problem definition to aria-planner state format.
  
  ## Parameters
  
  - `initial_state` - Initial state from problem definition (can be node-based or aria format)
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, aria_state}` - Converted aria-planner state
  - `{:error, reason}` - Error reason
  """
  @spec convert_initial_state(map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def convert_initial_state(initial_state, opts \\ []) do
    # Detect format and convert accordingly
    if is_graph_format?(initial_state) do
      graph_to_aria_state(initial_state, opts)
    else
      # Assume it's already in aria format, just validate
      validate_aria_state(initial_state)
    end
  end

  # Private helper functions

  defp convert_variables_to_facts(variables) when is_map(variables) do
    # Convert variables map to facts structure
    # Variables format: {"var_name" => value}
    # Facts format: facts[subject_id][predicate_table] = value
    
    Enum.reduce(variables, %{}, fn {var_name, value}, acc ->
      # Parse variable name to extract entity and attribute
      {entity_id, predicate} = parse_variable_name(var_name)
      
      Map.update(acc, entity_id, %{predicate => value}, fn existing ->
        Map.put(existing, predicate, value)
      end)
    end)
  end

  defp convert_variables_to_facts(_), do: %{}

  defp convert_node_outputs_to_facts(node_outputs) when is_map(node_outputs) do
    # Convert node outputs to facts
    # Node outputs format: {"node_id.socket_id" => value}
    # Facts format: facts[subject_id][predicate_table] = value
    
    Enum.reduce(node_outputs, %{}, fn {socket_path, value}, acc ->
      # Parse socket path to extract node and socket
      case String.split(socket_path, ".", parts: 2) do
        [node_id, socket_id] ->
          # Use node_id as entity, socket_id as predicate
          Map.update(acc, node_id, %{String.to_atom(socket_id) => value}, fn existing ->
            Map.put(existing, String.to_atom(socket_id), value)
          end)
        
        _ ->
          # Invalid format, skip
          acc
      end
    end)
  end

  defp convert_node_outputs_to_facts(_), do: %{}

  defp convert_facts_to_variables(facts) when is_map(facts) do
    # Convert facts structure to variables
    # Facts format: facts[subject_id][predicate_table] = value
    # Variables format: {"entity_id.predicate" => value}
    
    Enum.reduce(facts, %{}, fn {entity_id, predicates}, acc ->
      Enum.reduce(predicates, acc, fn {predicate, value}, var_acc ->
        var_name = "#{entity_id}.#{Atom.to_string(predicate)}"
        Map.put(var_acc, var_name, value)
      end)
    end)
  end

  defp convert_facts_to_variables(_), do: %{}

  defp parse_variable_name(var_name) when is_binary(var_name) do
    # Try to parse variable name as "entity.attribute" or just use as-is
    case String.split(var_name, ".", parts: 2) do
      [entity, attribute] ->
        {entity, String.to_atom(attribute)}
      
      [name] ->
        # Use default entity and attribute name
        {"default_entity", String.to_atom(name)}
    end
  end

  defp deep_merge_facts(facts1, facts2) do
    # Deep merge two facts maps
    Map.merge(facts1, facts2, fn _key, v1, v2 ->
      if is_map(v1) and is_map(v2) do
        Map.merge(v1, v2)
      else
        v2
      end
    end)
  end

  defp normalize_time(time) when is_binary(time) do
    case DateTime.from_iso8601(time) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end

  defp normalize_time(%DateTime{} = time), do: time
  defp normalize_time(_), do: DateTime.utc_now()

  defp normalize_time_to_string(%DateTime{} = time) do
    DateTime.to_iso8601(time)
  end

  defp normalize_time_to_string(time) when is_binary(time), do: time
  defp normalize_time_to_string(_), do: DateTime.to_iso8601(DateTime.utc_now())

  defp is_graph_format?(state) do
    # Check if state is in graph format (has "variables" or "nodeOutputs" keys)
    Map.has_key?(state, "variables") or Map.has_key?(state, "nodeOutputs")
  end

  defp validate_aria_state(state) do
    # Validate that state has required fields
    required_fields = [:current_time, :facts]
    
    missing_fields = Enum.filter(required_fields, fn field ->
      not Map.has_key?(state, field)
    end)
    
    if length(missing_fields) > 0 do
      {:error, "Missing required fields: #{inspect(missing_fields)}"}
    else
      {:ok, state}
    end
  end
end

