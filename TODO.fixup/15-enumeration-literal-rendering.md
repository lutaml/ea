# 15 - Enumeration Literal Rendering

## Status: DONE (2026-07-25)

## Outcome

New `Element::EnumerationLiteralRenderer` emits a literal
compartment below the attribute compartment for Enumeration
classifiers. Layout:

```
┌────────────────────┐
│ «enumeration»      │  header
│ EnumName           │
├────────────────────┤
│ + attr: Type       │  attributes (if any)
├────────────────────┤
│ literal1           │  literal compartment
│ literal2           │
└────────────────────┘
```

`CompartmentGeometry` extended with `attr_lines_count`,
`enum_divider_y`, `enum_literal_first_y`.

## Files changed

- `lib/ea/svg/ea_emitter/element/enumeration_literal_renderer.rb` — NEW
- `lib/ea/svg/ea_emitter/element.rb` — autoload
- `lib/ea/svg/ea_emitter/elements.rb` — invoke renderer, extend geometry
