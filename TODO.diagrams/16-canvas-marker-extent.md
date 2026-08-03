# 16 - Canvas Bounds Include Marker Extent

## Status: DONE (2026-07-23)

## Outcome

`Canvas.from` now extends the points list with `MARKER_EXTENT=15`
padding around each connector's source and target waypoints. This
prevents markers (diamonds, triangles, arrows) from being clipped
when they project beyond element bounds.

For Waterway this didn't change the canvas size (markers fit within
existing element bounds), but for diagrams where arrows extend below
or beside elements, the canvas now grows accordingly.

## Remaining diff

Waterway height: ours 869 vs ref 892 (23 px short). Root cause:
EA's renderer uses `image_bounds` (with 12 px image padding) for
certain elements while we use logical `bounds`. The 23 px diff
matches the difference between logical and image_bounds for the
lowest element (FacilityIdAttribute: logical bottom=895, image
bottom=918). To close this fully we'd need to compute canvas from
image_bounds union (matching EA's behavior), but this would also
require translating elements by image_bounds rather than logical
bounds — a larger change deferred to TODO 18.

## Files changed

- `lib/ea/svg/ea_emitter/canvas.rb` — `marker_extents` + concat into points
