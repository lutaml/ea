# 46 - Style Constants Parameterized by Theme

## Status: ANALYZED (2026-07-26, deferred)

## Decision

Current Style constants (CONNECTOR_LINE, DIAMOND_FILLED, etc.)
bake in stroke-width=2. Making them theme-parameterized would
require threading Theme through Connectors/Markers — significant
plumbing for marginal benefit since:
- Plateau (default theme) is the primary use case and uses sw=2
- Theme :119 diagrams use the same constants but render via
  Elements (which already uses theme.stroke_width)

The Connectors/Markers layer doesn't yet need theme support
since plateau parity is the primary target. Deferred until
theme-aware connector rendering is required.

## Files changed

None.
