# Contributing to the Pure Bash Bible

## Toolchain Overview

The project uses a small set of bash scripts that share a common Markdown
parsing library.  Every script has a single, clear responsibility:

| Script | What it does |
|---|---|
| `lib/markdown.sh` | Shared library — extracts chapters and `sh` code blocks from `README.md`. Both `build.sh` and `test.sh` source this file so parsing rules stay in one place. |
| `build.sh` | Splits `README.md` into per-chapter files under `manuscript/` (for the Leanpub book). |
| `test.sh` | Extracts `sh` code blocks from `README.md`, runs `shellcheck`, then runs every `test_*` function defined in `test.sh`. |
| `check.sh` | **Single entry point.** Runs `build.sh` then `test.sh` and reports an overall pass/fail. Run this after any change. |

### Quick validation

```sh
./check.sh
```

This regenerates the manuscript, lints the embedded code, and runs all unit
tests.  If any step fails the pipeline stops immediately so you can fix
issues one at a time.

## Adding Code to the Bible

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

## Code Block Conventions

`README.md` uses two types of fenced code blocks.  The language tag after
the opening fence determines how the toolchain treats the block:

| Fence tag | Meaning |
|---|---|
| ` ```sh ` | Tested and linted.  `test.sh` extracts these blocks, runs `shellcheck` on the result, and sources them so unit tests can call the functions. |
| ` ```shell ` | Example only.  Ignored by the extraction pipeline — use this for demonstrations that should not be tested or linted. |

```sh
# Shellcheck will lint this and the test script will source this.
func() {
    # Usage: func "arg"
    :
}
```

```shell
# Shorter file creation syntax — not linted or tested.
:>file
```

## Chapter Markers

The manuscript build (`build.sh`) splits the README into chapters using
HTML comment markers:

```html
<!-- CHAPTER START -->
…chapter content…
<!-- CHAPTER END -->
```

Each pair produces one `manuscript/chapter{N}.txt` file.  If you add or
reorder chapters, just make sure the markers stay balanced — `check.sh`
will catch mismatches.

## Writing Tests

Example test:

```sh
test_upper() {
    result="$(upper "HeLlO")"
    assert_equals "$result" "HELLO"
}
```

Steps:

1. Write the test function in `test.sh`.
    - Name it `test_<function_name>`.
    - Store the function output in a variable (`$result` or `${result[@]}`).
    - Use `assert_equals` to compare the result with the expected output.
2. Run `./check.sh` — the test runner discovers `test_*` functions
   automatically.

## Project Structure

```
.
├── README.md           # The single source of truth (all snippets live here)
├── CONTRIBUTING.md     # This file
├── LICENSE.md
├── .travis.yml         # CI — runs ./test.sh
├── lib/
│   └── markdown.sh     # Shared Markdown parsing (chapters + code blocks)
├── build.sh            # README → manuscript/chapter*.txt
├── test.sh             # Lint + unit tests
├── check.sh            # Run everything (build + lint + test)
└── manuscript/         # Generated chapter files (do not edit by hand)
    ├── Book.txt
    ├── chapter0.txt
    └── ...
```
