# TODO-D 04 - Rect under-rendering

## Status: WONTFIX (data drift) (2026-07-26)

## Investigation

Across 185 plateau diagrams, we under-render 221 rects (11%). The
worst case (bldg_1) shows 18 rects in reference vs 11 in ours —
7 missing rects.

Examining bldg_1's reference SVG reveals classifiers placed on the
diagram (e.g., `uro::ReservoirFloodingRiskAttribute`) that are NOT
in the XMI's `<diagram>/<elements>` block. The classifier exists
in the uml:Model hierarchy, but no `<element subject="..."/>` ref
places it on this diagram.

## Conclusion

The reference SVGs were generated from a MORE COMPLETE XMI than
the one we have. The XMI/SVG pair has drift — the SVG has
placements the XMI doesn't carry.

This is a fixture data issue, not an emitter bug. We cannot render
elements the XMI doesn't place. Closing this gap requires either:

1. Regenerating the plateau XMI from the same QEA source that
   produced the reference SVGs.
2. Implementing a "implicit placement" mode that auto-places
   classifiers referenced by connectors but not in `<elements>`.
   This would be guesswork — we don't know where EA placed them.

Option 1 is the right path. Marking this wontfix pending fixture
regeneration.
