# TODO.complete/56: Wire EmfRenderer into SVG emitter

## Status: done

`Ea::Image::EmfRenderer` is defined but never called from the SVG
emitter. t_image rows are loaded into the database but never
appear in diagram output.

Note: the upstream `emfsvg` gem currently can't parse EA's specific
EMF variant (signature=1 layout differs from spec). The wiring is
still correct infrastructure — when emfsvg adds support, rendering
will work without ea-side changes. EmfRenderer already returns nil
gracefully when conversion fails.

## Plan

1. In the SVG emitter, walk `database.collections[:images]`.
2. For each image: `svg_fragment = Ea::Image::EmfRenderer.render(image.bytes)`
3. If non-nil: inline as `<g transform="translate(...)">...</g>` at
   the diagram's image placement rect.
4. If nil: skip silently (current behavior).

## Acceptance

- Spec: emitter calls EmfRenderer once per t_image row.
- Spec: when EmfRenderer returns nil (current state), output has no
  image fragment but doesn't crash.
