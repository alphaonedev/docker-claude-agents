###############################################################################
# Docker Claude Agents — Makefile
#
# Common operations for the multi-agent system.
# Run `make help` to see all available targets.
###############################################################################

.DEFAULT_GOAL := help
SHELL := /bin/bash

# ── Configuration ──────────────────────────────────────────────────────────
COMPOSE          := docker compose
COMPOSE_CHAT     := $(COMPOSE) -f docker-compose.chat.yml
COMPOSE_COWORK   := $(COMPOSE) -f docker-compose.cowork.yml
COMPOSE_MCP      := $(COMPOSE) -f docker-compose.yml -f docker-compose.mcp.yml

# ── Colors ─────────────────────────────────────────────────────────────────
BLUE  := \033[0;34m
GREEN := \033[0;32m
BOLD  := \033[1m
RESET := \033[0m

# ═══════════════════════════════════════════════════════════════════════════
# TARGETS
# ═══════════════════════════════════════════════════════════════════════════

.PHONY: help
help: ## Show this help message
	@printf "\n$(BOLD)Docker Claude Agents$(RESET)\n"
	@printf '%.0s─' {1..50}; printf '\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ── Setup ──────────────────────────────────────────────────────────────────

.PHONY: setup
setup: ## First-time setup: create .env, workspace, .claude dirs
	@[ -f .env ] || (cp .env.example .env && echo "Created .env — edit it to add your ANTHROPIC_API_KEY")
	@mkdir -p workspace .claude
	@echo "Setup complete. Edit .env before running agents."

# ── Build ──────────────────────────────────────────────────────────────────

.PHONY: build
build: ## Build all agent images
	$(COMPOSE) build

# ── Run modes ──────────────────────────────────────────────────────────────

.PHONY: team
team: ## Launch the full 6-agent team
	./scripts/start-all.sh

.PHONY: chat
chat: ## Launch interactive single-agent chat
	./scripts/start-chat.sh

.PHONY: cowork
cowork: ## Launch lead + reviewer pair programming
	./scripts/start-cowork.sh

.PHONY: mcp
mcp: ## Launch agents with MCP tool servers
	./scripts/start-with-mcp.sh

.PHONY: task
task: ## Submit a task (usage: make task PROMPT="your task here")
	@[ -n "$(PROMPT)" ] || (echo "Usage: make task PROMPT=\"your task here\"" && exit 1)
	./scripts/submit-task.sh "$(PROMPT)"

.PHONY: run
run: ## Run a one-off task (usage: make run PROMPT="your task here")
	@[ -n "$(PROMPT)" ] || (echo "Usage: make run PROMPT=\"your task here\"" && exit 1)
	./scripts/run-single-task.sh "$(PROMPT)"

# ── Monitoring ─────────────────────────────────────────────────────────────

.PHONY: logs
logs: ## Tail logs from all running agents
	$(COMPOSE) logs -f

.PHONY: status
status: ## Show status of all running containers
	$(COMPOSE) ps -a
	@echo ""
	$(COMPOSE_COWORK) ps -a 2>/dev/null || true

.PHONY: health
health: ## Check health of all running containers
	@docker ps --filter "label=com.docker.compose.project" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20

# ── Cleanup ────────────────────────────────────────────────────────────────

.PHONY: stop
stop: ## Stop all running agents (keep volumes)
	./scripts/cleanup.sh

.PHONY: clean
clean: ## Stop agents and remove volumes
	./scripts/cleanup.sh --volumes

.PHONY: purge
purge: ## Remove everything: containers, volumes, and images
	./scripts/cleanup.sh --all

# ── Validation ─────────────────────────────────────────────────────────────

.PHONY: validate
validate: ## Validate compose files and environment
	@echo "Validating docker-compose.yml..."
	@$(COMPOSE) config --quiet && echo "  OK" || echo "  FAILED"
	@echo "Validating docker-compose.chat.yml..."
	@$(COMPOSE_CHAT) config --quiet && echo "  OK" || echo "  FAILED"
	@echo "Validating docker-compose.cowork.yml..."
	@$(COMPOSE_COWORK) config --quiet && echo "  OK" || echo "  FAILED"
	@echo ""
	@echo "Validating JSON schemas..."
	@for f in schemas/*.json; do jq empty "$$f" 2>/dev/null && echo "  $$f OK" || echo "  $$f INVALID"; done
	@echo ""
	@echo "Checking .env..."
	@[ -f .env ] && echo "  .env exists" || echo "  .env MISSING"
	@echo "Checking workspace..."
	@[ -d workspace ] && echo "  workspace/ exists" || echo "  workspace/ MISSING"

.PHONY: lint
lint: ## Lint shell scripts with shellcheck (if installed)
	@command -v shellcheck &>/dev/null || (echo "shellcheck not found — install it: brew install shellcheck" && exit 1)
	shellcheck scripts/*.sh
