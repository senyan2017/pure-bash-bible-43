#!/usr/bin/env bash
#
# build.sh — Split the README.md into per-chapter manuscript files.
#
# Reads the single README.md, finds every <!-- CHAPTER START --> /
# <!-- CHAPTER END --> pair, and writes the enclosed content to
# manuscript/chapter{N}.txt.  Also regenerates manuscript/Book.txt so
# it always reflects the current chapter list.
#
# Usage:
#     ./build.sh
#
# The chapter-extraction logic lives in lib/markdown.sh so that any
# other script that needs to understand the README's structure can
# share the same rules.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/markdown.sh"

extract_chapters README.md manuscript
