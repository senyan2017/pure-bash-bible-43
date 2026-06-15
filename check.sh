#!/usr/bin/env bash
#
# check.sh — One-command validation for the pure-bash-bible.
#
# Runs every validation step in the right order and reports an overall
# pass/fail result at the end.  Use this after editing README.md (or any
# snippet) to make sure the manuscript, lint, and tests all still agree.
#
# Steps executed:
#   1. build.sh  — regenerate manuscript/chapter*.txt from README.md
#   2. test.sh   — extract code, run shellcheck, run unit tests
#
# Exit code:
#   0 — everything passed
#   1 — at least one step failed (the first failure stops the pipeline)
#
# Usage:
#     ./check.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() {
    local label="$1"
    local cmd="$2"

    printf '\n== %s ==\n' "$label"
    if "$cmd"; then
        printf '   ✔ %s passed\n' "$label"
    else
        printf '   ✖ %s FAILED\n' "$label"
        exit 1
    fi
}

step "Build manuscript"  "$SCRIPT_DIR/build.sh"
step "Lint & test"       "$SCRIPT_DIR/test.sh"

printf '\n== All checks passed ==\n'
