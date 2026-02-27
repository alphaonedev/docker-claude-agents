"""
Microsoft Agent Framework — HTTP + gRPC Server

Provides a FastAPI HTTP server for health checks and task submission,
alongside a gRPC server for distributed agent communication.
"""

import asyncio
import json
import os
import signal
import sys
from datetime import datetime, timezone
from pathlib import Path

import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

app = FastAPI(title="Microsoft Agent Framework Runtime", version="1.0.0")


class TaskRequest(BaseModel):
    task_id: str
    description: str
    priority: str = "medium"
    timeout_minutes: int = 30


class HealthResponse(BaseModel):
    status: str
    timestamp: str
    framework: str
    version: str


WORKSPACE = Path(os.environ.get("WORKSPACE_DIR", "/app/workspace"))


@app.get("/health", response_model=HealthResponse)
async def health():
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now(timezone.utc).isoformat(),
        framework="microsoft-agent-framework",
        version="1.0.0",
    )


@app.post("/tasks")
async def submit_task(task: TaskRequest):
    task_dir = WORKSPACE / ".tasks" / "msagent"
    task_dir.mkdir(parents=True, exist_ok=True)
    task_file = task_dir / f"{task.task_id}.json"
    task_file.write_text(json.dumps(task.model_dump(), indent=2))
    return {"status": "accepted", "task_id": task.task_id}


@app.get("/tasks")
async def list_tasks():
    task_dir = WORKSPACE / ".tasks" / "msagent"
    if not task_dir.exists():
        return {"tasks": []}
    tasks = []
    for f in task_dir.glob("*.json"):
        tasks.append(json.loads(f.read_text()))
    return {"tasks": tasks}


def main():
    """Start the HTTP server."""
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("HTTP_PORT", "8080"))

    config = uvicorn.Config(app, host=host, port=port, log_level="info")
    server = uvicorn.Server(config)

    loop = asyncio.new_event_loop()

    def handle_signal(sig, frame):
        loop.call_soon_threadsafe(server.should_exit.__class__.__set__, server, "should_exit", True)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    loop.run_until_complete(server.serve())


if __name__ == "__main__":
    main()
