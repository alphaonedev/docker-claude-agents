###############################################################################
# Microsoft Agent Framework Runtime
# Semantic Kernel + AutoGen unified agent runtime with gRPC support
###############################################################################
FROM python:3.12-slim

LABEL org.opencontainers.image.title="Microsoft Agent Framework Runtime" \
      org.opencontainers.image.description="Semantic Kernel + AutoGen agent runtime with gRPC distributed support" \
      org.opencontainers.image.source="https://github.com/alphaonedev/docker-claude-agents"

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        curl tini; \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

WORKDIR /app
COPY . /app/

RUN useradd -m -s /bin/bash appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8080 50051

ENTRYPOINT ["tini", "--"]
CMD ["python", "-m", "msagent.server"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" 2>/dev/null || exit 1
