---
layout: default
title: Home
---

# Docker Multi-Framework AI Agent Orchestration Platform

Production-grade Docker orchestration unifying **Claude Code**, **LangGraph**, and **Microsoft Agent Framework** — all CIS Docker Benchmark hardened.

---

## Three Frameworks, One Platform

| Framework | Agents | Communication | Compose File |
|-----------|--------|---------------|-------------|
| **Claude Code** | 6 (Master + 5 specialists) | File-based IPC (JSON on shared volumes) | `docker-compose.yml` |
| **LangGraph** | Graph-based (supervisor, handoff, teams) | State checkpoints (PostgreSQL) + Redis pub/sub | `docker-compose.langgraph.yml` |
| **Microsoft Agent Framework** | Semantic Kernel + AutoGen agents | gRPC distributed runtime | `docker-compose.msagent.yml` |

## Quick Start

```bash
git clone https://github.com/alphaonedev/docker-claude-agents.git
cd docker-claude-agents
make setup       # creates .env from template
make build       # builds base + agent images
make team        # full 6-agent Claude team
# — or —
make platform    # all 3 frameworks
make full        # all frameworks + MCP tool servers
```

## Running Modes

| Mode | Command | Description |
|------|---------|-------------|
| Chat | `make chat` | Single interactive agent |
| Cowork | `make cowork` | Lead + reviewer pair |
| Team | `make team` | Full 6-agent Claude team |
| LangGraph | `make langgraph` | Claude + LangGraph stack |
| MS Agent | `make msagent` | Claude + Microsoft Agent Framework |
| Platform | `make platform` | All 3 frameworks |
| Full | `make full` | All frameworks + MCP tools |

## CIS Docker Benchmark Compliance

Every container enforces:

| Control | Setting | CIS Ref |
|---------|---------|---------|
| Capabilities | `cap_drop: [ALL]` | 5.3 |
| Privilege escalation | `no-new-privileges:true` | 5.25 |
| Root filesystem | `read_only: true` | 5.12 |
| PID limits | `pids_limit: 256` | 5.28 |
| Init process | `tini` as PID 1 | 5.29 |
| Resource limits | CPU/memory via `deploy.resources` | 5.10/5.11 |
| Log rotation | `json-file` with `max-size`/`max-file` | 5.7 |
| Non-root user | `USER node` | 5.15 |

## Documentation

- [Architecture](ARCHITECTURE.md) — System design, volume layout, communication protocol
- [Security](SECURITY.md) — Security model, CIS controls, secret management
- [Troubleshooting](TROUBLESHOOTING.md) — Common issues and solutions

## Reference Architecture

[**View the interactive architecture visualization →**](architecture-visual.html)

Agent orchestration, network topology, image layering, compose strategy, and CIS compliance — all in one visual reference.

## License

MIT — Copyright 2026 AlphaOne LLC
