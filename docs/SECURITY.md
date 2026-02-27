# Security Considerations

This document covers the security model, threat surface, and best practices for the Docker Claude Agents system.

## Threat Model

### What this system does

- Runs autonomous AI agents with unrestricted filesystem and network access inside containers.
- Agents execute arbitrary code in the workspace via `--dangerously-skip-permissions`.
- Containers have outbound internet access (required for the Anthropic API).

### What this means

This system is designed for **development and research use**. The `--dangerously-skip-permissions` flag bypasses all confirmation prompts, which means agents can:
- Read, write, and delete any file in mounted volumes
- Install packages, run scripts, make network requests
- Modify the shared workspace in unexpected ways

**Do not run this system against production data or in production environments without additional safeguards.**

## Secret Management

### API keys

| Secret | Storage | Access |
|--------|---------|--------|
| `ANTHROPIC_API_KEY` | `.env` file | All agent containers (env var) |
| `GITHUB_TOKEN` | `.env` file | MCP GitHub server only |
| `BRAVE_API_KEY` | `.env` file | MCP Brave server only |
| `POSTGRES_PASSWORD` | `.env` file | MCP Postgres + DB service |

### Best practices

1. **Never commit `.env`** — it is in `.gitignore` by default.
2. **Rotate API keys regularly** — especially after sharing the repository.
3. **Use scoped tokens** — GitHub PATs should have minimum required scopes (`repo`, `read:org`).
4. **Consider Docker secrets** for production deployments instead of environment variables.

### What NOT to do

- Do not hardcode API keys in Dockerfiles, compose files, or scripts.
- Do not pass API keys as command-line arguments (visible in `ps` output).
- Do not mount your host's `~/.claude` with write access (the compose files use `:ro`).

## Container Isolation

### CIS Docker Benchmark Controls

All compose files enforce the following security controls:

| Control | Setting | CIS Benchmark |
|---------|---------|---------------|
| Capabilities | `cap_drop: [ALL]` | 5.3 |
| Privilege escalation | `security_opt: [no-new-privileges:true]` | 5.25 |
| Root filesystem | `read_only: true` | 5.12 |
| PID limits | `pids_limit: 256` | 5.28 |
| Process init | `tini` as PID 1 (in base image) | 5.29 |
| Resource limits | CPU/memory via `deploy.resources` | 5.10/5.11 |
| Log rotation | `json-file` driver with `max-size`/`max-file` | 5.7 |
| Non-root user | `USER node` in Dockerfile | 5.15 |

Writable paths are limited to tmpfs mounts (`/tmp`, `/home/node/.config`, `/home/node/.cache`) and explicit volume mounts.

### What is isolated

- Each agent runs as the `node` user (non-root) inside its container.
- Containers have separate PID, network, and mount namespaces.
- All Linux capabilities are dropped; no privilege escalation is possible.
- Root filesystem is read-only; agents can only write to mounted volumes and tmpfs.
- Resource limits (CPU, memory, PIDs) prevent a single agent from exhausting the host.

### What is NOT isolated

- **Shared volumes** — All agents can read/write to `shared-tasks`, `shared-status`, `shared-output`, and `workspace`. A compromised agent could modify another agent's task files or outputs.
- **Network** — All agents share the `agent-net` bridge network. An agent could potentially communicate with MCP services or other agents.
- **Auth credentials** — `.claude/` is mounted to all containers (read-only).

## Network Security

- Containers use a Docker bridge network (`agent-net`) with outbound access.
- No ports are published to the host by default.
- Database connections (PostgreSQL) are unencrypted within the Docker network.
- For production use, enable SSL on database connections.

## Recommendations by Environment

### Development (default)

The current configuration is appropriate. Use as-is.

### Staging / CI

- Pin `CLAUDE_CODE_VERSION` to a specific version in `.env`.
- Use CI/CD secret management (GitHub Actions secrets, etc.) instead of `.env` files.
- Run Trivy scans on the base image (already included in CI pipeline).

### Production

Not recommended without:
- Removing `--dangerously-skip-permissions` and implementing approval workflows.
- Encrypting database connections with SSL.
- Using Docker secrets or a vault for API keys.
- Adding audit logging for all agent actions.
- Implementing network policies to restrict inter-container communication.
