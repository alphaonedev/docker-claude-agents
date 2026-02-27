# Troubleshooting

## Setup Issues

### `.env` file not found
```
[error] .env file not found
```
**Fix:** Run `make setup` or `cp .env.example .env`, then edit `.env` to set your `ANTHROPIC_API_KEY`.

### ANTHROPIC_API_KEY not set
```
ANTHROPIC_API_KEY is required — see .env.example
```
**Fix:** Edit `.env` and replace `your_anthropic_api_key_here` with your actual key from [console.anthropic.com](https://console.anthropic.com/settings/keys).

### Docker daemon not running
```
[error] Docker daemon is not running
```
**Fix:** Start Docker Desktop or the Docker daemon (`sudo systemctl start docker` on Linux).

### Docker Compose version too old
```
[error] Docker Compose V2 is required
```
**Fix:** Update Docker Desktop, or install the Compose plugin: `docker compose version` should show `v2.20+`.

## Runtime Issues

### Container exits immediately
**Cause:** Usually a missing or invalid API key.
**Debug:**
```bash
docker compose logs master-controller
```
Look for authentication errors.

### Agent hangs / no output
**Cause:** Missing `--dangerously-skip-permissions` flag, or the agent is waiting for a task file that doesn't exist.
**Debug:**
```bash
docker compose ps -a          # check container status
docker compose logs -f coder  # tail a specific agent's logs
```

### Task init service fails
```
task-init exited with code 1
```
**Cause:** Volume mount issue or permission problem.
**Fix:**
```bash
make clean                    # remove volumes
make team                     # rebuild from scratch
```

### Agent status stuck on "working"
**Cause:** Agent may have timed out or crashed mid-task.
**Debug:**
```bash
# Check if container is still running
docker compose ps

# Check container logs
docker compose logs tester

# Check status file directly
docker compose exec tester cat /app/status/tester/current.json
```

### Out of memory
```
Container killed (OOMKilled)
```
**Fix:** Increase memory limits in `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 8G  # increase from default 4G
```

## Volume Issues

### Stale data from previous runs
**Cause:** Shared volumes persist across `docker compose down`.
**Fix:**
```bash
make clean  # removes volumes
```

### Permission denied on workspace
**Cause:** Files created by the container's `node` user may have different ownership.
**Fix:**
```bash
sudo chown -R $(whoami) workspace/
```

## MCP Service Issues

### MCP server won't start
**Cause:** Missing API key in `.env`.
**Fix:** Check that `GITHUB_TOKEN`, `BRAVE_API_KEY`, or `POSTGRES_PASSWORD` is set.

### Database connection refused
**Cause:** PostgreSQL hasn't finished starting.
**Fix:** The health check should handle this, but if it persists:
```bash
docker compose -f docker-compose.yml -f docker-compose.mcp.yml logs db-service
```

## Network Issues

### Agents can't reach Anthropic API
**Cause:** Outbound network blocked, proxy required, or DNS issue.
**Debug:**
```bash
docker compose exec coder curl -s https://api.anthropic.com/ | head -5
```

### Accessing host services (Mac/Windows)
Use `host.docker.internal` as the hostname:
```bash
docker compose exec coder curl http://host.docker.internal:3000
```

### Accessing host services (Linux)
Add to `docker compose run`:
```bash
docker compose run --network=host claude-chat
```

## Getting More Help

1. Check agent logs: `make logs`
2. Check container status: `make status`
3. Validate config: `make validate`
4. Start fresh: `make clean && make team`
