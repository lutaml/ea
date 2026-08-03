# TODO-D 21: Auto-generated legend block

## Problem

EA renders a "凡例" (Legend) block in many diagrams that contain
color-coded stereotype elements. The block contains:

- A rounded-corner container rect (`rx=3`)
- 3 color swatch rects (`17×17`)
- A bold 12pt #003060 title "凡例"
- Three 9pt #003060 lines naming the source packages

Reference SVG example (EAID_0016F797):

```xml
<rect x="485" y="368" width="194" height="120" rx="3.00"/>
<rect x="495" y="398" width="17" height="17"/>  <!-- swatch 1 -->
<rect x="495" y="417" width="17" height="17"/>  <!-- swatch 2 -->
<rect x="495" y="436" width="17" height="17"/>  <!-- swatch 3 -->
<text x="546.00" y="387.00" font-weight:700 font-size:12pt>凡例</text>
<text x="517.00" y="410.00">GMLに定義されたクラス</text>
<text x="517.00" y="429.00">CityGMLに定義されたクラス</text>
<text x="517.00" y="448.00">i-URに定義されたクラス</text>
```

The block is NOT modeled in the QEA schema. There is no "Legend"
Object_Type, no t_lists row, no StyleEx flag tied to it.

## Investigation Notes

- 27 Note objects in the QEA, none contains "凡例".
- 5 Text objects in the QEA, all empty Note field.
- The legend titles and swatch colors vary per diagram but follow
  a fixed vocabulary: GML, CityGML, i-UR.
- The color swatches are the stereotype fill colors of elements
  visible in the diagram (e.g. FFCFFF for CityGML, CCFFCC for GML).

## Hypothesis

EA's "Diagram Legend" feature is a built-in diagram decoration
that auto-generates when:

1. The diagram contains elements whose stereotype maps to a
   known "package source" (GML, CityGML, i-UR).
2. The user has placed a Legend UI element (which EA serializes
   somewhere we haven't found yet — possibly t_image or a binary
   blob).

Without reverse-engineering EA.exe's legend code path or finding
the serialization, replicating this verbatim is high-risk.

## Status

Deferred. Pinned in the parity report (TODO.diagrams/
17-remaining-parity-gaps.md) as a known ~448-text gap.

## Acceptance (when picked up)

- Locate the legend serialization in the QEA (table + column).
- Model `Ea::Model::Legend` with `position`, `title`, `entries`
  (each entry: color + label).
- Build `Ea::Svg::EaEmitter::Legend` renderer producing the
  container rect + swatch rects + texts.
- Specs cover: empty legend, single-entry, three-entry.
- Parity text overlap climbs above 90%.
