#!/usr/bin/env bash
###############################################################################
# run-single-task.sh — Run a one-off autonomous task with a single agent
#
# Usage:
#   ./scripts/run-single-task.sh "Refactor all files to use async/await"
#   ./scripts/run-single-task.sh "Write unit tests for workspace/src/"
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

if [ -z "${1:-}" ]; then
  echo "Usage: $0 \"<task prompt>\""
  echo ""
  echo "Examples:"
  echo "  $0 \"Refactor the files in workspace/ to use async/await\""
  echo "  $0 \"Write unit tests for all functions in workspace/src/\""
  exit 1
fi

check_docker
check_api_key
check_workspace

TASK_PROMPT="$1"

print_banner "Single Task (Autonomous)"
log_info "Task: ${TASK_PROMPT}"
echo ""

exec docker compose -f docker-compose.chat.yml run --rm claude-chat \
  --dangerously-skip-permissions \
  "$TASK_PROMPT"
