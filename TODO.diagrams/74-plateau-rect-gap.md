# TODO-D 74: Plateau rect over-render (+4)

## Status: open

Across 188 plateau diagrams, we render 4 more `<rect>` elements
than EA's reference SVG. Per-diagram deltas are spread thin.

## Likely causes

1. **Phantom connector label boxes**: my phantom connector code
   synthesizes label boxes (LLB/LLT) that may render extra rects.
2. **Element rect for hidden elements**: elements that should be
   filtered (e.g., via element_filter) but still render their
   bounding rects.
3. **Compartment background rects**: extra rects for compartments
   that EA suppresses in certain modes.

## Next step

Identify the 4 specific diagrams with rect_delta > 0 and inspect
the actual `<rect>` content vs ref. Likely a per-diagram PDATA
flag mismatch.
