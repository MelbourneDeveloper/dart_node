---
name: fmt
description: Formats all code in this repo using dart format. Use when the user asks to format code, fix formatting, or before committing changes.
---

# Format

Format all code in this repo.

## Steps

1. Run `make fmt`
2. Run `make fmt-check` to confirm clean
3. Report which files were modified

## What it does

- `dart format packages/ examples/ tools/build`

## Success criteria

- `make fmt-check` exits with code 0 after formatting
