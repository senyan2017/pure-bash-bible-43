#!/usr/bin/env bash
# lib/markdown.sh — Shared Markdown parsing utilities for the pure-bash-bible
# toolchain.  Source this file from build.sh, test.sh, or any script that
# needs to work with the project's Markdown structure.
#
# The pure-bash-bible README.md uses two conventions to organize content:
#
#   1. Chapter markers:  <!-- CHAPTER START --> / <!-- CHAPTER END -->
#      Delimit sections that map to individual manuscript chapters.
#
#   2. Typed code fences: ```sh (tested/linted) vs ```shell (examples only)
#      Only ```sh blocks are extracted for shellcheck and unit testing.
#
# This library centralizes the logic for both conventions so that every
# script agrees on what "a chapter" and "a code block" mean.


# extract_code_blocks <input_file> <output_file>
#
# Read <input_file> (Markdown), find every ```sh ... ``` block, and write
# the concatenated code to <output_file>.  Blocks fenced with ```shell or
# any other language tag are ignored — this matches the project convention
# where ```sh means "linted and tested" and ```shell means "example only".
extract_code_blocks() {
    local input_file="$1"
    local output_file="$2"

    : > "$output_file"

    local in_sh_block=0
    while IFS=$'\n' read -r line; do
        # Start of a ```sh block.
        if [[ "$line" == '```sh' ]]; then
            in_sh_block=1
            continue
        fi

        # End of any fenced block.
        if [[ "$line" == '```' ]]; then
            in_sh_block=0
            continue
        fi

        # Accumulate lines while inside a ```sh block.
        if (( in_sh_block )); then
            printf '%s\n' "$line" >> "$output_file"
        fi
    done < "$input_file"
}


# extract_chapters <input_file> <output_dir>
#
# Read <input_file> (Markdown), split on <!-- CHAPTER START --> /
# <!-- CHAPTER END --> markers, and write each chapter to
# <output_dir>/chapter{N}.txt.  Also writes <output_dir>/Book.txt
# listing the chapter filenames in order (the format Leanpub expects).
#
# The output directory is wiped and recreated on every call so that
# stale chapter files from a previous build never survive.
extract_chapters() {
    local input_file="$1"
    local output_dir="$2"

    rm -rf "$output_dir"
    mkdir -p "$output_dir"

    local -a chapters
    local in_chapter=0
    local i=0

    while IFS=$'\n' read -r line; do
        if [[ "$line" == "<!-- CHAPTER START -->" ]]; then
            in_chapter=1
            chapters[i]=""
            continue
        fi

        if [[ "$line" == "<!-- CHAPTER END -->" ]]; then
            in_chapter=0
            (( i++ ))
            continue
        fi

        if (( in_chapter )); then
            chapters[i]+="$line"$'\n'
        fi
    done < "$input_file"

    # Write each chapter to its own file and build Book.txt.
    : > "$output_dir/Book.txt"
    for idx in "${!chapters[@]}"; do
        printf '%s\n' "${chapters[$idx]}" > "$output_dir/chapter${idx}.txt"
        printf '%s\n' "chapter${idx}.txt" >> "$output_dir/Book.txt"
    done
}
