#!/usr/bin/env bash
###############################################################################
# start-chat.sh — Launch a single interactive Claude agent
#
# Usage:
#   ./scripts/start-chat.sh                                   # interactive
#   ./scripts/start-chat.sh --dangerously-skip-permissions \
#     "Analyze this codebase"                                  # one-shot
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

check_docker
check_api_key
check_workspace

print_banner "Interactive Chat"

exec docker compose -f docker-compose.chat.yml run --rm claude-chat "$@"
