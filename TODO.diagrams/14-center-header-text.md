# TODO-D 14 - Center classifier header text

## Status: COMPLETE (2026-07-27)

## Context

EA centers stereotype and classifier-name text horizontally within
the element bounds. SVG `<text x=>` is the LEFT edge of the text,
not the center, so we need to compute:

  left_edge = bounds.center_x - text_width / 2

Our previous code emitted `x = bounds.center_x` directly, which
placed the LEFT EDGE at the center — making all text appear
right-of-center.

## What changed

`HeaderRenderer.center_x_for(text, bounds, size)` computes the
left edge from a text-width approximation:

  text_width = text.length * size * 0.55

The factor 0.55 approximates average Carlito character width as a
fraction of point size. Not pixel-perfect (EA uses GDI text
metrics) but visually centered.

## Acceptance

- Stereotype label now visually centered in element box
- Classifier name now visually centered
- Close to reference x positions (within ~5px due to text-width
  approximation)
