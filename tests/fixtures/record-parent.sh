#!/usr/bin/env bash
set -euo pipefail

: "${TURM_PARENT_FILE:?TURM_PARENT_FILE must be set}"
ps -o comm= -p "$PPID" > "$TURM_PARENT_FILE"
