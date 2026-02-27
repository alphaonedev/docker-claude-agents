#!/usr/bin/env bash
###############################################################################
# cleanup.sh - Stop all agents and clean up Docker resources
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=== Stopping all agents ==="
docker compose down --remove-orphans 2>/dev/null || true
docker compose -f docker-compose.chat.yml down --remove-orphans 2>/dev/null || true
docker compose -f docker-compose.cowork.yml down --remove-orphans 2>/dev/null || true
docker compose -f docker-compose.yml -f docker-compose.mcp.yml down --remove-orphans 2>/dev/null || true

echo ""
echo "=== Removing shared volumes ==="
docker volume rm docker-claude-agents_shared-tasks 2>/dev/null || true
docker volume rm docker-claude-agents_shared-status 2>/dev/null || true
docker volume rm docker-claude-agents_shared-output 2>/dev/null || true
docker volume rm docker-claude-agents_cowork-tasks 2>/dev/null || true
docker volume rm docker-claude-agents_cowork-status 2>/dev/null || true
docker volume rm docker-claude-agents_cowork-output 2>/dev/null || true
docker volume rm docker-claude-agents_db-data 2>/dev/null || true

echo ""
echo "Cleanup complete."
