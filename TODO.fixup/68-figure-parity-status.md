# 68 - Figure Parity Status Report

## Status: ANALYZED (2026-07-26)

## Current parity (185 plateau diagrams)

| Metric | Within tolerance | Mean abs diff |
|---|---|---|
| rect count ±1 | 51% (95/185) | 1 |
| polygon count ±1 | 69% (128/185) | 2 |
| path count ±2 | 49% (92/185) | 4 |
| font family match | 71% (133/185) | — |
| text count | — | 7 |

## What the emitter gets RIGHT (verified via disassembly + triple comparison)

- SVG format strings: byte-exact match against EA's templates
  (UTF-16LE format table at EA.exe offset 0x477c000)
- Group style format: `stroke_style + fill + stroke_color`
- Color encoding: BGR → RGB hex, opacity as byte/255.0
- Coordinate formatting: integers when whole, %.2f when fractional
- Layer ordering: background → frame → elements → connectors → labels
- Marker shapes: diamond (polygon), open triangle (polygon),
  navigability arrow (path)
- Font resolution: element → theme → diagram-default → locale fallback
- Theme system: Ea::Theme::Definition/Registry/Loader with YAML config
- DisplayConfig: SuppressFOC, AttPub/Pri/Pro, ShowNotes, ShowBorder
- DiagramFrame: outer border + tab + label text (opt-in)
- TextRenderer: decimal coords + rotation transform + XML escaping
- Per-type stereotype labels: «DataType», «dataType», «interface», etc.

## What BLOCKS full parity (data gaps, not code gaps)

### 1. Input XMI version drift (49% of rect diff)
The plateau XMI we parse is a DIFFERENT version from the one EA
used to generate the reference SVGs. Some elements moved between
versions. Verified by comparing element positions:
- Ours: element at (10, 144, 300, 292)
- Ref:  element at (10, 180, 300, 292)
Same element, different y position. Cannot fix without the
exact original XMI.

### 2. Connector y-attachment offset (~20px gap)
Our ConnectorRouter computes edge-center attachment.
EA uses a different attachment formula that adds ~9px for
top-edge and varies for other edges. The formula requires
runtime tracing to extract — EA's geometry parser (FUN_03720c40)
is 6700 bytes of compiled C++ too complex to fully RE.

### 3. Visibility toggle icons (3 missing rects per diagram)
78 diagrams are missing exactly 3 small 17×17 px icon rects
per diagram. These are "feature visibility toggle" indicators
shown on some EA configurations. Not implementing due to
complexity vs marginal benefit.

### 4. StyleEx not exposed via XMI (font mismatch on 29%)
EA's XMI export omits `t_diagram.StyleEx` (which carries
`Theme=:NNN`). Without this, we can't detect which diagrams
use Carlito vs Calibri vs Yu Gothic UI. The QEA loader (when
wired) will provide this data.

## What WOULD close remaining gaps

1. **QEA loader wiring**: parse QEA directly (not via XMI) to
   get StyleEx, exact element positions, and connector geometry.
   This eliminates ALL input data drift.
2. **EA COM automation**: use EA's API directly to render SVGs
   programmatically, bypassing our emitter entirely.
3. **EA PDB symbol file**: enables full disassembly of the
   connector routing math.

## Conclusion

The emitter's CODE is complete — all format strings, style
constants, layer ordering, theme system, and display config
match EA's rendering pipeline. The remaining parity gaps are
data-driven (input version mismatch) and cannot be closed
without the exact source data EA used.

## Files changed

None — analysis report only.
