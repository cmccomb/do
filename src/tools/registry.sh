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
#   - jq
#   - logging helpers from logging.sh
#
# Exit codes:
#   Functions emit errors via log and return non-zero when misused.

# shellcheck source=../lib/logging.sh disable=SC1091
source "${BASH_SOURCE[0]%/tools/registry.sh}/lib/logging.sh"

default_tool_registry_json() {
	printf '%s' '{"names":[],"registry":{}}'
}

: "${CANONICAL_TEXT_ARG_KEY:=input}"

canonical_text_arg_key() {
	printf '%s' "${CANONICAL_TEXT_ARG_KEY}"
}

tool_registry_json() {
	printf '%s' "${TOOL_REGISTRY_JSON:-$(default_tool_registry_json)}"
}

tool_names() {
	jq -r '.names[]?' <<<"$(tool_registry_json)"
}

tool_description() {
	local name
	name="$1"
	jq -r --arg name "${name}" '.registry[$name].description // ""' <<<"$(tool_registry_json)"
}

tool_command() {
	local name
	name="$1"
	jq -r --arg name "${name}" '.registry[$name].command // ""' <<<"$(tool_registry_json)"
}

tool_safety() {
	local name
	name="$1"
	jq -r --arg name "${name}" '.registry[$name].safety // ""' <<<"$(tool_registry_json)"
}

tool_handler() {
	local name
	name="$1"
	jq -r --arg name "${name}" '.registry[$name].handler // ""' <<<"$(tool_registry_json)"
}

tool_args_schema() {
	local name
	name="$1"
	jq -c --arg name "${name}" '.registry[$name].args_schema // {}' <<<"$(tool_registry_json)"
}

init_tool_registry() {
	TOOL_REGISTRY_JSON="$(default_tool_registry_json)"
}

default_args_schema() {
	local text_key
	text_key="$(canonical_text_arg_key)"
	jq -nc --arg key "${text_key}" '{"type":"object","properties":{($key):{"type":"string"}},"additionalProperties":{"type":"string"}}'
}

validate_args_schema() {
	local args_schema text_key
	args_schema="$1"
	text_key="$(canonical_text_arg_key)"

	if ! jq -e --arg key "${text_key}" '
	(. | type) == "object" and
	(if
	(.type == "object") and
	(.properties | type == "object") and
	([.properties|keys[]] | length == 1) and
	((.properties|values[]|.type) as $types | ($types == "string"))
	then
	(.properties|keys[] | .) == $key
	else
	true
	end)
	' <<<"${args_schema}" >/dev/null 2>&1; then
	log "ERROR" "Invalid args schema" "${args_schema}" || true
	return 1
	fi
}

validate_tool_name() {
	local name
	name="$1"
	if [[ ! "${name}" =~ ^[a-z0-9_]+$ ]]; then
		log "ERROR" "tool names must be alphanumeric with underscores" "${name}" || true
		return 1
	fi
}

update_tool_registry_json() {
	local registry_json name description command safety handler args_schema
	registry_json="$1"
	name="$2"
	description="$3"
	command="$4"
	safety="$5"
	handler="$6"
	args_schema="$7"
	
	jq -c \
	--arg name "${name}" \
	--arg description "${description}" \
	--arg command "${command}" \
	--arg safety "${safety}" \
	--arg handler "${handler}" \
	--argjson args_schema "${args_schema}" \
	'(.names //= [])
	| (.registry //= {})
	| (if (.names | index($name)) == null then .names += [$name] else . end)
	| .registry[$name] = {description:$description, command:$command, safety:$safety, handler:$handler, args_schema:$args_schema}' <<<"${registry_json}"
}

register_tool() {
	# Arguments:
	#   $1 - name
	#   $2 - description
	#   $3 - invocation command (string)
	#   $4 - safety notes
	#   $5 - handler function name
	#   $6 - optional JSON schema describing args
	if [[ $# -lt 5 ]]; then
		log "ERROR" "register_tool requires five arguments" "$*"
		return 1
	fi

	local name args_schema
	name="$1"
	args_schema="${6:-$(default_args_schema)}"

	if ! validate_args_schema "${args_schema}"; then
		return 1
	fi

	if ! validate_tool_name "${name}"; then
		return 1
	fi

	TOOL_REGISTRY_JSON=$(update_tool_registry_json "$(tool_registry_json)" "$@" "${args_schema}")
}
