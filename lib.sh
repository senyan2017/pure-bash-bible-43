#!/usr/bin/env bash
#
# Shared rules for building and testing the Pure Bash Bible.
#
# build.sh and test.sh both source this file so that the document structure
# (chapter markers and fenced code blocks) is defined in exactly ONE place.
# If you change a marker or a fence convention, change it here and both the
# book build and the test extraction stay in sync.
#
# This file is meant to be *sourced*, never executed. The functions below
# return non-zero and print to stderr on failure; the calling script decides
# whether to exit.
#
# shellcheck disable=SC2329  # functions are invoked by build.sh / test.sh.

# --- Structure markers (the single source of truth) -------------------------

# A chapter is everything between these two markers. Each marker must sit on
# its own line and match exactly (after trailing CR/whitespace is normalised).
BIBLE_CHAPTER_START='<!-- CHAPTER START -->'
BIBLE_CHAPTER_END='<!-- CHAPTER END -->'

# Fenced code blocks. A "```sh" block is linted, sourced and unit tested; a
# "```shell" block is documentation only and is ignored by the test harness.
# Every block, of either kind, is closed by a bare "```".
BIBLE_TEST_FENCE='```sh'
BIBLE_FENCE_CLOSE='```'

# Lines are normalised with "${line%$'\r'}" before any marker or fence is
# matched, so CRLF (or a stray CR) is treated exactly like LF everywhere.

# --- Validation (single source of the structural contract) ------------------

# bible_validate <file>
#
# Verify that README structure is well formed *before* anything is built or
# extracted, so a broken chapter marker or code block fails loudly instead of
# silently producing the wrong book or the wrong test input.
#
# Rules enforced:
#   * chapter markers are balanced and never nested;
#   * every fenced code block is closed;
#   * a testable "```sh" block only appears inside a chapter (otherwise it
#     would be tested but never make it into the book - the exact drift this
#     pipeline is meant to prevent);
#   * at least one chapter exists.
#
# Prints a "<file>:<line>: <reason>" diagnostic to stderr and returns 1 on the
# first problem found; returns 0 when the structure is sound.
bible_validate() {
    local file=$1 line lineno=0 chapters=0
    local in_chapter='' in_code=''

    if [[ ! -r $file ]]; then
        printf '%s: cannot read file\n' "$file" >&2
        return 1
    fi

    while IFS= read -r line || [[ -n $line ]]; do
        lineno=$((lineno + 1))
        line=${line%$'\r'}

        # Inside a fenced block only the closing fence is significant; markers
        # written inside code are literal text, not structure.
        if [[ -n $in_code ]]; then
            [[ $line == "$BIBLE_FENCE_CLOSE" ]] && in_code=''
            continue
        fi

        case $line in
            "$BIBLE_CHAPTER_START")
                if [[ -n $in_chapter ]]; then
                    printf '%s:%s: nested "%s" (previous chapter never closed)\n' \
                        "$file" "$lineno" "$BIBLE_CHAPTER_START" >&2
                    return 1
                fi
                in_chapter=1
                ;;
            "$BIBLE_CHAPTER_END")
                if [[ -z $in_chapter ]]; then
                    printf '%s:%s: "%s" without matching "%s"\n' \
                        "$file" "$lineno" "$BIBLE_CHAPTER_END" "$BIBLE_CHAPTER_START" >&2
                    return 1
                fi
                in_chapter=''
                chapters=$((chapters + 1))
                ;;
            "$BIBLE_FENCE_CLOSE")
                printf '%s:%s: closing fence "%s" without an opening fence\n' \
                    "$file" "$lineno" "$BIBLE_FENCE_CLOSE" >&2
                return 1
                ;;
            "$BIBLE_TEST_FENCE")
                if [[ -z $in_chapter ]]; then
                    printf '%s:%s: testable "%s" block outside chapter markers\n' \
                        "$file" "$lineno" "$BIBLE_TEST_FENCE" >&2
                    return 1
                fi
                in_code=1
                ;;
            '```'*)
                # Any other opening fence (e.g. ```shell): valid anywhere, but
                # it must still be closed.
                in_code=1
                ;;
        esac
    done < "$file"

    if [[ -n $in_code ]]; then
        printf '%s: unterminated code fence (missing closing "%s")\n' \
            "$file" "$BIBLE_FENCE_CLOSE" >&2
        return 1
    fi
    if [[ -n $in_chapter ]]; then
        printf '%s: unterminated chapter (missing "%s")\n' \
            "$file" "$BIBLE_CHAPTER_END" >&2
        return 1
    fi
    if (( chapters == 0 )); then
        printf '%s: no chapters found (expected "%s" ... "%s")\n' \
            "$file" "$BIBLE_CHAPTER_START" "$BIBLE_CHAPTER_END" >&2
        return 1
    fi
    return 0
}

# --- Code extraction (used by test.sh) --------------------------------------

# bible_extract_code <file>
#
# Print, to stdout, the contents of every testable "```sh" block that lives
# inside a chapter. Validation runs first, so this only ever sees well-formed
# input and the extracted code matches what build.sh puts into the book.
# Trailing CRs are stripped so CRLF documents source cleanly.
bible_extract_code() {
    local file=$1 line
    local in_chapter='' in_code='' emit=''

    bible_validate "$file" || return 1

    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}

        if [[ -n $in_code ]]; then
            if [[ $line == "$BIBLE_FENCE_CLOSE" ]]; then
                in_code='' emit=''
                continue
            fi
            [[ -n $emit ]] && printf '%s\n' "$line"
            continue
        fi

        case $line in
            "$BIBLE_CHAPTER_START") in_chapter=1 ;;
            "$BIBLE_CHAPTER_END")   in_chapter='' ;;
            "$BIBLE_TEST_FENCE")    in_code=1 emit=1 ;;
            '```'*)                 in_code=1 emit='' ;;
        esac
    done < "$file"
}

# --- Chapter splitting (used by build.sh) -----------------------------------

# bible_split_chapters <file> <outdir>
#
# Split <file> into one file per chapter inside <outdir> and write a Leanpub
# style Book.txt index. Validation runs first so the same structural contract
# guards the book build and the test extraction. Trailing CRs are normalised.
bible_split_chapters() {
    local file=$1 outdir=$2 line i=0 n chapter_open=''
    local -a chapter=()

    bible_validate "$file" || return 1

    rm -rf "$outdir"
    mkdir -p "$outdir"

    while IFS= read -r line || [[ -n $line ]]; do
        line=${line%$'\r'}
        [[ -n $chapter_open ]] && chapter[i]+="$line"$'\n'
        [[ $line == "$BIBLE_CHAPTER_START" ]] && chapter_open=1
        [[ $line == "$BIBLE_CHAPTER_END" ]]   && { chapter_open=''; i=$((i + 1)); }
    done < "$file"

    for n in "${!chapter[@]}"; do
        printf '%s\n' "${chapter[n]}" > "$outdir/chapter$n.txt"
        printf '%s\n' "chapter$n.txt" >> "$outdir/Book.txt"
    done
}
