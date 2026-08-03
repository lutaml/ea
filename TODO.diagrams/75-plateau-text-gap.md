# TODO-D 75: Plateau text under-render (-36)

## Status: open (partial — closed 62 of original -98 in TODO-D 71)

Across 188 plateau diagrams, we render 36 fewer `<text>` elements
than EA's reference SVG. Top undershoot diagrams:

  - tran_2 (-4): missing 2× RoadAttribute, 1× TransportationComplex,
    1× _TransportationObject, 1× TrafficAreaAttribute
  - urf_urbanFunction (-4): similar pattern
  - 12 diagrams at -3 each
  - many at -2

## Root cause

The foreign-package rule in `off_canvas_parent_name_for` is too
aggressive. It suppresses parent ghosts when ANY placed element
shares the parent's package, but EA actually renders ghosts in
this case for diagrams like tran_2 and urf_urbanFunction.

The discriminator is narrower than "package represented" — possibly
related to whether the parent is in a base library (gml) vs a user
package (uro, tran), or some other property of the parent class.

## What was tried

1. **Just HideParents flag**: closed -98 to +60 (over-rendered 60).
2. **HideParents + foreign-package check**: closed +60 to -36
   (under-rendered 36).

The truth is between these. Narrower discriminator needed.

## Deferred

Requires identifying the precise EA rule. Could be:
- A t_object flag on the parent (e.g., is it generic/template)
- The parent's package being a "base library" (gml vs user model)
- A specific stereotype pattern (e.g., base GML stereotypes)
- Connector-level metadata we're not yet reading
