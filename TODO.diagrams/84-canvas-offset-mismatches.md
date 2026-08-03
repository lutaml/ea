# TODO-D 84: Per-diagram canvas-offset / positioning mismatches

## Status: open (rolling)

Multiple plateau diagrams have small per-shape deltas (1-5 shapes
each) where my rendered positions differ from EA's reference.
The shape COUNTS are correct, but specific shapes are at the wrong
coordinates.

## Affected diagrams (sample)

  - utility network: -4 paths (canvas height off: ours 1156 vs ref 1156)
  - GenericObject: -5 paths (canvas width off: ours 872 vs ref 772)
  - ifc_3: +3 paths (frame dimensions match but divider y-positions off)
  - Appearance: +2 rects (canvas height off by 36px)
  - cons_1: +2 paths
  - bldg:Buildingの拡張属性（LOD4）: +2 paths
  - bldg:Roomの拡張属性（LOD4）: +2 paths

## Common pattern

Canvas dimensions or coordinate offsets differ by a small amount
(10-300 px). Once the canvas offset differs, every shape's
position shifts, producing both "extra" and "missing" paths at
slightly different coordinates.

## Likely root cause areas

1. `BoundsCalculator` includes element + connector + marker +
   package_tab points. EA may include ADDITIONAL geometry (label
   boxes, image bounds extensions, etc.) that we miss.

2. The MARKER_EXTENT padding (15 px) may differ from EA's actual
   padding for certain connector/marker combinations.

3. Element `image_bounds` handling: when an element has image
   bounds below its logical bounds, my code includes those points.
   EA may handle this conditionally.

## Why this is hard to fix incrementally

A change to BoundsCalculator affects EVERY diagram's canvas. A
fix that improves one diagram may regress others. Requires
identifying the precise missing bound source and applying
conditionally.

## Strategy

1. Pick one diagram (e.g. Appearance).
2. Reverse-engineer its canvas height from the reference.
3. Identify what geometry would produce that canvas height.
4. Add the missing bound source to BoundsCalculator.
5. Verify no regression on other diagrams.

Repeat for each affected diagram pattern.

## Related

  - TODO-D 82: Appearance-specific investigation
  - TODO-D 81: path over-render investigation
  - TODO-D 73: polygon under-render
