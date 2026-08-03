# TODO-D 48: Spec coverage for critical svg/ea_emitter components

## Goal

Most `lib/ea/svg/ea_emitter/element/*` and `lib/ea/svg/ea_emitter/*.rb`
files had zero dedicated specs — they were only exercised through
the high-level regression suites. A regression in BColDecoder,
HeaderLines, Filter, or TextEscape could ship undetected if it
didn't trigger a regression-suite threshold.

## Coverage added

- `spec/ea/svg/ea_emitter/element/bcol_decoder_spec.rb` — BGR
  decoding, sentinel handling, color hex format.
- `spec/ea/svg/ea_emitter/element/filter_spec.rb` — skip?
  predicate under all permutations of (background_color, name,
  properties, model_index presence).
- `spec/ea/svg/ea_emitter/element/header_lines_spec.rb` —
  stereotype fallback rules, abstract italic-bold, UMLDI keyword
  override, package-qualified display name, Note special-case.
- `spec/ea/svg/ea_emitter/element/divider_renderer_spec.rb` —
  horizontal path geometry, group style attributes.
- `spec/ea/svg/ea_emitter/element/shape_renderer_spec.rb` — rect
  attributes, fill/stroke group style, shape-rendering.
- `spec/ea/svg/ea_emitter/element/text_escape_spec.rb` — XML
  special-char escaping, UTF-8 preservation, stereotype/namespace
  marker preservation.

## Bug found and fixed during spec writing

`HeaderLines.explicit_stereotype` called `classifier.stereotype_refs`
without guarding for Note (which extends Base, not Classifier).
Same issue in `display_name` (qualified_name missing on Note).

Added `is_a?(Ea::Model::Classifier)` guards so Note and other
non-Classifier model elements degrade gracefully instead of
raising NoMethodError. Without the new spec coverage this bug
would only surface when a user rendered a diagram containing a
Note element with a stereotype keyword.

## Verification

- 1746 examples pass (up from 1694).
- New specs cover both the happy path and edge cases.
- Bench plateau XMI unchanged.
