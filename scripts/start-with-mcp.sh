#!/usr/bin/env bash
###############################################################################
# start-with-mcp.sh — Launch agents with MCP tool servers
#
# Adds GitHub, Brave Search, Filesystem, and PostgreSQL MCP servers.
#
# Usage:
#   ./scripts/start-with-mcp.sh
#   ./scripts/start-with-mcp.sh -d
#
# Prerequisites (in .env):
#   GITHUB_TOKEN, BRAVE_API_KEY, POSTGRES_PASSWORD
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

check_docker
check_api_key
check_workspace
ensure_base_image

# Validate MCP-specific environment
set -a; source .env; set +a

[ -z "${GITHUB_TOKEN:-}" ]      && log_warn "GITHUB_TOKEN not set — GitHub MCP will not start."
[ -z "${BRAVE_API_KEY:-}" ]     && log_warn "BRAVE_API_KEY not set — Brave Search MCP will not start."
[ -z "${POSTGRES_PASSWORD:-}" ] && log_warn "POSTGRES_PASSWORD not set — PostgreSQL MCP will not start."

print_banner "Full Team + MCP Services"

log_info "Agents:  6 (master + 5 specialists)"
log_info "MCP:     GitHub, Filesystem, Brave Search, PostgreSQL"
echo ""

exec docker compose -f docker-compose.yml -f docker-compose.mcp.yml up --build "$@"
