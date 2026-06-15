#!/usr/bin/env bash
#
# Build step: turn the single README.md into a per-chapter manuscript.
#
# Responsibility: lay the chapters out on disk. *Where* a chapter begins and
# ends is defined once in lib.sh (the CHAPTER markers); this script never
# parses Markdown itself.

# shellcheck source=lib.sh
. ./lib.sh

main() {
    rm -rf manuscript
    mkdir -p manuscript

    local i=0 chapter
    while IFS= read -r -d '' chapter; do
        printf '%s\n' "$chapter"        > "manuscript/chapter${i}.txt"
        printf '%s\n' "chapter${i}.txt" >> manuscript/Book.txt
        ((i+=1))
    done < <(extract_chapters)
}

main "$@"
