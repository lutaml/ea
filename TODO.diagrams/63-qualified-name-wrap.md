# TODO-D 63: Qualified-name line wrap for long class names

## Status: completed

EA wraps long qualified class names (e.g. `brid::OuterFloorSurface`)
across TWO `<text>` elements when the rendered width exceeds the
element's header width.

## Implementation

`Ea::Svg::EaEmitter::Element::HeaderLines.for` now accepts
`bounds_width:` and `font_size:` keyword args. When the qualified
name's estimated rendered width (using `TextRenderer.estimate_width`
with `width_factor=0.55` and `QUALIFIED_WRAP_PADDING=8`) exceeds
the element's bounds, the name splits into two header lines:

1. `"qualifier::"` (with trailing `::`)
2. `"ClassName"` (the base name after `::`)

The `Elements` orchestrator threads `raw_bounds.width` and the
resolved `font_size` through to `HeaderLines.for`.

## Results

- Plateau text delta: -3 → +5 (slight over-rendering on a few
  borderline cases — both name+wrap and not-quite-fit names).
- 154/188 matched diagrams (unchanged).
- basic.qea, test.qea, simple.qea: unchanged.

## Tuning

Width factor 0.55 matches Carlito 9pt bold's average glyph advance
for the CJK + Latin mix on the plateau. The 8px padding accounts
for the element's internal left+right padding that EA reserves
around header text. Both constants are at the top of HeaderLines
for easy future adjustment if EA's font metrics shift.
