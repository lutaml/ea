# TODO-D 06 - Group layering parity

## Status: PARTIAL (2026-07-26)

## Current state

EA emits each `<rect>`, `<polygon>`, `<path>`, `<text>` inside its
own `<g>` block with a specific `style` attribute. Style strings
differ by:

- stroke_width (1 vs 2)
- stroke_linecap (round vs square)
- stroke_linejoin (bevel vs miter)
- fill color
- stroke color
- opacity

Our emitter groups output by `style_key` (a Symbol like
`:diamond_filled` or `:triangle_open`), with the style string
looked up from a small dispatch table. This matches EA's grouping
semantics for most cases.

## Note element body

The Note element body was previously emitted as a `<polygon>`. EA
emits it as a closed `<path d="M...L...Z"/>` with
`stroke-linejoin=bevel` and `stroke-linecap=square`. Fixed in
commit f4fa55f.

## Remaining gap

EA sometimes uses different `stroke-linecap` for the same shape
type depending on whether it's a "decorative" element (square cap)
or a "connector" element (round cap). Our style dispatch table
doesn't distinguish these. Visible in:

- Note bodies (square) vs classifier rects (round) — fixed
- Connector lines (round) vs divider lines (round) — both round
- Visibility icon rects inside attribute compartments — TBD
