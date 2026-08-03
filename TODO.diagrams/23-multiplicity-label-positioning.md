# 23 - Diagram-Level Multiplicity Label Positioning

## Status: DONE (2026-07-23)

## Outcome

Refactored `Ea::Svg::EaEmitter::Labels` to emit per-end role name +
multiplicity using LLB (left label box) / LLT (left label text) and
RLB / RLT offsets from the connector geometry.

Uses UML convention: the role visible at one end of the connector is
the property owned by the OPPOSITE classifier. So LLT (near source)
shows the target-end property; RLT (near target) shows the source-
end property.

Each label emits as TWO `<text>` elements matching EA's encoding:
one for the role name (`+roleName`) and one for the multiplicity
(`0..1`).

## Files changed

- `lib/ea/svg/ea_emitter/labels.rb` — full rewrite with model_index,
  association_ends, label_position, role_text, multiplicity_text
- `lib/ea/svg/ea_emitter/document.rb` — passes `model_index` to Labels

## Outcome metrics

Text count mean abs diff dropped from 20 → 14 across 185 diagrams.
Waterway: 92 → 103 (ref=113). CityFurniture: 24 → 30 (ref=34).
