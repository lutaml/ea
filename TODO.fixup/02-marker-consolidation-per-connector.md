# 02 - Marker Consolidation Per Connector

## Status: DONE (2026-07-24)

## Outcome

Markers now use `:connector_line` style_key for arrow paths,
matching the line style. `Document#merge_layers_by_style` collapses
all Layers with the same style_key into one `<g>`, so:

- All line `<path>`s + arrow `<path>`s → ONE `<g>` (shared style:
  stroke-width:2, no fill, black stroke)
- All diamond `<polygon>`s → ONE `<g>` (filled black)
- All open triangle `<polygon>`s → ONE `<g>` (white fill)

## Files changed

- `lib/ea/svg/ea_emitter/markers.rb` — arrow uses `:connector_line` key,
  STYLE_MAP references Connectors::LINE_STYLE
- `lib/ea/svg/ea_emitter/document.rb` — `merge_layers_by_style` collapses
