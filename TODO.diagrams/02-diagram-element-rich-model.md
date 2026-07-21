# 02 - Rich DiagramElement / DiagramConnector Model

## Status: DONE (2026-07-21, folded into TODO 03)

## Problem

The current `Ea::Model::DiagramElement` carries only `bounds` and
an untyped `style` hash. EA's renderer needs:

- `image_bounds` (the imgL/imgT/imgR/imgB padded rect — distinct
  from the logical Left/Top/Right/Bottom rect)
- `background_color` (decoded from `BCol` BGR integer → RGB hex)
- `font_family`, `font_size`, `font_bold`, `font_italic`
- `line_color`, `line_width`
- `z_order` (seqno)
- `label_inset` (the offset from the bounds origin where text
  should start; EA convention is x+5, y+17 for the first line)

For `DiagramConnector`:
- `source_anchor`, `target_anchor` (which edge of the source/target
  element the line attaches to — top/right/bottom/left)
- `source_duid`, `target_duid` (so the renderer can resolve back to
  placed elements without re-walking the model)
- `label_boxes` (the four LRT/LRB/LLT/LLB label rectangles with
  their text content decoded)

## Approach

Extend the existing types (don't replace — backward compat for the
QEA adapter which doesn't populate these yet):

- `DiagramElement`: add `image_bounds`, `background_color`,
  `font_family`, `font_size`, `font_bold`, `font_italic`,
  `line_color`, `line_width`, `z_order`
- `DiagramConnector`: add `source_anchor`, `target_anchor`,
  `source_duid`, `target_duid`, `label_boxes` (collection)

The QEA adapter populates these from its `objectstyle` packed
string (existing `DiagramStyleParser`); the XMI adapter populates
them from the `<xmi:Extension>/<elements>` style attribute.

The renderer reads the typed fields directly — no more parsing at
render time.

## Files

- `lib/ea/model/diagram_element.rb`
- `lib/ea/model/diagram_connector.rb`
- `lib/ea/model/label_box.rb` (new)
- `lib/ea/sources/qea/diagram_builder.rb` (populate the new fields)
- `lib/ea/sources/qea/diagram_style_parser.rb` (extend to typed
  accessors, not just a hash)
- `spec/ea/model/diagram_element_spec.rb`
- `spec/ea/model/diagram_connector_spec.rb`

## Verification

- Round-trip: model JSON includes all new fields; deserialize
  preserves them.
- QEA adapter spec: every placed element has a non-nil
  `background_color`.
