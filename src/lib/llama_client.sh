#!/usr/bin/env bash
# shellcheck shell=bash
#
# llama.cpp client helpers for local inference.
#
# Usage:
#   source "${BASH_SOURCE[0]%/llama_client.sh}/llama_client.sh"
#
# Environment variables:
#   LLAMA_AVAILABLE (bool): whether llama.cpp is available for inference.
#   LLAMA_BIN (string): path to llama.cpp binary.
#   MODEL_REPO (string): Hugging Face repository name.
#   MODEL_FILE (string): model file within the repository.
#   VERBOSITY (int): log verbosity.
#
# Dependencies:
#   - bash 5+
#   - jq
#
# Exit codes:
#   Returns non-zero when llama.cpp is unavailable; otherwise mirrors llama.cpp.

# shellcheck source=../logging.sh disable=SC1091
source "${BASH_SOURCE[0]%/llama_client.sh}/../logging.sh"

llama_infer() {
	# Runs llama.cpp with HF caching enabled for the configured model.
	# Arguments:
	#   $1 - prompt string
	#   $2 - stop string (optional)
	#   $3 - max tokens (optional)
	#   $4 - grammar file path (optional)
	local prompt stop_string number_of_tokens grammar_file_path
	prompt="$1"
	stop_string="${2:-}"
	number_of_tokens="${3:-256}"
	grammar_file_path="${4:-}"

	if [[ "${LLAMA_AVAILABLE}" != true ]]; then
		log "WARN" "llama unavailable; skipping inference" "LLAMA_AVAILABLE=${LLAMA_AVAILABLE}"
		return 1
	fi

	local additional_args
	additional_args=()

	if [[ -n "${grammar_file_path}" ]]; then
		if [[ "${grammar_file_path}" == *.json ]]; then
			additional_args+=(--json-schema-file "${grammar_file_path}")
		else
			additional_args+=(--grammar-file "${grammar_file_path}")
		fi
	fi

	if [[ -n "${stop_string}" ]]; then
		"${LLAMA_BIN}" \
			--hf-repo "${MODEL_REPO}" \
			--hf-file "${MODEL_FILE}" \
			-no-cnv --no-display-prompt --simple-io --verbose -r "${stop_string}" \
			-n "${number_of_tokens}" \
			-p "${prompt}" \
			"${additional_args[@]}" 2>/dev/null || true
		return
	fi

	"${LLAMA_BIN}" \
		--hf-repo "${MODEL_REPO}" \
		--hf-file "${MODEL_FILE}" \
		-n "${number_of_tokens}" \
		-no-cnv --no-display-prompt --simple-io --verbose \
		-p "${prompt}" \
		"${additional_args[@]}" 2>/dev/null || true
}
