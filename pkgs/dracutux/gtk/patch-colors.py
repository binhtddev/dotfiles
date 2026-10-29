#!/usr/bin/env python3
"""Replace exact strings in arc-theme's SCSS colour files.

Usage: patch-colors.py <file> <json mapping>

The mapping is passed in from Nix so the palette lives in one place
(palette.nix). Fails loudly if a pattern disappeared upstream, which means the
SCSS needs updating.
"""
import json
import sys

path = sys.argv[1]
mapping = json.loads(sys.argv[2])

with open(path) as fh:
    text = fh.read()

for old, new in mapping.items():
    if old not in text:
        sys.exit(f"pattern not found in {path}: {old!r}")
    text = text.replace(old, new)

with open(path, "w") as fh:
    fh.write(text)
