#!/usr/bin/env bats
#
# Regression tests for planner examples integration.
#
# Usage:
#   bats tests/planner/test_planner_examples.sh
#
# Dependencies:
#   - bats
#   - bash 3.2+

@test "planner prompt threads examples into dynamic suffix" {
	run bash -lc "$(
		cat <<'INNERSCRIPT'
set -euo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

source ./src/lib/prompt/build_planner.sh

current_date_local() { printf '2024-01-01'; }
current_time_local() { printf '12:00'; }
current_weekday_local() { printf 'Monday'; }
load_schema_text() { printf '{}'; }

suffix="$(build_planner_prompt_dynamic_suffix 'What changed?' 'terminal' 'Search context unavailable.')"

[[ "${suffix}" == *"# Planner examples"* ]]
[[ "${suffix}" == *"Summarize the latest okso release notes."* ]]
INNERSCRIPT
	)"
	[ "$status" -eq 0 ]
}

@test "planner prompt renders without examples file" {
	run bash -lc "$(
		cat <<'INNERSCRIPT'
set -euo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1

tmp_prompts="$(mktemp -d)"
cp ./src/prompts/planner.txt "${tmp_prompts}/planner.txt"

source ./src/lib/prompt/build_planner.sh

PROMPTS_DIR="${tmp_prompts}"
current_date_local() { printf '2024-01-01'; }
current_time_local() { printf '12:00'; }
current_weekday_local() { printf 'Monday'; }
load_schema_text() { printf '{}'; }

suffix="$(build_planner_prompt_dynamic_suffix 'What changed?' 'terminal' 'Search context unavailable.')"

[[ "${suffix}" == *"# Planner examples"* ]]
[[ "${suffix}" != *'${planner_examples}'* ]]
INNERSCRIPT
	)"
	[ "$status" -eq 0 ]
}
