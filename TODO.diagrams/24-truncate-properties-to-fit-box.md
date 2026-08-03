# 24 - Truncate Properties to Fit Box (Match EA Display)

## Status: DONE (2026-07-23)

## Outcome

Discovered the actual rule: EA hides properties that are navigable
ends of an association (those are rendered as connector lines, not
as attribute text). This is NOT box-fit truncation — it's a content
filter based on property semantics.

## Implementation

1. Added `association_id` field to `Ea::Model::Property` (non-nil
   when the property is a navigable end of an Association).
2. `Ea::Sources::Xmi::PropertyBuilder` captures `attr.association`.
3. `Ea::Svg::EaEmitter::Elements#displayable_properties` rejects
   properties with `association_id` set.

## Files changed

- `lib/ea/model/property.rb` — `association_id` attribute + JSON mapping
- `lib/ea/sources/xmi/property_builder.rb` — populate `association_id`
- `lib/ea/svg/ea_emitter/elements.rb` — `displayable_properties` filter
