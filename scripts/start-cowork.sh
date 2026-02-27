#!/usr/bin/env bash
###############################################################################
# start-cowork.sh - Launch lead + reviewer pair programming agents
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and set your API key."
    exit 1
fi

echo "=== Docker Claude Agents - Cowork Mode ==="
echo ""
echo "Agents:"
echo "  1. Lead Agent (implements)"
echo "  2. Review Agent (reviews)"
echo ""

docker compose -f docker-compose.cowork.yml up --build "$@"
