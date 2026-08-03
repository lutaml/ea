# 69 - Package Diagram Elements Render as Polygons

## Status: COMPLETE (2026-07-26)

## What changed

1. `lib/ea/svg/ea_emitter/element/package_shape_renderer.rb` (NEW) —
   emits two polygons per Package element:
   - Body: `(left, top)` to `(right, bottom - 20)` (full element
     width, element height minus the tab strip)
   - Tab: `(left, top - 20)` to `(left + tab_width, top)` (sits ABOVE
     the element's logical top, 20px tall)

2. `lib/ea/svg/ea_emitter/element/filter.rb` — Filter now only skips
   Classifier placeholders with empty name+properties. Packages are
   always rendered.

3. `lib/ea/svg/ea_emitter/elements.rb` — Added `render_shape`
   dispatch: when the model element is an `Ea::Model::Package`, calls
   `PackageShapeRenderer`; otherwise `ShapeRenderer` (rect).

4. `lib/ea/model/document.rb` — `index_by_id` now aliases packages
   under both `EAPK_<guid>` (the uml:Model hierarchy id) and
   `EAID_<guid>` (the diagram element `subject=` ref). EA's XMI uses
   these two prefixes inconsistently — diagram elements always
   reference via `EAID_`, but packages are stored under `EAPK_`.

5. `lib/ea/svg/ea_emitter/bounds_calculator.rb` — Adds
   `package_tab_points` source so the canvas reserves 20px above
   each Package element for the tab polygon. Without this, tab
   vertices dip into negative coordinates.

6. `lib/ea/svg/ea_emitter/document.rb` — `frame:` now defaults to
   `true` (every diagram has a frame in EA's output).

7. `spec/ea/svg/ea_emitter/document_spec.rb` — New specs for the
   EAPK↔EAID alias and the polygon body+tab emission.

## Acceptance

- simple.qea "Package Contents" emits 11 polygons, matching the
  reference SVG byte-for-byte in count and shape structure.
- basic.xmi "Package Dependencies" emits 10 polygons, matching.
- Logical/Class diagrams still emit rects for Classifiers (no
  Package polygons).
- All 2285 specs pass.

## Remaining gap (canvas size)

Our canvas is ~40px narrower and ~26px shorter than the reference.
EA appears to reserve extra margin around the frame outer border
(non-uniform: ~35px left, ~50px right, ~60px top, ~36px bottom).
Closing this requires either parsing t_diagram cx/cy fields or
hard-coding per-diagram-type insets. Tracked separately.
