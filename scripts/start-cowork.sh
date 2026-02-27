#!/usr/bin/env bash
###############################################################################
# start-cowork.sh — Launch lead + reviewer pair programming agents
#
# Usage:
#   ./scripts/start-cowork.sh
#   ./scripts/start-cowork.sh -d    # detached
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

check_docker
check_api_key
check_workspace

print_banner "Cowork Mode (Pair Programming)"

log_info "Lead Agent    — plans and implements"
log_info "Review Agent  — reviews and validates"
echo ""

docker compose -f docker-compose.cowork.yml up --build "$@"
