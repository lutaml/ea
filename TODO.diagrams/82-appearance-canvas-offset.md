# TODO-D 82: Plateau Appearance diagram — canvas offset mismatch

## Status: open

The "Appearance" diagram (BC1F7E00 / C31C1314 — there are 2
versions) has 2 extra `<rect>` elements at positions that don't
match EA's reference.

## Symptom

  Our rects:                Ref rects:
    (35, 379) w=214 h=70      (35, 680) w=214 h=70
    (45, 479) w=208 h=70      (45, 580) w=208 h=70

Both elements (TransformationMatrix3x4 and TransformationMatrix2x2)
are placed on the diagram (stereotype="dataType", 16 placed
elements total). Ref renders them at y=580/680, we render at
y=379/479 — a delta of ~200 px.

## Root cause hypothesis

My `BoundsCalculator` computes canvas min_y = -1169 (lowest
element y -1154 minus MARKER_EXTENT 15). Reference's implied
min_y = -1470 (calculated from element model y -830 + render y 680
+ inset 40).

The 301-px difference suggests EA includes additional geometry
(extended labels, image-bounds padding, or some other source) in
its canvas bound computation that we don't.

## Why fixing this is hard

The BoundsCalculator is shared across all diagrams. A change here
affects every diagram's canvas. If the missing bound source is
diagram-specific (e.g., only DataType elements with certain
styles trigger it), the fix would need conditional logic.

## Likely related

  - Polygon positions on Appearance also differ — triangles at
    different anchors (might be connector endpoint mismatch
    due to wrong canvas translate).
  - Other diagrams with rect_delta > 0 may share the same offset
    issue.

## Next step

1. Identify what additional geometry EA's bounds include for
   Appearance. Candidates:
     - Connector label box extents (LLB/LRT geometry)
     - Element image_bounds vs logical bounds handling
     - Phantom connector waypoint contributions
2. Test by adding the candidate source to BoundsCalculator and
   verifying the canvas min_y matches.
