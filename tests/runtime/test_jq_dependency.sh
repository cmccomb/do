#!/usr/bin/env bats

@test "runtime guard emits structured error when jq is missing" {
        run bash --noprofile --norc -c '
                temp_path="$(mktemp -d)"
                ln -s /bin/dirname "${temp_path}/dirname"
                PATH="${temp_path}"
                export PATH
                source ./src/lib/runtime.sh
        '

        [ "$status" -ne 0 ]
        [ "$output" = '{"name":"runtime","category":"dependency","message":"Missing jq dependency. Install jq with your package manager (e.g., apt-get install jq or brew install jq) and re-run."}' ]
}
