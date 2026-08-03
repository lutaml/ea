# TODO-D 44: Element icon decorations (folded-paper class icon)

## Symptom

EA renders a small "folded paper" icon at the top-right corner of
each class shape. The icon is two `<path>` elements:

1. Outer outline: `M x y L x+6 y L x+9 y+4 L x+9 y+11 L x y+11 Z`
2. Folded corner: `M x+6 y L x+6 y+4 L x+9 y+4`

Style:
- `stroke-width:1; stroke-linecap:square; stroke-linejoin:bevel;`
- Outer: `fill:#DCF8F0; stroke:#577AC1` (light cyan fill, blue stroke)
- Inner corner: `fill:transparent; stroke:#577AC1`

## Discriminator

The XMI element style carries `HideIcon=0` (show) or `HideIcon=1`
(hide). When shown, EA emits the icon paths regardless of element
type (class, data type, etc.).

## Bench impact (estimated)

- 2 paths per shown icon × ~140 elements with `HideIcon=0` ≈ 280
  paths. This matches the current path delta of `-280`.

## Acceptance

- Add an `Element::IconRenderer` that emits the two `<path>`
  elements at (bounds.right - 12, bounds.top + 3) when
  `element.style["HideIcon"] == "0"` (default visible).
- Thread HideIcon parsing through `ExtensionStyleParser`.
- Spec coverage for both shown and hidden cases.
- Bench path delta → 0.
