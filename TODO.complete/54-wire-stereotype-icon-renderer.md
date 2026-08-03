# TODO.complete/54: Wire StereotypeIconRenderer into SVG emitter

## Status: done

`Ea::Svg::EaEmitter::Element::StereotypeIconRenderer` is defined
and autoloaded but never invoked. The polygon -4 parity gap on
plateau diagrams remains because the renderer is dead code.

## Plan

1. Call `StereotypeIconRenderer.render(...)` from the element
   rendering pipeline (between header and attribute compartment).
2. Pass: classifier, bounds, canvas.
3. Insert the emitted polygon into the element's `<g>` group.

## Acceptance

- Spec: parsing a QEA with `FeatureType`-stereotyped classes
  produces SVG with `<polygon>` inside the element group.
- Parity harness: plateau polygon count improves (was -4).
