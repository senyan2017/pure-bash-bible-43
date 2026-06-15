#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2329
#
# Shared parsing rules for the Pure Bash Bible toolchain.
#
# This file is the SINGLE SOURCE OF TRUTH for how README.md is structured.
# Source it (". ./lib.sh"); do not execute it. build.sh and test.sh both rely
# on the extractors below, so a Markdown rule only ever needs to change here.
#
# SC2329 is disabled file-wide because the functions are this library's public
# API: they are invoked by the scripts that source it, never from within.

# Document to parse. Override with "README=other.md" when testing the tooling.
readme="${README:-README.md}"

# Markers that delimit a manuscript chapter inside the README.
chapter_start="<!-- CHAPTER START -->"
chapter_end="<!-- CHAPTER END -->"

# Fenced-code language that marks a block as real, maintained code:
#   ```sh    -> linted by shellcheck and unit-tested (extracted by extract_code)
#   ```shell -> documentation only, ignored by the toolchain
code_lang="sh"

# Print every ```sh code block in the README to stdout. These are the blocks
# the toolchain lints with shellcheck and sources to run the unit tests.
extract_code() {
    local line code
    while IFS=$'\n' read -r line; do
        [[ "$code" && "$line" != '```' ]] && printf '%s\n' "$line"
        [[ "$line" == '```'"$code_lang" ]] && code=1
        [[ "$line" == '```' ]]             && code=
    done < "$readme"
}

# Print each CHAPTER START/END region to stdout, NUL-separated so a chapter may
# safely contain blank lines. build.sh turns each region into a chapter file.
extract_chapters() {
    local line chap chapter
    while IFS=$'\n' read -r line; do
        [[ "$chap" ]] && chapter+="$line"$'\n'
        [[ "$line" == "$chapter_start" ]] && chap=1
        [[ "$line" == "$chapter_end" ]]   && { chap=; printf '%s\0' "$chapter"; chapter=; }
    done < "$readme"
}
