# 23 - Diagram Frame Title Element

## Status: ANALYZED (2026-07-25, deferred)

## Findings

EA diagrams include a "diagram frame" — a thin border with the
diagram name in the upper-left "tab" area. Three small 17x17
rects per diagram appear to be visibility-toggle icons.

Verified via rect count diff: 78 of 185 diagrams are missing
exactly 3 small rects. These appear only on diagrams with
Yu Gothic UI 13px font (which have explicit feature visibility
toggles enabled).

## Decision

Deferring implementation:

1. Requires reverse-engineering icon shapes (likely small
   colored triangles or squares)
2. Visual benefit marginal — 3 small icons in upper corner
   don't affect overall diagram comprehension
3. Time investment vs parity gain is poor

If pixel-perfect parity becomes a hard requirement, this is
the next target.

## Files changed

None.
