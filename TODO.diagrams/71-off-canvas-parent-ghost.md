# TODO-D 71: Off-canvas parent class ghost line in element header

## Status: completed (2026-08-01)

EA prepends the off-canvas parent classifier's name as an italic
line at the top of a placed element's header when ALL of:

1. The diagram's HideParents PDATA flag is 0 (default).
2. The placed element has a Generalization to a parent NOT placed
   on the current diagram.
3. No other element from the parent's package is placed on the
   diagram (EA treats the parent's package as "represented").

e.g. on the indoor diagram (HideParents=0), Room's parent
_CityObject (in the "core" package, off-canvas, no other core
elements placed) renders as an italic "_CityObject" line above
Room's own header. On Building (HideParents=1), no parent ghosts
render at all.

## Implementation

  - RelationshipBuilder populates Generalization.specific_id and
    .general_id (child + parent GUIDs).
  - Diagram model gains show_parents attribute; DiagramBuilder
    parses HideParents= from t_diagram.PDATA.
  - RenderContext carries off_canvas_parent_name; Elements resolves
    it via document.relationships + model_index + diagram.elements.
  - HeaderLines prepends [name, :italic] when the value is non-nil.
  - LayerSequencer threads `document:` to Elements.

## Plateau QEA impact

  - Before: text delta -98 (98 texts missing vs ref)
  - After:  text delta -36 (62 texts closed)
  - 188/188 diagrams matched.

## Remaining gap (-36)

The foreign-package rule is slightly too aggressive — some diagrams
(tran_2, urf_urbanFunction) render parent ghosts for parents in
"represented" packages. Removing the foreign-package check
over-corrects to +60 (over-render). The true discriminator is
narrower than "package represented" but broader than just
HideParents. Defer to a future investigation if a clearer signal
(e.g., a t_object flag, MDG stereotype pattern) is identified.
