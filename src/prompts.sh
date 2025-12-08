#!/usr/bin/env bash
# shellcheck shell=bash
#
# Prompt builders for the okso assistant.
#
# Usage:
#   source "${BASH_SOURCE[0]%/prompts.sh}/prompts.sh"
#
# Environment variables:
#   None.
#
# Dependencies:
#   - bash 5+
#
# Exit codes:
#   Functions print prompts and return 0 on success.

build_concise_response_prompt() {
        # Arguments:
        #   $1 - user query (string)
        local user_query
        user_query="$1"

cat <<PROMPT
Provide a short, concise answer (two to three sentences) to the user. Your response will be stopped after the first newline character. USER REQUEST: ${user_query}.
CONCISE RESPONSE:  
PROMPT
}

build_planner_prompt() {
        # Arguments:
        #   $1 - user query (string)
        #   $2 - formatted tool descriptions (string)
        local user_query tool_lines
        user_query="$1"
        tool_lines="$2"

cat <<PROMPT
You are a planner for an autonomous agent. Given a user request and a list of available tools, draft a numbered list of high-level actions the agent should take. Each step must mention the tool name that will be used. Do NOT include fully executable shell commands; keep the guidance conceptual. Always end with a final step that uses the final_answer tool to deliver the response back to the user.

Available tools:
${tool_lines}
User request: ${user_query}
PROMPT
}

build_react_prompt() {
        # Arguments:
        #   $1 - user query (string)
        #   $2 - formatted allowed tool descriptions (string)
        #   $3 - high-level plan outline (string)
        #   $4 - prior interaction history (string)
        local user_query allowed_tools plan_outline history
        user_query="$1"
        allowed_tools="$2"
        plan_outline="$3"
        history="$4"

cat <<PROMPT
You are an assistant planning a sequence of actions. Use the high-level plan as guidance but adapt after each observation.
Respond ONLY with a single JSON object per turn.
Action schema:
- To use a tool: {"type":"tool","tool":"<tool_name>","query":"<specific command>"}
- To finish: {"type":"tool","tool":"final_answer","query":"<final user-facing reply>"}
High-level plan:
${plan_outline}
User request: ${user_query}
${allowed_tools}
Previous steps:
${history}
PROMPT
}
