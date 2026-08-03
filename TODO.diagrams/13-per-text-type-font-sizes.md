# TODO-D 13 - Per-text-type font sizes

## Status: COMPLETE (2026-07-27)

## Context

Reference SVGs use different font sizes for different text types:
- 9pt for classifier compartments (header, attributes, operations,
  enumeration literals, tagged values)
- 7pt for diagram-level text (frame label, swimlane names)
- 12pt for some classifier names (rare)

Theme :119 specifies font_size=7pt — that's the DIAGRAM-LEVEL font
size, not the element-level default. Element compartment text uses
9pt regardless of theme.

## What changed

- `FontResolver::DEFAULT_ELEMENT_FONT_SIZE = 9` — replaces the
  previous default of 13 (which was the Yu Gothic UI locale default)
- `FontResolver#size_for` no longer falls back to `theme.font_size`
  for elements — only diagram-level text uses theme font size
- `HeaderRenderer` and `AttributeRenderer` gain `size_unit:`
  parameter (defaults to `"pt"`) and propagate it to TextRenderer
- `Elements#groups_for` reads `size_unit` from FontResolver and
  passes through to all renderers

## Acceptance

- Reference text uses `font-size:9pt` for classifier compartments
- Our text now emits `font-size:9pt` (was `font-size:7px`)
- Text overlap metric unchanged (counts content, not formatting)
- 1612 specs pass
