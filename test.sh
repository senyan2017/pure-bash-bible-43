#!/usr/bin/env bash
# shellcheck source=/dev/null disable=SC2178,SC2128
#
# Tests for the Pure Bash Bible.
#
# This script:
#   1. Extracts ```sh code blocks from README.md into a temp file.
#   2. Runs shellcheck (if available) on the extracted code + test.sh + build.sh.
#   3. Sources the extracted code and runs all test_* functions defined below.
#
# Code block conventions (MUST be followed in README.md):
#   - ```sh   => testable code (linted by shellcheck, sourced for tests)
#   - ```shell => example/illustration only (ignored by this script)
#   - Closing ``` MUST be on its own line with no language specifier.
#
set -o pipefail
# NOTE: We do NOT use set -e because ((arith)) returning 0 would cause
# spurious exits.  We also avoid set -u because the extracted README code
# (documentation snippets) may use variables without prior initialization.
# Errors are handled explicitly throughout.

README='README.md'

# --- Test functions ---------------------------------------------------------

test_trim_string() {
    result="$(trim_string "    Hello,    World    ")"
    assert_equals "$result" "Hello,    World"
}

test_trim_all() {
    result="$(trim_all "    Hello,    World    ")"
    assert_equals "$result" "Hello, World"
}

test_regex() {
    result="$(regex "#FFFFFF" '^(#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3}))$')"
    assert_equals "$result" "#FFFFFF"
}

test_lower() {
    result="$(lower "HeLlO")"
    assert_equals "$result" "hello"
}

test_upper() {
    result="$(upper "HeLlO")"
    assert_equals "$result" "HELLO"
}

test_reverse_case() {
    result="$(reverse_case "HeLlO")"
    assert_equals "$result" "hElLo"
}

test_trim_quotes() {
    result="$(trim_quotes "\"te'st' 'str'ing\"")"
    assert_equals "$result" "test string"
}

test_strip_all() {
    result="$(strip_all "The Quick Brown Fox" "[aeiou]")"
    assert_equals "$result" "Th Qck Brwn Fx"
}

test_strip() {
    result="$(strip "The Quick Brown Fox" "[aeiou]")"
    assert_equals "$result" "Th Quick Brown Fox"
}

test_lstrip() {
    result="$(lstrip "!:IHello" "!:I")"
    assert_equals "$result" "Hello"
}

test_rstrip() {
    result="$(rstrip "Hello!:I" "!:I")"
    assert_equals "$result" "Hello"
}

test_urlencode() {
    result="$(urlencode "https://github.com/dylanaraps/pure-bash-bible")"
    assert_equals "$result" "https%3A%2F%2Fgithub.com%2Fdylanaraps%2Fpure-bash-bible"
}

test_urldecode() {
    result="$(urldecode "https%3A%2F%2Fgithub.com%2Fdylanaraps%2Fpure-bash-bible")"
    assert_equals "$result" "https://github.com/dylanaraps/pure-bash-bible"
}

test_reverse_array() {
    shopt -s compat44
    IFS=$'\n' read -d "" -ra result < <(reverse_array 1 2 3 4 5)
    assert_equals "${result[*]}" "5 4 3 2 1"
    shopt -u compat44
}

test_cycle() {
    # shellcheck disable=SC2034
    arr=(a b c d)
    result="$(cycle; cycle; cycle)"
    assert_equals "$result" "a b c "
}

test_head() {
    printf '%s\n%s\n\n\n' "hello" "world" > test_file
    result="$(head 2 test_file)"
    assert_equals "$result" $'hello\nworld'
}

test_tail() {
    printf '\n\n\n%s\n%s\n' "hello" "world" > test_file
    result="$(tail 2 test_file)"
    assert_equals "$result" $'hello\nworld'
}

test_lines() {
    printf '\n\n\n\n\n\n\n\n' > test_file
    result="$(lines test_file)"
    assert_equals "$result" "8"
}

test_lines_loop() {
    printf '\n\n\n\n\n\n\n\n' > test_file
    result="$(lines_loop test_file)"
    assert_equals "$result" "8"
}

test_count() {
    result="$(count ./{README.m,LICENSE.m,.travis.ym}*)"
    assert_equals "$result" "3"
}

test_dirname() {
    result="$(dirname "/home/black/Pictures/Wallpapers/1.jpg")"
    assert_equals "$result" "/home/black/Pictures/Wallpapers"

    result="$(dirname "/")"
    assert_equals "$result" "/"

    result="$(dirname "/foo")"
    assert_equals "$result" "/"

    result="$(dirname ".")"
    assert_equals "$result" "."

    result="$(dirname "/foo/foo")"
    assert_equals "$result" "/foo"

    result="$(dirname "something/")"
    assert_equals "$result" "."

    result="$(dirname "//")"
    assert_equals "$result" "/"

    result="$(dirname "//foo")"
    assert_equals "$result" "/"

    result="$(dirname "")"
    assert_equals "$result" "."

    result="$(dirname "something//")"
    assert_equals "$result" "."

    result="$(dirname "something/////////////////////")"
    assert_equals "$result" "."

    result="$(dirname "something/////////////////////a")"
    assert_equals "$result" "something"

    result="$(dirname "something//////////.///////////")"
    assert_equals "$result" "something"

    result="$(dirname "//////")"
    assert_equals "$result" "/"
}

test_basename() {
    result="$(basename "/home/black/Pictures/Wallpapers/1.jpg")"
    assert_equals "$result" "1.jpg"
}

test_hex_to_rgb() {
    result="$(hex_to_rgb "#FFFFFF")"
    assert_equals "$result" "255 255 255"

    result="$(hex_to_rgb "000000")"
    assert_equals "$result" "0 0 0"
}

test_rgb_to_hex() {
    result="$(rgb_to_hex 0 0 0)"
    assert_equals "$result" "#000000"
}

test_date() {
    result="$(date "%C")"
    assert_equals "$result" "20"
}

test_read_sleep() {
    result="$((SECONDS+1))"
    read_sleep 1
    assert_equals "$result" "$SECONDS"
}

test_bar() {
    result="$(bar 50 10)"
    assert_equals "${result//$'\r'}" "[-----     ]"
}

test_get_functions() {
    IFS=$'\n' read -d "" -ra functions < <(get_functions)
    assert_equals "${functions[0]}" "assert_equals"
}

test_extract() {
    printf '{\nhello, world\n}\n' > test_file
    result="$(extract test_file "{" "}")"
    assert_equals "$result" "hello, world"
}

test_split() {
    IFS=$'\n' read -d "" -ra result < <(split "hello,world,my,name,is,john" ",")
    assert_equals "${result[*]}" "hello world my name is john"
}

# --- Test harness -----------------------------------------------------------

assert_equals() {
    if [[ "$1" == "$2" ]]; then
        ((pass+=1)) || true
        status=$'\e[32m✔'
    else
        ((fail+=1)) || true
        status=$'\e[31m✖'
        local err="(\"$1\" != \"$2\")"
    fi

    printf ' %s\e[m | %s\n' "$status" "${FUNCNAME[1]/test_} ${err:-}"
}

extract_code_blocks() {
    # Extract ```sh code blocks from README.md.
    # Rules:
    #   - Opening: line matches exactly ```sh (with optional trailing CR).
    #   - Closing: line matches exactly ``` (with optional trailing CR).
    #   - Content between open/close is written to stdout.
    #   - Empty blocks (open immediately followed by close) are skipped.
    #   - If a block is never closed, we error out.
    local code=
    local block_has_content=
    local lineno=0
    local block_start=0

    while IFS=$'\n' read -r line || [[ -n "$line" ]]; do
        ((lineno++)) || true
        # Strip trailing CR for CRLF tolerance.
        line="${line%$'\r'}"

        if [[ -n "$code" ]]; then
            if [[ "$line" == '```' ]]; then
                # Close the code block.
                if [[ -z "$block_has_content" ]]; then
                    printf 'warning: Empty ```sh code block at line %d of %s.\n' \
                        "$block_start" "$README" >&2
                fi
                code=
                continue
            fi
            block_has_content=1
            printf '%s\n' "$line"
        else
            if [[ "$line" == '```sh' ]]; then
                code=1
                block_has_content=
                block_start=$lineno
            fi
        fi
    done < "$README"

    # Detect unclosed code block.
    if [[ -n "${code:-}" ]]; then
        printf 'error: Unclosed ```sh code block starting at line %d of %s.\n' \
            "$block_start" "$README" >&2
        return 1
    fi
}

main() {
    local pass=0 fail=0

    # Validate README exists.
    if [[ ! -f "$README" ]]; then
        printf 'error: %s not found.\n' "$README" >&2
        exit 1
    fi

    # Clean up temp files on exit.
    trap 'rm -f readme_code test_file' EXIT

    # Extract code blocks from the README.
    if ! extract_code_blocks > readme_code; then
        printf 'error: Code block extraction failed.\n' >&2
        exit 1
    fi

    # Validate that code was actually extracted.
    if [[ ! -s readme_code ]]; then
        printf 'error: No ```sh code blocks found in %s.\n' "$README" >&2
        printf '  Expected at least one ```sh ... ``` block with testable code.\n' >&2
        exit 1
    fi

    # Run shellcheck if available.
    if command -v shellcheck >/dev/null 2>&1; then
        printf '%s\n' '-> Running shellcheck...'
        # Exclude codes that are expected in documentation code snippets:
        #   SC2295: Expansions inside ${..} need quoting (intentional pattern matching)
        #   SC2329: Function never invoked (called indirectly via declare -F)
        #   SC2141: IFS contains literal letter (documented behavior)
        #   SC2016: Expressions don't expand in single quotes (intentional literal)
        #   SC2004: $/${} unnecessary on arithmetic (style preference)
        if ! shellcheck -s bash \
            -e SC2295,SC2329,SC2141,SC2016,SC2004 \
            readme_code test.sh build.sh; then
            printf 'error: shellcheck found issues.\n' >&2
            exit 1
        fi
    else
        printf 'warning: shellcheck not found, skipping lint.\n' >&2
    fi

    # Source the extracted code.
    # shellcheck disable=SC1091
    if ! . readme_code; then
        printf 'error: Failed to source extracted code from %s.\n' "$README" >&2
        exit 1
    fi

    local head_msg="-> Running tests on the Pure Bash Bible.."
    printf '\n%s\n%s\n' "$head_msg" "${head_msg//?/-}"

    # Discover and run all test_* functions.
    local funcs
    IFS=$'\n' read -d "" -ra funcs < <(declare -F) || true
    local test_count=0
    for func in "${funcs[@]//declare -f }"; do
        if [[ "$func" == test_* ]]; then
            "$func"
            ((test_count++)) || true
        fi
    done

    # Validate that tests actually ran.
    if ((test_count == 0)); then
        printf 'error: No test_* functions found in test.sh.\n' >&2
        exit 1
    fi

    local comp="Completed $((fail+pass)) tests. ${pass:-0} passed, ${fail:-0} failed."
    printf '%s\n%s\n\n' "${comp//?/-}" "$comp"

    # Exit with 1 if any test failed.
    if ((fail > 0)); then
        exit 1
    fi
    exit 0
}

main "$@"
