# TODO-D 49: More spec coverage for orchestrators + labels cleanup

## Goal

Add dedicated specs for the high-level orchestrators that were
previously only exercised through end-to-end regression tests.

## Coverage added

- `spec/ea/svg/ea_emitter/element/operation_renderer_spec.rb` —
  Operation signature rendering, parameter joining, line-height
  stacking, visibility marker offsets.
- `spec/ea/svg/ea_emitter/layer_sequencer_spec.rb` — Background
  layer presence, labels layer inclusion, frame toggle, theme
  propagation, connector path integration.

## Dead code removed

`Labels#midpoint_text_for` was an unused private method (the
actual midpoint text emission goes through `texts_for`). Deleted.

## Verification

- 1759 examples pass (up from 1746, +13 new).
- Bench plateau XMI unchanged.
