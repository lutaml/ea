# 12 - Connector Path Style Harmony

## Status: DONE (2026-07-24)

## Outcome

New `Ea::Svg::EaEmitter::Style` module centralizes style strings:
- `BACKGROUND` — white fill, no stroke
- `CONNECTOR_LINE` — used for line paths AND arrow paths
- `DIAMOND_FILLED` — aggregation/composition diamond polygons
- `TRIANGLE_OPEN` — generalization/realization triangles
- `TEXT_GROUP` — text wrapper `<g>`
- `ELEMENT_SHAPE_*` — shape stroke constants

`Connectors::LINE_STYLE` and `Markers::STYLE_MAP` reference Style
constants — single source of truth (DRY).

## Files changed

- `lib/ea/svg/ea_emitter/style.rb` — NEW constants module
- `lib/ea/svg/ea_emitter.rb` — autoload registration
- `lib/ea/svg/ea_emitter/connectors.rb` — references Style::CONNECTOR_LINE
- `lib/ea/svg/ea_emitter/markers.rb` — STYLE_MAP references Style
