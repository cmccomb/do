#!/usr/bin/env bats

setup() {
	export DO_VERBOSITY=0
	export DO_SUPERVISED=false
}

@test "shows help text" {
	run ./src/main.sh --help -- "example query"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Usage: ./src/main.sh"* ]]
}

@test "prints version" {
	run ./src/main.sh --version -- "query"
	[ "$status" -eq 0 ]
	[[ "$output" == *"do assistant"* ]]
}

@test "runs planner in unsupervised mode" {
	run ./src/main.sh --unsupervised -- "note something"
	[ "$status" -eq 0 ]
	[[ "$output" == *"Suggested tools"* ]]
	[[ "$output" == *"notes executed"* ]]
}

@test "records tool transcript to log directory" {
	local log_dir
	log_dir="${BATS_TMPDIR}/logs"
	mkdir -p "${log_dir}"

	run env DO_LOG_DIR="${log_dir}" DO_VERBOSITY=0 DO_SUPERVISED=false ./src/main.sh --unsupervised -- "note something"
	[ "$status" -eq 0 ]

	log_file=$(ls "${log_dir}"/*.log | head -n1)
	[ -f "${log_file}" ]
	grep -q "Execution summary" "${log_file}"
	grep -q "notes" "${log_file}"
}

@test "offers approval list in supervised mode" {
	local log_dir
	log_dir="${BATS_TMPDIR}/logs-supervised"
	mkdir -p "${log_dir}"

	run env DO_SUPERVISED=true DO_LOG_DIR="${log_dir}" DO_VERBOSITY=0 bash -c 'printf "1\n" | ./src/main.sh --supervised -- "notes"'
	[ "$status" -eq 0 ]
	[[ "$output" == *"Proposed tool calls:"* ]]
	[[ "$output" == *"[notes executed]"* ]]

	log_file=$(ls "${log_dir}"/*.log | head -n1)
	[ -f "${log_file}" ]
	grep -q "Approval selection" "${log_file}"
}

@test "allows skipping all tools" {
	local log_dir
	log_dir="${BATS_TMPDIR}/logs-skip"
	mkdir -p "${log_dir}"

	run env DO_SUPERVISED=true DO_LOG_DIR="${log_dir}" DO_VERBOSITY=0 bash -c 'printf "skip\n" | ./src/main.sh --supervised -- "notes"'
	[ "$status" -eq 0 ]
	[[ "$output" == *"[no tools executed]"* ]]

	log_file=$(ls "${log_dir}"/*.log | head -n1)
	[ -f "${log_file}" ]
	grep -q "Approval selection" "${log_file}"
	grep -q "skip" "${log_file}"
}
