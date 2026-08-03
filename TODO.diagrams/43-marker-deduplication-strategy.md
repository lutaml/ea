# TODO-D 43: Marker deduplication strategy

## Current behavior

`lib/ea/svg/ea_emitter/markers.rb` deduplicates marker polygons/paths
by their anchor point (first coord pair, rounded to integer).

```
unique_bodies = grouped_entries.uniq { |e| anchor_key(e.body) }
```

## Reference behavior (verified from plateau)

EA's reference set is INCONSISTENT:

- `EAID_E7AABA98` (Building): 9 parallel generalizations to one
  parent — EA emits 9 polygons at the same anchor (collapses NOT
  applied).
- `EAID_9994BF62` (地域地区および用途地域): 29 generalizations, EA
  emits only 3 triangles. Many generalizations share the same
  parent — EA emits ONE marker per parent point, not per connector.

So:
- Same parent, single shape per connector endpoint: 1 marker (collapsed)
- Same parent, parallel (multiple distinct routes): 1 marker per route

## Discriminator hypothesis

The discriminator is likely the connector's `Mode` style flag:

- `Mode=1` — Custom routing (each connector has its own route →
  emit per connector)
- `Mode=3` — Tree routing (children share route to parent →
  emit ONE marker per parent point)

## Acceptance

- Identify the exact field that distinguishes "tree" from "custom"
  routing.
- Implement per-mode marker strategy:
  - Tree mode: emit one marker per (parent, edge) tuple.
  - Custom mode: emit one marker per connector.
- Bench polygon delta → 0.
- Spec coverage for both modes.

## Bench impact (current)

```
polygon  ours=955 ref=961 delta=-6  (-0.6%)
```

If the discriminator is wrong we either over-render (Mode=3 case
with parallel connectors) or under-render (Mode=1 case with shared
parent).
