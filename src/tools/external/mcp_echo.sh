#!/usr/bin/env bash
# shellcheck shell=bash
#
# Minimal MCP-compatible endpoint exposing a single echo tool for reference.
#
# Usage:
#   echo '{"action":"list_tools"}' | ./src/tools/external/mcp_echo.sh
#
# Dependencies:
#   - bash 5+
#   - jq
set -euo pipefail

build_descriptor() {
        jq -n '{
                name:"echo_external",
                description:"Echo back provided message content.",
                command:"echo_external <message>",
                origin:"remote",
                safety:"Returns user-supplied content without mutation.",
                input_schema:{type:"object", required:["message"], properties:{message:{type:"string", description:"Text to echo"}}},
                result_schema:{type:"object", properties:{echo:{type:"string"}}}
        }'
}

respond_error() {
        local name category message
        name="$1"
        category="$2"
        message="$3"

        jq -n --arg name "${name}" --arg category "${category}" --arg message "${message}" '{type:"error", error:{name:$name, category:$category, message:$message}}'
}

handle_list() {
        local descriptor
        descriptor=$(build_descriptor)
        jq -n --argjson descriptor "${descriptor}" '{type:"result", tools:[$descriptor]}'
}

handle_describe() {
        local request tool descriptor
        request="$1"
        tool=$(jq -er '.tool' <<<"${request}" 2>/dev/null) || {
                respond_error "echo_external" "usage" "Tool name required" >&2
                return 1
        }

        if [[ "${tool}" != "echo_external" ]]; then
                respond_error "echo_external" "usage" "Unknown tool" >&2
                return 1
        fi

        descriptor=$(build_descriptor)
        jq -n --argjson descriptor "${descriptor}" '{type:"result", tool:$descriptor}'
}

handle_call() {
        local request message
        request="$1"
        message=$(jq -er '.arguments.message' <<<"${request}" 2>/dev/null) || {
                respond_error "echo_external" "usage" "arguments.message is required" >&2
                return 1
        }

        if [[ "${message}" == "explode" ]]; then
                respond_error "echo_external" "fatal" "Simulated failure" >&2
                return 1
        fi

        jq -n --arg tool "echo_external" --arg message "${message}" '{type:"result", tool:$tool, result:{echo:$message}}'
}

request_payload=$(cat)
action=$(jq -er '.action' <<<"${request_payload}" 2>/dev/null) || {
        respond_error "echo_external" "usage" "action is required" >&2
        exit 1
}

case "${action}" in
        list_tools)
                handle_list
                ;;
        describe_tool)
                if ! handle_describe "${request_payload}"; then
                        exit 1
                fi
                ;;
        call_tool)
                if ! handle_call "${request_payload}"; then
                        exit 1
                fi
                ;;
        *)
                respond_error "echo_external" "usage" "Unsupported action" >&2
                exit 1
                ;;
        esac
