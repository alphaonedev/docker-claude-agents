# Contributing

Thank you for considering contributing to Docker Claude Agents.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/docker-claude-agents.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Run setup: `make setup`

## Development

### Prerequisites

- Docker Engine >= 24.0
- Docker Compose >= 2.20
- shellcheck (for linting): `brew install shellcheck`
- jq (for JSON validation): `brew install jq`

### Validate before committing

```bash
make validate    # Check compose files, schemas, env
make lint        # Lint shell scripts
```

### Project structure

```
agents/{name}/          # Per-agent: Dockerfile, system-prompt.md, CLAUDE.md
scripts/                # Shell scripts (source lib.sh for shared functions)
schemas/                # JSON Schema contracts
docs/                   # Architecture, security, troubleshooting
docker-compose*.yml     # Compose configurations
```

## Pull Request Process

1. Ensure `make validate && make lint` passes
2. Update CHANGELOG.md with your changes under `[Unreleased]`
3. If adding a new agent, include Dockerfile, system-prompt.md, and CLAUDE.md
4. If modifying compose files, verify all 4 compose configurations still validate
5. Keep shell scripts shellcheck-clean
6. One PR per concern — avoid mixing unrelated changes

## Standards

- **Dockerfiles**: Agent Dockerfiles must extend `claude-agent-base` (4 lines max)
- **Shell scripts**: Source `scripts/lib.sh`, use `set -euo pipefail` (inherited from lib.sh)
- **Compose files**: Include CIS hardening (cap_drop, security_opt, read_only, pids_limit)
- **System prompts**: Keep under 40 lines — actionable instructions only, no padding
- **JSON schemas**: Validate with `jq empty`

## Reporting Issues

Use the [issue templates](.github/ISSUE_TEMPLATE/) for bug reports and feature requests.
