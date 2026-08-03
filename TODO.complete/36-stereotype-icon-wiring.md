# TODO.complete/36: Stereotype icon wiring (closes polygon -4 parity gap)

## Status: done

The `Ea::Shapescript::Parser` and `Renderer` exist but aren't wired
into the SVG emitter. As a result, stereotype decorator icons
defined via ShapeScript in MDG files never appear in our SVG
output — the visible "polygon -4" gap across 188 plateau diagrams.

## Plan

1. Add `Ea::Svg::EaEmitter::Element::StereotypeIconRenderer` that:
   - Looks up the classifier's applied stereotype
   - Finds the matching MDG technology's shape definition
   - Parses + renders the ShapeScript body
   - Emits a small `<g>` inside the element box at the stereotype's
     default icon position (top-right of header)
2. Wire into the existing element pipeline (between HeaderRenderer
   and AttributeRenderer).
3. Provide a fallback hardcoded polygon for `FeatureType` and `Type`
   so the gap closes even without full ShapeScript source.

## OCP/MECE

- StereotypeIconRenderer owns one concern.
- New shape definitions = MDG files; no renderer changes.

## Acceptance

- Spec: `Ea.parse(plateau_qea)` SVG output for `都市施設` includes
  a `<polygon>` for `CollectiveFacilitiesForReconstruction`.
- Parity: polygon count moves from -4 to 0 on plateau.
