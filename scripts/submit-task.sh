#!/usr/bin/env bash
###############################################################################
# submit-task.sh — Submit a task to the master controller for multi-agent work
#
# Writes a task file to a temporary volume, then launches all agents.
# The master controller reads the task, decomposes it, and delegates.
#
# Usage:
#   ./scripts/submit-task.sh "Build a REST API with Express.js"
#   ./scripts/submit-task.sh --priority low "Update the README"
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# ── Parse arguments ────────────────────────────────────────────────────────
PRIORITY="high"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--priority high|medium|low] \"<task description>\""
      echo ""
      echo "Examples:"
      echo "  $0 \"Build a REST API with Express.js and PostgreSQL\""
      echo "  $0 --priority medium \"Refactor the authentication module\""
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

if [ -z "${1:-}" ]; then
  log_fatal "No task description provided. Run: $0 --help"
fi

check_docker
check_api_key
check_workspace

TASK_DESCRIPTION="$1"
TASK_ID="task-$(date +%Y%m%d-%H%M%S)-$$"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── Write task file using jq for safe JSON encoding ────────────────────────
TASK_DIR="./workspace/.tasks/master"
mkdir -p "$TASK_DIR"

jq -n \
  --arg id "$TASK_ID" \
  --arg desc "$TASK_DESCRIPTION" \
  --arg ts "$TIMESTAMP" \
  --arg pri "$PRIORITY" \
  '{
    task_id: $id,
    description: $desc,
    submitted_at: $ts,
    priority: $pri
  }' > "${TASK_DIR}/incoming.json"

print_banner "Task Submitted"
log_ok "ID:       ${TASK_ID}"
log_ok "Priority: ${PRIORITY}"
log_ok "Task:     ${TASK_DESCRIPTION}"
echo ""
log_info "Starting 6-agent system..."
echo ""

docker compose up --build
