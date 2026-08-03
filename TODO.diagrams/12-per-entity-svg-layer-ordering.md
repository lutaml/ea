# 12 - Per-Entity SVG Layer Ordering

## Status: DONE (2026-07-23)

## Outcome

Restructured `Ea::Svg::EaEmitter::Document` to emit a flat sequence
of top-level `<g>` elements matching EA's per-entity layering:

- `Elements#groups` returns Array of per-element `<g>` blocks
  (shape → header → divider → attrs)
- `Connectors#groups` returns Array of one `<g>` per connector line
- `Markers#groups` returns Array of one `<g>` per connector marker
- `Document#connector_layers` interleaves line + marker per connector

Verified on Waterway: 50 top-level `<g>` (ours) vs 47 (ref) — the
3-group delta is due to the spurious frame element (TODO 14).

## Files changed

- `lib/ea/svg/ea_emitter/document.rb` — interleaves line/marker per connector
- `lib/ea/svg/ea_emitter/elements.rb` — `groups` method, per-element arrays
- `lib/ea/svg/ea_emitter/connectors.rb` — `groups` method, one `<g>` per connector
- `lib/ea/svg/ea_emitter/markers.rb` — `groups` method, one `<g>` per marker
