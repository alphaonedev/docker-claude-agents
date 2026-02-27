#!/usr/bin/env bash
###############################################################################
# start-with-mcp.sh - Launch agents with MCP servers (GitHub, DB, Search)
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and set your API key."
    exit 1
fi

echo "=== Docker Claude Agents - Full Stack with MCP Services ==="
echo ""
echo "Agents: 6 (master + 5 workers)"
echo "MCP Services: GitHub, Filesystem, Brave Search, PostgreSQL"
echo "Database: PostgreSQL 15"
echo ""

docker compose -f docker-compose.yml -f docker-compose.mcp.yml up --build "$@"
