"""
LangGraph Deep Agents — Reference Graph Definition

Defines a multi-agent graph with supervisor routing, tool execution,
and state checkpointing. This is the entry point referenced by langgraph.json.
"""

from __future__ import annotations

import operator
from typing import Annotated, Sequence, TypedDict

from langchain_core.messages import BaseMessage, HumanMessage
from langgraph.graph import END, StateGraph
from langgraph.prebuilt import ToolNode


# ── State Schema ────────────────────────────────────────────────────────────

class AgentState(TypedDict):
    """Shared state passed between all nodes in the graph."""
    messages: Annotated[Sequence[BaseMessage], operator.add]
    task_id: str
    next_agent: str
    iteration: int


# ── Node Definitions ────────────────────────────────────────────────────────

def supervisor_node(state: AgentState) -> dict:
    """Route tasks to the appropriate specialist agent."""
    messages = state["messages"]
    iteration = state.get("iteration", 0)

    if iteration >= 10:
        return {"next_agent": "aggregator", "iteration": iteration + 1}

    # Default routing logic — in production, this calls the LLM
    return {"next_agent": "researcher", "iteration": iteration + 1}


def researcher_node(state: AgentState) -> dict:
    """Research and analyze the task."""
    return {
        "messages": [HumanMessage(content="[Researcher] Analysis complete.")],
        "next_agent": "coder",
    }


def coder_node(state: AgentState) -> dict:
    """Implement the required changes."""
    return {
        "messages": [HumanMessage(content="[Coder] Implementation complete.")],
        "next_agent": "reviewer",
    }


def reviewer_node(state: AgentState) -> dict:
    """Review the implementation."""
    return {
        "messages": [HumanMessage(content="[Reviewer] Review complete.")],
        "next_agent": "aggregator",
    }


def aggregator_node(state: AgentState) -> dict:
    """Aggregate results from all agents."""
    return {
        "messages": [HumanMessage(content="[Aggregator] Final results compiled.")],
        "next_agent": END,
    }


# ── Conditional Routing ─────────────────────────────────────────────────────

def route_next(state: AgentState) -> str:
    """Determine the next node based on state."""
    return state.get("next_agent", END)


# ── Graph Construction ──────────────────────────────────────────────────────

workflow = StateGraph(AgentState)

workflow.add_node("supervisor", supervisor_node)
workflow.add_node("researcher", researcher_node)
workflow.add_node("coder", coder_node)
workflow.add_node("reviewer", reviewer_node)
workflow.add_node("aggregator", aggregator_node)

workflow.set_entry_point("supervisor")

workflow.add_conditional_edges("supervisor", route_next)
workflow.add_conditional_edges("researcher", route_next)
workflow.add_conditional_edges("coder", route_next)
workflow.add_conditional_edges("reviewer", route_next)
workflow.add_edge("aggregator", END)

graph = workflow.compile()
