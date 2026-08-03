# 41 - DiagramFrame ShowBorder Detection

## Status: PARTIAL (frame renderer exists, auto-detect not yet)

## Current state

DiagramFrame renderer is implemented and opt-in via `frame: true`
on Document constructor. EA version difference (Build 1624 vs
1628) means the same ShowBorder=1 flag produces different output.

## Auto-detect rule (TODO)

When QEA loader is wired:
- Read t_diagram.ShowBorder
- If 1 AND build_id <= 1624 → render frame
- Otherwise → suppress

Plateau (build 1628) → no frame even with ShowBorder=1
Simple/basic (build 1624) → frame rendered

## Files changed

None — DiagramFrame already exists.
