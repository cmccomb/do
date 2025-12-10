#!/usr/bin/env bash
# shellcheck shell=bash
#
# Formatting helpers for tool descriptions and summaries.
#
# Usage:
#   source "${BASH_SOURCE[0]%/formatting.sh}/formatting.sh"
#
# Environment variables:
#   None.
#
# Dependencies:
#   - bash 5+
#   - jq
#
# Exit codes:
#   Functions return non-zero on misuse.

# shellcheck source=../logging.sh disable=SC1091
source "${BASH_SOURCE[0]%/formatting.sh}/../logging.sh"

format_tool_descriptions() {
        # Arguments:
        #   $1 - newline-delimited allowed tool names (string)
        #   $2 - callback to format a single tool line (function name)
        local allowed_tools formatter tool_lines tool formatted_line
        allowed_tools="$1"
        formatter="$2"
        tool_lines=""

        if [[ -z "${formatter}" ]]; then
                log "ERROR" "format_tool_descriptions requires a formatter" ""
                return 1
        fi

        if ! declare -F "${formatter}" >/dev/null 2>&1; then
                log "ERROR" "Unknown tool formatter" "${formatter}"
                return 1
        fi

        while IFS= read -r tool; do
                [[ -z "${tool}" ]] && continue
                formatted_line="$(${formatter} "${tool}")"
                if [[ -n "${formatted_line}" ]]; then
                        tool_lines+="${formatted_line}"$'\n'
                fi
        done <<<"${allowed_tools}"

        printf '%s' "${tool_lines%$'\n'}"
}

format_tool_summary_line() {
        # Arguments:
        #   $1 - tool name (string)
        local tool
        tool="$1"
        printf -- '- %s: %s' "${tool}" "$(tool_description "${tool}")"
}

format_tool_example_line() {
        # Arguments:
        #   $1 - tool name (string)
        local tool
        tool="$1"
        printf -- '- %s: %s (example query: %s)' "${tool}" "$(tool_description "${tool}")" "$(tool_command "${tool}")"
}
