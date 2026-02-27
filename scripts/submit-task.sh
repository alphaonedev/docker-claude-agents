#!/usr/bin/env bash
###############################################################################
# submit-task.sh - Submit a task to the master controller for multi-agent work
#
# Usage:
#   ./scripts/submit-task.sh "Build a REST API with Express.js"
#
# This writes a task file to the shared volume, then launches the agents.
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

if [ ! -f .env ]; then
    echo "ERROR: .env file not found."
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Usage: $0 \"your task description\""
    exit 1
fi

TASK_DESCRIPTION="$1"
TASK_ID="task-$(date +%Y%m%d-%H%M%S)"

# Create task directories if they don't exist
mkdir -p ./workspace/.tasks/master

# Write the incoming task file
cat > "./workspace/.tasks/master/incoming.json" <<EOF
{
  "task_id": "$TASK_ID",
  "description": "$TASK_DESCRIPTION",
  "submitted_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "priority": "high"
}
EOF

echo "=== Task Submitted ==="
echo "ID:   $TASK_ID"
echo "Task: $TASK_DESCRIPTION"
echo ""
echo "Starting agent system..."
echo ""

docker compose up --build
