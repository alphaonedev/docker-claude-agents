#!/usr/bin/env bash
###############################################################################
# start-chat.sh - Launch a single interactive Claude agent
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and set your API key."
    exit 1
fi

echo "=== Docker Claude Agents - Interactive Chat Mode ==="
echo ""

docker compose -f docker-compose.chat.yml run --rm claude-chat "$@"
