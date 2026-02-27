# Architecture - Docker Claude Agents

## Overview

This system runs a team of 6 Claude Code agents inside Docker containers. Each agent has a specialized role and communicates with other agents through shared Docker volumes.

## Agent Design

### Master Controller

The master controller is the orchestration hub. When a task is submitted:

1. Reads the incoming task from `/app/tasks/master/incoming.json`
2. Decomposes it into subtasks appropriate for each specialist
3. Writes subtask files to `/app/tasks/{agent-name}/`
4. Monitors `/app/status/{agent-name}/current.json` for completion
5. Aggregates results from `/app/output/{agent-name}/`
6. Writes the final deliverable to `/app/output/master/`

### Worker Agents

Each worker agent follows the same lifecycle:

1. Check task directory for new task files
2. Read and parse the JSON task file
3. Execute the task (in workspace or analysis)
4. Write results to output directory
5. Update status file

### Communication Protocol

Agents do not communicate directly. Instead they use a file-based protocol on shared Docker volumes:

```
shared-tasks/          shared-status/         shared-output/
├── master/            ├── master/            ├── master/
│   └── incoming.json  │   └── plan.json      │   └── final.md
├── researcher/        ├── researcher/        ├── researcher/
│   └── task-001.json  │   └── current.json   │   └── findings.md
├── coder/             ├── coder/             ├── coder/
│   └── task-002.json  │   └── current.json   │   └── summary.md
├── reviewer/          ├── reviewer/          ├── reviewer/
│   └── task-003.json  │   └── current.json   │   └── review.md
├── tester/            ├── tester/            ├── tester/
│   └── task-004.json  │   └── current.json   │   └── report.json
└── deployer/          └── deployer/          └── deployer/
    └── task-005.json      └── current.json       └── config.md
```

## Docker Architecture

### Volumes

| Volume | Purpose | Access |
|--------|---------|--------|
| `shared-tasks` | Task assignment queue | Master writes, workers read |
| `shared-status` | Agent status tracking | All agents write their own status |
| `shared-output` | Results and deliverables | Workers write, master reads |
| `./workspace` | Shared codebase | All agents read/write |
| `./.claude` | Auth persistence | All agents (read) |

### Network

All agents share the `agent-net` bridge network for:
- MCP server communication (service name resolution)
- Database access
- External API access (Anthropic API)

### Init Service

The `task-init` service runs first to create the directory structure on shared volumes before any agent starts. This ensures all agents have their expected directories available.

## Compose File Organization

| File | Purpose |
|------|---------|
| `docker-compose.yml` | Core 6-agent system |
| `docker-compose.chat.yml` | Single interactive agent |
| `docker-compose.cowork.yml` | Lead + reviewer pair |
| `docker-compose.mcp.yml` | MCP service overlay (use with `-f` flag) |

## Customization

### Adding a New Agent

1. Create `agents/your-agent/Dockerfile` (copy from existing agent)
2. Create `agents/your-agent/system-prompt.md` with role description
3. Create `agents/your-agent/CLAUDE.md` with workflow instructions
4. Add the service to `docker-compose.yml`
5. Add the agent's directories to the `task-init` service

### Custom MCP Servers

Add entries to `docker-compose.mcp.yml`:

```yaml
mcp-your-tool:
  image: mcp/your-tool-server:latest
  environment:
    - YOUR_ENV_VAR=${YOUR_ENV_VAR}
  networks:
    - agent-net
```

### Modifying Agent Behavior

Each agent's behavior is controlled by two files:
- `system-prompt.md` - Detailed role description and protocols
- `CLAUDE.md` - Claude Code project instructions (loaded automatically)

Edit these files to change how agents operate.
