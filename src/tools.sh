#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034
#
# Tool registration and handlers for the do assistant CLI.
#
# Usage:
#   source "${BASH_SOURCE[0]%/tools.sh}/tools.sh"
#
# Environment variables:
#   NOTES_DIR (string): location to store notes; defaults set by caller.
#   TOOL_QUERY (string): populated before handler execution.
#
# Dependencies:
#   - bash 5+
#   - coreutils (ls, pwd)
#
# Exit codes:
#   Functions emit errors via log and return non-zero when misused.

# shellcheck source=./logging.sh disable=SC1091
source "${BASH_SOURCE[0]%/tools.sh}/logging.sh"

# shellcheck disable=SC2034
declare -A TOOL_DESCRIPTION=()
declare -A TOOL_COMMAND=()
declare -A TOOL_SAFETY=()
declare -A TOOL_HANDLER=()
TOOLS=()

init_tool_registry() {
	TOOL_DESCRIPTION=()
	TOOL_COMMAND=()
	TOOL_SAFETY=()
	TOOL_HANDLER=()
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
	TOOLS+=("${name}")
	TOOL_DESCRIPTION["${name}"]="$2"
	TOOL_COMMAND["${name}"]="$3"
	TOOL_SAFETY["${name}"]="$4"
	TOOL_HANDLER["${name}"]="${5:-}"
}

tool_os_nav() {
	log "INFO" "Running OS navigation" "Listing working directory"
	pwd
	ls -la
}

tool_file_search() {
	local query
	query=${TOOL_QUERY:-""}
	log "INFO" "Searching files" "${query}"

	if command -v fd >/dev/null 2>&1; then
		fd --hidden --color=never --max-depth 5 "${query:-.}" . || true
	else
		find . -maxdepth 5 -iname "*${query}*" || true
	fi

	if command -v rg >/dev/null 2>&1 && [[ -n "${query}" ]]; then
		rg --line-number --hidden --color=never "${query}" || true
	fi
}

tool_notes() {
	local query note_file
	query=${TOOL_QUERY:-""}
	note_file="${NOTES_DIR}/notes.txt"
	log "INFO" "Appending reminder" "${query}"
	printf '%s\t%s\n' "$(date -Iseconds)" "${query}" >>"${note_file}"
	printf 'Saved note to %s\n' "${note_file}"
}

tool_mail_stub() {
	local query
	query=${TOOL_QUERY:-""}
	log "INFO" "Mail stub invoked" "${query}"
	printf 'Mail delivery not configured. Draft preserved for review: %s\n' "${query}"
}

tool_applescript() {
	local query
	query=${TOOL_QUERY:-""}
	if [[ "${IS_MACOS}" != true ]]; then
		log "WARN" "AppleScript not available on this platform" "${query}"
		return 0
	fi

	if ! command -v osascript >/dev/null 2>&1; then
		log "WARN" "osascript missing; cannot execute AppleScript" "${query}"
		return 0
	fi

	log "INFO" "Executing AppleScript" "${query}"
	osascript -e "${query}"
}

initialize_tools() {
	register_tool \
		"os_nav" \
		"Inspect the current working directory contents." \
		"pwd && ls -la" \
		"Read-only visibility of local filesystem." \
		tool_os_nav

	register_tool \
		"file_search" \
		"Search project files by name and content using fd/rg." \
		"fd or find combined with ripgrep." \
		"May read many files; avoid leaking secrets." \
		tool_file_search

	register_tool \
		"notes" \
		"Persist reminders or notes under ~/.do for future runs." \
		"printf '<note>' >> ~/.do/notes.txt" \
		"Stores user-provided text locally; confirm contents." \
		tool_notes

	register_tool \
		"mail_stub" \
		"Prepare an email draft for later delivery." \
		"cat > /tmp/mcp_mail_draft.txt" \
		"Does not send mail; safe placeholder." \
		tool_mail_stub

	register_tool \
		"applescript" \
		"Execute AppleScript snippets on macOS." \
		"osascript -e '<script>'" \
		"Only available on macOS; disabled elsewhere." \
		tool_applescript
}
