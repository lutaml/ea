# 06 - Connector Labels (Role Names + Multiplicities)

## Status: DONE (2026-07-21, folded into TODO 03)

## Problem

EA renders labels on connectors at four canonical positions:

- `LLB` (lower-left, near source) — source role name
- `LLT` (upper-left, near source) — source multiplicity
- `LRB` (lower-right, near target) — target role name
- `LRT` (upper-right, near target) — target multiplicity

Each label has CX/CY (size), OX/OY (offset from the connector
endpoint), plus font/style flags.

Our current renderer emits no connector labels at all. The
information is in the XMI geometry string but never extracted.

## Approach

Extend the XMI adapter's geometry parser to also extract the four
label boxes, each as an `Ea::Model::LabelBox` with:

- `role` (:source_name, :source_multiplicity, :target_name,
  :target_multiplicity)
- `text` (decoded from the model's relationship ends)
- `offset_x`, `offset_y` (from OX/OY)
- `width`, `height` (from CX/CY)

The emitter renders each label as `<text>` at the appropriate
offset from the connector endpoint.

For QEA sources, the same data is in the connector's `SourceRole`
and `DestRole` notes + cardinality fields.

## Files

- `lib/ea/model/label_box.rb`
- `lib/ea/sources/xmi/extension_geometry_parser.rb` (extend)
- `lib/ea/svg/ea_emitter/labels.rb` (extend)
- `spec/ea/sources/xmi/extension_geometry_parser_spec.rb`
- `spec/ea/svg/ea_emitter/labels_spec.rb`

## Verification

- Spec: known geometry string yields 4 label boxes with correct
  offsets.
- Visual: connector labels appear at the same positions as EA.
