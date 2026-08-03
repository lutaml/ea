# TODO.complete/06: EMF→SVG conversion for t_image

## Status: open

EA's `t_image` table stores image blobs as Enhanced Metafile (EMF).
We currently skip them entirely.

The pure-Ruby `emfsvg` gem at `~/src/claricle/emfsvg/` consumes the
`emf` gem's domain model and converts EMF records to SVG — no FFI,
no libemf2svg. This is a perfect fit.

## Plan

1. Add `emfsvg` as an optional runtime dependency (`spec.add_dependency "emfsvg", "~> X"`).
2. Add `Ea::Image::EmfRenderer` that wraps `emfsvg` to convert a t_image
   BLOB to an SVG `<symbol>` definition.
3. Render in `lib/ea/svg/ea_emitter/`: emit `<defs><symbol id="img-{id}">`
   from EMF, then `<use href="#img-{id}"/>` at the placement rect.
4. Cache converted images per render pass (one t_image → one symbol).
5. Skip silently if `emfsvg` not available (graceful degradation).

## OCP / MECE

- Image rendering is its own namespace (`Ea::Image::`).
- No dependency on lutaml-uml.
- Lazy-loaded: only required when t_image rows exist.

## Acceptance

- Spec: `Ea.parse(plateau_v5_1_qea).images.size == 1`.
- Spec: SVG output for plateau includes an `<image>` reference or inline
  converted vector group.
- Spec: when emfsvg is unavailable, render proceeds without the image
  (no exception).
