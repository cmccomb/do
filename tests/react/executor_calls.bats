#!/usr/bin/env bats

setup() {
	unset -f chpwd _mise_hook 2>/dev/null || true
}

@test "format_tool_args builds executor payloads" {
	run bash <<'SCRIPT'
set -euo pipefail
source ./src/lib/react/loop.sh

terminal_args=$(format_tool_args "terminal" "echo hi --flag")
final_args=$(CANONICAL_TEXT_ARG_KEY="message" format_tool_args "final_answer" "all good")

jq -e '(.command == "echo") and (.args == ["hi","--flag"])' <<<"${terminal_args}"
jq -e '.message == "all good"' <<<"${final_args}"
SCRIPT

	[ "$status" -eq 0 ]
}

@test "apply_plan_arg_controls imputes missing executor args" {
	run bash <<'SCRIPT'
set -euo pipefail
source ./src/lib/react/loop.sh

# Override tool schema lookup to avoid global registry dependencies.
tool_args_schema() {
        printf '{"properties":{"title":{"type":"string"},"body":{"type":"string"}},"required":["title","body"],"additionalProperties":false}'
}

plan_entry='{"tool":"notes_create","args":{"title":"Planner Title","body":"Original body"},"args_control":{"title":"locked","body":"context"}}'
executor_args='{"title":"User Title","body":"__MISSING__"}'
user_query='Provide meeting summary'

resolved=$(apply_plan_arg_controls "notes_create" "${executor_args}" "${plan_entry}" "${user_query}" "__MISSING__")
jq -r '.title,.body' <<<"${resolved}"
SCRIPT

	[ "$status" -eq 0 ]
	[ "${lines[0]}" = "Planner Title" ]
	[ "${lines[1]}" = "Provide meeting summary" ]
}

@test "execute_tool_with_query surfaces handler failures without aborting" {
	run bash <<'SCRIPT'
set -euo pipefail
source ./src/lib/exec/dispatch.sh

log() { :; }
APPROVE_ALL=true
PLAN_ONLY=false
DRY_RUN=false
FORCE_CONFIRM=false

tool_handler() { printf 'failing_handler'; }
failing_handler() { echo "simulated stderr" 1>&2; return 23; }

payload=$(execute_tool_with_query "demo" "describe" "context" '{"foo":1}')
status=$?
exit_code=$(jq -r '.exit_code' <<<"${payload}")
error_body=$(jq -r '.error' <<<"${payload}")

printf 'status=%s exit=%s error=%s' "${status}" "${exit_code}" "${error_body}"
SCRIPT

	[ "$status" -eq 0 ]
	[[ "$output" == *"status=0"* ]]
	[[ "$output" == *"exit=23"* ]]
	[[ "$output" == *"simulated stderr"* ]]
}
