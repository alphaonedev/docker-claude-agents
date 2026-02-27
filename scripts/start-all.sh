#!/usr/bin/env bash
###############################################################################
# start-all.sh - Launch the full 6-agent system
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

# Check for .env
if [ ! -f .env ]; then
    echo "ERROR: .env file not found. Copy .env.example to .env and set your API key."
    echo "  cp .env.example .env"
    exit 1
fi

# Check for API key
source .env
if [ -z "${ANTHROPIC_API_KEY:-}" ] || [ "$ANTHROPIC_API_KEY" = "your_anthropic_api_key_here" ]; then
    echo "ERROR: ANTHROPIC_API_KEY not set in .env"
    exit 1
fi

echo "=== Docker Claude Agents - Starting 6-Agent System ==="
echo ""
echo "Agents:"
echo "  1. Master Controller (orchestrator)"
echo "  2. Researcher (information gathering)"
echo "  3. Coder (implementation)"
echo "  4. Reviewer (code review)"
echo "  5. Tester (testing)"
echo "  6. Deployer (deployment)"
echo ""

docker compose up --build "$@"
