# 36 - QEA Rect Coord Normalization

## Status: ANALYZED (2026-07-25, deferred)

## Findings

QEA's `t_diagramobjects` stores rect with NEGATIVE y values:
  RectTop=-195, RectBottom=-265

Top > Bottom in QEA's coords. Width = RectRight - RectLeft.
Height = |RectBottom - RectTop|.

The XMI export already normalizes this — XMI-loaded diagrams
work correctly. The QEA adapter (when wired) will need to
handle this normalization.

## Decision

Deferring until QEA loader is wired into SVG pipeline. Current
XMI path works correctly.

## Files changed

None.
