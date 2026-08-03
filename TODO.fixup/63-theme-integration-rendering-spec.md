# 63 - Theme Integration Rendering Spec

## Status: DONE (2026-07-26)

## Context

The theme system has unit specs but no end-to-end integration
test verifying that a themed diagram renders with the correct
font, colors, and stroke widths in the SVG output.

## What needs to change

1. Spec loads simple.qea/model.xml
2. Sets diagram.theme = "119"
3. Renders via Ea::Svg::EaEmitter::Document
4. Parses SVG output and asserts:
   - Text fill is #595959 (not #000000)
   - Element stroke is #9A8484 (not #000000)
   - Stroke-width is 1 (not 2)
   - Font-family is Carlito (not Calibri)

## Acceptance

- Integration spec verifies all theme attributes in rendered SVG
