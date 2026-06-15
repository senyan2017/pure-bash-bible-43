# Writing the Bible

<!-- vim-markdown-toc GFM -->

* [Adding Code to the Bible.](#adding-code-to-the-bible)
* [Special meanings for code blocks.](#special-meanings-for-code-blocks)
* [Chapter markers](#chapter-markers)
* [Writing tests](#writing-tests)
* [Building and testing](#building-and-testing)

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

Use `sh` for functions that should be linted and unit tested.

    ```sh
    # Shellcheck will lint this and the test script will source this.
    func() {
        # Usage: func "arg"
        :
    }
    ```

Use `shell` for code that should be ignored.

    ```shell
    # Shorter file creation syntax.
    :>file
    ```

## Chapter markers

The book under `manuscript/` is generated from this same README by splitting
it into chapters. A chapter is everything between two HTML-comment markers:

    <!-- CHAPTER START -->
    ## Some heading
    ...
    <!-- CHAPTER END -->

`build.sh` writes one `chapterN.txt` per region. You rarely edit this by hand —
just keep a new section inside a `START`/`END` pair if it should appear in the
book.

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


## Building and testing

After editing `README.md`, run one command to confirm the book still builds
and the code still lints and passes its tests:

```sh
cd pure-bash-bible
./check.sh
```

That is all a contributor needs. `check.sh` just chains the two
single-purpose scripts, which you can also run on their own:

| Script     | Responsibility |
| ---------- | -------------- |
| `lib.sh`   | The one place that knows the README's structure (the code-fence and chapter rules) and exposes `extract_code` / `extract_chapters`. Sourced, never run directly. |
| `build.sh` | Assembles `manuscript/` from the chapters `lib.sh` finds. |
| `test.sh`  | Runs `shellcheck` and the unit tests on the `sh` code `lib.sh` finds. |
| `check.sh` | The entry point: runs `build.sh`, then `test.sh`. |

Because every script gets its view of the README from `lib.sh`, changing a
Markdown rule (a new code-fence convention, different chapter markers) means
editing `lib.sh` only — never the build or test scripts.
