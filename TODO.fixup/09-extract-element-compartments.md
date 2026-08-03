# 09 - Extract ElementRenderer Compartments

## Status: DONE (2026-07-24)

## Outcome

Split `Elements` into focused collaborators under
`Ea::Svg::EaEmitter::Element::`:

- `Filter` — frame-element skip predicate
- `BColDecoder` — BGR int → #RRGGBB hex
- `ShapeRenderer` — element box `<g>` with rect
- `HeaderRenderer` — stereotype + name text `<g>`
- `HeaderLines` — line computation (abstract + stereotype logic)
- `TextEscape` — XML escape helper
- `DividerRenderer` — compartment divider path `<g>`
- `AttributeRenderer` — attribute text `<g>` with visibility split

`Elements` body shrinks to delegation. `CompartmentGeometry` struct
holds the y-coordinate math for header/divider/attr layout.

## Files changed

- `lib/ea/svg/ea_emitter/element.rb` — module entry with autoloads
- `lib/ea/svg/ea_emitter/element/filter.rb`
- `lib/ea/svg/ea_emitter/element/bcol_decoder.rb`
- `lib/ea/svg/ea_emitter/element/shape_renderer.rb`
- `lib/ea/svg/ea_emitter/element/header_renderer.rb`
- `lib/ea/svg/ea_emitter/element/header_lines.rb`
- `lib/ea/svg/ea_emitter/element/text_escape.rb`
- `lib/ea/svg/ea_emitter/element/divider_renderer.rb`
- `lib/ea/svg/ea_emitter/element/attribute_renderer.rb`
- `lib/ea/svg/ea_emitter/elements.rb` — orchestrator only
- `lib/ea/svg/ea_emitter.rb` — autoload Element
