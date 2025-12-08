#!/usr/bin/env bash
# shellcheck shell=bash
#
# Tool registry utilities shared across individual tool modules.
#
# Usage:
#   source "${BASH_SOURCE[0]%/tools/registry.sh}/tools/registry.sh"
#
# Environment variables:
#   None
#
# Dependencies:
#   - bash 3+
#   - logging helpers from logging.sh
#
# Exit codes:
#   Functions emit errors via log and return non-zero when misused.

# shellcheck source=../logging.sh disable=SC1091
source "${BASH_SOURCE[0]%/tools/registry.sh}/logging.sh"

# shellcheck disable=SC2034
TOOLS=()

tool_description() {
        local name var_name
        name="$1"
        var_name="TOOL_DESCRIPTION_${name}"
        printf '%s' "${!var_name:-}"
}

tool_command() {
        local name var_name
        name="$1"
        var_name="TOOL_COMMAND_${name}"
        printf '%s' "${!var_name:-}"
}

tool_safety() {
        local name var_name
        name="$1"
        var_name="TOOL_SAFETY_${name}"
        printf '%s' "${!var_name:-}"
}

tool_handler() {
        local name var_name
        name="$1"
        var_name="TOOL_HANDLER_${name}"
        printf '%s' "${!var_name:-}"
}

init_tool_registry() {
        local name
        for name in "${TOOLS[@]}"; do
                unset "TOOL_DESCRIPTION_${name}" "TOOL_COMMAND_${name}" "TOOL_SAFETY_${name}" "TOOL_HANDLER_${name}"
        done
        TOOLS=()
}

register_tool() {
	# Arguments:
	#   $1 - name
	#   $2 - description
	#   $3 - invocation command (string)
	#   $4 - safety notes
	#   $5 - handler function name
	if [[ $# -lt 5 ]]; then
		log "ERROR" "register_tool requires five arguments" "$*"
		return 1
	fi

	local name
	name="$1"

	if [[ ! "${name}" =~ ^[a-z0-9_]+$ ]]; then
		log "ERROR" "tool names must be alphanumeric with underscores" "${name}" || true
		return 1
	fi

	if [[ -n "${TOOL_NAME_ALLOWLIST[*]:-}" ]]; then
		local allowed
		allowed=false
		for allowed in "${TOOL_NAME_ALLOWLIST[@]}"; do
			if [[ "${name}" == "${allowed}" ]]; then
				allowed=true
				break
			fi
		done

		if [[ "${allowed}" != true ]]; then
			log "ERROR" "tool name not in allowlist" "${name}" || true
			return 1
		fi
	fi
        TOOLS+=("${name}")
        printf -v "TOOL_DESCRIPTION_${name}" '%s' "$2"
        printf -v "TOOL_COMMAND_${name}" '%s' "$3"
        printf -v "TOOL_SAFETY_${name}" '%s' "$4"
        printf -v "TOOL_HANDLER_${name}" '%s' "${5:-}"
}
