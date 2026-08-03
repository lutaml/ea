# 64 - Theme Write-Back to StyleEx

## Status: DONE (2026-07-26)

## Context

When `diagram.theme = :119` is called, the theme_override_id is
set in memory. There's no way to persist this back to the QEA's
`t_diagram.StyleEx` field.

## What needs to change

1. `Diagram#to_style_ex` — serializes style_ex_flags back to
   `Key=Value;` format, merging theme_id into existing flags
2. QEA writer (when implemented) uses this to write back
3. Diagram#apply_theme_to_style_ex — mutates style_ex in-place

## Acceptance

- Diagram.to_style_ex produces valid StyleEx string
- Theme ID round-trips through to_style_ex → from_style_ex
