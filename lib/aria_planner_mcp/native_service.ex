# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

defmodule AriaPlannerMcp.NativeService do
  @moduledoc """
  Native BEAM service for Aria Planner MCP using ex_mcp library.
  Provides planning capabilities via MCP protocol.

  This server provides tools for:
  - Validating planning domains and problems
  - Solving planning problems using trajectory generation, ranking, and judgment

  ## Input Format

  Domains and problems are provided as JSON (domain_definition and problem_definition).

  ## Output Format

  Validation and solution results are returned as JSON strings in the MCP content field.
  """

  # Suppress warnings from ex_mcp DSL generated code
  @compile {:no_warn_undefined, :no_warn_pattern}

  use ExMCP.Server,
    name: "Aria Planner MCP Server",
    version: "1.0.0"

  alias AriaPlannerMcp.Planner

  @spec child_spec(term()) :: Supervisor.child_spec()
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  # Override do_start_link to start without name when no name is provided
  # This prevents conflicts when ExMCP.MessageProcessor starts temporary instances
  # MessageProcessor now handles :already_started gracefully
  defp do_start_link(:native, opts) do
    name = Keyword.get(opts, :name)

    # Only register name if explicitly provided
    # When ExMCP.MessageProcessor calls start_link([]), no name is provided,
    # so we start without name registration to avoid conflicts
    genserver_opts = if name, do: [name: name], else: []

    GenServer.start_link(__MODULE__, opts, genserver_opts)
  end

  # Define Aria Planner tools using ex_mcp DSL

  deftool "aria_planner_validate" do
    meta do
      name("Validate Planning Domain and Problem")

      description("""
      Validates a planning domain and problem definition.
      
      Accepts domain definitions in glTF KHR_interactivity node-based format or aria-planner format.
      Validates syntax, semantics, and structure according to glTF KHR_interactivity specification.
      
      Returns validation results with errors and warnings if any issues are found.
      """)
    end

    input_schema(%{
      type: "object",
      properties: %{
        domain_definition: %{
          type: "object",
          description: "Domain definition as JSON object (node-based format or aria format)"
        },
        problem_definition: %{
          type: "object",
          description: "Problem definition with initial_state and goals"
        },
        options: %{
          type: "object",
          description: "Optional validation options",
          default: %{}
        }
      },
      required: ["domain_definition", "problem_definition"]
    })

    tool_annotations(%{
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: true
    })
  end

  deftool "aria_planner_solve" do
    meta do
      name("Solve Planning Problem")

      description("""
      Solves a planning problem using aria-planner.
      
      Accepts domain and problem definitions and returns a solution plan.
      """)
    end

    input_schema(%{
      type: "object",
      properties: %{
        domain_definition: %{
          type: "object",
          description: "Domain definition as JSON object (node-based format or aria format)"
        },
        problem_definition: %{
          type: "object",
          description: "Problem definition with initial_state and goals"
        },
        options: %{
          type: "object",
          description: "Optional solving options",
          default: %{}
        }
      },
      required: ["domain_definition", "problem_definition"]
    })

    tool_annotations(%{
      readOnlyHint: true,
      destructiveHint: false,
      idempotentHint: false
    })
  end

  # Initialize handler
  @impl true
  def handle_initialize(params, state) do
    {:ok,
     %{
       protocolVersion: Map.get(params, "protocolVersion", "2025-06-18"),
       serverInfo: %{
         name: "Aria Planner MCP Server",
         version: "1.0.0"
       },
       capabilities: %{
         tools: %{},
         resources: %{},
         prompts: %{}
       }
     }, state}
  end

  # Tool call handlers
  @impl true
  def handle_tool_call(tool_name, args, state) do
    case tool_name do
      "aria_planner_validate" ->
        handle_validate(args, state)

      "aria_planner_solve" ->
        handle_solve(args, state)

      _ ->
        {:error, "Tool not found: #{tool_name}", state}
    end
  end

  defp handle_validate(args, state) do
    # Ensure args is a map
    args = if is_map(args), do: args, else: %{}

    domain_definition = Map.get(args, "domain_definition")
    problem_definition = Map.get(args, "problem_definition")
    options = Map.get(args, "options", %{})

    try do
      result =
        if domain_definition && problem_definition do
          # Convert options to keyword list
          opts = map_to_keyword_list(options)
          
          # Validate domain and problem
          Planner.validate(domain_definition, problem_definition, opts)
        else
          {:error, "domain_definition and problem_definition must be provided"}
        end

      case result do
        {:ok, validation_result} ->
          # Ensure all keys are strings for JSON encoding
          validation_map = normalize_for_json(validation_result)
          
          # Encode to JSON
          case Jason.encode(validation_map) do
            {:ok, validation_json} ->
              content_item = %{"type" => "text", "text" => validation_json}
              response = %{"content" => [content_item]}
              {:ok, response, state}
              
            {:error, encode_error} ->
              error_msg = "Failed to encode validation result to JSON: #{inspect(encode_error)}"
              {:error, error_msg, state}
          end

        {:error, reason} ->
          error_msg = if is_binary(reason), do: reason, else: to_string(reason)
          {:error, error_msg, state}
      end
    rescue
      e ->
        error_msg = "Validation error: #{inspect(e)}"
        {:error, error_msg, state}
    catch
      :exit, reason ->
        error_msg = "Validation exited: #{inspect(reason)}"
        {:error, error_msg, state}
      kind, reason ->
        error_msg = "Validation error (#{inspect(kind)}): #{inspect(reason)}"
        {:error, error_msg, state}
    end
  end

  defp handle_solve(args, state) do
    # Ensure args is a map
    args = if is_map(args), do: args, else: %{}

    domain_definition = Map.get(args, "domain_definition")
    problem_definition = Map.get(args, "problem_definition")
    options = Map.get(args, "options", %{})

    try do
      result =
        if domain_definition && problem_definition do
          # Convert options to keyword list
          opts = map_to_keyword_list(options)
          
          # Solve planning problem
          Planner.solve(domain_definition, problem_definition, opts)
        else
          {:error, "domain_definition and problem_definition must be provided"}
        end

      case result do
        {:ok, solution} ->
          # Ensure all keys are strings for JSON encoding
          solution_map = normalize_for_json(solution)
          
          # Encode to JSON
          case Jason.encode(solution_map) do
            {:ok, solution_json} ->
              content_item = %{"type" => "text", "text" => solution_json}
              response = %{"content" => [content_item]}
              {:ok, response, state}
              
            {:error, encode_error} ->
              error_msg = "Failed to encode solution to JSON: #{inspect(encode_error)}"
              {:error, error_msg, state}
          end

        {:error, reason} ->
          error_msg = if is_binary(reason), do: reason, else: to_string(reason)
          {:error, error_msg, state}
      end
    rescue
      e ->
        error_msg = "Solve error: #{inspect(e)}"
        {:error, error_msg, state}
    catch
      :exit, reason ->
        error_msg = "Solve exited: #{inspect(reason)}"
        {:error, error_msg, state}
      kind, reason ->
        error_msg = "Solve error (#{inspect(kind)}): #{inspect(reason)}"
        {:error, error_msg, state}
    end
  end

  # Recursively convert atom keys to strings for JSON encoding
  defp normalize_for_json(value) when is_map(value) do
    Enum.reduce(value, %{}, fn
      {k, v}, acc when is_atom(k) ->
        Map.put(acc, Atom.to_string(k), normalize_for_json(v))

      {k, v}, acc ->
        Map.put(acc, k, normalize_for_json(v))
    end)
  end

  defp normalize_for_json(value) when is_list(value) do
    Enum.map(value, &normalize_for_json/1)
  end

  defp normalize_for_json(value), do: value

  defp map_to_keyword_list(map) when is_map(map) do
    Enum.map(map, fn {k, v} ->
      key = if is_binary(k), do: String.to_atom(k), else: k
      {key, v}
    end)
  end

  defp map_to_keyword_list(_), do: []
end

