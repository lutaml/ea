# TODO-D 26: Phantom general-parent rendering

## Problem

The reference SVGs contain class headers (`_AbstractGeometricAggregate`,
`_CityObject`, `_FeatureCollection`, etc.) that do NOT appear in
`t_diagramobjects` for the diagram. ~150 missing text instances
across the plateau dataset.

## Empirical Rule (partial)

When a class is placed in a diagram, EA also displays its
generalization parent if the parent isn't already in the diagram.

Validation across 188 diagrams:

- Total parent-checks: 241
- Parent rendered in SVG: 129 (53.5%)

53.5% match suggests the rule is "right idea, wrong details." Other
factors:

- Per-element font/style override may suppress phantom rendering
  when the parent's style isn't explicit
- The discriminator may be tied to AttPkg / SuppressFOC flags
- EA may only render one level up the generalization chain

## Implementation Sketch

Add `phantom_generalizations_for(diagram, model_index)` returning
phantom DiagramElements with synthetic bounds (placed near their
child). Render them through the existing `groups_for` path so they
participate in the same compartment math, color resolution, etc.

```ruby
def ordered_elements
  placed = (diagram.elements || []).sort_by { |e| e.z_order || 0 }
  placed + phantom_elements(placed)
end

def phantom_elements(placed)
  placed_ids = placed.map(&:model_element_ref)
  parents = placed_ids.flat_map { |id| generalizations_of(id) }.uniq - placed_ids
  parents.map { |pid| phantom_diagram_element(pid) }
end
```

The hard part is positioning: EA computes phantoms at coordinates
we cannot derive without GUI testing or sample-data correlation.

## Acceptance

- Render general-parent phantoms for at least the cases where the
  rule applies cleanly.
- Phantom bounding box is plausible (within canvas extents).
- Parity text overlap climbs to ~90%+.
- Specs cover: parent not in diagram (phantom added), parent
  already in diagram (no duplicate), phantom appears in correct
  sub-layer.