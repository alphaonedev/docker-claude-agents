#!/usr/bin/env bash
###############################################################################
# run-single-task.sh - Run a one-off autonomous task with a single agent
#
# Usage:
#   ./scripts/run-single-task.sh "Refactor all files to use async/await"
#   ./scripts/run-single-task.sh "Analyze the codebase and create documentation"
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and set your API key."
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Usage: $0 \"your task prompt here\""
    echo ""
    echo "Examples:"
    echo "  $0 \"Refactor the files in workspace/ to use async/await\""
    echo "  $0 \"Write unit tests for all functions in workspace/src/\""
    exit 1
fi

TASK_PROMPT="$1"

echo "=== Docker Claude Agents - Single Task Mode ==="
echo "Task: $TASK_PROMPT"
echo ""

docker compose -f docker-compose.chat.yml run --rm claude-chat \
    --dangerously-skip-permissions \
    "$TASK_PROMPT"
