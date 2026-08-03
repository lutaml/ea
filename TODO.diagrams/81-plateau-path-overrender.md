# TODO-D 81: Plateau path over-render on ifc_3 (+3) and similar diagrams

## Status: open

Several plateau diagrams render extra short horizontal `<path>`
elements (110-300px wide) that don't appear in EA's reference
SVG. The paths look like compartment dividers but appear at
positions where ref doesn't emit them.

## Per-diagram delta

  - ifc_3: +3 paths
  - utility network: -4 paths (different issue — missing phantom
    connector paths)
  - GenericObject: -5 paths (same as utility network)
  - cons_1: +2 paths
  - bldg:Buildingの拡張属性（LOD4）: +2 paths
  - bldg:Roomの拡張属性（LOD4）: +2 paths
  - udx: +2 paths
  - Urban Planning ADE2: +1 path
  - CityObjectGroupの拡張属性: +1
  - その他の構造物: +1
  - 位置図_C09_2: +1

## Pattern analysis (ifc_3)

Our extra paths at the same x range (218-438), varying y:
  - M 218 394 L 438 394
  - M 218 438 L 438 438
  - M 218 463 L 438 463
  - M 218 507 L 438 507

These look like 4 dividers in 4 different elements stacked
vertically. Ref's element layout differs (different y values),
suggesting our canvas/element y-offsets diverge from EA's.

## Hypothesis

Either:
1. Our divider emission logic fires for elements that EA treats
   as header-only (no divider).
2. Our canvas y-offset is off for some diagrams, causing dividers
   to land at "wrong" y values that don't match ref.

## Next step

For each affected diagram:
1. Compare element bounds (our placement vs ref's).
2. Compare divider_y values.
3. Identify whether it's a positioning issue or a divider-logic
   issue.

This is the largest remaining path-delta contributor.
