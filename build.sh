#!/usr/bin/env bash
#
# Turn the single document bible into a book separated by chapters.
#
# The chapter/fence conventions live in lib.sh so that this build and the
# test extraction (test.sh) always agree on what the document looks like.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=lib.sh
source ./lib.sh

main() {
    if ! bible_split_chapters README.md manuscript; then
        printf 'build.sh: README.md structure is invalid; book not built.\n' >&2
        exit 1
    fi
}

main "$@"
