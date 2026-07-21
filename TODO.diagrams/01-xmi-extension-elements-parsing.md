# 01 - Parse XMI Extension Elements Block

## Status: DONE (2026-07-21)

## Problem

EA's XMI stores diagram placement data inside an `<xmi:Extension>`
block, under `<elements>/<element>` rows. Each row carries:

- `geometry="Left=X;Top=Y;Right=X2;Bottom=Y2;imgL=..;imgT=..;imgR=..;imgB=..;"`
  (pixel bounds + image bounds with 25 px padding)
- `subject="EAID_..."` (the model element this placement refers to)
- `seqno="N"` (z-order)
- `style="BCol=<int>;font=<name>;fontsz=<int>;bold=0;italic=0;LWth=<int>;.."`
  (EA packed style)

For connectors, the same row shape carries:
- `geometry="SX=..;SY=..;EX=..;EY=..;EDGE=N;$LLB=..;$LLT=..;LRT=..;LRB=..;Path=;"`
- `style="Mode=3;SOID=<source DUID>;EOID=<target DUID>;Color=-1;LWidth=2;"`

Our `Ea::Sources::Xmi::DiagramBuilder` currently reads only the
UML-DI `<owned_element>/<bounds>` tree, which doesn't include any
of this rich placement/style data. Result: SVG rendering from XMI
sources is missing colors, fonts, bend routing, label positions,
and proper element placement.

## Approach

Extend the XMI source adapter to walk the `<xmi:Extension>`
block's `<elements>` rows for each diagram. Build a parallel
`Ea::Model::DiagramElement` per row, populating:

- `bounds` from `Left/Top/Right/Bottom`
- `model_element_ref` from `subject` (resolved to model id)
- `style` hash including `BCol`, `font`, `fontsz`, `bold`, `italic`,
  `LWth`, `LCol` (line color)
- A new `image_bounds` field carrying the `imgL/imgT/imgR/imgB`
  padded bounds (EA's visual box, vs. the logical bounds)

For connector rows, build `Ea::Model::DiagramConnector` with:
- `relationship_ref` from `subject`
- Source/target resolved via `SOID`/`EOID` → DUID → placed element
- Waypoints computed from the SX/SY/EX/EY deltas + the source and
  target element edge centers (matching EA's rendering math)
- Style hash with `Color`, `LWidth`, `Mode`

## Files

- `lib/ea/sources/xmi/extension_elements.rb` (new — walks the
  extension block, returns typed rows)
- `lib/ea/sources/xmi/extension_geometry_parser.rb` (new — parses
  `geometry="..."` packed string into a typed struct)
- `lib/ea/sources/xmi/extension_style_parser.rb` (new — parses
  `style="..."` packed string into a typed struct)
- `lib/ea/sources/xmi/diagram_builder.rb` (updated — uses
  extension data when present, falls back to umldi otherwise)
- `lib/ea/model/diagram_element.rb` (extended — add
  `image_bounds` field)
- `spec/ea/sources/xmi/extension_*_spec.rb`

## Verification

- Unit specs: parse a known geometry/style string, assert typed
  struct matches.
- Integration: load `plateau_all_packages_export.xmi`, find diagram
  `EAID_0016F797_...`, assert every placed element has bounds +
  style populated.
