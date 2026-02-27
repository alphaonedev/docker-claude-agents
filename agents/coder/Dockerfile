###############################################################################
# Coder Agent
#
# Code implementation, feature development, bug fixes, and refactoring.
###############################################################################
FROM node:22-slim

LABEL org.opencontainers.image.title="Claude Agent — Coder"
LABEL org.opencontainers.image.description="Code implementation specialist agent"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git curl jq ca-certificates procps; \
    rm -rf /var/lib/apt/lists/*

ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g "@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}" && \
    npm cache clean --force

WORKDIR /app

RUN mkdir -p /home/node/.claude /app/tasks /app/status /app/output /app/workspace && \
    chown -R node:node /home/node /app

COPY --chown=node:node system-prompt.md /app/system-prompt.md
COPY --chown=node:node CLAUDE.md /app/CLAUDE.md

ENV NODE_ENV=production
ENV CLAUDE_AGENT_ROLE=coder

USER node

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD pgrep -f "claude" > /dev/null || exit 1

ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
