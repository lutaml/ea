# 76 - Plateau text undershoot investigation

## Status: COMPLETE (2026-07-26)

## Root cause

`DisplayConfig` was mis-mapping `SuppressFOC=1` (suppress foreign
object content — embedded images/OLE) to "suppress feature
compartments" (attributes/operations). 60 percent of plateau
diagrams have `SuppressFOC=1` in their StyleEx, so they were
rendering without attribute compartments — losing 10-100+ text
elements per diagram.

## Fix

Decoupled `show_attributes?` and `show_operations?` from
`SuppressFOC`. They now correctly check Style1 `HideAtts=1` and
`HideOps=1` (the actual EA UI flags for hiding compartments).

Restructured DisplayConfig to take both Style (style1) and StyleEx
(style2) since the visibility flags are split across both columns in
t_diagram.

## Impact

Sample parity jumped from 178/220 (81 percent) to 193/220
(88 percent). The biggest single fix in this round.
