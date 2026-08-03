# 22 - Style-Based Path Grouping

## Status: DONE (2026-07-23)

## Outcome

`Connectors` emitter now supports `group_by_style:` constructor
option. When true, consecutive connectors with the same line style
are merged into a single `<g>` element with multiple `<path>` kids
(matching EA's encoding for diagrams with many similarly-styled
connectors).

Default behavior remains per-entity grouping (one `<g>` per
connector) to preserve z-order interleaving with markers.

## Usage

```ruby
# Default: per-entity groups (current behavior)
Connectors.new(diagram, canvas: canvas)

# EA-style grouped:
Connectors.new(diagram, canvas: canvas, group_by_style: true)
```

## Files changed

- `lib/ea/svg/ea_emitter/connectors.rb` — `group_by_style` option + `grouped_groups`
