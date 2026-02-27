FROM node:22-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @anthropic-ai/claude-code

WORKDIR /app

RUN mkdir -p /home/node/.claude && chown -R node:node /home/node /app

COPY --chown=node:node system-prompt.md /app/system-prompt.md
COPY --chown=node:node CLAUDE.md /app/CLAUDE.md

USER node

ENTRYPOINT ["claude"]
CMD ["--dangerously-skip-permissions"]
