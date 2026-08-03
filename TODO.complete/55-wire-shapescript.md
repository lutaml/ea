# TODO.complete/55: Wire ShapeScript into StereotypeIconRenderer

## Status: done

`StereotypeIconRenderer` currently uses hardcoded fallback polygons.
When the MDG technology defines a ShapeScript body for a stereotype,
we should parse it and emit the resulting primitives.

## Plan

1. Look up the stereotype's ShapeScript from the MDG registry.
2. If found: `Ea::Shapescript::Parser.parse(body)` →
   `Ea::Shapescript::Renderer.render(shapes)`.
3. If not found: use existing hardcoded fallback.
4. Translate the SVG fragment to absolute element coordinates.

## Acceptance

- Spec: StereotypeIconRenderer with an MDG-provided ShapeScript
  emits the parsed shape, not the fallback.
