#!/usr/bin/env bash
###############################################################################
# start-all.sh — Launch the full 6-agent team
#
# Usage:
#   ./scripts/start-all.sh              # foreground with logs
#   ./scripts/start-all.sh -d           # detached
#   ./scripts/start-all.sh --no-build   # skip image rebuild
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

check_docker
check_api_key
check_workspace

print_banner "Full Team (6 Agents)"

log_info "Master Controller  — orchestrator"
log_info "Researcher         — information gathering"
log_info "Coder              — implementation"
log_info "Reviewer           — code review & security"
log_info "Tester             — test authoring & execution"
log_info "Deployer           — CI/CD & infrastructure"
echo ""

docker compose up --build "$@"
