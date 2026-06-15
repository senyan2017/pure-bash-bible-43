#!/usr/bin/env bash
#
# Regression tests for the build/test/validate pipeline.
#
# These tests verify that breaking chapter markers, code blocks, or file
# format is immediately detected by validate.sh, build.sh, or test.sh.
#
# Each test creates a temporary corrupted README, runs the relevant script,
# and asserts that it fails with a non-zero exit code.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR=
PASS=0
FAIL=0

setup() {
    WORK_DIR="$(mktemp -d)"
    # Copy scripts into work dir so they can be run from there.
    cp "$SCRIPT_DIR/validate.sh" "$WORK_DIR/"
    cp "$SCRIPT_DIR/build.sh" "$WORK_DIR/"
    cp "$SCRIPT_DIR/test.sh" "$WORK_DIR/"
    chmod +x "$WORK_DIR/validate.sh" "$WORK_DIR/build.sh" "$WORK_DIR/test.sh"
}

teardown() {
    rm -rf "$WORK_DIR"
}

assert_fails() {
    local description="$1"
    shift
    local output
    # Run in a subshell from WORK_DIR so scripts find their README.md there.
    if output=$(cd "$WORK_DIR" && "$@" 2>&1); then
        printf ' \e[31m✖\e[m | %s (expected failure, but script succeeded)\n' "$description"
        printf '   Output: %s\n' "${output:0:200}"
        ((FAIL++)) || true
    else
        printf ' \e[32m✔\e[m | %s\n' "$description"
        ((PASS++)) || true
    fi
}

assert_succeeds() {
    local description="$1"
    shift
    local output
    # Run in a subshell from WORK_DIR so scripts find their README.md there.
    if output=$(cd "$WORK_DIR" && "$@" 2>&1); then
        printf ' \e[32m✔\e[m | %s\n' "$description"
        ((PASS++)) || true
    else
        printf ' \e[31m✖\e[m | %s (expected success, but script failed)\n' "$description"
        printf '   Output: %s\n' "${output:0:200}"
        ((FAIL++)) || true
    fi
}

# --- Test: missing README ---
test_missing_readme() {
    setup
    # No README.md in work dir.
    assert_fails "validate.sh detects missing README" \
        bash "$WORK_DIR/validate.sh"
    assert_fails "build.sh detects missing README" \
        bash "$WORK_DIR/build.sh"
    assert_fails "test.sh detects missing README" \
        bash "$WORK_DIR/test.sh"
    teardown
}

# --- Test: mismatched chapter markers (missing END) ---
test_mismatched_chapter_markers() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Chapter One
Some content.
HEREDOC
    assert_fails "validate.sh detects unclosed chapter" \
        bash "$WORK_DIR/validate.sh"
    assert_fails "build.sh detects unclosed chapter" \
        bash "$WORK_DIR/build.sh"
    teardown
}

# --- Test: mismatched chapter markers (extra END) ---
test_extra_chapter_end() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER END -->
HEREDOC
    assert_fails "validate.sh detects stray END marker" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: nested chapter markers ---
test_nested_chapters() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Outer
<!-- CHAPTER START -->
# Inner
<!-- CHAPTER END -->
<!-- CHAPTER END -->
HEREDOC
    assert_fails "validate.sh detects nested chapters" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: empty chapter ---
test_empty_chapter() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
<!-- CHAPTER END -->
HEREDOC
    assert_fails "validate.sh detects empty chapter" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: no chapter markers at all ---
test_no_chapter_markers() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
# Just a heading
Some content without any chapter markers.
HEREDOC
    assert_fails "validate.sh detects missing markers" \
        bash "$WORK_DIR/validate.sh"
    assert_fails "build.sh detects missing markers" \
        bash "$WORK_DIR/build.sh"
    teardown
}

# --- Test: unclosed ```sh code block ---
test_unclosed_code_block() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Test

```sh
func() { :; }
HEREDOC
    assert_fails "validate.sh detects unclosed code block" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: no ```sh code blocks ---
test_no_sh_code_blocks() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Test

```shell
echo "not testable"
```

<!-- CHAPTER END -->
HEREDOC
    assert_fails "validate.sh detects missing sh blocks" \
        bash "$WORK_DIR/validate.sh"
    assert_fails "test.sh detects missing sh blocks" \
        bash "$WORK_DIR/test.sh"
    teardown
}

# --- Test: CRLF line endings ---
test_crlf_line_endings() {
    setup
    printf '<!-- CHAPTER START -->\r\n# Test\r\n\r\n```sh\r\nfunc() { :; }\r\n```\r\n\r\n<!-- CHAPTER END -->\r\n' \
        > "$WORK_DIR/README.md"
    assert_fails "validate.sh detects CRLF endings" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: stray ``` outside code block ---
test_stray_closing_marker() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Test

Some text.
```

```sh
func() { :; }
```

<!-- CHAPTER END -->
HEREDOC
    assert_fails 'validate.sh detects stray ```' \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: well-formed README passes validation ---
test_valid_readme() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
# Title

Some intro text.

<!-- CHAPTER START -->
# Chapter One

## A function

```sh
greet() {
    # Usage: greet "name"
    printf 'Hello, %s\n' "$1"
}
```

```shell
$ greet "World"
Hello, World
```

<!-- CHAPTER END -->

<!-- CHAPTER START -->
# Chapter Two

More content here.

<!-- CHAPTER END -->
HEREDOC
    assert_succeeds "validate.sh accepts well-formed README" \
        bash "$WORK_DIR/validate.sh"
    assert_succeeds "build.sh accepts well-formed README" \
        bash "$WORK_DIR/build.sh"
    teardown
}

# --- Test: chapter marker with leading space is NOT recognized ---
test_indented_marker() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
 <!-- CHAPTER START -->
# Chapter
Content.
<!-- CHAPTER END -->
HEREDOC
    # The indented START marker won't be recognized, so we have END without START.
    assert_fails "validate.sh rejects indented START marker" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Test: empty ```sh block warning ---
test_empty_sh_block() {
    setup
    cat > "$WORK_DIR/README.md" << 'HEREDOC'
<!-- CHAPTER START -->
# Test

```sh
```

```sh
func() { :; }
```

<!-- CHAPTER END -->
HEREDOC
    # validate.sh should report the empty block (it warns but also counts errors
    # for empty sh blocks only if they are truly empty - the current validate.sh
    # issues a warning but doesn't fail for empty blocks).
    # The main thing is it doesn't crash.
    assert_succeeds "validate.sh handles empty sh block without crash" \
        bash "$WORK_DIR/validate.sh"
    teardown
}

# --- Run all tests ---
main() {
    local head="-> Running regression tests for build/test/validate pipeline.."
    printf '\n%s\n%s\n\n' "$head" "${head//?/-}"

    test_missing_readme
    test_mismatched_chapter_markers
    test_extra_chapter_end
    test_nested_chapters
    test_empty_chapter
    test_no_chapter_markers
    test_unclosed_code_block
    test_no_sh_code_blocks
    test_crlf_line_endings
    test_stray_closing_marker
    test_valid_readme
    test_indented_marker
    test_empty_sh_block

    local comp="Completed $((FAIL+PASS)) tests. ${PASS:-0} passed, ${FAIL:-0} failed."
    printf '%s\n%s\n\n' "${comp//?/-}" "$comp"

    if ((FAIL > 0)); then
        exit 1
    fi
    exit 0
}

main "$@"
