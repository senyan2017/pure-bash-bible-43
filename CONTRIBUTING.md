# Writing the Bible

<!-- vim-markdown-toc GFM -->

* [Adding Code to the Bible.](#adding-code-to-the-bible)
* [Special meanings for code blocks.](#special-meanings-for-code-blocks)
* [Writing tests](#writing-tests)
* [Running tests](#running-tests)
* [Chapter markers](#chapter-markers)
* [File format](#file-format)

<!-- vim-markdown-toc -->

## Adding Code to the Bible.

- The code must use only `bash` built-ins.
    - A fallback to an external program is allowed if the code doesn't
      always work.
    - Example Fallback: `${HOSTNAME:-$(hostname)}`
- If possible, wrap the code in a function.
    - This allows tests to be written.
    - It also allows `shellcheck` to properly lint it.
    - An added bonus is showing a working use-case.
- Write some examples.
    - Show some input and the modified output.


## Special meanings for code blocks.

**These rules are enforced by `test.sh` and `validate.sh`.**

Use `sh` for functions that should be linted and unit tested.

    ```sh
    # Shellcheck will lint this and the test script will source this.
    func() {
        # Usage: func "arg"
        :
    }
    ```

Use `shell` for code that should be ignored by the build/test pipeline.

    ```shell
    # Shorter file creation syntax.
    :>file
    ```

**Important constraints:**

- The opening marker ````sh` or ````shell` MUST be on its own line with
  no extra whitespace before or after the language tag.
- The closing ```` ``` ```` MUST be on its own line with nothing else on that line.
- Do NOT use other language tags (e.g., ````bash`, ````Bash`) for code that
  should be tested — only ````sh` is recognized by the test extractor.
- Do NOT leave code blocks empty (open immediately followed by close).
- Every opened code block MUST be closed before the next one is opened.
- Do NOT nest code blocks inside other code blocks.

## Writing tests

The test file is viewable here: https://github.com/dylanaraps/pure-bash-bible/blob/master/test.sh

Example test:

```sh
test_upper() {
    result="$(upper "HeLlO")"
    assert_equals "$result" "HELLO"
}
```

Steps:

1. Write the test.
    - Naming is `test_func_name`
    - Store the function output in a variable (`$result` or `${result[@]}`).
    - Use `assert_equals` to test equality between the variable and the
      expected output.
2. The test script will automatically execute it. :+1:


## Running tests

Running `test.sh` also runs `shellcheck` on the code (if installed).

```sh
cd pure-bash-bible
./test.sh
```

To validate the document structure without running tests:

```sh
./validate.sh
```

To build the manuscript chapters:

```sh
./build.sh
```

The CI pipeline runs all three: `validate.sh`, `test.sh`, and `build.sh`.


## Chapter markers

Chapters in README.md are delimited by HTML comment markers:

    <!-- CHAPTER START -->
    # Chapter Title

    Chapter content here...

    <!-- CHAPTER END -->

**Constraints enforced by `build.sh` and `validate.sh`:**

- Markers MUST appear at column 0 with no leading whitespace.
- Markers MUST be on their own line with exact text (no extra spaces).
- Every `<!-- CHAPTER START -->` MUST have a matching `<!-- CHAPTER END -->`.
- Chapters MUST NOT be nested.
- Chapters MUST NOT be empty (must contain at least one non-whitespace line).
- Content outside chapter markers (e.g., the header, TOC, afterword) is
  excluded from the manuscript build.

If you add, remove, or rearrange chapters, run `./validate.sh` and
`./build.sh` to verify the structure is correct.


## File format

- README.md MUST use Unix line endings (LF). CRLF (`\r\n`) will cause
  silent marker mismatches in `build.sh` and `test.sh`.
- The file MUST be valid UTF-8.
- Do not use tabs for indentation in Markdown content (use spaces).
- Ensure the file ends with a single newline.
