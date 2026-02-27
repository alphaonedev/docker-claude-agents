FROM node:22-slim

# Install git and essential tools for Claude to function
RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

RUN mkdir -p /home/node/.claude && chown -R node:node /home/node /app

# Copy agent-specific system prompt and config
COPY --chown=node:node system-prompt.md /app/system-prompt.md
COPY --chown=node:node CLAUDE.md /app/CLAUDE.md

USER node

ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
