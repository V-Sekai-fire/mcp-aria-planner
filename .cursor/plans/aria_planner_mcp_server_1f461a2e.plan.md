---
name: Aria Planner MCP Server
overview: Create an MCP server for aria-planner that provides planning capabilities via node-based domain definitions, integrating directly with aria-planner/aria-math libraries and exposing validate and solve tools.
todos:
  - id: setup_project
    content: Initialize Elixir project with mix.exs, dependencies (ex_mcp, jason, plug_cowboy, briefly, aria-planner, aria-math), and basic directory structure
    status: completed
  - id: application_supervisor
    content: Create Application supervisor with transport selection (HTTP/STDIO) matching mcp-minizinc pattern
    status: completed
  - id: node_domain_parser
    content: Implement node-based domain parser that converts JSON/YAML node definitions to aria-planner domain format
    status: completed
  - id: state_converter
    content: Create converters between node-based format and aria-math AEV format for state representation
    status: completed
  - id: planner_wrapper
    content: Create Planner module that wraps aria-planner APIs and implements trajectory generation, ranking, and judgment logic
    status: completed
  - id: validate_tool
    content: Implement aria_planner_validate MCP tool that validates domain and problem definitions
    status: completed
  - id: solve_tool
    content: Implement aria_planner_solve MCP tool that solves planning problems using trajectory/rank/judge pattern
    status: completed
  - id: stdio_transport
    content: Create STDIO server transport wrapper for MCP protocol
    status: completed
  - id: http_transport
    content: Create HTTP server transport with routing and health check endpoint
    status: completed
  - id: testing
    content: Add unit tests for domain parser, integration tests for MCP tools, and end-to-end planning scenario tests
    status: completed
  - id: documentation
    content: Create README with usage examples, node-based domain language specification, and API documentation
    status: completed
  - id: deployment
    content: Add Dockerfile, smithery.yaml configuration, and release setup for deployment
    status: completed
---

# Aria Planner MCP Server Implementation Plan

## Overview

Create an MCP server similar to `mcp-minizinc` that provides planning capabilities for aria-planner. The server will use a node-based language (exactly glTF interactivity) for domain definitions, integrate directly with aria-planner/aria-math as Elixir dependencies, and expose `validate` and `solve` tools.

## Architecture

### Core Components

1. **MCP Server Structure** (mirroring mcp-minizinc):

   - `AriaPlannerMcp.Application` - Supervisor and transport selection (HTTP/STDIO)
   - `AriaPlannerMcp.NativeService` - Main MCP service using ex_mcp
   - `AriaPlannerMcp.StdioServer` - STDIO transport wrapper
   - `AriaPlannerMcp.HttpServer` - HTTP transport wrapper
   - `AriaPlannerMcp.Router` - HTTP routing with health check
   - `AriaPlannerMcp.Planner` - Core planning logic wrapper

2. **Domain Definition**:

   - Node-based language parser/interpreter
   - Domain state representation (using aria-math AEV format internally)
   - Problem definition structure

3. **Planning Tools**:

   - `aria_planner_validate` - Validate domain and problem definitions
   - `aria_planner_solve` - Solve planning problems (internally uses trajectory creation, ranking, and judgment)

## Implementation Steps

### Phase 0: Prerequisites

1. **Fetch KHR_interactivity Reference**

   - **Critical**: Must maintain 100% compatibility with glTF KHR_interactivity specification
   - Provides reference implementation and specification for node-based language design

### Phase 1: Project Setup

1. **Initialize Elixir Project**

   - Create `mix.exs` with dependencies:
     - Core: `ex_mcp`, `jason`, `plug_cowboy`, `briefly`
     - Aria ecosystem: `aria_planner`, `aria_math`, `aria_gltf` (all as git dependencies)
   - Set up project structure matching mcp-minizinc

2. **Application Structure**

   - Create `lib/aria_planner_mcp/` directory structure
   - Set up `application.ex` with supervisor and transport selection
   - Configure environment-based transport (HTTP/STDIO)

### Phase 2: Node-Based Domain Language

1. **Domain Parser**

   - Define node-based schema (nodes, edges, properties)
   - Create parser for JSON/YAML domain definitions
   - Map node-based definitions to aria-planner domain format

2. **State Representation**

   - Integrate aria-math AEV format for state
   - Create converters between node-based and AEV formats

### Phase 3: MCP Tools Implementation

1. **Validate Tool** (`aria_planner_validate`)

   - Accept domain definition (node-based format)
   - Accept problem definition (initial state, goals)
   - Validate syntax and semantics
   - Return validation results with errors/warnings

2. **Solve Tool** (`aria_planner_solve`)

   - Accept domain and problem definitions
   - Generate multiple solution trajectories (internal)
   - Rank trajectories by criteria
   - Judge and select best solution
   - Return solution plan

### Phase 4: Integration & Testing

1. **Aria-Planner Integration**

   - Wrap aria-planner APIs for domain solving
   - Integrate aria-math for state operations
   - Handle errors and edge cases

2. **Testing**

   - Unit tests for domain parser
   - Integration tests for MCP tools
   - End-to-end tests for planning scenarios

### Phase 5: Documentation & Deployment

1. **Documentation**

   - README with usage examples
   - Node-based domain language specification
   - API documentation

2. **Deployment**

   - Dockerfile (similar to mcp-minizinc)
   - Smithery configuration
   - Release configuration

## Key Files to Create

- `mix.exs` - Project configuration
- `lib/aria_planner_mcp/application.ex` - Application supervisor
- `lib/aria_planner_mcp/native_service.ex` - MCP service with tools
- `lib/aria_planner_mcp/planner.ex` - Planning logic wrapper
- `lib/aria_planner_mcp/domain_parser.ex` - Node-based domain parser
- `lib/aria_planner_mcp/stdio_server.ex` - STDIO transport
- `lib/aria_planner_mcp/http_server.ex` - HTTP transport
- `lib/aria_planner_mcp/router.ex` - HTTP routing
- `lib/mix/tasks/mcp.server.ex` - Mix task for running server
- `Dockerfile` - Container configuration
- `smithery.yaml` - Smithery deployment config
- `README.md` - Documentation

## Dependencies

- `ex_mcp` - MCP protocol implementation
- `jason` - JSON encoding/decoding
- `plug_cowboy` - HTTP server
- `briefly` - Temporary file handling
- `aria_planner` - Planning engine (git dependency)
- `aria_math` - Math/state operations (git dependency)

## Node-Based Domain Format (Initial Design)

The node-based format will map to aria-planner's domain structure (entities, tasks, actions, commands, multigoals). The format should align with glTF KHR_interactivity node-based patterns while converting to aria-planner's internal representation.

Example structure (to be refined based on KHR_interactivity reference):

```json
{
  "nodes": [
    {
      "id": "entity_1",
      "type": "entity",
      "properties": {...}
    },
    {
      "id": "action_1",
      "type": "action",
      "name": "a_cross_east",
      "arity": 3,
      "properties": {...}
    },
    {
      "id": "task_1",
      "type": "task",
      "name": "transport_all",
      "properties": {...}
    }
  ],
  "edges": [
    {
      "from": "entity_1",
      "to": "action_1",
      "properties": {...}
    }
  ]
}
```

Note: The actual mapping from node-based format to aria-planner's internal structure will be handled by the domain parser, not exposed in the node-based format itself.

## Notes

- Domain definitions use node-based format externally but convert to aria-planner's internal format
- State uses aria-math AEV format for consistency with aria-planner ecosystem