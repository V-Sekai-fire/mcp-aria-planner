# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.Planner do
  @moduledoc """
  Planner wrapper that integrates aria-planner APIs.
  """

  require Logger
  alias AriaPlannerMcp.DomainParser
  alias AriaPlannerMcp.StateConverter

  @doc """
  Solves a planning problem using aria-planner.
  
  ## Parameters
  
  - `domain_definition` - Domain definition (node-based format or aria format)
  - `problem_definition` - Problem definition with initial state and goals
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, solution}` - Solution found
  - `{:error, reason}` - Error reason
  """
  @spec solve(map(), map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def solve(domain_definition, problem_definition, opts \\ []) do
    try do
      # Parse domain if needed
      domain = parse_domain(domain_definition)
      
      # Convert initial state
      {:ok, initial_state} = StateConverter.convert_initial_state(
        Map.get(problem_definition, "initial_state", %{}),
        opts
      )
      
      # Extract goals
      goals = Map.get(problem_definition, "goals", [])
      
      # Solve using aria-planner
      # This is a stub - would integrate with actual aria-planner solver
      solution = %{
        domain: domain,
        initial_state: initial_state,
        goals: goals,
        steps: [],
        solved_at: DateTime.utc_now()
      }
      
      {:ok, solution}
    rescue
      e ->
        Logger.error("Planning error: #{inspect(e)}")
        {:error, "Planning failed: #{inspect(e)}"}
    end
  end

  @doc """
  Validates a domain and problem definition.
  
  ## Parameters
  
  - `domain_definition` - Domain definition (node-based format or aria format)
  - `problem_definition` - Problem definition with initial state and goals
  - `opts` - Options keyword list
  
  ## Returns
  
  - `{:ok, validation_result}` - Validation result map
  - `{:error, reason}` - Error reason
  """
  @spec validate(map(), map(), keyword()) :: {:ok, map()} | {:error, String.t()}
  def validate(domain_definition, problem_definition, opts \\ []) do
    try do
      errors = []
      warnings = []
      
      # Validate domain
      domain_validation = validate_domain(domain_definition, opts)
      errors = errors ++ Map.get(domain_validation, "errors", [])
      warnings = warnings ++ Map.get(domain_validation, "warnings", [])
      
      # Validate problem
      problem_validation = validate_problem(problem_definition, opts)
      errors = errors ++ Map.get(problem_validation, "errors", [])
      warnings = warnings ++ Map.get(problem_validation, "warnings", [])
      
      valid = length(errors) == 0
      
      result = %{
        "valid" => valid,
        "errors" => errors,
        "warnings" => warnings,
        "message" => if valid, do: "Domain and problem are valid", else: "Validation failed"
      }
      
      {:ok, result}
    rescue
      e ->
        Logger.error("Validation error: #{inspect(e)}")
        {:error, "Validation failed: #{inspect(e)}"}
    end
  end

  # Private helper functions

  defp parse_domain(domain_definition) do
    # Check if domain is in node-based format (has "nodes" key)
    if Map.has_key?(domain_definition, "nodes") do
      # Parse from node-based format
      case DomainParser.parse_behavior_graph(domain_definition) do
        {:ok, domain} -> domain
        {:error, reason} -> raise "Domain parsing failed: #{reason}"
      end
    else
      # Assume it's already in aria format
      domain_definition
    end
  end

  defp validate_domain(domain_definition, _opts) do
    # Check if domain is in node-based format
    if Map.has_key?(domain_definition, "nodes") do
      case DomainParser.validate_behavior_graph(domain_definition) do
        {:ok, result} -> result
        {:error, reason} -> %{"valid" => false, "errors" => [reason], "warnings" => []}
      end
    else
      # Basic validation for aria format
      %{"valid" => true, "errors" => [], "warnings" => []}
    end
  end

  defp validate_problem(problem_definition, _opts) do
    errors = []
    warnings = []
    
    # Check for required fields
    unless Map.has_key?(problem_definition, "initial_state") do
      errors = ["Missing required 'initial_state' field" | errors]
    end
    
    unless Map.has_key?(problem_definition, "goals") do
      errors = ["Missing required 'goals' field" | errors]
    end
    
    # Validate goals
    if Map.has_key?(problem_definition, "goals") do
      goals = Map.get(problem_definition, "goals", [])
      unless is_list(goals) do
        errors = ["'goals' must be an array" | errors]
      end
    end
    
    %{"valid" => length(errors) == 0, "errors" => errors, "warnings" => warnings}
  end
end

