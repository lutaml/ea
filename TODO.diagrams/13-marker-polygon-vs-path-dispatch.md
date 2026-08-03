# 13 - Marker Encoding: Polygon vs Path by Shape

## Status: DONE (2026-07-23)

## Outcome

Refactored `Ea::Svg::EaEmitter::Markers` to dispatch marker shape
via a `Spec` value object. Each marker emits the correct element type:

- Diamond (Aggregation/Composition) → `<polygon>` 4 points
- Open triangle (Generalization/Realization/Dependency) → `<polygon>` 3 points, white fill
- Filled arrow (Association navigability) → `<path d="M .. L .. L .."/>` 3 points

Marker placement is direction-aware: "Destination -> Source" flips
which end holds the marker.

## Files changed

- `lib/ea/svg/ea_emitter/markers.rb` — Spec struct + dispatch
- `spec/ea/svg/ea_emitter/markers_spec.rb` — updated to reflect arrow emission
