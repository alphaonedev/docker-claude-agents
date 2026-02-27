# Docker Claude Agents

A production-grade, Docker-based reference architecture for running autonomous AI agent teams across three frameworks: [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (6 agents), [LangGraph](https://www.langchain.com/langgraph) (graph-based orchestration), and [Microsoft Agent Framework](https://learn.microsoft.com/en-us/semantic-kernel/) (Semantic Kernel + AutoGen). All containers are CIS Docker Benchmark hardened with `cap_drop: ALL`, `no-new-privileges`, `read_only` rootfs, and resource limits.

## Architecture

```
                         ┌─────────────────────┐
                         │  Master Controller   │
                         │    (orchestrator)    │
                         └──────────┬──────────┘
                                    │ decomposes & delegates
            ┌───────────┬───────────┼───────────┬───────────┐
            │           │           │           │           │
       ┌────▼───┐  ┌────▼───┐  ┌───▼────┐  ┌───▼──┐  ┌────▼────┐
       │Research│  │ Coder  │  │Reviewer│  │Tester│  │Deployer │
       └────┬───┘  └────┬───┘  └───┬────┘  └───┬──┘  └────┬────┘
            │           │          │            │           │
            └───────────┴──────────┴────────────┴───────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │   Shared Docker Volumes      │
                    │  tasks/ · status/ · output/  │
                    └──────────────────────────────┘
```

| Agent | Role |
|-------|------|
| **Master Controller** | Decomposes incoming tasks, delegates to specialists, monitors progress, aggregates results |
| **Researcher** | Codebase analysis, architecture mapping, documentation, technical findings |
| **Coder** | Feature implementation, bug fixes, refactoring, code generation |
| **Reviewer** | Code review, OWASP security audit, best-practice enforcement |
| **Tester** | Test authoring, test execution, coverage analysis, regression detection |
| **Deployer** | Dockerfiles, CI/CD pipelines, deployment scripts, infrastructure config |

## Prerequisites

- Docker Engine >= 24.0
- Docker Compose >= 2.20
- An [Anthropic API key](https://console.anthropic.com/settings/keys)

## Quick Start

```bash
# 1. Clone
git clone https://github.com/alphaonedev/docker-claude-agents.git
cd docker-claude-agents

# 2. Configure
make setup                         # creates .env from template
# Edit .env → set ANTHROPIC_API_KEY

# 3. Build & Run
make build                         # builds base + agent images
make team                          # full 6-agent system
# — or —
make chat                          # single interactive agent
make run PROMPT="Refactor to async/await"  # one-shot autonomous task
```

## Running Modes

| Mode | Command | Description |
|------|---------|-------------|
| **Full Team** | `make team` | All 6 Claude agents collaborating on a complex task |
| **Chat** | `make chat` | Single interactive agent for ad-hoc work |
| **Single Task** | `make run PROMPT="..."` | One-off autonomous task, no interaction |
| **Submit Task** | `make task PROMPT="..."` | Submit to master controller for team decomposition |
| **Cowork** | `make cowork` | Lead + reviewer pair programming |
| **With MCP** | `make mcp` | Full team + GitHub, Search, DB tool servers |
| **LangGraph** | `make langgraph` | Claude agents + LangGraph graph-based orchestration |
| **MS Agent** | `make msagent` | Claude agents + Microsoft Agent Framework (SK + AutoGen) |
| **Platform** | `make platform` | All 3 frameworks (Claude + LangGraph + MS Agent) |
| **Full** | `make full` | All frameworks + MCP tool servers |

### Direct Docker usage

```bash
# Interactive single agent
docker compose -f docker-compose.chat.yml run --rm claude-chat

# Full Claude team
docker compose up --build

# Claude + LangGraph
docker compose -f docker-compose.yml -f docker-compose.langgraph.yml up --build

# Claude + Microsoft Agent Framework
docker compose -f docker-compose.yml -f docker-compose.msagent.yml up --build

# All 3 frameworks + MCP
docker compose -f docker-compose.yml -f docker-compose.langgraph.yml \
  -f docker-compose.msagent.yml -f docker-compose.mcp.yml up --build
```

## Project Structure

```
docker-claude-agents/
├── Makefile                     # All common operations
├── Dockerfile.base              # Base image (all agents extend this)
├── docker-compose.yml           # Full 6-agent orchestration
├── docker-compose.chat.yml      # Interactive single-agent mode
├── docker-compose.cowork.yml    # Lead + reviewer pair mode
├── docker-compose.mcp.yml       # MCP services overlay
├── docker-compose.langgraph.yml # LangGraph Deep Agents overlay
├── docker-compose.msagent.yml   # Microsoft Agent Framework overlay
├── .env.example                 # Environment variable template
├── .dockerignore                # Docker build exclusions
├── mcp-config.json              # MCP server configuration
│
├── frameworks/                  # Multi-framework agent runtimes
│   ├── langgraph/
│   │   ├── langgraph.json       # LangGraph configuration
│   │   ├── graph.py             # Reference graph definition
│   │   └── requirements.txt     # Python dependencies
│   └── msagent/
│       ├── Dockerfile           # MS Agent Framework image
│       ├── requirements.txt     # Python dependencies
│       └── msagent/             # Framework runtime code
│           ├── __init__.py
│           └── server.py        # HTTP + gRPC server
│
├── agents/                      # One directory per Claude agent role
│   ├── master-controller/
│   │   ├── Dockerfile           # Thin layer (4 lines, extends base)
│   │   ├── system-prompt.md     # Role + protocol (~35 lines)
│   │   └── CLAUDE.md            # Claude Code project instructions
│   ├── researcher/
│   ├── coder/
│   ├── reviewer/
│   ├── tester/
│   └── deployer/
│
├── schemas/                     # JSON Schema contracts
│   ├── task.schema.json         # Task file format
│   ├── status.schema.json       # Status file format
│   └── output.schema.json       # Output manifest format
│
├── scripts/                     # Operational scripts
│   ├── lib.sh                   # Shared functions (validation, logging)
│   ├── start-all.sh             # Launch full team
│   ├── start-chat.sh            # Interactive mode
│   ├── start-cowork.sh          # Pair programming
│   ├── start-with-mcp.sh        # Team + MCP services
│   ├── run-single-task.sh       # One-off task
│   ├── submit-task.sh           # Submit to master controller
│   └── cleanup.sh               # Stop + cleanup
│
├── examples/                    # Example task files
│   ├── task-refactor.json
│   ├── task-api-build.json
│   └── task-security-audit.json
│
├── docs/
│   ├── ARCHITECTURE.md          # System design deep-dive
│   ├── SECURITY.md              # Security model + CIS controls
│   └── TROUBLESHOOTING.md       # Common issues and fixes
│
├── VERSION                      # Semantic version
├── CHANGELOG.md                 # Release history
├── CONTRIBUTING.md              # Contributor guide
├── CODE_OF_CONDUCT.md           # Community standards
│
└── workspace/                   # Mount your code here
```

## Agent Communication Protocol

Agents communicate exclusively through files on three shared Docker volumes:

| Volume | Purpose | Writer | Reader |
|--------|---------|--------|--------|
| `shared-tasks` | Task assignment queue | Master | Workers |
| `shared-status` | Agent progress tracking | Each agent (own status) | Master |
| `shared-output` | Results and deliverables | Workers | Master |

Each volume contains per-agent subdirectories: `master/`, `researcher/`, `coder/`, `reviewer/`, `tester/`, `deployer/`.

### Contracts

All JSON files conform to schemas in `schemas/`:

**Task** (`schemas/task.schema.json`):
```json
{
  "task_id": "task-coder-001",
  "description": "Implement JWT authentication middleware",
  "priority": "high",
  "dependencies": [],
  "timeout_minutes": 30
}
```

**Status** (`schemas/status.schema.json`):
```json
{
  "agent": "coder",
  "status": "working",
  "current_task": "task-coder-001",
  "progress_pct": 60,
  "timestamp": "2026-02-27T14:30:00Z"
}
```

**Output manifest** (`schemas/output.schema.json`):
```json
{
  "task_id": "task-coder-001",
  "agent": "coder",
  "status": "success",
  "summary": "Implemented JWT middleware with token validation",
  "artifacts": [{"path": "task-coder-001.md", "type": "code"}],
  "metrics": {"files_created": 1, "files_modified": 2}
}
```

## Network Access

All containers share an isolated `agent-net` bridge network with outbound access for the Anthropic API.

**Accessing host services:**
- **Linux:** `--network="host"`
- **Mac/Windows:** Use `host.docker.internal` as hostname

## MCP Server Integration

The `docker-compose.mcp.yml` overlay adds [Model Context Protocol](https://modelcontextprotocol.io/) tool servers:

| Server | Purpose | Required env var |
|--------|---------|------------------|
| GitHub | Repos, issues, PRs | `GITHUB_TOKEN` |
| Filesystem | Structured file I/O | — |
| Brave Search | Web search | `BRAVE_API_KEY` |
| PostgreSQL | Database access | `POSTGRES_PASSWORD` |

Add custom MCP servers by extending `docker-compose.mcp.yml`.

## LangGraph Deep Agents

The `docker-compose.langgraph.yml` overlay adds [LangGraph](https://www.langchain.com/langgraph) graph-based agent orchestration:

| Service | Purpose | Image |
|---------|---------|-------|
| **langgraph-api** | Graph execution runtime, REST + streaming | `langchain/langgraph-api` |
| **langgraph-postgres** | State checkpointing + pgvector embeddings | `pgvector/pgvector:pg16` |
| **langgraph-redis** | Real-time state streaming, pub/sub | `redis:7-alpine` |

Features: state graph workflows, conditional routing, checkpoint/resume/replay, human-in-the-loop breakpoints, multi-agent topologies (supervisor, handoff, hierarchical teams), LangSmith tracing.

## Microsoft Agent Framework

The `docker-compose.msagent.yml` overlay adds [Microsoft Agent Framework](https://learn.microsoft.com/en-us/semantic-kernel/) (Semantic Kernel + AutoGen):

| Service | Purpose | Image |
|---------|---------|-------|
| **msagent-runtime** | Semantic Kernel + AutoGen agent runtime | Custom (Dockerfile) |
| **msagent-memory** | Kernel Memory RAG pipeline + vector store | `kernelmemory/service` |
| **msagent-code-executor** | Sandboxed code execution | `python:3.12-slim` |

Features: gRPC distributed runtime, plugin architecture (native + OpenAPI + MCP), multi-model support (Azure OpenAI, Anthropic, Ollama), actor-model multi-agent conversations, Docker code executor.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `ANTHROPIC_API_KEY` | Yes | — | Anthropic API key |
| `CLAUDE_CODE_VERSION` | No | `latest` | Pin Claude Code CLI version |
| `GITHUB_TOKEN` | MCP only | — | GitHub Personal Access Token |
| `BRAVE_API_KEY` | MCP only | — | Brave Search API key |
| `POSTGRES_USER` | MCP only | `claude_agent` | Database user |
| `POSTGRES_PASSWORD` | MCP only | — | Database password |
| `POSTGRES_DB` | MCP only | `agentdb` | Database name |
| `OPENAI_API_KEY` | LangGraph | — | OpenAI API key |
| `LANGCHAIN_API_KEY` | LangGraph (optional) | — | LangSmith tracing key |
| `LANGGRAPH_POSTGRES_PASSWORD` | LangGraph | `langgraph_secret` | LangGraph DB password |
| `AZURE_OPENAI_ENDPOINT` | MS Agent | — | Azure OpenAI endpoint |
| `AZURE_OPENAI_API_KEY` | MS Agent | — | Azure OpenAI key |
| `AZURE_OPENAI_DEPLOYMENT` | MS Agent | `gpt-4o` | Azure OpenAI deployment |

## Key Design Decisions

- **File-based IPC** — Agents communicate via JSON files on shared volumes, not network calls. This is simple, debuggable, and requires no additional infrastructure.
- **Autonomous execution** — All agents run with `--dangerously-skip-permissions` for fully unattended operation.
- **Auth persistence** — `.claude/` is mounted read-only to avoid re-authentication across restarts.
- **Single base image** — All 6 agents extend `claude-agent-base` via thin 4-line Dockerfiles (no duplication).
- **CIS Docker Benchmark** — `cap_drop: ALL`, `no-new-privileges`, `read_only` rootfs, `pids_limit`, `tini` as PID 1.
- **YAML anchors** — `docker-compose.yml` uses `x-agent-defaults` to eliminate repetition across 6 services.
- **Resource limits** — Every service has CPU/memory limits and log rotation to prevent resource exhaustion.
- **Init service** — A lightweight Alpine container creates the directory structure on shared volumes before agents start.

## Customization

### Adding a new agent

1. Create `agents/your-agent/{Dockerfile,system-prompt.md,CLAUDE.md}` (Dockerfile: 4 lines extending `claude-agent-base`)
2. Add the service to `docker-compose.yml` (copy an existing agent block)
3. Add the agent name to the `task-init` service's directory loop
4. Update the master controller's system prompt to know about the new agent

### Modifying agent behavior

Each agent's behavior is defined by two files:
- `system-prompt.md` — Detailed role, workflow, error handling, constraints
- `CLAUDE.md` — Concise project-level instructions loaded by Claude Code

## Monitoring

```bash
make logs      # tail all agent logs
make status    # container status table
make health    # health check summary
```

## Cleanup

```bash
make stop      # stop containers (keep volumes + images)
make clean     # stop + remove volumes
make purge     # stop + remove volumes + images
```

## Further Reading

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System design, volume layout, communication protocol
- [docs/SECURITY.md](docs/SECURITY.md) — Security model, secret management, threat considerations
- [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) — Common issues and solutions

## License

MIT
