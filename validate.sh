#!/usr/bin/env bash
#
# Validate the structural integrity of README.md.
#
# Checks:
#   - Chapter markers are properly paired (START before END, no nesting).
#   - Code blocks are properly opened and closed.
#   - No CRLF line endings (which can silently break marker matching).
#   - No empty ```sh code blocks.
#   - At least one chapter and one code block exist.
#   - Every chapter contains at least one non-whitespace line.
#   - No stray ``` closing markers outside of code blocks.
#
# Exit codes:
#   0 - All checks passed.
#   1 - One or more checks failed.
#
set -euo pipefail

README='README.md'

main() {
    local errors=0
    local lineno=0
    local in_chapter=0
    local chapter_starts=0
    local chapter_ends=0
    local empty_chapters=0
    local chapter_has_content=0
    local in_code_block=0
    local code_block_start=0
    local sh_blocks=0
    local other_blocks=0
    local empty_sh_blocks=0
    local code_block_has_content=0
    local crlf_count=0

    if [[ ! -f "$README" ]]; then
        printf 'error: %s not found.\n' "$README" >&2
        exit 1
    fi

    while IFS=$'\n' read -r line || [[ -n "$line" ]]; do
        ((lineno++)) || true

        # --- Check for CRLF line endings ---
        if [[ "$line" == *$'\r' ]]; then
            ((crlf_count++)) || true
            line="${line%$'\r'}"
        fi

        # --- Chapter marker checks ---
        if [[ "$line" == '<!-- CHAPTER START -->' ]]; then
            if ((in_chapter)); then
                printf 'error: Nested CHAPTER START at line %d (previous START had no END).\n' \
                    "$lineno" >&2
                ((errors++)) || true
            fi
            in_chapter=1
            chapter_has_content=0
            ((chapter_starts++)) || true
            continue
        fi

        if [[ "$line" == '<!-- CHAPTER END -->' ]]; then
            if ((! in_chapter)); then
                printf 'error: CHAPTER END at line %d without matching START.\n' \
                    "$lineno" >&2
                ((errors++)) || true
            else
                if ((! chapter_has_content)); then
                    ((empty_chapters++)) || true
                    printf 'error: Chapter ending at line %d is empty.\n' \
                        "$lineno" >&2
                    ((errors++)) || true
                fi
            fi
            in_chapter=0
            ((chapter_ends++)) || true
            continue
        fi

        # Track whether current chapter has real content.
        if ((in_chapter)) && [[ -n "${line// /}" ]]; then
            chapter_has_content=1
        fi

        # --- Code block checks ---
        if ((in_code_block)); then
            if [[ "$line" == '```' ]]; then
                # Closing a code block.
                if ((in_code_block == 1)); then
                    # Was a ```sh block.
                    if ((! code_block_has_content)); then
                        ((empty_sh_blocks++)) || true
                        printf 'warning: Empty ```sh code block at line %d (opened at line %d).\n' \
                            "$lineno" "$code_block_start" >&2
                    fi
                fi
                in_code_block=0
                code_block_has_content=0
            else
                code_block_has_content=1
            fi
        else
            if [[ "$line" == '```sh' ]]; then
                in_code_block=1
                code_block_start=$lineno
                code_block_has_content=0
                ((sh_blocks++)) || true
            elif [[ "$line" =~ ^\`\`\`.+ ]]; then
                # Some other fenced block (```shell, ```bash, etc.)
                in_code_block=2
                code_block_start=$lineno
                code_block_has_content=0
                ((other_blocks++)) || true
            elif [[ "$line" == '```' ]]; then
                # Stray closing marker outside any block.
                printf 'error: Stray ``` at line %d (no open code block).\n' \
                    "$lineno" >&2
                ((errors++)) || true
            fi
        fi

    done < "$README"

    # --- Post-scan summary checks ---

    if ((crlf_count > 0)); then
        printf 'error: Found %d line(s) with CRLF (\\r\\n) endings.\n' \
            "$crlf_count" >&2
        printf '  Convert to Unix line endings (LF only) to avoid silent marker mismatches.\n' >&2
        ((errors++)) || true
    fi

    if ((chapter_starts == 0)); then
        printf 'error: No <!-- CHAPTER START --> markers found.\n' >&2
        ((errors++)) || true
    fi

    if ((chapter_starts != chapter_ends)); then
        printf 'error: Mismatched chapter markers: %d START vs %d END.\n' \
            "$chapter_starts" "$chapter_ends" >&2
        ((errors++)) || true
    fi

    if ((in_chapter)); then
        printf 'error: Last chapter is not closed (START without END).\n' >&2
        ((errors++)) || true
    fi

    if ((in_code_block == 1)); then
        printf 'error: Unclosed ```sh code block (opened at line %d).\n' \
            "$code_block_start" >&2
        ((errors++)) || true
    elif ((in_code_block == 2)); then
        printf 'error: Unclosed code block (opened at line %d).\n' \
            "$code_block_start" >&2
        ((errors++)) || true
    fi

    if ((sh_blocks == 0)); then
        printf 'error: No ```sh code blocks found in %s.\n' "$README" >&2
        printf '  test.sh requires at least one ```sh block with testable code.\n' >&2
        ((errors++)) || true
    fi

    # --- Report ---
    printf '\n'
    printf 'Validation Summary\n'
    printf '==================\n'
    printf '  Chapters:            %d\n' "$chapter_starts"
    printf '  ```sh code blocks:   %d\n' "$sh_blocks"
    printf '  Other code blocks:   %d\n' "$other_blocks"
    printf '  CRLF lines:          %d\n' "$crlf_count"
    printf '  Empty sh blocks:     %d\n' "$empty_sh_blocks"
    printf '\n'

    if ((errors > 0)); then
        printf 'FAILED: %d error(s) found.\n' "$errors"
        exit 1
    fi

    printf 'OK: All structural checks passed.\n'
    exit 0
}

main "$@"
