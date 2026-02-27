# Architecture

## System Overview

The Docker Claude Agents system runs 6 containerized Claude Code agents that collaborate on software engineering tasks. The architecture is designed around three principles:

1. **Isolation** — Each agent runs in its own container with defined resource limits.
2. **Simplicity** — Agents communicate through JSON files on shared volumes (no message broker, no database).
3. **Observability** — Structured status files, log rotation, and health checks enable monitoring.

## Agent Lifecycle

```
┌──────────┐     ┌─────────┐     ┌──────────┐     ┌───────────┐     ┌──────────┐
│  Start   │────▶│  Read   │────▶│  Update  │────▶│  Execute  │────▶│  Write   │
│          │     │  Tasks  │     │  Status  │     │   Task    │     │  Output  │
└──────────┘     └─────────┘     │ "working"│     └───────────┘     └──────┬───┘
                                 └──────────┘                              │
                                                                    ┌──────▼───┐
                                                                    │  Update  │
                                                                    │  Status  │
                                                                    │"completed"│
                                                                    └──────────┘
```

Every agent — master and workers alike — follows this lifecycle:

1. **Start** — Container launches, Claude Code initializes.
2. **Read tasks** — Agent reads `.json` files from its task directory.
3. **Update status** — Writes `{"status": "working"}` to its status file.
4. **Execute** — Performs its specialized work.
5. **Write output** — Produces deliverables + an output manifest.
6. **Update status** — Writes `{"status": "completed"}`.

If no tasks are found, the agent writes `{"status": "idle"}` and exits.

## Volume Architecture

```
Bind Mount (workspace/.tasks/)
─────────────────────────────────────────────────────────────
workspace/.tasks/
└── incoming.json                ← User-submitted task (via submit-task.sh)

Docker Named Volumes
─────────────────────────────────────────────────────────────
shared-tasks/                    ← Inter-agent task delegation
├── researcher/
│   └── task-research-001.json   ← Subtask from master
├── coder/
│   └── task-coder-001.json
├── reviewer/
│   └── task-reviewer-001.json
├── tester/
│   └── task-tester-001.json
└── deployer/
    └── task-deployer-001.json

shared-status/                   ← Real-time agent status
├── init.json                    ← Written by task-init service
├── master/
│   ├── current.json             ← Master's current status
│   └── plan.json                ← Execution plan
├── researcher/
│   └── current.json
├── coder/
│   └── current.json
├── reviewer/
│   └── current.json
├── tester/
│   └── current.json
└── deployer/
    └── current.json

shared-output/                   ← Results and deliverables
├── master/
│   └── result.md                ← Final aggregated report
├── researcher/
│   ├── task-research-001.md          ← Findings report
│   └── task-research-001.manifest.json
├── coder/
│   ├── task-coder-001.md
│   └── task-coder-001.manifest.json
├── reviewer/
│   ├── task-reviewer-001.md
│   └── task-reviewer-001.manifest.json
├── tester/
│   ├── task-tester-001.md
│   └── task-tester-001.manifest.json
└── deployer/
    ├── task-deployer-001.md
    └── task-deployer-001.manifest.json
```

### Bind Mounts

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./workspace` | `/app/workspace` | Shared codebase (read/write for workers) |
| `./.claude` | `/home/node/.claude` | Auth persistence (read-only) |

## Network Topology

```
                    ┌─────────────────────────────────────┐
                    │          agent-net (bridge)          │
                    │                                     │
                    │  ┌────────┐  ┌────────┐  ┌──────┐  │
                    │  │ master │  │ coder  │  │ ...  │  │
                    │  └───┬────┘  └───┬────┘  └──┬───┘  │
                    │      │           │          │      │
                    │  ┌───▼───────────▼──────────▼───┐  │
                    │  │     Docker DNS resolution     │  │
                    │  └──────────────┬────────────────┘  │
                    │                 │                    │
                    │  ┌──────────────▼────────────────┐  │
                    │  │  MCP servers (when enabled)   │  │
                    │  │  mcp-github, mcp-postgres...  │  │
                    │  └──────────────────────────────┘  │
                    │                                     │
                    └──────────────────┬──────────────────┘
                                       │ outbound
                                       ▼
                              Anthropic API
                              api.anthropic.com
```

All services share the `agent-net` bridge network. Docker's built-in DNS allows agents to resolve MCP service names (e.g., `mcp-github`, `db-service`).

## Compose File Strategy

| File | Scope | Usage |
|------|-------|-------|
| `docker-compose.yml` | Core 6-agent system | `docker compose up` |
| `docker-compose.chat.yml` | Single interactive agent | `docker compose -f docker-compose.chat.yml run --rm claude-chat` |
| `docker-compose.cowork.yml` | Lead + reviewer pair | `docker compose -f docker-compose.cowork.yml up` |
| `docker-compose.mcp.yml` | MCP overlay (extends core) | `docker compose -f docker-compose.yml -f docker-compose.mcp.yml up` |

The core `docker-compose.yml` uses YAML anchors (`x-agent-defaults`, `x-agent-environment`, `x-agent-volumes`) to define shared configuration once and reference it across all 6 agent services. All compose files include CIS Docker Benchmark hardening (cap_drop, security_opt, read_only, pids_limit).

## Image Strategy

```
node:22-slim
    └── claude-agent-base (Dockerfile.base)    ← single source of truth
            ├── master-controller (4-line Dockerfile: FROM + COPY + ENV)
            ├── researcher
            ├── coder
            ├── reviewer
            ├── tester
            └── deployer
```

All agent Dockerfiles are thin layers (4 lines) that extend `claude-agent-base`. The base image contains all shared dependencies (Node.js, Claude Code CLI, tini, git, jq, curl). Agent images only add their `system-prompt.md` and `CLAUDE.md`.

## Init Service

The `task-init` service is a lightweight Alpine container that runs before any agent starts. It creates the directory structure on the shared volumes:

```
task-init → creates dirs → exits → agents start
```

All agent services use `depends_on: task-init: condition: service_completed_successfully` to ensure directories exist before agents attempt to read/write.

## Customization Guide

### Adding a new agent

1. Create the agent directory:
   ```
   agents/your-agent/
   ├── Dockerfile        # 4 lines: FROM claude-agent-base, LABEL, COPY, ENV
   ├── system-prompt.md  # Define role, workflow (~30 focused lines)
   └── CLAUDE.md         # Concise project instructions
   ```

2. Add to `docker-compose.yml`:
   ```yaml
   your-agent:
     <<: *agent-defaults
     build:
       context: ./agents/your-agent
       args:
         CLAUDE_CODE_VERSION: ${CLAUDE_CODE_VERSION:-latest}
     environment:
       <<: *agent-environment
       CLAUDE_AGENT_ROLE: your-agent
     volumes: *agent-volumes
     command:
       - "--dangerously-skip-permissions"
       - "--system-prompt"
       - "/app/system-prompt.md"
       - "Your agent's initial prompt here."
   ```

3. Add to the `task-init` command's agent list.

4. Update the master controller's `system-prompt.md` to include the new agent in its team table.

### Modifying resource limits

Override the YAML anchor defaults per-service:
```yaml
coder:
  <<: *agent-defaults
  deploy:
    resources:
      limits:
        cpus: "4"
        memory: 8G
```

### Adding custom MCP servers

Add to `docker-compose.mcp.yml`:
```yaml
mcp-your-tool:
  image: your-org/your-mcp-server:1.0.0
  environment:
    YOUR_API_KEY: ${YOUR_API_KEY}
  networks:
    - agent-net
  restart: on-failure:3
```

## Design Trade-offs

| Decision | Benefit | Limitation |
|----------|---------|------------|
| File-based IPC | Simple, debuggable, no infra deps | No real-time messaging; polling-based |
| All agents same image base | Consistent environment | Larger image size per agent |
| Single Docker host | Simple deployment | Not horizontally scalable |
| Named volumes | Persist across restarts | Must be explicitly cleaned up |
| `--dangerously-skip-permissions` | Fully autonomous | No guardrails on agent actions |
