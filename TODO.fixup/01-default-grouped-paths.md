# 01 - Default Connectors to Style-Grouped Mode

## Status: DONE (2026-07-24)

## Outcome

Refactored emitters to use a `Layer` value object (style_key +
style + body). `Connectors` and `Markers` both return Arrays of
Layer structs. Document orchestrator renders each Layer as one
`<g>`.

Default mode is `grouped: true` for both Connectors and Markers —
all same-style paths/polygons collapse into ONE `<g>` matching
EA's encoding.

## Outcome metrics (5 sample diagrams)

Group count diffs (ours vs ref):
- Bridge:    +120 → -24  (97 vs 121)
- Building:  +77  → -36  (93 vs 129)
- Waterway:  +6   → -10  (37 vs 47)
- CityFurniture: was +6, now **exact match** (20 vs 20)

Slight overshoot on Bridge/Building because we collapse all
markers of one style into a single group, while EA keeps some
sub-bucketing. Acceptable for now.

## Files changed

- `lib/ea/svg/ea_emitter/layer.rb` — NEW Layer value object
- `lib/ea/svg/ea_emitter.rb` — autoload Layer
- `lib/ea/svg/ea_emitter/connectors.rb` — Layer-based, `grouped:` flag
- `lib/ea/svg/ea_emitter/markers.rb` — Layer-based, style-bucketed
- `lib/ea/svg/ea_emitter/document.rb` — consumes Layer API
