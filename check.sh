#!/usr/bin/env bash
#
# Content check: the one command to run after editing README.md.
#
# It chains the two single-purpose scripts so a contributor gets a single
# pass/fail for documentation, build and tests together:
#   build.sh -> the manuscript still assembles from the README
#   test.sh  -> the README's code still lints (shellcheck) and passes its tests

main() {
    printf '==> Building manuscript (build.sh)\n'
    ./build.sh || { printf 'build.sh failed\n' >&2; exit 1; }

    printf '==> Linting and testing code (test.sh)\n'
    ./test.sh || exit 1

    printf '\nAll content checks passed.\n'
}

main "$@"
