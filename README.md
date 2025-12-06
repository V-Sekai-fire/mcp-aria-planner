# Aria Planner MCP Server

A Model Context Protocol (MCP) server that provides planning capabilities for aria-planner using glTF KHR_interactivity node-based domain definitions.

## Features

- **100% glTF KHR_interactivity Compatible**: Uses exact glTF KHR_interactivity specification for node-based domain definitions
- **Validate Planning Domains**: Validate domain and problem definitions with detailed error reporting
- **Solve Planning Problems**: Solve planning problems using aria-planner
- **State Conversion**: Automatic conversion between node-based format and aria-math AEV format
- **JSON-RPC 2.0 Protocol**: Support via STDIO or HTTP transports
- **Server-Sent Events (SSE)**: Support for streaming responses

## Quick Start

### Prerequisites

- Elixir 1.18+
- aria-planner, aria-math, and aria-gltf dependencies (automatically fetched)

### Installation

```bash
git clone <repository-url>
cd mcp-aria-planner
mix deps.get
mix compile
```

## Usage

### STDIO Transport (Default)

For local development:

```bash
mix mcp.server
```

Or using release:

```bash
./_build/prod/rel/aria_planner_mcp/bin/aria_planner_mcp start
```

### HTTP Transport

For web deployments (e.g., Smithery):

```bash
PORT=8081 MIX_ENV=prod ./_build/prod/rel/aria_planner_mcp/bin/aria_planner_mcp start
```

**Endpoints:**

- `POST /` - JSON-RPC 2.0 MCP requests
- `GET /sse` - Server-Sent Events for streaming
- `GET /health` - Health check

### Docker

```bash
docker build -t aria-planner-mcp .
docker run -d -p 8081:8081 --name aria-planner-mcp aria-planner-mcp
```

## Tools

The server provides the following MCP tools:

### `aria_planner_validate`

Validate a planning domain and problem definition.

#### Parameters

- `domain_definition` (object, required): Domain definition as JSON object (glTF KHR_interactivity node-based format or aria format)
- `problem_definition` (object, required): Problem definition with `initial_state` and `goals`
- `options` (object, optional): Optional validation options

#### Response Format

Returns a JSON object with:
- `valid` (boolean): Whether the domain and problem are valid
- `errors` (array): List of error messages (if any)
- `warnings` (array): List of warning messages (if any)
- `message` (string): Human-readable message

#### Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "aria_planner_validate",
    "arguments": {
      "domain_definition": {
        "nodes": [
          {
            "id": "node1",
            "operation": "math/add"
          }
        ]
      },
      "problem_definition": {
        "initial_state": {
          "variables": {}
        },
        "goals": ["goal1"]
      }
    }
  }
}
```

### `aria_planner_solve`

Solve a planning problem using aria-planner.

#### Parameters

- `domain_definition` (object, required): Domain definition as JSON object (glTF KHR_interactivity node-based format or aria format)
- `problem_definition` (object, required): Problem definition with `initial_state` and `goals`
- `options` (object, optional): Optional solving options

#### Response Format

Returns a JSON object with:
- `domain` (object): Domain used for planning
- `initial_state` (object): Initial state
- `goals` (array): Goals to achieve
- `steps` (array): Solution steps (plan)
- `solved_at` (string): Timestamp when solution was generated

#### Example

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "aria_planner_solve",
    "arguments": {
      "domain_definition": {
        "nodes": [
          {
            "id": "action1",
            "operation": "action/move"
          }
        ]
      },
      "problem_definition": {
        "initial_state": {
          "variables": {
            "agent.position": [0, 0, 0]
          }
        },
        "goals": [
          {
            "type": "reach",
            "target": [10, 10, 0]
          }
        ]
      },
      "options": {}
    }
  }
}
```

## Domain Definition Format

The server accepts domain definitions in two formats:

### glTF KHR_interactivity Format (Node-Based)

100% compatible with glTF KHR_interactivity specification. Domains are defined as behavior graphs with nodes and connections.

```json
{
  "nodes": [
    {
      "id": "node1",
      "operation": "math/add",
      "inputValueSockets": {
        "a": 5,
        "b": 3
      },
      "outputValueSockets": {
        "value": 8
      }
    }
  ]
}
```

### Aria-Planner Format

Traditional aria-planner domain format with entities, tasks, actions, commands, and multigoals.

```json
{
  "type": "custom",
  "entities": [...],
  "tasks": [...],
  "actions": [...],
  "commands": [...],
  "multigoals": [...]
}
```

## State Format

States are automatically converted between formats:

- **Node-based format**: Uses `variables` and `nodeOutputs` maps
- **Aria format**: Uses `facts` structure with `facts[entity_id][predicate] = value`

## Configuration

**Environment Variables:**

- `MCP_TRANSPORT` - Transport type (`"http"` or `"stdio"`)
- `PORT` - HTTP server port (default: 8081)
- `HOST` - HTTP server host (default: `0.0.0.0` if PORT set, else `localhost`)
- `MIX_ENV` - Environment (`prod`, `dev`, `test`)
- `MCP_SSE_ENABLED` - Enable/disable Server-Sent Events (default: `true`, set to `"false"` to disable)

**Transport Selection:**

1. If `MCP_TRANSPORT` is set, use that transport
2. If `PORT` is set, use HTTP transport
3. Otherwise, use STDIO transport (default)

## Architecture

The server integrates with aria-planner to solve planning problems:

1. **Parse Domain**: Converts glTF KHR_interactivity format to aria-planner format if needed
2. **Convert State**: Converts initial state to aria-planner format
3. **Solve**: Calls aria-planner to generate a solution plan

## Testing

```bash
mix test
```

## Development

### Building

```bash
mix deps.get
mix compile
```

### Building Release

```bash
MIX_ENV=prod mix release
```

## Dependencies

- `ex_mcp` - MCP protocol implementation
- `jason` - JSON encoding/decoding
- `plug_cowboy` - HTTP server
- `briefly` - Temporary file handling
- `aria_planner` - Planning engine (git dependency)
- `aria_math` - Math/state operations (git dependency)
- `aria_gltf` - glTF processing (git dependency)

## License

MIT License - see LICENSE for details.

## Copyright

Copyright (c) 2025-present K. S. Ernest (iFire) Lee

