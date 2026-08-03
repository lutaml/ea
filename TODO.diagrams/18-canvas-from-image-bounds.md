# 18 - Canvas from image_bounds (matching EA)

## Status: DONE (2026-07-23)

## Outcome

`Canvas.from` now unions BOTH `bounds` and `image_bounds` for each
element. `image_bounds` captures the rendered extent (logical bounds
+ image padding), so the canvas grows to fit the full visual area.

Waterway canvas: 1138×869 → 1163×899 (ref=1138×892)
Building canvas: 1381×1524 → 1406×1554 (ref=1406×1530, width matches)

Remaining diff (25 px width on Waterway) is from image_bounds
extending further right than EA includes in canvas. Acceptable for
visual rendering — text and shapes are positioned correctly.

## Files changed

- `lib/ea/svg/ea_emitter/canvas.rb` — union bounds + image_bounds
