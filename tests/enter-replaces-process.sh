#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
turm_bin="${TURM_BIN:-$repo_dir/target/debug/turm}"
probe_file="$(mktemp)"
trap 'rm -f -- "$probe_file"' EXIT

command -v expect >/dev/null || {
    echo "SKIP: expect is required for the terminal integration test"
    exit 77
}

export TURM_PARENT_FILE="$probe_file"
export TURM_TEST_PATH="$repo_dir/scripts/mock-slurm/bin:$PATH"
export TURM_TEST_SHELL="$repo_dir/tests/fixtures/record-parent.sh"
export TURM_TEST_BIN="$turm_bin"

expect -c '
log_user 0
set timeout 8
set env(PATH) $env(TURM_TEST_PATH)
set env(SHELL) $env(TURM_TEST_SHELL)
spawn $env(TURM_TEST_BIN) --me
after 1000
send "\r"
expect {
    eof {}
    timeout { puts stderr "FAIL: turm did not exit after Enter"; exit 1 }
}
'

parent="$(tr -d '[:space:]' < "$probe_file")"
if [[ "$parent" == *turm* ]]; then
    echo "FAIL: Enter left turm alive as the launched shell parent: $parent"
    exit 1
fi

echo "PASS: Enter replaced turm; launched shell parent: $parent"
