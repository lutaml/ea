# 03 - Diagram-Level Font Inference

## Status: DONE (2026-07-24)

## Outcome

Updated `FontResolver#diagram_default_family` and
`#diagram_default_size`:

- If ANY element specifies `font=`, use the most common (existing
  behavior — picks up Yu Gothic UI diagrams).
- If NO element specifies font=, fall back to EA's English-locale
  default: **Calibri 10px**.

This handles the 63 Calibri diagrams where no element carries font
info — EA's runtime default kicks in at render time.

## Outcome metrics

Font family match rate: 62% → **71%** (133/185 diagrams).

Remaining 29% are diagrams where elements have a non-Calibri,
non-Yu-Gothic font explicitly (Meiryo UI, mixed-font diagrams).

## Files changed

- `lib/ea/svg/ea_emitter/font_resolver.rb` — Calibri fallback
- `spec/ea/svg/ea_emitter/font_resolver_spec.rb` — covers fallback
