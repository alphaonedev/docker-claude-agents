#!/usr/bin/env bash
###############################################################################
# lib.sh — Shared functions for all Docker Claude Agent scripts
#
# Source this file at the top of every script:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "${SCRIPT_DIR}/lib.sh"
###############################################################################

set -euo pipefail

# ── Resolve project root ────────────────────────────────────────────────────
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")/.." && pwd)"
cd "$PROJECT_DIR"

# ── Color helpers (disable if not a terminal) ────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m'
  BLUE='\033[0;34m' BOLD='\033[1m' RESET='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' RESET=''
fi

log_info()  { printf "${BLUE}[info]${RESET}  %s\n" "$*"; }
log_ok()    { printf "${GREEN}[ok]${RESET}    %s\n" "$*"; }
log_warn()  { printf "${YELLOW}[warn]${RESET}  %s\n" "$*" >&2; }
log_error() { printf "${RED}[error]${RESET} %s\n" "$*" >&2; }
log_fatal() { log_error "$*"; exit 1; }

# ── Signal handling ─────────────────────────────────────────────────────────
_cleanup_pids=()

on_signal() {
  local sig="$1"
  log_warn "Caught ${sig} — shutting down..."
  # Kill any background processes we spawned
  for pid in "${_cleanup_pids[@]}"; do
    kill "$pid" 2>/dev/null || true
  done
  exit 130
}

trap 'on_signal SIGINT'  INT
trap 'on_signal SIGTERM' TERM

cleanup_on_exit() {
  local exit_code=$?
  if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
    log_error "Exited with code ${exit_code}."
    log_warn "Containers may still be running — use 'make stop' to clean up."
  fi
}
trap cleanup_on_exit EXIT

# ── Prerequisite checks ─────────────────────────────────────────────────────
require_command() {
  command -v "$1" &>/dev/null || log_fatal "'$1' is required but not found in PATH."
}

check_docker() {
  require_command docker
  docker info &>/dev/null || log_fatal "Docker daemon is not running."
  docker compose version &>/dev/null || log_fatal "Docker Compose V2 is required."
}

check_env_file() {
  [ -f .env ] || log_fatal ".env not found. Run: cp .env.example .env"
}

check_api_key() {
  check_env_file
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  if [ -z "${ANTHROPIC_API_KEY:-}" ] || [ "$ANTHROPIC_API_KEY" = "your_anthropic_api_key_here" ]; then
    log_fatal "ANTHROPIC_API_KEY not set. Edit .env to configure it."
  fi
}

check_workspace() {
  [ -d workspace ] || { mkdir -p workspace; log_info "Created workspace/ directory."; }
}

# ── Base image helper ────────────────────────────────────────────────────────
ensure_base_image() {
  if ! docker image inspect claude-agent-base &>/dev/null; then
    log_info "Building base image (claude-agent-base)..."
    docker build -f Dockerfile.base -t claude-agent-base \
      --build-arg BUILD_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
      .
    log_ok "Base image built."
  fi
}

# ── Atomic JSON write (write to temp, then rename) ──────────────────────────
write_json() {
  local dest="$1" content="$2"
  local tmp="${dest}.tmp.$$"
  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$content" > "$tmp"
  mv -f "$tmp" "$dest"
}

# ── Banner ──────────────────────────────────────────────────────────────────
print_banner() {
  local mode="${1:-}"
  printf "\n${BOLD}Docker Claude Agents${RESET}"
  [ -n "$mode" ] && printf " — ${BLUE}%s${RESET}" "$mode"
  printf "\n"
  printf '%*s\n' 50 '' | tr ' ' '─'
}
