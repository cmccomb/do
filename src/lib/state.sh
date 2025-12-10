#!/usr/bin/env bash
# shellcheck shell=bash
#
# JSON-backed state helpers.
#
# Usage:
#   source "${BASH_SOURCE[0]%/state.sh}/state.sh"
#
# Environment variables:
#   None.
#
# Dependencies:
#   - bash 5+
#   - jq
#
# Exit codes:
#   Functions return non-zero on misuse; callers should handle failures.

state_namespace_json_var() {
	# Arguments:
	#   $1 - state prefix (string)
	printf '%s_json' "$1"
}

state_get_json_document() {
	# Arguments:
	#   $1 - state prefix (string)
	local json_var default_json
	json_var=$(state_namespace_json_var "$1")
	default_json='{}'
	printf '%s' "${!json_var:-${default_json}}"
}

state_set_json_document() {
	# Arguments:
	#   $1 - state prefix (string)
	#   $2 - JSON document (string)
	local json_var
	json_var=$(state_namespace_json_var "$1")
	printf -v "${json_var}" '%s' "$2"
}

state_set() {
	# Arguments:
	#   $1 - state prefix (string)
	#   $2 - key (string)
	#   $3 - value (string)
	local prefix key value updated
	prefix="$1"
	key="$2"
	value="$3"
	updated=$(jq -c --arg key "${key}" --arg value "${value}" '.[$key] = $value' <<<"$(state_get_json_document "${prefix}")")
	state_set_json_document "${prefix}" "${updated}"
}

state_get() {
	# Arguments:
	#   $1 - state prefix (string)
	#   $2 - key (string)
	local prefix key
	prefix="$1"
	key="$2"
	jq -r --arg key "${key}" '(.[$key] // "") | (if type == "array" then join("\n") else tostring end)' <<<"$(state_get_json_document "${prefix}")"
}

state_increment() {
	# Arguments:
	#   $1 - state prefix (string)
	#   $2 - key (string)
	#   $3 - increment amount (int, optional; defaults to 1)
	local prefix key increment current updated
	prefix="$1"
	key="$2"
	increment="${3:-1}"
	current="$(state_get_json_document "${prefix}")"
	updated=$(jq -c --arg key "${key}" --argjson inc "${increment}" '.[$key] = ((try (.[$key]|tonumber) catch 0) + $inc)' <<<"${current}")
	state_set_json_document "${prefix}" "${updated}"
}

state_append_history() {
	# Arguments:
	#   $1 - state prefix (string)
	#   $2 - entry to append (string)
	local prefix entry updated
	prefix="$1"
	entry="$2"
	updated=$(jq -c --arg entry "${entry}" '(.history //= []) | .history += [$entry]' <<<"$(state_get_json_document "${prefix}")")
	state_set_json_document "${prefix}" "${updated}"
}
