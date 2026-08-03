# 70 - Tagged Values Compartment Rendering

## Status: COMPLETE (2026-07-26)

## What changed

1. `lib/ea/sources/xmi/tag_builder.rb` (NEW) — Parses
   `<xmi:Extension>/<elements>/<element>/<tags>/<tag/>` blocks via
   Nokogiri (the xmi gem doesn't expose Sparx tags directly).
   Groups tags by their `modelElement` attribute and strips the
   `#NOTES#...` suffix EA appends to the value attribute.

2. `lib/ea/sources/xmi/adapter.rb` — Calls TagBuilder, attaches the
   resulting TaggedValue arrays to the owning Classifier and
   Package objects. Handles the EAPK_↔EAID_ alias for packages.

3. `lib/ea/svg/ea_emitter/element/tagged_value_renderer.rb` (NEW) —
   Emits an italic "tags" header followed by `key = value` lines
   for each tagged value, matching EA's encoding.

4. `lib/ea/svg/ea_emitter/elements.rb` —
   `groups_for` now invokes `TaggedValueRenderer` when the
   classifier has tagged_values. `CompartmentGeometry` gains
   `tagged_values_count` + `tagged_value_first_y`.
   `has_content_below_header?` now treats tagged values as
   content (so the divider renders).

5. `lib/ea/svg/ea_emitter/element.rb` — autoload for
   TaggedValueRenderer.

6. `lib/ea/sources/xmi.rb` — autoload for TagBuilder.

## Acceptance

- AcmeUmlClass in simple.xmi renders the "tags" header plus
  isCollection and noPropertyType lines.
- Text count on diagrams with tagged classifiers increases
  proportionally.
- All 2285 specs pass.
