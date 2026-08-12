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
export TURM_TEST_PATH="$repo_dir/tests/fixtures/mock-bin:$repo_dir/scripts/mock-slurm/bin:$PATH"
export TURM_TEST_BIN="$turm_bin"

expect -c '
log_user 0
set timeout 8
set env(PATH) $env(TURM_TEST_PATH)
spawn $env(TURM_TEST_BIN) --me
after 1000
send "n"
expect {
    "__TURM_SSH_DONE__" {}
    timeout { puts stderr "FAIL: mock ssh did not run"; exit 1 }
}
expect {
    "\033\[?1049l" {}
    timeout { puts stderr "FAIL: terminal was not restored after node monitor"; exit 1 }
}
'

parent="$(sed -n '1p' "$probe_file" | tr -d '[:space:]')"
if [[ "$parent" == *turm* ]]; then
    echo "FAIL: node monitor left turm alive as ssh parent"
    sed -n '1,4p' "$probe_file"
    exit 1
fi

echo "PASS: node monitor replaced turm; ssh parent: $parent"
