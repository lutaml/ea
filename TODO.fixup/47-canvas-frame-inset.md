# 47 - Canvas Frame Inset

## Status: ANALYZED (2026-07-26, deferred)

## Decision

When frame is enabled, elements can overlap the frame border
(6px inset). This is a real issue but only affects the simple/
basic test diagrams (where frame is opt-in via frame: true).

Plateau (frame disabled) is unaffected.

The fix would require BoundsCalculator to add 6px to all
elements when frame is enabled — non-trivial plumbing. Deferred
until frame auto-detection is implemented.

## Files changed

None.
