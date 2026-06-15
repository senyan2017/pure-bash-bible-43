#!/usr/bin/env bash
#
# Turn the single document bible into a book separated by chapters.
#
# Requirements:
#   - README.md must exist in the current directory.
#   - Chapters are delimited by exact marker lines:
#       <!-- CHAPTER START -->
#       <!-- CHAPTER END -->
#   - Markers must appear at column 0 with no extra leading whitespace.
#   - Every START marker must have a matching END marker.
#
set -euo pipefail

CHAPTER_START_MARKER='<!-- CHAPTER START -->'
CHAPTER_END_MARKER='<!-- CHAPTER END -->'
README='README.md'
OUTPUT_DIR='manuscript'

main() {
    if [[ ! -f "$README" ]]; then
        printf 'error: %s not found.\n' "$README" >&2
        exit 1
    fi

    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"

    local i=0
    local chap=
    local start_count=0
    local end_count=0
    # Use an array to accumulate chapter content.
    declare -a chapter=()

    # Strip CR to handle CRLF line endings transparently.
    while IFS=$'\n' read -r line || [[ -n "$line" ]]; do
        # Strip trailing CR for CRLF tolerance.
        line="${line%$'\r'}"

        if [[ "$line" == "$CHAPTER_START_MARKER" ]]; then
            chap=1
            ((start_count++)) || true
            continue
        fi

        if [[ "$line" == "$CHAPTER_END_MARKER" ]]; then
            if [[ -z "$chap" ]]; then
                printf 'error: END marker without matching START at approximate line.\n' >&2
                exit 1
            fi
            chap=
            ((end_count++)) || true
            ((i++)) || true
            continue
        fi

        if [[ -n "$chap" ]]; then
            chapter[$i]+="$line"$'\n'
        fi
    done < "$README"

    # Validate marker pairing.
    if ((start_count != end_count)); then
        printf 'error: Mismatched chapter markers in %s.\n' "$README" >&2
        printf '  Found %d START markers and %d END markers.\n' \
            "$start_count" "$end_count" >&2
        exit 1
    fi

    # Validate at least one chapter was found.
    if ((start_count == 0)); then
        printf 'error: No chapter markers found in %s.\n' "$README" >&2
        printf '  Expected at least one pair of:\n' >&2
        printf '    %s\n' "$CHAPTER_START_MARKER" >&2
        printf '    %s\n' "$CHAPTER_END_MARKER" >&2
        exit 1
    fi

    # Detect unclosed chapter (START without END).
    if [[ -n "${chap:-}" ]]; then
        printf 'error: Last chapter has START marker but no END marker.\n' >&2
        exit 1
    fi

    # Write the chapters to separate files.
    for idx in "${!chapter[@]}"; do
        local content="${chapter[$idx]}"

        # Validate chapter is not empty.
        if [[ -z "${content//[$'\n ']}" ]]; then
            printf 'error: Chapter %d is empty.\n' "$idx" >&2
            exit 1
        fi

        printf '%s' "$content" > "${OUTPUT_DIR}/chapter${idx}.txt"
        printf '%s\n' "chapter${idx}.txt" >> "${OUTPUT_DIR}/Book.txt"
    done

    printf 'Build complete: %d chapters written to %s/.\n' \
        "$start_count" "$OUTPUT_DIR"
}

main "$@"
