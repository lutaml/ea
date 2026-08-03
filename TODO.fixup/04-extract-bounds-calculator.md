# 04 - Extract BoundsCalculator (SRP)

## Status: DONE (2026-07-24)

## Outcome

`Ea::Svg::EaEmitter::BoundsCalculator` now owns canvas bound
computation. Three private methods each contribute points:

- `element_points`: logical bounds for x-extent, union of logical
  + image_bounds for y-extent.
- `connector_points`: waypoint positions.
- `marker_points`: MARKER_EXTENT padding around each connector's
  endpoints.

`Canvas.from` shrinks to 2 lines (delegate + construct). Canvas
remains a small value-object with translation and formatting.

## Files changed

- `lib/ea/svg/ea_emitter/bounds_calculator.rb` — NEW extractor class
- `lib/ea/svg/ea_emitter.rb` — autoload registration
- `lib/ea/svg/ea_emitter/canvas.rb` — delegates to BoundsCalculator
- `spec/ea/svg/ea_emitter/bounds_calculator_spec.rb` — 4 specs covering
  x-extent, y-extent, marker extent, empty diagram
