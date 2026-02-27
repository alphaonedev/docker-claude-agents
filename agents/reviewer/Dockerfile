FROM claude-agent-base
LABEL org.opencontainers.image.title="Claude Agent — Reviewer"
COPY --chown=node:node system-prompt.md CLAUDE.md /app/
ENV CLAUDE_AGENT_ROLE=reviewer
