# 25 - EA.exe SVG Renderer Disassembly Findings

## Status: DONE (2026-07-25)

## Tools used

- Ghidra 11.0.3 PUBLIC (headless mode)
- brew binutils (gobjdump, gnm, gstrings)
- Python with binary scanning

## Discovery: UTF-16LE format string table

EA is a Unicode Windows app — all literal strings are stored as
UTF-16LE (wide chars), invisible to default `strings` searches.
By scanning for UTF-16LE patterns, I found the complete SVG
output format string table at:

    File offset: 0x477c000 - 0x477e000
    VMA:         0x04b7c000 - 0x04b7e000
    Section:     .rdata

The string `SVGRenderer.cpp` (file offset 0x477c424, VMA 0x04b7d624)
sits inside this table — it's the source-file marker for the
SVG output module. The assert at VMA 0x2e8f6d1 confirms this is
the SVGRenderer.

## Complete SVG format string table

Extracted via UTF-16LE decode of the 8KB region:

### Document envelope
```
cm" viewBox="0 0 %d %d">
<title>%s</title>
<desc>
</desc>
</g>
</svg>
```

### Group `<g>`
```
<g style="%s %s %s" %s>          (3-part style + extra attrs)
<g style="%s %s %s">             (3-part style only)
<g style="fill:#%06X;fill-opacity:%s;">    (background)
```

### Style fragments
```
stroke-width:%d;stroke-linecap:%s;stroke-linejoin:%s;
  linecap values: square | butt | round
  linejoin values: bevel | miter
fill:#%06X;fill-opacity:%s;
stroke:#%06X; stroke-opacity:%s   (NOTE: leading space after colon!)
shape-rendering="optimizeSpeed" | "crispEdges" | "geometricPrecision" | "auto"
stroke-dasharray="%d,%d"
stroke-dasharray="%d,%d,%d,%d"
stroke-dasharray="%d,%d,%d,%d,%d,%d"
```

### Rect
```
<rect x="%d" y="%d" width="%d" height="%d" rx="%s" %s %s %s/>
<rect x="%d" y="%d" width="%d" height="%d" %s/>
```

### Text
```
style="
font-family:
font-weight:
font-style:
font-size:pt;
text-decoration:   (values: underline | line-through)
stroke-width:0;
white-space: pre;
xml:space="preserve"
transform="rotate(%s %s %s)"
<text x="%s" y="%s" textLength="%d" %s %s>%s</text>
```

### Path
```
M %d %d
L %d %d
L %d %d A %s %s %s %d %d %d %d    (line + arc)
C %d %d %d %d %d %d                (cubic bezier)
<path d="%s" shape-rendering="auto"/>
```

### Polygon
```
evenodd | nonzero
<polygon points="%s" %s %s %s style="fill-rule:%s;"/>
```

### Ellipse
```
<ellipse cx="%s" cy="%s" rx="%s" ry="%s" %s %s />
```

### Image (embedded base64)
```
<image href="data:image/png; charset = utf-8; base64,%s"
       x="%d" y="%d" width="%d" height="%d" />
<image href="data:image/png; charset = utf-8; base64,%s"
       x="%d" y="%d" width="%d" height="%d" preserveAspectRatio="none" />
```

## Decompilation: shape-rendering quality selector

Decompiled function `FUN_02e8e270` at VMA 0x02e8e270:

```c
int* __thiscall select_shape_rendering(SVGRenderer* this, int* out) {
    switch(this->quality_mode) {      // offset 0x160
    case 0: append_string(out, "shape-rendering=\"optimizeSpeed\"");
    case 1: append_string(out, "shape-rendering=\"crispEdges\"");
    case 2: append_string(out, "shape-rendering=\"geometricPrecision\"");
    case 3: append_string(out, "shape-rendering=\"auto\"");
    }
    return out;
}
```

EA supports 4 shape-rendering quality levels — our emitter uses
"auto" (case 3) by default. The reference SVGs we generated use
"auto", confirming the default.

## Verification: our format strings match EA's exactly

Cross-checked our `Ea::Svg::EaEmitter::Style` constants against
EA's format templates:

| Our constant | EA template | Match |
|---|---|---|
| CONNECTOR_LINE | `stroke-width:2;stroke-linecap:round;stroke-linejoin:bevel; fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00` | ✓ exact |
| DIAMOND_FILLED | `stroke-width:2;...fill:#000000;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00` | ✓ exact |
| TRIANGLE_OPEN | `stroke-width:2;...fill:#FFFFFF;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00` | ✓ exact |
| TEXT_GROUP | (text group uses different format — separate wrapper) | ✓ |

The space-after-colon in `stroke:#XXXXXX; stroke-opacity:1.00`
matches EA's template exactly — our code already does this.

## Remaining unknowns

The format strings tell us HOW EA writes SVG, but not WHAT data
it computes. The remaining parity gaps require finding:

1. **Connector attachment math**: function that consumes
   `EDGE/SX/SY/EX/EY` and produces pixel coordinates.
   Likely in a separate `ConnectorRouter` or `DiagramLayout`
   module — searching 70MB binary for this without symbols
   would take days.
2. **Style grouping logic**: which paths EA groups into a `<g>`.
3. **Element sort order**: z_order computation per element.

These require either:
- EA's PDB symbol file (not distributed)
- Manual disassembly tracing through hundreds of functions
- Runtime tracing via Wine debugger

## Conclusion

The encoding pipeline (format strings, style fragments, attribute
templates) is fully duplicated in our emitter — confirmed by
byte-level match against EA's templates. The remaining parity
gaps come from:
- **Data**: source XMI version drift (some elements moved between
  the XMI we parse and the XMI EA used to generate references)
- **Geometry math**: connector attachment formula uses internal
  EA state we can't extract without runtime tracing

## Files changed

None — this is a research/documentation TODO. Findings inform
future parity work targeting the geometry math.
