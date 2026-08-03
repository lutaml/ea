# 61 - Theme Definition Validation

## Status: DONE (2026-07-26)

## Context

`Ea::Theme::Definition.new` accepts any values without
validation. Invalid data (malformed hex, negative font_size,
nil required fields) produces silently broken rendering.

## What needs to change

1. `Definition#initialize` validates:
   - id is non-empty string
   - colors match /^#[0-9A-Fa-f]{6}$/
   - font_size is nil or positive integer
   - stroke_width is positive integer
   - text_weight_normal/bold are integers
2. Raises `ArgumentError` with descriptive message on violation
3. Skip validation when loading from YAML (trust source) — use
   `Definition.new(..., validate: false)` or `Definition.from_hash`

## Acceptance

- Invalid hex raises ArgumentError
- Negative font_size raises ArgumentError
- Empty id raises ArgumentError
- Valid Definition passes without error
