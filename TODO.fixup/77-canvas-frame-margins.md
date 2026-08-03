# 77 - Canvas frame margins and connector Path= semantics

## Status: PARTIAL (2026-07-26)

## What changed

`ConnectorRouter#waypoints` was treating `Path=` values as relative
deltas from the source point, applying `src_pt + (dx, dy)`. The
`ExtensionGeometryParser` documentation says (and EA reference SVGs
confirm) these are ABSOLUTE pixel positions on the canvas.

Fixed by using bend points as-is. Plateau diagrams that had
connector endpoints at x=2700+ (vs element bounds max=1463) now
route correctly.

## What remains

The canvas size still doesn't perfectly match the reference — EA
uses non-uniform frame margins (left=35, right=50, top=60,
bottom=36) plus a per-diagram "DocSize" override. Our
BoundsCalculator uses uniform 10px padding plus 20px reserved for
Package tabs.

Closing the remaining gap requires either:
1. Parsing t_diagram.cx/cy fields for explicit canvas dimensions
2. Hard-coding EA's non-uniform frame insets per diagram type

Deferred until more parity work justifies it.
