# Docker Claude Agents

A repeatable, Docker-based multi-agent system powered by [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Run a team of 6 autonomous Claude agents (1 master controller + 5 specialists) that collaborate on software engineering tasks.

## Architecture

```
                    +---------------------+
                    |  Master Controller  |
                    |   (Orchestrator)    |
                    +----------+----------+
                               |
          +--------------------+--------------------+
          |          |         |         |          |
    +-----+----+ +--+---+ +---+----+ +--+---+ +----+-----+
    |Researcher| | Coder| |Reviewer| |Tester| | Deployer |
    +----------+ +------+ +--------+ +------+ +----------+
          |          |         |         |          |
          +----------+---------+---------+----------+
                               |
                    +----------+----------+
                    |   Shared Volumes    |
                    |  tasks/status/output |
                    +---------------------+
```

**Agent Roles:**

| Agent | Role |
|-------|------|
| **Master Controller** | Decomposes tasks, delegates to workers, aggregates results |
| **Researcher** | Gathers information, analyzes code, writes documentation |
| **Coder** | Implements features, fixes bugs, refactors code |
| **Reviewer** | Code review, security audits, best practice enforcement |
| **Tester** | Writes and runs tests, validates functionality |
| **Deployer** | CI/CD, Docker configs, deployment automation |

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/YOUR_USERNAME/docker-claude-agents.git
cd docker-claude-agents
cp .env.example .env
# Edit .env and add your ANTHROPIC_API_KEY
```

### 2. Run a Single Agent (Chat Mode)

```bash
# Interactive session
./scripts/start-chat.sh

# One-off autonomous task
./scripts/run-single-task.sh "Refactor all files to use async/await"
```

### 3. Run the Full 6-Agent System

```bash
# Submit a task to the master controller
./scripts/submit-task.sh "Build a REST API with Express.js and PostgreSQL"

# Or launch all agents directly
./scripts/start-all.sh
```

### 4. Run in Cowork Mode (Pair Programming)

```bash
./scripts/start-cowork.sh
```

### 5. Run with MCP Services (GitHub, Search, Database)

```bash
# Set GITHUB_TOKEN and BRAVE_API_KEY in .env first
./scripts/start-with-mcp.sh
```

## Project Structure

```
docker-claude-agents/
├── README.md
├── .env.example              # Environment variable template
├── .gitignore
├── Dockerfile.base           # Base image for single-agent use
├── docker-compose.yml        # Full 6-agent orchestration
├── docker-compose.chat.yml   # Interactive single-agent mode
├── docker-compose.cowork.yml # Lead + Reviewer pair mode
├── docker-compose.mcp.yml    # MCP services overlay
├── mcp-config.json           # MCP server configuration
├── agents/
│   ├── master-controller/    # Orchestrator agent
│   │   ├── Dockerfile
│   │   ├── CLAUDE.md
│   │   └── system-prompt.md
│   ├── researcher/           # Research & analysis agent
│   │   ├── Dockerfile
│   │   ├── CLAUDE.md
│   │   └── system-prompt.md
│   ├── coder/                # Implementation agent
│   │   ├── Dockerfile
│   │   ├── CLAUDE.md
│   │   └── system-prompt.md
│   ├── reviewer/             # Code review agent
│   │   ├── Dockerfile
│   │   ├── CLAUDE.md
│   │   └── system-prompt.md
│   ├── tester/               # Testing agent
│   │   ├── Dockerfile
│   │   ├── CLAUDE.md
│   │   └── system-prompt.md
│   └── deployer/             # Deployment agent
│       ├── Dockerfile
│       ├── CLAUDE.md
│       └── system-prompt.md
├── scripts/
│   ├── start-all.sh          # Launch all 6 agents
│   ├── start-chat.sh         # Interactive single agent
│   ├── start-cowork.sh       # Pair programming mode
│   ├── start-with-mcp.sh     # Agents + MCP services
│   ├── run-single-task.sh    # One-off autonomous task
│   ├── submit-task.sh        # Submit task to master
│   └── cleanup.sh            # Stop everything, remove volumes
├── examples/
│   ├── task-refactor.json    # Example: code refactoring task
│   ├── task-api-build.json   # Example: build an API task
│   └── task-security-audit.json # Example: security audit task
├── workspace/                # Shared codebase (mount your code here)
└── docs/
    └── ARCHITECTURE.md       # Detailed architecture docs
```

## Running Modes

### Chat Mode (Interactive)

Run a single Claude agent interactively for ad-hoc tasks:

```bash
docker compose -f docker-compose.chat.yml run --rm claude-chat
```

### Single Task (Autonomous)

Run a one-off task without interaction:

```bash
docker run -it \
  -e ANTHROPIC_API_KEY="your_api_key_here" \
  -v ~/.claude:/home/node/.claude \
  -v $(pwd)/workspace:/app \
  custom-claude-agent --dangerously-skip-permissions \
  "Refactor the files in this directory to use async/await"
```

Without a mounted volume (ephemeral):

```bash
docker run -e ANTHROPIC_API_KEY="your_key" custom-claude-agent \
  sh -c "yes | claude --dangerously-skip-permissions"
```

### Full Team (6 Agents)

Launch all agents to collaborate on complex tasks:

```bash
docker compose up --build
```

Or run a specific one-off command:

```bash
docker compose run --rm coder --dangerously-skip-permissions "your prompt here"
```

### Cowork Mode (Pair Programming)

Two agents collaborate: one implements, one reviews:

```bash
docker compose -f docker-compose.cowork.yml up --build
```

### With MCP Services

Add GitHub, Brave Search, Filesystem, and PostgreSQL MCP servers:

```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml up --build
```

## Agent Communication

Agents communicate through shared Docker volumes:

| Volume | Purpose |
|--------|---------|
| `shared-tasks` | Task assignment files (JSON) |
| `shared-status` | Agent status updates |
| `shared-output` | Results and deliverables |

### Task File Format

```json
{
  "task_id": "unique-id",
  "priority": "high",
  "description": "What needs to be done",
  "context": "Background information",
  "expected_output": "What the result should look like",
  "dependencies": ["other-task-id"]
}
```

### Status File Format

```json
{
  "agent": "coder",
  "status": "working",
  "current_task": "task-123",
  "timestamp": "2026-02-27T10:00:00Z"
}
```

## Network Access

Docker containers use bridge networking by default, allowing agents to reach the Anthropic API.

**For host machine services:**
- **Linux:** `--network="host"`
- **Mac/Windows:** Use `host.docker.internal` to reference host services

```bash
docker run --network="host" \
  -e ANTHROPIC_API_KEY="your_key" \
  custom-claude-agent --dangerously-skip-permissions "your prompt"
```

## MCP Server Integration

Connect agents to external tools via MCP (Model Context Protocol):

| MCP Server | Purpose |
|------------|---------|
| GitHub | Repository access, issues, PRs |
| Filesystem | Structured file operations |
| Brave Search | Web search capabilities |
| PostgreSQL | Database queries and management |

Add custom MCP servers in `docker-compose.mcp.yml`:

```yaml
mcp-custom:
  image: mcp/your-server:latest
  environment:
    - YOUR_API_KEY=${YOUR_API_KEY}
  networks:
    - agent-net
```

Browse available MCP servers: [https://code.claude.com/docs/en/mcp](https://code.claude.com/docs/en/mcp)

## Key Implementation Details

- **Authentication Persistence**: Mounting `.claude` to `/home/node/.claude` keeps agents logged in across container restarts
- **Unattended Operation**: `--dangerously-skip-permissions` is required for autonomous operation; without it, containers hang waiting for user confirmation
- **Service Discovery**: Agents communicate with MCP servers using Docker service names on the shared `agent-net` bridge network
- **All agents run autonomously** with no human-in-the-loop by default

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Your Anthropic API key |
| `GITHUB_TOKEN` | No | GitHub PAT (for GitHub MCP) |
| `BRAVE_API_KEY` | No | Brave Search API key |

## Cleanup

```bash
# Stop all agents and remove volumes
./scripts/cleanup.sh

# Or manually
docker compose down --remove-orphans
docker volume prune
```

## License

MIT
