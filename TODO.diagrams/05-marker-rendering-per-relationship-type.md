# 05 - Marker Rendering Per Relationship Type

## Status: DONE (2026-07-21, folded into TODO 03)

## Problem

EA renders different arrow markers based on the connector's
semantic type:

- **Association** (navigable): filled triangle at target
- **Generalization**: open triangle at target (white fill, black
  stroke)
- **Realization**: open triangle at target + dashed line
- **Dependency**: open arrow at target + dashed line
- **Aggregation** (source): open diamond at source
- **Composition** (source): filled diamond at source

Our current renderer emits a filled triangle at target regardless
of relationship type, plus a diamond for aggregations. The
distinction between open and filled markers matters visually.

## Approach

Add a `MarkerResolver` that maps a relationship type + end
(source/target) to a marker shape:

- `:filled_triangle`, `:open_triangle`, `:filled_diamond`,
  `:open_diamond`, `:open_arrow`, `:none`

Each shape is rendered as a 4-point `<polygon>` with the
appropriate fill color.

The marker anchor is the END of the polyline (target) or the
START (source). The marker is rotated to align with the line's
direction at that end.

## Files

- `lib/ea/svg/marker_resolver.rb`
- `lib/ea/svg/marker_shapes.rb` (one class per shape)
- Update `lib/ea/svg/ea_emitter/markers.rb`
- `spec/ea/svg/marker_resolver_spec.rb`

## Verification

- Spec: Association → filled triangle at target.
- Spec: Generalization → open triangle at target.
- Spec: Composition → filled diamond at source + filled triangle
  at target.
