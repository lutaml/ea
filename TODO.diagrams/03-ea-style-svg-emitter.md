# 03 - EA-Style SVG Emitter

## Status: DONE (2026-07-21) (depends on 02)

## Problem

The current `Ea::Svg::Renderer` emits minimal SVG: header,
background rect, then per-element `<g class="element">` groups
with the box + label inside. EA's SVG output is structurally
different:

1. DOCTYPE declaration (SVG 1.0)
2. Root `<svg>` with `width="Xcm" height="Ycm"` and
   `viewBox="0 0 W H"`
3. `<title></title>` (empty)
4. `<desc>Created with Enterprise Architect (Build: 1628) 2</desc>`
5. Background `<g style="fill:#FFFFFF;..."><rect .../></g>`
6. For each element, TWO `<g>` blocks:
   a. Shape `<g>` with `style="...fill:COLOR;..."` containing the
      `<rect>`
   b. Text `<g>` with `style="fill:#000000;..."` containing all
      `<text>` labels for that element
7. Divider line as `<g><path d="M x y L x2 y2"/></g>`
8. Connector paths as separate `<g>` blocks per path segment
9. Arrow markers as `<g><polygon .../></g>`
10. Connector labels as a final `<g>` block of `<text>`

The output is layered by visual category, not by element. Our
current emitter layers by element, mixing shapes and text in one
`<g>`.

## Approach

Rewrite the emitter to follow EA's layering. Each render phase
emits one or more `<g>` blocks in the canonical order:

1. `Ea::Svg::EaEmitter::Background`
2. `Ea::Svg::EaEmitter::Elements` (one shape `<g>` + one text `<g>`
   per element, in z-order)
3. `Ea::Svg::EaEmitter::Dividers` (one `<g>` per divider line)
4. `Ea::Svg::EaEmitter::Connectors` (one `<g>` per path)
5. `Ea::Svg::EaEmitter::Markers` (filled / open polygons)
6. `Ea::Svg::EaEmitter::Labels` (all text labels last)

Each emitter is a single-responsibility class. The orchestrator
calls them in order.

The existing `Ea::Svg::Renderer` stays as a thinner alternative
(useful for diagrams without full style data, e.g. from QEA
sources with sparse style). The new `EaEmitter` is the default
when full EA-style data is available.

## Files

- `lib/ea/svg/ea_emitter.rb` (orchestrator)
- `lib/ea/svg/ea_emitter/background.rb`
- `lib/ea/svg/ea_emitter/elements.rb`
- `lib/ea/svg/ea_emitter/dividers.rb`
- `lib/ea/svg/ea_emitter/connectors.rb`
- `lib/ea/svg/ea_emitter/markers.rb`
- `lib/ea/svg/ea_emitter/labels.rb`
- `lib/ea/svg/ea_emitter/canvas.rb` (computes cm dimensions + viewBox)
- `spec/ea/svg/ea_emitter/*_spec.rb`

## Verification

- Byte-level structural diff against EA's reference SVG for one
  diagram. We don't require pixel-perfect match (font rendering
  differences), but the element layering, group structure, and
  attribute presence should match.
