# 26 - SVGRenderer Architecture (from disassembly)

## Status: DONE (2026-07-25)

## Architecture findings

Decompiled 12 SVG-rendering functions in EA.exe. The SVG output
pipeline is structured as:

### Layer 1: Top-level draw driver

Iterates over shapes in a diagram, calls each shape's virtual
`DrawToSVG()` method. 22 caller functions found at addresses
0x199xxxx-0x19bxxxx, each handling a different shape type
(RectangleShape, EllipseShape, PolygonShape, PathShape, etc.).

### Layer 2: Per-shape SVG emitters

Each shape's `DrawToSVG()` calls into shared SVG helpers in the
0x2e8e000-0x2e9b000 range. Examples:

- `FUN_02e8e030` — emit `<g style="%s %s %s">` group envelope
  - Calls `FUN_02e8e4b0` (stroke_style: width+linecap+linejoin)
  - Calls `FUN_02e8e850` (fill_color: `fill:#XXXXXX;fill-opacity:N.NN;`)
  - Calls `FUN_02e8e9e0` (stroke_color: `stroke:#XXXXXX; stroke-opacity:N.NN`)
- `FUN_02e8e270` — emit `shape-rendering="X"` (4 quality modes)
- `FUN_02e91b30` — emit `<ellipse>` (computes center + radii)
- `FUN_02e91e80` — emit using stock object 5 (white brush — backgrounds)
- `FUN_02e91f20` — emit using stock object 8 (light-gray brush)

### Layer 3: Style fragment builders

These compose the 3-part group style from a shape's pen/brush:

- LineCap enum (offset 0x108): 0x100=butt, 0x200=square, default=round
- LineJoin enum (offset 0x10c): 0x1000=bevel, 0x2000=miter, default=round
- FillColor (offset 0x12c): BGR int
- StrokeColor (offset 0x110): BGR int
- StrokeWidth (offset ?): int
- FillOpacity / StrokeOpacity: byte 0-255, formatted as `byte/255.0`

### Key validation against our emitter

Cross-checked our Style constants:

| Our output | EA template | Match |
|---|---|---|
| `stroke-width:2;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00` | `<g style="%s %s %s">` filled with stroke_style + fill + stroke_color | ✓ byte-exact |
| `fill:#FFFFCC;fill-opacity:1.00;` | `fill:#%06X;fill-opacity:%s;` | ✓ |
| `stroke:#000000; stroke-opacity:1.00` | `stroke:#%06X; stroke-opacity:%s` (note leading space) | ✓ |
| `shape-rendering="auto"` | One of 4 modes per quality | ✓ |

## What we still don't know

The diagram iteration driver (which calls the per-shape draw
methods) lives in code outside the 0x2e8d000-0x2e9b000 range.
Finding it requires tracing the call graph upward from the
per-shape functions — would take additional days of analysis
without EA's PDB symbol file.

The remaining parity gaps (path/rect/polygon count diffs) come
from:

1. **Source XMI version drift** — the reference SVGs were
   generated from a different XMI version than the one we parse.
   Some elements moved between versions.
2. **Diagram iteration order** — EA iterates shapes in an order
   we can't fully determine without runtime tracing.

These gaps cannot be closed without either:
- The exact XMI version EA used (unavailable)
- A PDB symbol file (proprietary, not distributed)
- Runtime tracing via Wine/x64dbg

## Files changed

None — pure research/documentation TODO. Findings inform future
parity work.
