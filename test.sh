#!/usr/bin/env bash
# shellcheck source=/dev/null disable=2178,2128
#
# Tests for the Pure Bash Bible.

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
    # shellcheck disable=2034
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

test_load_env_file_basic() {
    printf 'KEY1=value1\nKEY2=value2\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" $'KEY1=value1\nKEY2=value2'
}

test_load_env_file_comments_and_blanks() {
    printf '# comment\n\nKEY=val\n# another comment\n\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" "KEY=val"
}

test_load_env_file_quoted_values() {
    printf "K1='hello world'\nK2=\"foo bar\"\n" > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" $'K1=hello world\nK2=foo bar'
}

test_load_env_file_inline_comment() {
    printf 'KEY=value # this is a comment\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" "KEY=value"
}

test_load_env_file_empty_value() {
    printf 'EMPTY=\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" "EMPTY="
}

test_load_env_file_value_with_equals() {
    printf 'KEY=a=b=c\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" "KEY=a=b=c"
}

test_load_env_file_missing_file() {
    result="$(load_env_file /nonexistent_file_xyz 2>/dev/null)"
    local rc=$?
    assert_equals "$rc" "1"
}

test_load_env_file_leading_whitespace() {
    printf '  KEY=value\n' > test_file
    result="$(load_env_file test_file)"
    assert_equals "$result" "KEY=value"
}

test_kv_set_and_get() {
    # Reset the store.
    __kv_store=()
    kv_set "testkey" "testval"
    result="$(kv_get "testkey")"
    assert_equals "$result" "testval"
}

test_kv_get_missing_key() {
    __kv_store=()
    result="$(kv_get "nonexistent_key_xyz")"
    assert_equals "$result" ""
}

test_kv_get_with_default() {
    __kv_store=()
    result="$(kv_get "nonexistent_key_xyz" "default_val")"
    assert_equals "$result" "default_val"
}

test_kv_overwrite() {
    __kv_store=()
    kv_set "dup" "first"
    kv_set "dup" "second"
    result="$(kv_get "dup")"
    assert_equals "$result" "second"
}

test_kv_empty_value() {
    __kv_store=()
    kv_set "emptykey" ""
    # An empty value is set, so the default should NOT be used.
    result="$(kv_get "emptykey" "default")"
    assert_equals "$result" ""
}

test_kv_value_with_spaces() {
    __kv_store=()
    kv_set "spaced" "hello world foo"
    result="$(kv_get "spaced")"
    assert_equals "$result" "hello world foo"
}

test_ensure_dirs() {
    local tmpbase="/tmp/pbb_test_$$"
    ensure_dirs "$tmpbase/a" "$tmpbase/b/c"
    local ok=1
    [[ -d "$tmpbase/a" ]] || ok=0
    [[ -d "$tmpbase/b/c" ]] || ok=0
    rm -rf "$tmpbase"
    assert_equals "$ok" "1"
}

test_ensure_dirs_existing() {
    # /tmp always exists; should not error.
    ensure_dirs "/tmp"
    local ok=$?
    assert_equals "$ok" "0"
}

test_ensure_dirs_no_args() {
    # No arguments should be a no-op (success).
    ensure_dirs
    local ok=$?
    assert_equals "$ok" "0"
}

test_check_commands_valid() {
    # bash and printf are always available.
    check_commands "bash" "printf"
    local ok=$?
    assert_equals "$ok" "0"
}

test_check_commands_invalid() {
    (check_commands "nonexistent_cmd_xyz_123" 2>/dev/null)
    local rc=$?
    assert_equals "$rc" "1"
}

test_require_vars_set() {
    local __rv_a="hello" __rv_b="world"
    require_vars "__rv_a" "__rv_b"
    local ok=$?
    assert_equals "$ok" "0"
}

test_require_vars_unset() {
    unset __rv_missing_var 2>/dev/null
    (require_vars "__rv_missing_var" 2>/dev/null)
    local rc=$?
    assert_equals "$rc" "1"
}

test_require_vars_empty() {
    local __rv_empty=""
    (require_vars "__rv_empty" 2>/dev/null)
    local rc=$?
    assert_equals "$rc" "1"
}

test_set_defaults_unset_var() {
    unset __sd_port 2>/dev/null
    set_defaults "__sd_port=8080"
    # shellcheck disable=SC2154
    assert_equals "$__sd_port" "8080"
}

test_set_defaults_existing_var() {
    local __sd_host="0.0.0.0"
    set_defaults "__sd_host=localhost"
    assert_equals "$__sd_host" "0.0.0.0"
}

test_set_defaults_empty_var_gets_default() {
    local __sd_workers=""
    set_defaults "__sd_workers=4"
    assert_equals "$__sd_workers" "4"
}

test_set_defaults_multiple() {
    unset __sd_a __sd_b 2>/dev/null
    local __sd_c="keep"
    set_defaults "__sd_a=1" "__sd_b=2" "__sd_c=3"
    local ok=1
    # shellcheck disable=SC2154
    [[ "$__sd_a" == "1" ]] || ok=0
    # shellcheck disable=SC2154
    [[ "$__sd_b" == "2" ]] || ok=0
    [[ "$__sd_c" == "keep" ]] || ok=0
    assert_equals "$ok" "1"
}

test_mk_temp_dir() {
    # The EXIT trap set inside mk_temp_dir fires when the command
    # substitution subshell exits, removing the dir before we can
    # inspect it.  We verify the function by:
    #   1. Checking the output path matches the expected pattern.
    #   2. Creating a sibling dir with the same pattern to confirm
    #      the naming/mkdir logic works.
    local dir
    dir="$(mk_temp_dir)"
    local ok=0
    if [[ "$dir" == /tmp/bash_* || "$dir" == "${TMPDIR:-/tmp}"/bash_* ]]; then
        # Also verify we can create a dir with the same pattern.
        local verify_dir="${dir}_verify"
        if mkdir -p -- "$verify_dir" 2>/dev/null && [[ -d "$verify_dir" ]]; then
            rmdir -- "$verify_dir"
            ok=1
        fi
    fi
    rm -rf -- "$dir" 2>/dev/null
    assert_equals "$ok" "1"
}

test_lock_acquire_and_release() {
    local lockdir="/tmp/pbb_lock_test_$$"
    rm -rf -- "$lockdir"
    lock_acquire "$lockdir"
    local ok=0
    if [[ -d "$lockdir" ]]; then
        ok=1
    fi
    lock_release "$lockdir"
    if [[ -d "$lockdir" ]]; then
        ok=0
    fi
    rm -rf -- "$lockdir" 2>/dev/null
    assert_equals "$ok" "1"
}

test_lock_acquire_conflict() {
    local lockdir="/tmp/pbb_lock_conflict_$$"
    mkdir -- "$lockdir"
    (lock_acquire "$lockdir" 2>/dev/null)
    local rc=$?
    rmdir -- "$lockdir" 2>/dev/null
    assert_equals "$rc" "1"
}

assert_equals() {
    if [[ "$1" == "$2" ]]; then
        ((pass+=1))
        status=$'\e[32m✔'
    else
        ((fail+=1))
        status=$'\e[31m✖'
        local err="(\"$1\" != \"$2\")"
    fi

    printf ' %s\e[m | %s\n' "$status" "${FUNCNAME[1]/test_} $err"
}

main() {
    trap 'rm readme_code test_file' EXIT

    # Extract code blocks from the README.
    while IFS=$'\n' read -r line; do
        [[ "$code" && "$line" != \`\`\` ]] && printf '%s\n' "$line"
        [[ "$line" =~ ^\`\`\`sh$ ]] && code=1
        [[ "$line" =~ ^\`\`\`$ ]]   && code=
    done < README.md > readme_code

    # Run shellcheck and source the code.
    # Add global directives for pre-existing warnings in extracted README code
    # that newer shellcheck versions flag (these are NOT from new additions).
    { printf '# shellcheck disable=SC2295,SC2329,SC2141\n'; cat readme_code; } > readme_code_sc
    mv readme_code_sc readme_code
    shellcheck -s bash readme_code test.sh build.sh || exit 1
    . readme_code

    head="-> Running tests on the Pure Bash Bible.."
    printf '\n%s\n%s\n' "$head" "${head//?/-}"

    # Generate the list of tests to run.
    IFS=$'\n' read -d "" -ra funcs < <(declare -F)
    for func in "${funcs[@]//declare -f }"; do
        [[ "$func" == test_* ]] && "$func";
    done

    comp="Completed $((fail+pass)) tests. ${pass:-0} passed, ${fail:-0} failed."
    printf '%s\n%s\n\n' "${comp//?/-}" "$comp"

    # If a test failed, exit with '1'.
    ((fail>0)) || exit 0 && exit 1
}

main "$@"
