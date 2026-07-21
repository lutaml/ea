# 07 - Canvas Size + viewBox Computation

## Status: DONE (2026-07-21, folded into TODO 03)

## Problem

EA's root `<svg>` element declares `width="Xcm" height="Ycm"` and
`viewBox="0 0 W H"`. The cm dimensions are computed from the
union of all element `image_bounds` (the padded bounds), with
~25 px padding around the canvas. The viewBox is in pixel units.

Our current renderer computes a viewBox from the union of element
bounds + connectors, but doesn't emit cm dimensions.

## Approach

`Ea::Svg::EaEmitter::Canvas` computes:

1. Union of all element `image_bounds` (NOT logical bounds — EA's
   canvas size is based on the visual padding).
2. Adds 10 px outer margin.
3. Emits viewBox = "min_x min_y width height".
4. Emits width/height in cm as `width / 28.346` (72 DPI conversion).

The canvas module is also responsible for translating the
coordinate space if min_x/min_y are non-zero (EA's convention is
to keep the viewBox starting at 0,0 by translating all elements).

## Files

- `lib/ea/svg/ea_emitter/canvas.rb`
- `spec/ea/svg/ea_emitter/canvas_spec.rb`

## Verification

- Spec: known element set produces expected viewBox and cm
  dimensions.
- Visual: SVG opens in a viewer at the same physical size as EA's
  output.
