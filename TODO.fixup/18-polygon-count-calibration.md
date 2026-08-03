# 18 - Polygon Count Calibration

## Status: ANALYZED (2026-07-25, closed)

## Findings

After TODO.fixup/17 removed aggregation arrows, the polygon
count diff dropped. Remaining 45 diagrams with polygon >+1
fall into two categories:

1. **Aggregation vs Composition fill rule**: EA may use open
   (white-fill) diamonds for `shared` aggregation kind and
   filled for `composite`. Our Diamond kind always emits
   `:diamond_filled`. Verified the source XMI stores 205
   Aggregations, 0 Compositions — so this rule doesn't apply
   to this dataset.

2. **NoteLink / Package connector markers**: 18 Package +
   14 NoteLink connectors in source. We currently emit no
   markers for these. EA may render small icon-shaped polygons
   for them.

## Decision

Closing as analyzed — no clear win available without source
data distinguishing `shared` vs `composite` aggregations.
Future XMI imports with explicit composition markers will
need the open-vs-filled diamond rule.

## Files changed

None.
