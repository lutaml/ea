# 19 - Rect Count Undershoot Investigation

## Status: DONE (2026-07-25, analyzed)

## Findings

The 78 diagrams with rect count undershoot have a consistent
pattern: each is missing 3 small ~17×17 px "visibility toggle"
icons at the right edge of certain element boxes.

Example from `EAID_0016F797_*.svg`:
```
x=470 y=344 w=17 h=17
x=470 y=363 w=17 h=17
x=470 y=382 w=17 h=17
```

These icons appear to be "feature visibility toggles" (private/
protected/public indicator) that EA renders on some diagrams
when the diagram's "show feature visibility" option is enabled.

## Decision

Not implementing icon decoration rendering because:

1. **Visual complexity**: requires reverse-engineering the icon
   shapes (likely small triangles or circles filled with
   specific colors).
2. **Marginal benefit**: 3 small rects per diagram doesn't
   significantly affect visual fidelity.
3. **Configuration-gated**: appears only on diagrams with a
   specific display flag set — we'd need to plumb that flag
   through.

If full parity on rect count is needed in the future, this is
the next target. Tracked as TODO.fixup/23.

## Files changed

None.
