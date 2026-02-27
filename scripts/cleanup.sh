#!/usr/bin/env bash
###############################################################################
# cleanup.sh — Stop all agents and clean up Docker resources
#
# Usage:
#   ./scripts/cleanup.sh             # stop containers, keep volumes
#   ./scripts/cleanup.sh --volumes   # stop containers AND remove volumes
#   ./scripts/cleanup.sh --all       # remove volumes + images
###############################################################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib.sh"

REMOVE_VOLUMES=false
REMOVE_IMAGES=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --volumes|-v)
      REMOVE_VOLUMES=true
      shift
      ;;
    --all|-a)
      REMOVE_VOLUMES=true
      REMOVE_IMAGES=true
      shift
      ;;
    --help|-h)
      echo "Usage: $0 [--volumes] [--all]"
      echo ""
      echo "  (no flags)   Stop containers, keep volumes and images"
      echo "  --volumes    Also remove shared Docker volumes"
      echo "  --all        Remove volumes AND built images"
      exit 0
      ;;
    *)
      log_fatal "Unknown flag: $1. Run: $0 --help"
      ;;
  esac
done

check_docker

# ── Stop containers across all compose configurations ──────────────────────
print_banner "Cleanup"

log_info "Stopping containers..."
COMPOSE_FILES=(
  "docker-compose.yml"
  "docker-compose.chat.yml"
  "docker-compose.cowork.yml"
)

for f in "${COMPOSE_FILES[@]}"; do
  if [ -f "$f" ]; then
    docker compose -f "$f" down --remove-orphans 2>/dev/null || true
  fi
done

# Also handle the MCP overlay
if [ -f docker-compose.mcp.yml ]; then
  docker compose -f docker-compose.yml -f docker-compose.mcp.yml down --remove-orphans 2>/dev/null || true
fi
log_ok "Containers stopped."

# ── Remove volumes if requested ────────────────────────────────────────────
if [ "$REMOVE_VOLUMES" = true ]; then
  log_info "Removing Docker volumes..."
  PROJECT_NAME="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"

  # Dynamically find and remove project volumes instead of hardcoding names
  docker volume ls --filter "name=${PROJECT_NAME}" --quiet | while read -r vol; do
    docker volume rm "$vol" 2>/dev/null && log_ok "  Removed $vol" || log_warn "  Could not remove $vol"
  done
  log_ok "Volumes removed."
fi

# ── Remove images if requested ─────────────────────────────────────────────
if [ "$REMOVE_IMAGES" = true ]; then
  log_info "Removing built images..."
  docker images --filter "label=org.opencontainers.image.source=https://github.com/alphaonedev/docker-claude-agents" --quiet | while read -r img; do
    docker rmi "$img" 2>/dev/null && log_ok "  Removed $img" || log_warn "  Could not remove $img"
  done
  log_ok "Images removed."
fi

echo ""
log_ok "Cleanup complete."
