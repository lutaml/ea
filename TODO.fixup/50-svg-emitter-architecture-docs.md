# 50 - SVG Emitter Architecture Documentation

## Status: ANALYZED (2026-07-26)

## Architecture summary

    Document
      └─ LayerSequencer (frame?, theme via diagram.style_ex)
           ├─ Background
           ├─ DiagramFrame (opt-in)
           ├─ Elements → Element::* compartment renderers
           │    ├─ ShapeRenderer → TextRenderer
           │    ├─ HeaderRenderer → TextRenderer
           │    ├─ DividerRenderer
           │    ├─ AttributeRenderer → TextRenderer
           │    ├─ OperationRenderer → TextRenderer
           │    └─ EnumerationLiteralRenderer → TextRenderer
           ├─ Connectors → Layer
           ├─ Markers → Marker::Registry (OCP) → Layer
           └─ Labels → TextRenderer

    Cross-cutting:
      Canvas (value object, translate_x/y)
      BoundsCalculator (3 source strategies)
      ColorResolver (BCol → theme → stereotype → default)
      FontResolver (element → theme → diagram → locale)
      Theme / ThemeRegistry (OCP)
      TextRenderer (decimal coords + rotation transform)
      Style (centralized constants)

## Files changed

None — documented in TODO.
