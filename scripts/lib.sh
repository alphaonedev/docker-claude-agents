#!/usr/bin/env bash
###############################################################################
# lib.sh — Shared functions for all Docker Claude Agent scripts
#
# Source this file at the top of every script:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib.sh"
###############################################################################

set -euo pipefail

# ── Resolve project root ───────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")/.." && pwd)"
cd "$PROJECT_DIR"

# ── Color helpers (disable if not a terminal) ──────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

log_info()  { printf "${BLUE}[info]${RESET}  %s\n" "$*"; }
log_ok()    { printf "${GREEN}[ok]${RESET}    %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[warn]${RESET}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[error]${RESET} %s\n" "$*" >&2; }
log_fatal() { log_error "$*"; exit 1; }

# ── Prerequisite checks ───────────────────────────────────────────────────
require_command() {
  command -v "$1" &>/dev/null || log_fatal "'$1' is required but not found in PATH."
}

check_docker() {
  require_command docker
  docker info &>/dev/null || log_fatal "Docker daemon is not running."

  # Verify Compose V2
  docker compose version &>/dev/null || log_fatal "Docker Compose V2 is required. Update Docker Desktop or install the compose plugin."
}

check_env_file() {
  if [ ! -f .env ]; then
    log_fatal ".env file not found. Run: cp .env.example .env  — then set your ANTHROPIC_API_KEY."
  fi
}

check_api_key() {
  check_env_file

  # Source .env safely (only export lines matching KEY=VALUE)
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a

  if [ -z "${ANTHROPIC_API_KEY:-}" ] || [ "$ANTHROPIC_API_KEY" = "your_anthropic_api_key_here" ]; then
    log_fatal "ANTHROPIC_API_KEY is not set or still contains the placeholder value. Edit .env to set it."
  fi
}

check_workspace() {
  if [ ! -d workspace ]; then
    mkdir -p workspace
    log_info "Created workspace/ directory."
  fi
}

# ── Cleanup trap ──────────────────────────────────────────────────────────
cleanup_on_error() {
  local exit_code=$?
  if [ $exit_code -ne 0 ]; then
    log_warn "Script exited with code $exit_code. Containers may still be running."
    log_warn "Run 'make clean' or './scripts/cleanup.sh' to stop all agents."
  fi
}
trap cleanup_on_error EXIT

# ── Banner ────────────────────────────────────────────────────────────────
print_banner() {
  local mode="${1:-}"
  printf "\n${BOLD}Docker Claude Agents${RESET}"
  [ -n "$mode" ] && printf " — ${BLUE}%s${RESET}" "$mode"
  printf "\n"
  printf '%*s\n' 50 '' | tr ' ' '─'
}
