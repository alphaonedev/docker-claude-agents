###############################################################################
# Docker Claude Agents — Makefile
###############################################################################

.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE           := docker compose
COMPOSE_CHAT      := $(COMPOSE) -f docker-compose.chat.yml
COMPOSE_COWORK    := $(COMPOSE) -f docker-compose.cowork.yml
COMPOSE_MCP       := $(COMPOSE) -f docker-compose.yml -f docker-compose.mcp.yml
COMPOSE_LANGGRAPH := $(COMPOSE) -f docker-compose.yml -f docker-compose.langgraph.yml
COMPOSE_MSAGENT   := $(COMPOSE) -f docker-compose.yml -f docker-compose.msagent.yml
COMPOSE_PLATFORM  := $(COMPOSE) -f docker-compose.yml -f docker-compose.langgraph.yml -f docker-compose.msagent.yml
COMPOSE_FULL      := $(COMPOSE) -f docker-compose.yml -f docker-compose.langgraph.yml -f docker-compose.msagent.yml -f docker-compose.mcp.yml

BLUE  := \033[0;34m
GREEN := \033[0;32m
BOLD  := \033[1m
RESET := \033[0m

# ═════════════════════════════════════════════════════════════════════════════

.PHONY: help setup build-base build team chat cowork mcp task run \
        langgraph msagent platform full \
        logs status health stop clean purge validate lint

help: ## Show this help
	@printf "\n$(BOLD)Docker Claude Agents$(RESET)\n"
	@printf '%.0s─' {1..50}; printf '\n'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ── Setup ────────────────────────────────────────────────────────────────────

setup: ## First-time setup: create .env, workspace, .claude dirs
	@[ -f .env ] || (cp .env.example .env && echo "Created .env — edit it to add your ANTHROPIC_API_KEY")
	@mkdir -p workspace .claude
	@echo "Setup complete. Edit .env before running agents."

# ── Build ────────────────────────────────────────────────────────────────────

build-base: ## Build the base agent image
	docker build -f Dockerfile.base -t claude-agent-base \
		--build-arg BUILD_DATE="$$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		--build-arg VCS_REF="$$(git rev-parse --short HEAD 2>/dev/null || echo unknown)" \
		.

build: build-base ## Build all agent images
	$(COMPOSE) build

# ── Run modes ────────────────────────────────────────────────────────────────

team: ## Launch the full 6-agent team
	./scripts/start-all.sh

chat: ## Launch interactive single-agent chat
	./scripts/start-chat.sh

cowork: ## Launch lead + reviewer pair programming
	./scripts/start-cowork.sh

mcp: ## Launch agents with MCP tool servers
	./scripts/start-with-mcp.sh

langgraph: build-base ## Launch Claude agents + LangGraph stack
	$(COMPOSE_LANGGRAPH) up --build

msagent: build-base ## Launch Claude agents + Microsoft Agent Framework
	$(COMPOSE_MSAGENT) up --build

platform: build-base ## Launch all 3 frameworks (Claude + LangGraph + MS Agent)
	$(COMPOSE_PLATFORM) up --build

full: build-base ## Launch all frameworks + MCP tool servers
	$(COMPOSE_FULL) up --build

task: ## Submit a task (usage: make task PROMPT="your task here")
	@[ -n "$(PROMPT)" ] || (echo "Usage: make task PROMPT=\"your task here\"" && exit 1)
	./scripts/submit-task.sh "$(PROMPT)"

run: ## Run a one-off task (usage: make run PROMPT="your task here")
	@[ -n "$(PROMPT)" ] || (echo "Usage: make run PROMPT=\"your task here\"" && exit 1)
	./scripts/run-single-task.sh "$(PROMPT)"

# ── Monitoring ───────────────────────────────────────────────────────────────

logs: ## Tail logs from all running agents
	$(COMPOSE) logs -f

status: ## Show status of all running containers
	$(COMPOSE) ps -a
	@echo ""
	$(COMPOSE_COWORK) ps -a 2>/dev/null || true

health: ## Check health of all running containers
	@docker ps --filter "label=com.docker.compose.project" \
		--format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20

# ── Cleanup ──────────────────────────────────────────────────────────────────

stop: ## Stop all running agents (keep volumes)
	./scripts/cleanup.sh

clean: ## Stop agents and remove volumes
	./scripts/cleanup.sh --volumes

purge: ## Remove everything: containers, volumes, and images
	./scripts/cleanup.sh --all

# ── Validation ───────────────────────────────────────────────────────────────

validate: ## Validate compose files, schemas, and environment
	@echo "Validating docker-compose.yml..."
	@$(COMPOSE) config --quiet
	@echo "Validating docker-compose.chat.yml..."
	@$(COMPOSE_CHAT) config --quiet
	@echo "Validating docker-compose.cowork.yml..."
	@$(COMPOSE_COWORK) config --quiet
	@echo "Validating docker-compose.langgraph.yml..."
	@$(COMPOSE_LANGGRAPH) config --quiet
	@echo "Validating docker-compose.msagent.yml..."
	@$(COMPOSE_MSAGENT) config --quiet
	@echo ""
	@echo "Validating JSON schemas..."
	@for f in schemas/*.json; do jq empty "$$f" && echo "  $$f OK" || exit 1; done
	@echo ""
	@echo "Checking .env..."
	@[ -f .env ] || { echo "  .env MISSING"; exit 1; }
	@echo "  .env exists"
	@echo "Checking workspace..."
	@[ -d workspace ] || { echo "  workspace/ MISSING"; exit 1; }
	@echo "  workspace/ exists"
	@echo ""
	@echo "Validation passed."

lint: ## Lint shell scripts with shellcheck
	@command -v shellcheck &>/dev/null || { echo "shellcheck not found — install: brew install shellcheck"; exit 1; }
	shellcheck -x scripts/*.sh
