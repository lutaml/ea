# TODO-D 18: Property lookup index (performance + OCP)

## Problem

`Ea::Svg::EaEmitter::Labels#property_at_end` walks every Classifier
and every Property on each Classifier to find a Property by ID:

```ruby
def property_at_end(association, end_kind)
  id = end_kind == :source ? association.source_id : association.target_id
  return nil unless id && model_index

  model_index.values.each do |obj|
    next unless obj.is_a?(Ea::Model::Classifier)
    found = (obj.properties || []).find { |p| p.id == id }
    return found if found
  end
  nil
end
```

For the 205-diagram plateau QEA this is called once per visible
association per diagram (~10k calls × ~600 classifiers × ~10
properties = 60M comparisons). That is the dominant cost in SVG
rendering.

## Fix

Add a lazily-built property index to `Ea::Model::Document` keyed by
property id. Labels (and any future consumer) calls
`document.property_by_id[id]` for O(1) lookup.

This keeps the lookup logic in the model (model-driven) and avoids
each consumer rebuilding the same index (DRY).

## Acceptance

- `Document#property_index` returns `{ property_id => Property }`.
- `Labels#property_at_end` uses the index.
- Parity text overlap remains ≥ 87%.
- Specs continue to pass.
- `rake benchmark` (or ad-hoc timing) shows measurable speed-up.
