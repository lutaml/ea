# 29 - QEA+SVG+XMI Triple Comparison Findings

## Status: DONE (2026-07-25)

## Methodology

Three synchronized data sources now available:

- `examples/qea/*.qea` — source QEA files (SQLite database)
- `examples/exports/*/model.xml` — XMI exports
- `examples/exports/*/Images/*.svg` — SVG exports (from EA)

Triple comparison isolates where parity gaps come from:

| Compare | Reveals |
|---|---|
| QEA vs XMI | What info is lost in XMI export |
| XMI → our SVG vs EA's SVG | Our renderer bugs |
| QEA → our SVG (when supported) vs EA's SVG | Pure renderer comparison |

## Available datasets

| QEA | Diagrams | Notes |
|---|---|---|
| `simple` | 2 | Tiny — Package + Class diagrams |
| `test` | 2 | Small test models |
| `basic` | 22 | UML template with all classifier types |
| `ArcGISWorkspace_template` | 6 | ArcGIS domain |
| `UmlModel_template` | 0 (empty) | N/A |
| `simple_example` | 0 (empty) | N/A |
| `20251010_current_plateau_v5.1` | 188 | Production model |

## Key finding #1: EA has a THEME system

The QEA's `t_diagram.StyleEx` field carries a `Theme=:NNN` flag:

| QEA | Theme | Resulting style |
|---|---|---|
| `simple` | `:119` | Carlito 7pt, gray text, pastel fills |
| `basic` | `:119` | Same as simple |
| `test` | `:119` (some), `nil` (others) | Mixed |
| `ArcGISWorkspace_template` | `nil` | Default styling |
| `plateau v5.1` | `nil` | Yu Gothic UI 13px (element-stored) |

Theme `:119` produces:
- **Font**: Carlito (a Calibri-compatible open font)
- **Font size**: 7pt (not px)
- **Text color**: #595959 (gray, NOT black)
- **Text font-weight**: 0 for normal, 700 for bold (0 instead of 400!)
- **Element border**: #9A8484 (purple-gray, NOT black)
- **Element fill**: pastel per classifier type (see below)
- **Stroke width**: 1 (NOT 2)
- **Stroke cap/join**: round/bevel

## Key finding #2: Per-type fill colors (theme :119)

| Classifier type | Fill color | Stereotype label |
|---|---|---|
| Class | `#FDFAF7` | (depends on applied stereotype) |
| Interface | `#F1ECFA` | `«interface»` |
| DataType | `#FAF9E6` | `«dataType»` (lowercase d!) |
| Enumeration | `#E8FDE3` | `«enumeration»` |
| PrimitiveType | `#FAF9E6` | `«primitive»` |

Stereotype label casing observed in ref SVGs:
- `«DataType»` — Class with explicit DataType stereotype applied (CapD, CapT)
- `«dataType»` — DataType classifier (lowercase d, CapT)
- `«interface»` — Interface classifier (all lowercase)
- `«enumeration»` — Enumeration classifier (all lowercase)
- `«primitive»` — PrimitiveType classifier (all lowercase)

Our current emitter uses `«DataType»` for ALL Klass subclasses,
which is WRONG for actual DataType/Interface/Enumeration types.

## Key finding #3: Diagram frame

Every EA diagram has an outer border with a "tab" containing
the diagram name+type. Rendered as:

```xml
<!-- Outer border (path, not rect) -->
<g style="stroke-width:1;stroke-linecap:square;stroke-linejoin:miter;
          fill:#000000;fill-opacity:0.00; stroke:#000000; stroke-opacity:1.00">
  <path d="M 6 6 L 6 H-6 W-6 W-6 6 L 6 6" shape-rendering="auto"/>
</g>
<!-- Tab polygon (hexagon shape) -->
<g style="stroke-width:1;stroke-linecap:square;stroke-linejoin:miter;
          fill:#FFFFFF;fill-opacity:1.00; stroke:#000000; stroke-opacity:1.00">
  <polygon points="6 26 X 26 X+13 12 X+13 6 6 6 6 26"
           shape-rendering="auto" style="fill-rule:evenodd;"/>
</g>
<!-- Tab title text -->
<g style="...">
  <text x="11" y="19" textLength="W"
        style="font-family:Carlito; font-weight:700; ...;
               transform=rotate(-0.00 11 19)">
    class DiagramName
  </text>
</g>
```

Format: `<diagram_type> <diagram_name>` (e.g., `class Package A.1.1`,
`pkg Package Contents`).

Our emitter does NOT render the diagram frame at all.

## Key finding #4: Package rendering

Packages are rendered as POLYGONS, not rects:

```xml
<g style="stroke-width:1;stroke-linecap:round;stroke-linejoin:bevel;
          fill:#FAF3F0;fill-opacity:1.00; stroke:#9A8484; stroke-opacity:1.00">
  <!-- Main package body -->
  <polygon points="L T R T R B L B L T" .../>
  <!-- Tab on top-left -->
  <polygon points="L T-20 L+105 T-20 L+105 T L T L T-20" .../>
</g>
```

## Key finding #5: Text rotation transform

EVERY text element has a rotation transform, even when 0:

```xml
<text x="11.00" y="19.00" textLength="88"
      style="..."
      xml:space="preserve"
      transform="rotate(-0.00 11.00 19.00)">text</text>
```

Note: `x` and `y` are decimals (2 places), `textLength` is an integer.
The transform uses the same decimal x,y as the text.

Our emitter emits integer coords and no transform.

## Key finding #6: Stroke width per layer

| Layer | stroke-width | cap/join |
|---|---|---|
| Background rect | (none) | n/a |
| Diagram frame border | 1 | square/miter |
| Diagram frame tab | 1 | square/miter |
| Class boxes (theme :119) | 1 | round/bevel |
| Class dividers | 1 | round/bevel |
| Connector lines | 1 or 2 | round/bevel |

Our emitter hardcodes stroke-width 2 for everything.

## Key finding #7: DiagramObjects coords

QEA's t_diagramobjects stores rect coords with NEGATIVE y values
(e.g., `RectTop=-195, RectBottom=-265`). EA normalizes by
translating all elements so the topmost has y=padding.

Width = RectRight - RectLeft (positive)
Height = RectTop - RectBottom (positive — top > bottom in QEA's coords!)

Our current parser treats `top` as the upper coord and computes
height as `bottom - top`. For QEA data, this produces NEGATIVE
height. Need to take absolute value or swap.

## Practical parity improvements identified

1. **Diagram frame rendering** — add path + polygon + text for the
   outer border and tab.
2. **Theme support** — load theme from QEA's `t_diagram.StyleEx`
   `Theme=:NNN` field. Map theme ID to font/color/stroke values.
3. **Per-type stereotype labels** — fix the casing per classifier
   concrete class.
4. **Per-type fill colors** — lookup table for theme :119.
5. **Text rotation transform** — always emit `transform="rotate(-0.00 X Y)"`.
6. **Decimal text coords** — format x/y as `%.2f`.
7. **Stroke width 1** — use 1 for elements, dividers, frame.
8. **QEA rect coord fix** — height is `top - bottom` (not `bottom - top`).
9. **Package shape** — render as polygon with tab.
10. **Diagram style flags** — honor `SuppressFOC`, `AttPkg`,
    `ShowNotes` from StyleEx.

These collectively should close most parity gaps on the simple/basic
test diagrams and validate the same rules apply to the plateau data.

## Files changed

None — analysis TODO. Implementation in fixup 30+.
