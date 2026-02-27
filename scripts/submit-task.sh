#!/usr/bin/env bash
###############################################################################
# submit-task.sh — Submit a task to the master controller
#
# Writes a task JSON to workspace/.tasks/ then launches the 6-agent team.
#
# Usage:
#   ./scripts/submit-task.sh "Build a REST API with Express.js"
#   ./scripts/submit-task.sh --priority low "Update the README"
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

# ── Parse arguments ──────────────────────────────────────────────────────────
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

[ -z "${1:-}" ] && log_fatal "No task description provided. Run: $0 --help"

check_docker
check_api_key
check_workspace
ensure_base_image

TASK_DESCRIPTION="$1"
TASK_ID="task-$(date +%Y%m%d-%H%M%S)-$$"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# ── Write task file atomically using jq for safe JSON encoding ───────────────
TASK_FILE="./workspace/.tasks/incoming.json"

write_json "$TASK_FILE" "$(jq -n \
  --arg id "$TASK_ID" \
  --arg desc "$TASK_DESCRIPTION" \
  --arg ts "$TIMESTAMP" \
  --arg pri "$PRIORITY" \
  '{task_id: $id, description: $desc, submitted_at: $ts, priority: $pri}'
)"

print_banner "Task Submitted"
log_ok "ID:       ${TASK_ID}"
log_ok "Priority: ${PRIORITY}"
log_ok "Task:     ${TASK_DESCRIPTION}"
echo ""
log_info "Starting 6-agent system..."
echo ""

exec docker compose up --build
