# 59 - Thread Theme Through All Renderers

## Status: DONE (2026-07-26)

## Context

Only `Elements` consults `diagram.theme`. Four other renderers
hardcode values:
- `Labels` — hardcodes Yu Gothic UI 13px, #000000 fill
- `DiagramFrame` — hardcodes Calibri 7pt, #000000 fill
- `Connectors` — hardcodes stroke-width:2 via Style constant
- `Markers` — hardcodes stroke-width:2 via Style constant

Theme :119 needs sw=1, Carlito 7pt, #595959 text everywhere.

## What needs to change

1. `LayerSequencer` reads `diagram.theme` and passes to all
   child renderers via constructor param.
2. Labels gains `theme:` → uses theme.font_family / text_color
3. DiagramFrame gains `theme:` → uses theme.font_family / text_color
4. Connectors/Markers gain `theme:` → use theme.stroke_width

## Acceptance

- All renderers receive and use theme
- Theme :119 diagrams render all text in #595959
- All connector lines render at sw=1 when themed
- Existing specs pass
