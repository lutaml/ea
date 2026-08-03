# TODO-D 42: Close all SVG parity deltas to zero

## Goal

Reach shape/text parity 0/0/0/0 against the plateau XMI
reference set (192 SVGs in `001-mds/xmi-images/`).

## Current state (after TODO-D 41, 42)

```
rect     ours= 1781 ref= 2002  delta=-221 (-11.0%)
path     ours= 3018 ref= 3298  delta=-280 ( -8.5%)
polygon  ours=  955 ref=  961  delta=  -6 ( -0.6%)
text     ours=16947 ref=17548  delta=-601 ( -3.4%)
Text overlap avg: 64.5%
```

185/188 diagrams matched, 59 outliers.

## Architecture cleanup (DONE)

- `lib/ea.rb` no longer `require_relative`s `ea/version`. VERSION
  is inlined.
- `lib/ea/sources/xmi/diagram_builder.rb` no longer
  `require_relative`s `umldi_keyword_extractor`. Uses autoload.
- `lib/ea/qea/factory/generalization_builder.rb` no longer uses
  `public_send(:"#{k}=", v)` for attribute assignment.

## Diagnosis (DONE)

The deltas decompose into three root causes:

1. **Element icon decorations** (TODO-D 44, ~280 paths).
   EA renders a small "folded paper" icon at the top-right of
   some elements. IconRenderer exists but the discriminator
   (which elements get icons) is non-trivial — not just
   `HideIcon=0`.

2. **Phantom parent class boxes** (TODO-D 45, ~80 rects).
   When a connector's endpoint references a classifier that
   isn't placed on the diagram, EA renders a minimal "phantom"
   box at the connector's endpoint.

3. **User-drawn legend swatches** (TODO-D 46, ~50-100 rects).
   Manually-drawn colored rectangles inside Note/text elements.
   Not encoded as standard UML — may be unrecoverable from XMI.

Plus two text-delta sources:
- Diagrams where EA renders only a frame and no elements
  (TODO-D 41 has examples). The reference SVG is a tiny blank
  canvas; our renderer emits the full content.
- Tree-routing generalization markers: EA collapses 9 parallel
  connectors into 9 polygons at the same anchor (TODO-D 43).

## Acceptance

Closing each delta to zero requires:
- [ ] TODO-D 44 discriminator identified and IconRenderer enabled
- [ ] TODO-D 45 phantom parent rendering implemented
- [ ] TODO-D 46 either implemented or excluded from parity measurement
- [ ] TODO-D 43 marker strategy per connector Mode (tree vs custom)
- [ ] Blank-frame diagram detection (small canvas, all elements off-canvas)

## Out of scope for this commit

The remaining work requires EA GUI testing or Ghidra disassembly
to identify the icon discriminator and phantom-box trigger. These
are tracked in their own TODOs and will be addressed in focused
follow-up PRs.
