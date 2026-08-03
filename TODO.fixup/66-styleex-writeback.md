# 66 - StyleEx Write-Back (to_style_ex) on Diagram

## Status: DONE (2026-07-26)

## Context

Diagram has `style_ex_flags` (parse) but no `to_style_ex`
(serialize). This prevents writing theme changes back to the
QEA database.

## What needs to change

1. `Diagram#to_style_ex` merges current style_ex_flags with
   theme_override_id, producing a new StyleEx string.
2. Round-trip: parse → modify → serialize → parse yields same result.

## Acceptance

- to_style_ex produces valid "Key=Value;..." string
- Theme ID is included in output
- Existing flags preserved
- New spec covers round-trip
